import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Unused import
import '../models/gamification.dart';
import '../services/storage_service.dart';
import '../services/analytics_consent_manager.dart';
import '../services/analytics_schema_validator.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Service for tracking and analyzing user behavior and app usage.
class AnalyticsService extends ChangeNotifier {
  AnalyticsService(this._storageService) {
    _initializeSession();
    _initializeFirestore();
  }
  static const String _analyticsCollection = 'analytics_events';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService;
  final Uuid _uuid = const Uuid();
  final AnalyticsConsentManager _consentManager = AnalyticsConsentManager();
  final AnalyticsSchemaValidator _validator = AnalyticsSchemaValidator();

  String? _currentSessionId;
  DateTime? _sessionStartTime;
  Map<String, dynamic> _sessionParameters = {};
  final List<AnalyticsEvent> _pendingEvents = [];
  final List<AnalyticsEvent> _sessionEvents = [];

  // Connection state tracking
  bool _isFirestoreAvailable = false;

  // ================ SESSION MANAGEMENT ================

  /// Initializes a new analytics session.
  void _initializeSession() {
    _currentSessionId = _uuid.v4();
    _sessionStartTime = DateTime.now();
    _sessionParameters = {
      'platform': defaultTargetPlatform.toString(),
      'appVersion': '0.1.4+96', // Could be dynamic
      'deviceLocale': 'en_US', // Could be dynamic
    };

    _trackSessionStart();
  }

  /// Clears all analytics session data and pending events.
  /// Should be called on user sign-out to prevent data leakage.
  void clearAnalyticsData() {
    _currentSessionId = null;
    _sessionStartTime = null;
    _sessionParameters = {};
    _pendingEvents.clear();
    _sessionEvents.clear();
    WasteAppLogger.info('✅ Analytics data cleared');
  }

  /// Tracks the start of a user session.
  void _trackSessionStart() {
    trackEvent(
      eventType: AnalyticsEventTypes.userAction,
      eventName: 'session_start',
      parameters: _sessionParameters,
    );
  }

