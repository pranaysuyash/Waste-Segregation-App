import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/cloud_storage_service.dart';
import '../services/gamification_service.dart';
import '../services/points_engine.dart';
import '../models/gamification.dart';
import '../models/user_profile.dart';

/// Central provider declarations for all services
/// This eliminates duplicate provider declarations across the app

/// Storage service provider - single source of truth
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

/// Cloud storage service provider - single source of truth  
final cloudStorageServiceProvider = Provider<CloudStorageService>((ref) {
  final storageService = ref.read(storageServiceProvider);
  return CloudStorageService(storageService);
});

/// Gamification service provider - depends on storage services
final gamificationServiceProvider = Provider<GamificationService>((ref) {
  final storageService = ref.read(storageServiceProvider);
  final cloudStorageService = ref.read(cloudStorageServiceProvider);
  return GamificationService(storageService, cloudStorageService);
});

/// Points engine provider - single source of truth for points
final pointsEngineProvider = Provider<PointsEngine>((ref) {
  final storageService = ref.read(storageServiceProvider);
  final cloudStorageService = ref.read(cloudStorageServiceProvider);
  return PointsEngine(storageService, cloudStorageService);
});

/// Points earned stream provider - for real-time popup events
final pointsEarnedProvider = StreamProvider<int>((ref) {
  final engine = ref.watch(pointsEngineProvider);
  return engine.earnedStream;
});

/// Achievement earned stream provider - for real-time celebration events
final achievementEarnedProvider = StreamProvider<Achievement>((ref) {
  final engine = ref.watch(pointsEngineProvider);
  return engine.achievementStream;
});

/// Today's goal provider - tracks daily classification progress
final todayGoalProvider = FutureProvider<(int, int)>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  final classifications = await storageService.getAllClassifications();
  
  // Count today's classifications
  final today = DateTime.now();
  final todayClassifications = classifications.where((c) {
    return c.timestamp.year == today.year &&
           c.timestamp.month == today.month &&
           c.timestamp.day == today.day;
  }).length;
  
  // Default daily goal is 10 items
  const dailyGoal = 10;
  
  return (todayClassifications, dailyGoal);
});

/// Unread notifications provider - tracks notification count
final unreadNotificationsProvider = FutureProvider<int>((ref) async {
  // For now, return 0 as notifications system is not fully implemented
  // This can be enhanced when notification system is added
  return 0;
});

/// User profile provider - for accessing user display name and other profile data
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  try {
    return await storageService.getCurrentUserProfile();
  } catch (e) {
    debugPrint('Error loading user profile: $e');
    return null;
  }
}); 