import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/gamification.dart';
import '../models/analytics_event.dart';
import '../services/storage_service.dart';

/// Service for tracking and analyzing user behavior and app usage.
class AnalyticsService extends ChangeNotifier {
  static const String _analyticsCollection = 'analytics_events';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService;
  final Uuid _uuid = const Uuid();
  
  String? _currentSessionId;
  DateTime? _sessionStartTime;
  Map<String, dynamic> _sessionParameters = {};
  List<AnalyticsEvent> _pendingEvents = [];
  
  AnalyticsService(this._storageService) {
    _initializeSession();
  }

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
    debugPrint('✅ Analytics data cleared');
  }

  /// Tracks the start of a user session.
  void _trackSessionStart() {
    trackEvent(
      eventType: AnalyticsEventTypes.userAction,
      eventName: 'session_start',
      parameters: _sessionParameters,
    );
  }

  /// Tracks the end of a user session.
  void trackSessionEnd() {
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

  /// Tracks a generic analytics event.
  Future<void> trackEvent({
    required String eventType,
    required String eventName,
    Map<String, dynamic> parameters = const {},
  }) async {
    try {
      final userProfile = await _storageService.getCurrentUserProfile();
      if (userProfile == null) {
        // Track anonymous events differently or skip
        return;
      }

      final event = AnalyticsEvent.create(
        userId: userProfile.id,
        eventType: eventType,
        eventName: eventName,
        parameters: {
          ...parameters,
          'timestamp': DateTime.now().toIso8601String(),
          'session_id': _currentSessionId,
        },
        sessionId: _currentSessionId,
        deviceInfo: _getDeviceInfo(),
      );

      _pendingEvents.add(event);
      
      // Save to Firebase immediately (could be batched for efficiency)
      await _saveEventToFirestore(event);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Analytics: Failed to track event $eventName: $e');
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

  // ================ ANALYTICS QUERIES ================

  /// Gets analytics data for a user within a date range.
  Future<Map<String, dynamic>> getUserAnalytics(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      final querySnapshot = await _firestore
          .collection(_analyticsCollection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('timestamp', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('timestamp', descending: true)
          .get();

      final events = querySnapshot.docs
          .map((doc) => AnalyticsEvent.fromJson(doc.data()))
          .toList();

      return _calculateUserAnalytics(events);
    } catch (e) {
      debugPrint('Analytics: Failed to get user analytics: $e');
      return {};
    }
  }

  /// Gets analytics data for a family.
  Future<Map<String, dynamic>> getFamilyAnalytics(
    String familyId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      final querySnapshot = await _firestore
          .collection(_analyticsCollection)
          .where('parameters.family_id', isEqualTo: familyId)
          .where('timestamp', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('timestamp', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('timestamp', descending: true)
          .get();

      final events = querySnapshot.docs
          .map((doc) => AnalyticsEvent.fromJson(doc.data()))
          .toList();

      return _calculateFamilyAnalytics(events);
    } catch (e) {
      debugPrint('Analytics: Failed to get family analytics: $e');
      return {};
    }
  }

  /// Gets popular features based on usage analytics.
  Future<List<Map<String, dynamic>>> getPopularFeatures({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 7));
      endDate ??= DateTime.now();

      final querySnapshot = await _firestore
          .collection(_analyticsCollection)
          .where('eventType', isEqualTo: AnalyticsEventTypes.userAction)
          .where('timestamp', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('timestamp', isLessThanOrEqualTo: endDate.toIso8601String())
          .get();

      final events = querySnapshot.docs
          .map((doc) => AnalyticsEvent.fromJson(doc.data()))
          .toList();

      return _calculatePopularFeatures(events, limit);
    } catch (e) {
      debugPrint('Analytics: Failed to get popular features: $e');
      return [];
    }
  }

  // ================ HELPER METHODS ================

  /// Saves an event to Firestore.
  Future<void> _saveEventToFirestore(AnalyticsEvent event) async {
    try {
      await _firestore
          .collection(_analyticsCollection)
          .doc(event.id)
          .set(event.toJson());
    } catch (e) {
      debugPrint('Analytics: Failed to save event to Firestore: $e');
    }
  }

  /// Gets basic device information for analytics.
  String _getDeviceInfo() {
    return '${defaultTargetPlatform.toString()}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Calculates analytics metrics for a user.
  Map<String, dynamic> _calculateUserAnalytics(List<AnalyticsEvent> events) {
    final totalEvents = events.length;
    final uniqueSessions = events.map((e) => e.sessionId).toSet().length;
    
    // Calculate event type breakdown
    final Map<String, int> eventTypeBreakdown = {};
    for (final event in events) {
      eventTypeBreakdown[event.eventType] = (eventTypeBreakdown[event.eventType] ?? 0) + 1;
    }

    // Calculate daily activity
    final Map<String, int> dailyActivity = {};
    for (final event in events) {
      final dateKey = event.timestamp.toIso8601String().split('T')[0];
      dailyActivity[dateKey] = (dailyActivity[dateKey] ?? 0) + 1;
    }

    // Calculate most used features
    final Map<String, int> featureUsage = {};
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
    final Map<String, int> memberActivity = {};
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
      'most_active_member': memberActivity.isNotEmpty 
          ? memberActivity.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
    };
  }

  /// Calculates popular features based on usage frequency.
  List<Map<String, dynamic>> _calculatePopularFeatures(List<AnalyticsEvent> events, int limit) {
    final Map<String, int> featureUsage = {};
    
    for (final event in events) {
      featureUsage[event.eventName] = (featureUsage[event.eventName] ?? 0) + 1;
    }

    final sortedFeatures = featureUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedFeatures.take(limit).map((entry) => {
      'feature_name': entry.key,
      'usage_count': entry.value,
      'usage_percentage': (entry.value / events.length * 100).toStringAsFixed(1),
    }).toList();
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
  Future<void> dispose() async {
    trackSessionEnd();
    super.dispose();
  }
} 