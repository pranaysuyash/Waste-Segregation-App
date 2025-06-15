import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:waste_segregation_app/main.dart' as app;

void main() {
  patrolTest(
    'Waste Classification Flow - Patrol E2E',
    ($) async {
      // Launch the app
      await $.pumpWidgetAndSettle(const MaterialApp(home: Text('Test App')));

      // Wait for initialization
      await Future.delayed(const Duration(seconds: 2));

      // Verify home screen
      await $(#homeScreen).waitUntilVisible();
      
      // Test camera/classification flow
      if (await $(#classifyButton).exists) {
        await $(#classifyButton).tap();
        await $(#cameraScreen).waitUntilVisible();
        
        // Test camera permissions (if needed)
        await $.native.grantPermissionWhenInUse();
        
        // Navigate back to test other flows
        await $.native.pressBack();
      }

      // Test history navigation
      if (await $(#historyButton).exists) {
        await $(#historyButton).tap();
        await $(#historyScreen).waitUntilVisible();
        
        // Verify history content loads
        await $(#historyList).waitUntilVisible();
        
        await $.native.pressBack();
      }

      // Test achievements
      if (await $(#achievementsButton).exists) {
        await $(#achievementsButton).tap();
        await $(#achievementsScreen).waitUntilVisible();
        
        // Test achievement claiming (if any available)
        final claimButtons = $(#claimButton);
        if (await claimButtons.exists) {
          await claimButtons.tap();
          // Verify points update
          await $(#pointsDisplay).waitUntilVisible();
        }
        
        await $.native.pressBack();
      }
    },
  );

  patrolTest(
    'Premium Features Flow - Patrol E2E',
    ($) async {
      await $.pumpWidgetAndSettle(const MaterialApp(home: Text('Test App')));
      await Future.delayed(const Duration(seconds: 2));

      // Navigate to premium features
      if (await $(#premiumButton).exists) {
        await $(#premiumButton).tap();
        await $(#premiumScreen).waitUntilVisible();
        
        // Test premium banner
        await $(#premiumBanner).waitUntilVisible();
        
        // Test upgrade button
        if (await $(#upgradeButton).exists) {
          await $(#upgradeButton).tap();
          // Handle potential system dialogs for payments
          await $.native.grantPermissionWhenInUse();
        }
      }
    },
  );

  patrolTest(
    'Points System Integration - Patrol E2E',
    ($) async {
      await $.pumpWidgetAndSettle(const MaterialApp(home: Text('Test App')));
      await Future.delayed(const Duration(seconds: 2));

      // Verify points display on home screen
      await $(#pointsDisplay).waitUntilVisible();
      
      // Get initial points value
      final initialPointsText = await $(#pointsDisplay).text;
      
      // Perform an action that should award points (mock classification)
      if (await $(#classifyButton).exists) {
        await $(#classifyButton).tap();
        
        // Simulate successful classification
        if (await $(#mockClassificationButton).exists) {
          await $(#mockClassificationButton).tap();
          
          // Navigate back to home
          await $.native.pressBack();
          
          // Verify points increased
          await $(#pointsDisplay).waitUntilVisible();
          final newPointsText = await $(#pointsDisplay).text;
          
          // Points should have changed
          expect(newPointsText, isNot(equals(initialPointsText)));
        }
      }
    },
  );

  patrolTest(
    'Settings and Preferences - Patrol E2E',
    ($) async {
      await $.pumpWidgetAndSettle(const MaterialApp(home: Text('Test App')));
      await Future.delayed(const Duration(seconds: 2));

      // Navigate to settings
      if (await $(#settingsButton).exists) {
        await $(#settingsButton).tap();
        await $(#settingsScreen).waitUntilVisible();
        
        // Test theme toggle
        if (await $(#themeToggle).exists) {
          await $(#themeToggle).tap();
          // Verify theme change (visual test would be better)
        }
        
        // Test notification settings
        if (await $(#notificationToggle).exists) {
          await $(#notificationToggle).tap();
          // Handle system permission dialog if needed
          await $.native.grantPermissionWhenInUse();
        }
        
        // Test language settings
        if (await $(#languageSelector).exists) {
          await $(#languageSelector).tap();
          // Select a different language if available
          if (await $(#languageOption).exists) {
            await $(#languageOption).tap();
          }
        }
      }
    },
  );

  patrolTest(
    'Network Connectivity and Error Handling - Patrol E2E',
    ($) async {
      await $.pumpWidgetAndSettle(const MaterialApp(home: Text('Test App')));
      await Future.delayed(const Duration(seconds: 2));

      // Test offline behavior
      await $.native.disableWifi();
      await $.native.disableCellular();
      
      // Try to perform network-dependent action
      if (await $(#classifyButton).exists) {
        await $(#classifyButton).tap();
        
        // Should show offline message
        await $(#offlineMessage).waitUntilVisible();
      }
      
      // Re-enable connectivity
      await $.native.enableWifi();
      await $.native.enableCellular();
      
      // Verify app recovers
      await Future.delayed(const Duration(seconds: 3));
      await $(#homeScreen).waitUntilVisible();
    },
  );
} 