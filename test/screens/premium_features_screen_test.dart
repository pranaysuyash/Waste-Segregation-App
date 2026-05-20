import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/models/premium_feature.dart';
import 'package:waste_segregation_app/screens/premium_features_screen.dart';
import 'package:waste_segregation_app/services/premium_service.dart';

class FakePremiumService extends ChangeNotifier implements PremiumService {
  final Map<String, bool> _enabled = {};

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  bool isPremiumFeature(String featureId) => _enabled[featureId] ?? false;

  @override
  Future<void> setPremiumFeature(String featureId, bool isPremium) async {
    _enabled[featureId] = isPremium;
    notifyListeners();
  }

  @override
  Future<void> toggleFeature(String featureId) async {
    await setPremiumFeature(featureId, !(isPremiumFeature(featureId)));
  }

  @override
  bool hasActivePremiumPlan() => false;

  @override
  List<PremiumFeature> getPremiumFeatures() => PremiumFeature.features
      .where((feature) => isPremiumFeature(feature.id))
      .map((feature) => PremiumFeature(
            id: feature.id,
            title: feature.title,
            description: feature.description,
            icon: feature.icon,
            route: feature.route,
            isEnabled: true,
          ))
      .toList();

  @override
  List<PremiumFeature> getComingSoonFeatures() => PremiumFeature.features
      .where((feature) => !isPremiumFeature(feature.id))
      .toList();

  @override
  Future<void> resetPremiumFeatures() async {
    _enabled.clear();
    notifyListeners();
  }
}

void main() {
  group('PremiumFeaturesScreen', () {
    testWidgets('renders the screen', (tester) async {
      final premiumService = FakePremiumService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PremiumService>.value(value: premiumService),
          ],
          child: const MaterialApp(home: PremiumFeaturesScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Premium Features'), findsOneWidget);
    });
  });
}

