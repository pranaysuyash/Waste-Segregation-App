import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/analysis_progress_view.dart';

void main() {
  group('AnalysisProgressView', () {
    Widget buildStage(
      AnalysisProgressStage stage, {
      String? imageName,
      String? errorMessage,
      String? statusMessage,
      int? offlineQueueCount,
      String? localRuleChipText,
      String? confidenceText,
      VoidCallback? onRetry,
      VoidCallback? onCancel,
      VoidCallback? onContinue,
      bool showRetry = false,
      bool showCancel = false,
      bool disableAnimations = false,
    }) {
      final stageWidget = AnalysisProgressView(
        stage: stage,
        imageName: imageName,
        errorMessage: errorMessage,
        statusMessage: statusMessage,
        offlineQueueCount: offlineQueueCount,
        localRuleChipText: localRuleChipText,
        confidenceText: confidenceText,
        onRetry: onRetry,
        onCancel: onCancel,
        onContinue: onContinue,
        showRetry: showRetry,
        showCancel: showCancel,
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
        buildStage(
          AnalysisProgressStage.checkingQuality,
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
        buildStage(
          AnalysisProgressStage.queuedOffline,
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
        buildStage(
          AnalysisProgressStage.applyingLocalRules,
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
        buildStage(
          AnalysisProgressStage.success,
          confidenceText: 'Confidence: 93%',
          onContinue: () {},
        ),
      );

      expect(find.text('Result ready'), findsOneWidget);
      expect(find.text('Confidence: 93%'), findsOneWidget);
      expect(find.text('View result'), findsOneWidget);

      await tester.pumpWidget(
        buildStage(
          AnalysisProgressStage.fallback,
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
        buildStage(
          AnalysisProgressStage.failedRetryable,
          errorMessage: 'Network request timed out.',
          onRetry: () => retryed = true,
          showRetry: true,
          onCancel: () {},
          showCancel: true,
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
        buildStage(
          AnalysisProgressStage.applyingLocalRules,
          disableAnimations: true,
          showCancel: true,
          onCancel: () {},
        ),
      );

      final card = tester.widget<Card>(find.byType(Card).first);
      expect(card.elevation, equals(0));
    });
  });
}
