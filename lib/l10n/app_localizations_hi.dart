// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get accountSection => 'Account';

  @override
  String get signOut => 'Sign Out';

  @override
  String get switchToGoogle => 'Switch to Google Account';

  @override
  String get signOutSubtitle => 'Sign out and return to login screen';

  @override
  String get guestModeSubtitle => 'Currently in guest mode - sign in to sync data';

  @override
  String get signOutConfirmTitle => 'Sign Out';

  @override
  String get signOutConfirmBody =>
      'Are you sure you want to sign out? Your data will remain on this device, but you won\'t be able to sync with the cloud.';

  @override
  String get cancel => 'Cancel';

  @override
  String get premiumSection => 'Premium';

  @override
  String get premiumFeatures => 'Premium Features';

  @override
  String get premiumFeaturesSubtitle => 'Unlock advanced features';

  @override
  String get appSettingsSection => 'App Settings';

  @override
  String get themeSettings => 'Theme Settings';

  @override
  String get themeSettingsSubtitle => 'Customize app appearance';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get notificationSettingsSubtitle => 'Manage notifications and alerts';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get offlineModeSubtitle => 'Configure offline functionality';

  @override
  String get dataExport => 'Data Export';

  @override
  String get dataExportSubtitle => 'Export your data and history';

  @override
  String get navigationSection => 'Navigation';

  @override
  String get navigationSettings => 'Navigation Settings';

  @override
  String get navigationSettingsSubtitle => 'Customize navigation behavior';

  @override
  String get bottomNavigation => 'Bottom Navigation';

  @override
  String get bottomNavigationSubtitle => 'Show bottom navigation bar';

  @override
  String get cameraButton => 'Camera Button (FAB)';

  @override
  String get cameraButtonSubtitle => 'Show floating camera button';

  @override
  String get navigationStyle => 'Navigation Style';

  @override
  String navigationStyleCurrent(String style) {
    return 'Current: $style';
  }

  @override
  String get navigationStyles => 'Navigation Styles';

  @override
  String get navigationStylesSubtitle => 'Try different navigation designs';

  @override
  String get featuresSection => 'Features & Tools';

  @override
  String get modernUIComponents => 'Modern UI Components';

  @override
  String get modernUIComponentsSubtitle => 'Showcase of new design elements';

  @override
  String get offlineModeClassify => 'Classify items without internet';

  @override
  String get analytics => 'Analytics';

  @override
  String get analyticsSubtitle => 'View your waste classification insights';

  @override
  String get advancedAnalytics => 'Advanced Analytics';

  @override
  String get advancedAnalyticsSubtitle => 'Detailed insights and trends';

  @override
  String get offlineModeComingSoon => 'Offline mode settings coming soon!';

  @override
  String get legalSupportSection => 'Legal & Support';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicySubtitle => 'How we handle your data';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get termsOfServiceSubtitle => 'Terms and conditions';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get helpSupportSubtitle => 'Get help and contact support';

  @override
  String get about => 'About';

  @override
  String get aboutSubtitle => 'App version and information';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get contactSupportSubtitle => 'Send us an email';

  @override
  String get reportBug => 'Report a Bug';

  @override
  String get reportBugSubtitle => 'Help us improve the app';

  @override
  String get rateApp => 'Rate the App';

  @override
  String get rateAppSubtitle => 'Leave a review';

  @override
  String get developerOptions => 'DEVELOPER OPTIONS';

  @override
  String get toggleDeveloperMode => 'Toggle Developer Mode';

  @override
  String get toggleFeaturesForTesting => 'Toggle features for testing';

  @override
  String get resetAll => 'Reset All';

  @override
  String get factoryReset => 'Factory Reset';

  @override
  String get factoryResetBody =>
      'This will delete ALL app data including classifications, settings, and user preferences. This action cannot be undone.\\n\\nAre you sure you want to continue?';

  @override
  String get resetAllData => 'Reset All Data';

  @override
  String get clearFirebaseData => 'Clear Firebase Data';

  @override
  String get clearFirebaseDataBody =>
      'This will clear all Firebase data for testing purposes. This simulates a fresh install experience.\\n\\nContinue?';

  @override
  String get clearData => 'Clear Data';

  @override
  String premiumFeatureTitle(String feature) {
    return '$feature - Premium Feature';
  }

  @override
  String premiumFeatureBody(String feature) {
    return '$feature is a premium feature. Upgrade to unlock this and other advanced features.';
  }

  @override
  String get upgrade => 'Upgrade';

  @override
  String bottomNavEnabled(String status) {
    return 'Bottom navigation $status';
  }

  @override
  String cameraButtonEnabled(String status) {
    return 'Camera button $status';
  }

  @override
  String navigationStyleChanged(String style) {
    return 'Navigation style changed to $style';
  }

  @override
  String get enabled => 'enabled';

  @override
  String get disabled => 'disabled';

  @override
  String get successfullySignedIn => 'Successfully signed in to Google account';

  @override
  String signOutFailed(String error) {
    return 'Failed to sign out: $error';
  }

  @override
  String get newFeatureBadge => 'New feature';

  @override
  String get updatedFeatureBadge => 'Updated feature';

  @override
  String get premiumFeatureBadge => 'Premium feature';

  @override
  String get toggleBottomNavigation => 'Toggle bottom navigation bar';

  @override
  String get toggleFloatingCameraButton => 'Toggle floating camera button';

  @override
  String get cameraShutterLabel => 'Camera shutter';

  @override
  String get cameraShutterHint => 'Takes a photo';

  @override
  String get startClassifyingHint => 'Opens the camera to classify waste';

  @override
  String get rewardConfettiLabel => 'Reward confetti';

  @override
  String get rewardConfettiHint => 'Celebrates your achievement';

  @override
  String get allPremiumFeaturesReset => 'All premium features reset';

  @override
  String get removeAds => 'Remove Ads';

  @override
  String get themeCustomization => 'Theme Customization';

  @override
  String get advancedAnalyticsFeature => 'Advanced Analytics';

  @override
  String get exportData => 'Export Data';

  @override
  String get forceCrashTest => 'Force Crash (Crashlytics Test)';

  @override
  String get resetFullData => 'Reset Full Data (Factory Reset)';

  @override
  String get clearFirebaseDataFresh => 'Clear Firebase Data (Fresh Install)';

  @override
  String get migrateOldClassifications => 'Migrate Old Classifications';

  @override
  String get glassmorphism => 'Glassmorphism';

  @override
  String get material3 => 'Material 3';

  @override
  String get floating => 'Floating';

  @override
  String get adsDisabled => 'Ads are disabled';

  @override
  String get manageAdPreferences => 'Manage ad preferences';

  @override
  String get adsCurrentlyDisabled => 'Ads are currently disabled';

  @override
  String get exportDataSubtitle => 'Export your classification history';

  @override
  String get googleCloudSync => 'Google Cloud Sync';

  @override
  String get feedbackSettings => 'Feedback Settings';

  @override
  String get feedbackSettingsSubtitle => 'Control when you can provide feedback';

  @override
  String get allowFeedbackRecentHistory => 'Allow Feedback on Recent History';

  @override
  String get feedbackTimeframe => 'Feedback Timeframe';

  @override
  String feedbackTimeframeDays(int days) {
    return 'Can provide feedback on items from last $days days';
  }

  @override
  String get oneDay => '1 day';

  @override
  String get threeDays => '3 days';

  @override
  String get sevenDays => '7 days';

  @override
  String get fourteenDays => '14 days';

  @override
  String get thirtyDays => '30 days';

  @override
  String get lastCloudSync => 'Last Cloud Sync';

  @override
  String get syncLocalDataToCloud => 'Sync Local Data to Cloud';

  @override
  String get syncLocalDataSubtitle => 'Upload existing local classifications to cloud';

  @override
  String get forceDownloadFromCloud => 'Force Download from Cloud';

  @override
  String get forceDownloadSubtitle => 'Download latest data from cloud';

  @override
  String get resetAllAppData => 'Reset all app data (history, settings, preferences)';

  @override
  String get allDataClearedSuccessfully => 'All data cleared successfully';

  @override
  String get privacyPolicyAndTerms => 'Privacy Policy and Terms of Service';

  @override
  String get appInformationAndCredits => 'App information and credits';

  @override
  String get getHelpViaEmail => 'Get help via email';

  @override
  String get helpUsImproveApp => 'Help us improve the app';

  @override
  String get rateUsOnAppStore => 'Rate us on the app store';

  @override
  String get signingOut => 'Signing out...';

  @override
  String errorSigningOut(String error) {
    return 'Error signing out: $error';
  }

  @override
  String get stayInGuestMode => 'Stay in Guest Mode';

  @override
  String get signIn => 'Sign In';

  @override
  String upgradeToUse(String feature) {
    return 'Upgrade to Use $feature';
  }

  @override
  String get notNow => 'Not Now';

  @override
  String get seePremiumFeatures => 'See Premium Features';

  @override
  String errorOpeningEmail(String error) {
    return 'Error opening email: $error';
  }

  @override
  String get unableToOpenAppStore =>
      'Unable to open app store. Please search for \"Waste Segregation App\" in your app store.';

  @override
  String errorOpeningAppStore(String error) {
    return 'Error opening app store: $error';
  }

  @override
  String get emailNotAvailable => 'Email Not Available';

  @override
  String get noEmailAppFound => 'No email app found. Please send an email to:';

  @override
  String get emailAddressCopied => 'Email address copied to clipboard';

  @override
  String get copyEmail => 'Copy Email';

  @override
  String get close => 'Close';

  @override
  String featureStatusChanged(String title, String status) {
    return '$title $status';
  }

  @override
  String get factoryResetWarning =>
      'This will delete ALL app data including:\\n\\n• All classification history\\n• All gamification progress (points, streaks, achievements)\\n• All user preferences and settings\\n• All cached data\\n• All premium feature settings\\n\\nThis action cannot be undone.\\n\\nAre you sure you want to continue?';

  @override
  String get resettingToFactorySettings => 'Resetting app to factory settings...';

  @override
  String get googleSyncDisabled => 'Google sync disabled. Future classifications will be saved locally only.';

  @override
  String failedToToggleGoogleSync(String error) {
    return 'Failed to toggle Google sync: $error';
  }

  @override
  String get googleSyncEnabled => 'Google Sync Enabled';

  @override
  String get googleSyncEnabledMessage => 'Google sync is now enabled!';
}
