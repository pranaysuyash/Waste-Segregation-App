import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as provider;
import 'package:waste_segregation_app/models/premium_feature.dart';
import 'package:waste_segregation_app/providers/app_providers.dart';
import 'package:waste_segregation_app/screens/educational_content_screen.dart';
import 'package:waste_segregation_app/services/ad_service.dart';
import 'package:waste_segregation_app/services/premium_service.dart';

class FakePremiumService extends ChangeNotifier implements PremiumService {
  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  bool isPremiumFeature(String featureId) => false;

  @override
  Future<void> setPremiumFeature(String featureId, bool isPremium) async {}

  @override
  Future<void> setPremiumPlanEntitlement(bool isPremium) async {
    await setPremiumFeature(PremiumService.proSubscriptionEntitlement, isPremium);
  }

  @override
  List<PremiumFeature> getPremiumFeatures() => const [];

  @override
  List<PremiumFeature> getComingSoonFeatures() => PremiumFeature.features;

  @override
  Future<void> resetPremiumFeatures() async {}

  @override
  Future<void> toggleFeature(String featureId) async {}

  @override
  bool hasActivePremiumPlan() => false;
}

Widget _wrapForTest(Widget child) {
  final adService = AdService();
  final premiumService = FakePremiumService();

  return ProviderScope(
    overrides: [
      adServiceProvider.overrideWithValue(adService),
    ],
    child: provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider<AdService>.value(value: adService),
        provider.ChangeNotifierProvider<PremiumService>.value(
            value: premiumService),
      ],
      child: MaterialApp(home: child),
    ),
  );
}

void main() {
  group('EducationalContentScreen', () {
    testWidgets('renders tabs and default content', (tester) async {
      await tester.pumpWidget(_wrapForTest(const EducationalContentScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Articles'), findsOneWidget);
      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('Infographics'), findsOneWidget);
      expect(find.text('Quizzes'), findsOneWidget);
      expect(find.text('Tutorials'), findsOneWidget);
      expect(find.text('Tips'), findsOneWidget);

      // Built-in service content smoke check.
      expect(
          find.text('Understanding Plastic Recycling Codes'), findsOneWidget);
    });

    testWidgets('filters by search query', (tester) async {
      await tester.pumpWidget(_wrapForTest(const EducationalContentScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Composting');
      await tester.pumpAndSettle();

      expect(find.text('Understanding Plastic Recycling Codes'), findsNothing);
    });
  });
}
