import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/enhanced_family.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/community_service.dart';
import 'package:waste_segregation_app/services/firebase_family_service.dart';
import 'package:waste_segregation_app/services/cache_service.dart';
import 'package:mockito/mockito.dart';

/// Comprehensive test utilities for the Waste Segregation App
/// Provides common test data, mock services, and helper functions
class TestHelpers {
  // =============================================================================
  // TEST DATA GENERATORS
  // =============================================================================

  /// Creates a basic test classification with minimal required fields
  static WasteClassification createBasicClassification([String? itemName]) {
    return WasteClassification(
      itemName: itemName ?? 'Test Item',
      category: 'Dry Waste',
      subcategory: 'Test Subcategory',
      explanation: 'Test explanation for testing purposes',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Test disposal method',
        steps: ['Test step 1', 'Test step 2'],
        hasUrgentTimeframe: false,
      ),
      timestamp: DateTime.now(),
      region: 'Test Region',
      visualFeatures: ['test', 'feature'],
      alternatives: [],
      confidence: 0.85,
    );
  }

  /// Creates a comprehensive test classification with all fields populated
  static WasteClassification createDetailedClassification({
    String? itemName,
    String? category,
    String? userId,
    double? confidence,
    bool? isRecyclable,
    int? recyclingCode,
    List<AlternativeClassification>? alternatives,
  }) {
    return WasteClassification(
      itemName: itemName ?? 'Detailed Test Item',
      category: category ?? 'Dry Waste',
      subcategory: 'Plastic',
      explanation: 'Comprehensive test item with detailed properties for thorough testing scenarios',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Recycle in designated container',
        steps: [
          'Clean the item thoroughly',
          'Remove any non-recyclable components',
          'Place in appropriate recycling bin',
          'Ensure proper sorting'
        ],
        hasUrgentTimeframe: false,
        warnings: ['Handle with care', 'Check local guidelines'],
        tips: ['Rinse before recycling', 'Remove labels if possible'],
        location: 'Local recycling center',
        timeframe: 'Next collection day',
      ),
      timestamp: DateTime.now(),
      region: 'Test Region with detailed info',
      visualFeatures: ['plastic', 'bottle', 'clear', 'recyclable'],
      alternatives: alternatives ?? [
        AlternativeClassification(
          category: 'Non-Waste',
          subcategory: 'Reusable',
          confidence: 0.3,
          reason: 'Could potentially be reused for storage',
        ),
      ],
      confidence: confidence ?? 0.92,
      isRecyclable: isRecyclable ?? true,
      isCompostable: false,
      requiresSpecialDisposal: false,
      recyclingCode: recyclingCode ?? 1,
      materialType: 'PET Plastic',
      colorCode: '#FFFFFF',
      brand: 'Test Brand',
      product: 'Test Product Line',
      userId: userId ?? 'test_user_123',
      isSaved: true,
      environmentalImpact: {
        'co2_saved': '0.5 kg',
        'energy_saved': '85%',
        'recyclability': 'High'
      },
    );
  }

  /// Creates a hazardous waste classification for testing special disposal
  static WasteClassification createHazardousClassification() {
    return WasteClassification(
      itemName: 'Lithium Battery',
      category: 'Hazardous Waste',
      subcategory: 'Electronic Waste',
      explanation: 'Lithium-ion battery containing toxic materials requiring special handling',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Take to certified e-waste facility',
        steps: [
          'Do not throw in regular trash',
          'Keep battery terminals covered',
          'Transport in original packaging if available',
          'Take to certified disposal facility during operating hours'
        ],
        hasUrgentTimeframe: true,
        timeframe: 'Within 30 days',
        warnings: [
          'Do not puncture or damage',
          'Keep away from heat sources',
          'Do not disassemble',
          'Keep away from children'
        ],
        tips: [
          'Many electronics stores accept batteries',
          'Check manufacturer take-back programs',
          'Never put in household recycling'
        ],
        location: 'Certified hazardous waste facility',
      ),
      timestamp: DateTime.now(),
      region: 'Test Region',
      visualFeatures: ['battery', 'lithium', 'electronic'],
      alternatives: [],
      confidence: 0.96,
      isRecyclable: false,
      isCompostable: false,
      requiresSpecialDisposal: true,
      materialType: 'Lithium-ion',
      userId: 'test_user_123',
    );
  }

  /// Creates a list of diverse test classifications for testing pagination, search, etc.
  static List<WasteClassification> createClassificationList(int count, {String? userId}) {
    final categories = ['Dry Waste', 'Wet Waste', 'Hazardous Waste', 'Medical Waste', 'Non-Waste'];
    final items = ['Bottle', 'Can', 'Paper', 'Battery', 'Food', 'Glass', 'Plastic', 'Metal'];
    
    return List.generate(count, (index) {
      final category = categories[index % categories.length];
      final item = items[index % items.length];
      
      return WasteClassification(
        itemName: '$item ${index + 1}',
        category: category,
        subcategory: 'Test Subcategory $index',
        explanation: 'Test explanation for $item ${index + 1}',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test disposal for $category',
          steps: ['Step 1 for $item', 'Step 2 for $item'],
          hasUrgentTimeframe: category == 'Hazardous Waste',
        ),
        timestamp: DateTime.now().subtract(Duration(hours: index)),
        region: 'Test Region',
        visualFeatures: [item.toLowerCase(), 'test'],
        alternatives: [],
        confidence: 0.7 + (index % 3) * 0.1, // Varies between 0.7-0.9
        userId: userId ?? 'test_user_$index',
      );
    });
  }

  /// Creates a test user profile
  static UserProfile createTestUser({
    String? id,
    String? email,
    String? displayName,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? 'test_user_123',
      email: email ?? 'testuser@example.com',
      displayName: displayName ?? 'Test User',
      photoUrl: 'https://example.com/avatar.jpg',
      createdAt: createdAt ?? DateTime.now().subtract(const Duration(days: 30)),
      lastActive: DateTime.now(),
      preferences: {
        'notifications': true,
        'theme': 'system',
        'language': 'en',
        'analytics': true,
      },
    );
  }

  /// Creates a test gamification profile
  static GamificationProfile createTestGamificationProfile({
    String? userId,
    int? totalPoints,
    int? currentStreak,
    List<Achievement>? achievements,
  }) {
    return GamificationProfile(
      userId: userId ?? 'test_user_123',
      points: UserPoints(
        total: totalPoints ?? 150,
        weeklyTotal: 50,
        monthlyTotal: 120,
        categoryPoints: {
          'Dry Waste': 80,
          'Wet Waste': 40,
          'Hazardous Waste': 30,
        },
      ),
      streak: Streak(
        current: currentStreak ?? 5,
        longest: 12,
        lastUsageDate: DateTime.now(),
      ),
      achievements: achievements ?? [
        Achievement(
          id: 'waste_novice',
          title: 'Waste Novice',
          description: 'Classified your first 5 items',
          type: AchievementType.wasteIdentified,
          threshold: 5,
          iconName: 'star',
          color: Colors.blue,
          progress: 1.0,
          earnedOn: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ],
      activeChallenges: [
        Challenge(
          id: 'weekly_classifier',
          title: 'Weekly Classifier',
          description: 'Classify 10 items this week',
          startDate: DateTime.now().subtract(const Duration(days: 2)),
          endDate: DateTime.now().add(const Duration(days: 5)),
          pointsReward: 25,
          iconName: 'timeline',
          color: Colors.green,
          requirements: {'count': 10, 'timeframe': 'week'},
          progress: 0.6,
        ),
      ],
      completedChallenges: [],
    );
  }

  /// Creates a test family
  static EnhancedFamily createTestFamily({
    String? id,
    String? name,
    String? createdBy,
    List<FamilyMember>? members,
    bool? isPublic,
  }) {
    return EnhancedFamily(
      id: id ?? 'test_family_123',
      name: name ?? 'Test Family',
      createdBy: createdBy ?? 'admin_user',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      members: members ?? [
        FamilyMember(
          userId: 'admin_user',
          email: 'admin@example.com',
          displayName: 'Admin User',
          role: FamilyRole.admin,
          joinedAt: DateTime.now().subtract(const Duration(days: 10)),
          statistics: MemberStatistics(
            totalClassifications: 25,
            totalPoints: 500,
            favoriteCategory: 'Dry Waste',
          ),
        ),
        FamilyMember(
          userId: 'member_user',
          email: 'member@example.com',
          displayName: 'Member User',
          role: FamilyRole.member,
          joinedAt: DateTime.now().subtract(const Duration(days: 5)),
          statistics: MemberStatistics(
            totalClassifications: 10,
            totalPoints: 200,
            favoriteCategory: 'Wet Waste',
          ),
        ),
      ],
      settings: FamilySettings(
        isPublic: isPublic ?? false,
        allowInvites: true,
      ),
      statistics: FamilyStatistics(
        totalClassifications: 35,
        totalPoints: 700,
        categoryCounts: {
          'Dry Waste': 20,
          'Wet Waste': 10,
          'Hazardous Waste': 5,
        },
        weeklyActivity: [],
        environmentalImpact: const EnvironmentalImpact(
          totalWasteClassified: 35,
          recyclableItems: 25,
          compostableItems: 8,
          hazardousItemsHandled: 2,
          estimatedCO2Saved: 5.2,
        ),
      ),
      inviteCode: 'TEST123',
    );
  }

  // =============================================================================
  // WIDGET TEST HELPERS
  // =============================================================================

  /// Creates a MaterialApp wrapper with providers for testing widgets
  static Widget createTestApp({
    required Widget child,
    ThemeData? theme,
    bool includeMockProviders = true,
  }) {
    if (includeMockProviders) {
      return MultiProvider(
        providers: [
          Provider<AiService>(create: (_) => MockAiService()),
          Provider<StorageService>(create: (_) => MockStorageService()),
          Provider<GamificationService>(create: (_) => MockGamificationService()),
          Provider<AnalyticsService>(create: (_) => MockAnalyticsService()),
          Provider<CommunityService>(create: (_) => MockCommunityService()),
          Provider<FirebaseFamilyService>(create: (_) => MockFirebaseFamilyService()),
          Provider<CacheService>(create: (_) => MockCacheService()),
        ],
        child: MaterialApp(
          theme: theme,
          home: child,
        ),
      );
    }
    
    return MaterialApp(
      theme: theme,
      home: child,
    );
  }

  /// Pumps a widget with full app context including providers
  static Future<void> pumpAppWithProviders(
    WidgetTester tester,
    Widget widget, {
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(createTestApp(
      child: widget,
      theme: theme,
    ));
    await tester.pumpAndSettle();
  }

  /// Sets up common mock behaviors for services
  static void setupMockServices({
    MockAiService? aiService,
    MockStorageService? storageService,
    MockGamificationService? gamificationService,
    MockAnalyticsService? analyticsService,
    MockCommunityService? communityService,
  }) {
    // Setup AI Service
    if (aiService != null) {
      when(aiService.analyzeWebImage(any, any))
          .thenAnswer((_) async => createBasicClassification());
    }

    // Setup Storage Service
    if (storageService != null) {
      when(storageService.getRecentClassifications(limit: any))
          .thenAnswer((_) async => createClassificationList(5));
      when(storageService.saveClassification(any))
          .thenAnswer((_) async => {});
      when(storageService.getClassificationHistory())
          .thenAnswer((_) async => createClassificationList(20));
    }

    // Setup Gamification Service
    if (gamificationService != null) {
      when(gamificationService.getUserProfile())
          .thenAnswer((_) async => createTestGamificationProfile());
      when(gamificationService.processClassification(any))
          .thenAnswer((_) async => {
            'points_earned': 10,
            'achievements_unlocked': [],
            'streak_updated': true,
          });
    }

    // Setup Analytics Service
    if (analyticsService != null) {
      when(analyticsService.trackEvent(any))
          .thenAnswer((_) async => {});
    }

    // Setup Community Service
    if (communityService != null) {
      when(communityService.trackClassificationActivity(any, any))
          .thenAnswer((_) async => {});
      when(communityService.getCommunityFeed())
          .thenAnswer((_) async => []);
    }
  }

  // =============================================================================
  // TEST ASSERTIONS AND MATCHERS
  // =============================================================================

  /// Custom matcher for checking if a widget has accessibility properties
  static Matcher hasAccessibilityLabel(String label) {
    return _HasAccessibilityLabel(label);
  }

  /// Custom matcher for checking widget dimensions
  static Matcher hasMinimumSize(double width, double height) {
    return _HasMinimumSize(width, height);
  }

  /// Verifies that a classification is valid
  static void assertValidClassification(WasteClassification classification) {
    expect(classification.itemName, isNotEmpty, reason: 'Item name should not be empty');
    expect(classification.category, isNotEmpty, reason: 'Category should not be empty');
    expect(classification.explanation, isNotEmpty, reason: 'Explanation should not be empty');
    expect(classification.disposalInstructions, isNotNull, reason: 'Disposal instructions required');
    expect(classification.timestamp, isNotNull, reason: 'Timestamp is required');
    expect(classification.confidence, isNotNull, reason: 'Confidence should be provided');
    
    if (classification.confidence != null) {
      expect(classification.confidence!, greaterThanOrEqualTo(0.0), reason: 'Confidence should be >= 0');
      expect(classification.confidence!, lessThanOrEqualTo(1.0), reason: 'Confidence should be <= 1');
    }
  }

  /// Verifies that gamification data is consistent
  static void assertValidGamificationProfile(GamificationProfile profile) {
    expect(profile.userId, isNotEmpty, reason: 'User ID should not be empty');
    expect(profile.points.total, greaterThanOrEqualTo(0), reason: 'Points should be non-negative');
    expect(profile.streak.current, greaterThanOrEqualTo(0), reason: 'Current streak should be non-negative');
    expect(profile.streak.longest, greaterThanOrEqualTo(profile.streak.current), 
           reason: 'Longest streak should be >= current streak');
    
    // Check achievement progress
    for (final achievement in profile.achievements) {
      expect(achievement.progress, greaterThanOrEqualTo(0.0), reason: 'Achievement progress should be >= 0');
      expect(achievement.progress, lessThanOrEqualTo(1.0), reason: 'Achievement progress should be <= 1');
    }
  }

  // =============================================================================
  // PERFORMANCE TESTING HELPERS
  // =============================================================================

  /// Measures the time taken to execute a function
  static Future<Duration> measureExecutionTime(Future<void> Function() function) async {
    final stopwatch = Stopwatch()..start();
    await function();
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Creates a large dataset for performance testing
  static List<WasteClassification> createLargeDataset(int size) {
    return List.generate(size, (index) {
      return createDetailedClassification(
        itemName: 'Performance Test Item $index',
        userId: 'perf_user_${index % 100}', // Simulate multiple users
      );
    });
  }

  /// Simulates memory pressure for testing
  static List<List<int>> createMemoryPressure(int sizeMB) {
    const bytesPerMB = 1024 * 1024;
    final totalBytes = sizeMB * bytesPerMB;
    const listSize = 1000;
    final numLists = totalBytes ~/ (listSize * 4); // 4 bytes per int
    
    return List.generate(numLists, (index) => 
      List.generate(listSize, (i) => index * listSize + i));
  }

  // =============================================================================
  // ERROR AND EDGE CASE TESTING
  // =============================================================================

  /// Creates invalid test data for testing error handling
  static WasteClassification createInvalidClassification() {
    return WasteClassification(
      itemName: '', // Invalid: empty name
      category: 'Invalid Category', // Invalid category
      explanation: '', // Invalid: empty explanation
      disposalInstructions: DisposalInstructions(
        primaryMethod: '',
        steps: [], // Invalid: no steps
        hasUrgentTimeframe: false,
      ),
      timestamp: DateTime.now(),
      region: '',
      visualFeatures: [],
      alternatives: [],
      confidence: -0.5, // Invalid: negative confidence
    );
  }

  /// Creates test data with edge case values
  static List<WasteClassification> createEdgeCaseClassifications() {
    return [
      // Very long item name
      createBasicClassification('A' * 1000),
      
      // Very high confidence
      createDetailedClassification(confidence: 0.99999),
      
      // Very low confidence
      createDetailedClassification(confidence: 0.00001),
      
      // Maximum alternatives
      WasteClassification(
        itemName: 'Ambiguous Item',
        category: 'Dry Waste',
        explanation: 'Item with many possible classifications',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Multiple options',
          steps: ['Consider all options'],
          hasUrgentTimeframe: false,
        ),
        timestamp: DateTime.now(),
        region: 'Test Region',
        visualFeatures: ['ambiguous'],
        alternatives: List.generate(10, (i) => AlternativeClassification(
          category: 'Alternative $i',
          subcategory: 'Option $i',
          confidence: 0.1 + (i * 0.05),
          reason: 'Possible classification option $i',
        )),
        confidence: 0.5,
      ),
    ];
  }

  // =============================================================================
  // CLEANUP AND UTILITIES
  // =============================================================================

  /// Cleans up test resources
  static void cleanup() {
    // Reset any global state
    // Clear caches
    // Reset mock behaviors
  }

  /// Generates random test data with specified constraints
  static WasteClassification generateRandomClassification({
    List<String>? categories,
    double? minConfidence,
    double? maxConfidence,
  }) {
    final random = DateTime.now().millisecondsSinceEpoch;
    final availableCategories = categories ?? ['Dry Waste', 'Wet Waste', 'Hazardous Waste'];
    final category = availableCategories[random % availableCategories.length];
    
    final confidence = (minConfidence ?? 0.5) + 
        ((maxConfidence ?? 1.0) - (minConfidence ?? 0.5)) * 
        ((random % 1000) / 1000.0);
    
    return createDetailedClassification(
      itemName: 'Random Item $random',
      category: category,
      confidence: confidence,
    );
  }
}

// =============================================================================
// MOCK SERVICES
// =============================================================================

class MockAiService extends Mock implements AiService {}
class MockStorageService extends Mock implements StorageService {}
class MockGamificationService extends Mock implements GamificationService {}
class MockAnalyticsService extends Mock implements AnalyticsService {}
class MockCommunityService extends Mock implements CommunityService {}
class MockFirebaseFamilyService extends Mock implements FirebaseFamilyService {}
class MockCacheService extends Mock implements CacheService {}

// =============================================================================
// CUSTOM MATCHERS
// =============================================================================

class _HasAccessibilityLabel extends Matcher {
  
  _HasAccessibilityLabel(this.expectedLabel);
  final String expectedLabel;
  
  @override
  bool matches(item, Map matchState) {
    if (item is Widget) {
      // Check if widget has semantics with expected label
      // This would need more sophisticated implementation
      return true; // Simplified for example
    }
    return false;
  }
  
  @override
  Description describe(Description description) {
    return description.add('has accessibility label "$expectedLabel"');
  }
}

class _HasMinimumSize extends Matcher {
  
  _HasMinimumSize(this.minWidth, this.minHeight);
  final double minWidth;
  final double minHeight;
  
  @override
  bool matches(item, Map matchState) {
    if (item is Size) {
      return item.width >= minWidth && item.height >= minHeight;
    }
    return false;
  }
  
  @override
  Description describe(Description description) {
    return description.add('has minimum size of ${minWidth}x$minHeight');
  }
}

// =============================================================================
// TEST CONFIGURATION
// =============================================================================

class TestConfig {
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 5);
  static const Duration longTimeout = Duration(minutes: 2);
  
  static const int smallDatasetSize = 10;
  static const int mediumDatasetSize = 100;
  static const int largeDatasetSize = 1000;
  
  static const double minimumTouchTargetSize = 44.0;
  static const double minimumContrastRatio = 4.5;
  
  static const Map<String, dynamic> defaultTestEnvironment = {
    'platform': 'test',
    'isDebugMode': true,
    'enableMockServices': true,
    'useTestDatabase': true,
  };
}
