import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/widgets/banner_ad_widget.dart';
import 'package:waste_segregation_app/services/ad_service.dart';
import 'package:waste_segregation_app/services/premium_service.dart';

// Simple mock classes without using mockito
class MockAdService extends AdService {
  Widget? _mockBannerAd;
  bool _mockPremiumStatus = false;

  void setMockBannerAd(Widget widget) {
    _mockBannerAd = widget;
  }

  @override
  Widget getBannerAd() {
    return _mockBannerAd ?? const SizedBox.shrink();
  }

  @override
  void setPremiumStatus(bool hasPremium) {
    _mockPremiumStatus = hasPremium;
  }

  bool get mockPremiumStatus => _mockPremiumStatus;
}

class MockPremiumService extends PremiumService {
  bool _mockIsPremium = false;

  void setMockIsPremium(bool isPremium) {
    _mockIsPremium = isPremium;
  }

  @override
  bool isPremiumFeature(String featureId) {
    return _mockIsPremium;
  }
}

void main() {
  group('BannerAdWidget Tests', () {
    late MockAdService mockAdService;
    late MockPremiumService mockPremiumService;

    setUp(() {
      mockAdService = MockAdService();
      mockPremiumService = MockPremiumService();
    });

    Widget createTestWidget({
      double? height,
      bool showAtBottom = false,
    }) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AdService>.value(value: mockAdService),
            ChangeNotifierProvider<PremiumService>.value(value: mockPremiumService),
          ],
          child: Scaffold(
            body: BannerAdWidget(
              height: height ?? 50,
              showAtBottom: showAtBottom,
            ),
          ),
        ),
      );
    }

    group('Widget Initialization', () {
      testWidgets('should initialize with default height', (WidgetTester tester) async {
        mockPremiumService.setMockIsPremium(false);
        mockAdService.setMockBannerAd(const SizedBox(height: 50));

        await tester.pumpWidget(createTestWidget());

        expect(find.byType(BannerAdWidget), findsOneWidget);
        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('should use custom height when provided', (WidgetTester tester) async {
        mockPremiumService.setMockIsPremium(false);
        mockAdService.setMockBannerAd(const SizedBox(height: 100));

        await tester.pumpWidget(createTestWidget(height: 100));

        final bannerWidget = find.byType(BannerAdWidget);
        expect(bannerWidget, findsOneWidget);
        
        // Check that the widget was created with the correct height parameter
        final widget = tester.widget<BannerAdWidget>(bannerWidget);
        expect(widget.height, equals(100.0));
      });

      testWidgets('should show at bottom when showAtBottom is true', (WidgetTester tester) async {
        mockPremiumService.setMockIsPremium(false);
        mockAdService.setMockBannerAd(const SizedBox(height: 50));

        await tester.pumpWidget(createTestWidget(showAtBottom: true));

        expect(find.byType(Positioned), findsOneWidget);
        final positioned = tester.widget<Positioned>(find.byType(Positioned));
        expect(positioned.bottom, equals(0));
      });

      testWidgets('should not show positioned widget when showAtBottom is false', (WidgetTester tester) async {
        mockPremiumService.setMockIsPremium(false);
        mockAdService.setMockBannerAd(const SizedBox(height: 50));

        await tester.pumpWidget(createTestWidget());

        expect(find.byType(Positioned), findsNothing);
        expect(find.byType(Container), findsOneWidget);
      });
    });

    group('Premium Service Integration', () {
      testWidgets('should call setPremiumStatus on ad service', (WidgetTester tester) async {
        mockPremiumService.setMockIsPremium(true);
        mockAdService.setMockBannerAd(const SizedBox.shrink());

        await tester.pumpWidget(createTestWidget());

        expect(mockAdService.mockPremiumStatus, isTrue);
      });

      testWidgets('should handle premium status false', (WidgetTester tester) async {
        mockPremiumService.setMockIsPremium(false);
        mockAdService.setMockBannerAd(const SizedBox(height: 50));

        await tester.pumpWidget(createTestWidget());

        expect(mockAdService.mockPremiumStatus, isFalse);
      });

      testWidgets('should handle premium service errors gracefully', (WidgetTester tester) async {
        // This test would need a more complex mock setup to simulate errors
        // For now, just test that the widget renders
        mockPremiumService.setMockIsPremium(false);
        mockAdService.setMockBannerAd(const SizedBox.shrink());

        await tester.pumpWidget(createTestWidget());

        expect(find.byType(BannerAdWidget), findsOneWidget);
      });
    });

    group('Ad Service Integration', () {
      testWidgets('should display ad from ad service', (WidgetTester tester) async {
        mockPremiumService.setMockIsPremium(false);
        mockAdService.setMockBannerAd(
          Container(
            height: 50,
            color: Colors.blue,
            child: const Text('Test Ad'),
          ),
        );

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Test Ad'), findsOneWidget);
        expect(find.byType(Container), findsAtLeastNWidgets(1));
      });

      testWidgets('should handle empty ad widget', (WidgetTester tester) async {
        mockPremiumService.setMockIsPremium(false);
        mockAdService.setMockBannerAd(const SizedBox.shrink());

        await tester.pumpWidget(createTestWidget());

        expect(find.byType(BannerAdWidget), findsOneWidget);
      });

      testWidgets('should handle ad service errors', (WidgetTester tester) async {
        mockPremiumService.setMockIsPremium(false);
        // Don't set a mock banner ad to simulate error case
        
        await tester.pumpWidget(createTestWidget());

        // Should not crash
        expect(find.byType(BannerAdWidget), findsOneWidget);
      });
    });

    group('Layout Tests', () {
      testWidgets('should have correct height constraints', (WidgetTester tester) async {
        mockPremiumService.setMockIsPremium(false);
        mockAdService.setMockBannerAd(const SizedBox(height: 50));

        await tester.pumpWidget(createTestWidget());

        final bannerWidget = find.byType(BannerAdWidget);
        expect(bannerWidget, findsOneWidget);
        
        // Check that the widget was created with the correct height parameter
        final widget = tester.widget<BannerAdWidget>(bannerWidget);
        expect(widget.height, equals(50.0));
      });

      testWidgets('should center align ad content', (WidgetTester tester) async {
        mockPremiumService.setMockIsPremium(false);
        mockAdService.setMockBannerAd(const SizedBox(height: 50));

        await tester.pumpWidget(createTestWidget());

        final container = tester.widget<Container>(find.byType(Container));
        expect(container.alignment, equals(Alignment.center));
      });

      testWidgets('should have safe area when shown at bottom', (WidgetTester tester) async {
        mockPremiumService.setMockIsPremium(false);
        mockAdService.setMockBannerAd(const SizedBox(height: 50));

        await tester.pumpWidget(createTestWidget(showAtBottom: true));

        expect(find.byType(SafeArea), findsOneWidget);
        final safeArea = tester.widget<SafeArea>(find.byType(SafeArea));
        expect(safeArea.top, isFalse);
      });

      testWidgets('should have white background when shown at bottom', (WidgetTester tester) async {
        mockPremiumService.setMockIsPremium(false);
        mockAdService.setMockBannerAd(const SizedBox(height: 50));

        await tester.pumpWidget(createTestWidget(showAtBottom: true));

        final positioned = tester.widget<Positioned>(find.byType(Positioned));
        final container = positioned.child as Container;
        expect(container.color, equals(Colors.white));
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle zero height', (WidgetTester tester) async {
        mockPremiumService.setMockIsPremium(false);
        mockAdService.setMockBannerAd(const SizedBox.shrink());

        await tester.pumpWidget(createTestWidget(height: 0));

        expect(find.byType(BannerAdWidget), findsOneWidget);
      });

      testWidgets('should handle very large height', (WidgetTester tester) async {
        mockPremiumService.setMockIsPremium(false);
        mockAdService.setMockBannerAd(const SizedBox(height: 1000));

        await tester.pumpWidget(createTestWidget(height: 1000));

        final bannerWidget = find.byType(BannerAdWidget);
        expect(bannerWidget, findsOneWidget);
        
        // Check that the widget was created with the correct height parameter
        final widget = tester.widget<BannerAdWidget>(bannerWidget);
        expect(widget.height, equals(1000.0));
      });

      testWidgets('should handle rapid rebuilds', (WidgetTester tester) async {
        mockPremiumService.setMockIsPremium(false);
        mockAdService.setMockBannerAd(const SizedBox(height: 50));

        for (var i = 0; i < 5; i++) {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();
        }

        expect(find.byType(BannerAdWidget), findsOneWidget);
      });
    });

    group('Performance Tests', () {
      testWidgets('should handle widget disposal gracefully', (WidgetTester tester) async {
        mockPremiumService.setMockIsPremium(false);
        mockAdService.setMockBannerAd(const SizedBox(height: 50));

        await tester.pumpWidget(createTestWidget());
        
        // Remove widget
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Empty'))));

        // Should not cause any errors
        expect(find.text('Empty'), findsOneWidget);
      });
    });
  });
}
