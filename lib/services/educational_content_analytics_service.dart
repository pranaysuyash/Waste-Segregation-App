import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to track educational content engagement and analytics
class EducationalContentAnalyticsService extends ChangeNotifier {
  static const String _viewsKey = 'educational_views';
  static const String _timeSpentKey = 'educational_time_spent';
  static const String _completionsKey = 'educational_completions';
  static const String _interactionsKey = 'educational_interactions';
  static const String _favoritesKey = 'educational_favorites';
  static const String _searchQueriesKey = 'educational_searches';
  static const String _categoryPreferencesKey = 'category_preferences';

  // In-memory analytics data
  Map<String, ContentAnalytics> _contentAnalytics = {};
  Map<String, int> _categoryViews = {};
  Map<String, int> _searchQueries = {};
  Map<String, DateTime> _lastViewed = {};
  List<String> _recentlyViewed = [];
  List<String> _favoriteContent = [];
  
  // Current session tracking
  String? _currentContentId;
  DateTime? _sessionStartTime;
  final Map<String, Duration> _sessionTimes = {};

  EducationalContentAnalyticsService() {
    _loadAnalytics();
  }

  // ==================== PUBLIC GETTERS ====================

  /// Get analytics for specific content
  ContentAnalytics getContentAnalytics(String contentId) {
    return _contentAnalytics[contentId] ?? ContentAnalytics(
      contentId: contentId,
      views: 0,
      totalTimeSpent: Duration.zero,
      completions: 0,
      lastViewed: null,
      isFavorite: false,
    );
  }

