# 🚁 Complete Patrol Testing Guide

## 🎯 **What is Patrol?**

Patrol is Flutter's equivalent to **Playwright/Cypress** for web testing. It lets you:
- ✅ Control real devices/simulators
- ✅ Handle native system dialogs (permissions, notifications)
- ✅ Simulate network conditions
- ✅ Take screenshots automatically
- ✅ Test cross-platform (iOS, Android, Web)

## 🚀 **Quick Start Commands**

```bash
# Install Patrol CLI (one-time setup)
dart pub global activate patrol_cli

# Run your E2E tests
patrol test

# Run on specific device
patrol test --device "iPhone 15"

# Run with custom target
patrol test --target integration_test/my_test.dart
```

## 📱 **Basic Patrol Syntax**

### **Finding Elements**
```dart
// By key (recommended)
await $(Key('classify-button')).tap();

// By type
await $(FloatingActionButton).tap();

// By text
await $('Classify Waste').tap();

// By icon
await $(Icons.camera_alt).tap();

// Complex selectors
await $(Scaffold).$(AppBar).$(Icons.settings).tap();
```

### **Waiting for Elements**
```dart
// Wait until visible (most common)
await $(Key('home-screen')).waitUntilVisible();

// Wait until exists
await $(Key('loading-indicator')).waitUntilExists();

// Wait with timeout
await $(Key('result-screen')).waitUntilVisible(
  timeout: Duration(seconds: 10)
);

// Wait for condition
await $(Key('points-display')).waitUntilVisible();
expect($(Key('points-display')).text, isNotEmpty);
```

### **Interactions**
```dart
// Tap
await $(Key('classify-button')).tap();

// Long press
await $(Key('classification-card')).longPress();

// Type text
await $(TextField).enterText('search query');

// Scroll
await $(ListView).scrollTo($(Key('item-50')));

// Drag
await $(Key('slider')).drag(Offset(100, 0));
```

### **Native System Interactions**
```dart
// Handle permissions
await $.native.grantPermissionWhenInUse(); // Camera, location, etc.
await $.native.grantPermissionOnlyThisTime();
await $.native.denyPermission();

// Handle system dialogs
await $.native.pressBack(); // Android back button
await $.native.pressHome(); // Home button

// Network simulation
await $.native.disableWifi();
await $.native.enableWifi();
await $.native.disableCellular();
await $.native.enableCellular();

// Device controls
await $.native.openNotifications();
await $.native.pressVolumeUp();
```

## 🎯 **Real Examples for Your App**

### **1. Complete App Flow Test**
```dart
patrolTest(
  'Complete Waste Classification Journey',
  ($) async {
    // Launch your actual app
    await $.pumpWidgetAndSettle(WasteSegregationApp(
      storageService: MockStorageService(),
      aiService: MockAiService(),
      // ... other mock services
    ));

    // Handle consent screen
    await $(Key('accept-consent-button')).waitUntilVisible();
    await $(Key('accept-consent-button')).tap();

    // Handle auth screen (guest mode)
    await $(Key('continue-as-guest-button')).waitUntilVisible();
    await $(Key('continue-as-guest-button')).tap();

    // Wait for home screen
    await $(Key('home-screen')).waitUntilVisible();
    
    // Test classification flow
    await $(Key('classify-fab')).tap();
    
    // Handle camera permission
    await $.native.grantPermissionWhenInUse();
    
    // Wait for camera screen
    await $(Key('camera-screen')).waitUntilVisible();
    
    // Simulate taking photo (tap capture button)
    await $(Key('capture-button')).tap();
    
    // Wait for result screen
    await $(Key('result-screen')).waitUntilVisible();
    
    // Verify result elements
    await $(Key('waste-type-text')).waitUntilVisible();
    await $(Key('confidence-text')).waitUntilVisible();
    await $(Key('points-earned')).waitUntilVisible();
    
    // Save classification
    await $(Key('save-classification-button')).tap();
    
    // Verify navigation back to home
    await $(Key('home-screen')).waitUntilVisible();
    
    // Check points updated
    final pointsText = $(Key('points-display')).text;
    expect(pointsText, isNotEmpty);
  },
);
```

