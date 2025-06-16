import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/cloud_storage_service.dart';
import '../services/gamification_service.dart';
import '../services/points_engine.dart';
import '../models/gamification.dart';

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