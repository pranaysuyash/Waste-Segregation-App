import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:waste_segregation_app/widgets/error_boundary.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';

@GenerateMocks([AnalyticsService])
import 'error_boundary_test.mocks.dart';

// Test widget that can throw errors
class ErrorThrowingWidget extends StatelessWidget {
  const ErrorThrowingWidget({
    Key? key,
    this.shouldThrow = false,
    this.errorMessage,
  }) : super(key: key);
  final bool shouldThrow;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (shouldThrow) {
      throw Exception(errorMessage ?? 'Test error');
    }
    return const Text('Normal Widget');
  }
}

// Widget that throws errors during specific lifecycle events
class LifecycleErrorWidget extends StatefulWidget {
  const LifecycleErrorWidget({
    Key? key,
    this.throwInInit = false,
    this.throwInBuild = false,
    this.throwInDispose = false,
  }) : super(key: key);
  final bool throwInInit;
  final bool throwInBuild;
  final bool throwInDispose;

  @override
  State<LifecycleErrorWidget> createState() => _LifecycleErrorWidgetState();
}

class _LifecycleErrorWidgetState extends State<LifecycleErrorWidget> {
  @override
  void initState() {
    super.initState();
    if (widget.throwInInit) {
      throw Exception('Error in initState');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.throwInBuild) {
      throw Exception('Error in build');
    }
    return const Text('Lifecycle Widget');
  }

  @override
  void dispose() {
    if (widget.throwInDispose) {
      throw Exception('Error in dispose');
    }
    super.dispose();
  }
}

