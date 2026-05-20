class NearMilestoneNudge {
  const NearMilestoneNudge({
    required this.isNear,
    this.iconName,
    required this.title,
    required this.message,
  });

  final bool isNear;
  final String? iconName;
  final String title;
  final String message;
}
