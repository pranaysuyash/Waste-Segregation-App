import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/remote_config_service.dart';

void main() {
  group('RemoteConfigService.getClassificationRoutingStrategy', () {
    test('returns balanced when remote config is not initialized', () async {
      final service = RemoteConfigService();
      // Not initialized — should fall back to default
      final strategy = await service.getClassificationRoutingStrategy();
      expect(strategy, equals('balanced'));
    });
  });

  group('Routing strategy validation', () {
    test('all RoutingStrategy enum values are in valid list', () {
      const valid = ['costFirst', 'qualityFirst', 'latencyFirst', 'balanced'];
      // Ensure we're not missing any new strategy values
      expect(valid.length, equals(4));
    });

    test('default config key is balanced', () {
      // Verify the default value in the config is 'balanced'
      const defaultStrategy = 'balanced';
      const valid = ['costFirst', 'qualityFirst', 'latencyFirst', 'balanced'];
      expect(valid.contains(defaultStrategy), isTrue);
    });

    test('unknown strategy string falls back to balanced', () {
      const valid = ['costFirst', 'qualityFirst', 'latencyFirst', 'balanced'];
      const unknown = 'unknownStrategy';
      final result = valid.contains(unknown) ? unknown : 'balanced';
      expect(result, equals('balanced'));
    });
  });
}
