import 'package:waste_segregation_app/models/waste_classification.dart';
import 'local_guidelines_plugin.dart';

/// Structured data bundle that powers a [LocalGuidelinesPlugin].
///
/// New cities ship as data first — a [CityPolicyData] instance plus a thin
/// plugin class that delegates to it.  Only override a method when the city
/// has genuinely different compliance logic (e.g. BBMP's per-category
/// multi-field validation).
///
/// Usage:
/// ```dart
/// class PunePMCPlugin extends LocalGuidelinesPlugin {
///   static final _data = CityPolicyData.pune();
///   @override String get pluginId => _data.pluginId;
///   // ... other getters delegate to _data
///   @override applyLocalGuidelines(c) => _data.applyDefaults(this, c);
///   // override validateCompliance only if city-specific logic needed
/// }
/// ```
class CityPolicyData {
  const CityPolicyData({
    required this.pluginId,
    required this.authorityName,
    required this.region,
    required this.guidelinesVersion,
    required this.colorCoding,
    required this.collectionSchedule,
    required this.disposalInstructions,
    required this.regulations,
    required this.helpline,
    required this.sourceUrl,
    this.subcategoryOverrides = const {},
    this.specialPrograms = const {},
    this.penaltyInfo,
    this.governanceStage = 'draft',
    this.owningTeam = 'policy_platform',
  });

  final String pluginId;
  final String authorityName;
  final String region;
  final String guidelinesVersion;
  final Map<String, String> colorCoding;
  final Map<String, Map<String, dynamic>> collectionSchedule;
  final Map<String, Map<String, dynamic>> disposalInstructions;
  final Map<String, Map<String, String>> regulations;
  final String helpline;
  final String sourceUrl;
  final Map<String, Map<String, dynamic>> subcategoryOverrides;
  final Map<String, String> specialPrograms;
  final String? penaltyInfo;
  final String governanceStage;
  final String owningTeam;

  String get guidelinesRefPrefix =>
      pluginId.toUpperCase().replaceAll('_', '-');

  LocalComplianceResult defaultValidateCompliance(
    LocalGuidelinesPlugin plugin,
    WasteClassification classification,
  ) {
    final violations = <String>[];
    final warnings = <String>[];
    final cat = classification.category.toLowerCase();

    if (cat == 'hazardous waste' &&
        classification.requiresSpecialDisposal != true) {
      violations.add(
        '$authorityName: Hazardous waste must be marked for special disposal.',
      );
    }
    if (cat == 'medical waste' &&
        classification.hasUrgentTimeframe != true) {
      violations.add(
        '$authorityName: Medical waste must be flagged urgent.',
      );
    }

    return LocalComplianceResult(
      status: violations.isNotEmpty
          ? 'violation'
          : warnings.isNotEmpty
              ? 'requires_attention'
              : 'compliant',
      violations: violations,
      warnings: warnings,
      recommendations: _defaultRecommendations(plugin, classification),
    );
  }

  Future<WasteClassification> applyDefaults(
    LocalGuidelinesPlugin plugin,
    WasteClassification classification,
  ) async {
    final compliance = plugin.validateCompliance(classification);
    final instructions = getDisposalFor(classification.category,
        classification.subcategory);
    final regs = regulations[classification.category
            .toLowerCase()
            .replaceAll(' ', '_')] ??
        {};

    var updated = classification.copyWith(
      localRegulations: {
        ...regs,
        'authority': authorityName,
        'helpline': helpline,
      },
      bbmpComplianceStatus: compliance.status,
      localGuidelinesVersion: guidelinesVersion,
      localGuidelinesReference:
          '$guidelinesRefPrefix-${classification.category.toLowerCase().replaceAll(' ', '_')}',
    );

    if (instructions != null) {
      updated = _applyDisposalOverrides(updated, instructions);
    }

    return updated;
  }

  Map<String, dynamic>? getDisposalFor(
      String category, String? subcategory) {
    final catKey = category.toLowerCase().replaceAll(' ', '_');
    final subKey = subcategory?.toLowerCase().replaceAll(' ', '_');

    final base = disposalInstructions[catKey];
    if (base == null) return null;

    if (subKey != null && subcategoryOverrides.containsKey(subKey)) {
      return {...base, ...subcategoryOverrides[subKey]!};
    }
    return base;
  }

