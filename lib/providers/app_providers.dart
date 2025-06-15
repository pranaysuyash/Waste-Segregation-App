import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/cloud_storage_service.dart';
import '../services/gamification_service.dart';

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