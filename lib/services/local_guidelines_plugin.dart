import 'package:waste_segregation_app/models/waste_classification.dart';
import 'city_policy_data.dart';
import '../utils/waste_app_logger.dart';

/// Abstract base class for local guidelines plugins.
///
/// New cities should use [CityPolicyData] to power most methods without
/// writing custom logic. Only override [validateCompliance] when the city
/// has genuinely unique multi-field validation (e.g. BBMP).
abstract class LocalGuidelinesPlugin {
  String get pluginId;
  String get authorityName;
  String get guidelinesVersion;
  String get region;

  Future<WasteClassification> applyLocalGuidelines(
      WasteClassification classification);
  LocalComplianceResult validateCompliance(WasteClassification classification);
  Map<String, dynamic>? getLocalDisposalInstructions(
      String category, String? subcategory);
  Map<String, String> getColorCoding();
  Map<String, dynamic> getCollectionSchedule();
  Map<String, String> getLocalRegulations(String category);
}

/// Helper mixin-like base that delegates most methods to a [CityPolicyData].
///
/// Subclasses only need to provide [cityData] and optionally override
/// [validateCompliance] for city-specific logic. Everything else delegates.
mixin CityDataPluginMixin on LocalGuidelinesPlugin {
  CityPolicyData get cityData;

  @override
  String get pluginId => cityData.pluginId;
  @override
  String get authorityName => cityData.authorityName;
  @override
  String get guidelinesVersion => cityData.guidelinesVersion;
  @override
  String get region => cityData.region;

  @override
  Future<WasteClassification> applyLocalGuidelines(
      WasteClassification classification) async {
    return cityData.applyDefaults(this as LocalGuidelinesPlugin, classification);
  }

  @override
  LocalComplianceResult validateCompliance(
      WasteClassification classification) {
    return cityData.defaultValidateCompliance(
        this as LocalGuidelinesPlugin, classification);
  }

  @override
  Map<String, dynamic>? getLocalDisposalInstructions(
      String category, String? subcategory) {
    return cityData.getDisposalFor(category, subcategory);
  }

  @override
  Map<String, String> getColorCoding() => cityData.getColorCodingMap();

  @override
  Map<String, dynamic> getCollectionSchedule() =>
      cityData.getCollectionScheduleMap();

  @override
  Map<String, String> getLocalRegulations(String category) =>
      cityData.getLocalRegulations(category);
}

/// BBMP (Bruhat Bengaluru Mahanagara Palike) — Bangalore.
///
/// Keeps custom compliance validation (richer multi-field checks). Uses
/// [CityPolicyData] for data tables.
class BBMPBangalorePlugin extends LocalGuidelinesPlugin {
  @override
  String get pluginId => cityData.pluginId;
  @override
  String get authorityName => cityData.authorityName;
  @override
  String get guidelinesVersion => cityData.guidelinesVersion;
  @override
  String get region => cityData.region;

  static const CityPolicyData cityData = CityPolicyData.bbmp;

  @override
  Future<WasteClassification> applyLocalGuidelines(
      WasteClassification classification) async {
    try {
      WasteAppLogger.info('Applying BBMP guidelines to classification',
          context: {
            'plugin': pluginId,
            'item': classification.itemName,
            'category': classification.category,
          });

      final localRegulations = getLocalRegulations(classification.category);
      final complianceResult = validateCompliance(classification);
      final localInstructions = getLocalDisposalInstructions(
        classification.category,
        classification.subCategory,
      );

      var updatedClassification = classification.copyWith(
        localRegulations: localRegulations,
        bbmpComplianceStatus: complianceResult.status,
        localGuidelinesVersion: guidelinesVersion,
        localGuidelinesReference: _generateGuidelinesReference(classification),
      );

      if (localInstructions != null) {
        updatedClassification = _applyLocalDisposalOverrides(
          updatedClassification,
          localInstructions,
        );
      }

      final pointsModifier =
          _calculatePointsModifier(classification, complianceResult);
      if (pointsModifier != 0) {
        final newPoints = (classification.pointsAwarded ?? 10) + pointsModifier;
        updatedClassification = updatedClassification.copyWith(
          pointsAwarded: newPoints.clamp(5, 50),
        );
      }

      WasteAppLogger.info('BBMP guidelines applied successfully', context: {
        'compliance_status': complianceResult.status,
        'points_modifier': pointsModifier,
        'regulations_count': localRegulations.length,
      });

      return updatedClassification;
    } catch (e) {
      WasteAppLogger.severe('Error applying BBMP guidelines',
          error: e,
          context: {
            'plugin': pluginId,
            'item': classification.itemName,
          });
      return classification;
    }
  }

