class PremiumFeature {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String route;
  final bool isEnabled;

  const PremiumFeature({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
    this.isEnabled = false,
  });

  factory PremiumFeature.fromJson(Map<String, dynamic> json) {
    return PremiumFeature(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      route: json['route'] as String,
      isEnabled: json['isEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'route': route,
      'isEnabled': isEnabled,
    };
  }

  static const List<PremiumFeature> features = [
    PremiumFeature(
      id: 'remove_ads',
      title: 'Remove Ads',
      description: 'Enjoy an ad-free experience',
      icon: 'block',
      route: '/settings/ads',
    ),
    PremiumFeature(
      id: 'theme_customization',
      title: 'Theme Customization',
      description: 'Choose between light and dark mode',
      icon: 'palette',
      route: '/settings/theme',
    ),
    PremiumFeature(
      id: 'offline_mode',
      title: 'Offline Classification',
      description: 'Classify items without internet connection',
      icon: 'offline_bolt',
      route: '/settings/offline',
    ),
    PremiumFeature(
      id: 'advanced_analytics',
      title: 'Advanced Analytics',
      description: 'Detailed insights about your waste segregation habits',
      icon: 'analytics',
      route: '/analytics',
    ),
    PremiumFeature(
      id: 'export_data',
      title: 'Data Export',
      description: 'Export your classification history and statistics',
      icon: 'file_download',
      route: '/settings/export',
    ),
  ];
} 