  /// Get most viewed content
  List<String> getMostViewedContent({int limit = 10}) {
    final sortedAnalytics = _contentAnalytics.entries.toList()
      ..sort((a, b) => b.value.views.compareTo(a.value.views));
    
    return sortedAnalytics
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get recently viewed content
  List<String> getRecentlyViewed({int limit = 10}) {
    return _recentlyViewed.take(limit).toList();
  }

  /// Get favorite content
  List<String> getFavoriteContent() {
    return List<String>.from(_favoriteContent);
  }

  /// Get popular categories based on views
  List<MapEntry<String, int>> getPopularCategories() {
    final sortedCategories = _categoryViews.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedCategories;
  }

  /// Get total engagement metrics
  EngagementMetrics getTotalEngagementMetrics() {
    int totalViews = 0;
    Duration totalTimeSpent = Duration.zero;
    int totalCompletions = 0;
    int totalInteractions = 0;

    for (final analytics in _contentAnalytics.values) {
      totalViews += analytics.views;
      totalTimeSpent += analytics.totalTimeSpent;
      totalCompletions += analytics.completions;
      totalInteractions += analytics.interactions;
    }

    return EngagementMetrics(
      totalViews: totalViews,
      totalTimeSpent: totalTimeSpent,
      totalCompletions: totalCompletions,
      totalInteractions: totalInteractions,
      uniqueContentViewed: _contentAnalytics.length,
      favoriteCount: _favoriteContent.length,
    );
  }

  /// Get learning streak (days with educational content interaction)
  int getLearningStreak() {
    if (_lastViewed.isEmpty) return 0;

    final now = DateTime.now();
    final sortedDates = _lastViewed.values.toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime currentDate = DateTime(now.year, now.month, now.day);

    for (final viewDate in sortedDates) {
      final viewDay = DateTime(viewDate.year, viewDate.month, viewDate.day);
      
      if (viewDay == currentDate || 
          currentDate.difference(viewDay).inDays == 1) {
        streak++;
        currentDate = viewDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Get personalized content recommendations
  List<String> getPersonalizedRecommendations({
    required List<EducationalContent> allContent,
    int limit = 5,
  }) {
    final recommendations = <String>[];
    
    // Get user's favorite categories
    final favoriteCategories = getPopularCategories()
        .take(3)
        .map((entry) => entry.key)
        .toList();

    // Find content in favorite categories that hasn't been viewed much
    for (final content in allContent) {
      if (favoriteCategories.contains(content.category) &&
          getContentAnalytics(content.id).views < 3 &&
          !_recentlyViewed.contains(content.id)) {
        recommendations.add(content.id);
        if (recommendations.length >= limit) break;
      }
    }

    // Fill remaining slots with popular content
    if (recommendations.length < limit) {
      final popular = getMostViewedContent(limit: limit * 2);
      for (final contentId in popular) {
        if (!recommendations.contains(contentId) && 
            !_recentlyViewed.take(3).contains(contentId)) {
          recommendations.add(contentId);
          if (recommendations.length >= limit) break;
        }
      }
    }

    return recommendations;
  }

  // ==================== TRACKING METHODS ====================

  /// Track content view
  Future<void> trackContentView(String contentId, String category) async {
    try {
      final analytics = getContentAnalytics(contentId);
      final updatedAnalytics = analytics.copyWith(
        views: analytics.views + 1,
        lastViewed: DateTime.now(),
      );

      _contentAnalytics[contentId] = updatedAnalytics;
      _updateRecentlyViewed(contentId);
      _updateCategoryViews(category);
      _lastViewed[contentId] = DateTime.now();

      await _saveAnalytics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error tracking content view: $e');
    }
  }

  /// Start content session (for time tracking)
  void startContentSession(String contentId) {
    _endCurrentSession(); // End any existing session
    
    _currentContentId = contentId;
    _sessionStartTime = DateTime.now();
  }

  /// End content session and track time spent
  Future<void> endContentSession({bool wasCompleted = false}) async {
    if (_currentContentId == null || _sessionStartTime == null) return;

    try {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      final contentId = _currentContentId!;
      
      final analytics = getContentAnalytics(contentId);
      final updatedAnalytics = analytics.copyWith(
        totalTimeSpent: analytics.totalTimeSpent + sessionDuration,
        completions: wasCompleted ? analytics.completions + 1 : analytics.completions,
      );

      _contentAnalytics[contentId] = updatedAnalytics;
      _sessionTimes[contentId] = sessionDuration;

      await _saveAnalytics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error ending content session: $e');
    } finally {
      _currentContentId = null;
      _sessionStartTime = null;
    }
  }

  /// Track content interaction (like, share, bookmark, etc.)
  Future<void> trackContentInteraction(String contentId, ContentInteractionType type) async {
    try {
      final analytics = getContentAnalytics(contentId);
      final updatedAnalytics = analytics.copyWith(
        interactions: analytics.interactions + 1,
      );

      _contentAnalytics[contentId] = updatedAnalytics;

      // Track specific interaction types
      switch (type) {
        case ContentInteractionType.favorite:
          await _toggleFavorite(contentId, true);
          break;
        case ContentInteractionType.unfavorite:
          await _toggleFavorite(contentId, false);
          break;
        case ContentInteractionType.share:
        case ContentInteractionType.bookmark:
        case ContentInteractionType.like:
          // These are tracked in general interactions count
          break;
      }

      await _saveAnalytics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error tracking content interaction: $e');
    }
  }

  /// Track search query
  Future<void> trackSearchQuery(String query, {int resultsCount = 0}) async {
    if (query.trim().isEmpty) return;

    try {
      final normalizedQuery = query.toLowerCase().trim();
      _searchQueries[normalizedQuery] = (_searchQueries[normalizedQuery] ?? 0) + 1;

      await _saveAnalytics();
    } catch (e) {
      debugPrint('Error tracking search query: $e');
    }
  }

  /// Get popular search queries
  List<MapEntry<String, int>> getPopularSearchQueries({int limit = 10}) {
    final sortedQueries = _searchQueries.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedQueries.take(limit).toList();
  }

  // ==================== PRIVATE METHODS ====================

  void _endCurrentSession() {
    if (_currentContentId != null) {
      endContentSession(); // This will save and clear current session
    }
  }

  void _updateRecentlyViewed(String contentId) {
    _recentlyViewed.remove(contentId); // Remove if already exists
    _recentlyViewed.insert(0, contentId); // Add to front
    
    // Keep only last 50 items
    if (_recentlyViewed.length > 50) {
      _recentlyViewed = _recentlyViewed.take(50).toList();
    }
  }

  void _updateCategoryViews(String category) {
    _categoryViews[category] = (_categoryViews[category] ?? 0) + 1;
  }

  Future<void> _toggleFavorite(String contentId, bool isFavorite) async {
    if (isFavorite) {
      if (!_favoriteContent.contains(contentId)) {
        _favoriteContent.add(contentId);
      }
    } else {
      _favoriteContent.remove(contentId);
    }

    final analytics = getContentAnalytics(contentId);
    _contentAnalytics[contentId] = analytics.copyWith(isFavorite: isFavorite);
  }

  // ==================== PERSISTENCE ====================

  Future<void> _loadAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load content analytics
      final viewsJson = prefs.getString(_viewsKey);
      if (viewsJson != null) {
        // Parse and load stored analytics data
        // Implementation would depend on your JSON serialization approach
      }

      // Load category preferences
      final categoryJson = prefs.getString(_categoryPreferencesKey);
      if (categoryJson != null) {
        // Parse and load category data
      }

      // Load favorites
      _favoriteContent = prefs.getStringList(_favoritesKey) ?? [];

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    }
  }

  Future<void> _saveAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save content analytics
      // Convert _contentAnalytics to JSON and save
      
      // Save category views
      // Convert _categoryViews to JSON and save
      
      // Save search queries
      // Convert _searchQueries to JSON and save
      
      // Save favorites
      await prefs.setStringList(_favoritesKey, _favoriteContent);
      
    } catch (e) {
      debugPrint('Error saving analytics: $e');
    }
  }

