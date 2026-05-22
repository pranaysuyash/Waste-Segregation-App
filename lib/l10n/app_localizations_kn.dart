// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kannada (`kn`).
class AppLocalizationsKn extends AppLocalizations {
  AppLocalizationsKn([String locale = 'kn']) : super(locale);

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
  String get hapticFeedback => 'Haptic Feedback';

  @override
  String get hapticFeedbackSubtitle => 'Vibrate on successful scan';

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
  String get trainingReviewQueue => 'Training Review Queue';

  @override
  String get trainingReviewQueueSubtitle => 'Review pending training samples and labels';

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
  String get advancedSegmentation => 'Advanced Segmentation';

  @override
  String get advancedSegmentationSubtitle => 'Identify multiple objects in a single image';

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
  String get debugMode => 'Debug Mode';

  @override
  String get debugModeSubtitle => 'Enable debug logging';

  @override
  String get performanceMonitor => 'Performance Monitor';

  @override
  String get performanceMonitorSubtitle => 'View performance metrics';

  @override
  String get resetAppData => 'Reset App Data';

  @override
  String get resetAppDataSubtitle => 'Clear all app data';

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
  String testModeFeature(String feature) {
    return 'Test mode: $feature';
  }

  @override
  String featureEnabledForTesting(String feature, String status) {
    return '$feature $status for testing';
  }

  @override
  String get supportContactComingSoon => 'Support contact feature coming soon!';

  @override
  String get bugReportComingSoon => 'Bug reporting feature coming soon!';

  @override
  String get rateAppComingSoon => 'App rating feature coming soon!';

  @override
  String get aboutDialogBodyLine1 => 'A comprehensive Flutter application for proper waste identification, segregation guidance, and environmental education.';

  @override
  String get aboutDialogBodyLine2 => 'Built with Flutter and powered by AI for accurate waste classification.';

  @override
  String get appName => 'Waste Segregation App';

  @override
  String get newBadge => 'NEW';

  @override
  String developerModeToggled(String status) {
    return 'Developer mode $status';
  }

  @override
  String get resettingAllData => 'Resetting all data...';

  @override
  String dataClearingFailed(String error) {
    return 'Data clearing failed: $error';
  }

  @override
  String migrationCompleted(int updated, int skipped, int errors) {
    return 'Migration completed: $updated updated, $skipped skipped, $errors errors';
  }

  @override
  String migrationFailed(String message) {
    return 'Migration failed: $message';
  }

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
  String get unableToOpenAppStore => 'Unable to open app store. Please search for \"Waste Segregation App\" in your app store.';

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
  String get factoryResetWarning => 'This will delete ALL app data including:\\n\\n• All classification history\\n• All gamification progress (points, streaks, achievements)\\n• All user preferences and settings\\n• All cached data\\n• All premium feature settings\\n\\nThis action cannot be undone.\\n\\nAre you sure you want to continue?';

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

  @override
  String get privacySection => 'ಗೌಪ್ಯತೆ ಮತ್ತು ಸಮ್ಮತಿ';

  @override
  String get leaderboardOptOut => 'ಲೀಡರ್ಬೋರ್ಡ್‌ನಿಂದ ಮರೆಮಾಡಿ';

  @override
  String get leaderboardOptOutHide => 'ಲೀಡರ್ಬೋರ್ಡ್‌ನಲ್ಲಿ ನಿಮ್ಮ ಹೆಸರು ಮತ್ತು ಫೋಟೋ ಮರೆಮಾಡಲಾಗಿದೆ';

  @override
  String get leaderboardOptOutVisible => 'ಲೀಡರ್ಬೋರ್ಡ್‌ನಲ್ಲಿ ನಿಮ್ಮ ಹೆಸರು ಮತ್ತು ಫೋಟೋ ಗೋಚರಿಸುತ್ತದೆ';

  @override
  String get leaderboardHidden => 'ನೀವು ಈಗ ಲೀಡರ್ಬೋರ್ಡ್‌ನಿಂದ ಮರೆಮಾಡಲ್ಪಟ್ಟಿದ್ದೀರಿ';

  @override
  String get leaderboardVisible => 'ನೀವು ಈಗ ಲೀಡರ್ಬೋರ್ಡ್‌ನಲ್ಲಿ ಗೋಚರಿಸುತ್ತಿದ್ದೀರಿ';

  @override
  String failedToUpdateLeaderboard(String error) {
    return 'ಲೀಡರ್ಬೋರ್ಡ್ ಗೌಪ್ಯತೆಯನ್ನು ನವೀಕರಿಸಲು ವಿಫಲವಾಗಿದೆ: $error';
  }

