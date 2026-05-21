import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waste_segregation_app/models/educational_content.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/services/ad_service.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/services/analytics_consent_manager.dart';
import 'package:waste_segregation_app/services/analytics_schema_validator.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/services/educational_content_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/points_engine.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/training_data_service.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';
import 'package:waste_segregation_app/utils/firebase_gate.dart';
import 'cost_management_providers.dart';

/// Central provider declarations for all services
/// This eliminates duplicate provider declarations across the app

/// Storage service provider - single source of truth
final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

/// Cloud storage service provider - single source of truth
final cloudStorageServiceProvider = Provider<CloudStorageService>((ref) {
  final storageService = ref.read(storageServiceProvider);
  return CloudStorageService(storageService);
});

/// Consent-gated training data pipeline provider.
final trainingDataServiceProvider = Provider<TrainingDataService>((ref) {
  final storageService = ref.read(storageServiceProvider);
  return TrainingDataService(storageService: storageService);
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
  return PointsEngine.getInstance(storageService, cloudStorageService);
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
    WasteAppLogger.severe('Error loading user profile',
        error: e, context: {'action': 'return_default_profile'});
    return null;
  }
});

/// Educational content service provider - single source of truth
final educationalContentServiceProvider =
    Provider<EducationalContentService>((ref) => EducationalContentService());

/// Daily learning tip provider — deterministic per day, category-aware.
///
/// If the user has scanned a category recently, the tip will prefer
/// related content. The tip is stable for the entire calendar day and
/// only changes across days.
final dailyLearningTipProvider = Provider<DailyTip>((ref) {
  final service = ref.watch(educationalContentServiceProvider);
  return service.getDailyTip();
});

/// Ad service provider - single source of truth
final adServiceProvider = Provider<AdService>((ref) => AdService());

/// Analytics service provider - single source of truth
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final storageService = ref.read(storageServiceProvider);
  return AnalyticsService(
    storageService,
    enableFirestore: isFirebaseEnabled,
  );
});

/// Analytics consent manager provider - for GDPR/CCPA compliance
final analyticsConsentManagerProvider =
    Provider<AnalyticsConsentManager>((ref) => AnalyticsConsentManager());

/// Analytics schema validator provider - for event validation
final analyticsSchemaValidatorProvider =
    Provider<AnalyticsSchemaValidator>((ref) => AnalyticsSchemaValidator());

/// Gamification profile provider - for accessing current user's gamification data
final profileProvider = FutureProvider<GamificationProfile?>((ref) async {
  final gamificationService = ref.watch(gamificationServiceProvider);
  try {
    return await gamificationService.getProfile();
  } catch (e) {
    WasteAppLogger.severe('Error loading gamification profile',
        error: e, context: {'action': 'return_null_profile'});
    return null;
  }
});

/// Home header v2 feature flag provider for A/B testing
final homeHeaderV2EnabledProvider = FutureProvider<bool>((ref) async {
  final remoteConfig = ref.watch(remoteConfigServiceProvider);
  return remoteConfig.getBool('home_header_v2_enabled', defaultValue: true);
});

/// Enhanced Ai service provider with cost management integration
final aiServiceProvider = Provider<AiService>((ref) {
  final pricingService = ref.read(dynamicPricingServiceProvider);
  final guardrailService = ref.read(costGuardrailServiceProvider);
  final errorHandler = ref.read(enhancedApiErrorHandlerProvider);

  return AiService(
    pricingService: pricingService,
    guardrailService: guardrailService,
    errorHandler: errorHandler,
  );
});
