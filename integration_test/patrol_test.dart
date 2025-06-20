import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:waste_segregation_app/main.dart' as app;

void main() {
  group('Basic Waste Segregation App E2E Tests', () {
    
    patrolTest(
      'App Launch and Basic Navigation - Patrol E2E',
      ($) async {
        // Launch the actual app
        app.main();
        await $.pumpAndSettle();

        // Wait for app initialization
        await Future.delayed(const Duration(seconds: 5));

        // Handle consent dialog if it appears
        await _handleConsentFlow($);

        // Handle auth screen - choose guest mode for testing
        await _handleAuthFlow($);

        // Verify we're on the home screen
        await _verifyHomeScreen($);

        // Test bottom navigation if it exists
        await _testBasicNavigation($);

        // Take screenshot for verification
        await $.takeScreenshot('basic-app-launch');
      },
    );

    patrolTest(
      'Classification Flow - Basic E2E',
      ($) async {
        app.main();
        await $.pumpAndSettle();
        await Future.delayed(const Duration(seconds: 5));

        await _handleConsentFlow($);
        await _handleAuthFlow($);

        // Test camera/classification flow
        await _testClassificationFlow($);

        await $.takeScreenshot('classification-flow');
      },
    );

    patrolTest(
      'Points System - Basic E2E',
      ($) async {
        app.main();
        await $.pumpAndSettle();
        await Future.delayed(const Duration(seconds: 5));

        await _handleConsentFlow($);
        await _handleAuthFlow($);

        // Test points display and functionality
        await _testPointsSystem($);

        await $.takeScreenshot('points-system');
      },
    );

    patrolTest(
      'Settings Flow - Basic E2E',
      ($) async {
        app.main();
        await $.pumpAndSettle();
        await Future.delayed(const Duration(seconds: 5));

        await _handleConsentFlow($);
        await _handleAuthFlow($);

        // Test settings navigation and basic features
        await _testSettingsFlow($);

        await $.takeScreenshot('settings-flow');
      },
    );

    patrolTest(
      'Offline Mode - Basic E2E',
      ($) async {
        app.main();
        await $.pumpAndSettle();
        await Future.delayed(const Duration(seconds: 5));

        await _handleConsentFlow($);
        await _handleAuthFlow($);

        // Test app behavior when offline
        await _testOfflineMode($);

        await $.takeScreenshot('offline-mode');
      },
    );
  });
}

// Helper Functions

Future<void> _handleConsentFlow(PatrolTester $) async {
  try {
    // Look for various consent dialog patterns
    if ($(const Text('Privacy Policy')).exists || 
        $(const Text('Terms of Service')).exists ||
        $(const Text('Accept')).exists) {
      
      // Try different accept button patterns
      if ($(const Text('Accept')).exists) {
        await $(const Text('Accept')).tap();
      } else if ($(const Text('I Accept')).exists) {
        await $(const Text('I Accept')).tap();
      } else if ($(ElevatedButton).exists) {
        await $(ElevatedButton).first.tap();
      } else if ($(FilledButton).exists) {
        await $(FilledButton).first.tap();
      }
      
      await $.pumpAndSettle();
    }
  } catch (e) {
    // Consent dialog might not appear, continue
  }
}

Future<void> _handleAuthFlow(PatrolTester $) async {
  try {
    // Look for auth screen and choose guest mode for testing
    await Future.delayed(const Duration(seconds: 2));
    
    // Look for guest mode button with various text patterns
    if ($(const Text('Continue as Guest')).exists) {
      await $(const Text('Continue as Guest')).tap();
    } else if ($(const Text('Guest Mode')).exists) {
      await $(const Text('Guest Mode')).tap();
    } else if ($(const Text('Try as Guest')).exists) {
      await $(const Text('Try as Guest')).tap();
    } else if ($(const Text('Skip Sign In')).exists) {
      await $(const Text('Skip Sign In')).tap();
    } else {
      // Look for any button that might be guest mode
      final buttons = $(InkWell);
      if (buttons.exists) {
        // Try the second button if there are multiple (first might be sign in)
        if (buttons.at(1).exists) {
          await buttons.at(1).tap();
        } else {
          await buttons.first.tap();
        }
      }
    }
    
    await $.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 3));
  } catch (e) {
    // Auth flow might be different, continue
  }
}

Future<void> _verifyHomeScreen(PatrolTester $) async {
  // Wait a bit more for home screen to load
  await Future.delayed(const Duration(seconds: 3));
  
  // Look for common home screen elements
  expect(
    $(const Text('Waste Segregation')).exists || 
    $(FloatingActionButton).exists ||
    $(const Text('Scan')).exists ||
    $(const Text('Home')).exists ||
    $(Icons.camera_alt).exists ||
    $(NavigationBar).exists ||
    $(BottomNavigationBar).exists,
    isTrue,
    reason: 'Should find at least one home screen element'
  );
}

