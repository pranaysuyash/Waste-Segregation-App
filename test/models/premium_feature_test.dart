import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/premium_feature.dart';

void main() {
  group('PremiumFeature', () {
    test('serializes and deserializes round-trip', () {
      const feature = PremiumFeature(
        id: 'f1',
        title: 'Feature 1',
        description: 'Desc',
        icon: 'star',
        route: '/premium/f1',
        isEnabled: true,
      );

      final decoded = PremiumFeature.fromJson(feature.toJson());
      expect(decoded.id, feature.id);
      expect(decoded.title, feature.title);
      expect(decoded.description, feature.description);
      expect(decoded.icon, feature.icon);
      expect(decoded.route, feature.route);
      expect(decoded.isEnabled, isTrue);
    });

    test('fromJson defaults isEnabled to false', () {
      final feature = PremiumFeature.fromJson({
        'id': 'x',
        'title': 'X',
        'description': 'Y',
        'icon': 'z',
        'route': '/x',
      });

      expect(feature.isEnabled, isFalse);
    });

    test('static features list has unique ids and routes', () {
      final ids = PremiumFeature.features.map((f) => f.id).toList();
      final routes = PremiumFeature.features.map((f) => f.route).toList();

      expect(ids.toSet().length, ids.length);
      expect(routes.toSet().length, routes.length);
      expect(PremiumFeature.features, isNotEmpty);
    });
  });
}
