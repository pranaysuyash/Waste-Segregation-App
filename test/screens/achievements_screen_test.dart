import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waste_segregation_app/providers/app_providers.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/screens/achievements_screen.dart';
import 'package:waste_segregation_app/services/points_engine.dart';
import 'package:waste_segregation_app/utils/constants.dart';

class FakePointsEngine extends Fake implements PointsEngine {
  FakePointsEngine(this._profile);

  final GamificationProfile _profile;

  @override
  GamificationProfile? get currentProfile => _profile;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> refresh() async {}
}

void main() {
  group('AchievementsScreen', () {
    testWidgets('renders with a populated profile', (tester) async {
      final profile = GamificationProfile(
        userId: 'test_user',
        streaks: const {},
        points: const UserPoints(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pointsEngineProvider.overrideWithValue(FakePointsEngine(profile)),
          ],
          child: const MaterialApp(home: AchievementsScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text(AppStrings.achievements), findsOneWidget);
    });
  });
}