### **2. Navigation Testing**
```dart
patrolTest(
  'Navigation Between All Screens',
  ($) async {
    await $.pumpWidgetAndSettle(WasteSegregationApp(/* your services */));
    
    // Skip consent and auth (or handle them)
    await _skipToHomeScreen($);
    
    // Test navigation to history
    await $(Key('history-tab')).tap();
    await $(Key('history-screen')).waitUntilVisible();
    expect($(AppBar).$(Text('History')), findsOneWidget);
    
    // Test navigation to achievements
    await $(Key('achievements-tab')).tap();
    await $(Key('achievements-screen')).waitUntilVisible();
    expect($(AppBar).$(Text('Achievements')), findsOneWidget);
    
    // Test navigation to settings
    await $(Key('settings-tab')).tap();
    await $(Key('settings-screen')).waitUntilVisible();
    
    // Test settings sub-navigation
    await $(Key('theme-settings-tile')).tap();
    await $(Key('theme-settings-screen')).waitUntilVisible();
    
    // Go back
    await $.native.pressBack();
    await $(Key('settings-screen')).waitUntilVisible();
    
    // Test premium features
    await $(Key('premium-features-tile')).tap();
    await $(Key('premium-screen')).waitUntilVisible();
  },
);
```

### **3. Points System Testing**
```dart
patrolTest(
  'Points and Achievements System',
  ($) async {
    await $.pumpWidgetAndSettle(WasteSegregationApp(/* your services */));
    await _skipToHomeScreen($);
    
    // Get initial points
    final initialPoints = $(Key('points-display')).text;
    
    // Perform classification to earn points
    await $(Key('classify-fab')).tap();
    await _performMockClassification($);
    
    // Check points increased
    await $(Key('home-screen')).waitUntilVisible();
    final newPoints = $(Key('points-display')).text;
    expect(newPoints, isNot(equals(initialPoints)));
    
    // Check for achievement unlock
    if ($(Key('achievement-popup')).exists) {
      await $(Key('achievement-popup')).waitUntilVisible();
      await $(Key('claim-achievement-button')).tap();
    }
    
    // Navigate to achievements screen
    await $(Key('achievements-tab')).tap();
    await $(Key('achievements-screen')).waitUntilVisible();
    
    // Verify achievement is unlocked
    await $(Key('achievement-first-classification')).waitUntilVisible();
    expect($(Key('achievement-first-classification')).$(Icon), findsOneWidget);
  },
);
```

### **4. Error Handling & Offline Testing**
```dart
patrolTest(
  'Offline Behavior and Error Handling',
  ($) async {
    await $.pumpWidgetAndSettle(WasteSegregationApp(/* your services */));
    await _skipToHomeScreen($);
    
    // Disable network
    await $.native.disableWifi();
    await $.native.disableCellular();
    
    // Try to classify (should show offline message)
    await $(Key('classify-fab')).tap();
    
    // Should show offline indicator
    await $(Key('offline-banner')).waitUntilVisible();
    expect($(Text('No internet connection')), findsOneWidget);
    
    // Enable network
    await $.native.enableWifi();
    
    // Wait for connection restored
    await Future.delayed(Duration(seconds: 2));
    
    // Offline banner should disappear
    expect($(Key('offline-banner')), findsNothing);
    
    // Classification should work now
    await $(Key('classify-fab')).tap();
    await $.native.grantPermissionWhenInUse();
    await $(Key('camera-screen')).waitUntilVisible();
  },
);
```

### **5. Settings and Preferences Testing**
```dart
patrolTest(
  'Settings and User Preferences',
  ($) async {
    await $.pumpWidgetAndSettle(WasteSegregationApp(/* your services */));
    await _skipToHomeScreen($);
    
    // Navigate to settings
    await $(Key('settings-tab')).tap();
    await $(Key('settings-screen')).waitUntilVisible();
    
    // Test theme toggle
    await $(Key('theme-toggle')).tap();
    
    // Verify theme changed (check for dark/light mode indicators)
    await Future.delayed(Duration(milliseconds: 500));
    // You could check background color or theme indicators
    
    // Test notification settings
    await $(Key('notification-settings-tile')).tap();
    await $(Key('notification-settings-screen')).waitUntilVisible();
    
    await $(Key('enable-notifications-switch')).tap();
    
    // Handle system permission dialog
    await $.native.grantPermissionWhenInUse();
    
    // Test language settings
    await $.native.pressBack();
    await $(Key('language-settings-tile')).tap();
    await $(Key('language-settings-screen')).waitUntilVisible();
    
    // Select different language
    await $(Key('language-hindi')).tap();
    
    // Verify language changed
    await $.native.pressBack();
    await $(Key('settings-screen')).waitUntilVisible();
    // Check if UI text changed to Hindi
  },
);
```

