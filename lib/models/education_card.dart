enum EducationCardVariant {
  story,
  impact,
  mistake,
  localRule,
  alternative,
}

class WasteEducationCard {
  const WasteEducationCard({
    required this.id,
    required this.title,
    required this.body,
    required this.iconName,
    required this.variant,
    this.triggerCategories = const [],
    this.triggerMaterials = const [],
    this.triggerSubcategories = const [],
    this.applicableRegions = const ['all'],
    this.priority = 100,
    this.requiresExplicitDismiss = false,
    this.extendedBody,
  });

  final String id;
  final String title;
  final String body;
  final String iconName;
  final EducationCardVariant variant;
  final List<String> triggerCategories;
  final List<String> triggerMaterials;
  final List<String> triggerSubcategories;
  final List<String> applicableRegions;
  final int priority;
  final bool requiresExplicitDismiss;
  final String? extendedBody;
}

class SeenEducationCard {
  const SeenEducationCard({
    required this.cardId,
    required this.lastSeen,
    this.dismissCount = 0,
    this.permanentlyDismissed = false,
  });

  factory SeenEducationCard.fromJson(Map<String, dynamic> json) =>
      SeenEducationCard(
        cardId: json['cardId'] as String,
        lastSeen: DateTime.parse(json['lastSeen'] as String),
        dismissCount: json['dismissCount'] as int? ?? 0,
        permanentlyDismissed: json['permanentlyDismissed'] as bool? ?? false,
      );

  final String cardId;
  final DateTime lastSeen;
  final int dismissCount;
  final bool permanentlyDismissed;

  SeenEducationCard copyWith({
    String? cardId,
    DateTime? lastSeen,
    int? dismissCount,
    bool? permanentlyDismissed,
  }) {
    return SeenEducationCard(
      cardId: cardId ?? this.cardId,
      lastSeen: lastSeen ?? this.lastSeen,
      dismissCount: dismissCount ?? this.dismissCount,
      permanentlyDismissed: permanentlyDismissed ?? this.permanentlyDismissed,
    );
  }

  Map<String, dynamic> toJson() => {
        'cardId': cardId,
        'lastSeen': lastSeen.toIso8601String(),
        'dismissCount': dismissCount,
        'permanentlyDismissed': permanentlyDismissed,
      };
}
