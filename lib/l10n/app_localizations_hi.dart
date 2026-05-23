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
  String get appName => 'ReLoop';

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
  String get unableToOpenAppStore => 'Unable to open app store. Please search for \"ReLoop\" in your app store.';

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
  String get privacySection => 'गोपनीयता और सहमति';

  @override
  String get leaderboardOptOut => 'लीडरबोर्ड से छुपाएं';

  @override
  String get leaderboardOptOutHide => 'आपका नाम और फोटो लीडरबोर्ड पर छिपा दिया गया है';

  @override
  String get leaderboardOptOutVisible => 'आपका नाम और फोटो लीडरबोर्ड पर दिखाई देता है';

  @override
  String get leaderboardHidden => 'आप अब लीडरबोर्ड से छिपा दिए गए हैं';

  @override
  String get leaderboardVisible => 'आप अब लीडरबोर्ड पर दिखाई दे रहे हैं';

  @override
  String failedToUpdateLeaderboard(String error) {
    return 'लीडरबोर्ड गोपनीयता अपडेट करने में विफल: $error';
  }

  @override
  String get noUserProfileFound => 'कोई उपयोगकर्ता प्रोफ़ाइल नहीं मिली। कृपया पहले साइन इन करें।';

  @override
  String get trainingConsent => 'मेरी छवियों से मॉडल में सुधार करें';

  @override
  String get trainingConsentEnabled => 'सक्षम। आप कभी भी रद्द कर सकते हैं और योगदान किए गए प्रशिक्षण उम्मीदवारों को हटाने का अनुरोध कर सकते हैं।';

  @override
  String get trainingConsentDisabled => 'अक्षम। कोई नई छवि/सुधार प्रशिक्षण उम्मीदवारों में प्रवेश नहीं करता।';

  @override
  String get trainingConsentGranted => 'प्रशिक्षण सहमति सक्षम।';

  @override
  String get trainingConsentRevoked => 'प्रशिक्षण सहमति रद्द और हटाने का अनुरोध किया गया।';

  @override
  String couldNotUpdateTrainingConsent(String error) {
    return 'प्रशिक्षण सहमति अपडेट नहीं कर सका: $error';
  }

  @override
  String get syncEnabledUploadPrompt => 'क्या आप अपने मौजूदा स्थानीय वर्गीकरण को क्लाउड पर अपलोड करना चाहेंगे?';

  @override
  String get syncAvailableAcrossDevices => 'इससे वे आपके सभी उपकरणों पर उपलब्ध होंगे।';

  @override
  String get skip => 'छोड़ें';

  @override
  String get uploadNow => 'अभी अपलोड करें';

  @override
  String get syncingDataToCloud => 'क्लाउड पर डेटा सिंक हो रहा है...';

  @override
  String syncedToCloud(int count) {
    return '$count वर्गीकरण सफलतापूर्वक क्लाउड पर सिंक हुए!';
  }

  @override
  String get noClassificationsSynced => 'कोई वर्गीकरण सिंक नहीं हुआ।';

  @override
  String syncFailed(String error) {
    return 'सिंक विफल: $error';
  }

  @override
  String get downloadingFromCloud => 'क्लाउड से डाउनलोड हो रहा है...';

  @override
  String downloadedFromCloud(int count) {
    return 'क्लाउड से $count वर्गीकरण डाउनलोड हुए!';
  }

  @override
  String get noClassificationsDownloaded => 'कोई वर्गीकरण डाउनलोड नहीं हुआ।';

  @override
  String downloadFailed(String error) {
    return 'डाउनलोड विफल: $error';
  }

  @override
  String get feedbackOnHistoryEnabled => 'इतिहास से हाल के वर्गीकरण पर प्रतिक्रिया दे सकते हैं';

  @override
  String get feedbackOnHistoryDisabled => 'केवल नए वर्गीकरण पर प्रतिक्रिया दे सकते हैं';

  @override
  String get feedbackExplanationEnabled => 'एक साथ कई आइटम स्कैन करने और बाद में प्रतिक्रिया देने के लिए उपयुक्त';

  @override
  String get feedbackExplanationDisabled => 'प्रतिक्रिया केवल वर्गीकरण के तुरंत बाद उपलब्ध है';

  @override
  String get syncClassificationsLocally => 'वर्गीकरण स्वचालित रूप से क्लाउड पर सिंक होते हैं';

  @override
  String get syncClassificationsLocalOnly => 'वर्गीकरण केवल स्थानीय रूप से सहेजे जाते हैं';

  @override
  String get enableNotifications => 'सूचनाएं सक्षम करें';

  @override
  String get educationalContent => 'शैक्षिक सामग्री';

  @override
  String get gamification => 'गेमिफिकेशन';

  @override
  String get reminders => 'अनुस्मारक';

  @override
  String get notificationSettingsSaved => 'सूचना सेटिंग्स सहेजी गईं';

  @override
  String get systemDefault => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get followSystemTheme => 'सिस्टम थीम सेटिंग्स का पालन करें';

  @override
  String get lightTheme => 'लाइट थीम';

  @override
  String get alwaysUseLight => 'हमेशा लाइट थीम का उपयोग करें';

  @override
  String get darkTheme => 'डार्क थीम';

  @override
  String get alwaysUseDark => 'हमेशा डार्क थीम का उपयोग करें';

  @override
  String get offlineSaved => 'ऑफ़लाइन सेटिंग्स सहेजी गईं';

  @override
  String get enableOfflineMode => 'ऑफ़लाइन मोड सक्षम करें';

  @override
  String downloadModel(String model) {
    return '$model डाउनलोड करें';
  }

  @override
  String removeModel(String model) {
    return '$model हटाएं';
  }

  @override
  String modelRemoved(String model) {
    return '$model हटा दिया गया';
  }

  @override
  String downloadingModel(String model) {
    return '$model डाउनलोड हो रहा है...';
  }

  @override
  String downloadingModelSize(String size) {
    return '$size डाउनलोड हो रहा है...';
  }

  @override
  String modelDownloaded(String model) {
    return '$model सफलतापूर्वक डाउनलोड हुआ';
  }

  @override
  String get downloadedModels => 'डाउनलोड किए गए मॉडल';

  @override
  String get advancedSettings => 'उन्नत सेटिंग्स';

  @override
  String get autoDownloadUpdates => 'मॉडल अपडेट स्वचालित रूप से डाउनलोड करें';

  @override
  String get autoDownloadSubtitle => 'नए मॉडल संस्करण स्वचालित रूप से डाउनलोड करें';

  @override
  String get compressImages => 'इमेज कंप्रेस करें';

  @override
  String get compressSubtitle => 'तेज़ प्रोसेसिंग के लिए इमेज का आकार कम करें';

  @override
  String get storageOptimization => 'स्टोरेज ऑप्टिमाइज़ेशन';

  @override
  String get storageSubtitle => 'पुरानी कैश फ़ाइलों को स्वचालित रूप से साफ़ करें';

  @override
  String get storageUsage => 'स्टोरेज उपयोग';

  @override
  String get modelsDownloaded => 'डाउनलोड किए गए मॉडल:';

  @override
  String get totalStorageUsed => 'कुल स्टोरेज उपयोग:';

  @override
  String get available => 'उपलब्ध:';

  @override
  String get enableOfflineClassification => 'ऑफ़लाइन वर्गीकरण सक्षम करें';

  @override
  String get offlineEnabled => 'ऑफ़लाइन मोड सक्षम है';

  @override
  String get offlineDisabled => 'ऑफ़लाइन मोड अक्षम है';

  @override
  String get offlineDescription => 'इंटरनेट कनेक्शन के बिना अपशिष्ट वस्तुओं का वर्गीकरण करें। ऑफ़लाइन मॉडल आपके डिवाइस पर डाउनलोड हो जाएंगे।';

  @override
  String get loadingOfflineSettings => 'ऑफ़लाइन सेटिंग्स लोड हो रही हैं...';

  @override
  String get save => 'सहेजें';

  @override
  String get ok => 'ठीक है';

  @override
  String get remove => 'हटाएं';

  @override
  String get downloadFailedTitle => 'डाउनलोड विफल';

  @override
  String modelDownloadFailed(String model) {
    return '$model डाउनलोड करने में विफल';
  }

  @override
  String modelRemoveFailed(String model) {
    return '$model हटाने में विफल';
  }

  @override
  String removeModelConfirm(String model) {
    return 'क्या आप वाकई $model को हटाना चाहते हैं? आप इसे बाद में फिर से डाउनलोड कर सकते हैं।';
  }

  @override
  String get premiumCustomThemesBody => 'कस्टम थीम प्रीमियम सब्सक्रिप्शन के साथ उपलब्ध हैं। इस सुविधा को अनलॉक करने के लिए अपग्रेड करें!';
}