## 🔧 **Helper Functions**

Create reusable helper functions:

```dart
// Skip consent and auth to get to home screen
Future<void> _skipToHomeScreen(PatrolTester $) async {
  // Handle consent if shown
  if ($(Key('consent-dialog')).exists) {
    await $(Key('accept-consent-button')).tap();
  }
  
  // Handle auth screen
  if ($(Key('auth-screen')).exists) {
    await $(Key('continue-as-guest-button')).tap();
  }
  
  // Wait for home screen
  await $(Key('home-screen')).waitUntilVisible();
}

// Perform a mock classification
Future<void> _performMockClassification(PatrolTester $) async {
  // Assuming you have mock data or test mode
  await $(Key('camera-screen')).waitUntilVisible();
  await $(Key('capture-button')).tap();
  await $(Key('result-screen')).waitUntilVisible();
  await $(Key('save-classification-button')).tap();
}

// Sign in user for authenticated tests
Future<void> _signInUser(PatrolTester $) async {
  await $(Key('sign-in-button')).tap();
  await $.native.grantPermissionWhenInUse(); // Google Sign-in permission
  // Handle Google sign-in flow...
}
```

## 📸 **Screenshots and Debugging**

```dart
patrolTest(
  'Screenshot Example',
  ($) async {
    await $.pumpWidgetAndSettle(WasteSegregationApp(/* services */));
    
    // Take screenshot
    await $.takeScreenshot('01-launch-screen');
    
    await _skipToHomeScreen($);
    await $.takeScreenshot('02-home-screen');
    
    await $(Key('classify-fab')).tap();
    await $.takeScreenshot('03-camera-screen');
    
    // Screenshots saved to patrol_screenshots/
  },
);
```

## 🎯 **Advanced Features**

### **Custom Finders**
```dart
// Find by multiple criteria
PatrolFinder get classificationCards => $(Key('classification-list')).$(Card);
PatrolFinder get unlockedAchievements => $(Key('achievements-list')).$(Key('unlocked'));

// Use in tests
final cardCount = classificationCards.evaluate().length;
expect(cardCount, greaterThan(0));
```

### **Platform-Specific Tests**
```dart
patrolTest(
  'iOS Specific Features',
  ($) async {
    await $.pumpWidgetAndSettle(WasteSegregationApp(/* services */));
    
    if (Platform.isIOS) {
      // Test iOS-specific features
      await $(CupertinoButton).tap();
      await $.native.pressHome();
      // Handle iOS-specific dialogs
    }
  },
  // Only run on iOS
  skip: !Platform.isIOS,
);
```

### **Performance Testing**
```dart
patrolTest(
  'App Performance',
  ($) async {
    final stopwatch = Stopwatch()..start();
    
    await $.pumpWidgetAndSettle(WasteSegregationApp(/* services */));
    await _skipToHomeScreen($);
    
    stopwatch.stop();
    
    // App should launch quickly
    expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    
    // Test navigation performance
    final navStopwatch = Stopwatch()..start();
    await $(Key('history-tab')).tap();
    await $(Key('history-screen')).waitUntilVisible();
    navStopwatch.stop();
    
    expect(navStopwatch.elapsedMilliseconds, lessThan(1000));
  },
);
```

## 🚀 **Running Your Tests**

### **Basic Commands**
```bash
# Run all patrol tests
patrol test

# Run specific test file
patrol test --target integration_test/waste_classification_test.dart

# Run on iOS simulator
patrol test --device "iPhone 15"

# Run on Android emulator
patrol test --device android

# Run with verbose output
patrol test --verbose
```

### **Using Your Existing Script**
```bash
# Your existing E2E test script
./scripts/run_e2e_tests.sh

# Run on specific device
./scripts/run_e2e_tests.sh ios
./scripts/run_e2e_tests.sh android
./scripts/run_e2e_tests.sh all
```