  @override
  String get noUserProfileFound => 'ಯಾವುದೇ ಬಳಕೆದಾರ ಪ್ರೊಫೈಲ್ ಕಂಡುಬಂದಿಲ್ಲ. ದಯವಿಟ್ಟು ಮೊದಲು ಸೈನ್ ಇನ್ ಮಾಡಿ.';

  @override
  String get trainingConsent => 'ನನ್ನ ಚಿತ್ರಗಳೊಂದಿಗೆ ಮಾದರಿಯನ್ನು ಸುಧಾರಿಸಿ';

  @override
  String get trainingConsentEnabled => 'ಸಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ. ನೀವು ಯಾವುದೇ ಸಮಯದಲ್ಲಿ ರದ್ದುಮಾಡಬಹುದು ಮತ್ತು ಕೊಡುಗೆ ನೀಡಿದ ತರಬೇತಿ ಅಭ್ಯರ್ಥಿಗಳನ್ನು ಅಳಿಸಲು ವಿನಂತಿಸಬಹುದು.';

  @override
  String get trainingConsentDisabled => 'ನಿಷ್ಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ. ಯಾವುದೇ ಹೊಸ ಚಿತ್ರ/ತಿದ್ದುಪಡಿ ತರಬೇತಿ ಅಭ್ಯರ್ಥಿಗಳನ್ನು ಪ್ರವೇಶಿಸುವುದಿಲ್ಲ.';

  @override
  String get trainingConsentGranted => 'ತರಬೇತಿ ಸಮ್ಮತಿಯನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ.';

  @override
  String get trainingConsentRevoked => 'ತರಬೇತಿ ಸಮ್ಮತಿಯನ್ನು ರದ್ದುಗೊಳಿಸಲಾಗಿದೆ ಮತ್ತು ಅಳಿಸಲು ವಿನಂತಿಸಲಾಗಿದೆ.';

  @override
  String couldNotUpdateTrainingConsent(String error) {
    return 'ತರಬೇತಿ ಸಮ್ಮತಿಯನ್ನು ನವೀಕರಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ: $error';
  }

  @override
  String get syncEnabledUploadPrompt => 'ನಿಮ್ಮ ಅಸ್ತಿತ್ವದಲ್ಲಿರುವ ಸ್ಥಳೀಯ ವರ್ಗೀಕರಣಗಳನ್ನು ಕ್ಲೌಡ್‌ಗೆ ಅಪ್‌ಲೋಡ್ ಮಾಡಲು ನೀವು ಬಯಸುವಿರಾ?';

  @override
  String get syncAvailableAcrossDevices => 'ಇದು ನಿಮ್ಮ ಎಲ್ಲಾ ಸಾಧನಗಳಲ್ಲಿ ಅವುಗಳನ್ನು ಲಭ್ಯವಾಗುವಂತೆ ಮಾಡುತ್ತದೆ.';

  @override
  String get skip => 'ಬಿಟ್ಟುಬಿಡಿ';

  @override
  String get uploadNow => 'ಈಗ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ';

  @override
  String get syncingDataToCloud => 'ಕ್ಲೌಡ್‌ಗೆ ಡೇಟಾ ಸಿಂಕ್ ಮಾಡಲಾಗುತ್ತಿದೆ...';

  @override
  String syncedToCloud(int count) {
    return '$count ವರ್ಗೀಕರಣಗಳನ್ನು ಕ್ಲೌಡ್‌ಗೆ ಯಶಸ್ವಿಯಾಗಿ ಸಿಂಕ್ ಮಾಡಲಾಗಿದೆ!';
  }

  @override
  String get noClassificationsSynced => 'ಯಾವುದೇ ವರ್ಗೀಕರಣಗಳನ್ನು ಸಿಂಕ್ ಮಾಡಲಾಗಿಲ್ಲ.';

  @override
  String syncFailed(String error) {
    return 'ಸಿಂಕ್ ವಿಫಲವಾಗಿದೆ: $error';
  }

  @override
  String get downloadingFromCloud => 'ಕ್ಲೌಡ್‌ನಿಂದ ಡೌನ್‌ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ...';

  @override
  String downloadedFromCloud(int count) {
    return 'ಕ್ಲೌಡ್‌ನಿಂದ $count ವರ್ಗೀಕರಣಗಳನ್ನು ಡೌನ್‌ಲೋಡ್ ಮಾಡಲಾಗಿದೆ!';
  }

  @override
  String get noClassificationsDownloaded => 'ಯಾವುದೇ ವರ್ಗೀಕರಣಗಳನ್ನು ಡೌನ್‌ಲೋಡ್ ಮಾಡಲಾಗಿಲ್ಲ.';

  @override
  String downloadFailed(String error) {
    return 'ಡೌನ್‌ಲೋಡ್ ವಿಫಲವಾಗಿದೆ: $error';
  }

