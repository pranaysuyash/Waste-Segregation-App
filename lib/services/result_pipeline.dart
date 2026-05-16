import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../models/gamification.dart';
import '../models/classification_feedback.dart';
import '../services/storage_service.dart';
import '../services/gamification_service.dart';
import '../services/cloud_storage_service.dart';
import '../services/community_service.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import '../services/dynamic_link_service.dart';
import '../utils/share_service.dart';
import '../utils/waste_app_logger.dart';
import '../utils/error_handler.dart';
import '../providers/app_providers.dart';

/// Result of a feedback submission, carrying outcome details for the UI.
class FeedbackResult {
  const FeedbackResult({
    required this.saved,
    required this.pointsAwarded,
    required this.nominalPoints,
    required this.wasDuplicate,
    required this.cloudSynced,
  });

  /// Whether the feedback was saved successfully.
  final bool saved;

  /// Points actually awarded for this action. 0 on duplicate.
  final int pointsAwarded;

  /// The nominal point value for this action type (e.g. 5 or 10),
  /// regardless of whether points were actually awarded.
  /// UI can use this for context even on duplicate.
  final int nominalPoints;

  /// True if this was a duplicate submission (feedback already existed).
  final bool wasDuplicate;

  /// Whether the feedback was successfully synced to Firestore.
  final bool cloudSynced;
}

/// Pipeline state for tracking the result processing
class ResultPipelineState {
  const ResultPipelineState({
    this.isProcessing = false,
    this.error,
    this.pointsEarned = 0,
    this.newAchievements = const [],
    this.completedChallenge,
    this.isSaved = false,
  });
  final bool isProcessing;
  final String? error;
  final int pointsEarned;
  final List<Achievement> newAchievements;
  final Challenge? completedChallenge;
  final bool isSaved;

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
  ResultPipeline(
    this._storageService,
    this._gamificationService,
    this._cloudStorageService,
    this._communityService,
    this._adService,
    this._analyticsService,
  ) : super(const ResultPipelineState());
  final StorageService _storageService;
  final GamificationService _gamificationService;
  final CloudStorageService _cloudStorageService;
  final CommunityService _communityService;
  final AdService _adService;
  final AnalyticsService _analyticsService;

  // Track classifications being processed to prevent duplicates
  static final Set<String> _processingClassifications = <String>{};

