# Data Migration Playbook

## Overview
This document provides detailed procedures for handling data schema migrations for both Hive (local storage) and cloud storage as the app evolves. It ensures backward compatibility and prevents data loss during app updates.

## Current Data Architecture

The Waste Segregation App currently uses the following data storage mechanisms:

- **Hive**: Primary local storage for user data, classifications, cached results, and app settings
- **Firebase Firestore** (Planned): Cloud storage for user data synchronization, shared classifications, and community features
- **Shared Preferences**: For simple key-value storage of app settings and flags

## Hive Migration Strategy

### TypeAdapter Versioning

Hive requires explicit versioning of TypeAdapters to handle schema changes. Follow these guidelines:

1. **Initial TypeAdapter Registration**:
```dart
// Pseudocode for initial registration
@HiveType(typeId: 0)
class WasteClassification {
  @HiveField(0)
  final String itemName;
  
  @HiveField(1)
  final String wasteCategory;
  
  // Other fields...
}
```

2. **Adding New Fields (Non-Breaking Change)**:
```dart
// Pseudocode for adding new fields
@HiveType(typeId: 0)
class WasteClassification {
  @HiveField(0)
  final String itemName;
  
  @HiveField(1)
  final String wasteCategory;
  
  // Existing fields...
  
  // New field with a new index
  @HiveField(10)
  final bool isVerifiedByUser;
}
```

3. **Changing Field Types (Breaking Change)**:
```dart
// Pseudocode for changing field types
// Create a new class with a new typeId
@HiveType(typeId: 5)
class WasteClassificationV2 {
  @HiveField(0)
  final String itemName;
  
  // Changed from String to enum
  @HiveField(1)
  final WasteCategory wasteCategory;
  
  // Other fields...
}
```

### Migration Functions

For each significant schema change, create a dedicated migration function:

```dart
// Pseudocode for migration function
Future<void> migrateWasteClassificationV1toV2(Box<dynamic> box) async {
  for (final key in box.keys) {
    final oldObject = box.get(key);
    if (oldObject is WasteClassification) {
      // Create new version with transformed data
      final newObject = WasteClassificationV2(
        itemName: oldObject.itemName,
        wasteCategory: _parseWasteCategory(oldObject.wasteCategory),
        // Transform other fields...
      );
      
      // Replace old object with new
      await box.put(key, newObject);
    }
  }
}

// Helper to transform string category to enum
WasteCategory _parseWasteCategory(String categoryString) {
  switch (categoryString.toLowerCase()) {
    case 'wet waste':
      return WasteCategory.wetWaste;
    // Other cases...
    default:
      return WasteCategory.unknown;
  }
}
```

### Migration Registry

Maintain a central registry of migrations that need to be applied:

```dart
// Pseudocode for migration registry
class MigrationRegistry {
  static final List<Migration> migrations = [
    Migration(
      fromVersion: 1,
      toVersion: 2,
      migrationFn: migrateWasteClassificationV1toV2,
    ),
    // Other migrations...
  ];
}

class Migration {
  final int fromVersion;
  final int toVersion;
  final Future<void> Function(Box<dynamic>) migrationFn;
  
  Migration({
    required this.fromVersion,
    required this.toVersion,
    required this.migrationFn,
  });
}
```

### Migration Execution Process

Run migrations during app initialization:

```dart
// Pseudocode for migration execution
Future<void> runRequiredMigrations() async {
  final currentVersion = await _getCurrentSchemaVersion();
  final neededMigrations = MigrationRegistry.migrations
      .where((m) => m.fromVersion >= currentVersion)
      .toList()
      ..sort((a, b) => a.fromVersion.compareTo(b.fromVersion));
  
  for (final migration in neededMigrations) {
    try {
      final box = await Hive.openBox('waste_classifications');
      await migration.migrationFn(box);
      await _updateSchemaVersion(migration.toVersion);
      await box.close();
    } catch (e) {
      // Handle migration error
      await _logMigrationError(e, migration);
      // Fallback strategy
      await _applyFallbackForFailedMigration(migration);
    }
  }
}
```

## Cloud Data Migration (Firestore/Firebase)

### Schema Evolution Approach

For cloud data, follow these principles:

1. **Additive Changes**: Always prefer adding fields rather than modifying existing ones
2. **Field Deprecation**: Mark fields as deprecated before removing them
3. **Document Versioning**: Include a version field in all documents

### Server-Side Migration Scripts

For major schema changes, use Firebase Functions:

```javascript
// Pseudocode for Firebase Function migration
exports.migrateUserProfiles = functions.https.onRequest(async (req, res) => {
  // Admin authentication check
  if (!isAuthorizedAdmin(req)) {
    return res.status(403).send('Unauthorized');
  }
  
  // Batch size to avoid timeout
  const batchSize = 100;
  
  // Get all documents that need migration
  const snapshot = await db.collection('userProfiles')
    .where('schemaVersion', '<', 2)
    .limit(batchSize)
    .get();
  
  // No documents to migrate
  if (snapshot.empty) {
    return res.status(200).send('No documents to migrate');
  }
  
  // Process batch
  const batch = db.batch();
  snapshot.docs.forEach(doc => {
    const data = doc.data();
    // Transform data
    const updatedData = {
      ...data,
      // Add new fields, transform existing ones
      pointsEarned: data.points || 0,
      schemaVersion: 2,
    };
    batch.update(doc.ref, updatedData);
  });
  
  await batch.commit();
  
  // If there are more documents, trigger another run
  if (snapshot.size === batchSize) {
    // Enqueue next batch with Cloud Tasks or similar
  }
  
  return res.status(200).send(`Migrated ${snapshot.size} documents`);
});
```

### Client-Side Migration Handling

Handle schema differences in client code:

```dart
// Pseudocode for client-side compatibility
Map<String, dynamic> ensureCompatibleUserData(Map<String, dynamic> userData) {
  final schemaVersion = userData['schemaVersion'] ?? 1;
  
  if (schemaVersion < getCurrentSchemaVersion()) {
    // Apply client-side transformations for backward compatibility
    if (schemaVersion < 2 && !userData.containsKey('pointsEarned')) {
      userData['pointsEarned'] = userData['points'] ?? 0;
    }
    
    // Add other compatibility transforms
  }
  
  return userData;
}
```

## User Data Preservation

### Backup Before Migration

Always create a backup before migrations:

```dart
// Pseudocode for backup process
Future<void> backupBoxBeforeMigration(String boxName) async {
  final box = await Hive.openBox(boxName);
  final json = box.toMap().map((key, value) => 
    MapEntry(key.toString(), _convertToJson(value)));
  
  final backupDir = await getApplicationDocumentsDirectory();
  final backupFile = File(
    '${backupDir.path}/backup_${boxName}_${DateTime.now().millisecondsSinceEpoch}.json'
  );
  
  await backupFile.writeAsString(jsonEncode(json));
  await box.close();
}

dynamic _convertToJson(dynamic value) {
  if (value is HiveObject) {
    return value.toJson();
  }
  return value;
}
```

### Data Validation

Validate migrated data to ensure integrity:

```dart
// Pseudocode for validation
Future<bool> validateMigratedData(String boxName) async {
  final box = await Hive.openBox(boxName);
  
  bool isValid = true;
  for (final key in box.keys) {
    final value = box.get(key);
    if (!_isValidForCurrentSchema(value)) {
      isValid = false;
      await _logValidationError(boxName, key, value);
    }
  }
  
  await box.close();
  return isValid;
}

bool _isValidForCurrentSchema(dynamic value) {
  // Type-specific validation logic
  if (value is WasteClassificationV2) {
    return value.itemName != null && value.wasteCategory != null;
  }
  // Other validations...
  return true;
}
```

### Recovery Process

Implement a recovery process for failed migrations:

```dart
// Pseudocode for recovery
Future<void> recoverFromBackup(String boxName, String backupPath) async {
  // Delete corrupted box
  await Hive.deleteBoxFromDisk(boxName);
  
  // Read backup
  final backupFile = File(backupPath);
  final backupJson = jsonDecode(await backupFile.readAsString());
  
  // Restore data
  final box = await Hive.openBox(boxName);
  for (final entry in backupJson.entries) {
    final key = entry.key;
    final value = _convertFromJson(entry.value);
    await box.put(key, value);
  }
  
  await box.close();
}
```

## Migration Testing

### Test Scenarios

For each migration, test these scenarios:

1. **Standard Migration Path**: Normal upgrade from previous version
2. **Skip-Version Migration**: Upgrade from several versions back
3. **Edge Cases**: Empty boxes, corrupted data, partial migrations
4. **Large Data Sets**: Test with realistic data volume

### Test Implementation Example