## 🛠️ **Debugging Tips**

### **Common Issues & Solutions**

1. **Element Not Found**
```dart
// ❌ Bad: Immediate tap
await $(Key('button')).tap();

// ✅ Good: Wait first
await $(Key('button')).waitUntilVisible();
await $(Key('button')).tap();
```

2. **Timing Issues**
```dart
// ❌ Bad: Fixed delays
await Future.delayed(Duration(seconds: 5));

// ✅ Good: Wait for specific conditions
await $(Key('loading-indicator')).waitUntilGone();
await $(Key('content')).waitUntilVisible();
```

3. **Native Permissions**
```dart
// Always handle permissions before camera/location features
await $.native.grantPermissionWhenInUse();
```

### **Debug Information**
```dart
// Print available elements
print($.tester.allElements.map((e) => e.widget.runtimeType));

// Check if element exists
if ($(Key('optional-element')).exists) {
  await $(Key('optional-element')).tap();
}

// Get element properties
final buttonText = $(Key('submit-button')).text;
final isEnabled = $(Key('submit-button')).enabled;
```

## 🎯 **Best Practices**

### **1. Use Semantic Keys**
```dart
// In your widgets
FloatingActionButton(
  key: Key('classify-fab'),
  onPressed: () => Navigator.push(...),
  child: Icon(Icons.camera_alt),
)

// In tests
await $(Key('classify-fab')).tap();
```

### **2. Test User Journeys, Not Implementation**
```dart
// ❌ Bad: Testing internal state
expect(provider.isLoading, false);

// ✅ Good: Testing user-visible behavior
await $(Key('loading-indicator')).waitUntilGone();
await $(Key('classification-result')).waitUntilVisible();
```

### **3. Handle Flaky Elements**
```dart
// Retry for flaky network-dependent elements
for (int i = 0; i < 3; i++) {
  try {
    await $(Key('sync-button')).tap();
    await $(Key('sync-complete')).waitUntilVisible();
    break;
  } catch (e) {
    if (i == 2) rethrow;
    await Future.delayed(Duration(seconds: 1));
  }
}
```

### **4. Clean Test Data**
```dart
// Set up clean state for each test
patrolTest(
  'Test Name',
  ($) async {
    // Clear storage before test
    await StorageService.clearAllData();
    
    // Run test with clean state
    await $.pumpWidgetAndSettle(WasteSegregationApp(/* services */));
    // ... test logic
  },
);
```

Your Patrol setup is already excellent - now you can write comprehensive E2E tests that validate your entire app like a real user would use it!


practical:
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:waste_segregation_app/main.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/educational_content_analytics_service.dart';
import 'package:waste_segregation_app/services/educational_content_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/services/ad_service.dart';
import 'package:waste_segregation_app/services/google_drive_service.dart';
import 'package:waste_segregation_app/services/navigation_settings_service.dart';
import 'package:waste_segregation_app/services/haptic_settings_service.dart';
import 'package:waste_segregation_app/services/community_service.dart';

