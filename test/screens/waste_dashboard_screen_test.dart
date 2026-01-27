import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/screens/waste_dashboard_screen.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';

import 'waste_dashboard_screen_test.mocks.dart';

@GenerateMocks([StorageService, GamificationService])
void main() {
  group('WasteDashboardScreen', () {
    testWidgets('shows empty state when there is no data', (tester) async {
      final storageService = MockStorageService();
      final gamificationService = MockGamificationService();

      when(gamificationService.syncGamificationData())
          .thenAnswer((_) async {});
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
  });
}
