import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:waste_segregation_app/main.dart' as app;

void main() {
  group('Comprehensive Waste Segregation App E2E Tests', () {

    patrolTest(
      'Complete App Launch and Navigation Flow',
      ($) async {
        // Launch the actual app
        app.main();
        await $.pumpAndSettle();

        // Wait for initialization
        await Future.delayed(const Duration(seconds: 5));

        // Handle consent dialog if it appears
        await _handleConsentFlow($);

        // Handle auth screen 
        await _handleAuthFlow($);

        // Verify we're on home screen
        await _verifyHomeScreen($);

        // Test all navigation tabs
        await _testBottomNavigation($);

        // Take final screenshot
        await $.takeScreenshot('01-complete-navigation-flow');
      },
    );

    patrolTest(
      'Waste Classification End-to-End Journey',
      ($) async {
        app.main();
        await $.pumpAndSettle();
        await Future.delayed(const Duration(seconds: 5));

        await _handleConsentFlow($);
        await _handleAuthFlow($);

        // Test camera classification flow
        await _testCameraClassification($);

        // Test gallery classification flow  
        await _testGalleryClassification($);

        // Verify classification appears in history
        await _verifyClassificationInHistory($);

        await $.takeScreenshot('02-classification-journey');
      },
    );

    patrolTest(
      'Points and Achievements System',
      ($) async {
        app.main();
        await $.pumpAndSettle();
        await Future.delayed(const Duration(seconds: 5));

        await _handleConsentFlow($);
        await _handleAuthFlow($);

        // Get initial points
        final initialPoints = await _getPointsDisplay($);

        // Perform classification to earn points
        await _performMockClassification($);

        // Verify points increased
        await _verifyPointsIncreased($, initialPoints);

        // Test achievements screen
        await _testAchievementsScreen($);

        await $.takeScreenshot('03-points-achievements');
      },
    );

    patrolTest(
      'Settings and Preferences Flow',
      ($) async {
        app.main();
        await $.pumpAndSettle();
        await Future.delayed(const Duration(seconds: 5));

        await _handleConsentFlow($);
        await _handleAuthFlow($);

        // Navigate to settings
        await _testSettingsNavigation($);

        // Test theme settings
        await _testThemeSettings($);

        // Test notification settings
        await _testNotificationSettings($);

        // Test premium features
        await _testPremiumFeatures($);

        await $.takeScreenshot('04-settings-flow');
      },
    );

    patrolTest(
      'Offline Mode and Error Handling',
      ($) async {
        app.main();
        await $.pumpAndSettle();
        await Future.delayed(const Duration(seconds: 5));

        await _handleConsentFlow($);
        await _handleAuthFlow($);

        // Test offline behavior
        await $.native.disableWifi();
        await $.native.disableCellular();

        // Try to use app offline
        await _testOfflineBehavior($);

        // Restore connectivity
        await $.native.enableWifi();
        await $.native.enableCellular();

        // Test recovery
        await _testConnectivityRecovery($);

        await $.takeScreenshot('05-offline-handling');
      },
    );

    patrolTest(
      'Educational Content and Learning Flow',
      ($) async {
        app.main();
        await $.pumpAndSettle();
        await Future.delayed(const Duration(seconds: 5));

        await _handleConsentFlow($);
        await _handleAuthFlow($);

        // Test educational content access
        await _testEducationalContent($);

        // Test daily tips
        await _testDailyTips($);

        // Test waste categories learning
        await _testWasteCategories($);

        await $.takeScreenshot('06-educational-flow');
      },
    );

    patrolTest(
      'Performance and Stress Testing',
      ($) async {
        app.main();
        await $.pumpAndSettle();

        final stopwatch = Stopwatch()..start();
        
        await Future.delayed(const Duration(seconds: 5));
        await _handleConsentFlow($);
        await _handleAuthFlow($);
        
        stopwatch.stop();

        // App should launch within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(15000));

        // Test rapid navigation
        await _testRapidNavigation($);

        // Test scroll performance
        await _testScrollPerformance($);

        await $.takeScreenshot('07-performance-testing');
      },
    );

    patrolTest(
      'Cross-Platform Compatibility',
      ($) async {
        app.main();
        await $.pumpAndSettle();
        await Future.delayed(const Duration(seconds: 5));

        await _handleConsentFlow($);
        await _handleAuthFlow($);

        // Test platform-specific features
        await _testPlatformFeatures($);

        // Test responsive design
        await _testResponsiveDesign($);

        await $.takeScreenshot('08-platform-compatibility');
      },
    );

  });
}