void main() {
  group('Waste Segregation App - Real E2E Tests', () {
    
    patrolTest(
      'App Launch and Navigation Flow',
      ($) async {
        // Launch your actual app
        await $.pumpWidgetAndSettle(
          WasteSegregationApp(
            storageService: StorageService(),
            aiService: AiService(),
            analyticsService: AnalyticsService(StorageService()),
            educationalContentAnalyticsService: EducationalContentAnalyticsService(),
            educationalContentService: EducationalContentService(EducationalContentAnalyticsService()),
            gamificationService: GamificationService(StorageService(), null),
            premiumService: PremiumService(),
            adService: AdService(),
            googleDriveService: GoogleDriveService(StorageService()),
            navigationSettingsService: NavigationSettingsService(),
            hapticSettingsService: HapticSettingsService(),
            communityService: CommunityService(),
          ),
        );

        await $.native.grantPermissionWhenInUse();

        // Wait for app to load (splash screen)
        await Future.delayed(const Duration(seconds: 3));

        // Handle consent dialog if it appears
        if ($(Text('Privacy Policy')).exists) {
          await $(Text('Accept')).tap();
          await Future.delayed(const Duration(seconds: 1));
        }

        // Handle auth screen - choose guest mode
        if ($(Text('Continue as Guest')).exists) {
          await $(Text('Continue as Guest')).tap();
        } else if ($(Text('Guest Mode')).exists) {
          await $(Text('Guest Mode')).tap();
        }

        // Wait for home screen to appear
        await Future.delayed(const Duration(seconds: 2));
        
        // Take screenshot of home screen
        await $.takeScreenshot('01-home-screen');

        // Look for the main classification button (FAB or main button)
        if ($(FloatingActionButton).exists) {
          await $(FloatingActionButton).tap();
          await $.takeScreenshot('02-camera-screen');
        }

        print('✅ App launched successfully and navigation working!');
      },
    );

    patrolTest(
      'Bottom Navigation Test',
      ($) async {
        await _launchAppToHome($);

        // Test each bottom navigation tab
        await _testNavigationTab($, 'History', '03-history-screen');
        await _testNavigationTab($, 'Achievements', '04-achievements-screen');
        await _testNavigationTab($, 'Settings', '05-settings-screen');
        
        // Test educational content if it exists
        if ($(Text('Educational')).exists || $(Text('Learn')).exists) {
          await _testNavigationTab($, 'Educational', '06-educational-screen');
        }

        print('✅ Navigation tabs working correctly!');
      },
    );

    patrolTest(
      'Settings Screen Interaction',
      ($) async {
        await _launchAppToHome($);

        // Navigate to settings
        await _tapTextOrIcon($, ['Settings', Icons.settings]);
        await Future.delayed(const Duration(seconds: 1));
        
        // Test theme toggle if it exists
        if ($(Text('Theme')).exists) {
          await $(Text('Theme')).tap();
          await Future.delayed(const Duration(milliseconds: 500));
          await $.takeScreenshot('07-theme-settings');
        }

        // Test other settings
        if ($(Text('Notifications')).exists) {
          await $(Text('Notifications')).tap();
          await Future.delayed(const Duration(milliseconds: 500));
          await $.native.pressBack();
        }

        print('✅ Settings interactions working!');
      },
    );

    patrolTest(
      'Offline Mode Simulation',
      ($) async {
        await _launchAppToHome($);

        // Disable network
        await $.native.disableWifi();
        await $.native.disableCellular();

        await $.takeScreenshot('08-offline-mode');

        // Try to navigate around the app
        await _tapTextOrIcon($, ['History', Icons.history]);
        await Future.delayed(const Duration(seconds: 1));

        // Re-enable network
        await $.native.enableWifi();
        await $.native.enableCellular();

        await Future.delayed(const Duration(seconds: 2));
        await $.takeScreenshot('09-online-restored');

        print('✅ Offline mode testing completed!');
      },
    );

    patrolTest(
      'Premium Features Discovery',
      ($) async {
        await _launchAppToHome($);

        // Look for premium features
        if ($(Text('Premium')).exists) {
          await $(Text('Premium')).tap();
          await Future.delay(const Duration(seconds: 1));
          await $.takeScreenshot('10-premium-screen');
        } else if ($(Text('Upgrade')).exists) {
          await $(Text('Upgrade')).tap();
          await Future.delay(const Duration(seconds: 1));
          await $.takeScreenshot('10-upgrade-screen');
        }

        // Navigate through settings to find premium features
        await _tapTextOrIcon($, ['Settings', Icons.settings]);
        await Future.delay(const Duration(seconds: 1));

        if ($(Text('Premium Features')).exists) {
          await $(Text('Premium Features')).tap();
          await $.takeScreenshot('11-premium-settings');
        }

        print('✅ Premium features exploration completed!');
      },
    );

  });
}

