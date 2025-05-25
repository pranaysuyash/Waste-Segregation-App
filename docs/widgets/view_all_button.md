# ViewAllButton Widget

## Overview

The `ViewAllButton` is a specialized responsive button widget designed to provide a "View All" action, typically used at the end of lists or sections to navigate to a more comprehensive view.

It adapts its appearance based on the available width, transitioning between full text, abbreviated text, and an icon-only representation to prevent UI overflow and maintain a clean look across different screen sizes.

## File Location

`lib/widgets/modern_ui/modern_buttons.dart` (within the `ModernButton` class structure, specifically the `ViewAllButton` named constructor/variant).

## Responsive Behavior

The button has three main display states determined by `LayoutBuilder`:

1.  **Full Text (Default)**: Displays "View All" along with an optional icon (e.g., `Icons.arrow_forward`). This is used when sufficient width is available (>= 120 logical pixels).
2.  **Abbreviated Text (Narrow)**: Displays only the last word of the `text` property (e.g., "All") or a truncated version if the last word is too long, plus the icon. This is used for widths between 80 and 120 logical pixels.
3.  **Icon-Only (Very Narrow)**: Displays only the icon. A tooltip showing the full text ("View All") is automatically displayed on hover or long-press. This is used when the width is less than 80 logical pixels.

## Key Features

- **Automatic Responsiveness**: Uses `LayoutBuilder` to adapt its content dynamically.
- **Text Abbreviation**: Intelligently shortens the text for narrower contexts.
- **Icon Support**: Can display a leading icon.
- **Tooltip for Icon-Only**: Ensures usability even in the most compact form by showing a tooltip.
- **Customizable Text**: While typically "View All", the text can be customized.
- **Standard `ModernButton` Properties**: Inherits styling and behavior from the `ModernButton` base, such as `onPressed` callback, `icon`, `textStyle`, etc.

## Parameters

Being a specialized version of `ModernButton`, it primarily uses the standard `ModernButton` parameters, but its internal logic is tailored for the "View All" use case.

- **`onPressed`**: `VoidCallback?` - The function to call when the button is tapped.
- **`text`**: `String` - The text to display (defaults to "View All" effectively, but can be set).
- **`icon`**: `IconData?` - The icon to display (e.g., `Icons.arrow_forward`).
- **`iconSize`**: `double?` - Size of the icon.
- **`textStyle`**: `TextStyle?` - Style for the button text.
- **`buttonStyle`**: `ButtonStyle?` - Further customization of the button's appearance.
- **`tooltip`**: `String?` - Custom tooltip text. If not provided, it defaults to the button `text` in icon-only mode.

## Usage Example

```dart
// In a widget, typically at the end of a list section
ViewAllButton(
  onPressed: () {
    // Navigate to the full list screen
    Navigator.push(context, MaterialPageRoute(builder: (_) => FullHistoryScreen()));
  },
  // Optional: icon: Icons.chevron_right,
)

// Example with custom text used in a section header
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text("Recent Activity", style: Theme.of(context).textTheme.headline6),
    ViewAllButton(
      text: "See All Activity",
      onPressed: () => print("Navigate to all activity"),
      icon: Icons.read_more,
    ),
  ],
)
```

## Implementation Notes

- The responsive logic is encapsulated within the `_ViewAllButtonState` class.
- Breakpoints (80px and 120px) are defined internally for switching between display states.
- Text abbreviation logic attempts to extract the last word. If the text is a single long word, it will truncate it with an ellipsis.

This widget is crucial for creating clean and adaptive UIs where space is at a premium, ensuring that "View All" actions remain accessible and understandable across various device sizes. 