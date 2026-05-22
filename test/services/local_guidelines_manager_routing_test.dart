import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/local_guidelines_plugin.dart';

void main() {
  group('LocalGuidelinesManager routing', () {
    setUpAll(() {
      LocalGuidelinesManager.initializeDefaultPlugins();
    });

    test('routes Bangalore aliases to BBMP plugin', () {
      expect(
          LocalGuidelinesManager.getPluginForRegion('Bangalore, IN')!.pluginId,
          equals('bbmp_bangalore'));
      expect(
          LocalGuidelinesManager.getPluginForRegion('Bengaluru')!.pluginId,
          equals('bbmp_bangalore'));
    });

    test('routes Mumbai aliases to BMC plugin', () {
      expect(
          LocalGuidelinesManager.getPluginForRegion('Mumbai, IN')!.pluginId,
          equals('bmc_mumbai'));
      expect(
          LocalGuidelinesManager.getPluginForRegion('Bombay')!.pluginId,
          equals('bmc_mumbai'));
    });

    test('routes Delhi aliases to MCD plugin', () {
      expect(
          LocalGuidelinesManager.getPluginForRegion('Delhi, IN')!.pluginId,
          equals('mcd_delhi'));
      expect(
          LocalGuidelinesManager.getPluginForRegion('New Delhi')!.pluginId,
          equals('mcd_delhi'));
    });

    test('routes Pune to PMC plugin', () {
      expect(
          LocalGuidelinesManager.getPluginForRegion('Pune, IN')!.pluginId,
          equals('pmc_pune'));
    });

    test('routes Hyderabad to GHMC plugin', () {
      expect(
          LocalGuidelinesManager.getPluginForRegion('Hyderabad, IN')!.pluginId,
          equals('ghmc_hyderabad'));
    });

    test('routes Chennai to GCC plugin', () {
      expect(
          LocalGuidelinesManager.getPluginForRegion('Chennai, IN')!.pluginId,
          equals('gcc_chennai'));
    });

    test('routes Kolkata to KMC plugin', () {
      expect(
          LocalGuidelinesManager.getPluginForRegion('Kolkata, IN')!.pluginId,
          equals('kmc_kolkata'));
    });

    test('routes Ahmedabad to AMC plugin', () {
      expect(
          LocalGuidelinesManager.getPluginForRegion('Ahmedabad, IN')!.pluginId,
          equals('amc_ahmedabad'));
    });

    test('routes Surat to SMC plugin', () {
      expect(
          LocalGuidelinesManager.getPluginForRegion('Surat, IN')!.pluginId,
          equals('smc_surat'));
    });

    test('routes Jaipur to JMC plugin', () {
      expect(
          LocalGuidelinesManager.getPluginForRegion('Jaipur, IN')!.pluginId,
          equals('jmc_jaipur'));
    });

    test('routes Lucknow to LMC plugin', () {
      expect(
          LocalGuidelinesManager.getPluginForRegion('Lucknow, IN')!.pluginId,
          equals('lmc_lucknow'));
    });

    test('routes Nagpur to NMC plugin', () {
      expect(
          LocalGuidelinesManager.getPluginForRegion('Nagpur, IN')!.pluginId,
          equals('nmc_nagpur'));
    });

    test('routes Indore to IMC plugin', () {
      expect(
          LocalGuidelinesManager.getPluginForRegion('Indore, IN')!.pluginId,
          equals('imc_indore'));
    });

    test('routes Bhopal to BMC Bhopal plugin', () {
      expect(
          LocalGuidelinesManager.getPluginForRegion('Bhopal, IN')!.pluginId,
          equals('bmc_bhopal'));
    });

    test('routes Coimbatore to CCMC plugin', () {
      expect(
          LocalGuidelinesManager.getPluginForRegion('Coimbatore, IN')!.pluginId,
          equals('ccmc_coimbatore'));
    });

    test('routes Kochi to Cochin plugin', () {
      expect(
          LocalGuidelinesManager.getPluginForRegion('Kochi, IN')!.pluginId,
          equals('cochin_kochi'));
      expect(
          LocalGuidelinesManager.getPluginForRegion('Cochin')!.pluginId,
          equals('cochin_kochi'));
    });

    test('routes Chandigarh to MCC plugin', () {
      expect(
          LocalGuidelinesManager.getPluginForRegion('Chandigarh, IN')!.pluginId,
          equals('mcc_chandigarh'));
    });

    test('supports direct plugin-id lookup fallback', () {
      expect(
          LocalGuidelinesManager.getPluginForRegion('mcd_delhi')!.pluginId,
          equals('mcd_delhi'));
    });

    test('returns null for unknown region', () {
      expect(LocalGuidelinesManager.getPluginForRegion('Unknown City'),
          isNull);
    });

    test('all 17 plugins are registered', () {
      final ids = [
        'bbmp_bangalore', 'bmc_mumbai', 'mcd_delhi', 'pmc_pune',
        'ghmc_hyderabad', 'gcc_chennai', 'kmc_kolkata',
        'amc_ahmedabad', 'smc_surat', 'jmc_jaipur', 'lmc_lucknow',
        'nmc_nagpur', 'imc_indore', 'bmc_bhopal', 'ccmc_coimbatore',
        'cochin_kochi', 'mcc_chandigarh',
      ];
      for (final id in ids) {
        expect(
          LocalGuidelinesManager.getPluginForRegion(id),
          isNotNull,
          reason: 'Plugin $id should be registered',
        );
      }
    });
  });
}