  WasteClassification _applyDisposalOverrides(
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

  List<String> _defaultRecommendations(
    LocalGuidelinesPlugin plugin,
    WasteClassification classification,
  ) {
    final recs = <String>[];
    final catKey = classification.category.toLowerCase().replaceAll(' ', '_');

    final bin = colorCoding[catKey];
    if (bin != null) {
      recs.add('$authorityName bin: $bin');
    }

    final schedule = collectionSchedule[catKey];
    if (schedule != null) {
      recs.add(
        'Collection: ${schedule['frequency']}${schedule['time'] != null ? ' at ${schedule['time']}' : ''}',
      );
    }

    if (helpline.isNotEmpty) {
      recs.add('Helpline: $helpline');
    }

    return recs;
  }

  Map<String, String> getColorCodingMap() => colorCoding;

  Map<String, dynamic> getCollectionScheduleMap() => collectionSchedule;

  Map<String, String> getLocalRegulations(String category) {
    final catKey = category.toLowerCase().replaceAll(' ', '_');
    return regulations[catKey] ?? {};
  }

  // ---- Pre-built city instances ----

  static const CityPolicyData bbmp = CityPolicyData(
    pluginId: 'bbmp_bangalore',
    authorityName: 'BBMP',
    region: 'Bangalore, IN',
    guidelinesVersion: 'BBMP-2024.1',
    governanceStage: 'production',
    owningTeam: 'india_city_ops',
    helpline: '1800-425-1442',
    sourceUrl: 'https://bbmp.gov.in/swm',
    colorCoding: {
      'wet_waste': 'Green Bin/Bag',
      'dry_waste': 'Blue Bin/Bag',
      'hazardous_waste': 'Red Bin/Bag',
      'medical_waste': 'Yellow Bin/Bag',
      'e_waste': 'Red Bin (hazardous) or designated drop-off',
      'sanitary_waste': 'Blue Bin (wrapped securely)',
      'construction_waste': 'Separate collection required',
    },
    collectionSchedule: {
      'wet_waste': {
        'frequency': 'daily',
        'time': '6:00 AM - 9:00 AM',
        'notes': 'Collect daily to prevent pest infestation',
      },
      'dry_waste': {
        'frequency': 'alternate_days',
        'time': '6:00 AM - 9:00 AM',
        'notes': 'Clean and dry before disposal',
      },
      'hazardous_waste': {
        'frequency': 'monthly',
        'time': 'Contact BBMP for pickup',
        'notes': 'Special collection required',
      },
      'medical_waste': {
        'frequency': 'immediate',
        'time': 'Contact authorized dealer',
        'notes': 'Never mix with regular waste',
      },
    },
    disposalInstructions: {
      'wet_waste': {
        'primaryMethod': 'Compost or wet waste bin',
        'location': 'Green bin - daily collection',
        'timeframe': 'Daily disposal recommended',
        'bbmp_specific': 'Follow BBMP composting guidelines; apartments ≥10 units must compost',
      },
      'dry_waste': {
        'primaryMethod': 'Clean and recycle',
        'location': 'Blue bin - alternate day collection',
        'timeframe': 'Clean before disposal',
        'bbmp_specific': 'BBMP recycling partner network',
      },
      'hazardous_waste': {
        'primaryMethod': 'Special BBMP collection',
        'location': 'Red bin - monthly collection',
        'timeframe': 'Contact BBMP for pickup',
        'bbmp_specific': 'Helpline: 1800-425-1442',
      },
    },
    regulations: {
      'wet_waste': {
        'bin': 'Green bin/bag only',
        'composting': 'Mandatory for apartments with 10+ units',
        'penalty': 'Rs. 100-500 for non-compliance',
      },
      'dry_waste': {
        'bin': 'Blue bin/bag only',
        'cleaning': 'Must be clean and dry',
        'sorting': 'Sort by material type when possible',
      },
      'hazardous_waste': {
        'bin': 'Red bin/bag only',
        'contact': 'Contact BBMP helpline for pickup',
        'storage': 'Store in safe, dry place',
      },
      'medical_waste': {
        'bin': 'Yellow bin/bag only',
        'handling': 'Authorized dealer only',
        'warning': 'Never mix with regular waste',
      },
    },
    subcategoryOverrides: {
      'e_waste': {
        'location': 'Authorized e-waste collection center',
        'bbmp_specific': 'BBMP e-waste exchange program',
      },
      'battery': {
        'location': 'Battery collection box at retail stores',
        'bbmp_specific': 'Return to manufacturer program',
      },
    },
    specialPrograms: {
      'e_waste': 'BBMP e-waste exchange program',
      'bulk_waste': 'Prior intimation required for bulk pickup',
    },
    penaltyInfo: 'Rs. 100-500 spot fine for non-compliance',
  );

  static const CityPolicyData bmc = CityPolicyData(
    pluginId: 'bmc_mumbai',
    authorityName: 'BMC',
    region: 'Mumbai, IN',
    guidelinesVersion: 'BMC-2025.1',
    governanceStage: 'pilot',
    owningTeam: 'india_city_ops',
    helpline: '1916',
    sourceUrl: 'https://portal.mcgm.gov.in/swm',
    colorCoding: {
      'wet_waste': 'Green Bin/Bag',
      'dry_waste': 'Blue Bin/Bag',
      'hazardous_waste': 'Red Bin/Bag',
      'medical_waste': 'Yellow Bin/Bag',
      'e_waste': 'Designated BMC drop-off centres (27 across city)',
    },
    collectionSchedule: {
      'wet_waste': {
        'frequency': 'daily',
        'time': '7:00 AM - 10:00 AM',
        'notes': 'Door-to-door collection',
      },
      'dry_waste': {
        'frequency': '2x per week',
        'time': '7:00 AM - 10:00 AM',
        'notes': 'Check ward-specific schedule',
      },
      'hazardous_waste': {
        'frequency': 'quarterly',
        'time': 'Contact BMC',
        'notes': 'Special collection drive announced per ward',
      },
      'medical_waste': {
        'frequency': 'immediate',
        'time': 'Contact authorized biomedical waste handler',
        'notes': 'Never mix with MSW',
      },
    },
    disposalInstructions: {
      'wet_waste': {
        'primaryMethod': 'Wet waste bin',
        'location': 'Green bin - daily collection',
        'timeframe': 'Daily disposal',
        'bmc_specific': 'Separate wet waste from dry; no plastic bags in wet bin',
      },
      'dry_waste': {
        'primaryMethod': 'Dry waste collection',
        'location': 'Blue bin - twice weekly collection',
        'timeframe': 'Clean and dry before disposal',
        'bmc_specific': 'BMC has 27 e-waste drop-off centres',
      },
      'hazardous_waste': {
        'primaryMethod': 'Special collection',
        'location': 'Red bin - quarterly collection drive',
        'timeframe': 'Contact BMC ward office',
        'bmc_specific': 'Helpline: 1916',
      },
    },
    regulations: {
      'wet_waste': {
        'bin': 'Green bin only',
        'requirement': 'No plastic bags in wet waste',
        'penalty': 'Rs. 100-500',
      },
      'dry_waste': {
        'bin': 'Blue bin only',
        'cleaning': 'Items must be clean and dry',
        'e_waste': '27 dedicated drop-off centres',
      },
      'hazardous_waste': {
        'bin': 'Red bin',
        'disposal': 'Quarterly ward-level collection',
        'contact': 'Helpline 1916',
      },
    },
    subcategoryOverrides: {
      'e_waste': {
        'location': 'BMC e-waste drop-off centre',
        'bmc_specific': 'Find nearest centre at portal.mcgm.gov.in',
      },
    },
    specialPrograms: {
      'e_waste': '27 e-waste collection centres across Mumbai',
      'bulk_waste': 'Appointment required for bulk waste pickup',
    },
    penaltyInfo: 'Rs. 100-500 for improper segregation',
  );

  static const CityPolicyData mcd = CityPolicyData(
    pluginId: 'mcd_delhi',
    authorityName: 'MCD',
    region: 'Delhi, IN',
    guidelinesVersion: 'MCD-2025.1',
    governanceStage: 'pilot',
    owningTeam: 'india_city_ops',
    helpline: '155308',
    sourceUrl: 'https://mcdonline.nic.in/swm',
    colorCoding: {
      'wet_waste': 'Green Bin/Bag',
      'dry_waste': 'Blue Bin/Bag',
      'hazardous_waste': 'Red Bin/Bag',
      'medical_waste': 'Yellow Bin/Bag',
      'sanitary_waste': 'Pink Bin (MCD-specific)',
      'e_waste': 'Red Bin or designated recycler',
    },
    collectionSchedule: {
      'wet_waste': {
        'frequency': 'daily',
        'time': '6:00 AM - 10:00 AM',
        'notes': 'Door-to-door collection',
      },
      'dry_waste': {
        'frequency': '2x per week',
        'time': '6:00 AM - 10:00 AM',
        'notes': 'Segregation at source mandatory',
      },
      'hazardous_waste': {
        'frequency': 'quarterly',
        'time': 'Contact MCD',
        'notes': 'Special collection drive',
      },
      'medical_waste': {
        'frequency': 'immediate',
        'time': 'Contact authorized biomedical waste facility',
        'notes': 'Never mix with MSW; penalty for violation',
      },
    },
    disposalInstructions: {
      'wet_waste': {
        'primaryMethod': 'Green bin for daily collection',
        'location': 'Green bin',
        'timeframe': 'Daily disposal recommended',
        'mcd_specific': 'MCD mandates segregation at source',
      },
      'dry_waste': {
        'primaryMethod': 'Blue bin for recyclables',
        'location': 'Blue bin',
        'timeframe': 'Clean and dry before disposal',
        'mcd_specific': 'MCD empanelled recyclers for bulk dry waste',
      },
      'hazardous_waste': {
        'primaryMethod': 'Special MCD collection',
        'location': 'Red bin',
        'timeframe': 'Contact MCD for schedule',
        'mcd_specific': 'Helpline: 155308',
      },
    },
    regulations: {
      'wet_waste': {
        'bin': 'Green bin only',
        'mandate': 'Segregation at source is mandatory',
        'penalty': 'Rs. 200-1000 for violation',
      },
      'dry_waste': {
        'bin': 'Blue bin only',
        'requirement': 'Items must be clean and sorted',
        'bulk': 'MCD empanelled recyclers available',
      },
      'hazardous_waste': {
        'bin': 'Red bin',
        'disposal': 'Quarterly collection drives',
        'contact': 'Helpline 155308',
      },
      'medical_waste': {
        'bin': 'Yellow bin',
        'handling': 'Authorized BMW facility only',
        'penalty': 'Strict penalty for mixing with MSW',
      },
    },
    specialPrograms: {
      'sanitary_waste': 'Pink bin pilot program in select wards',
      'e_waste': 'MCD empanelled e-waste recyclers',
    },
    penaltyInfo: 'Rs. 200-1000 for non-compliance with segregation',
  );

  static const CityPolicyData pmc = CityPolicyData(
    pluginId: 'pmc_pune',
    authorityName: 'Pune Municipal Corporation',
    region: 'Pune, IN',
    guidelinesVersion: 'PMC-2025.1',
    governanceStage: 'pilot',
    owningTeam: 'india_city_ops',
    helpline: '1800-103-0503',
    sourceUrl: 'https://pmc.gov.in/swm',
    colorCoding: {
      'wet_waste': 'Green Bin/Bag',
      'dry_waste': 'Blue Bin/Bag',
      'hazardous_waste': 'Red Bin/Bag',
      'medical_waste': 'Yellow Bin/Bag (via authorized handler)',
      'e_waste': 'Quarterly PMC e-waste drives',
    },
    collectionSchedule: {
      'wet_waste': {
        'frequency': 'daily',
        'time': '7:00 AM - 10:00 AM',
        'notes': 'PMC mandates on-site composting for apartments ≥20 units',
      },
      'dry_waste': {
        'frequency': 'weekly',
        'time': '7:00 AM - 10:00 AM',
        'notes': 'Weekly collection; segregate recyclables',
      },
      'hazardous_waste': {
        'frequency': 'bi-monthly',
        'time': 'Contact PMC ward office',
        'notes': 'Special collection; notify ward office',
      },
      'medical_waste': {
        'frequency': 'immediate',
        'time': 'Contact authorized biomedical waste handler',
        'notes': 'Never mix with MSW',
      },
    },
    disposalInstructions: {
      'wet_waste': {
        'primaryMethod': 'Compost (preferred) or green bin',
        'location': 'Green bin or on-site composter',
        'timeframe': 'Daily disposal or compost on-site',
        'pmc_specific': 'PMC pioneer in decentralized waste processing; apartments ≥20 units must compost on-site',
      },
      'dry_waste': {
        'primaryMethod': 'Blue bin for weekly collection',
        'location': 'Blue bin',
        'timeframe': 'Clean and dry; store for weekly pickup',
        'pmc_specific': 'PMC has GPS-tracked collection vehicles',
      },
      'hazardous_waste': {
        'primaryMethod': 'Bi-monthly special collection',
        'location': 'Red bin - notify ward office',
        'timeframe': 'Contact PMC ward office for schedule',
        'pmc_specific': 'Helpline: 1800-103-0503',
      },
    },
    regulations: {
      'wet_waste': {
        'bin': 'Green bin',
        'composting': 'Mandatory on-site composting for apartments ≥20 units',
        'penalty': 'Rs. 50-200 for non-compliance',
      },
      'dry_waste': {
        'bin': 'Blue bin',
        'cleaning': 'Items must be clean and dry',
        'collection': 'Weekly collection by PMC',
      },
      'hazardous_waste': {
        'bin': 'Red bin',
        'collection': 'Bi-monthly; must notify ward office',
        'contact': 'Helpline 1800-103-0503',
      },
    },
    subcategoryOverrides: {
      'e_waste': {
        'location': 'PMC quarterly e-waste collection camps',
        'pmc_specific': 'Check pmc.gov.in for camp schedule',
      },
    },
    specialPrograms: {
      'composting': 'PMC provides subsidized compost bins',
      'e_waste': 'Quarterly e-waste collection drives',
      'bulk_waste': 'Online booking for bulk waste pickup',
    },
    penaltyInfo: 'Rs. 50-200 for non-compliance',
  );

  static const CityPolicyData ghmc = CityPolicyData(
    pluginId: 'ghmc_hyderabad',
    authorityName: 'GHMC',
    region: 'Hyderabad, IN',
    guidelinesVersion: 'GHMC-2025.1',
    governanceStage: 'pilot',
    owningTeam: 'india_city_ops',
    helpline: '040-21111111',
    sourceUrl: 'https://ghmc.gov.in/swm',
    colorCoding: {
      'wet_waste': 'Green Bin/Bag',
      'dry_waste': 'Blue Bin/Bag',
      'hazardous_waste': 'Red Bin/Bag',
      'medical_waste': 'Yellow Bin/Bag',
      'e_waste': 'GHMC e-waste bins at select locations',
    },
    collectionSchedule: {
      'wet_waste': {
        'frequency': 'daily',
        'time': '6:00 AM - 9:00 AM',
        'notes': 'Door-to-door collection by GHMC',
      },
      'dry_waste': {
        'frequency': 'alternate_days',
        'time': '6:00 AM - 9:00 AM',
        'notes': 'Clean and dry before disposal',
      },
      'hazardous_waste': {
        'frequency': 'monthly',
        'time': 'Contact GHMC',
        'notes': 'Special collection; helpline for schedule',
      },
      'medical_waste': {
        'frequency': 'immediate',
        'time': 'Contact authorized biomedical waste facility',
        'notes': 'Never mix with MSW',
      },
    },
    disposalInstructions: {
      'wet_waste': {
        'primaryMethod': 'Green bin for daily collection',
        'location': 'Green bin - daily door-to-door',
        'timeframe': 'Daily disposal',
        'ghmc_specific': 'GHMC mandates segregation at source',
      },
      'dry_waste': {
        'primaryMethod': 'Blue bin for recyclables',
        'location': 'Blue bin - alternate day collection',
        'timeframe': 'Clean and dry before disposal',
        'ghmc_specific': 'GHMC has material recovery facilities',
      },
      'hazardous_waste': {
        'primaryMethod': 'Special GHMC collection',
        'location': 'Red bin',
        'timeframe': 'Monthly collection; contact helpline',
        'ghmc_specific': 'Helpline: 040-21111111',
      },
    },
    regulations: {
      'wet_waste': {
        'bin': 'Green bin only',
        'mandate': 'Segregation at source mandatory',
        'penalty': 'Rs. 100-500 for violation',
      },
      'dry_waste': {
        'bin': 'Blue bin only',
        'cleaning': 'Must be clean and dry',
        'recycling': 'GHMC operates material recovery facilities',
      },
      'hazardous_waste': {
        'bin': 'Red bin',
        'disposal': 'Monthly special collection',
        'contact': 'Helpline 040-21111111',
      },
      'e_waste': {
        'disposal': 'GHMC e-waste bins at circle offices',
        'contact': 'Check ghmc.gov.in for nearest bin',
      },
    },
    subcategoryOverrides: {
      'e_waste': {
        'location': 'GHMC e-waste collection bin at circle office',
        'ghmc_specific': 'Drop at nearest GHMC e-waste bin',
      },
    },
    specialPrograms: {
      'e_waste': 'Dedicated e-waste bins at GHMC circle offices',
      'composting': 'GHMC promotes community composting',
    },
    penaltyInfo: 'Rs. 100-500 for non-compliance',
  );

  static const CityPolicyData gcc = CityPolicyData(
    pluginId: 'gcc_chennai',
    authorityName: 'Greater Chennai Corporation',
    region: 'Chennai, IN',
    guidelinesVersion: 'GCC-2025.1',
    governanceStage: 'pilot',
    owningTeam: 'india_city_ops',
    helpline: '1913',
    sourceUrl: 'https://chennaicorporation.gov.in/swm',
    colorCoding: {
      'wet_waste': 'Green Bin/Bag',
      'dry_waste': 'Blue Bin/Bag',
      'hazardous_waste': 'Red Bin/Bag',
      'medical_waste': 'Yellow Bin/Bag',
      'e_waste': 'Red Bin or GCC drop-off centre',
    },
    collectionSchedule: {
      'wet_waste': {
        'frequency': 'daily',
        'time': '6:00 AM - 10:00 AM',
        'notes': 'Door-to-door collection by GCC',
      },
      'dry_waste': {
        'frequency': 'alternate_days',
        'time': '6:00 AM - 10:00 AM',
        'notes': 'Segregation mandatory; bio-mining of legacy waste underway',
      },
      'hazardous_waste': {
        'frequency': 'monthly',
        'time': 'Contact GCC',
        'notes': 'Special collection; contact ward office',
      },
      'medical_waste': {
        'frequency': 'immediate',
        'time': 'Contact authorized BMW facility',
        'notes': 'Separate collection by authorized handlers',
      },
    },
    disposalInstructions: {
      'wet_waste': {
        'primaryMethod': 'Green bin for daily collection',
        'location': 'Green bin',
        'timeframe': 'Daily disposal',
        'gcc_specific': 'GCC operates bio-mining of legacy dump sites',
      },
      'dry_waste': {
        'primaryMethod': 'Blue bin for recyclables',
        'location': 'Blue bin',
        'timeframe': 'Clean and dry before disposal',
        'gcc_specific': 'GCC has material recovery facilities',
      },
      'hazardous_waste': {
        'primaryMethod': 'Monthly special collection',
        'location': 'Red bin',
        'timeframe': 'Contact GCC ward office',
        'gcc_specific': 'Helpline: 1913',
      },
    },
    regulations: {
      'wet_waste': {
        'bin': 'Green bin only',
        'mandate': 'Segregation at source mandatory',
        'penalty': 'Rs. 100-500',
      },
      'dry_waste': {
        'bin': 'Blue bin only',
        'cleaning': 'Items must be clean and dry',
        'sorting': 'Sort by material type when possible',
      },
      'hazardous_waste': {
        'bin': 'Red bin',
        'disposal': 'Monthly special collection',
        'contact': 'Helpline 1913',
      },
    },
    specialPrograms: {
      'bio_mining': 'Legacy waste bio-mining projects across Chennai',
      'e_waste': 'GCC designated e-waste collection points',
    },
    penaltyInfo: 'Rs. 100-500 for non-compliance',
  );

  static const CityPolicyData kmc = CityPolicyData(
    pluginId: 'kmc_kolkata',
    authorityName: 'Kolkata Municipal Corporation',
    region: 'Kolkata, IN',
    guidelinesVersion: 'KMC-2025.1',
    governanceStage: 'pilot',
    owningTeam: 'india_city_ops',
    helpline: '033-2286-1111',
    sourceUrl: 'https://kmcgov.in/swm',
    colorCoding: {
      'wet_waste': 'Green Bin/Bag',
      'dry_waste': 'Blue Bin/Bag',
      'hazardous_waste': 'Red Bin/Bag',
      'medical_waste': 'Yellow Bin/Bag',
      'e_waste': 'Red Bin or informal sector recycler',
    },
    collectionSchedule: {
      'wet_waste': {
        'frequency': 'daily',
        'time': '6:00 AM - 9:00 AM',
        'notes': 'Door-to-door; informal sector (kabadiwala) also active',
      },
      'dry_waste': {
        'frequency': 'alternate_days',
        'time': '6:00 AM - 9:00 AM',
        'notes': 'Informal sector plays major role in dry waste collection',
      },
      'hazardous_waste': {
        'frequency': 'monthly',
        'time': 'Contact KMC borough office',
        'notes': 'Limited formal collection; use authorized dealers',
      },
      'medical_waste': {
        'frequency': 'immediate',
        'time': 'Contact authorized biomedical waste handler',
        'notes': 'KMC has designated BMW collection',
      },
    },
    disposalInstructions: {
      'wet_waste': {
        'primaryMethod': 'Green bin or community composting',
        'location': 'Green bin',
        'timeframe': 'Daily disposal',
        'kmc_specific': 'KMC ward-level collection; informal sector supplements',
      },
      'dry_waste': {
        'primaryMethod': 'Blue bin or sell to kabadiwala',
        'location': 'Blue bin or local scrap dealer',
        'timeframe': 'Clean and dry',
        'kmc_specific': 'Kolkata has active informal recycling network; kabadiwala collects door-to-door',
      },
      'hazardous_waste': {
        'primaryMethod': 'Contact KMC or authorized dealer',
        'location': 'Red bin',
        'timeframe': 'Monthly collection; borough office',
        'kmc_specific': 'Helpline: 033-2286-1111',
      },
    },
    regulations: {
      'wet_waste': {
        'bin': 'Green bin',
        'mandate': 'Segregation encouraged',
        'note': 'Informal sector also collects organic waste for piggeries',
      },
      'dry_waste': {
        'bin': 'Blue bin',
        'recycling': 'Strong informal recycling network (kabadiwala)',
        'tip': 'Selling to kabadiwala often yields better recycling rates',
      },
      'hazardous_waste': {
        'bin': 'Red bin',
        'disposal': 'Limited formal collection; contact borough office',
        'contact': 'Helpline 033-2286-1111',
      },
      'medical_waste': {
        'handling': 'Authorized biomedical waste handler',
        'warning': 'Never mix with MSW',
      },
    },
    subcategoryOverrides: {
      'e_waste': {
        'location': 'Local scrap dealer or KMC authorized centre',
        'kmc_specific': 'Informal sector actively collects e-waste in Kolkata',
      },
    },
    specialPrograms: {
      'kabadiwala': 'Door-to-door scrap collection by informal sector',
      'composting': 'Community composting initiatives in select wards',
    },
    penaltyInfo: 'Penalty varies by borough; segregation not strictly enforced',
  );
}
