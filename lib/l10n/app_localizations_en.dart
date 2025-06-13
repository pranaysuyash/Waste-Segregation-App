// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get signOutConfirmBody => 'Are you sure you want to sign out? Your data will remain on this device, but you won\'t be able to sync with the cloud.';

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
  String get factoryResetBody => 'This will delete ALL app data including classifications, settings, and user preferences. This action cannot be undone.\\n\\nAre you sure you want to continue?';

  @override
  String get resetAllData => 'Reset All Data';

  @override
  String get clearFirebaseData => 'Clear Firebase Data';

  @override
  String get clearFirebaseDataBody => 'This will clear all Firebase data for testing purposes. This simulates a fresh install experience.\\n\\nContinue?';

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
}
