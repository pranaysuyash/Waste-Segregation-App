import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/screens/auth_screen.dart';
import 'package:waste_segregation_app/services/google_drive_service.dart';
import 'package:waste_segregation_app/widgets/navigation_wrapper.dart';
import 'package:waste_segregation_app/utils/constants.dart';
import '../test_helper.dart';

// Mock classes for testing
class MockGoogleDriveService extends Mock implements GoogleDriveService {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  group('AuthScreen Critical Tests', () {
    late MockGoogleDriveService mockGoogleDriveService;

    setUpAll(() async {
      await TestHelper.setupCompleteTest();
    });

    tearDownAll(() async {
      await TestHelper.tearDownCompleteTest();
    });

    setUp(() {
      mockGoogleDriveService = MockGoogleDriveService();
    });

    Widget createTestableWidget({bool isWeb = false}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<GoogleDriveService>.value(
            value: mockGoogleDriveService,
          ),
        ],
        child: MaterialApp(
          home: const AuthScreen(),
          routes: {
            '/main': (context) => const MainNavigationWrapper(),
            '/main_guest': (context) => const MainNavigationWrapper(isGuestMode: true),
          },
        ),
      );
    }

    group('UI Rendering Tests', () {
      testWidgets('should render all essential UI elements', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Verify app logo
        expect(find.byIcon(Icons.restore_from_trash), findsOneWidget);

        // Verify app name and title
        expect(find.text(AppStrings.appName), findsOneWidget);
        expect(find.text('Join the Eco-Warriors Community'), findsOneWidget);

        // Verify welcome message
        expect(find.text(AppStrings.welcomeMessage), findsOneWidget);

        // Verify impact statistics cards
        expect(find.text('50K+'), findsOneWidget);
        expect(find.text('Items Classified'), findsOneWidget);
        expect(find.text('2.5T'), findsOneWidget);
        expect(find.text('CO₂ Saved'), findsOneWidget);
        expect(find.text('10K+'), findsOneWidget);
        expect(find.text('Eco-Warriors'), findsOneWidget);

        // Verify auth buttons
        expect(find.text(AppStrings.signInWithGoogle), findsOneWidget);
        expect(find.text(AppStrings.continueAsGuest), findsOneWidget);

        // Verify info message
        expect(find.text('Sign in to save your progress and sync data across devices'), findsOneWidget);
      });

      testWidgets('should display impact cards with correct icons', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Verify impact card icons
        expect(find.byIcon(Icons.recycling), findsOneWidget);
        expect(find.byIcon(Icons.eco), findsOneWidget);
        expect(find.byIcon(Icons.people), findsOneWidget);
      });

