import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/local_guidelines_plugin.dart';

void main() {
  group('LocalGuidelinesManager routing', () {
    setUpAll(() {
      LocalGuidelinesManager.initializeDefaultPlugins();
    });

    test('routes Bangalore aliases to BBMP plugin', () {
      final pluginA =
          LocalGuidelinesManager.getPluginForRegion('Bangalore, IN');
      final pluginB = LocalGuidelinesManager.getPluginForRegion('Bengaluru');

      expect(pluginA, isNotNull);
      expect(pluginB, isNotNull);
      expect(pluginA!.pluginId, equals('bbmp_bangalore'));
      expect(pluginB!.pluginId, equals('bbmp_bangalore'));
    });

    test('routes Mumbai aliases to BMC plugin', () {
      final pluginA = LocalGuidelinesManager.getPluginForRegion('Mumbai, IN');
      final pluginB = LocalGuidelinesManager.getPluginForRegion('Bombay');

      expect(pluginA, isNotNull);
      expect(pluginB, isNotNull);
      expect(pluginA!.pluginId, equals('bmc_mumbai'));
      expect(pluginB!.pluginId, equals('bmc_mumbai'));
    });

    test('routes Delhi aliases to MCD plugin', () {
      final pluginA = LocalGuidelinesManager.getPluginForRegion('Delhi, IN');
      final pluginB = LocalGuidelinesManager.getPluginForRegion('New Delhi');

      expect(pluginA, isNotNull);
      expect(pluginB, isNotNull);
      expect(pluginA!.pluginId, equals('mcd_delhi'));
      expect(pluginB!.pluginId, equals('mcd_delhi'));
    });

    test('supports direct plugin-id lookup fallback', () {
      final plugin = LocalGuidelinesManager.getPluginForRegion('mcd_delhi');
      expect(plugin, isNotNull);
      expect(plugin!.pluginId, equals('mcd_delhi'));
    });
  });
}