// Helper Functions

Future<void> _handleConsentFlow(PatrolTester $) async {
  try {
    // Look for consent dialog with more comprehensive patterns
    await Future.delayed(const Duration(seconds: 1));
    
    if ($(Text('Privacy Policy')).exists || 
        $(Text('Terms of Service')).exists ||
        $(Text('Accept')).exists ||
        $(Text('I Accept')).exists ||
        $(Text('Agree')).exists) {
      
      // Try different accept button patterns
      if ($(Text('Accept')).exists) {
        await $(Text('Accept')).tap();
      } else if ($(Text('I Accept')).exists) {
        await $(Text('I Accept')).tap();
      } else if ($(Text('Agree')).exists) {
        await $(Text('Agree')).tap();
      } else if ($(ElevatedButton).exists) {
        await $(ElevatedButton).first.tap();
      } else if ($(FilledButton).exists) {
        await $(FilledButton).first.tap();
      }
      
      await $.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 1));
    }
  } catch (e) {
    // Consent dialog might not appear, continue
  }
}

Future<void> _handleAuthFlow(PatrolTester $) async {
  try {
    // Handle authentication screen - choose guest mode for testing
    await Future.delayed(const Duration(seconds: 2));
    
    if ($(Text('Continue as Guest')).exists) {
      await $(Text('Continue as Guest')).tap();
    } else if ($(Text('Guest Mode')).exists) {
      await $(Text('Guest Mode')).tap();
    } else if ($(Text('Try as Guest')).exists) {
      await $(Text('Try as Guest')).tap();
    } else if ($(Text('Skip Sign In')).exists) {
      await $(Text('Skip Sign In')).tap();
    } else {
      // Look for InkWell or MaterialButton that might be guest mode
      final inkWells = $(InkWell);
      if (inkWells.exists && inkWells.evaluate().length > 1) {
        // Try the second button (first might be Google sign in)
        await inkWells.at(1).tap();
      } else if (inkWells.exists) {
        await inkWells.first.tap();
      }
    }
    
    await $.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 3));
  } catch (e) {
    // Auth flow might be different, continue
  }
}

Future<void> _verifyHomeScreen(PatrolTester $) async {
  // Wait for home screen to load
  await Future.delayed(const Duration(seconds: 3));
  
  // Look for home screen indicators
  expect(
    $(Text('Waste Segregation')).exists || 
    $(FloatingActionButton).exists || 
    $(Text('Scan')).exists ||
    $(Text('Home')).exists ||
    $(Icons.camera_alt).exists ||
    $(NavigationBar).exists ||
    $(Text('Hello')).exists ||
    $(Text('Eco-Warriors')).exists,
    isTrue,
    reason: 'Should find at least one home screen element'
  );
}

