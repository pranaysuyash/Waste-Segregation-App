import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  await WasteAppLogger.initialize();
  WasteAppLogger.info('🎮 DEBUG: Starting gamification debug...', null, null, {
    'debug_type': 'gamification',
    'mode': 'temp_script'
  });
  
  try {
    // Initialize services
    await StorageService.initializeHive();
    final storageService = StorageService();
    
    final cloudStorageService = CloudStorageService(storageService);
    final gamificationService = GamificationService(storageService, cloudStorageService);
    
    await gamificationService.initGamification();
    
    WasteAppLogger.info('🎮 DEBUG: Services initialized', null, null, {
      'services': ['storage', 'cloud_storage', 'gamification']
    });
    
    // Get current profile
    final profileBefore = await gamificationService.getProfile();
    WasteAppLogger.gamificationEvent('profile_status_before', context: {
      'points_total': profileBefore.points.total,
      'level': profileBefore.points.level,
      'category_points': profileBefore.points.categoryPoints
    });
    
    // Create a test classification
    final testClassification = WasteClassification(
      itemName: 'Test Plastic Bottle',
      category: 'Dry Waste',
      subcategory: 'Plastic',
      explanation: 'Test classification for debugging',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Recycle',
        steps: ['Test step'],
        hasUrgentTimeframe: false,
      ),
      timestamp: DateTime.now(),
      region: 'Test Region',
      visualFeatures: [],
      alternatives: [],
    );
    
    WasteAppLogger.wasteEvent('test_classification_created', testClassification.category, context: {
      'item_name': testClassification.itemName,
      'subcategory': testClassification.subcategory
    });
    
    // Process the classification
    WasteAppLogger.gamificationEvent('processing_classification', context: {
      'classification_id': testClassification.itemName
    });
    await gamificationService.processClassification(testClassification);
    
    // Get updated profile
    final profileAfter = await gamificationService.getProfile();
    final pointsEarned = profileAfter.points.total - profileBefore.points.total;
    WasteAppLogger.gamificationEvent('classification_processed', pointsEarned: pointsEarned, context: {
      'points_before': profileBefore.points.total,
      'points_after': profileAfter.points.total,
      'level_before': profileBefore.points.level,
      'level_after': profileAfter.points.level,
      'category_points_after': profileAfter.points.categoryPoints
    });
    
    if (pointsEarned > 0) {
      WasteAppLogger.gamificationEvent('points_verification_success', pointsEarned: pointsEarned);
    } else {
      WasteAppLogger.severe('Points verification failed', null, null, {
        'expected_points': '>0',
        'actual_points': pointsEarned
      });
    }
    
    // Test cloud storage service gamification processing
    WasteAppLogger.info('Testing CloudStorageService gamification...', null, null, {
      'test_type': 'cloud_storage_gamification'
    });
    await cloudStorageService.saveClassificationWithSync(
      testClassification.copyWith(itemName: 'Test Cloud Classification'),
      false, // No Google sync for test
    );
    
    final profileAfterCloud = await gamificationService.getProfile();
    final cloudPointsEarned = profileAfterCloud.points.total - profileAfter.points.total;
    WasteAppLogger.gamificationEvent('cloud_points_earned', pointsEarned: cloudPointsEarned, context: {
      'service_type': 'cloud_storage'
    });
    
  } catch (e, stackTrace) {
    WasteAppLogger.severe('Gamification debug error', e, stackTrace, {
      'debug_type': 'gamification_temp_script'
    });
  }
  
  WasteAppLogger.info('🎮 DEBUG: Debug complete', null, null, {
    'debug_session': 'gamification_completed'
  });
  exit(0);
} 