void main() {
  group('ErrorBoundary Tests', () {
    late MockAnalyticsService mockAnalyticsService;

    setUp(() {
      mockAnalyticsService = MockAnalyticsService();
    });

    Widget createTestWidget({
      Widget? child,
      Widget? fallback,
      ErrorCallback? onError,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ErrorBoundary(
            fallback: fallback,
            onError: onError,
            analyticsService: mockAnalyticsService,
            child: child ?? const Text('Normal Child'),
          ),
        ),
      );
    }

    group('Normal Operation', () {
      testWidgets('should render child widget when no error occurs', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: const Text('Test Child'),
        ));

        expect(find.text('Test Child'), findsOneWidget);
        expect(find.text('Something went wrong'), findsNothing);
      });

      testWidgets('should render complex child widgets normally', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: const Column(
            children: [
              Text('Title'),
              Icon(Icons.check),
              ElevatedButton(onPressed: null, child: Text('Button')),
            ],
          ),
        ));

        expect(find.text('Title'), findsOneWidget);
        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(find.text('Button'), findsOneWidget);
      });

      testWidgets('should handle stateful child widgets', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: const LifecycleErrorWidget(),
        ));

        expect(find.text('Lifecycle Widget'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should catch and handle widget errors', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: const ErrorThrowingWidget(shouldThrow: true),
        ));

        expect(find.text('Normal Widget'), findsNothing);
        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('should show custom error message', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: const ErrorThrowingWidget(
            shouldThrow: true,
            errorMessage: 'Custom error message',
          ),
        ));

        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.textContaining('Custom error message'), findsOneWidget);
      });

      testWidgets('should render custom fallback widget', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: const ErrorThrowingWidget(shouldThrow: true),
          fallback: const Column(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              Text('Custom Fallback UI'),
              Text('Please try again later'),
            ],
          ),
        ));

        expect(find.text('Custom Fallback UI'), findsOneWidget);
        expect(find.text('Please try again later'), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsOneWidget);
        expect(find.text('Something went wrong'), findsNothing);
      });

      testWidgets('should call error callback when provided', (WidgetTester tester) async {
        FlutterError? capturedError;
        ErrorDetails? capturedDetails;

        await tester.pumpWidget(createTestWidget(
          child: const ErrorThrowingWidget(shouldThrow: true, errorMessage: 'Callback test'),
          onError: (error, details) {
            capturedError = error;
            capturedDetails = details;
          },
        ));

        expect(capturedError, isNotNull);
        expect(capturedError.toString(), contains('Callback test'));
        expect(capturedDetails, isNotNull);
      });

      testWidgets('should report errors to analytics service', (WidgetTester tester) async {
        when(mockAnalyticsService.logError(any, any, any)).thenAnswer((_) async => null);

        await tester.pumpWidget(createTestWidget(
          child: const ErrorThrowingWidget(
            shouldThrow: true,
            errorMessage: 'Analytics test error',
          ),
        ));

        verify(mockAnalyticsService.logError(
          'widget_error',
          argThat(contains('Analytics test error')),
          any,
        )).called(1);
      });
    });

    group('Error Recovery', () {
      testWidgets('should allow retry after error', (WidgetTester tester) async {
        var shouldThrow = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return ErrorBoundary(
                    onRetry: () {
                      setState(() {
                        shouldThrow = false;
                      });
                    },
                    analyticsService: mockAnalyticsService,
                    child: ErrorThrowingWidget(shouldThrow: shouldThrow),
                  );
                },
              ),
            ),
          ),
        );

        // Should show error initially
        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.text('Try Again'), findsOneWidget);

        // Tap retry button
        await tester.tap(find.text('Try Again'));
        await tester.pumpAndSettle();

        // Should show normal widget after retry
        expect(find.text('Normal Widget'), findsOneWidget);
        expect(find.text('Something went wrong'), findsNothing);
      });

      testWidgets('should reset error state on rebuild', (WidgetTester tester) async {
        var shouldThrow = true;

        Widget buildWidget() {
          return MaterialApp(
            home: Scaffold(
              body: ErrorBoundary(
                analyticsService: mockAnalyticsService,
                child: ErrorThrowingWidget(shouldThrow: shouldThrow),
              ),
            ),
          );
        }

        await tester.pumpWidget(buildWidget());

        // Should show error
        expect(find.text('Something went wrong'), findsOneWidget);

        // Change the error condition and rebuild
        shouldThrow = false;
        await tester.pumpWidget(buildWidget());

        // Should show normal widget
        expect(find.text('Normal Widget'), findsOneWidget);
      });

      testWidgets('should handle multiple consecutive errors', (WidgetTester tester) async {
        var errorCount = 0;

        await tester.pumpWidget(createTestWidget(
          child: const ErrorThrowingWidget(shouldThrow: true),
          onError: (error, details) {
            errorCount++;
          },
        ));

        expect(errorCount, 1);

        // Rebuild with another error
        await tester.pumpWidget(createTestWidget(
          child: const ErrorThrowingWidget(
            shouldThrow: true,
            errorMessage: 'Second error',
          ),
          onError: (error, details) {
            errorCount++;
          },
        ));

        expect(errorCount, 2);
      });
    });

    group('Error Types', () {
      testWidgets('should handle assertion errors', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: Builder(
            builder: (context) {
              assert(false, 'Assertion error test');
              return const Text('Should not show');
            },
          ),
        ));

        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.text('Should not show'), findsNothing);
      });

      testWidgets('should handle null pointer exceptions', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: Builder(
            builder: (context) {
              String? nullString;
              return Text(nullString!); // Will throw null check error
            },
          ),
        ));

        expect(find.text('Something went wrong'), findsOneWidget);
      });

      testWidgets('should handle type errors', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: Builder(
            builder: (context) {
              final dynamic value = 'string';
              final number = value as int; // Will throw type error
              return Text('Number: $number');
            },
          ),
        ));

        expect(find.text('Something went wrong'), findsOneWidget);
      });

      testWidgets('should handle async errors in FutureBuilder', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: FutureBuilder(
            future: Future.delayed(
              const Duration(milliseconds: 100),
              () => throw Exception('Async error'),
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                throw snapshot.error!;
              }
              if (snapshot.hasData) {
                return Text('Data: ${snapshot.data}');
              }
              return const CircularProgressIndicator();
            },
          ),
        ));

        await tester.pumpAndSettle();

        expect(find.text('Something went wrong'), findsOneWidget);
      });
    });

    group('Error Boundary Nesting', () {
      testWidgets('should handle nested error boundaries', (WidgetTester tester) async {
        var outerErrorCaught = false;
        var innerErrorCaught = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorBoundary(
                onError: (error, details) {
                  outerErrorCaught = true;
                },
                analyticsService: mockAnalyticsService,
                child: Column(
                  children: [
                    const Text('Outer Content'),
                    ErrorBoundary(
                      child: const ErrorThrowingWidget(shouldThrow: true),
                      onError: (error, details) {
                        innerErrorCaught = true;
                      },
                      analyticsService: mockAnalyticsService,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(innerErrorCaught, true);
        expect(outerErrorCaught, false); // Inner boundary should catch the error
        expect(find.text('Outer Content'), findsOneWidget);
        expect(find.text('Something went wrong'), findsOneWidget);
      });

      testWidgets('should propagate errors if inner boundary fails', (WidgetTester tester) async {
        var outerErrorCaught = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorBoundary(
                onError: (error, details) {
                  outerErrorCaught = true;
                },
                analyticsService: mockAnalyticsService,
                child: ErrorBoundary(
                  child: const ErrorThrowingWidget(shouldThrow: true),
                  // Inner boundary that also throws an error
                  fallback: Builder(
                    builder: (context) {
                      throw Exception('Fallback error');
                    },
                  ),
                  analyticsService: mockAnalyticsService,
                ),
              ),
            ),
          ),
        );

        expect(outerErrorCaught, true);
        expect(find.text('Something went wrong'), findsOneWidget);
      });
    });

    group('Performance and Resource Management', () {
      testWidgets('should not impact performance when no errors occur', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(createTestWidget(
          child: Column(
            children: List.generate(100, (index) => Text('Item $index')),
          ),
        ));

        stopwatch.stop();

        // Should not significantly impact render time
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(find.text('Item 0'), findsOneWidget);
        expect(find.text('Item 99'), findsOneWidget);
      });

      testWidgets('should clean up resources on error', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: const LifecycleErrorWidget(throwInBuild: true),
        ));

        expect(find.text('Something went wrong'), findsOneWidget);

        // Rebuild with different child to ensure cleanup
        await tester.pumpWidget(createTestWidget(
          child: const Text('New Child'),
        ));

        expect(find.text('New Child'), findsOneWidget);
        expect(find.text('Something went wrong'), findsNothing);
      });

      testWidgets('should handle rapid error state changes', (WidgetTester tester) async {
        var shouldThrow = true;

        Widget buildWidget() {
          return MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return ErrorBoundary(
                    onRetry: () {
                      setState(() {
                        shouldThrow = !shouldThrow;
                      });
                    },
                    analyticsService: mockAnalyticsService,
                    child: ErrorThrowingWidget(shouldThrow: shouldThrow),
                  );
                },
              ),
            ),
          );
        }

        await tester.pumpWidget(buildWidget());

        // Rapidly toggle error state
        for (var i = 0; i < 5; i++) {
          await tester.tap(find.text('Try Again'));
          await tester.pump();

          if (shouldThrow) {
            expect(find.text('Something went wrong'), findsOneWidget);
          } else {
            expect(find.text('Normal Widget'), findsOneWidget);
          }
        }
      });
    });

    group('Accessibility', () {
      testWidgets('should provide proper semantics for error state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: const ErrorThrowingWidget(shouldThrow: true),
        ));

        expect(
          tester.getSemantics(find.text('Something went wrong')),
          matchesSemantics(
            label: 'Something went wrong',
            isLiveRegion: true,
          ),
        );

        expect(
          tester.getSemantics(find.text('Try Again')),
          matchesSemantics(
            label: 'Try Again',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
          ),
        );
      });

      testWidgets('should announce errors to screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: const ErrorThrowingWidget(shouldThrow: true),
        ));

        // Should have live region announcement for accessibility
        expect(find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.liveRegion == true),
            findsOneWidget);
      });

      testWidgets('should support keyboard navigation in error state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: const ErrorThrowingWidget(shouldThrow: true),
        ));

        // Focus should be manageable
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        expect(WidgetsBinding.instance.focusManager.primaryFocus, isNotNull);

        // Enter key should trigger retry
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
      });
    });

    group('Error Reporting Integration', () {
      testWidgets('should include stack trace in error reports', (WidgetTester tester) async {
        when(mockAnalyticsService.logError(any, any, any)).thenAnswer((_) async => null);

        await tester.pumpWidget(createTestWidget(
          child: const ErrorThrowingWidget(
            shouldThrow: true,
            errorMessage: 'Stack trace test',
          ),
        ));

        verify(mockAnalyticsService.logError(
          'widget_error',
          argThat(contains('Stack trace test')),
          argThat(isNotNull), // Stack trace should be included
        )).called(1);
      });

      testWidgets('should handle analytics service errors gracefully', (WidgetTester tester) async {
        when(mockAnalyticsService.logError(any, any, any)).thenThrow(Exception('Analytics error'));

        await tester.pumpWidget(createTestWidget(
          child: const ErrorThrowingWidget(shouldThrow: true),
        ));

        // Should still show error UI even if analytics fails
        expect(find.text('Something went wrong'), findsOneWidget);
      });

      testWidgets('should throttle error reports for repeated errors', (WidgetTester tester) async {
        when(mockAnalyticsService.logError(any, any, any)).thenAnswer((_) async => null);

        // Trigger same error multiple times
        for (var i = 0; i < 5; i++) {
          await tester.pumpWidget(createTestWidget(
            child: const ErrorThrowingWidget(
              shouldThrow: true,
              errorMessage: 'Repeated error',
            ),
          ));
        }

        // Should not report the same error too frequently
        verify(mockAnalyticsService.logError(any, any, any)).called(lessThanOrEqualTo(3));
      });
    });
  });
}
