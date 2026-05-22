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

    test('routes Pune to PMC plugin', () {
      final plugin =
          LocalGuidelinesManager.getPluginForRegion('Pune, IN');
      expect(plugin, isNotNull);
      expect(plugin!.pluginId, equals('pmc_pune'));
    });

    test('routes Hyderabad to GHMC plugin', () {
      final plugin =
          LocalGuidelinesManager.getPluginForRegion('Hyderabad, IN');
      expect(plugin, isNotNull);
      expect(plugin!.pluginId, equals('ghmc_hyderabad'));
    });

    test('routes Chennai to GCC plugin', () {
      final plugin =
          LocalGuidelinesManager.getPluginForRegion('Chennai, IN');
      expect(plugin, isNotNull);
      expect(plugin!.pluginId, equals('gcc_chennai'));
    });

    test('routes Kolkata to KMC plugin', () {
      final plugin =
          LocalGuidelinesManager.getPluginForRegion('Kolkata, IN');
      expect(plugin, isNotNull);
      expect(plugin!.pluginId, equals('kmc_kolkata'));
    });

    test('supports direct plugin-id lookup fallback', () {
      final plugin = LocalGuidelinesManager.getPluginForRegion('mcd_delhi');
      expect(plugin, isNotNull);
      expect(plugin!.pluginId, equals('mcd_delhi'));
    });

    test('returns null for unknown region', () {
      final plugin =
          LocalGuidelinesManager.getPluginForRegion('Unknown City');
      expect(plugin, isNull);
    });
  });
}
