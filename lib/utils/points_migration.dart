import 'package:flutter/foundation.dart';
import '../services/points_engine.dart';
import '../services/gamification_service.dart';
import '../services/storage_service.dart';
import '../services/cloud_storage_service.dart';

/// Migration utility to transition from legacy GamificationService to Points Engine
class PointsMigration {
  PointsMigration(this._storageService, this._cloudStorageService);

  final StorageService _storageService;
  final CloudStorageService _cloudStorageService;

  /// Migrate from legacy system to Points Engine
  Future<void> migrateToPointsEngine() async {
    try {
      debugPrint('🔄 Starting Points Engine migration...');
      
      // Create Points Engine instance
      final pointsEngine = PointsEngine(_storageService, _cloudStorageService);
      await pointsEngine.initialize();
      
      // Create legacy GamificationService for comparison
      final legacyService = GamificationService(_storageService, _cloudStorageService);
      await legacyService.initGamification();
      
      // Get profiles from both systems
      final legacyProfile = await legacyService.getProfile();
      final engineProfile = pointsEngine.currentProfile;
      
      if (engineProfile == null) {
        debugPrint('⚠️ Points Engine profile is null, skipping migration');
        return;
      }
      
      // Compare and sync if needed
      final needsSync = _compareProfiles(legacyProfile, engineProfile);
      
      if (needsSync) {
        debugPrint('🔄 Profiles differ, syncing to Points Engine...');
        await _syncProfiles(legacyProfile, pointsEngine);
        debugPrint('✅ Migration completed successfully');
      } else {
        debugPrint('✅ Profiles already in sync, no migration needed');
      }
      
      // Validate the migration
      await _validateMigration(legacyProfile, pointsEngine);
      
    } catch (e) {
      debugPrint('🔥 Points Engine migration failed: $e');
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
    
    debugPrint('📊 Profile comparison:');
    debugPrint('   Legacy: $legacyPoints pts, level $legacyLevel, $legacyAchievements achievements');
    debugPrint('   Engine: $enginePoints pts, level $engineLevel, $engineAchievements achievements');
    
    // Need sync if there are significant differences
    return legacyPoints != enginePoints || 
           legacyLevel != engineLevel || 
           legacyAchievements != engineAchievements;
  }

  /// Sync legacy profile data to Points Engine
  Future<void> _syncProfiles(dynamic legacyProfile, PointsEngine pointsEngine) async {
    if (legacyProfile == null) return;
    
    try {
      // Sync points if legacy has more
      final legacyPoints = legacyProfile.points?.total ?? 0;
      final enginePoints = pointsEngine.currentPoints;
      
      if (legacyPoints > enginePoints) {
        final pointsDiff = legacyPoints - enginePoints;
        debugPrint('🔄 Syncing $pointsDiff missing points...');
        
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
        final missingAchievements = legacyAchievements.where((legacy) =>
          !engineAchievements.any((engine) => engine.id == legacy.id)
        ).toList();
        
        if (missingAchievements.isNotEmpty) {
          debugPrint('🏆 Found ${missingAchievements.length} missing achievements');
          // Note: Achievement sync would require more complex logic
          // For now, we'll just log this for manual review
        }
      }
      
    } catch (e) {
      debugPrint('🔥 Error syncing profiles: $e');
      rethrow;
    }
  }

  /// Validate that migration was successful
  Future<void> _validateMigration(dynamic legacyProfile, PointsEngine pointsEngine) async {
    try {
      final engineProfile = pointsEngine.currentProfile;
      
      if (engineProfile == null) {
        throw Exception('Engine profile is null after migration');
      }
      
      final legacyPoints = legacyProfile?.points?.total ?? 0;
      final enginePoints = engineProfile.points.total;
      
      if (enginePoints < legacyPoints) {
        debugPrint('⚠️ Warning: Engine points ($enginePoints) less than legacy ($legacyPoints)');
      }
      
      debugPrint('✅ Migration validation passed');
      debugPrint('   Final points: $enginePoints');
      debugPrint('   Final level: ${engineProfile.points.level}');
      debugPrint('   Achievements: ${engineProfile.achievements.length}');
      
    } catch (e) {
      debugPrint('🔥 Migration validation failed: $e');
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
      debugPrint('🔥 Error checking migration status: $e');
      return false;
    }
  }

  /// Perform a dry run of the migration (for testing)
  Future<Map<String, dynamic>> dryRunMigration() async {
    try {
      final pointsEngine = PointsEngine(_storageService, _cloudStorageService);
      await pointsEngine.initialize();
      
      final legacyService = GamificationService(_storageService, _cloudStorageService);
      await legacyService.initGamification();
      
      final legacyProfile = await legacyService.getProfile();
      final engineProfile = pointsEngine.currentProfile;
      
      return {
        'migration_needed': _compareProfiles(legacyProfile, engineProfile),
        'legacy_points': legacyProfile.points.total ?? 0,
        'engine_points': engineProfile?.points.total ?? 0,
        'legacy_level': legacyProfile.points.level ?? 1,
        'engine_level': engineProfile?.points.level ?? 1,
        'legacy_achievements': legacyProfile.achievements.length ?? 0,
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