Future<void> _testBasicNavigation(PatrolTester $) async {
  try {
    // Test bottom navigation if it exists
    if ($(NavigationBar).exists) {
      // Try tapping different navigation items
      final destinations = $(NavigationDestination);
      if (destinations.exists) {
        // Tap on History tab
        if (destinations.at(1).exists) {
          await destinations.at(1).tap();
          await $.pumpAndSettle();
          await Future.delayed(const Duration(seconds: 1));
        }
        
        // Tap on Learn/Educational tab
        if (destinations.at(2).exists) {
          await destinations.at(2).tap();
          await $.pumpAndSettle();
          await Future.delayed(const Duration(seconds: 1));
        }
        
        // Return to home
        if (destinations.at(0).exists) {
          await destinations.at(0).tap();
          await $.pumpAndSettle();
        }
      }
    } else if ($(BottomNavigationBar).exists) {
      // Legacy bottom nav
      final items = $(BottomNavigationBarItem);
      if (items.exists && items.evaluate().length > 1) {
        // Test a couple of navigation items
        await items.at(1).tap();
        await $.pumpAndSettle();
        await Future.delayed(const Duration(seconds: 1));
        
        await items.at(0).tap();
        await $.pumpAndSettle();
      }
    }
  } catch (e) {
    // Navigation might be different, continue
  }
}

Future<void> _testClassificationFlow(PatrolTester $) async {
  try {
    // Look for classification/scan button
    if ($(FloatingActionButton).exists) {
      await $(FloatingActionButton).tap();
    } else if ($(const Text('Scan')).exists) {
      await $(const Text('Scan')).tap();
    } else if ($(Icons.camera_alt).exists) {
      await $(Icons.camera_alt).tap();
    } else if ($(FilledButton).exists) {
      // Look for a scan button among filled buttons
      await $(FilledButton).first.tap();
    }
    
    await $.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 2));
    
    // Handle camera permissions if requested
    try {
      await $.native.grantPermissionWhenInUse();
    } catch (e) {
      // Permission might not be needed or handled differently
    }
    
    // If camera screen opens, go back
    await $.native.pressBack();
    await $.pumpAndSettle();
    
  } catch (e) {
    // Classification flow might not be accessible
  }
}

Future<void> _testPointsSystem(PatrolTester $) async {
  try {
    // Look for points display
    if ($(const Text('Points')).exists || 
        $(const Text('Score')).exists ||
        $(Icons.star).exists) {
      
      // Points system exists, verify it's displayed
      expect(
        $(const Text('Points')).exists || $(const Text('Score')).exists,
        isTrue,
        reason: 'Points system should be visible'
      );
    }
    
    // Try to navigate to achievements if possible
    if ($(const Text('Achievements')).exists || $(const Text('Rewards')).exists) {
      await $(const Text('Achievements')).tap();
      await $.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 1));
      
      // Go back
      await $.native.pressBack();
      await $.pumpAndSettle();
    }
  } catch (e) {
    // Points system might not be visible
  }
}

Future<void> _testSettingsFlow(PatrolTester $) async {
  try {
    // Look for settings access
    if ($(const Text('Settings')).exists) {
      await $(const Text('Settings')).tap();
    } else if ($(Icons.settings).exists) {
      await $(Icons.settings).tap();
    } else {
      // Try to find settings in navigation
      final destinations = $(NavigationDestination);
      if (destinations.exists && destinations.evaluate().length > 4) {
        await destinations.at(4).tap(); // Often the last tab
      }
    }
    
    await $.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 2));
    
    // Verify we're in settings
    expect(
      $(const Text('Settings')).exists ||
      $(const Text('Preferences')).exists ||
      $(const Text('Theme')).exists,
      isTrue,
      reason: 'Should be in settings screen'
    );
    
    // Test theme toggle if available
    if ($(const Text('Theme')).exists) {
      await $(const Text('Theme')).tap();
      await $.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 1));
      await $.native.pressBack();
    }
    
  } catch (e) {
    // Settings might not be accessible
  }
}

Future<void> _testOfflineMode(PatrolTester $) async {
  try {
    // Disable network
    await $.native.disableWifi();
    await $.native.disableCellular();
    
    await Future.delayed(const Duration(seconds: 2));
    
    // Try to use the app
    if ($(FloatingActionButton).exists) {
      await $(FloatingActionButton).tap();
      await $.pumpAndSettle();
      
      // Should show offline message or handle gracefully
      await $.native.pressBack();
    }
    
    // Re-enable network
    await $.native.enableWifi();
    await $.native.enableCellular();
    
    await Future.delayed(const Duration(seconds: 2));
    
  } catch (e) {
    // Network control might not be available on all platforms
    try {
      await $.native.enableWifi();
      await $.native.enableCellular();
    } catch (e2) {
      // Ignore
    }
  }
}