      testWidgets('should have proper visual styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Verify scaffold exists
        expect(find.byType(Scaffold), findsOneWidget);

        // Verify gradient container
        expect(find.byType(Container), findsWidgets);

        // Verify scrollable content
        expect(find.byType(SingleChildScrollView), findsOneWidget);

        // Verify safe area
        expect(find.byType(SafeArea), findsOneWidget);
      });

      testWidgets('should render auth cards with proper styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Verify Material widgets for auth cards
        expect(find.byType(Material), findsAtLeastNWidgets(2));

        // Verify InkWell for tap interactions
        expect(find.byType(InkWell), findsAtLeastNWidgets(2));

        // Verify icons in auth cards
        expect(find.byIcon(Icons.g_mobiledata), findsOneWidget);
        expect(find.byIcon(Icons.person_outline), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward_ios), findsAtLeastNWidgets(2));
      });
    });

    group('Google Sign-In Tests', () {
      testWidgets('should handle successful Google sign-in', (WidgetTester tester) async {
        // Mock successful sign-in
        when(mockGoogleDriveService.signIn()).thenAnswer((_) async => 'mock_user');

        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Find and tap Google sign-in button
        final googleSignInButton = find.text(AppStrings.signInWithGoogle);
        expect(googleSignInButton, findsOneWidget);

        await tester.tap(googleSignInButton);
        await tester.pump(); // Start the async operation

        // Verify loading state
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle(); // Complete the async operation

        // Verify sign-in was called
        verify(mockGoogleDriveService.signIn()).called(1);
      });

      testWidgets('should handle Google sign-in failure', (WidgetTester tester) async {
        // Mock sign-in failure
        when(mockGoogleDriveService.signIn()).thenThrow(Exception('Sign in failed'));

        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Tap Google sign-in button
        await tester.tap(find.text(AppStrings.signInWithGoogle));
        await tester.pump();

        // Wait for async operation and error handling
        await tester.pumpAndSettle();

        // Verify error snackbar is shown
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Sign in failed: Exception: Sign in failed'), findsOneWidget);

        // Verify sign-in was attempted
        verify(mockGoogleDriveService.signIn()).called(1);
      });

      testWidgets('should show loading indicator during sign-in', (WidgetTester tester) async {
        // Mock slow sign-in
        when(mockGoogleDriveService.signIn()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 500));
          return 'mock_user';
        });

        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Tap Google sign-in button
        await tester.tap(find.text(AppStrings.signInWithGoogle));
        await tester.pump();

        // Verify loading state
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Verify button is disabled during loading
        final googleButton = tester.widget<InkWell>(
          find.ancestor(
            of: find.byType(CircularProgressIndicator),
            matching: find.byType(InkWell),
          ),
        );
        expect(googleButton.onTap, isNull);

        await tester.pumpAndSettle();
      });

      testWidgets('should handle null user response from sign-in', (WidgetTester tester) async {
        // Mock sign-in returning null user
        when(mockGoogleDriveService.signIn()).thenAnswer((_) async => null);

        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppStrings.signInWithGoogle));
        await tester.pumpAndSettle();

        // Verify sign-in was called but no navigation occurred
        verify(mockGoogleDriveService.signIn()).called(1);

        // Should remain on auth screen
        expect(find.byType(AuthScreen), findsOneWidget);
      });

      testWidgets('should disable Google sign-in button during loading', (WidgetTester tester) async {
        when(mockGoogleDriveService.signIn()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return 'mock_user';
        });

        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Tap Google sign-in button
        await tester.tap(find.text(AppStrings.signInWithGoogle));
        await tester.pump();

        // Try to tap again while loading
        await tester.tap(find.byType(CircularProgressIndicator));
        await tester.pump();

        // Verify sign-in was called only once
        await tester.pumpAndSettle();
        verify(mockGoogleDriveService.signIn()).called(1);
      });
    });

    group('Guest Mode Tests', () {
      testWidgets('should handle guest mode navigation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Find and tap guest mode button
        final guestButton = find.text(AppStrings.continueAsGuest);
        expect(guestButton, findsOneWidget);

        await tester.tap(guestButton);
        await tester.pumpAndSettle();

        // Verify guest mode navigation occurred
        // Note: In a real test, you'd verify navigation to MainNavigationWrapper with isGuestMode: true
        expect(find.byType(AuthScreen), findsNothing);
      });

      testWidgets('should disable guest button during Google sign-in loading', (WidgetTester tester) async {
        when(mockGoogleDriveService.signIn()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 500));
          return 'mock_user';
        });

        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Start Google sign-in
        await tester.tap(find.text(AppStrings.signInWithGoogle));
        await tester.pump();

        // Try to tap guest button while Google sign-in is loading
        final guestButtonFinder = find.text(AppStrings.continueAsGuest);
        final guestInkWell = tester.widget<InkWell>(
          find.ancestor(
            of: guestButtonFinder,
            matching: find.byType(InkWell),
          ),
        );

        // Guest button should be disabled during loading
        expect(guestInkWell.onTap, isNull);

        await tester.pumpAndSettle();
      });

      testWidgets('should show correct guest mode styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Verify guest mode icon
        expect(find.byIcon(Icons.person_outline), findsOneWidget);

        // Verify guest mode subtitle
        expect(find.text('Try the app without signing in'), findsOneWidget);
      });
    });

    group('Platform-Specific Behavior Tests', () {
      // Note: These tests would require mocking kIsWeb or platform detection
      testWidgets('should show web platform warning when on web', (WidgetTester tester) async {
        // This test would need platform mocking to properly test web behavior
        await tester.pumpWidget(createTestableWidget(isWeb: true));
        await tester.pumpAndSettle();

        // In a properly mocked environment, we would verify:
        // - Web warning message is shown
        // - Google sign-in is disabled
        // - Appropriate warning styling
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should handle multiple rapid taps gracefully', (WidgetTester tester) async {
        when(mockGoogleDriveService.signIn()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 200));
          return 'mock_user';
        });

        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Rapidly tap Google sign-in button multiple times
        final googleButton = find.text(AppStrings.signInWithGoogle);
        await tester.tap(googleButton);
        await tester.pump();
        await tester.tap(googleButton);
        await tester.pump();
        await tester.tap(googleButton);
        await tester.pump();

        await tester.pumpAndSettle();

        // Should only call sign-in once due to loading state protection
        verify(mockGoogleDriveService.signIn()).called(1);
      });

      testWidgets('should handle widget disposal during async operation', (WidgetTester tester) async {
        when(mockGoogleDriveService.signIn()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return 'mock_user';
        });

        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Start sign-in process
        await tester.tap(find.text(AppStrings.signInWithGoogle));
        await tester.pump();

        // Navigate away from screen (simulating disposal)
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Different Screen'))));
        await tester.pumpAndSettle();

        // Should not crash when async operation completes
        await tester.pumpAndSettle();
      });

      testWidgets('should handle network timeout gracefully', (WidgetTester tester) async {
        when(mockGoogleDriveService.signIn()).thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 5));
          throw Exception('Network timeout');
        });

        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppStrings.signInWithGoogle));
        await tester.pump();

        // Fast-forward time to simulate timeout
        await tester.pump(const Duration(seconds: 6));

        // Should show error message
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Network timeout'), findsOneWidget);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper accessibility labels', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Verify key elements have proper semantics
        expect(find.byType(InkWell), findsAtLeastNWidgets(2));
        expect(find.byType(Icon), findsAtLeastNWidgets(6)); // Impact cards + auth buttons + app logo
      });

      testWidgets('should be navigable with keyboard/screen reader', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Verify focusable elements
        final inkWells = find.byType(InkWell);
        expect(inkWells, findsAtLeastNWidgets(2));

        // All InkWell widgets should be tappable
        for (var i = 0; i < 2; i++) {
          final inkWell = tester.widget<InkWell>(inkWells.at(i));
          expect(inkWell.onTap, isNotNull);
        }
      });

      testWidgets('should support large text sizes', (WidgetTester tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: createTestableWidget(),
          ),
        );
        await tester.pumpAndSettle();

        // Should render without overflow issues
        expect(find.byType(AuthScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('UI State Management Tests', () {
      testWidgets('should maintain correct button states', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Initially, both buttons should be enabled
        final googleButtonFinder = find.text(AppStrings.signInWithGoogle);
        final guestButtonFinder = find.text(AppStrings.continueAsGuest);

        expect(googleButtonFinder, findsOneWidget);
        expect(guestButtonFinder, findsOneWidget);

        // Both should be tappable initially
        final googleInkWell = tester.widget<InkWell>(
          find.ancestor(of: googleButtonFinder, matching: find.byType(InkWell)),
        );
        final guestInkWell = tester.widget<InkWell>(
          find.ancestor(of: guestButtonFinder, matching: find.byType(InkWell)),
        );

        expect(googleInkWell.onTap, isNotNull);
        expect(guestInkWell.onTap, isNotNull);
      });

      testWidgets('should show correct loading state elements', (WidgetTester tester) async {
        when(mockGoogleDriveService.signIn()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 200));
          return 'mock_user';
        });

        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Tap sign-in button
        await tester.tap(find.text(AppStrings.signInWithGoogle));
        await tester.pump();

        // Verify loading indicator properties
        final progressIndicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(progressIndicator.strokeWidth, equals(2.0));

        await tester.pumpAndSettle();
      });
    });

    group('Navigation Integration Tests', () {
      testWidgets('should navigate to main screen after successful sign-in', (WidgetTester tester) async {
        when(mockGoogleDriveService.signIn()).thenAnswer((_) async => 'test_user');

        final mockObserver = MockNavigatorObserver();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<GoogleDriveService>.value(
                value: mockGoogleDriveService,
              ),
            ],
            child: MaterialApp(
              home: const AuthScreen(),
              navigatorObservers: [mockObserver],
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppStrings.signInWithGoogle));
        await tester.pumpAndSettle();

        // Verify navigation occurred
        expect(find.byType(AuthScreen), findsNothing);
      });

      testWidgets('should navigate to guest mode correctly', (WidgetTester tester) async {
        final mockObserver = MockNavigatorObserver();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<GoogleDriveService>.value(
                value: mockGoogleDriveService,
              ),
            ],
            child: MaterialApp(
              home: const AuthScreen(),
              navigatorObservers: [mockObserver],
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppStrings.continueAsGuest));
        await tester.pumpAndSettle();

        // Verify navigation occurred
        expect(find.byType(AuthScreen), findsNothing);
      });
    });

    group('Edge Cases and Stress Tests', () {
      testWidgets('should handle very long app strings gracefully', (WidgetTester tester) async {
        // This would test with very long strings in constants
        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Should render without overflow
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle small screen sizes', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 568)); // Small phone size

        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Should render without overflow on small screens
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Reset surface size
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('should handle very large screen sizes', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 1600)); // Tablet size

        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Should render properly on large screens
        expect(find.byType(AuthScreen), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Reset surface size
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('should handle rapid orientation changes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Simulate orientation changes
        await tester.binding.setSurfaceSize(const Size(800, 600)); // Landscape
        await tester.pump();

        await tester.binding.setSurfaceSize(const Size(600, 800)); // Portrait
        await tester.pump();

        // Should handle orientation changes gracefully
        expect(find.byType(AuthScreen), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Reset surface size
        await tester.binding.setSurfaceSize(null);
      });
    });
  });
}
