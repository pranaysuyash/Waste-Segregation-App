# Responsive Text Widgets for AppBar and Greetings

## Overview

To handle text overflow and ensure a clean UI across various screen sizes, the application utilizes a set of responsive text widgets. These are primarily found in `lib/widgets/responsive_text.dart` and leverage the `auto_size_text` package for dynamic font sizing.

## File Location

`lib/widgets/responsive_text.dart`

## Core Component: `ResponsiveText`

`ResponsiveText` is the base class that provides auto-sizing capabilities. It wraps the `AutoSizeText` widget and offers a convenient way to create text that adjusts its font size to fit within the available space, preventing overflow.

### Key Features of `ResponsiveText`:
- **Auto-sizing**: Automatically adjusts font size.
- **Min/Max Font Size**: Allows defining a range for font scaling.
- **Max Lines**: Can limit the number of lines.
- **Overflow Handling**: Supports `TextOverflow.ellipsis` or other overflow strategies.
- **Presets**: Offers specialized constructors for common use cases like AppBar titles and greetings.

## Specialized Responsive Widgets

### 1. `ResponsiveAppBarTitle`

**Purpose**: Specifically designed for AppBar titles to prevent overflow, especially on narrower screens or with longer titles (e.g., "Waste Segregation Pro Edition").

**Key Features**:
- **Automatic Font Sizing**: Adjusts the title's font size to fit the AppBar.
- **Abbreviation Logic**: If the title is too long even after font scaling, it can abbreviate the text. For example, "Waste Segregation App" might become "WS App" or similar on very small screens. This logic is customizable.
- **Uses `ResponsiveText.appBarTitle()`**: This named constructor of `ResponsiveText` is pre-configured with suitable parameters for AppBar usage (e.g., `maxLines: 1`).

**Usage Example**:
```dart
// In an AppBar
appBar: AppBar(
  title: ResponsiveAppBarTitle(text: AppStrings.appName),
)
```

### 2. `GreetingText`

**Purpose**: Displays time-based greetings (e.g., "Good Morning, User", "Good Evening, Pranay") and ensures they are responsive and do not overflow, especially with long usernames.

**Key Features**:
- **Dynamic Greetings**: Shows greetings based on the time of day.
- **Automatic Font Sizing**: Adjusts the greeting text font size.
- **Username Handling**: Accommodates varying lengths of usernames.
- **Uses `ResponsiveText.greeting()`**: This named constructor is tailored for greeting messages.
- **Overflow Detection (Internal)**: While primarily relying on `AutoSizeText`, it can incorporate additional logic to handle extreme cases.

**Usage Example**:
```dart
// In the home screen's hero section
GreetingText(userName: "Pranay Kumar")
```

## Underlying Technology

- **`auto_size_text` Package**: The core mechanism for dynamic font sizing. This package provides the `AutoSizeText` widget, which `ResponsiveText` wraps and configures.

## Benefits

- **Prevents UI Overflow**: Eliminates text clipping or `RenderFlex` overflow errors caused by long text in constrained spaces.
- **Improved Readability**: Ensures text remains legible across different device sizes.
- **Consistent Look and Feel**: Provides a more polished and professional appearance.
- **Reduced Manual Adjustments**: Developers don't need to manually tweak font sizes for different screen densities or languages with varying text lengths.

These responsive text components are fundamental to the application's adaptive UI, ensuring that titles, greetings, and other important text elements are always displayed correctly and legibly. 