  @override
  String get feedbackOnHistoryEnabled => 'ಇತಿಹಾಸದಿಂದ ಇತ್ತೀಚಿನ ವರ್ಗೀಕರಣಗಳ ಬಗ್ಗೆ ಪ್ರತಿಕ್ರಿಯೆ ನೀಡಬಹುದು';

  @override
  String get feedbackOnHistoryDisabled => 'ಹೊಸ ವರ್ಗೀಕರಣಗಳ ಬಗ್ಗೆ ಮಾತ್ರ ಪ್ರತಿಕ್ರಿಯೆ ನೀಡಬಹುದು';

  @override
  String get feedbackExplanationEnabled => 'ಅನೇಕ ವಸ್ತುಗಳನ್ನು ತ್ವರಿತವಾಗಿ ಸ್ಕ್ಯಾನ್ ಮಾಡಲು ಮತ್ತು ನಂತರ ಪ್ರತಿಕ್ರಿಯೆ ನೀಡಲು ಸೂಕ್ತವಾಗಿದೆ!';

  @override
  String get feedbackExplanationDisabled => 'ಪ್ರತಿಕ್ರಿಯೆಯು ವರ್ಗೀಕರಣದ ನಂತರ ತಕ್ಷಣವೇ ಮಾತ್ರ ಲಭ್ಯವಿರುತ್ತದೆ.';

  @override
  String get syncClassificationsLocally => 'ವರ್ಗೀಕರಣಗಳು ಸ್ವಯಂಚಾಲಿತವಾಗಿ ಕ್ಲೌಡ್‌ಗೆ ಸಿಂಕ್ ಆಗುತ್ತವೆ';

  @override
  String get syncClassificationsLocalOnly => 'ವರ್ಗೀಕರಣಗಳು ಸ್ಥಳೀಯವಾಗಿ ಮಾತ್ರ ಉಳಿಸಲ್ಪಡುತ್ತವೆ';

  @override
  String get enableNotifications => 'ಅಧಿಸೂಚನೆಗಳನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ';

  @override
  String get educationalContent => 'ಶೈಕ್ಷಣಿಕ ವಿಷಯ';

  @override
  String get gamification => 'ಗೇಮಿಫಿಕೇಶನ್';

  @override
  String get reminders => 'ಜ್ಞಾಪನೆಗಳು';

  @override
  String get notificationSettingsSaved => 'ಅಧಿಸೂಚನೆ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ಉಳಿಸಲಾಗಿದೆ';

  @override
  String get systemDefault => 'ಸಿಸ್ಟಮ್ ಡೀಫಾಲ್ಟ್';

  @override
  String get followSystemTheme => 'ಸಿಸ್ಟಮ್ ಥೀಮ್ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ಅನುಸರಿಸಿ';

  @override
  String get lightTheme => 'ಲೈಟ್ ಥೀಮ್';

  @override
  String get alwaysUseLight => 'ಯಾವಾಗಲೂ ಲೈಟ್ ಥೀಮ್ ಬಳಸಿ';

  @override
  String get darkTheme => 'ಡಾರ್ಕ್ ಥೀಮ್';

  @override
  String get alwaysUseDark => 'ಯಾವಾಗಲೂ ಡಾರ್ಕ್ ಥೀಮ್ ಬಳಸಿ';

  @override
  String get offlineSaved => 'ಆಫ್‌ಲೈನ್ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ಉಳಿಸಲಾಗಿದೆ';

  @override
  String get enableOfflineMode => 'ಆಫ್‌ಲೈನ್ ಮೋಡ್ ಸಕ್ರಿಯಗೊಳಿಸಿ';

  @override
  String downloadModel(String model) {
    return '$model ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ';
  }

  @override
  String removeModel(String model) {
    return '$model ತೆಗೆದುಹಾಕಿ';
  }

  @override
  String modelRemoved(String model) {
    return '$model ತೆಗೆದುಹಾಕಲಾಗಿದೆ';
  }

  @override
  String downloadingModel(String model) {
    return '$model ಡೌನ್‌ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ...';
  }

  @override
  String downloadingModelSize(String size) {
    return '$size ಡೌನ್‌ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ...';
  }

  @override
  String modelDownloaded(String model) {
    return '$model ಯಶಸ್ವಿಯಾಗಿ ಡೌನ್‌ಲೋಡ್ ಆಗಿದೆ';
  }

  @override
  String get downloadedModels => 'ಡೌನ್‌ಲೋಡ್ ಮಾಡಿದ ಮಾಡೆಲ್‌ಗಳು';

  @override
  String get advancedSettings => 'ಸುಧಾರಿತ ಸೆಟ್ಟಿಂಗ್‌ಗಳು';