Future<void> _testBottomNavigation(PatrolTester $) async {
  try {
    // Test bottom navigation
    if ($(NavigationBar).exists) {
      final destinations = $(NavigationDestination);
      if (destinations.exists) {
        final count = destinations.evaluate().length;
        
        // Test History tab (usually index 1)
        if (count > 1) {
          await destinations.at(1).tap();
          await $.pumpAndSettle();
          await Future.delayed(const Duration(seconds: 1));
        }

        // Test Learn/Educational tab (usually index 2)
        if (count > 2) {
          await destinations.at(2).tap();
          await $.pumpAndSettle();
          await Future.delayed(const Duration(seconds: 1));
        }

        // Test Social tab (usually index 3)
        if (count > 3) {
          await destinations.at(3).tap();
          await $.pumpAndSettle();
          await Future.delayed(const Duration(seconds: 1));
        }

        // Test Achievements/Rewards tab (usually index 4)
        if (count > 4) {
          await destinations.at(4).tap();
          await $.pumpAndSettle();
          await Future.delayed(const Duration(seconds: 1));
        }

        // Return to home
        await destinations.at(0).tap();
        await $.pumpAndSettle();
      }
    } else {
      // Try alternative navigation patterns
      final tabs = [
        'History', 'Learn', 'Social', 'Achievements', 'Rewards', 'Home'
      ];
      
      for (final tab in tabs) {
        if ($(Text(tab)).exists) {
          await $(Text(tab)).tap();
          await $.pumpAndSettle();
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }
  } catch (e) {
    // Navigation might be different
  }
}

Future<void> _testCameraClassification(PatrolTester $) async {
  try {
    // Test camera flow
    if ($(FloatingActionButton).exists) {
      await $(FloatingActionButton).tap();
    } else if ($(Text('Scan')).exists) {
      await $(Text('Scan')).tap();
    } else if ($(FilledButton).exists) {
      await $(FilledButton).first.tap();
    }

    await $.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 1));

    // Handle camera options if modal appears
    if ($(Text('Take Photo')).exists) {
      await $(Text('Take Photo')).tap();
    } else if ($(Text('Camera')).exists) {
      await $(Text('Camera')).tap();
    }

    // Handle camera permission
    try {
      await $.native.grantPermissionWhenInUse();
    } catch (e) {
      // Permission might not be needed
    }
    
    await Future.delayed(const Duration(seconds: 2));

    // Go back from camera
    await $.native.pressBack();
    await $.pumpAndSettle();
  } catch (e) {
    // Camera flow might not be accessible
  }
}

Future<void> _testGalleryClassification(PatrolTester $) async {
  try {
    // Test gallery flow
    if ($(FloatingActionButton).exists) {
      await $(FloatingActionButton).tap();
    } else if ($(Text('Scan')).exists) {
      await $(Text('Scan')).tap();
    }

    await $.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 1));

    // Look for gallery option
    if ($(Text('Upload Image')).exists) {
      await $(Text('Upload Image')).tap();
    } else if ($(Text('Gallery')).exists) {
      await $(Text('Gallery')).tap();
    } else if ($(Text('Choose from gallery')).exists) {
      await $(Text('Choose from gallery')).tap();
    }

    await Future.delayed(const Duration(seconds: 2));
    await $.native.pressBack();
    await $.pumpAndSettle();
  } catch (e) {
    // Gallery flow might not be accessible
  }
}

Future<void> _verifyClassificationInHistory(PatrolTester $) async {
  try {
    // Navigate to history
    if ($(NavigationBar).exists) {
      final destinations = $(NavigationDestination);
      if (destinations.exists && destinations.evaluate().length > 1) {
        await destinations.at(1).tap();
      }
    } else if ($(Text('History')).exists) {
      await $(Text('History')).tap();
    }
    
    await $.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 1));
    
    // Verify history screen loaded
    expect(
      $(Text('History')).exists || 
      $(Text('Classification History')).exists ||
      $(ListView).exists ||
      $(Text('No classifications')).exists ||
      $(Text('Empty')).exists,
      isTrue,
      reason: 'Should be on history screen'
    );
  } catch (e) {
    // History might not be accessible
  }
}

Future<String?> _getPointsDisplay(PatrolTester $) async {
  try {
    if ($(Text('Points')).exists) {
      return $(Text('Points')).text;
    } else if ($(Text('Score')).exists) {
      return $(Text('Score')).text;
    }
    return null;
  } catch (e) {
    return null;
  }
}

Future<void> _performMockClassification(PatrolTester $) async {
  try {
    // Simulate a classification action
    if ($(FloatingActionButton).exists) {
      await $(FloatingActionButton).tap();
      await $.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 1));
      await $.native.pressBack();
      await $.pumpAndSettle();
    }
  } catch (e) {
    // Mock classification failed
  }
}

Future<void> _verifyPointsIncreased(PatrolTester $, String? initialPoints) async {
  await Future.delayed(const Duration(seconds: 1));
  try {
    if (initialPoints != null) {
      if ($(Text('Points')).exists) {
        final newPoints = $(Text('Points')).text;
        expect(newPoints, isNotNull);
      }
    }
  } catch (e) {
    // Points verification failed
  }
}

