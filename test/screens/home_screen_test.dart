import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:waste_segregation_app/models/educational_content.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/providers/app_providers.dart' as app_providers;
import 'package:waste_segregation_app/screens/home_screen.dart';
import 'package:waste_segregation_app/screens/ultra_modern_home_screen.dart' as home;
import 'package:waste_segregation_app/services/ad_service.dart';
import 'package:waste_segregation_app/services/educational_content_service.dart';
import 'package:waste_segregation_app/utils/constants.dart';

void main() {
  final mockProfile = GamificationProfile(
    userId: 'test_user',
    points: const UserPoints(total: 500),
    streaks: {},
    achievements: [],
    discoveredItemIds: [],
    unlockedHiddenContentIds: [],
  );

  final mockUserProfile = UserProfile(
    id: 'test_user',
    displayName: 'Jane',
    email: 'jane@test.com',
    createdAt: DateTime.now(),
  );

  final mockClassification = WasteClassification(
    id: 'test-1',
    itemName: 'Plastic Bottle',
    category: 'Dry Waste',
    explanation: 'A recyclable plastic bottle',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Recycle',
      steps: ['Rinse', 'Recycle'],
      hasUrgentTimeframe: false,
    ),
    region: 'Test',
    visualFeatures: ['plastic'],
    alternatives: [],
    confidence: 0.92,
    timestamp: DateTime.now(),
  );

  Widget buildApp({
    required EducationalContentService educationalService,
    List<WasteClassification> classifications = const [],
  }) {
    return provider_pkg.MultiProvider(
      providers: [
        provider_pkg.ChangeNotifierProvider<AdService>(create: (_) => AdService()),
      ],
      child: ProviderScope(
        overrides: [
          home.profileProvider.overrideWith((ref) async => mockProfile),
          home.userProfileProvider.overrideWith((ref) async => mockUserProfile),
          home.classificationsProvider.overrideWith((ref) async => classifications),
          app_providers.educationalContentServiceProvider.overrideWith((ref) => educationalService),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
  }

  group('Home Screen - Daily Tip', () {
    testWidgets('shows daily tip card', (WidgetTester tester) async {
      final service = EducationalContentService();
      await tester.pumpWidget(
        buildApp(educationalService: service),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining("Today's Sorting Tip"), findsOneWidget);
    });

    testWidgets('daily tip card has action icon', (
      WidgetTester tester,
    ) async {
      final service = _TestEducationalContentService();
      await tester.pumpWidget(
        buildApp(educationalService: service),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining("Today's Sorting Tip"), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });

  group('Home Screen - Empty State', () {
    testWidgets('shows empty state when no classifications', (
      WidgetTester tester,
    ) async {
      final service = EducationalContentService();
      await tester.pumpWidget(
        buildApp(educationalService: service),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.startYourJourney), findsOneWidget);
      expect(find.text(AppStrings.takeFirstPhoto), findsOneWidget);
    });
  });

  group('Home Screen - With Classifications', () {
    testWidgets('shows recent classification card', (
      WidgetTester tester,
    ) async {
      final service = EducationalContentService();
      await tester.pumpWidget(
        buildApp(
          educationalService: service,
          classifications: [mockClassification],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Plastic Bottle'), findsOneWidget);
      // "Dry Waste" appears in both the classification card and
      // the CommunityImpactCard's "Most common" row.
      expect(find.text('Dry Waste'), findsAtLeastNWidgets(2));
    });
  });
}

class _TestEducationalContentService extends EducationalContentService {
  @override
  DailyTip getDailyTipForHome({DateTime? date, String? preferredCategory}) {
    return DailyTip(
      id: 'test_tip',
      title: 'Test Tip',
      content: 'Test content for tap',
      category: 'General',
      date: DateTime.now(),
    );
  }
}
