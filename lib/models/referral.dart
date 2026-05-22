class Referral {
  Referral({
    required this.id,
    required this.referrerUid,
    required this.code,
    required this.createdAt,
    this.rewardedAt,
    this.rewardTier = 'free',
  });

  factory Referral.fromJson(Map<String, dynamic> json, String id) => Referral(
    id: id,
    referrerUid: json['referrerUid'] as String,
    code: json['code'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    rewardedAt: json['rewardedAt'] != null
      ? DateTime.parse(json['rewardedAt'] as String)
      : null,
    rewardTier: json['rewardTier'] as String? ?? 'free',
  );

  final String id;
  final String referrerUid;
  final String code;
  final DateTime createdAt;
  final DateTime? rewardedAt;
  final String rewardTier;

  Map<String, dynamic> toJson() => {
    'id': id,
    'referrerUid': referrerUid,
    'code': code,
    'createdAt': createdAt.toIso8601String(),
    if (rewardedAt != null) 'rewardedAt': rewardedAt!.toIso8601String(),
    'rewardTier': rewardTier,
  };
}

class ReferralRedemption {
  ReferralRedemption({
    required this.id,
    required this.code,
    required this.redeemedByUid,
    required this.redeemedAt,
  });

  factory ReferralRedemption.fromJson(Map<String, dynamic> json, String id) =>
    ReferralRedemption(
      id: id,
      code: json['code'] as String,
      redeemedByUid: json['redeemedByUid'] as String,
      redeemedAt: DateTime.parse(json['redeemedAt'] as String),
    );

  final String id;
  final String code;
  final String redeemedByUid;
  final DateTime redeemedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'redeemedByUid': redeemedByUid,
    'redeemedAt': redeemedAt.toIso8601String(),
  };
}