  @override
  LocalComplianceResult validateCompliance(
      WasteClassification classification) {
    final violations = <String>[];
    final warnings = <String>[];

    switch (classification.category.toLowerCase()) {
      case 'wet waste':
        _validateWetWasteCompliance(classification, violations, warnings);
        break;
      case 'dry waste':
        _validateDryWasteCompliance(classification, violations, warnings);
        break;
      case 'hazardous waste':
        _validateHazardousWasteCompliance(classification, violations, warnings);
        break;
      case 'medical waste':
        _validateMedicalWasteCompliance(classification, violations, warnings);
        break;
    }

    String status;
    if (violations.isNotEmpty) {
      status = 'violation';
    } else if (warnings.isNotEmpty) {
      status = 'requires_attention';
    } else {
      status = 'compliant';
    }

    return LocalComplianceResult(
      status: status,
      violations: violations,
      warnings: warnings,
      recommendations: _getComplianceRecommendations(classification),
    );
  }

  @override
  Map<String, dynamic>? getLocalDisposalInstructions(
      String category, String? subcategory) {
    return cityData.getDisposalFor(category, subcategory);
  }

  @override
  Map<String, String> getColorCoding() => cityData.getColorCodingMap();

  @override
  Map<String, dynamic> getCollectionSchedule() =>
      cityData.getCollectionScheduleMap();

  @override
  Map<String, String> getLocalRegulations(String category) =>
      cityData.getLocalRegulations(category);

  // -- BBMP-specific compliance logic --

  void _validateWetWasteCompliance(WasteClassification c,
      List<String> violations, List<String> warnings) {
    if (c.disposalMethod?.toLowerCase().contains('landfill') == true) {
      violations.add('Wet waste should not go to landfill - must be composted');
    }
    if (c.isCompostable != true) {
      warnings.add('Item should be marked as compostable if it\'s organic');
    }
    if (c.visualFeatures.any((f) => f.toLowerCase().contains('plastic'))) {
      violations.add('Remove plastic packaging before wet waste disposal');
    }
  }

  void _validateDryWasteCompliance(WasteClassification c,
      List<String> violations, List<String> warnings) {
    if (c.isRecyclable != true &&
        c.subCategory?.toLowerCase().contains('plastic') == true) {
      warnings.add('Most plastics are recyclable - verify recycling code');
    }
    if (c.visualFeatures.any((f) => f.toLowerCase().contains('dirty'))) {
      warnings.add('Clean items before dry waste disposal for better recycling');
    }
  }

  void _validateHazardousWasteCompliance(WasteClassification c,
      List<String> violations, List<String> warnings) {
    if (c.requiresSpecialDisposal != true) {
      violations.add('Hazardous waste must be marked as requiring special disposal');
    }
    if (c.riskLevel == 'safe') {
      warnings.add('Risk level may be underestimated for hazardous category');
    }
  }

  void _validateMedicalWasteCompliance(WasteClassification c,
      List<String> violations, List<String> warnings) {
    if (c.hasUrgentTimeframe != true) {
      violations.add('Medical waste requires immediate disposal');
    }
    if (c.requiredPPE?.isEmpty ?? true) {
      warnings.add('Medical waste handling typically requires PPE');
    }
  }

