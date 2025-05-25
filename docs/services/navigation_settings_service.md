# Navigation Settings Service

## Overview

The `NavigationSettingsService` is responsible for managing user preferences related to app navigation. It allows users to customize the visibility and style of navigation elements like the bottom navigation bar and the floating action button (FAB).

This service extends `ChangeNotifier` to notify listeners (typically UI widgets) when settings change, allowing the UI to dynamically update. Settings are persisted locally using `shared_preferences`.

## File Location

`lib/services/navigation_settings_service.dart`

## Core Functionality

- **Persistence**: Saves and loads navigation preferences using `SharedPreferences`. This ensures that user settings are retained across app sessions.
- **State Management**: Uses `ChangeNotifier` to manage and broadcast changes to navigation settings.
- **Customization Options**:
    - **Bottom Navigation Bar**: Enable or disable the main bottom navigation.
    - **Floating Action Button (FAB)**: Enable or disable the central camera/action button.
    - **Navigation Style**: Choose between different visual styles for the bottom navigation bar.

## Settings Details

### 1. Bottom Navigation Bar Visibility
- **Key**: `showBottomNavBar`
- **Type**: `bool`
- **Default**: `true`
- **Description**: Controls whether the bottom navigation bar is displayed.

### 2. Floating Action Button (FAB) Visibility
- **Key**: `showFab`
- **Type**: `bool`
- **Default**: `true`
- **Description**: Controls whether the Floating Action Button (primarily for camera access) is displayed.

### 3. Navigation Style
- **Key**: `navigationStyle`
- **Type**: `NavigationStyle` (enum)
- **Default**: `NavigationStyle.material3`
- **Description**: Allows the user to select the visual appearance of the bottom navigation bar.
- **Available Styles**:
    - `NavigationStyle.material3`: Standard Material Design 3 navigation bar.
    - `NavigationStyle.glassmorphism`: A semi-transparent, blurred navigation bar.
    - `NavigationStyle.floating`: A floating, pill-shaped navigation bar.

## Methods

### `NavigationSettingsService()`
- Constructor. Initializes the service and loads saved preferences.

### `Future<void> loadPreferences()`
- Asynchronously loads all navigation settings from `SharedPreferences`.
- If a preference is not found, it defaults to the predefined default values.
- Notifies listeners after loading.

### `Future<void> _savePreference(String key, dynamic value)`
- Private helper method to save a key-value pair to `SharedPreferences`.

### `Future<void> setShowBottomNavBar(bool value)`
- Updates the `showBottomNavBar` setting.
- Saves the preference and notifies listeners.

### `Future<void> setShowFab(bool value)`
- Updates the `showFab` setting.
- Saves the preference and notifies listeners.

### `Future<void> setNavigationStyle(NavigationStyle value)`
- Updates the `navigationStyle` setting.
- Saves the preference (as a string representation of the enum) and notifies listeners.

### `Future<void> resetToDefaults()`
- Resets all navigation settings to their default values.
- Saves the default preferences and notifies listeners.

## Usage Example

The `NavigationSettingsService` is typically provided at a higher level in the widget tree using a `ChangeNotifierProvider`. Widgets that need to react to navigation settings changes can consume the service.

```dart
// In main.dart or an equivalent setup file
MultiProvider(
  providers: [
    // ... other providers
    ChangeNotifierProvider(create: (_) => NavigationSettingsService()),
  ],
  child: MyApp(),
)

// In a widget that needs to adapt to navigation settings
Consumer<NavigationSettingsService>(
  builder: (context, settings, child) {
    return Scaffold(
      bottomNavigationBar: settings.showBottomNavBar 
          ? MyCustomBottomNav(style: settings.navigationStyle) 
          : null,
      floatingActionButton: settings.showFab ? MyFab() : null,
      // ...
    );
  }
)
```

## Integration

- **Settings Screen**: `lib/screens/settings_screen.dart` provides UI elements (switches, dropdowns) for users to modify these settings.
- **Navigation Wrapper**: `lib/widgets/navigation_wrapper.dart` consumes this service to dynamically render the navigation elements based on user preferences.

This service plays a crucial role in providing a customizable and user-friendly navigation experience within the Waste Segregation App. 