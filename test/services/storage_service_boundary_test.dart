// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/classification_storage_service.dart';
import 'package:waste_segregation_app/services/user_profile_storage_service.dart';
import 'package:waste_segregation_app/utils/constants.dart';

WasteClassification _makeClassification({
  String id = 'test_id',
  String itemName = 'test-item',
  String category = 'plastic',
  String explanation = 'Test classification',
}) {
  return WasteClassification(
    id: id,
    itemName: itemName,
    category: category,
    explanation: explanation,
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Recycle',
      steps: ['Rinse', 'Sort', 'Drop at center'],
      hasUrgentTimeframe: false,
    ),
    region: 'Bangalore',
    visualFeatures: [],
    alternatives: [],
  );
}

void main() {
  late ClassificationStorageService classificationStorage;
  late UserProfileStorageService profileStorage;
  late StorageService storageService;

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_boundary');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(WasteClassificationAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AlternativeClassificationAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DisposalInstructionsAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(UserRoleAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    // Open boxes directly (skip StorageService.initializeHive which
    // requires platform channels not available in unit test mode)
    await Hive.openBox(StorageKeys.userBox);
    await Hive.openBox(StorageKeys.classificationsBox);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox<String>('classificationHashesBox');
  });

  setUp(() {
    classificationStorage = ClassificationStorageService();
    profileStorage = UserProfileStorageService();
    storageService = StorageService();
  });

  tearDown(() async {
    try {
      await Hive.box(StorageKeys.classificationsBox).clear();
    } catch (_) {}
    try {
      await Hive.box(StorageKeys.userBox).clear();
    } catch (_) {}
    try {
      await Hive.box('classificationHashesBox').clear();
    } catch (_) {}
  });

  group('ClassificationStorageService — format boundary', () {
    test(
        'ClassificationStorageService.saveClassification writes JSON string, '
        'not TypeAdapter object', () async {
      final classification = _makeClassification(id: 'boundary_test_001');

      await classificationStorage.saveClassification(classification);

      final box = Hive.box(StorageKeys.classificationsBox);
      final rawData = box.get('boundary_test_001');

      expect(rawData, isA<String>(),
          reason: 'Extracted service should write JSON strings, '
              'not TypeAdapter binary objects');
      final decoded = jsonDecode(rawData as String);
      expect(decoded, isA<Map<String, dynamic>>());
      expect(decoded['id'], equals('boundary_test_001'));
      expect(decoded['itemName'], equals('test-item'));
    });

    test(
        'StorageService.saveClassification writes TypeAdapter object, '
        'not JSON string', () async {
      final classification = _makeClassification(id: 'boundary_test_002');

      await storageService.saveClassification(classification);

      final box = Hive.box(StorageKeys.classificationsBox);
      final rawData = box.get('boundary_test_002');

      expect(rawData, isA<WasteClassification>(),
          reason: 'StorageService should write TypeAdapter binary objects, '
              'not JSON strings');
      final obj = rawData as WasteClassification;
      expect(obj.id, equals('boundary_test_002'));
      expect(obj.itemName, equals('test-item'));
    });

    test(
        'Classifications written by both formats are readable by '
        'ClassificationStorageService.getAllClassifications', () async {
      final jsonItem = _makeClassification(id: 'json_item');
      final adapterItem = _makeClassification(
        id: 'adapter_item',
        itemName: 'from-type-adapter',
        category: 'metal',
      );

      await classificationStorage.saveClassification(jsonItem);
      await storageService.saveClassification(adapterItem);

      final all = await classificationStorage.getAllClassifications();
      final ids = all.map((c) => c.id).toSet();

      expect(ids, contains('json_item'));
      expect(ids, contains('adapter_item'));
    });

    test(
        'Classifications written by both formats are readable by '
        'StorageService.getAllClassifications', () async {
      final jsonItem = _makeClassification(
        id: 'ss_json_item',
        itemName: 'ss-from-json',
        category: 'glass',
      );
      final adapterItem = _makeClassification(
        id: 'ss_adapter_item',
        itemName: 'ss-from-adapter',
        category: 'organic',
      );

      await classificationStorage.saveClassification(jsonItem);
      await storageService.saveClassification(adapterItem);

      final all = await storageService.getAllClassifications();
      final ids = all.map((c) => c.id).toSet();

      expect(ids, contains('ss_json_item'));
      expect(ids, contains('ss_adapter_item'));
    });
  });

  group('UserProfileStorageService — key mismatch boundary', () {
    final testProfile = UserProfile(
      id: 'uuid-profile-123',
      displayName: 'Boundary Test User',
      email: 'boundary@test.com',
    );

    test(
        'UserProfileStorageService.saveUserProfile stores under '
        'userProfile.id (UUID), not StorageKeys.userProfileKey', () async {
      await profileStorage.saveUserProfile(testProfile);

      final box = Hive.box(StorageKeys.userBox);

      final storedUnderUuid = box.get(testProfile.id);
      final storedUnderConstantKey = box.get(StorageKeys.userProfileKey);

      expect(storedUnderUuid, isNotNull,
          reason: 'Profile should be stored under userProfile.id (UUID)');
      expect(storedUnderUuid, isA<String>(),
          reason: 'Extracted service writes JSON string');
      final decoded = jsonDecode(storedUnderUuid as String);
      expect(decoded['id'], equals('uuid-profile-123'));

      expect(storedUnderConstantKey, isNull,
          reason: 'Profile should NOT be stored under StorageKeys.userProfileKey '
              'when using the extracted service');
    });

    test(
        'StorageService.saveUserProfile stores under '
        'StorageKeys.userProfileKey, not userProfile.id', () async {
      await storageService.saveUserProfile(testProfile);

      final box = Hive.box(StorageKeys.userBox);

      final storedUnderUuid = box.get(testProfile.id);
      final storedUnderConstantKey = box.get(StorageKeys.userProfileKey);

      expect(storedUnderConstantKey, isNotNull,
          reason: 'Profile should be stored under StorageKeys.userProfileKey');
      expect(storedUnderConstantKey, isA<UserProfile>(),
          reason: 'StorageService writes TypeAdapter binary');

      expect(storedUnderUuid, isNull,
          reason: 'Profile should NOT be stored under userProfile.id (UUID) '
              'when using StorageService');
    });

    test(
        'StorageService.getCurrentUserProfile returns null for profile '
        'written by UserProfileStorageService', () async {
      await profileStorage.saveUserProfile(testProfile);

      final result = await storageService.getCurrentUserProfile();

      expect(result, isNull,
          reason: 'StorageService reads from StorageKeys.userProfileKey, '
              'but UserProfileStorageService writes under userProfile.id. '
              'A naive wire would silently lose the user profile.');
    });

    test(
        'StorageService.getCurrentUserProfile finds profile written by '
        'StorageService.saveUserProfile', () async {
      await storageService.saveUserProfile(testProfile);

      final result = await storageService.getCurrentUserProfile();

      expect(result, isNotNull,
          reason: 'StorageService should read its own writes');
      expect(result!.id, equals('uuid-profile-123'));
    });

    test(
        'UserProfileStorageService stored JSON is decodable by '
        'UserProfile.fromJson', () async {
      await profileStorage.saveUserProfile(testProfile);

      final box = Hive.box(StorageKeys.userBox);
      final rawData = box.get(testProfile.id) as String;
      final decoded = UserProfile.fromJson(jsonDecode(rawData));

      expect(decoded.id, equals('uuid-profile-123'));
      expect(decoded.displayName, equals('Boundary Test User'));
      expect(decoded.email, equals('boundary@test.com'));
    });
  });

  group('Read safety — multi-format compatibility', () {
    test(
        'ClassificationStorageService.getClassificationById returns correct '
        'result for both JSON and TypeAdapter entries', () async {
      final jsonItem = _makeClassification(
        id: 'multi_json_id',
        itemName: 'multi-json-item',
        category: 'plastic',
      );
      final adapterItem = _makeClassification(
        id: 'multi_adapter_id',
        itemName: 'multi-adapter-item',
        category: 'paper',
      );

      await classificationStorage.saveClassification(jsonItem);
      await storageService.saveClassification(adapterItem);

      final jsonResult =
          await classificationStorage.getClassificationById('multi_json_id');
      final adapterResult =
          await classificationStorage.getClassificationById('multi_adapter_id');

      expect(jsonResult, isNotNull);
      expect(jsonResult!.itemName, equals('multi-json-item'));

      expect(adapterResult, isNotNull);
      expect(adapterResult!.itemName, equals('multi-adapter-item'));
    });
  });

  group('Settings read/write — no conflict across services', () {
    test('UserProfileStorageService settings operations work', () async {
      await profileStorage.saveSettings(
        additionalSettings: {'test_key': 'test_value'},
      );

      final result = await profileStorage.getSetting<String>('test_key');
      expect(result, equals('test_value'));
    });
  });
}
