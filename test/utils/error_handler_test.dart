import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/utils/error_handler.dart';

void main() {
  group('ErrorHandler Tests', () {
    test('getUserFriendlyMessage returns network guidance', () {
      final message = ErrorHandler.getUserFriendlyMessage(
        Exception('network connection failed'),
      );
      expect(message.toLowerCase(), contains('network'));
    });

    test('getUserFriendlyMessage returns timeout guidance', () {
      final message = ErrorHandler.getUserFriendlyMessage(
        Exception('timeout while requesting'),
      );
      expect(message.toLowerCase(), contains('timed out'));
    });

    test('getUserFriendlyMessage returns generic fallback', () {
      final message = ErrorHandler.getUserFriendlyMessage(
        Exception('unrecognized failure'),
      );
      expect(
        message,
        equals('An unexpected error occurred. Please try again.'),
      );
    });

    test('handleSync returns result when operation succeeds', () {
      final result = ErrorHandler.handleSync<int>(() => 42, context: 'sync');
      expect(result, equals(42));
    });

    test('handleSync returns null when operation throws', () {
      final result = ErrorHandler.handleSync<int>(
        () => throw Exception('boom'),
        context: 'sync-fail',
      );
      expect(result, isNull);
    });

    test('handleError accepts context and does not throw', () {
      expect(
        () => ErrorHandler.handleError(
          Exception('boom'),
          StackTrace.current,
          context: 'unit-test',
        ),
        returnsNormally,
      );
    });

    test('retryOperation retries and eventually succeeds', () async {
      var attempts = 0;
      final value = await ErrorHandler.retryOperation<int>(
        () async {
          attempts += 1;
          if (attempts < 3) {
            throw Exception('transient');
          }
          return 7;
        },
        maxRetries: 3,
        initialDelay: const Duration(milliseconds: 1),
      );

      expect(value, equals(7));
      expect(attempts, equals(3));
    });

    test('retryOperation rethrows after max retries', () async {
      expect(
        () => ErrorHandler.retryOperation<void>(
          () async => throw Exception('always fails'),
          maxRetries: 2,
          initialDelay: const Duration(milliseconds: 1),
        ),
        throwsException,
      );
    });

    testWidgets('initialize and showGlobalErrorDialog are safe',
        (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      );

      ErrorHandler.initialize(navigatorKey);
      ErrorHandler.showGlobalErrorDialog(
        title: 'Test',
        message: 'Message',
      );

      await tester.pump();
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Message'), findsOneWidget);
    });
  });
}
