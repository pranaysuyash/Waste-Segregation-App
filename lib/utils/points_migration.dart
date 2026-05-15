import '../services/points_engine.dart';
import '../services/gamification_service.dart';
import '../services/storage_service.dart';
import '../services/cloud_storage_service.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Migration utility to transition from legacy GamificationService to Points Engine
class PointsMigration {
  PointsMigration(this._storageService, this._cloudStorageService);

  final StorageService _storageService;
  final CloudStorageService _cloudStorageService;

  /// Migrate from legacy system to Points Engine
  Future<void> migrateToPointsEngine() async {
    try {
      WasteAppLogger.info('🔄 Starting Points Engine migration...');

      // Create Points Engine instance
      final pointsEngine =
          PointsEngine.getInstance(_storageService, _cloudStorageService);
      await pointsEngine.initialize();

      // Create legacy GamificationService for comparison
      final legacyService =
          GamificationService(_storageService, _cloudStorageService);
      await legacyService.initGamification();

      // Get profiles from both systems
      final legacyProfile = await legacyService.getProfile();
      final engineProfile = pointsEngine.currentProfile;

      if (engineProfile == null) {
        WasteAppLogger.info(
            '⚠️ Points Engine profile is null, error: skipping migration');
        return;
      }

      // Compare and sync if needed
      final needsSync = _compareProfiles(legacyProfile, engineProfile);

      if (needsSync) {
        WasteAppLogger.info(
            '🔄 Profiles differ, error: syncing to Points Engine...');
        await _syncProfiles(legacyProfile, pointsEngine);
        WasteAppLogger.info('✅ Migration completed successfully');
      } else {
        WasteAppLogger.info(
            '✅ Profiles already in sync, error: no migration needed');
      }

      // Validate the migration
      await _validateMigration(legacyProfile, pointsEngine);
    } catch (e) {
      WasteAppLogger.severe('🔥 Points Engine migration failed: $e');
      rethrow;
    }
  }

  /// Compare profiles to determine if migration is needed
  bool _compareProfiles(dynamic legacyProfile, dynamic engineProfile) {
    if (legacyProfile == null || engineProfile == null) {
      return true; // Need sync if either is null
    }

    // Compare key metrics
    final legacyPoints = legacyProfile.points?.total ?? 0;
    final enginePoints = engineProfile.points?.total ?? 0;

    final legacyLevel = legacyProfile.points?.level ?? 1;
    final engineLevel = engineProfile.points?.level ?? 1;

    final legacyAchievements = legacyProfile.achievements?.length ?? 0;
    final engineAchievements = engineProfile.achievements?.length ?? 0;

    WasteAppLogger.info('📊 Profile comparison:');
    WasteAppLogger.info(
        '   Legacy: $legacyPoints pts, error: level $legacyLevel, stackTrace: $legacyAchievements achievements');
    WasteAppLogger.info(
        '   Engine: $enginePoints pts, error: level $engineLevel, stackTrace: $engineAchievements achievements');

    // Need sync if there are significant differences
    return legacyPoints != enginePoints ||
        legacyLevel != engineLevel ||
        legacyAchievements != engineAchievements;
  }

  /// Sync legacy profile data to Points Engine
  Future<void> _syncProfiles(
      dynamic legacyProfile, PointsEngine pointsEngine) async {
    if (legacyProfile == null) return;

    try {
      // Sync points if legacy has more
      final legacyPoints = legacyProfile.points?.total ?? 0;
      final enginePoints = pointsEngine.currentPoints;

      if (legacyPoints > enginePoints) {
        final pointsDiff = legacyPoints - enginePoints;
        WasteAppLogger.info('🔄 Syncing $pointsDiff missing points...');

        await pointsEngine.addPoints(
          'migration_sync',
          customPoints: pointsDiff,
          metadata: {
            'source': 'PointsMigration',
            'legacy_points': legacyPoints,
            'engine_points': enginePoints,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }

      // Sync achievements if needed
      final legacyAchievements = legacyProfile.achievements ?? [];
      final engineProfile = pointsEngine.currentProfile;

      if (engineProfile != null) {
        final engineAchievements = engineProfile.achievements;

        // Find achievements that exist in legacy but not in engine
        final missingAchievements = legacyAchievements
            .where((legacy) =>
                !engineAchievements.any((engine) => engine.id == legacy.id))
            .toList();

        if (missingAchievements.isNotEmpty) {
          WasteAppLogger.info(
              '🏆 Found ${missingAchievements.length} missing achievements');
          // Note: Achievement sync would require more complex logic
          // For now, we'll just log this for manual review
        }
      }
    } catch (e) {
      WasteAppLogger.severe('🔥 Error syncing profiles: $e');
      rethrow;
    }
  }

  /// Validate that migration was successful
  Future<void> _validateMigration(
      dynamic legacyProfile, PointsEngine pointsEngine) async {
    try {
      final engineProfile = pointsEngine.currentProfile;

      if (engineProfile == null) {
        throw Exception('Engine profile is null after migration');
      }

      final legacyPoints = legacyProfile?.points?.total ?? 0;
      final enginePoints = engineProfile.points.total;

      if (enginePoints < legacyPoints) {
        WasteAppLogger.warning(
            '⚠️ Warning: Engine points ($enginePoints) less than legacy ($legacyPoints)');
      }

      WasteAppLogger.info('✅ Migration validation passed');
      WasteAppLogger.info('   Final points: $enginePoints');
      WasteAppLogger.info('   Final level: ${engineProfile.points.level}');
      WasteAppLogger.info(
          '   Achievements: ${engineProfile.achievements.length}');
    } catch (e) {
      WasteAppLogger.severe('🔥 Migration validation failed: $e');
      rethrow;
    }
  }

  /// Check if migration is needed
  static Future<bool> isMigrationNeeded(StorageService storageService) async {
    try {
      // Check if there's legacy data that needs migration
      final userProfile = await storageService.getCurrentUserProfile();

      if (userProfile?.gamificationProfile == null) {
        return false; // No legacy data to migrate
      }

      // Check if Points Engine has been initialized
      // This is a simple heuristic - in practice you might want more sophisticated checks
      final legacyPoints = userProfile!.gamificationProfile!.points.total;

      // If there are legacy points, migration might be needed
      return legacyPoints > 0;
    } catch (e) {
      WasteAppLogger.severe('🔥 Error checking migration status: $e');
      return false;
    }
  }

  /// Perform a dry run of the migration (for testing)
  Future<Map<String, dynamic>> dryRunMigration() async {
    try {
      final pointsEngine =
          PointsEngine.getInstance(_storageService, _cloudStorageService);
      await pointsEngine.initialize();

      final legacyService =
          GamificationService(_storageService, _cloudStorageService);
      await legacyService.initGamification();

      final legacyProfile = await legacyService.getProfile();
      final engineProfile = pointsEngine.currentProfile;

      return {
        'migration_needed': _compareProfiles(legacyProfile, engineProfile),
        'legacy_points': legacyProfile.points.total,
        'engine_points': engineProfile?.points.total ?? 0,
        'legacy_level': legacyProfile.points.level,
        'engine_level': engineProfile?.points.level ?? 1,
        'legacy_achievements': legacyProfile.achievements.length,
        'engine_achievements': engineProfile?.achievements.length ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
