# Responsive Text Widgets for AppBar and Greetings

## Overview

To handle text overflow and ensure a clean UI across various screen sizes, the application utilizes a comprehensive set of responsive text widgets. These are implemented in `lib/widgets/responsive_text.dart` and leverage the `auto_size_text` package for dynamic font sizing and intelligent text adaptation.

## File Location

`lib/widgets/responsive_text.dart`

## Core Component: `ResponsiveText`

`ResponsiveText` is the base class that provides comprehensive auto-sizing capabilities. It intelligently wraps the `AutoSizeText` widget and offers a convenient way to create text that adjusts its font size to fit within the available space, preventing overflow.

### Key Features of `ResponsiveText`:
- **Auto-sizing**: Automatically adjusts font size based on available space
- **Min/Max Font Size**: Configurable range for font scaling (default: 12.0-16.0)
- **Max Lines**: Customizable line limits for different use cases
- **Overflow Handling**: Supports `TextOverflow.ellipsis` and other overflow strategies
- **Text Wrapping**: Optional word wrapping with `enableWrapping` parameter
- **Semantic Support**: Built-in accessibility with `semanticsLabel`
- **Specialized Presets**: Named constructors for common use cases:
  - `ResponsiveText.appBarTitle()` - Optimized for AppBar titles
  - `ResponsiveText.greeting()` - Optimized for greeting messages
  - `ResponsiveText.cardTitle()` - Optimized for card titles

## Specialized Responsive Widgets

### 1. `ResponsiveAppBarTitle`

**Purpose**: Specifically designed for AppBar titles to prevent overflow, especially on narrower screens or with longer titles (e.g., "Waste Segregation Pro Edition").

**Key Features**:
- **Automatic Font Sizing**: Adjusts the title's font size (14.0-20.0px) to fit the AppBar
- **Intelligent Abbreviation Logic**: For very narrow screens (<200px), automatically creates abbreviations:
  - Multi-word titles: "Waste Segregation App" → "WSA"
  - Long single words: "WasteSegregation" → "WasteSeg..."
- **Layout-Based Adaptation**: Uses `LayoutBuilder` to detect available space
- **Single Line Display**: Enforces `maxLines: 1` with ellipsis overflow
- **Accessibility**: Maintains full title in semantic labels

**Implementation Details**:
- **Font Range**: 14.0px (minimum) to 20.0px (maximum)
- **Breakpoint**: 200px width for abbreviation trigger
- **Abbreviation Algorithm**: First letter of each word for multi-word titles

**Usage Example**:
```dart
// In an AppBar
appBar: AppBar(
  title: ResponsiveAppBarTitle(
    title: AppStrings.appName,
    style: Theme.of(context).textTheme.titleLarge,
  ),
)
```

### 2. `GreetingText`

**Purpose**: Displays dynamic greetings (e.g., "Good Morning, User", "Good Evening, Pranay") with intelligent overflow handling for varying username lengths.

**Key Features**:
- **Intelligent Overflow Detection**: Uses `TextPainter` to pre-calculate text overflow
- **Adaptive Font Sizing**: Automatically adjusts font size (16.0-28.0px) when overflow is detected
- **Multi-line Support**: Allows up to 2 lines for long usernames with word wrapping
- **Performance Optimization**: Uses regular `Text` widget when no overflow is detected
- **Customizable Styling**: Supports custom colors and text styles
- **Default Styling**: Uses `headlineMedium` with bold weight and white color

**Implementation Details**:
- **Font Range**: 16.0px (minimum) to 28.0px (maximum, or style fontSize)
- **Max Lines**: 2 lines with word wrapping enabled
- **Overflow Strategy**: `TextOverflow.ellipsis` for extreme cases
- **Performance**: Pre-calculation prevents unnecessary auto-sizing

**Usage Example**:
```dart
// In the home screen's hero section
GreetingText(
  greeting: "Good Morning",
  userName: "Pranay Kumar",
  color: Colors.white,
  style: Theme.of(context).textTheme.headlineLarge,
)
```

### 3. `ResponsiveText.cardTitle`

**Purpose**: Optimized for card titles and content headers that need to fit within card layouts.

**Key Features**:
- **Card-Optimized Font Range**: 14.0-18.0px for readable card content
- **Multi-line Support**: Up to 2 lines with word wrapping
- **Left Alignment**: Default `TextAlign.start` for card layouts
- **Overflow Protection**: Ellipsis handling for extremely long titles

**Implementation Details**:
- **Font Range**: 14.0px (minimum) to 18.0px (maximum)
- **Max Lines**: 2 lines with wrapping enabled
- **Text Alignment**: Start-aligned for natural reading flow

**Usage Example**:
```dart
// In card widgets
Card(
  child: Column(
    children: [
      ResponsiveText.cardTitle(
        'Long Card Title That Might Overflow',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      // Card content...
    ],
  ),
)
```

## Underlying Technology

- **`auto_size_text` Package**: The core mechanism for dynamic font sizing. This package provides the `AutoSizeText` widget, which `ResponsiveText` wraps and configures.
- **`TextPainter`**: Used in `GreetingText` for intelligent overflow pre-calculation
- **`LayoutBuilder`**: Enables responsive behavior based on available space constraints

## Advanced Features

### Performance Optimizations
- **Conditional Auto-sizing**: `ResponsiveText` can disable auto-sizing with `enableAutoSizing: false`
- **Smart Overflow Detection**: `GreetingText` only uses auto-sizing when necessary
- **Efficient Layout**: `LayoutBuilder` prevents unnecessary rebuilds

### Accessibility Support
- **Semantic Labels**: All components support `semanticsLabel` for screen readers
- **Readable Font Sizes**: Minimum font sizes ensure accessibility compliance
- **High Contrast**: Works with system accessibility settings

### Customization Options
- **Style Override**: All components accept custom `TextStyle`
- **Color Theming**: Automatic theme integration with manual override options
- **Alignment Control**: Configurable text alignment for different layouts

## Benefits

- **Prevents UI Overflow**: Eliminates text clipping or `RenderFlex` overflow errors caused by long text in constrained spaces
- **Improved Readability**: Ensures text remains legible across different device sizes and orientations
- **Performance Optimized**: Intelligent overflow detection prevents unnecessary auto-sizing operations
- **Accessibility Compliant**: Built-in support for screen readers and accessibility standards
- **Consistent Look and Feel**: Provides a more polished and professional appearance across the app
- **Reduced Manual Adjustments**: Developers don't need to manually tweak font sizes for different screen densities or languages with varying text lengths
- **Future-Proof**: Adapts automatically to new screen sizes and device types

## Implementation Guidelines

### Best Practices
1. **Use Appropriate Presets**: Choose the right named constructor for your use case
2. **Provide Semantic Labels**: Always include `semanticsLabel` for accessibility
3. **Test on Various Screens**: Verify behavior on different device sizes
4. **Consider Performance**: Use `GreetingText` pattern for expensive overflow calculations

### Common Use Cases
- **AppBar Titles**: Use `ResponsiveAppBarTitle` for app navigation
- **Hero Sections**: Use `GreetingText` for personalized welcome messages
- **Card Content**: Use `ResponsiveText.cardTitle` for card headers
- **General Text**: Use base `ResponsiveText` with custom parameters

These responsive text components are fundamental to the application's adaptive UI architecture, ensuring that titles, greetings, and other important text elements are always displayed correctly and legibly across all supported devices and screen sizes. 