  /// Clear all analytics data
  Future<void> clearAllAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_viewsKey);
      await prefs.remove(_timeSpentKey);
      await prefs.remove(_completionsKey);
      await prefs.remove(_interactionsKey);
      await prefs.remove(_favoritesKey);
      await prefs.remove(_searchQueriesKey);
      await prefs.remove(_categoryPreferencesKey);

      _contentAnalytics.clear();
      _categoryViews.clear();
      _searchQueries.clear();
      _lastViewed.clear();
      _recentlyViewed.clear();
      _favoriteContent.clear();
      _sessionTimes.clear();

      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing analytics: $e');
    }
  }

  /// Export analytics data for user
  Map<String, dynamic> exportAnalyticsData() {
    final metrics = getTotalEngagementMetrics();
    
    return {
      'totalMetrics': {
        'totalViews': metrics.totalViews,
        'totalTimeSpent': metrics.totalTimeSpent.inMinutes,
        'totalCompletions': metrics.totalCompletions,
        'uniqueContentViewed': metrics.uniqueContentViewed,
        'favoriteCount': metrics.favoriteCount,
        'learningStreak': getLearningStreak(),
      },
      'topCategories': getPopularCategories().take(5).map((entry) => {
        'category': entry.key,
        'views': entry.value,
      }).toList(),
      'recentContent': _recentlyViewed.take(10).toList(),
      'favoriteContent': _favoriteContent,
      'searchHistory': getPopularSearchQueries(limit: 10).map((entry) => {
        'query': entry.key,
        'count': entry.value,
      }).toList(),
    };
  }
}

// ==================== SUPPORTING CLASSES ====================

/// Analytics data for individual content
class ContentAnalytics {
  final String contentId;
  final int views;
  final Duration totalTimeSpent;
  final int completions;
  final int interactions;
  final DateTime? lastViewed;
  final bool isFavorite;

  const ContentAnalytics({
    required this.contentId,
    required this.views,
    required this.totalTimeSpent,
    required this.completions,
    this.interactions = 0,
    this.lastViewed,
    this.isFavorite = false,
  });

  ContentAnalytics copyWith({
    int? views,
    Duration? totalTimeSpent,
    int? completions,
    int? interactions,
    DateTime? lastViewed,
    bool? isFavorite,
  }) {
    return ContentAnalytics(
      contentId: contentId,
      views: views ?? this.views,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      completions: completions ?? this.completions,
      interactions: interactions ?? this.interactions,
      lastViewed: lastViewed ?? this.lastViewed,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Get engagement score (0-100)
  double get engagementScore {
    double score = 0;
    
    // Views contribute 30%
    score += (views * 5).clamp(0, 30);
    
    // Time spent contributes 40%
    final timeMinutes = totalTimeSpent.inMinutes;
    score += (timeMinutes * 2).clamp(0, 40);
    
    // Completions contribute 20%
    score += (completions * 10).clamp(0, 20);
    
    // Interactions contribute 10%
    score += (interactions * 2).clamp(0, 10);
    
    return score.clamp(0, 100);
  }
}

/// Overall engagement metrics
class EngagementMetrics {
  final int totalViews;
  final Duration totalTimeSpent;
  final int totalCompletions;
  final int totalInteractions;
  final int uniqueContentViewed;
  final int favoriteCount;

  const EngagementMetrics({
    required this.totalViews,
    required this.totalTimeSpent,
    required this.totalCompletions,
    required this.totalInteractions,
    required this.uniqueContentViewed,
    required this.favoriteCount,
  });

  /// Get average time per content viewed
  Duration get averageTimePerContent {
    if (uniqueContentViewed == 0) return Duration.zero;
    return Duration(
      milliseconds: totalTimeSpent.inMilliseconds ~/ uniqueContentViewed,
    );
  }

  /// Get completion rate
  double get completionRate {
    if (totalViews == 0) return 0.0;
    return totalCompletions / totalViews;
  }
}

/// Types of content interactions
enum ContentInteractionType {
  favorite,
  unfavorite,
  share,
  bookmark,
  like,
}

/// Simple educational content model for analytics
class EducationalContent {
  final String id;
  final String title;
  final String category;
  final String type;

  const EducationalContent({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
  });
} 