import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/classification_state.dart';
import 'package:waste_segregation_app/widgets/analysis_progress_view.dart';

void main() {
  group('AnalysisProgressView', () {
    Widget buildState(
      ClassificationState state, {
      String? imageName,
      String? errorMessage,
      String? statusMessage,
      int? offlineQueueCount,
      String? localRuleChipText,
      String? confidenceText,
      VoidCallback? onRetry,
      VoidCallback? onCancel,
      VoidCallback? onContinue,
      bool disableAnimations = false,
    }) {
      final stageWidget = AnalysisProgressView(
        state: state,
        imageName: imageName,
        errorMessage: errorMessage,
        statusMessage: statusMessage,
        offlineQueueCount: offlineQueueCount,
        localRuleChipText: localRuleChipText,
        confidenceText: confidenceText,
        onRetry: onRetry,
        onCancel: onCancel,
        onContinue: onContinue,
      );

      final mediaQueryData = MediaQueryData(
        disableAnimations: disableAnimations,
      );

      return MaterialApp(
        home: MediaQuery(
          data: mediaQueryData,
          child: Scaffold(
            body: Center(child: stageWidget),
          ),
        ),
      );
    }

    testWidgets('renders checking quality stage messaging', (tester) async {
      await tester.pumpWidget(
        buildState(
          ClassificationState.qualityChecking,
          imageName: 'captured_photo.jpg',
          statusMessage: 'Checking edges and brightness',
        ),
      );

      expect(find.text('Checking image quality'), findsOneWidget);
      expect(find.text('Checking edges and brightness'), findsOneWidget);
      expect(find.text('captured_photo.jpg'), findsOneWidget);
    });

    testWidgets('renders offline queue state with queue position',
        (tester) async {
      await tester.pumpWidget(
        buildState(
          ClassificationState.queuedOffline,
          offlineQueueCount: 3,
          imageName: 'captured_photo.jpg',
        ),
      );

      expect(find.text('Queued for offline processing'), findsOneWidget);
      expect(find.text('Offline queue position #3'), findsNWidgets(3));
    });

    testWidgets('renders local-rule chip when applying local rules',
        (tester) async {
      await tester.pumpWidget(
        buildState(
          ClassificationState.policyApplied,
          localRuleChipText: 'Regional waste rules matched for your city.',
        ),
      );

      expect(find.text('Applying local rules'), findsOneWidget);
      expect(find.text('Regional waste rules matched for your city.'),
          findsOneWidget);
    });

    testWidgets('renders confidence in success and fallback states',
        (tester) async {
      await tester.pumpWidget(
        buildState(
          ClassificationState.classificationSucceeded,
          confidenceText: 'Confidence: 93%',
          onContinue: () {},
        ),
      );

      expect(find.text('Classification complete'), findsOneWidget);
      expect(find.text('Confidence: 93%'), findsOneWidget);
      expect(find.text('View result'), findsOneWidget);

      await tester.pumpWidget(
        buildState(
          ClassificationState.awaitingUserConfirmation,
          confidenceText: 'Confidence: 58%',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Result needs review'), findsOneWidget);
      expect(find.text('Confidence: 58%'), findsOneWidget);
    });

    testWidgets('renders retryable error state with actions', (tester) async {
      var retryed = false;

      await tester.pumpWidget(
        buildState(
          ClassificationState.failedRetryable,
          errorMessage: 'Network request timed out.',
          onRetry: () => retryed = true,
          onCancel: () {},
        ),
      );

      expect(find.text('Analysis interrupted'), findsOneWidget);
      expect(find.text('Network request timed out.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retryed, isTrue);
    });

    testWidgets('honors reduced-motion in visual contract', (tester) async {
      await tester.pumpWidget(
        buildState(
          ClassificationState.policyApplied,
          disableAnimations: true,
          onCancel: () {},
        ),
      );

      final card = tester.widget<Card>(find.byType(Card).first);
      expect(card.elevation, equals(0));
    });
  });
}
