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
- **Key**: `bottom_nav_enabled`
- **Property**: `bottomNavEnabled`
- **Type**: `bool`
- **Default**: `true`
- **Description**: Controls whether the bottom navigation bar is displayed.

### 2. Floating Action Button (FAB) Visibility
- **Key**: `fab_enabled`
- **Property**: `fabEnabled`
- **Type**: `bool`
- **Default**: `true`
- **Description**: Controls whether the Floating Action Button (primarily for camera access) is displayed.

### 3. Navigation Style
- **Key**: `navigation_style`
- **Property**: `navigationStyle`
- **Type**: `String`
- **Default**: `'glassmorphism'`
- **Description**: Allows the user to select the visual appearance of the bottom navigation bar.
- **Available Styles**:
    - `'glassmorphism'`: A semi-transparent, blurred navigation bar (default).
    - `'material3'`: Standard Material Design 3 navigation bar.
    - `'floating'`: A floating, pill-shaped navigation bar.

## Properties

### `bool bottomNavEnabled`
- **Getter**: Returns the current state of bottom navigation visibility
- **Default**: `true`

### `bool fabEnabled`
- **Getter**: Returns the current state of FAB visibility
- **Default**: `true`

### `String navigationStyle`
- **Getter**: Returns the current navigation style
- **Default**: `'glassmorphism'`

## Methods

### `NavigationSettingsService()`
- **Constructor**: Initializes the service and automatically loads saved preferences via `_loadSettings()`

### `Future<void> _loadSettings()`
- **Private method**: Asynchronously loads all navigation settings from `SharedPreferences`
- **Error Handling**: Includes try-catch with debug logging for failed operations
- **Defaults**: If a preference is not found, uses predefined default values
- **Notification**: Calls `notifyListeners()` after loading to update UI

### `Future<void> setBottomNavEnabled(bool enabled)`
- **Purpose**: Updates the bottom navigation visibility setting
- **Parameters**: `enabled` - boolean value for navigation bar visibility
- **Persistence**: Saves to SharedPreferences with key `bottom_nav_enabled`
- **Error Handling**: Includes try-catch with debug logging
- **Notification**: Calls `notifyListeners()` to update UI

### `Future<void> setFabEnabled(bool enabled)`
- **Purpose**: Updates the FAB visibility setting
- **Parameters**: `enabled` - boolean value for FAB visibility
- **Persistence**: Saves to SharedPreferences with key `fab_enabled`
- **Error Handling**: Includes try-catch with debug logging
- **Notification**: Calls `notifyListeners()` to update UI

### `Future<void> setNavigationStyle(String style)`
- **Purpose**: Updates the navigation style setting
- **Parameters**: `style` - string value ('glassmorphism', 'material3', or 'floating')
- **Persistence**: Saves to SharedPreferences with key `navigation_style`
- **Error Handling**: Includes try-catch with debug logging
- **Notification**: Calls `notifyListeners()` to update UI

### `Future<void> resetToDefaults()`
- **Purpose**: Resets all navigation settings to their default values
- **Implementation**: Removes all keys from SharedPreferences and resets internal state
- **Defaults Applied**:
  - `bottomNavEnabled`: `true`
  - `fabEnabled`: `true`
  - `navigationStyle`: `'glassmorphism'`
- **Error Handling**: Includes try-catch with debug logging
- **Notification**: Calls `notifyListeners()` to update UI

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
      bottomNavigationBar: settings.bottomNavEnabled 
          ? MyCustomBottomNav(style: settings.navigationStyle) 
          : null,
      floatingActionButton: settings.fabEnabled ? MyFab() : null,
      // ...
    );
  }
)

// In settings screen for user controls
class NavigationSettingsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationSettingsService>(
      builder: (context, navSettings, child) {
        return Column(
          children: [
            SwitchListTile(
              title: Text('Show Bottom Navigation'),
              value: navSettings.bottomNavEnabled,
              onChanged: (value) => navSettings.setBottomNavEnabled(value),
            ),
            SwitchListTile(
              title: Text('Show Floating Action Button'),
              value: navSettings.fabEnabled,
              onChanged: (value) => navSettings.setFabEnabled(value),
            ),
            DropdownButton<String>(
              value: navSettings.navigationStyle,
              items: [
                DropdownMenuItem(value: 'glassmorphism', child: Text('Glassmorphism')),
                DropdownMenuItem(value: 'material3', child: Text('Material 3')),
                DropdownMenuItem(value: 'floating', child: Text('Floating')),
              ],
              onChanged: (style) {
                if (style != null) navSettings.setNavigationStyle(style);
              },
            ),
            ElevatedButton(
              onPressed: () => navSettings.resetToDefaults(),
              child: Text('Reset to Defaults'),
            ),
          ],
        );
      },
    );
  }
}
```

## Implementation Details

### Constants
The service uses private constants for SharedPreferences keys:
- `_bottomNavEnabledKey`: `'bottom_nav_enabled'`
- `_fabEnabledKey`: `'fab_enabled'`
- `_navigationStyleKey`: `'navigation_style'`

### Error Handling
All async operations include comprehensive error handling:
- Try-catch blocks around SharedPreferences operations
- Debug logging for troubleshooting
- Graceful fallbacks to default values

### State Management
- Extends `ChangeNotifier` for reactive UI updates
- Automatic notification of listeners after state changes
- Immediate UI reflection of setting changes

## Integration Points

### Settings Screen
- **File**: `lib/screens/settings_screen.dart`
- **Purpose**: Provides UI controls (switches, dropdowns) for users to modify navigation settings
- **Implementation**: Uses `Consumer<NavigationSettingsService>` to react to changes

### Navigation Components
- **Bottom Navigation**: Conditionally rendered based on `bottomNavEnabled`
- **FAB**: Conditionally rendered based on `fabEnabled`
- **Style Application**: Navigation style applied through `navigationStyle` property

### Provider Setup
The service should be provided at the app level:
```dart
ChangeNotifierProvider(
  create: (_) => NavigationSettingsService(),
  child: MaterialApp(...),
)
```

## Performance Considerations

### Initialization
- Settings are loaded asynchronously during service construction
- No blocking of app startup
- Default values ensure immediate functionality

### Persistence
- Individual setting changes are immediately persisted
- No batching required for user preference changes
- Efficient SharedPreferences usage

### Memory Management
- Lightweight service with minimal memory footprint
- Automatic cleanup through ChangeNotifier lifecycle
- No manual disposal required when properly provided

## Best Practices

### Usage Guidelines
1. **Provider Level**: Always provide at app or high widget tree level
2. **Consumer Pattern**: Use `Consumer<NavigationSettingsService>` for reactive UI
3. **Error Handling**: Service handles errors internally, no additional handling needed
4. **Default Values**: Service provides sensible defaults, no null checks required

### Testing Considerations
- Mock SharedPreferences for unit testing
- Test default value fallbacks
- Verify listener notifications
- Test error handling scenarios

## Related Components

- **`ModernBottomNavigation`**: Consumes navigation style settings
- **`ModernFAB`**: Visibility controlled by FAB settings
- **`SettingsScreen`**: Provides user interface for configuration
- **`NavigationWrapper`**: Orchestrates navigation component rendering

This service is essential for providing a customizable and user-friendly navigation experience, allowing users to personalize their interaction with the Waste Segregation App while maintaining consistent functionality across different navigation styles. 