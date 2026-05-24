import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waste_segregation_app/models/filter_options.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';

class _FakeStorageService extends StorageService {
  _FakeStorageService({
    UserProfile? profile,
    List<WasteClassification>? classifications,
  })  : _profile = profile,
        _classifications = classifications ?? <WasteClassification>[];

  UserProfile? _profile;
  final List<WasteClassification> _classifications;
  final List<WasteClassification> savedClassifications = <WasteClassification>[];

  @override
  Future<UserProfile?> getCurrentUserProfile() async => _profile;

  @override
  Future<void> saveClassification(WasteClassification classification,
      {bool force = false}) async {
    final saved = classification.copyWith(userId: _profile?.id);
    _classifications.add(saved);
    savedClassifications.add(saved);
  }

  @override
  Future<ClassificationSaveResult> saveClassificationWithResult(
    WasteClassification classification, {
    bool force = false,
  }) async {
    final saved = classification.copyWith(userId: _profile?.id);
    _classifications.add(saved);
    savedClassifications.add(saved);
    return ClassificationSaveResult(
      saved: true,
      wasDuplicate: false,
      contentHash: 'test-hash-${savedClassifications.length}',
    );
  }

  @override
  Future<List<WasteClassification>> getAllClassifications(
      {FilterOptions? filterOptions}) async {
    return List<WasteClassification>.unmodifiable(_classifications);
  }

  void seedProfile(UserProfile profile) {
    _profile = profile;
  }
}

WasteClassification _classification({String id = 'classification-1'}) {
  return WasteClassification(
    id: id,
    itemName: 'Glass Bottle',
    category: 'Dry Waste',
    subCategory: 'Glass',
    explanation: 'Test classification',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Recycle',
      steps: const ['Rinse', 'Sort'],
      hasUrgentTimeframe: false,
    ),
    region: 'Test Region',
    visualFeatures: const ['glass', 'bottle'],
    alternatives: const [],
  );
}

UserProfile _profile({
  String id = 'user-1',
  String? email,
  String? displayName,
}) {
  return UserProfile(
    id: id,
    email: email,
    displayName: displayName,
  );
}

void main() {
  late _FakeStorageService storage;
  late CloudStorageService cloudStorageService;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    storage = _FakeStorageService(profile: _profile());
    cloudStorageService = CloudStorageService(storage);
  });

  group('CloudStorageService', () {
    test('saveUserProfileToFirestore skips empty user ids', () async {
      storage.seedProfile(_profile(id: '', email: 'ignored@example.com'));

      await cloudStorageService.saveUserProfileToFirestore(
        _profile(id: '', email: 'ignored@example.com'),
      );

      expect(storage.savedClassifications, isEmpty);
    });

    test('saveClassificationWithSync saves locally when cloud sync is off',
        () async {
      final classification = _classification();

      await cloudStorageService.saveClassificationWithSync(
        classification,
        false,
        processGamification: false,
      );

      expect(storage.savedClassifications, hasLength(1));
      expect(storage.savedClassifications.single.id, classification.id);
      expect(storage.savedClassifications.single.userId, 'user-1');
    });

    test('getAllClassificationsWithCloudSync returns local data when sync is off',
        () async {
      final classification = _classification(id: 'local-1');
      await storage.saveClassification(classification);

      final classifications =
          await cloudStorageService.getAllClassificationsWithCloudSync(false);

      expect(classifications, hasLength(1));
      expect(classifications.single.id, 'local-1');
    });
  });
}