  List<String> _getComplianceRecommendations(WasteClassification c) {
    final recs = <String>[];
    recs.add(
        'Follow BBMP color-coding: ${getColorCoding()[c.category.toLowerCase().replaceAll(' ', '_')]}');

    final schedule = getCollectionSchedule()[
        c.category.toLowerCase().replaceAll(' ', '_')];
    if (schedule != null) {
      recs.add('Collection: ${schedule['frequency']} at ${schedule['time']}');
    }

    switch (c.category.toLowerCase()) {
      case 'wet waste':
        recs.add('Drain excess water before disposal');
        recs.add('Remove non-biodegradable packaging');
        break;
      case 'dry waste':
        recs.add('Clean and dry items for better recycling');
        recs.add('Sort by material type when possible');
        break;
      case 'hazardous waste':
        recs.add('Contact BBMP for special collection');
        recs.add('Store safely until disposal');
        break;
    }
    if (cityData.helpline.isNotEmpty) {
      recs.add('Helpline: ${cityData.helpline}');
    }
    return recs;
  }

  String _generateGuidelinesReference(WasteClassification c) {
    final cat = c.category.toLowerCase().replaceAll(' ', '_');
    return 'BBMP-2024-$cat-guidelines';
  }

  WasteClassification _applyLocalDisposalOverrides(
    WasteClassification classification,
    Map<String, dynamic> localInstructions,
  ) {
    final newMethod =
        localInstructions['primaryMethod'] ?? classification.disposalMethod;
    final locationOverride = localInstructions['location'];

    if (locationOverride != null) {
      final updatedInstructions = classification.disposalInstructions.copyWith(
        location: locationOverride,
      );
      return classification.copyWith(
        disposalMethod: newMethod,
        disposalInstructions: updatedInstructions,
      );
    }
    return classification.copyWith(disposalMethod: newMethod);
  }

  int _calculatePointsModifier(
    WasteClassification classification,
    LocalComplianceResult compliance,
  ) {
    var modifier = 0;
    switch (compliance.status) {
      case 'compliant':
        modifier += 3;
        break;
      case 'requires_attention':
        modifier += 1;
        break;
      case 'violation':
        modifier -= 2;
        break;
    }
    if (classification.localGuidelinesReference?.isNotEmpty == true) {
      modifier += 2;
    }
    return modifier;
  }
}

/// BMC (Brihanmumbai Municipal Corporation) — Mumbai.
class BMCMumbaiPlugin extends LocalGuidelinesPlugin with CityDataPluginMixin {
  @override
  CityPolicyData get cityData => CityPolicyData.bmc;
}

/// MCD (Municipal Corporation of Delhi) — Delhi.
class MCDDelhiPlugin extends LocalGuidelinesPlugin with CityDataPluginMixin {
  @override
  CityPolicyData get cityData => CityPolicyData.mcd;

  @override
  LocalComplianceResult validateCompliance(
      WasteClassification classification) {
    final result = cityData.defaultValidateCompliance(this, classification);
    if (classification.category.toLowerCase() == 'sanitary waste' &&
        (classification.requiresSpecialDisposal != true)) {
      result.warnings.add(
          'Sanitary waste should be wrapped securely before blue bin disposal.');
    }
    return result;
  }
}

/// PMC (Pune Municipal Corporation) — Pune.
class PunePMCPlugin extends LocalGuidelinesPlugin with CityDataPluginMixin {
  @override
  CityPolicyData get cityData => CityPolicyData.pmc;

  @override
  LocalComplianceResult validateCompliance(
      WasteClassification classification) {
    final result = cityData.defaultValidateCompliance(this, classification);
    if (classification.category.toLowerCase() == 'wet waste' &&
        classification.isCompostable != true) {
      result.warnings.add(
          'PMC encourages composting; wet waste should be compostable.');
    }
    return result;
  }
}

/// GHMC (Greater Hyderabad Municipal Corporation) — Hyderabad.
class GHMCHyderabadPlugin extends LocalGuidelinesPlugin
    with CityDataPluginMixin {
  @override
  CityPolicyData get cityData => CityPolicyData.ghmc;
}

/// GCC (Greater Chennai Corporation) — Chennai.
class GCCChennaiPlugin extends LocalGuidelinesPlugin with CityDataPluginMixin {
  @override
  CityPolicyData get cityData => CityPolicyData.gcc;
}