```dart
// Pseudocode for migration test
void testWasteClassificationMigration() async {
  // Setup test environment
  await Hive.initFlutter(getTempDirectory());
  
  // Register adapters
  Hive.registerAdapter(WasteClassificationAdapter());
  Hive.registerAdapter(WasteClassificationV2Adapter());
  
  // Create test box with old schema data
  final box = await Hive.openBox<dynamic>('test_waste_classifications');
  await box.put('test1', WasteClassification(
    itemName: 'Plastic Bottle',
    wasteCategory: 'dry waste',
    // Other fields...
  ));
  
  // Run migration
  await migrateWasteClassificationV1toV2(box);
  
  // Validate results
  final migratedItem = box.get('test1');
  expect(migratedItem, isA<WasteClassificationV2>());
  expect(migratedItem.wasteCategory, equals(WasteCategory.dryWaste));
  
  // Cleanup
  await box.close();
  await Hive.deleteBoxFromDisk('test_waste_classifications');
}
```

## Migration Deployment

### Phased Rollout

Use a phased deployment approach:

1. **Alpha Testing**: Internal team tests migration on test devices
2. **Beta Group**: Small group of real users with monitored upgrades
3. **Progressive Rollout**: Gradual increase in the percentage of users receiving the update

### User Communication

Communicate changes to users:

1. **Pre-Migration Notification**: Inform users about upcoming changes
2. **During Update**: Show progress indicator during migration
3. **Post-Migration Summary**: Confirm successful update with key changes

```dart
// Pseudocode for migration UI
Widget buildMigrationUI() {
  return StreamBuilder<MigrationProgress>(
    stream: _migrationProgressStream,
    builder: (context, snapshot) {
      final progress = snapshot.data;
      
      if (progress == null) {
        return SplashScreen(); // Normal splash
      }
      
      if (progress.isComplete) {
        return MigrationCompletedScreen(
          changesDescription: progress.changesSummary,
        );
      }
      
      return MigrationProgressScreen(
        progress: progress.percentComplete,
        currentOperation: progress.currentOperation,
      );
    },
  );
}
```

## Subscription Tier Data Handling

Special considerations for the tiered subscription approach:

### User Tier Changes

When a user changes subscription tier:

1. **Upgrade**: Extend schema with tier-specific data
2. **Downgrade**: Preserve tier-specific data but mark as inactive

```dart
// Pseudocode for tier change handling
Future<void> handleUserTierChange(
  SubscriptionTier oldTier, 
  SubscriptionTier newTier
) async {
  final userBox = await Hive.openBox('user_data');
  
  if (isUpgrade(oldTier, newTier)) {
    // Add tier-specific capabilities
    await _enableTierFeatures(userBox, newTier);
  } else {
    // Downgrade - preserve data but disable features
    await _preserveTierData(userBox, oldTier, newTier);
  }
}

Future<void> _preserveTierData(
  Box userBox, 
  SubscriptionTier oldTier, 
  SubscriptionTier newTier
) async {
  // For example, preserve Pro-level segmentation settings
  // but mark them as inactive
  if (oldTier == SubscriptionTier.pro) {
    final segSettings = userBox.get('segmentation_settings');
    if (segSettings != null) {
      await userBox.put('inactive_pro_segmentation_settings', segSettings);
    }
  }
}
```

### Offline Model Management

Handle on-device models for different tiers:

```dart
// Pseudocode for model management during tier changes
Future<void> handleModelChangesForTier(SubscriptionTier newTier) async {
  final modelManager = ModelManager();
  
  switch (newTier) {
    case SubscriptionTier.free:
      // Remove premium models to save space
      await modelManager.removeModel('enhanced_classifier');
      await modelManager.removeModel('segmentation_model');
      break;
      
    case SubscriptionTier.premium:
      // Download basic model
      await modelManager.downloadModel('basic_offline_classifier');
      // Remove pro models
      await modelManager.removeModel('advanced_classifier');
      break;
      
    case SubscriptionTier.pro:
      // Download all advanced models
      await modelManager.downloadModel('advanced_offline_classifier');
      await modelManager.downloadModel('offline_segmentation');
      break;
  }
}
```

## Conclusion

This data migration playbook provides a comprehensive approach to handling schema changes as the app evolves. By following these procedures, we can ensure smooth upgrades for users while preserving data integrity and backward compatibility.

Key practices to remember:
- Always version your data schemas
- Test migrations thoroughly before deployment
- Create backups before migrations
- Implement validation and recovery mechanisms
- Consider subscription tier implications for data

This approach supports the app's long-term evolution while minimizing disruption to users during updates.