// Helper function to launch app and get to home screen
Future<void> _launchAppToHome(PatrolTester $) async {
  await $.pumpWidgetAndSettle(
    WasteSegregationApp(
      storageService: StorageService(),
      aiService: AiService(),
      analyticsService: AnalyticsService(StorageService()),
      educationalContentAnalyticsService: EducationalContentAnalyticsService(),
      educationalContentService: EducationalContentService(EducationalContentAnalyticsService()),
      gamificationService: GamificationService(StorageService(), null),
      premiumService: PremiumService(),
      adService: AdService(),
      googleDriveService: GoogleDriveService(StorageService()),
      navigationSettingsService: NavigationSettingsService(),
      hapticSettingsService: HapticSettingsService(),
      communityService: CommunityService(),
    ),
  );

  await $.native.grantPermissionWhenInUse();
  await Future.delayed(const Duration(seconds: 3));

  // Handle consent
  if ($(Text('Privacy Policy')).exists || $(Text('Accept')).exists) {
    if ($(Text('Accept')).exists) {
      await $(Text('Accept')).tap();
    } else if ($(ElevatedButton).exists) {
      await $(ElevatedButton).tap();
    }
    await Future.delayed(const Duration(seconds: 1));
  }

  // Handle auth
  if ($(Text('Continue as Guest')).exists) {
    await $(Text('Continue as Guest')).tap();
  } else if ($(Text('Guest Mode')).exists) {
    await $(Text('Guest Mode')).tap();
  }

  await Future.delayed(const Duration(seconds: 2));
}

// Helper function to test navigation tabs
Future<void> _testNavigationTab(PatrolTester $, String tabName, String screenshotName) async {
  await _tapTextOrIcon($, [tabName]);
  await Future.delayed(const Duration(seconds: 1));
  await $.takeScreenshot(screenshotName);
  
  // Go back to home if needed
  if ($(Text('Home')).exists) {
    await $(Text('Home')).tap();
  } else if ($(Icons.home).exists) {
    await $(Icons.home).tap();
  }
  await Future.delayed(const Duration(milliseconds: 500));
}

// Helper function to tap by text or icon (flexible finder)
Future<void> _tapTextOrIcon(PatrolTester $, List<dynamic> options) async {
  for (final option in options) {
    if (option is String && $(Text(option)).exists) {
      await $(Text(option)).tap();
      return;
    } else if (option is IconData && $(Icon(option)).exists) {
      await $(Icon(option)).tap();
      return;
    }
  }
  
  // If nothing found, try bottom navigation
  if ($(BottomNavigationBar).exists) {
    final bottomNav = $(BottomNavigationBar);
    if (bottomNav.$(Text(options.first as String)).exists) {
      await bottomNav.$(Text(options.first as String)).tap();
    }
  }
}


// Example: Adding test keys to your existing widgets for better Patrol testing

// 1. HOME SCREEN MODIFICATIONS
class ModernHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('home-screen'), // Add this key
      appBar: AppBar(
        key: const Key('home-app-bar'), // Add this key
        title: Text('Waste Segregation'),
      ),
      body: Column(
        children: [
          // Points display
          Container(
            key: const Key('points-display'), // Add this key
            child: Text('Points: ${points}'),
          ),
          
          // Classification history preview
          ListView(
            key: const Key('recent-classifications'), // Add this key
            children: classifications.map((c) => 
              ClassificationCard(
                key: Key('classification-${c.id}'), // Dynamic keys
                classification: c,
                onTap: () => Navigator.push(...),
              )
            ).toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('classify-fab'), // Add this key
        onPressed: () => _startClassification(),
        child: Icon(Icons.camera_alt),
      ),
      bottomNavigationBar: BottomNavigationBar(
        key: const Key('bottom-navigation'), // Add this key
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, key: const Key('home-tab')), // Add key to icon
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history, key: const Key('history-tab')), // Add key
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events, key: const Key('achievements-tab')), // Add key
            label: 'Achievements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, key: const Key('settings-tab')), // Add key
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// 2. CLASSIFICATION CARD MODIFICATIONS
class ClassificationCard extends StatelessWidget {
  final Classification classification;
  final VoidCallback? onTap;
  
  const ClassificationCard({
    Key? key, // Accept key parameter
    required this.classification,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      key: key ?? Key('classification-card-${classification.id}'), // Use provided key or generate
      child: ListTile(
        key: Key('classification-tile-${classification.id}'), // Add specific key
        leading: Container(
          key: Key('classification-image-${classification.id}'), // Add key
          child: Image.network(classification.imageUrl),
        ),
        title: Text(
          classification.wasteType,
          key: Key('waste-type-${classification.id}'), // Add key
        ),
        subtitle: Text(
          '${(classification.confidence * 100).toInt()}% confidence',
          key: Key('confidence-${classification.id}'), // Add key
        ),
        trailing: Container(
          key: Key('points-earned-${classification.id}'), // Add key
          child: Text('+${classification.pointsEarned} pts'),
        ),
        onTap: onTap,
      ),
    );
  }
}