  /// Tracks the end of a user session (legacy method - use enhanced version).
  void trackSessionEndLegacy() {
    if (_sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!).inMinutes;

      trackEvent(
        eventType: AnalyticsEventTypes.userAction,
        eventName: 'session_end',
        parameters: {
          ..._sessionParameters,
          'session_duration_minutes': sessionDuration,
          'events_tracked': _pendingEvents.length,
        },
      );
    }
  }

  // ================ EVENT TRACKING ================

  /// Tracks a generic analytics event with consent and validation.
  Future<void> trackEvent({
    required String eventType,
    required String eventName,
    Map<String, dynamic> parameters = const {},
  }) async {
    try {
      // Check consent before tracking
      if (!await _consentManager.shouldTrackEvent(eventType)) {
        WasteAppLogger.info('Event not tracked due to consent settings', null, null,
            {'event_name': eventName, 'event_type': eventType, 'service': 'AnalyticsService'});
        return;
      }

      // Get user ID or anonymous ID
      final userProfile = await _storageService.getCurrentUserProfile();
      final userId = userProfile?.id ?? await _consentManager.getAnonymousId();

      // Add consent metadata and enhanced parameters
      final consentMetadata = await _consentManager.getConsentMetadata();
      final enhancedParameters = {
        ...parameters,
        'app_version': '0.1.4+96', // TODO: Get from package info
        'platform': defaultTargetPlatform.name,
        'session_id': _currentSessionId,
        'consent_metadata': consentMetadata,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final event = AnalyticsEvent.create(
        userId: userId,
        eventType: eventType,
        eventName: eventName,
        parameters: enhancedParameters,
        sessionId: _currentSessionId,
        deviceInfo: _getDeviceInfo(),
      );

      // Validate event before processing
      final validationResult = await _validator.validateEvent(event);
      if (!validationResult.isValid) {
        WasteAppLogger.warning('Event validation failed, not tracking', null, null,
            {'event_name': eventName, 'validation_errors': validationResult.errors, 'service': 'AnalyticsService'});
        return;
      }

      _pendingEvents.add(event);

      // Save to Firebase immediately (could be batched for efficiency)
      await _saveEventToFirestore(event);

      notifyListeners();
    } catch (e) {
      WasteAppLogger.severe('Analytics: Failed to track event $eventName: $e');
    }
  }

  /// Tracks screen view events.
  Future<void> trackScreenView(String screenName, {Map<String, dynamic>? parameters}) async {
    await trackEvent(
      eventType: AnalyticsEventTypes.screenView,
      eventName: '${screenName}_view',
      parameters: {
        'screen_name': screenName,
        ...?parameters,
      },
    );
  }

  /// Tracks user actions (button clicks, swipes, etc.).
  Future<void> trackUserAction(String actionName, {Map<String, dynamic>? parameters}) async {
    await trackEvent(
      eventType: AnalyticsEventTypes.userAction,
      eventName: actionName,
      parameters: parameters ?? {},
    );
  }

  /// Tracks waste classification events.
  Future<void> trackClassification({
    required String classificationId,
    required String category,
    required bool isRecyclable,
    required double confidence,
    required String method,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventTypes.classification,
      eventName: AnalyticsEventNames.classificationCompleted,
      parameters: {
        'classification_id': classificationId,
        'category': category,
        'is_recyclable': isRecyclable,
        'confidence': confidence,
        'classification_method': method,
        ...?additionalData,
      },
    );
  }

  /// Tracks social/family interaction events.
  Future<void> trackSocialInteraction({
    required String interactionType,
    required String targetId,
    String? familyId,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventTypes.social,
      eventName: interactionType,
      parameters: {
        'target_id': targetId,
        'family_id': familyId,
        ...?additionalData,
      },
    );
  }

  /// Tracks achievement unlocking events.
  Future<void> trackAchievement({
    required String achievementId,
    required String achievementType,
    required int pointsAwarded,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventTypes.achievement,
      eventName: AnalyticsEventNames.achievementUnlocked,
      parameters: {
        'achievement_id': achievementId,
        'achievement_type': achievementType,
        'points_awarded': pointsAwarded,
        ...?additionalData,
      },
    );
  }

  /// Tracks error events.
  Future<void> trackError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventTypes.error,
      eventName: '${errorType}_error',
      parameters: {
        'error_message': errorMessage,
        'stack_trace': stackTrace,
        ...?additionalData,
      },
    );
  }

  // ================ ENHANCED TRACKING METHODS ================

  /// Tracks session start with comprehensive metadata
  Future<void> trackSessionStart() async {
    await trackEvent(
      eventType: AnalyticsEventTypes.session,
      eventName: AnalyticsEventNames.sessionStart,
      parameters: {
        'device_type': defaultTargetPlatform.name,
        'app_version': '0.1.4+96', // TODO: Get from package info
        'platform': defaultTargetPlatform.name,
        'user_segment': 'standard', // TODO: Determine user segment
        ..._sessionParameters,
      },
    );
  }

  /// Tracks session end with session metrics
  Future<void> trackSessionEnd() async {
    if (_sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);

      await trackEvent(
        eventType: AnalyticsEventTypes.session,
        eventName: AnalyticsEventNames.sessionEnd,
        parameters: {
          'session_duration_ms': sessionDuration.inMilliseconds,
          'events_in_session': _sessionEvents.length,
          'classifications_count': _getSessionClassificationsCount(),
          ..._sessionParameters,
        },
      );
    }
  }

  /// Tracks page/screen view with navigation context
  Future<void> trackPageView(
    String screenName, {
    String? previousScreen,
    String? navigationMethod,
    int? timeOnPreviousScreen,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventTypes.pageView,
      eventName: AnalyticsEventNames.pageView,
      parameters: {
        'screen_name': screenName,
        'previous_screen': previousScreen,
        'navigation_method': navigationMethod ?? 'unknown',
        'time_on_previous_screen_ms': timeOnPreviousScreen,
      },
    );
  }

  /// Tracks click interactions with detailed context
  Future<void> trackClick({
    required String elementId,
    required String screenName,
    required String elementType,
    String? userIntent,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventTypes.interaction,
      eventName: AnalyticsEventNames.click,
      parameters: {
        'element_id': elementId,
        'screen_name': screenName,
        'element_type': elementType,
        'user_intent': userIntent,
        ...?additionalData,
      },
    );
  }

  /// Tracks rage clicks (multiple taps on same element)
  Future<void> trackRageClick({
    required String elementId,
    required String screenName,
    required int tapCount,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventTypes.interaction,
      eventName: AnalyticsEventNames.rageClick,
      parameters: {
        'element_id': elementId,
        'screen_name': screenName,
        'tap_count': tapCount,
        ...?additionalData,
      },
    );
  }

  /// Tracks scroll depth for content engagement
  Future<void> trackScrollDepth({
    required int depthPercent,
    required String screenName,
    String? contentType,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventTypes.engagement,
      eventName: AnalyticsEventNames.scrollDepth,
      parameters: {
        'depth_percent': depthPercent,
        'screen_name': screenName,
        'content_type': contentType,
        ...?additionalData,
      },
    );
  }

  /// Tracks comprehensive file classification events
  Future<void> trackFileClassified({
    required String classificationId,
    required String category,
    required double confidenceScore,
    required int processingDuration,
    required String modelVersion,
    String? method,
    bool? resultAccuracy,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventTypes.classification,
      eventName: AnalyticsEventNames.fileClassified,
      parameters: {
        'classification_id': classificationId,
        'category': category,
        'confidence_score': confidenceScore,
        'processing_duration_ms': processingDuration,
        'model_version': modelVersion,
        'method': method ?? 'standard',
        'result_accuracy': resultAccuracy,
        ...?additionalData,
      },
    );
  }

  /// Tracks classification retry attempts
  Future<void> trackClassificationRetried({
    required String classificationId,
    required double originalConfidence,
    required String retryReason,
    required int attemptNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventTypes.classification,
      eventName: AnalyticsEventNames.classificationRetried,
      parameters: {
        'classification_id': classificationId,
        'original_confidence': originalConfidence,
        'retry_reason': retryReason,
        'attempt_number': attemptNumber,
        ...?additionalData,
      },
    );
  }

  /// Tracks performance issues and slow operations
  Future<void> trackSlowResource({
    required String operationName,
    required int durationMs,
    required String resourceType,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventTypes.performance,
      eventName: AnalyticsEventNames.slowResource,
      parameters: {
        'operation_name': operationName,
        'duration_ms': durationMs,
        'resource_type': resourceType,
        ...?additionalData,
      },
    );
  }

  /// Tracks API errors with detailed context
  Future<void> trackApiError({
    required String endpoint,
    required int statusCode,
    required int latencyMs,
    int? retryCount,
    String? errorMessage,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventTypes.performance,
      eventName: AnalyticsEventNames.apiError,
      parameters: {
        'endpoint': endpoint,
        'status_code': statusCode,
        'latency_ms': latencyMs,
        'retry_count': retryCount ?? 0,
        'error_message': errorMessage,
        ...?additionalData,
      },
    );
  }

  /// Tracks client-side errors
  Future<void> trackClientError({
    required String errorMessage,
    required String screenName,
    String? stackTrace,
    String? userAction,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventTypes.errorDetailed,
      eventName: AnalyticsEventNames.clientError,
      parameters: {
        'error_message': errorMessage,
        'screen_name': screenName,
        'stack_trace': stackTrace,
        'user_action': userAction,
        ...?additionalData,
      },
    );
  }

  /// Tracks points earned events
  Future<void> trackPointsEarned({
    required int pointsAmount,
    required String sourceAction,
    required int totalPoints,
    String? category,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventTypes.gamification,
      eventName: AnalyticsEventNames.pointsEarned,
      parameters: {
        'points_amount': pointsAmount,
        'source_action': sourceAction,
        'total_points': totalPoints,
        'category': category,
        ...?additionalData,
      },
    );
  }

  /// Tracks educational content engagement
  Future<void> trackContentViewed({
    required String contentId,
    required String contentType,
    String? source,
    int? userLevel,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventTypes.content,
      eventName: AnalyticsEventNames.contentViewed,
      parameters: {
        'content_id': contentId,
        'content_type': contentType,
        'source': source,
        'user_level': userLevel,
        ...?additionalData,
      },
    );
  }

  /// Tracks content completion
  Future<void> trackContentCompleted({
    required String contentId,
    required int timeSpentMs,
    double? completionRate,
    int? quizScore,
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent(
      eventType: AnalyticsEventTypes.content,
      eventName: AnalyticsEventNames.contentCompleted,
      parameters: {
        'content_id': contentId,
        'time_spent_ms': timeSpentMs,
        'completion_rate': completionRate,
        'quiz_score': quizScore,
        ...?additionalData,
      },
    );
  }

  // ================ ANALYTICS QUERIES ================

  /// Gets user analytics data for a specific time period.
  Future<Map<String, dynamic>> getUserAnalytics(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (!_isFirestoreAvailable) {
        WasteAppLogger.info('Analytics: Firestore not available for user analytics query');
        return {'error': 'Analytics service unavailable'};
      }

      final querySnapshot = await _firestore
          .collection(_analyticsCollection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final events = querySnapshot.docs.map((doc) => AnalyticsEvent.fromJson(doc.data())).toList();

      return _aggregateUserAnalytics(events);
    } catch (e) {
      WasteAppLogger.severe('Analytics: Error getting user analytics: $e');
      _isFirestoreAvailable = false;
      return {'error': 'Failed to fetch analytics data'};
    }
  }

  /// Gets system-wide analytics data.
  Future<Map<String, dynamic>> getSystemAnalytics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (!_isFirestoreAvailable) {
        WasteAppLogger.info('Analytics: Firestore not available for system analytics query');
        return {'error': 'Analytics service unavailable'};
      }

      final querySnapshot = await _firestore
          .collection(_analyticsCollection)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final events = querySnapshot.docs.map((doc) => AnalyticsEvent.fromJson(doc.data())).toList();

      return _aggregateSystemAnalytics(events);
    } catch (e) {
      WasteAppLogger.severe('Analytics: Error getting system analytics: $e');
      _isFirestoreAvailable = false;
      return {'error': 'Failed to fetch system analytics data'};
    }
  }

  /// Gets popular content analytics.
  Future<List<Map<String, dynamic>>> getPopularContent(int limit) async {
    try {
      if (!_isFirestoreAvailable) {
        WasteAppLogger.info('Analytics: Firestore not available for popular content query');
        return [];
      }

      final querySnapshot = await _firestore
          .collection(_analyticsCollection)
          .where('eventType', isEqualTo: 'content_interaction')
          .orderBy('timestamp', descending: true)
          .limit(limit * 10) // Get more to account for duplicates
          .get();

      final events = querySnapshot.docs.map((doc) => AnalyticsEvent.fromJson(doc.data())).toList();

      return _aggregateContentAnalytics(events, limit);
    } catch (e) {
      WasteAppLogger.severe('Analytics: Error getting popular content: $e');
      _isFirestoreAvailable = false;
      return [];
    }
  }

  // ================ ANALYTICS AGGREGATION ================

  /// Aggregate user analytics from events
  Map<String, dynamic> _aggregateUserAnalytics(List<AnalyticsEvent> events) {
    final eventCounts = <String, int>{};
    final dailyActivity = <String, int>{};
    final totalEvents = events.length;

    for (final event in events) {
      // Count event types
      eventCounts[event.eventType] = (eventCounts[event.eventType] ?? 0) + 1;

      // Count daily activity
      final dateKey = '${event.timestamp.year}-${event.timestamp.month}-${event.timestamp.day}';
      dailyActivity[dateKey] = (dailyActivity[dateKey] ?? 0) + 1;
    }

    return {
      'totalEvents': totalEvents,
      'eventCounts': eventCounts,
      'dailyActivity': dailyActivity,
      'periodStart': events.isNotEmpty ? events.last.timestamp : null,
      'periodEnd': events.isNotEmpty ? events.first.timestamp : null,
    };
  }

  /// Aggregate system-wide analytics from events
  Map<String, dynamic> _aggregateSystemAnalytics(List<AnalyticsEvent> events) {
    final eventTypeCounts = <String, int>{};
    final userCounts = <String, int>{};
    final dailyTotals = <String, int>{};
    final uniqueUsers = <String>{};

    for (final event in events) {
      // Count event types
      eventTypeCounts[event.eventType] = (eventTypeCounts[event.eventType] ?? 0) + 1;

      // Track unique users
      uniqueUsers.add(event.userId);

      // Count daily totals
      final dateKey = '${event.timestamp.year}-${event.timestamp.month}-${event.timestamp.day}';
      dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + 1;
    }

    return {
      'totalEvents': events.length,
      'uniqueUsers': uniqueUsers.length,
      'eventTypeCounts': eventTypeCounts,
      'dailyTotals': dailyTotals,
      'averageEventsPerUser': uniqueUsers.isNotEmpty ? events.length / uniqueUsers.length : 0,
    };
  }

  /// Aggregate content analytics from events
  List<Map<String, dynamic>> _aggregateContentAnalytics(List<AnalyticsEvent> events, int limit) {
    final contentCounts = <String, int>{};
    final contentDetails = <String, Map<String, dynamic>>{};

    for (final event in events) {
      final contentId = event.parameters['content_id'] as String?;
      final contentTitle = event.parameters['content_title'] as String?;
      final contentType = event.parameters['content_type'] as String?;

      if (contentId != null) {
        contentCounts[contentId] = (contentCounts[contentId] ?? 0) + 1;
        contentDetails[contentId] = {
          'id': contentId,
          'title': contentTitle ?? 'Unknown',
          'type': contentType ?? 'Unknown',
          'count': contentCounts[contentId],
        };
      }
    }

    // Sort by count and return top items
    final sortedContent = contentDetails.values.toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    return sortedContent.take(limit).toList();
  }

  // ================ HELPER METHODS ================

  /// Saves an event to Firestore.
  Future<void> _saveEventToFirestore(AnalyticsEvent event) async {
    try {
      // Check if Firestore is available
      if (!_isFirestoreAvailable) {
        WasteAppLogger.info('Analytics: Firestore not available, storing event locally');
        _pendingEvents.add(event);
        return;
      }

      await _firestore.collection('analytics_events').doc(event.id).set(event.toJson());
      WasteAppLogger.info('Analytics: Event saved to Firestore successfully');
    } catch (e) {
      WasteAppLogger.severe('Analytics: Failed to save event to Firestore: $e');

      // If Firestore fails, mark as unavailable and store locally
      _isFirestoreAvailable = false;
      _pendingEvents.add(event);

      // Try to reinitialize Firestore connection in background
      _initializeFirestore();
    }
  }

  /// Process pending events when Firestore becomes available
  Future<void> _processPendingEvents() async {
    if (!_isFirestoreAvailable || _pendingEvents.isEmpty) {
      return;
    }

    WasteAppLogger.info('Analytics: Processing ${_pendingEvents.length} pending events');

    final eventsToProcess = List<AnalyticsEvent>.from(_pendingEvents);
    _pendingEvents.clear();

    for (final event in eventsToProcess) {
      try {
        await _firestore.collection('analytics_events').doc(event.id).set(event.toJson());
      } catch (e) {
        WasteAppLogger.severe('Analytics: Failed to process pending event: $e');
        // Add back to pending if still failing
        _pendingEvents.add(event);
        _isFirestoreAvailable = false;
        break;
      }
    }

    if (_pendingEvents.isEmpty) {
      WasteAppLogger.info('✅ All pending analytics events processed successfully');
    }
  }

  /// Get connection status for diagnostics
  bool get isFirestoreConnected => _isFirestoreAvailable;

  /// Get number of pending events
  int get pendingEventsCount => _pendingEvents.length;

  /// Gets basic device information for analytics.
  String _getDeviceInfo() {
    return '${defaultTargetPlatform.toString()}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Gets count of classifications in current session
  int _getSessionClassificationsCount() {
    return _sessionEvents
        .where((event) =>
            event.eventType == AnalyticsEventTypes.classification || event.eventName.contains('classification'))
        .length;
  }

  /// Calculates analytics metrics for a user.
  Map<String, dynamic> _calculateUserAnalytics(List<AnalyticsEvent> events) {
    final totalEvents = events.length;
    final uniqueSessions = events.map((e) => e.sessionId).toSet().length;

    // Calculate event type breakdown
    final eventTypeBreakdown = <String, int>{};
    for (final event in events) {
      eventTypeBreakdown[event.eventType] = (eventTypeBreakdown[event.eventType] ?? 0) + 1;
    }

    // Calculate daily activity
    final dailyActivity = <String, int>{};
    for (final event in events) {
      final dateKey = event.timestamp.toIso8601String().split('T')[0];
      dailyActivity[dateKey] = (dailyActivity[dateKey] ?? 0) + 1;
    }

    // Calculate most used features
    final featureUsage = <String, int>{};
    for (final event in events.where((e) => e.eventType == AnalyticsEventTypes.userAction)) {
      featureUsage[event.eventName] = (featureUsage[event.eventName] ?? 0) + 1;
    }

    return {
      'total_events': totalEvents,
      'unique_sessions': uniqueSessions,
      'event_type_breakdown': eventTypeBreakdown,
      'daily_activity': dailyActivity,
      'feature_usage': featureUsage,
      'analysis_period': {
        'start': events.isNotEmpty ? events.last.timestamp.toIso8601String() : null,
        'end': events.isNotEmpty ? events.first.timestamp.toIso8601String() : null,
      },
    };
  }

  /// Calculates analytics metrics for a family.
  Map<String, dynamic> _calculateFamilyAnalytics(List<AnalyticsEvent> events) {
    final totalEvents = events.length;
    final uniqueUsers = events.map((e) => e.userId).toSet().length;

    // Calculate member activity
    final memberActivity = <String, int>{};
    for (final event in events) {
      memberActivity[event.userId] = (memberActivity[event.userId] ?? 0) + 1;
    }

    // Calculate social interactions
    final socialEvents = events.where((e) => e.eventType == AnalyticsEventTypes.social).toList();
    final classificationEvents = events.where((e) => e.eventType == AnalyticsEventTypes.classification).toList();

    return {
      'total_events': totalEvents,
      'unique_members': uniqueUsers,
      'member_activity': memberActivity,
      'social_interactions': socialEvents.length,
      'classifications_shared': classificationEvents.length,
      'most_active_member':
          memberActivity.isNotEmpty ? memberActivity.entries.reduce((a, b) => a.value > b.value ? a : b).key : null,
    };
  }

  /// Calculates popular features based on usage frequency.
  List<Map<String, dynamic>> _calculatePopularFeatures(List<AnalyticsEvent> events, int limit) {
    final featureUsage = <String, int>{};

    for (final event in events) {
      featureUsage[event.eventName] = (featureUsage[event.eventName] ?? 0) + 1;
    }

    final sortedFeatures = featureUsage.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sortedFeatures
        .take(limit)
        .map((entry) => {
              'feature_name': entry.key,
              'usage_count': entry.value,
              'usage_percentage': (entry.value / events.length * 100).toStringAsFixed(1),
            })
        .toList();
  }

  // ================ CONVENIENCE METHODS ================

  /// Tracks common app actions with simplified interface.
  void trackButtonClick(String buttonName, {String? screenName}) {
    trackUserAction(AnalyticsEventNames.buttonClick, parameters: {
      'button_name': buttonName,
      if (screenName != null) 'screen_name': screenName,
    });
  }

  void trackScreenSwipe(String direction, {String? screenName}) {
    trackUserAction(AnalyticsEventNames.screenSwipe, parameters: {
      'direction': direction,
      if (screenName != null) 'screen_name': screenName,
    });
  }

  void trackSearch(String query, {int? resultCount}) {
    trackUserAction(AnalyticsEventNames.searchPerformed, parameters: {
      'search_query': query,
      if (resultCount != null) 'result_count': resultCount,
    });
  }

  /// Tracks classification workflow events.
  void trackClassificationStarted({String? method}) {
    trackEvent(
      eventType: AnalyticsEventTypes.classification,
      eventName: AnalyticsEventNames.classificationStarted,
      parameters: {
        if (method != null) 'method': method,
      },
    );
  }

  void trackClassificationShared(String classificationId, {String? familyId}) {
    trackSocialInteraction(
      interactionType: AnalyticsEventNames.classificationShared,
      targetId: classificationId,
      familyId: familyId,
    );
  }

  /// Tracks family-related events.
  void trackFamilyCreated(String familyId, {int? memberCount}) {
    trackSocialInteraction(
      interactionType: AnalyticsEventNames.familyCreated,
      targetId: familyId,
      familyId: familyId,
      additionalData: {
        if (memberCount != null) 'member_count': memberCount,
      },
    );
  }

  void trackFamilyJoined(String familyId, {String? invitationId}) {
    trackSocialInteraction(
      interactionType: AnalyticsEventNames.familyJoined,
      targetId: familyId,
      familyId: familyId,
      additionalData: {
        if (invitationId != null) 'invitation_id': invitationId,
      },
    );
  }

  void trackReactionAdded(String classificationId, String reactionType, {String? familyId}) {
    trackSocialInteraction(
      interactionType: AnalyticsEventNames.reactionAdded,
      targetId: classificationId,
      familyId: familyId,
      additionalData: {
        'reaction_type': reactionType,
      },
    );
  }

  /// Flushes any pending events and ends the current session.
  @override
  Future<void> dispose() async {
    trackSessionEnd();
    super.dispose();
  }

  /// Initializes Firestore connection and checks availability
  void _initializeFirestore() async {
    try {
      // Test Firestore connection
      await _firestore.enableNetwork();

      // Try a simple read operation to verify API access
      await _firestore.collection('test').limit(1).get();

      _isFirestoreAvailable = true;
      WasteAppLogger.info('✅ Firestore connection established');

      // Sync any pending events
      await _syncPendingEvents();
    } catch (e) {
      _isFirestoreAvailable = false;
      WasteAppLogger.info('❌ Firestore unavailable: $e');
      WasteAppLogger.info('📱 Analytics will use local storage only');

      // Check if it's a permission error and provide helpful message
      if (e.toString().contains('PERMISSION_DENIED') ||
          e.toString().contains('has not been used') ||
          e.toString().contains('disabled')) {
        WasteAppLogger.info(
            '🔧 To fix: Enable Firestore API at https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=waste-segregation-app-df523');
      }
    }
  }

  /// Store analytics events locally when Firestore is unavailable
  void _storeEventsLocally() {
    WasteAppLogger.info('Analytics: Storing ${_pendingEvents.length} events locally');
    // You could implement local storage here using Hive or SharedPreferences
    // For now, we'll just log the events for debugging
    for (final event in _pendingEvents) {
      WasteAppLogger.info('Analytics Event: ${event.eventName} - ${event.eventType}');
    }
  }

  // ================ PRIVATE HELPER METHODS ================

  /// Syncs pending events to Firestore when connection is available
  Future<void> _syncPendingEvents() async {
    if (!_isFirestoreAvailable || _pendingEvents.isEmpty) return;

    try {
      final batch = _firestore.batch();

      for (final event in _pendingEvents) {
        final docRef = _firestore.collection(_analyticsCollection).doc();
        batch.set(docRef, event.toJson());
      }

      await batch.commit();
      WasteAppLogger.info('✅ Synced ${_pendingEvents.length} pending analytics events');
      _pendingEvents.clear();

      // Save cleared pending events to local storage
      await _storageService.saveAnalyticsEvents(_pendingEvents);
    } catch (e) {
      WasteAppLogger.severe('❌ Failed to sync pending events: $e');
    }
  }

  /// Stores an event locally when Firestore is unavailable
  void _storeEventLocally(AnalyticsEvent event) {
    _pendingEvents.add(event);

    // Limit pending events to prevent memory issues
    if (_pendingEvents.length > 100) {
      _pendingEvents.removeAt(0);
    }

    // Save to local storage
    _storageService.saveAnalyticsEvents(_pendingEvents);
    WasteAppLogger.info('📱 Stored analytics event locally (${_pendingEvents.length} pending)');
  }
}
