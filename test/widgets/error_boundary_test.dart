import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/error_boundary.dart';

void main() {
  group('ErrorBoundary', () {
    testWidgets('renders child when no error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorBoundary(
            child: Text('healthy'),
          ),
        ),
      );

      expect(find.text('healthy'), findsOneWidget);
    });
  });

  group('AsyncErrorBoundary', () {
    testWidgets('shows loading then data', (tester) async {
      final future = Future.value('ok');

      await tester.pumpWidget(
        MaterialApp(
          home: AsyncErrorBoundary(
            future: future,
            builder: (_, data) => Text('data:$data'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('data:ok'), findsOneWidget);
    });
  });

  group('NetworkErrorBoundary', () {
    testWidgets('renders child in healthy path', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NetworkErrorBoundary(
            child: Text('network-ok'),
          ),
        ),
      );

      expect(find.text('network-ok'), findsOneWidget);
    });
  });
}