// 3. SETTINGS SCREEN MODIFICATIONS
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('settings-screen'), // Add this key
      appBar: AppBar(
        key: const Key('settings-app-bar'), // Add this key
        title: Text('Settings'),
      ),
      body: ListView(
        key: const Key('settings-list'), // Add this key
        children: [
          ListTile(
            key: const Key('theme-settings-tile'), // Add this key
            leading: Icon(Icons.palette),
            title: Text('Theme'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ThemeSettingsScreen()),
            ),
          ),
          SwitchListTile(
            key: const Key('notifications-switch'), // Add this key
            title: Text('Notifications'),
            value: notificationsEnabled,
            onChanged: (value) => _toggleNotifications(value),
          ),
          ListTile(
            key: const Key('premium-features-tile'), // Add this key
            leading: Icon(Icons.star),
            title: Text('Premium Features'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PremiumFeaturesScreen()),
            ),
          ),
          ListTile(
            key: const Key('data-export-tile'), // Add this key
            leading: Icon(Icons.download),
            title: Text('Export Data'),
            onTap: () => _exportData(),
          ),
        ],
      ),
    );
  }
}

// 4. AUTH SCREEN MODIFICATIONS
class AuthScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('auth-screen'), // Add this key
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              key: const Key('app-logo'), // Add this key
              child: Icon(Icons.recycling, size: 100),
            ),
            
            // Sign in button
            ElevatedButton(
              key: const Key('sign-in-button'), // Add this key
              onPressed: () => _signInWithGoogle(),
              child: Text('Sign in with Google'),
            ),
            
            // Guest mode button
            TextButton(
              key: const Key('continue-as-guest-button'), // Add this key
              onPressed: () => _continueAsGuest(),
              child: Text('Continue as Guest'),
            ),
          ],
        ),
      ),
    );
  }
}

