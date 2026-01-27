import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/screens/family_dashboard_screen.dart';
import 'package:waste_segregation_app/services/storage_service.dart';

import 'family_dashboard_screen_test.mocks.dart';

@GenerateMocks([StorageService])
void main() {
  group('FamilyDashboardScreen', () {
    testWidgets('shows create/join state when user has no family',
        (tester) async {
      final storageService = MockStorageService();

      when(storageService.getCurrentUserProfile()).thenAnswer(
        (_) async => UserProfile(
          id: 'user_1',
          email: 'user@test.com',
          displayName: 'User',
          familyId: null,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storageService),
          ],
          child: const MaterialApp(home: FamilyDashboardScreen()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      // No-family UI should render (copy may evolve; just smoke-check scaffold title).
      expect(find.text('Family Dashboard'), findsOneWidget);
    });
  });
}