/// KMC (Kolkata Municipal Corporation) — Kolkata.
class KMKKolkataPlugin extends LocalGuidelinesPlugin with CityDataPluginMixin {
  @override
  CityPolicyData get cityData => CityPolicyData.kmc;

  @override
  LocalComplianceResult validateCompliance(
      WasteClassification classification) {
    final result = cityData.defaultValidateCompliance(this, classification);
    result.recommendations.add(
        'Consider selling recyclable dry waste to your local kabadiwala for better recycling rates.');
    return result;
  }
}

/// AMC (Ahmedabad Municipal Corporation) — Ahmedabad.
class AMCAhmedabadPlugin extends LocalGuidelinesPlugin with CityDataPluginMixin {
  @override
  CityPolicyData get cityData => CityPolicyData.amc;
}

/// SMC (Surat Municipal Corporation) — Surat.
class SMCSuratPlugin extends LocalGuidelinesPlugin with CityDataPluginMixin {
  @override
  CityPolicyData get cityData => CityPolicyData.smc;
}

/// JMC (Jaipur Municipal Corporation) — Jaipur.
class JMCJaipurPlugin extends LocalGuidelinesPlugin with CityDataPluginMixin {
  @override
  CityPolicyData get cityData => CityPolicyData.jmc;
}

/// LMC (Lucknow Municipal Corporation) — Lucknow.
class LMCLucknowPlugin extends LocalGuidelinesPlugin with CityDataPluginMixin {
  @override
  CityPolicyData get cityData => CityPolicyData.lmc;

  @override
  LocalComplianceResult validateCompliance(
      WasteClassification classification) {
    final result = cityData.defaultValidateCompliance(this, classification);
    result.recommendations.add(
        'Report garbage collection issues to Mayor helpline: ${cityData.helpline}');
    return result;
  }
}

/// NMC (Nagpur Municipal Corporation) — Nagpur.
class NMCNagpurPlugin extends LocalGuidelinesPlugin with CityDataPluginMixin {
  @override
  CityPolicyData get cityData => CityPolicyData.nmc;
}

/// IMC (Indore Municipal Corporation) — Indore.
class IMCIndorePlugin extends LocalGuidelinesPlugin with CityDataPluginMixin {
  @override
  CityPolicyData get cityData => CityPolicyData.imc;
}

/// BMC (Bhopal Municipal Corporation) — Bhopal.
class BMCBhopalPlugin extends LocalGuidelinesPlugin with CityDataPluginMixin {
  @override
  CityPolicyData get cityData => CityPolicyData.bmcBhopal;
}

/// CCMC (Coimbatore City Municipal Corporation) — Coimbatore.
class CCMCCoimbatorePlugin extends LocalGuidelinesPlugin
    with CityDataPluginMixin {
  @override
  CityPolicyData get cityData => CityPolicyData.ccmc;
}

/// Cochin Corporation — Kochi.
class CochinKochiPlugin extends LocalGuidelinesPlugin with CityDataPluginMixin {
  @override
  CityPolicyData get cityData => CityPolicyData.kochi;
}

/// MCC (Municipal Corporation Chandigarh) — Chandigarh.
class MCCChandigarhPlugin extends LocalGuidelinesPlugin
    with CityDataPluginMixin {
  @override
  CityPolicyData get cityData => CityPolicyData.mcc;
}

/// Result of local compliance validation.
class LocalComplianceResult {
  LocalComplianceResult({
    required this.status,
    required this.violations,
    required this.warnings,
    required this.recommendations,
  });

  String status;
  final List<String> violations;
  final List<String> warnings;
  final List<String> recommendations;
}

