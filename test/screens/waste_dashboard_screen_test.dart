import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mocktail/mocktail.dart' as mt;
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/providers/points_engine_provider.dart';
import 'package:waste_segregation_app/screens/waste_dashboard_screen.dart';
import 'package:waste_segregation_app/services/points_engine.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'waste_dashboard_screen_test.mocks.dart';

class FakePointsEngine extends mt.Fake implements PointsEngine {
  FakePointsEngine(this._profile);

  final GamificationProfile _profile;

  @override
  GamificationProfile? get currentProfile => _profile;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> refresh() async {}
}

class FakePointsEngineProvider extends ChangeNotifier
    implements PointsEngineProvider {
  FakePointsEngineProvider(this._engine);

  final PointsEngine _engine;

  @override
  PointsEngine get pointsEngine => _engine;

  @override
  void dispose() {
    super.dispose();
  }
}

WasteClassification buildClassification(
  String itemName,
  String category, {
  required int hoursAgo,
  bool recyclable = false,
}) {
  return WasteClassification(
    itemName: itemName,
    category: category,
    explanation: '$itemName classified for dashboard testing',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Follow local guidelines',
      steps: const ['Sort it', 'Place it in the right bin'],
      hasUrgentTimeframe: false,
    ),
    region: 'Test Region',
    visualFeatures: const ['test'],
    alternatives: const [],
    timestamp: DateTime.now().subtract(Duration(hours: hoursAgo)),
    isRecyclable: recyclable,
  );
}

@GenerateMocks([StorageService, GamificationService])
void main() {
  GamificationProfile buildProfile() {
    return GamificationProfile(
      userId: 'test_user',
      streaks: {
        StreakType.dailyClassification.toString(): StreakDetails(
          type: StreakType.dailyClassification,
          currentCount: 7,
          longestCount: 12,
          lastActivityDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      },
      points: const UserPoints(
        total: 240,
        weeklyTotal: 90,
        monthlyTotal: 180,
        categoryPoints: {
          'Dry Waste': 120,
          'Wet Waste': 80,
          'Hazardous Waste': 40,
        },
      ),
      achievements: const [],
      activeChallenges: const [],
      completedChallenges: const [],
    );
  }

  group('WasteDashboardScreen', () {
    testWidgets('shows empty state when there is no data', (tester) async {
      final storageService = MockStorageService();
      final gamificationService = MockGamificationService();

      when(gamificationService.syncGamificationData()).thenAnswer((_) async {});
      when(gamificationService.syncWeeklyStatsWithClassifications())
          .thenAnswer((_) async {});
      when(storageService.getAllClassifications()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storageService),
            ChangeNotifierProvider<GamificationService>.value(
                value: gamificationService),
          ],
          child: const MaterialApp(home: WasteDashboardScreen()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.text('No Data Yet'), findsOneWidget);
    });

    testWidgets('renders the populated dashboard shell', (tester) async {
      final storageService = MockStorageService();
      final gamificationService = MockGamificationService();
      final classifications = [
        buildClassification('Plastic Bottle', 'Dry Waste',
            hoursAgo: 1, recyclable: true),
        buildClassification('Food Scraps', 'Wet Waste', hoursAgo: 2),
        buildClassification('Old Battery', 'Hazardous Waste', hoursAgo: 3),
        buildClassification('Glass Jar', 'Dry Waste',
            hoursAgo: 4, recyclable: true),
      ];
      final profile = buildProfile();
      final pointsProvider =
          FakePointsEngineProvider(FakePointsEngine(profile));

      when(gamificationService.syncGamificationData()).thenAnswer((_) async {});
      when(gamificationService.syncWeeklyStatsWithClassifications())
          .thenAnswer((_) async {});
      when(storageService.getAllClassifications())
          .thenAnswer((_) async => classifications);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storageService),
            ChangeNotifierProvider<GamificationService>.value(
                value: gamificationService),
            ChangeNotifierProvider<PointsEngineProvider>.value(
                value: pointsProvider),
          ],
          child: const MaterialApp(home: WasteDashboardScreen()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('Waste Analytics Dashboard'), findsOneWidget);
      expect(find.text('Mission Control'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Waste Category Distribution'), findsOneWidget);
      expect(find.text('Recent Classifications'), findsOneWidget);
      expect(find.text('Your Environmental Impact'), findsOneWidget);
      expect(find.text('Your Gamification Progress'), findsOneWidget);
      expect(
          find.text(
              'Leaderboard coming soon! Compete with others to see who\'s the top recycler.'),
          findsOneWidget);
      expect(find.text('Dry Waste'), findsWidgets);
      expect(find.text('Wet Waste'), findsWidgets);
    });
  });
}
