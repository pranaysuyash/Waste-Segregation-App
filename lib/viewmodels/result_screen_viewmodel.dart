import 'package:flutter/foundation.dart';
import '../models/waste_classification.dart';
import '../models/gamification.dart';
import '../models/gamification_result.dart';
import '../services/storage_service.dart';
import '../services/gamification_service.dart';
import '../services/cloud_storage_service.dart';
import '../services/analytics_service.dart';
import '../utils/waste_app_logger.dart';

/// OPTIMIZATION: ViewModel for ResultScreen to separate business logic from UI
/// 
/// Extracts 500+ lines of business logic from ResultScreen into a dedicated ViewModel.
/// This follows the MVVM pattern for better testability and maintainability.
/// 
/// Benefits:
/// - Separation of concerns (business logic vs UI)
/// - Easier unit testing (no widget context needed)
/// - Reduced ResultScreen complexity
/// - Reusable business logic
class ResultScreenViewModel extends ChangeNotifier {
  ResultScreenViewModel({
    required this.classification,
    required StorageService storageService,
    required GamificationService gamificationService,
    required CloudStorageService cloudStorageService,
    required AnalyticsService analyticsService,
  })  : _storageService = storageService,
        _gamificationService = gamificationService,
        _cloudStorageService = cloudStorageService,
        _analyticsService = analyticsService;

  final WasteClassification classification;
  final StorageService _storageService;
  final GamificationService _gamificationService;
  final CloudStorageService _cloudStorageService;
  final AnalyticsService _analyticsService;

  // State
  bool _isSaved = false;
  bool _isAutoSaving = false;
  bool _isProcessingGamification = false;
  List<Achievement> _newlyEarnedAchievements = [];
  int _pointsEarned = 0;
  Challenge? _completedChallenge;
  String? _error;

  // Getters
  bool get isSaved => _isSaved;
  bool get isAutoSaving => _isAutoSaving;
  bool get isProcessingGamification => _isProcessingGamification;
  List<Achievement> get newlyEarnedAchievements => _newlyEarnedAchievements;
  int get pointsEarned => _pointsEarned;
  Challenge? get completedChallenge => _completedChallenge;
  String? get error => _error;
  bool get hasError => _error != null;

  /// Auto-save classification and process gamification
  Future<void> autoSaveAndProcess() async {
    if (_isSaved || _isAutoSaving) {
      WasteAppLogger.debug('Classification already saved or saving in progress');
      return;
    }

    _isAutoSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Save classification
      await _storageService.saveClassification(classification);
      _isSaved = true;

      // Process gamification
      await _processGamification();

      _analyticsService.trackEvent(
        eventType: 'classification',
        eventName: 'auto_saved',
        parameters: {
          'classification_id': classification.id,
          'category': classification.category,
        },
      );
    } catch (e, s) {
      WasteAppLogger.severe('Error during auto-save', e, s);
      _error = 'Failed to save classification';
    } finally {
      _isAutoSaving = false;
      notifyListeners();
    }
  }

  /// Manually save classification
  Future<void> saveClassification() async {
    if (_isSaved) {
      WasteAppLogger.debug('Classification already saved');
      return;
    }

    _error = null;
    notifyListeners();

    try {
      await _storageService.saveClassification(classification);
      _isSaved = true;

      _analyticsService.trackEvent(
        eventType: 'user_action',
        eventName: 'classification_saved',
        parameters: {
          'classification_id': classification.id,
          'category': classification.category,
        },
      );

      notifyListeners();
    } catch (e, s) {
      WasteAppLogger.severe('Error saving classification', e, s);
      _error = 'Failed to save classification';
      notifyListeners();
    }
  }

  /// Process gamification for the classification
  Future<void> _processGamification() async {
    if (_isProcessingGamification) {
      return;
    }

    _isProcessingGamification = true;

    try {
      // Get user profile
      final userProfile = await _storageService.getCurrentUserProfile();
      if (userProfile == null) {
        WasteAppLogger.debug('No user profile found, skipping gamification');
        return;
      }

      // Process classification for gamification
      final result = await _gamificationService.processClassificationForGamification(
        classification,
        userProfile.id,
      );

      if (result != null) {
        _pointsEarned = result.pointsEarned;
        _newlyEarnedAchievements = result.newAchievements;
        _completedChallenge = result.completedChallenge;

        WasteAppLogger.info(
          'Gamification processed',
          context: {
            'points': _pointsEarned,
            'achievements': _newlyEarnedAchievements.length,
            'challenge_completed': _completedChallenge != null,
          },
        );
      }
    } catch (e, s) {
      WasteAppLogger.severe('Error processing gamification', e, s);
      // Don't set error - gamification is optional
    } finally {
      _isProcessingGamification = false;
      notifyListeners();
    }
  }

  /// Share classification result
  Future<void> shareResult() async {
    try {
      _analyticsService.trackEvent(
        eventType: 'user_action',
        eventName: 'share_started',
        parameters: {
          'classification_id': classification.id,
          'category': classification.category,
        },
      );

      // Share logic will be handled by UI using ShareService
      notifyListeners();
    } catch (e, s) {
      WasteAppLogger.severe('Error preparing share', e, s);
      _error = 'Failed to share';
      notifyListeners();
    }
  }

  /// Submit user correction for the classification
  Future<void> submitCorrection(String userCorrection, String? reason) async {
    _error = null;
    notifyListeners();

    try {
      final updatedClassification = classification.copyWith(
        userCorrection: userCorrection,
        disagreementReason: reason,
        userConfirmed: false,
      );

      await _storageService.saveClassification(updatedClassification);

      _analyticsService.trackEvent(
        eventType: 'user_action',
        eventName: 'correction_submitted',
        parameters: {
          'classification_id': classification.id,
          'original_category': classification.category,
          'correction': userCorrection,
        },
      );

      notifyListeners();
    } catch (e, s) {
      WasteAppLogger.severe('Error submitting correction', e, s);
      _error = 'Failed to submit correction';
      notifyListeners();
    }
  }

  /// Confirm classification as correct
  Future<void> confirmClassification() async {
    _error = null;
    notifyListeners();

    try {
      final updatedClassification = classification.copyWith(
        userConfirmed: true,
      );

      await _storageService.saveClassification(updatedClassification);

      _analyticsService.trackEvent(
        eventType: 'user_action',
        eventName: 'classification_confirmed',
        parameters: {
          'classification_id': classification.id,
          'category': classification.category,
        },
      );

      notifyListeners();
    } catch (e, s) {
      WasteAppLogger.severe('Error confirming classification', e, s);
      _error = 'Failed to confirm';
      notifyListeners();
    }
  }

  /// Delete the classification
  Future<bool> deleteClassification() async {
    _error = null;
    notifyListeners();

    try {
      await _storageService.deleteClassification(classification.id);

      _analyticsService.trackEvent(
        eventType: 'user_action',
        eventName: 'classification_deleted',
        parameters: {
          'classification_id': classification.id,
          'category': classification.category,
        },
      );

      return true;
    } catch (e, s) {
      WasteAppLogger.severe('Error deleting classification', e, s);
      _error = 'Failed to delete';
      notifyListeners();
      return false;
    }
  }

  /// Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}
