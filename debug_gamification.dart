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
  
  print('🎮 DEBUG: Starting gamification debug...');
  
  try {
    // Initialize services
    await StorageService.initializeHive();
    final storageService = StorageService();
    
    final cloudStorageService = CloudStorageService(storageService);
    final gamificationService = GamificationService(storageService, cloudStorageService);
    
    await gamificationService.initGamification();
    
    print('🎮 DEBUG: Services initialized');
    
    // Get current profile
    final profileBefore = await gamificationService.getProfile();
    print('🎮 DEBUG: Current points: ${profileBefore.points.total}');
    print('🎮 DEBUG: Current level: ${profileBefore.points.level}');
    print('🎮 DEBUG: Category points: ${profileBefore.points.categoryPoints}');
    
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
    
    print('🎮 DEBUG: Created test classification: ${testClassification.itemName}');
    
    // Process the classification
    print('🎮 DEBUG: Processing classification...');
    await gamificationService.processClassification(testClassification);
    
    // Get updated profile
    final profileAfter = await gamificationService.getProfile();
    print('🎮 DEBUG: Points after processing: ${profileAfter.points.total}');
    print('🎮 DEBUG: Level after processing: ${profileAfter.points.level}');
    print('🎮 DEBUG: Category points after: ${profileAfter.points.categoryPoints}');
    
    final pointsEarned = profileAfter.points.total - profileBefore.points.total;
    print('🎮 DEBUG: Points earned: $pointsEarned');
    
    if (pointsEarned > 0) {
      print('✅ SUCCESS: Points were awarded correctly!');
    } else {
      print('❌ ISSUE: No points were awarded');
    }
    
    // Test cloud storage service gamification processing
    print('🎮 DEBUG: Testing CloudStorageService gamification...');
    await cloudStorageService.saveClassificationWithSync(
      testClassification.copyWith(itemName: 'Test Cloud Classification'),
      false, // No Google sync for test
    );
    
    final profileAfterCloud = await gamificationService.getProfile();
    final cloudPointsEarned = profileAfterCloud.points.total - profileAfter.points.total;
    print('🎮 DEBUG: Points earned from cloud service: $cloudPointsEarned');
    
  } catch (e, stackTrace) {
    print('❌ ERROR: $e');
    print('Stack trace: $stackTrace');
  }
  
  print('🎮 DEBUG: Debug complete');
  exit(0);
} 