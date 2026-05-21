import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/token_wallet.dart';
import 'package:waste_segregation_app/providers/token_providers.dart';
import 'package:waste_segregation_app/widgets/analysis_speed_selector.dart';

void main() {
  testWidgets('forceBatchMode disables instant selection', (tester) async {
    AnalysisSpeed selected = AnalysisSpeed.batch;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenWalletProvider.overrideWith((ref) async => TokenWallet(
                balance: 50,
                totalEarned: 50,
                totalSpent: 0,
                lastUpdated: DateTime.now(),
              )),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AnalysisSpeedSelector(
              selectedSpeed: selected,
              forceBatchMode: true,
              onSpeedChanged: (speed) => selected = speed,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Instant mode is temporarily disabled by cost guardrails.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Instant'));
    await tester.pump();

    expect(selected, AnalysisSpeed.batch);
    expect(
      find.text('Batch mode is enforced right now due to AI cost guardrails.'),
      findsOneWidget,
    );
  });
}