/// Extension for DisposalInstructions to support copyWith.
extension DisposalInstructionsExtension on DisposalInstructions {
  DisposalInstructions copyWith({
    String? primaryMethod,
    List<String>? steps,
    String? timeframe,
    String? location,
    List<String>? warnings,
    List<String>? tips,
    String? recyclingInfo,
    String? estimatedTime,
    bool? hasUrgentTimeframe,
  }) {
    return DisposalInstructions(
      primaryMethod: primaryMethod ?? this.primaryMethod,
      steps: steps ?? this.steps,
      timeframe: timeframe ?? this.timeframe,
      location: location ?? this.location,
      warnings: warnings ?? this.warnings,
      tips: tips ?? this.tips,
      recyclingInfo: recyclingInfo ?? this.recyclingInfo,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      hasUrgentTimeframe: hasUrgentTimeframe ?? this.hasUrgentTimeframe,
    );
  }
}

/// Local Guidelines Manager to handle multiple plugins.
class LocalGuidelinesManager {
  static final Map<String, LocalGuidelinesPlugin> _plugins = {};
  static final Map<String, String> _regionAliases = {
    'bangalore': 'bbmp_bangalore',
    'bengaluru': 'bbmp_bangalore',
    'mumbai': 'bmc_mumbai',
    'bombay': 'bmc_mumbai',
    'delhi': 'mcd_delhi',
    'new delhi': 'mcd_delhi',
    'pune': 'pmc_pune',
    'hyderabad': 'ghmc_hyderabad',
    'secunderabad': 'ghmc_hyderabad',
    'chennai': 'gcc_chennai',
    'madras': 'gcc_chennai',
    'kolkata': 'kmc_kolkata',
    'calcutta': 'kmc_kolkata',
    'ahmedabad': 'amc_ahmedabad',
    'surat': 'smc_surat',
    'jaipur': 'jmc_jaipur',
    'lucknow': 'lmc_lucknow',
    'nagpur': 'nmc_nagpur',
    'indore': 'imc_indore',
    'bhopal': 'bmc_bhopal',
    'coimbatore': 'ccmc_coimbatore',
    'kochi': 'cochin_kochi',
    'cochin': 'cochin_kochi',
    'chandigarh': 'mcc_chandigarh',
  };

  static void registerPlugin(LocalGuidelinesPlugin plugin) {
    _plugins[plugin.pluginId] = plugin;
    WasteAppLogger.info('Local guidelines plugin registered', context: {
      'plugin_id': plugin.pluginId,
      'authority': plugin.authorityName,
      'region': plugin.region,
    });
  }

  static LocalGuidelinesPlugin? getPluginForRegion(String region) {
    final normalized = region.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    for (final entry in _regionAliases.entries) {
      if (normalized.contains(entry.key)) {
        return _plugins[entry.value];
      }
    }

    if (_plugins.containsKey(normalized)) {
      return _plugins[normalized];
    }
    return null;
  }

  static Future<WasteClassification> applyLocalGuidelines(
    WasteClassification classification,
    String region,
  ) async {
    final plugin = getPluginForRegion(region);
    if (plugin != null) {
      return plugin.applyLocalGuidelines(classification);
    }

    WasteAppLogger.info('No local guidelines plugin found for region',
        context: {
          'region': region,
          'available_plugins': _plugins.keys.toList(),
        });

    return classification;
  }

  static void initializeDefaultPlugins() {
    if (_plugins.isNotEmpty) return;
    registerPlugin(BBMPBangalorePlugin());
    registerPlugin(BMCMumbaiPlugin());
    registerPlugin(MCDDelhiPlugin());
    registerPlugin(PunePMCPlugin());
    registerPlugin(GHMCHyderabadPlugin());
    registerPlugin(GCCChennaiPlugin());
    registerPlugin(KMKKolkataPlugin());
    registerPlugin(AMCAhmedabadPlugin());
    registerPlugin(SMCSuratPlugin());
    registerPlugin(JMCJaipurPlugin());
    registerPlugin(LMCLucknowPlugin());
    registerPlugin(NMCNagpurPlugin());
    registerPlugin(IMCIndorePlugin());
    registerPlugin(BMCBhopalPlugin());
    registerPlugin(CCMCCoimbatorePlugin());
    registerPlugin(CochinKochiPlugin());
    registerPlugin(MCCChandigarhPlugin());
  }
}