  @override
  String get autoDownloadUpdates => 'ಮಾಡೆಲ್ ಅಪ್‌ಡೇಟ್‌ಗಳನ್ನು ಸ್ವಯಂಚಾಲಿತವಾಗಿ ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ';

  @override
  String get autoDownloadSubtitle => 'ಹೊಸ ಮಾಡೆಲ್ ಆವೃತ್ತಿಗಳನ್ನು ಸ್ವಯಂಚಾಲಿತವಾಗಿ ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ';

  @override
  String get compressImages => 'ಚಿತ್ರಗಳನ್ನು ಸಂಕುಚಿತಗೊಳಿಸಿ';

  @override
  String get compressSubtitle => 'ವೇಗದ ಸಂಸ್ಕರಣೆಗಾಗಿ ಚಿತ್ರದ ಗಾತ್ರ ಕಡಿಮೆ ಮಾಡಿ';

  @override
  String get storageOptimization => 'ಸಂಗ್ರಹಣೆ ಆಪ್ಟಿಮೈಜೇಶನ್';

  @override
  String get storageSubtitle => 'ಹಳೆಯ ಕ್ಯಾಶ್ ಫೈಲ್‌ಗಳನ್ನು ಸ್ವಯಂಚಾಲಿತವಾಗಿ ಸ್ವಚ್ಛಗೊಳಿಸಿ';

  @override
  String get storageUsage => 'ಸಂಗ್ರಹಣೆ ಬಳಕೆ';

  @override
  String get modelsDownloaded => 'ಡೌನ್‌ಲೋಡ್ ಮಾಡಿದ ಮಾಡೆಲ್‌ಗಳು:';

  @override
  String get totalStorageUsed => 'ಒಟ್ಟು ಸಂಗ್ರಹಣೆ ಬಳಕೆ:';

  @override
  String get available => 'ಲಭ್ಯವಿದೆ:';

  @override
  String get enableOfflineClassification => 'ಆಫ್‌ಲೈನ್ ವರ್ಗೀಕರಣವನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ';

  @override
  String get offlineEnabled => 'ಆಫ್‌ಲೈನ್ ಮೋಡ್ ಸಕ್ರಿಯಗೊಂಡಿದೆ';

  @override
  String get offlineDisabled => 'ಆಫ್‌ಲೈನ್ ಮೋಡ್ ನಿಷ್ಕ್ರಿಯಗೊಂಡಿದೆ';

  @override
  String get offlineDescription => 'ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕವಿಲ್ಲದೆಯೇ ತ್ಯಾಜ್ಯ ವಸ್ತುಗಳನ್ನು ವರ್ಗೀಕರಿಸಿ. ಆಫ್‌ಲೈನ್ ಮಾಡೆಲ್‌ಗಳನ್ನು ನಿಮ್ಮ ಸಾಧನಕ್ಕೆ ಡೌನ್‌ಲೋಡ್ ಮಾಡಲಾಗುತ್ತದೆ.';

  @override
  String get loadingOfflineSettings => 'ಆಫ್‌ಲೈನ್ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ...';

  @override
  String get save => 'ಉಳಿಸಿ';

  @override
  String get ok => 'ಸರಿ';

  @override
  String get remove => 'ತೆಗೆದುಹಾಕಿ';

  @override
  String get downloadFailedTitle => 'ಡೌನ್‌ಲೋಡ್ ವಿಫಲವಾಗಿದೆ';

  @override
  String modelDownloadFailed(String model) {
    return '$model ಡೌನ್‌ಲೋಡ್ ಮಾಡಲು ವಿಫಲವಾಗಿದೆ';
  }

  @override
  String modelRemoveFailed(String model) {
    return '$model ತೆಗೆದುಹಾಕಲು ವಿಫಲವಾಗಿದೆ';
  }

  @override
  String removeModelConfirm(String model) {
    return 'ನೀವು ಖಚಿತವಾಗಿ $model ಅನ್ನು ತೆಗೆದುಹಾಕಲು ಬಯಸುವಿರಾ? ನೀವು ನಂತರ ಮತ್ತೆ ಡೌನ್‌ಲೋಡ್ ಮಾಡಬಹುದು.';
  }

  @override
  String get premiumCustomThemesBody => 'ಕಸ್ಟಮ್ ಥೀಮ್‌ಗಳು ಪ್ರೀಮಿಯಂ ಚಂದಾದಾರಿಕೆಯೊಂದಿಗೆ ಲಭ್ಯವಿದೆ. ಈ ವೈಶಿಷ್ಟ್ಯವನ್ನು ಅನ್‌ಲಾಕ್ ಮಾಡಲು ಅಪ್‌ಗ್ರೇಡ್ ಮಾಡಿ!';
}
