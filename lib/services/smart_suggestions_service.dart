import 'dart:math';
import '../models/waste_classification.dart';
import '../services/storage_service.dart';
import '../services/offline_queue_service.dart';
import '../utils/waste_app_logger.dart';

/// Track 4: Smart Suggestions Service
/// Analyzes user behavior and offline queue data to provide personalized suggestions
class SmartSuggestionsService {
  SmartSuggestionsService(this._storageService, this._queueService);

  final StorageService _storageService;
  final OfflineQueueService _queueService;

  /// Get smart suggestions based on user behavior patterns
  Future<List<SmartSuggestion>> getSmartSuggestions() async {
    final suggestions = <SmartSuggestion>[];

    try {
      // Analyze classification patterns
      final classifications = await _storageService.getAllClassifications();
      if (classifications.isEmpty) {
        return [SmartSuggestion.welcomeSuggestion()];
      }

      // Analyze offline queue usage
      final queueStats = _queueService.getQueueStats();
      final hasUsedOfflineQueue = queueStats['totalQueued']! > 0;

      // Analyze classification confidence patterns
      final lowConfidenceCount = classifications.where((c) => (c.confidence ?? 0) < 0.7).length;
      final hasLowConfidenceIssues = lowConfidenceCount > classifications.length * 0.3;

      // Analyze category distribution
      final categoryCounts = <String, int>{};
      for (final classification in classifications) {
        categoryCounts[classification.category] = (categoryCounts[classification.category] ?? 0) + 1;
      }

      // Generate suggestions based on patterns

      // 1. Offline queue suggestion
      if (!hasUsedOfflineQueue && classifications.length >= 3) {
        suggestions.add(SmartSuggestion.offlineQueueSuggestion());
      }

      // 2. Photo quality improvement suggestion
      if (hasLowConfidenceIssues) {
        suggestions.add(SmartSuggestion.photoQualitySuggestion());
      }

      // 3. Category exploration suggestion
      final mostCommonCategory = categoryCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      if (categoryCounts.length < 5 && classifications.length >= 5) {
        suggestions.add(SmartSuggestion.categoryExplorationSuggestion(mostCommonCategory));
      }

      // 4. Batch processing suggestion
      if (classifications.length >= 10 && !hasUsedOfflineQueue) {
        suggestions.add(SmartSuggestion.batchProcessingSuggestion());
      }

      // 5. Community contribution suggestion
      if (classifications.length >= 5) {
        suggestions.add(SmartSuggestion.communityContributionSuggestion());
      }

      // 6. Achievement progress suggestion
      final userProfile = await _storageService.getCurrentUserProfile();
      if (userProfile?.gamificationProfile != null) {
        final profile = userProfile!.gamificationProfile!;
        final totalPoints = profile.points.total;

        if (totalPoints < 100) {
          suggestions.add(SmartSuggestion.achievementProgressSuggestion(totalPoints));
        }
      }

      // Limit to top 3 most relevant suggestions
      return suggestions.take(3).toList();

    } catch (e) {
      WasteAppLogger.warning('Error generating smart suggestions: $e');
      return [SmartSuggestion.errorSuggestion()];
    }
  }
}

/// Represents a smart suggestion for the user
class SmartSuggestion {
  const SmartSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.priority,
    this.actionText,
    this.actionRoute,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final String color;
  final int priority; // 1 = highest, 3 = lowest
  final String? actionText;
  final String? actionRoute;

  // Factory methods for different suggestion types

  factory SmartSuggestion.welcomeSuggestion() {
    return const SmartSuggestion(
      id: 'welcome',
      title: 'Welcome to Waste Segregation!',
      description: 'Start by taking a photo of waste to get your first classification.',
      icon: '🎉',
      color: 'green',
      priority: 1,
      actionText: 'Take Photo',
      actionRoute: '/camera',
    );
  }

  factory SmartSuggestion.offlineQueueSuggestion() {
    return const SmartSuggestion(
      id: 'offline_queue',
      title: 'Try Offline Mode',
      description: 'Classify waste even without internet! Your photos will be processed when you reconnect.',
      icon: '📱',
      color: 'blue',
      priority: 2,
      actionText: 'Learn More',
      actionRoute: '/settings',
    );
  }

  factory SmartSuggestion.photoQualitySuggestion() {
    return const SmartSuggestion(
      id: 'photo_quality',
      title: 'Improve Photo Quality',
      description: 'Take clearer photos in good lighting for more accurate classifications.',
      icon: '📸',
      color: 'orange',
      priority: 1,
      actionText: 'Camera Tips',
      actionRoute: '/camera',
    );
  }

  factory SmartSuggestion.categoryExplorationSuggestion(String commonCategory) {
    return SmartSuggestion(
      id: 'category_exploration',
      title: 'Explore New Categories',
      description: 'You classify mostly $commonCategory. Try classifying different types of waste!',
      icon: '🔍',
      color: 'purple',
      priority: 3,
      actionText: 'Browse Categories',
      actionRoute: '/analytics',
    );
  }

  factory SmartSuggestion.batchProcessingSuggestion() {
    return const SmartSuggestion(
      id: 'batch_processing',
      title: 'Process Multiple Items',
      description: 'Take photos of multiple waste items and classify them all at once.',
      icon: '📦',
      color: 'teal',
      priority: 2,
      actionText: 'Batch Mode',
      actionRoute: '/camera',
    );
  }

  factory SmartSuggestion.communityContributionSuggestion() {
    return const SmartSuggestion(
      id: 'community_contribution',
      title: 'Help the Community',
      description: 'Contribute disposal information for facilities in your area.',
      icon: '🤝',
      color: 'green',
      priority: 3,
      actionText: 'Contribute',
      actionRoute: '/contribution',
    );
  }

  factory SmartSuggestion.achievementProgressSuggestion(int currentPoints) {
    final nextMilestone = ((currentPoints ~/ 50) + 1) * 50;
    final pointsNeeded = nextMilestone - currentPoints;

    return SmartSuggestion(
      id: 'achievement_progress',
      title: 'Achievement Progress',
      description: 'Earn $pointsNeeded more points to reach $nextMilestone points!',
      icon: '🏆',
      color: 'gold',
      priority: 1,
      actionText: 'View Achievements',
      actionRoute: '/achievements',
    );
  }

  factory SmartSuggestion.errorSuggestion() {
    return const SmartSuggestion(
      id: 'error',
      title: 'Smart Suggestions Unavailable',
      description: 'Unable to load personalized suggestions at this time.',
      icon: '⚠️',
      color: 'red',
      priority: 3,
    );
  }
}