/// Centralized route names for the application
class Routes {
  // Main app routes
  static const String home = '/';
  static const String settings = '/settings';
  static const String auth = '/auth';
  
  // Settings sub-routes
  static const String themeSettings = '/theme_settings';
  static const String notificationSettings = '/notification_settings';
  static const String offlineModeSettings = '/offline_mode_settings';
  static const String dataExport = '/data_export';
  static const String navigationDemo = '/navigation_demo';
  static const String modernUIShowcase = '/modern_ui_showcase';
  static const String premiumFeatures = '/premium_features';
  static const String premiumFeaturesHyphen = '/premium-features';
  static const String premium = '/premium';
  static const String wasteDashboard = '/waste_dashboard';
  
  // Legal routes
  static const String privacyPolicy = '/privacy_policy';
  static const String termsOfService = '/terms_of_service';
  static const String legalDocument = '/legal_document';
  
  // Classification routes
  static const String camera = '/camera';
  static const String classification = '/classification';
  static const String result = '/result';
  
  // Utility method to check if a route exists
  static bool isValidRoute(String route) {
    return _allRoutes.contains(route);
  }
  
  // Private list of all routes for validation
  static const List<String> _allRoutes = [
    home,
    settings,
    auth,
    themeSettings,
    notificationSettings,
    offlineModeSettings,
    dataExport,
    navigationDemo,
    modernUIShowcase,
    premiumFeatures,
    premiumFeaturesHyphen,
    premium,
    wasteDashboard,
    privacyPolicy,
    termsOfService,
    legalDocument,
    camera,
    classification,
    result,
  ];
} 