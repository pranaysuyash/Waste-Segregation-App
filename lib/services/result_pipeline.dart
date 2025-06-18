import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/waste_classification.dart';
import '../models/gamification.dart';
import '../services/storage_service.dart';
import '../services/gamification_service.dart';
import '../services/cloud_storage_service.dart';
import '../services/community_service.dart';
import '../services/ad_service.dart';
import '../utils/waste_app_logger.dart';
import '../providers/app_providers.dart';

/// Pipeline state for tracking the result processing
class ResultPipelineState {
  final bool isProcessing;
  final String? error;
  final int pointsEarned;
  final List<Achievement> newAchievements;
  final Challenge? completedChallenge;
  final bool isSaved;

  const ResultPipelineState({
    this.isProcessing = false,
    this.error,
    this.pointsEarned = 0,
    this.newAchievements = const [],
    this.completedChallenge,
    this.isSaved = false,
  });

  ResultPipelineState copyWith({
    bool? isProcessing,
    String? error,
    int? pointsEarned,
    List<Achievement>? newAchievements,
    Challenge? completedChallenge,
    bool? isSaved,
  }) {
    return ResultPipelineState(
      isProcessing: isProcessing ?? this.isProcessing,
      error: error ?? this.error,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      newAchievements: newAchievements ?? this.newAchievements,
      completedChallenge: completedChallenge ?? this.completedChallenge,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

/// ResultPipeline handles all business logic for processing waste classifications
/// This separates concerns from the UI and makes the system more testable
class ResultPipeline extends StateNotifier<ResultPipelineState> {
  final StorageService _storageService;
  final GamificationService _gamificationService;
  final CloudStorageService _cloudStorageService;
  final CommunityService _communityService;
  final AdService _adService;
  final Ref _ref;

  // Track classifications being processed to prevent duplicates
  static final Set<String> _processingClassifications = <String>{};

  ResultPipeline(
    this._ref,
    this._storageService,
    this._gamificationService,
    this._cloudStorageService,
    this._communityService,
    this._adService,
  ) : super(const ResultPipelineState());

  /// Main pipeline execution - processes classification through all stages
  Future<void> processClassification(
    WasteClassification classification, {
    bool force = false,
    bool autoAnalyze = false,
  }) async {
    final classificationId = classification.id;
    
    // Prevent duplicate processing
    if (_processingClassifications.contains(classificationId) && !force) {
             WasteAppLogger.warning('Classification already being processed', null, null, {
         'classificationId': classificationId,
         'service': 'ResultPipeline',
       });
      return;
    }

    _processingClassifications.add(classificationId);
    state = state.copyWith(isProcessing: true, error: null);

    try {
      // Stage 1: Save classification locally
      WasteAppLogger.info('Starting classification processing pipeline', null, null, {
        'classificationId': classificationId,
        'stage': 'local_save',
        'service': 'ResultPipeline',
      });

      final savedClassification = classification.copyWith(isSaved: true);
      await _storageService.saveClassification(savedClassification, force: force);

      // Stage 2: Process gamification (points, achievements, challenges)
      WasteAppLogger.info('Processing gamification', null, null, {
        'classificationId': classificationId,
        'stage': 'gamification',
        'service': 'ResultPipeline',
      });

      final oldProfile = await _gamificationService.getProfile();
      await _gamificationService.processClassification(savedClassification);
      final newProfile = await _gamificationService.getProfile(forceRefresh: true);

      // Calculate deltas
      final pointsEarned = newProfile.points.total - oldProfile.points.total;
      final oldAchievementIds = oldProfile.achievements.map((a) => a.id).toSet();
      final newlyEarnedAchievements = newProfile.achievements
          .where((a) => a.isEarned && !oldAchievementIds.contains(a.id))
          .toList();
      
      final completedChallenge = newProfile.completedChallenges
          .where((c) => !oldProfile.completedChallenges.map((oc) => oc.id).contains(c.id))
          .firstOrNull;

      // Stage 3: Cloud sync (if enabled)
      final settings = await _storageService.getSettings();
      final isGoogleSyncEnabled = settings['isGoogleSyncEnabled'] ?? false;
      
              if (isGoogleSyncEnabled) {
        WasteAppLogger.info('Syncing to cloud', null, null, {
          'classificationId': classificationId,
          'stage': 'cloud_sync',
          'service': 'ResultPipeline',
        });

        await _cloudStorageService.saveClassificationWithSync(
          savedClassification,
          isGoogleSyncEnabled,
          processGamification: false, // Already processed
        );
        await _gamificationService.saveProfile(newProfile);
      }

      // Stage 4: Community post (if opted-in)
      final shareToFeed = settings['shareToFeed'] ?? false;
      if (shareToFeed && !autoAnalyze) {
        WasteAppLogger.info('Posting to community feed', null, null, {
          'classificationId': classificationId,
          'stage': 'community_post',
          'service': 'ResultPipeline',
        });

        try {
          // Use recordClassification instead of postToFeed
          final userProfile = await _storageService.getCurrentUserProfile();
          if (userProfile != null) {
            await _communityService.recordClassification(savedClassification, userProfile);
          }
        } catch (e) {
          // Community posting is non-critical, log but don't fail
          WasteAppLogger.warning('Community post failed', e, null, {
            'classificationId': classificationId,
            'service': 'ResultPipeline',
          });
        }
      }

      // Stage 5: Maybe show interstitial ad
      _maybeShowInterstitial();

      // Update state with results
      state = state.copyWith(
        isProcessing: false,
        pointsEarned: pointsEarned,
        newAchievements: newlyEarnedAchievements,
        completedChallenge: completedChallenge,
        isSaved: true,
      );

      WasteAppLogger.info('Classification processing pipeline completed', null, null, {
        'classificationId': classificationId,
        'pointsEarned': pointsEarned,
        'achievementsEarned': newlyEarnedAchievements.length,
        'service': 'ResultPipeline',
      });

    } catch (error, stackTrace) {
      WasteAppLogger.severe('Classification processing pipeline failed', error, stackTrace, {
        'classificationId': classificationId,
        'service': 'ResultPipeline',
      });

      state = state.copyWith(
        isProcessing: false,
        error: error.toString(),
      );
    } finally {
      _processingClassifications.remove(classificationId);
    }
  }

  /// Maybe show interstitial ad based on classification count
  void _maybeShowInterstitial() {
    try {
      if (_adService.shouldShowInterstitial()) {
        _adService.showInterstitialAd();
      }
    } catch (e) {
      // Ad showing is non-critical
      WasteAppLogger.warning('Failed to show interstitial ad', e, null, {
        'service': 'ResultPipeline',
      });
    }
  }

  /// Reset the pipeline state
  void reset() {
    state = const ResultPipelineState();
  }
}

// Community service provider (if not already defined elsewhere)
final communityServiceProvider = Provider<CommunityService>((ref) => CommunityService());

/// Provider for the ResultPipeline
final resultPipelineProvider = StateNotifierProvider<ResultPipeline, ResultPipelineState>((ref) {
  final storageService = ref.read(storageServiceProvider);
  final gamificationService = ref.read(gamificationServiceProvider);
  final cloudStorageService = ref.read(cloudStorageServiceProvider);
  final communityService = ref.read(communityServiceProvider);
  final adService = ref.read(adServiceProvider);

  return ResultPipeline(
    ref,
    storageService,
    gamificationService,
    cloudStorageService,
    communityService,
    adService,
  );
});

// Convenience providers for accessing specific parts of the pipeline state
final resultPipelinePointsProvider = Provider<int>((ref) {
  return ref.watch(resultPipelineProvider).pointsEarned;
});

final resultPipelineAchievementsProvider = Provider<List<Achievement>>((ref) {
  return ref.watch(resultPipelineProvider).newAchievements;
});

final resultPipelineIsProcessingProvider = Provider<bool>((ref) {
  return ref.watch(resultPipelineProvider).isProcessing;
}); 