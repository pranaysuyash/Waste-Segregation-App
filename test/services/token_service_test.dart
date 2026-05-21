import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:waste_segregation_app/models/token_wallet.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/token_service.dart';
import 'package:waste_segregation_app/utils/firebase_gate.dart';

class _FakeStorageService extends StorageService {
  UserProfile? _profile;

  void seedProfile(UserProfile profile) {
    _profile = profile;
  }

  @override
  Future<UserProfile?> getCurrentUserProfile() async => _profile;

  @override
  Future<void> saveUserProfile(UserProfile userProfile) async {
    _profile = userProfile;
  }
}

class _FakeCloudStorageService extends CloudStorageService {
  _FakeCloudStorageService(super.storageService);

  final List<UserProfile> savedProfiles = <UserProfile>[];

  @override
  Future<void> saveUserProfileToFirestore(UserProfile userProfile,
      {bool useBatching = true}) async {
    savedProfiles.add(userProfile);
  }
}

class _MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class _MockHttpsCallable extends Mock implements HttpsCallable {}

UserProfile _baseProfile({TokenWallet? wallet, List<TokenTransaction>? txns}) {
  return UserProfile(
    id: 'user-1',
    displayName: 'User One',
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
    lastActive: DateTime.now().subtract(const Duration(days: 1)),
    tokenWallet: wallet,
    tokenTransactions: txns,
  );
}

void main() {
  late _FakeStorageService storage;
  late _FakeCloudStorageService cloud;
  late TokenService tokenService;

  setUp(() {
    storage = _FakeStorageService();
    cloud = _FakeCloudStorageService(storage);
    tokenService = TokenService(storage, cloud);
    TokenService.enableTokenEnforcement = false;
    TokenService.enableServerSideValidation = false;
  });

  test('initialize creates new wallet for first-time user', () async {
    storage.seedProfile(_baseProfile());

    await tokenService.initialize();

    final wallet = tokenService.currentWallet;
    expect(wallet, isNotNull);
    expect(wallet!.balance, 50);
    expect(wallet.totalEarned, 50);
  });

  test('spendTokens deducts balance and records transaction', () async {
    storage.seedProfile(_baseProfile(
      wallet: TokenWallet(
        balance: 12,
        totalEarned: 20,
        totalSpent: 8,
        lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ));

    final updated = await tokenService.spendTokens(5, 'Instant analysis');

    expect(updated.balance, 7);
    expect(updated.totalSpent, 13);
    final txns = await tokenService.getTransactionHistory();
    expect(txns, isNotEmpty);
    expect(txns.first.delta, -5);
    expect(txns.first.description, 'Instant analysis');
  });

  test('spendTokens throws on insufficient balance', () async {
    storage.seedProfile(_baseProfile(
      wallet: TokenWallet(
        balance: 2,
        totalEarned: 10,
        totalSpent: 8,
        lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ));

    expect(
      () => tokenService.spendTokens(5, 'Instant analysis'),
      throwsException,
    );
  });

  test('convertPointsToTokens enforces multiple of conversion rate', () async {
    storage.seedProfile(_baseProfile(
      wallet: TokenWallet(
        balance: 10,
        totalEarned: 10,
        totalSpent: 0,
        lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ));

    expect(
      () => tokenService.convertPointsToTokens(50, 1000),
      throwsException,
    );
  });

  test('convertPointsToTokens updates wallet and daily conversion count',
      () async {
    storage.seedProfile(_baseProfile(
      wallet: TokenWallet(
        balance: 10,
        totalEarned: 10,
        totalSpent: 0,
        lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ));

    final updated = await tokenService.convertPointsToTokens(200, 200);

    expect(updated.balance, 12);
    expect(updated.totalEarned, 12);
    expect(updated.dailyConversionsUsed, 1);
  });

  test('processDailyLogin awards bonus only once per day', () async {
    storage.seedProfile(_baseProfile(
      wallet: TokenWallet(
        balance: 10,
        totalEarned: 10,
        totalSpent: 0,
        lastUpdated: DateTime.now(),
      ),
    ));

    final unchanged = await tokenService.processDailyLogin();
    expect(unchanged.balance, 10);

    storage.seedProfile(_baseProfile(
      wallet: TokenWallet(
        balance: 10,
        totalEarned: 10,
        totalSpent: 0,
        lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ));
    final refreshed = TokenService(storage, cloud);
    TokenService.enableServerSideValidation = false;
    final updated = await refreshed.processDailyLogin();
    expect(updated.balance, 12);
  });

  test('premium pricing applies discount for instant analysis', () async {
    storage.seedProfile(_baseProfile(
      wallet: TokenWallet(
        balance: 3,
        totalEarned: 10,
        totalSpent: 0,
        lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ));

    await tokenService.initialize();
    TokenService.enableTokenEnforcement = true;

    expect(tokenService.getAnalysisCost(AnalysisSpeed.instant), 5);
    expect(
        tokenService.getAnalysisCost(AnalysisSpeed.instant,
            isPremiumUser: true),
        2);
    expect(
      tokenService.canAffordAnalysisWithPricing(AnalysisSpeed.instant,
          isPremiumUser: true),
      isTrue,
    );
    expect(
      tokenService.canAffordAnalysisWithPricing(AnalysisSpeed.instant),
      isFalse,
    );
  });

  test(
      'spendTokens fails fast when enforcement is on but server validation is off',
      () async {
    storage.seedProfile(_baseProfile(
      wallet: TokenWallet(
        balance: 12,
        totalEarned: 20,
        totalSpent: 8,
        lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ));
    TokenService.enableTokenEnforcement = true;
    TokenService.enableServerSideValidation = false;

    if (isFirebaseEnabled) {
      expect(
        () => tokenService.spendTokens(2, 'Config guard test'),
        throwsException,
      );
    }
  });

  test(
      'spendTokens falls back to local spend for guest when server returns unauthenticated',
      () async {
    final mockFunctions = _MockFirebaseFunctions();
    final mockCallable = _MockHttpsCallable();

    when(() => mockFunctions.httpsCallable('spendUserTokens'))
        .thenReturn(mockCallable);
    when(() => mockCallable.call(any())).thenThrow(
      FirebaseFunctionsException(
        code: 'unauthenticated',
        message: 'Authentication required.',
      ),
    );

    storage.seedProfile(_baseProfile(
      wallet: TokenWallet(
        balance: 12,
        totalEarned: 20,
        totalSpent: 8,
        lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ));

    final guestTokenService = TokenService(
      storage,
      cloud,
      functionsClient: mockFunctions,
    );

    TokenService.enableTokenEnforcement = true;
    TokenService.enableServerSideValidation = true;

    if (isFirebaseEnabled) {
      final updated =
          await guestTokenService.spendTokens(5, 'Instant analysis');
      expect(updated.balance, 7);
      expect(updated.totalSpent, 13);
      final txns = await guestTokenService.getTransactionHistory();
      expect(txns, isNotEmpty);
      expect(txns.first.delta, -5);
    }
  });
}