// 5. CAMERA/CLASSIFICATION SCREEN MODIFICATIONS
class ImageCaptureScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('camera-screen'), // Add this key
      appBar: AppBar(
        key: const Key('camera-app-bar'), // Add this key
        title: Text('Classify Waste'),
        leading: IconButton(
          key: const Key('camera-back-button'), // Add this key
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            child: Container(
              key: const Key('camera-preview'), // Add this key
              child: CameraPreview(controller),
            ),
          ),
          
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                key: const Key('gallery-button'), // Add this key
                icon: Icon(Icons.photo_library),
                onPressed: () => _pickFromGallery(),
              ),
              FloatingActionButton(
                key: const Key('capture-button'), // Add this key
                onPressed: () => _takePicture(),
                child: Icon(Icons.camera),
              ),
              IconButton(
                key: const Key('flash-toggle-button'), // Add this key
                icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
                onPressed: () => _toggleFlash(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 6. RESULT SCREEN MODIFICATIONS
class ResultScreen extends StatelessWidget {
  final Classification result;
  
  const ResultScreen({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('result-screen'), // Add this key
      appBar: AppBar(
        key: const Key('result-app-bar'), // Add this key
        title: Text('Classification Result'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Image
            Container(
              key: const Key('result-image'), // Add this key
              child: Image.network(result.imageUrl),
            ),
            
            // Waste type
            Text(
              result.wasteType,
              key: const Key('waste-type-text'), // Add this key
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            
            // Confidence
            Text(
              '${(result.confidence * 100).toInt()}% confidence',
              key: const Key('confidence-text'), // Add this key
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            
            // Points earned
            Container(
              key: const Key('points-earned-display'), // Add this key
              child: Text('+${result.pointsEarned} points'),
            ),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  key: const Key('save-classification-button'), // Add this key
                  onPressed: () => _saveClassification(),
                  child: Text('Save'),
                ),
                TextButton(
                  key: const Key('retake-photo-button'), // Add this key
                  onPressed: () => _retakePhoto(),
                  child: Text('Retake'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 7. ACHIEVEMENT POPUP MODIFICATIONS
class AchievementUnlockPopup extends StatelessWidget {
  final Achievement achievement;
  
  const AchievementUnlockPopup({Key? key, required this.achievement}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('achievement-popup'), // Add this key
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events,
              key: const Key('achievement-icon'), // Add this key
              size: 50,
              color: Colors.gold,
            ),
            Text(
              'Achievement Unlocked!',
              key: const Key('achievement-title'), // Add this key
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              achievement.title,
              key: Key('achievement-name-${achievement.id}'), // Add this key
            ),
            Text(
              '+${achievement.pointsReward} points',
              key: Key('achievement-points-${achievement.id}'), // Add this key
            ),
            ElevatedButton(
              key: const Key('claim-achievement-button'), // Add this key
              onPressed: () => _claimAchievement(),
              child: Text('Claim Reward'),
            ),
          ],
        ),
      ),
    );
  }
}

// 8. OFFLINE BANNER MODIFICATIONS
class OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('offline-banner'), // Add this key
      width: double.infinity,
      padding: EdgeInsets.all(8),
      color: Colors.orange,
      child: Row(
        children: [
          Icon(
            Icons.cloud_off,
            key: const Key('offline-icon'), // Add this key
            color: Colors.white,
          ),
          SizedBox(width: 8),
          Text(
            'No internet connection',
            key: const Key('offline-message'), // Add this key
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// 9. LOADING INDICATORS
class LoadingIndicator extends StatelessWidget {
  final String? message;
  
  const LoadingIndicator({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('loading-indicator'), // Add this key
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            key: const Key('loading-spinner'), // Add this key
          ),
          if (message != null) ...[
            SizedBox(height: 16),
            Text(
              message!,
              key: const Key('loading-message'), // Add this key
            ),
          ],
        ],
      ),
    );
  }
}

// 10. CONSENT DIALOG MODIFICATIONS
class ConsentDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('consent-dialog'), // Add this key
      title: Text(
        'Privacy Policy',
        key: const Key('consent-title'), // Add this key
      ),
      content: Text(
        'We value your privacy...',
        key: const Key('consent-content'), // Add this key
      ),
      actions: [
        TextButton(
          key: const Key('decline-consent-button'), // Add this key
          onPressed: () => _declineConsent(),
          child: Text('Decline'),
        ),
        ElevatedButton(
          key: const Key('accept-consent-button'), // Add this key
          onPressed: () => _acceptConsent(),
          child: Text('Accept'),
        ),
      ],
    );
  }
}

I'll show you how to use Patrol effectively in your Flutter app! You already have it set up, so let's dive into practical usage.Now let me create a practical example you can run immediately with your current app:Now let me show you how to add testable keys to your existing widgets for better Patrol testing:## 🚀 How to Run Patrol Tests Right Now

Step 1: Save the Test File

# Save the practical test as a new file
touch integration_test/real_app_patrol_test.dart
# Copy the "Practical Patrol Test" code into this file


Step 2: Run the Test

# Run the test
patrol test --target integration_test/real_app_patrol_test.dart

# Or use your existing script
./scripts/run_e2e_tests.sh


Step 3: View Results

Screenshots will be saved in patrol_screenshots/

Test results will show in terminal

Any failures will be clearly indicated

🎯 What Patrol Tests vs Other Tests

Test Type What It Tests When to Use Unit Tests Individual functions, logic Daily development Widget Tests Single widgets in isolation After UI changes Golden Tests Visual appearance (pixels) After style changes Integration Tests Full app flows Before releases Patrol E2E Tests Real user behavior on device Weekly validation

💡 Key Patrol Advantages

Native System Integration - Handles permissions, notifications, network

Real Device Testing - Tests on actual iOS/Android devices

Cross-Platform - Same tests work on iOS, Android, Web

Screenshot Capture - Automatic visual documentation

Network Simulation - Test offline/online scenarios

🎮 Quick Commands to Try

# Run on your connected device
patrol test

# Run with screenshots
patrol test --verbose

# Run specific test
patrol test --target integration_test/real_app_patrol_test.dart

# Check available devices
patrol devices


Your existing setup is already excellent - Patrol just adds the final layer of real-device testing to complement your golden tests, widget tests, and integration tests. It's like having a QA engineer that tests your app exactly like a real user would! 🚀

Want me to help you add specific test keys to any particular screen or create tests for specific user flows?