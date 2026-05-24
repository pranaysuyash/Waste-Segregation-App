/// Represents waste policy overrides registered by an apartment society / RWA.
///
/// Societies often have stricter or different rules than the municipal standard
/// (e.g. on-site composting mandate, specific collection windows, banned items
/// in common chute). These sit as a delta layer on top of the base city plugin.
///
/// The engine applies the base city plugin first, then overlays society
/// overrides. Conflicts are flagged in the policy decision's warnings list.
class SocietyPolicyOverride {
  const SocietyPolicyOverride({
    required this.societyId,
    required this.societyName,
    required this.basePluginId,
    required this.overrides,
    this.verifiedById,
    this.verifiedByName,
    this.verifiedAt,
    this.isVerified = false,
    this.locationLat,
    this.locationLng,
    this.address,
    this.unitCount,
  });

  factory SocietyPolicyOverride.fromJson(Map<String, dynamic> json) =>
      SocietyPolicyOverride(
        societyId: json['societyId'] as String,
        societyName: json['societyName'] as String,
        basePluginId: json['basePluginId'] as String,
        overrides: (json['overrides'] as List<dynamic>)
            .map((o) =>
                RuleOverride.fromJson(o as Map<String, dynamic>))
            .toList(),
        verifiedById: json['verifiedById'] as String?,
        verifiedByName: json['verifiedByName'] as String?,
        verifiedAt: json['verifiedAt'] != null
            ? DateTime.parse(json['verifiedAt'] as String)
            : null,
        isVerified: json['isVerified'] as bool? ?? false,
        locationLat: (json['locationLat'] as num?)?.toDouble(),
        locationLng: (json['locationLng'] as num?)?.toDouble(),
        address: json['address'] as String?,
        unitCount: json['unitCount'] as int?,
      );

  /// Firestore document ID or internal ID for this society
  final String societyId;

  /// Display name of the society / RWA
  final String societyName;

  /// The base city plugin this overrides (e.g. 'bbmp_bangalore')
  final String basePluginId;

  /// List of specific rule overrides
  final List<RuleOverride> overrides;

  /// User ID of the person who verified these rules (RWA secretary, admin)
  final String? verifiedById;

  /// Display name of the verifier
  final String? verifiedByName;

  /// When the rules were last verified
  final DateTime? verifiedAt;

  /// Whether the rules have been verified by a trusted authority
  final bool isVerified;

  /// GPS coordinates for proximity-based society detection
  final double? locationLat;
  final double? locationLng;

  /// Society address
  final String? address;

  /// Approximate number of units in the society
  final int? unitCount;

  Map<String, dynamic> toJson() => {
        'societyId': societyId,
        'societyName': societyName,
        'basePluginId': basePluginId,
        'overrides': overrides.map((o) => o.toJson()).toList(),
        'verifiedById': verifiedById,
        'verifiedByName': verifiedByName,
        'verifiedAt': verifiedAt?.toIso8601String(),
        'isVerified': isVerified,
        'locationLat': locationLat,
        'locationLng': locationLng,
        'address': address,
        'unitCount': unitCount,
      };
}

/// A single rule override within a society's policy.
class RuleOverride {
  const RuleOverride({
    required this.categoryKey,
    required this.overrideType,
    required this.value,
    this.description,
  });

  factory RuleOverride.fromJson(Map<String, dynamic> json) => RuleOverride(
        categoryKey: json['categoryKey'] as String,
        overrideType: RuleOverrideType.values.firstWhere(
          (e) => e.name == json['overrideType'],
          orElse: () => RuleOverrideType.binColor,
        ),
        value: json['value'] as String,
        description: json['description'] as String?,
      );

  /// Category this override applies to (e.g. 'wet_waste', 'dry_waste')
  final String categoryKey;

  /// What kind of override this is
  final RuleOverrideType overrideType;

  /// The override value (bin colour, frequency, instruction text)
  final String value;

  /// Human-readable description of this override
  final String? description;

  Map<String, dynamic> toJson() => {
        'categoryKey': categoryKey,
        'overrideType': overrideType.name,
        'value': value,
        'description': description,
      };
}

enum RuleOverrideType {
  /// Override the bin/bag colour for this category
  binColor,

  /// Override the collection frequency
  collectionFrequency,

  /// Override the disposal method
  disposalMethod,

  /// Override the collection location
  collectionLocation,

  /// Ban/disallow specific items in this category
  bannedItem,

  /// Custom instruction for a specific category
  customInstruction,
}

/// Enhanced `LocalPolicyDecision` extension when society override is applied.
class SocietyAwareDecision {
  const SocietyAwareDecision({
    required this.society,
    required this.appliedOverrides,
    required this.conflicts,
  });

  final SocietyPolicyOverride? society;
  final List<RuleOverride> appliedOverrides;
  final List<String> conflicts;
}