  /// Main pipeline execution - processes classification through all stages
  Future<void> processClassification(
    WasteClassification classification, {
    bool force = false,
    bool autoAnalyze = false,
  }) async {
    final classificationId = classification.id;

    // Prevent duplicate processing
    if (_processingClassifications.contains(classificationId) && !force) {
      WasteAppLogger.warning('Classification already being processed',
          context: {
            'classificationId': classificationId,
            'service': 'ResultPipeline',
          });
      return;
    }

    _processingClassifications.add(classificationId);
    state = state.copyWith(isProcessing: true);

    try {
      // Stage 1: Save classification locally
      WasteAppLogger.info('Starting classification processing pipeline',
          context: {
            'classificationId': classificationId,
            'stage': 'local_save',
            'service': 'ResultPipeline',
          });

      final savedClassification = classification.copyWith(isSaved: true);
      await _storageService.saveClassification(savedClassification,
          force: force);

      // Stage 2: Process gamification (points, achievements, challenges)
      WasteAppLogger.info('Processing gamification', context: {
        'classificationId': classificationId,
        'stage': 'gamification',
        'service': 'ResultPipeline',
      });

      final oldProfile = await _gamificationService.getProfile();
      await _gamificationService.processClassification(savedClassification);
      final newProfile =
          await _gamificationService.getProfile(forceRefresh: true);

      // Calculate deltas
      final pointsEarned = newProfile.points.total - oldProfile.points.total;
      final oldAchievementIds =
          oldProfile.achievements.map((a) => a.id).toSet();
      final newlyEarnedAchievements = newProfile.achievements
          .where((a) => a.isEarned && !oldAchievementIds.contains(a.id))
          .toList();

      final completedChallenge = newProfile.completedChallenges
          .where((c) =>
              !oldProfile.completedChallenges.map((oc) => oc.id).contains(c.id))
          .firstOrNull;

      // Stage 3: Cloud sync (if enabled)
      final settings = await _storageService.getSettings();
      final isGoogleSyncEnabled = settings['isGoogleSyncEnabled'] ?? false;

      if (isGoogleSyncEnabled) {
        WasteAppLogger.info('Syncing to cloud', context: {
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
        WasteAppLogger.info('Posting to community feed', context: {
          'classificationId': classificationId,
          'stage': 'community_post',
          'service': 'ResultPipeline',
        });

        try {
          // Use recordClassification instead of postToFeed
          final userProfile = await _storageService.getCurrentUserProfile();
          if (userProfile != null) {
            await _communityService.recordClassification(
                savedClassification, userProfile);
          }
        } catch (e) {
          // Community posting is non-critical, log but don't fail
          WasteAppLogger.warning('Community post failed', error: e, context: {
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

      WasteAppLogger.info('Classification processing pipeline completed',
          context: {
            'classificationId': classificationId,
            'pointsEarned': pointsEarned,
            'achievementsEarned': newlyEarnedAchievements.length,
            'service': 'ResultPipeline',
          });
    } catch (error, stackTrace) {
      WasteAppLogger.severe('Classification processing pipeline failed',
          error: error,
          stackTrace: stackTrace,
          context: {
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
      WasteAppLogger.warning('Failed to show interstitial ad',
          error: e,
          context: {
            'service': 'ResultPipeline',
          });
    }
  }

  /// Track analytics events for result screen
  Future<void> trackScreenView(WasteClassification classification) async {
    try {
      await _analyticsService.trackScreenView('ResultScreen', parameters: {
        'classification_id': classification.id,
        'category': classification.category,
        'item_name': classification.itemName,
        'confidence': classification.confidence,
      });
    } catch (e) {
      WasteAppLogger.warning('Failed to track screen view', error: e, context: {
        'service': 'ResultPipeline',
      });
    }
  }

  /// Track user action analytics
  Future<void> trackUserAction(
      String action, WasteClassification classification) async {
    try {
      await _analyticsService.trackUserAction(action, parameters: {
        'category': classification.category,
        'item': classification.itemName,
      });
    } catch (e) {
      WasteAppLogger.warning('Failed to track user action', error: e, context: {
        'action': action,
        'service': 'ResultPipeline',
      });
    }
  }

  /// Share classification result with dynamic link
  Future<String> shareClassification(WasteClassification classification) async {
    try {
      await trackUserAction('classification_share', classification);

      final link = DynamicLinkService.createResultLink(classification);
      final shareText =
          'I identified ${classification.itemName} as ${classification.category} waste using the Waste Segregation app!\n$link';

      await ShareService.share(
        text: shareText,
        subject: 'Waste Classification Result',
      );

      return shareText;
    } catch (e, stackTrace) {
      final error = 'Error sharing: ${ErrorHandler.getUserFriendlyMessage(e)}';
      WasteAppLogger.severe('Failed to share classification',
          error: e,
          stackTrace: stackTrace,
          context: {
            'classificationId': classification.id,
            'service': 'ResultPipeline',
          });
      throw Exception(error);
    }
  }

  /// Save classification without full processing (for manual save)
  Future<void> saveClassificationOnly(WasteClassification classification,
      {bool force = false}) async {
    try {
      await trackUserAction('classification_save', classification);

      final savedClassification = classification.copyWith(isSaved: true);
      await _storageService.saveClassification(savedClassification,
          force: force);

      state = state.copyWith(isSaved: true);

      WasteAppLogger.info('Classification saved manually', context: {
        'classificationId': classification.id,
        'service': 'ResultPipeline',
      });
    } catch (e, stackTrace) {
      final error = 'Error saving: ${ErrorHandler.getUserFriendlyMessage(e)}';
      WasteAppLogger.severe('Failed to save classification',
          error: e,
          stackTrace: stackTrace,
          context: {
            'classificationId': classification.id,
            'service': 'ResultPipeline',
          });
      state = state.copyWith(error: error);
      throw Exception(error);
    }
  }

  /// Submit user feedback on a classification (confirm or correct).
  ///
  /// Uses a stable deterministic feedback ID derived from userId + classificationId
  /// to prevent duplicate feedback records, duplicate point awards, and duplicate
  /// analytics events. If feedback for this classification by this user already
  /// exists locally, the method returns the previously-awarded points without
  /// re-creating the record.
  ///
  /// Returns a [FeedbackResult] with the outcome details.
  Future<FeedbackResult> submitFeedback({
    required WasteClassification classification,
    required bool userConfirmed,
    String? userCorrection,
    String? userNotes,
    String? userSuggestedCategory,
    String? userSuggestedMaterial,
    String? userSuggestedItemName,
  }) async {
    final isCorrection = userConfirmed == false && userSuggestedCategory != null;
    final action = isCorrection ? 'correction_provided' : 'feedback_provided';
    final points = GamificationService.pointValues[action] ?? 0;

    try {
      // 0. Idempotency check: if feedback already exists for this classification,
      // return early with pointsAwarded=0 and wasDuplicate=true. No points,
      // analytics, or cloud sync are repeated for duplicate submissions.
      final profile = await _storageService.getCurrentUserProfile();
      final userId = profile?.id ?? 'unknown';
      final dedupKey = ClassificationFeedback.dedupKey(userId, classification.id);

      final existingFeedback = await _storageService.getClassificationFeedback(dedupKey);
      if (existingFeedback != null) {
        WasteAppLogger.info('Feedback already submitted locally',
            context: {
              'classificationId': classification.id,
              'dedupKey': dedupKey,
              'service': 'ResultPipeline',
            });
        return FeedbackResult(
          saved: true,
          pointsAwarded: 0,
          nominalPoints: points,
          wasDuplicate: true,
          cloudSynced: false,
        );
      }

      // 0b. Cloud dedup check: if local data was cleared but the feedback doc
      // already exists in Firestore, treat as duplicate to prevent re-awarding.
      try {
        final settings = await _storageService.getSettings();
        if (settings['isGoogleSyncEnabled'] == true) {
          final cloudExists = await _cloudStorageService
              .checkClassificationFeedbackExists(dedupKey);
          if (cloudExists) {
            WasteAppLogger.info(
                'Feedback already exists in cloud (local was cleared)',
                context: {
                  'classificationId': classification.id,
                  'dedupKey': dedupKey,
                  'service': 'ResultPipeline',
                });
            return FeedbackResult(
              saved: true,
              pointsAwarded: 0,
              nominalPoints: points,
              wasDuplicate: true,
              cloudSynced: true,
            );
          }
        }
      } catch (e) {
        // Cloud check failure should not block local submission.
        // If we can't verify cloud state, proceed with local flow.
        WasteAppLogger.warning('Cloud dedup check failed, proceeding locally',
            error: e,
            context: {
              'classificationId': classification.id,
              'service': 'ResultPipeline',
            });
      }

      // 1. Save updated classification locally
      final updated = classification.copyWith(
        userConfirmed: userConfirmed,
        userCorrection: userCorrection,
        userNotes: userNotes,
      );
      await _storageService.saveClassification(updated, force: true);

      // 2. Persist ClassificationFeedback record with stable ID
      final feedback = ClassificationFeedback.createStable(
        userId: userId,
        originalClassificationId: classification.id,
        originalAIItemName: classification.itemName,
        originalAICategory: classification.category,
        originalAIMaterial: classification.materialType,
        originalAIConfidence: classification.confidence,
        userSuggestedItemName: userSuggestedItemName,
        userSuggestedCategory: userSuggestedCategory ?? classification.category,
        userSuggestedMaterial: userSuggestedMaterial,
        userNotes: userNotes,
      );
      await _storageService.saveClassificationFeedback(feedback);

      // 3. Sync to Firestore (non-blocking — fail silently)
      var cloudSynced = false;
      try {
        final settings = await _storageService.getSettings();
        if (settings['isGoogleSyncEnabled'] == true) {
          await _cloudStorageService.saveClassificationFeedbackToCloud(feedback);
          cloudSynced = true;
        }
      } catch (e) {
        WasteAppLogger.warning('Feedback cloud sync failed', error: e, context: {
          'classificationId': classification.id,
          'service': 'ResultPipeline',
        });
      }

      // 4. Award gamification points
      try {
        await _gamificationService.addPoints(action, customPoints: points);
      } catch (e) {
        WasteAppLogger.warning('Feedback points award failed', error: e);
      }

      // 5. Track analytics (once per stable submission)
      await _analyticsService.trackEvent(
        eventType: AnalyticsEventTypes.userAction,
        eventName: 'classification.feedback',
        parameters: {
          'is_correct': userConfirmed.toString(),
          'corrected_to': userSuggestedCategory ?? classification.category,
          'classification_id': classification.id,
          'original_category': classification.category,
        },
      );

      WasteAppLogger.info('Feedback submitted', context: {
        'classificationId': classification.id,
        'action': action,
        'points': points,
        'service': 'ResultPipeline',
      });

      return FeedbackResult(
        saved: true,
        pointsAwarded: points,
        nominalPoints: points,
        wasDuplicate: false,
        cloudSynced: cloudSynced,
      );
    } catch (e, stackTrace) {
      WasteAppLogger.severe('Feedback submission failed',
          error: e,
          stackTrace: stackTrace,
          context: {
            'classificationId': classification.id,
            'service': 'ResultPipeline',
          });
      rethrow;
    }
  }

  /// Check and process retroactive gamification for existing classifications
  Future<void> processRetroactiveGamification() async {
    try {
      WasteAppLogger.info('Checking retroactive gamification processing',
          context: {
            'service': 'ResultPipeline',
          });

      // Get current profile
      final profile = await _gamificationService.getProfile();
      final currentPoints = profile.points.total;

      // Get all classifications
      final allClassifications = await _storageService.getAllClassifications();

      // If user has classifications but 0 points, they need retroactive processing
      if (allClassifications.isNotEmpty && currentPoints == 0) {
        WasteAppLogger.info(
            'Processing retroactive gamification for ${allClassifications.length} classifications',
            context: {
              'service': 'ResultPipeline',
            });

        // Process all classifications for gamification
        for (final classification in allClassifications) {
          await _gamificationService.processClassification(classification);
        }

        WasteAppLogger.info('Retroactive gamification processing completed',
            context: {
              'classificationsProcessed': allClassifications.length,
              'service': 'ResultPipeline',
            });
      } else {
        WasteAppLogger.info('No retroactive processing needed', context: {
          'classifications': allClassifications.length,
          'currentPoints': currentPoints,
          'service': 'ResultPipeline',
        });
      }
    } catch (e, stackTrace) {
      WasteAppLogger.severe('Retroactive gamification processing failed',
          error: e,
          stackTrace: stackTrace,
          context: {
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
final communityServiceProvider =
    Provider<CommunityService>((ref) => CommunityService());

/// Provider for the ResultPipeline
final resultPipelineProvider =
    StateNotifierProvider<ResultPipeline, ResultPipelineState>((ref) {
  final storageService = ref.read(storageServiceProvider);
  final gamificationService = ref.read(gamificationServiceProvider);
  final cloudStorageService = ref.read(cloudStorageServiceProvider);
  final communityService = ref.read(communityServiceProvider);
  final adService = ref.read(adServiceProvider);
  final analyticsService = ref.read(analyticsServiceProvider);

  return ResultPipeline(
    storageService,
    gamificationService,
    cloudStorageService,
    communityService,
    adService,
    analyticsService,
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
