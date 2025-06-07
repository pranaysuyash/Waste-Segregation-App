import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  debugPrint('🎮 DEBUG: Starting gamification debug...');
  
  try {
    // Initialize services
    await StorageService.initializeHive();
    final storageService = StorageService();
    
    final cloudStorageService = CloudStorageService(storageService);
    final gamificationService = GamificationService(storageService, cloudStorageService);
    
    await gamificationService.initGamification();
    
    debugPrint('🎮 DEBUG: Services initialized');
    
    // Get current profile
    final profileBefore = await gamificationService.getProfile();
    debugPrint('🎮 DEBUG: Current points: ${profileBefore.points.total}');
    debugPrint('🎮 DEBUG: Current level: ${profileBefore.points.level}');
    debugPrint('🎮 DEBUG: Category points: ${profileBefore.points.categoryPoints}');
    
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
    
    debugPrint('🎮 DEBUG: Created test classification: ${testClassification.itemName}');
    
    // Process the classification
    debugPrint('🎮 DEBUG: Processing classification...');
    await gamificationService.processClassification(testClassification);
    
    // Get updated profile
    final profileAfter = await gamificationService.getProfile();
    debugPrint('🎮 DEBUG: Points after processing: ${profileAfter.points.total}');
    debugPrint('🎮 DEBUG: Level after processing: ${profileAfter.points.level}');
    debugPrint('🎮 DEBUG: Category points after: ${profileAfter.points.categoryPoints}');
    
    final pointsEarned = profileAfter.points.total - profileBefore.points.total;
    debugPrint('🎮 DEBUG: Points earned: $pointsEarned');
    
    if (pointsEarned > 0) {
      debugPrint('✅ SUCCESS: Points were awarded correctly!');
    } else {
      debugPrint('❌ ISSUE: No points were awarded');
    }
    
    // Test cloud storage service gamification processing
    debugPrint('🎮 DEBUG: Testing CloudStorageService gamification...');
    await cloudStorageService.saveClassificationWithSync(
      testClassification.copyWith(itemName: 'Test Cloud Classification'),
      false, // No Google sync for test
    );
    
    final profileAfterCloud = await gamificationService.getProfile();
    final cloudPointsEarned = profileAfterCloud.points.total - profileAfter.points.total;
    debugPrint('🎮 DEBUG: Points earned from cloud service: $cloudPointsEarned');
    
  } catch (e, stackTrace) {
    debugPrint('❌ ERROR: $e');
    debugPrint('Stack trace: $stackTrace');
  }
  
  debugPrint('🎮 DEBUG: Debug complete');
  exit(0);
} 