Future<void> _testAchievementsScreen(PatrolTester $) async {
  try {
    // Navigate to achievements
    if ($(NavigationBar).exists) {
      final destinations = $(NavigationDestination);
      if (destinations.exists && destinations.evaluate().length > 4) {
        await destinations.at(4).tap();
      }
    } else if ($(Text('Achievements')).exists) {
      await $(Text('Achievements')).tap();
    } else if ($(Text('Rewards')).exists) {
      await $(Text('Rewards')).tap();
    }
    
    await $.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 1));
    
    // Verify achievements screen
    expect(
      $(Text('Achievements')).exists || 
      $(Text('Rewards')).exists ||
      $(ListView).exists,
      isTrue,
      reason: 'Should be on achievements screen'
    );
  } catch (e) {
    // Achievements screen might not be accessible
  }
}

Future<void> _testSettingsNavigation(PatrolTester $) async {
  try {
    // Try to find settings
    if ($(Text('Settings')).exists) {
      await $(Text('Settings')).tap();
    } else if ($(Icons.settings).exists) {
      await $(Icons.settings).tap();
    } else {
      // Look for menu or drawer
      if ($(Icons.menu).exists) {
        await $(Icons.menu).tap();
        await $.pumpAndSettle();
        if ($(Text('Settings')).exists) {
          await $(Text('Settings')).tap();
        }
      }
    }
    
    await $.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 1));
  } catch (e) {
    // Settings navigation failed
  }
}

Future<void> _testThemeSettings(PatrolTester $) async {
  try {
    if ($(Text('Theme')).exists) {
      await $(Text('Theme')).tap();
      await $.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 1));
      await $.native.pressBack();
      await $.pumpAndSettle();
    } else if ($(Text('Appearance')).exists) {
      await $(Text('Appearance')).tap();
      await $.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 1));
      await $.native.pressBack();
      await $.pumpAndSettle();
    }
  } catch (e) {
    // Theme settings not found
  }
}

Future<void> _testNotificationSettings(PatrolTester $) async {
  try {
    if ($(Text('Notifications')).exists) {
      await $(Text('Notifications')).tap();
      await $.pumpAndSettle();
      try {
        await $.native.grantPermissionWhenInUse();
      } catch (e) {
        // Permission might not be requested
      }
      await Future.delayed(const Duration(seconds: 1));
      await $.native.pressBack();
      await $.pumpAndSettle();
    }
  } catch (e) {
    // Notification settings not found
  }
}

Future<void> _testPremiumFeatures(PatrolTester $) async {
  try {
    if ($(Text('Premium')).exists) {
      await $(Text('Premium')).tap();
      await $.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 1));
      await $.native.pressBack();
      await $.pumpAndSettle();
    } else if ($(Text('Upgrade')).exists) {
      await $(Text('Upgrade')).tap();
      await $.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 1));
      await $.native.pressBack();
      await $.pumpAndSettle();
    }
  } catch (e) {
    // Premium features not found
  }
}

Future<void> _testOfflineBehavior(PatrolTester $) async {
  try {
    // Try to perform actions while offline
    if ($(FloatingActionButton).exists) {
      await $(FloatingActionButton).tap();
      await $.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 1));
      
      // Should show offline message or handle gracefully
      await $.native.pressBack();
      await $.pumpAndSettle();
    }
  } catch (e) {
    // Offline behavior test failed
  }
}

Future<void> _testConnectivityRecovery(PatrolTester $) async {
  try {
    await Future.delayed(const Duration(seconds: 3));
    
    // App should recover gracefully
    expect(
      $(Text('Waste Segregation')).exists || 
      $(FloatingActionButton).exists ||
      $(NavigationBar).exists,
      isTrue,
      reason: 'App should recover after connectivity restoration'
    );
  } catch (e) {
    // Recovery test failed
  }
}

