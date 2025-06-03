import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Unused import
import '../models/gamification.dart';
import '../services/storage_service.dart';

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

  /// Gets user analytics data for a specific time period.
  Future<Map<String, dynamic>> getUserAnalytics(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (!_isFirestoreAvailable) {
        debugPrint('Analytics: Firestore not available for user analytics query');
        return {'error': 'Analytics service unavailable'};
      }
      
      final querySnapshot = await _firestore
          .collection(_analyticsCollection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final events = querySnapshot.docs
          .map((doc) => AnalyticsEvent.fromJson(doc.data()))
          .toList();

      return _aggregateUserAnalytics(events);
    } catch (e) {
      debugPrint('Analytics: Error getting user analytics: $e');
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
        debugPrint('Analytics: Firestore not available for system analytics query');
        return {'error': 'Analytics service unavailable'};
      }
      
      final querySnapshot = await _firestore
          .collection(_analyticsCollection)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final events = querySnapshot.docs
          .map((doc) => AnalyticsEvent.fromJson(doc.data()))
          .toList();

      return _aggregateSystemAnalytics(events);
    } catch (e) {
      debugPrint('Analytics: Error getting system analytics: $e');
      _isFirestoreAvailable = false;
      return {'error': 'Failed to fetch system analytics data'};
    }
  }

  /// Gets popular content analytics.
  Future<List<Map<String, dynamic>>> getPopularContent(int limit) async {
    try {
      if (!_isFirestoreAvailable) {
        debugPrint('Analytics: Firestore not available for popular content query');
        return [];
      }
      
      final querySnapshot = await _firestore
          .collection(_analyticsCollection)
          .where('eventType', isEqualTo: 'content_interaction')
          .orderBy('timestamp', descending: true)
          .limit(limit * 10) // Get more to account for duplicates
          .get();

      final events = querySnapshot.docs
          .map((doc) => AnalyticsEvent.fromJson(doc.data()))
          .toList();

      return _aggregateContentAnalytics(events, limit);
    } catch (e) {
      debugPrint('Analytics: Error getting popular content: $e');
      _isFirestoreAvailable = false;
      return [];
    }
  }

  // ================ ANALYTICS AGGREGATION ================
  
  /// Aggregate user analytics from events
  Map<String, dynamic> _aggregateUserAnalytics(List<AnalyticsEvent> events) {
    final eventCounts = <String, int>{};
    final dailyActivity = <String, int>{};
    var totalEvents = events.length;
    
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
      uniqueUsers.add(event.userId!);
          
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
        debugPrint('Analytics: Firestore not available, storing event locally');
        _pendingEvents.add(event);
        return;
      }
      
      await _firestore
          .collection('analytics_events')
          .doc(event.id)
          .set(event.toJson());
      debugPrint('Analytics: Event saved to Firestore successfully');
    } catch (e) {
      debugPrint('Analytics: Failed to save event to Firestore: $e');
      
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
    
    debugPrint('Analytics: Processing ${_pendingEvents.length} pending events');
    
    final eventsToProcess = List<AnalyticsEvent>.from(_pendingEvents);
    _pendingEvents.clear();
    
    for (final event in eventsToProcess) {
      try {
        await _firestore
            .collection('analytics_events')
            .doc(event.id)
            .set(event.toJson());
      } catch (e) {
        debugPrint('Analytics: Failed to process pending event: $e');
        // Add back to pending if still failing
        _pendingEvents.add(event);
        _isFirestoreAvailable = false;
        break;
      }
    }
    
    if (_pendingEvents.isEmpty) {
      debugPrint('✅ All pending analytics events processed successfully');
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
      'most_active_member': memberActivity.isNotEmpty 
          ? memberActivity.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
    };
  }

  /// Calculates popular features based on usage frequency.
  List<Map<String, dynamic>> _calculatePopularFeatures(List<AnalyticsEvent> events, int limit) {
    final featureUsage = <String, int>{};
    
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
      debugPrint('✅ Firestore connection established');
      
      // Sync any pending events
      await _syncPendingEvents();
    } catch (e) {
      _isFirestoreAvailable = false;
      debugPrint('❌ Firestore unavailable: $e');
      debugPrint('📱 Analytics will use local storage only');
      
      // Check if it's a permission error and provide helpful message
      if (e.toString().contains('PERMISSION_DENIED') || 
          e.toString().contains('has not been used') ||
          e.toString().contains('disabled')) {
        debugPrint('🔧 To fix: Enable Firestore API at https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=waste-segregation-app-df523');
      }
    }
  }
  
  /// Store analytics events locally when Firestore is unavailable
  void _storeEventsLocally() {
    debugPrint('Analytics: Storing ${_pendingEvents.length} events locally');
    // You could implement local storage here using Hive or SharedPreferences
    // For now, we'll just log the events for debugging
    for (final event in _pendingEvents) {
      debugPrint('Analytics Event: ${event.eventName} - ${event.eventType}');
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
      debugPrint('✅ Synced ${_pendingEvents.length} pending analytics events');
      _pendingEvents.clear();
      
      // Save cleared pending events to local storage
      await _storageService.saveAnalyticsEvents(_pendingEvents);
    } catch (e) {
      debugPrint('❌ Failed to sync pending events: $e');
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
    debugPrint('📱 Stored analytics event locally (${_pendingEvents.length} pending)');
  }
} 