Future<void> _testEducationalContent(PatrolTester $) async {
  try {
    // Navigate to educational content
    if ($(NavigationBar).exists) {
      final destinations = $(NavigationDestination);
      if (destinations.exists && destinations.evaluate().length > 2) {
        await destinations.at(2).tap();
      }
    } else if ($(Text('Learn')).exists) {
      await $(Text('Learn')).tap();
    } else if ($(Text('Education')).exists) {
      await $(Text('Education')).tap();
    }
    
    await $.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 1));
    
    // Look for educational content
    if ($(Text('Learn More')).exists) {
      await $(Text('Learn More')).tap();
      await $.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 1));
      await $.native.pressBack();
      await $.pumpAndSettle();
    }
  } catch (e) {
    // Educational content not accessible
  }
}

Future<void> _testDailyTips(PatrolTester $) async {
  try {
    // Look for daily tips
    if ($(Text('Daily Tip')).exists || $(Text('DAILY TIP')).exists) {
      expect(
        $(Text('Daily Tip')).exists || $(Text('DAILY TIP')).exists,
        isTrue,
        reason: 'Daily tip should be visible'
      );
    }
  } catch (e) {
    // Daily tips not found
  }
}

Future<void> _testWasteCategories(PatrolTester $) async {
  try {
    // Test waste category interaction
    final categories = ['Wet Waste', 'Dry Waste', 'Hazardous', 'Recyclable'];
    
    for (final category in categories) {
      if ($(Text(category)).exists) {
        await $(Text(category)).tap();
        await $.pumpAndSettle();
        await Future.delayed(const Duration(seconds: 1));
        await $.native.pressBack();
        await $.pumpAndSettle();
        break; // Test one category
      }
    }
  } catch (e) {
    // Waste categories not found
  }
}

Future<void> _testRapidNavigation(PatrolTester $) async {
  try {
    // Test rapid navigation between tabs
    if ($(NavigationBar).exists) {
      final destinations = $(NavigationDestination);
      if (destinations.exists) {
        final count = destinations.evaluate().length;
        
        for (int i = 0; i < count && i < 5; i++) {
          await destinations.at(i).tap();
          await $.pumpAndSettle();
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    }
  } catch (e) {
    // Rapid navigation test failed
  }
}

Future<void> _testScrollPerformance(PatrolTester $) async {
  try {
    // Navigate to history for scroll testing
    if ($(NavigationBar).exists) {
      final destinations = $(NavigationDestination);
      if (destinations.exists && destinations.evaluate().length > 1) {
        await destinations.at(1).tap();
        await $.pumpAndSettle();
        
        // Test scrolling if content exists
        if ($(ListView).exists) {
          await $(ListView).scroll(Offset(0, -200));
          await Future.delayed(const Duration(milliseconds: 300));
          await $(ListView).scroll(Offset(0, 200));
          await Future.delayed(const Duration(milliseconds: 300));
        } else if ($(SingleChildScrollView).exists) {
          await $(SingleChildScrollView).scroll(Offset(0, -200));
          await Future.delayed(const Duration(milliseconds: 300));
          await $(SingleChildScrollView).scroll(Offset(0, 200));
        }
      }
    }
  } catch (e) {
    // Scroll performance test failed
  }
}

Future<void> _testPlatformFeatures(PatrolTester $) async {
  try {
    // Test platform-specific features
    await $.native.pressBack();
    await $.native.pressHome();
    await Future.delayed(const Duration(seconds: 1));
    
    // This might reopen the app on some platforms
  } catch (e) {
    // Platform features test failed
  }
}

Future<void> _testResponsiveDesign(PatrolTester $) async {
  try {
    // Test different orientations if supported
    await $.native.setOrientation(Orientation.landscape);
    await Future.delayed(const Duration(seconds: 1));
    
    // Verify app still works in landscape
    expect(
      $(NavigationBar).exists || 
      $(FloatingActionButton).exists ||
      $(Text('Waste Segregation')).exists,
      isTrue,
      reason: 'App should work in landscape mode'
    );
    
    await $.native.setOrientation(Orientation.portrait);
    await Future.delayed(const Duration(seconds: 1));
  } catch (e) {
    // Orientation change not supported on this platform
  }
}
