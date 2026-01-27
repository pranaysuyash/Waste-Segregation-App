# ViewAllButton Widget

## Overview

The `ViewAllButton` is a specialized responsive button widget designed to provide a "View All" action, typically used at the end of lists or sections to navigate to a more comprehensive view.

It adapts its appearance based on the available width, transitioning between full text, abbreviated text, and an icon-only representation to prevent UI overflow and maintain a clean look across different screen sizes.

## File Location

`lib/widgets/modern_ui/modern_buttons.dart` - Implemented as a standalone `ViewAllButton` class that extends `StatelessWidget`.

## Responsive Behavior

The button has three main display states determined by `LayoutBuilder`:

1.  **Full Text (Default)**: Displays "View All" along with an optional icon (e.g., `Icons.arrow_forward`). This is used when sufficient width is available (≥ 120 logical pixels).
2.  **Abbreviated Text (Narrow)**: Displays only the last word of the `text` property (e.g., "All") or a truncated version if the last word is too long, plus the icon. This is used for widths between 80–119 logical pixels.
3.  **Icon-Only (Very Narrow)**: Displays only the icon. A tooltip showing the full text ("View All") is automatically displayed on hover or long-press. This is used when the width is < 80 logical pixels.

## Key features

- **Automatic Responsiveness**: Uses `LayoutBuilder` to adapt its content dynamically based on available width
- **Intelligent Text Abbreviation**: Extracts last word from multi-word text or truncates long single words
- **Icon Support**: Optional leading icon (defaults to `Icons.arrow_forward` in icon-only mode)
- **Tooltip for Icon-Only**: Automatically shows full text as tooltip in icon-only mode for accessibility
- **Customizable Text**: Defaults to "View All" but fully customizable
- **Modern Button Integration**: Built on top of `ModernButton` with all its styling options
- **Overflow Protection**: Prevents UI overflow in constrained spaces

## Parameters

The `ViewAllButton` has its own set of parameters optimized for the "View All" use case:

- **`text`**: `String` - The text to display (defaults to "View All")
- **`onPressed`**: `VoidCallback` - Required callback function when the button is tapped
- **`icon`**: `IconData?` - Optional icon to display (defaults to `Icons.arrow_forward` in icon-only mode)
- **`color`**: `Color?` - Optional color override for the button
- **`style`**: `ModernButtonStyle` - Button style (defaults to `ModernButtonStyle.text`)
- **`size`**: `ModernButtonSize` - Button size (defaults to `ModernButtonSize.small`)

### Inherited ModernButton features
Since `ViewAllButton` uses `ModernButton` internally, it inherits:
- **Tooltip Support**: Automatic tooltip in icon-only mode via `tooltipMessage` parameter
- **Animation Effects**: Scale animation on press
- **Theme Integration**: Automatic color and style theming
- **Accessibility**: Screen reader support and semantic labels via `semanticLabel`
- **Custom Padding**: Configurable padding parameter for fine-tuned spacing

## Usage examples

```dart
// Basic usage - typically at the end of a list section
ViewAllButton(
  onPressed: () {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => FullHistoryScreen()),
    );
  },
)

// Custom text and icon
ViewAllButton(
  text: "See All Activity",
  icon: Icons.read_more,
  onPressed: () => Navigator.pushNamed(context, '/all-activity'),
)

// With custom styling
ViewAllButton(
  text: "View More",
  style: ModernButtonStyle.outlined,
  size: ModernButtonSize.medium,
  color: Theme.of(context).colorScheme.secondary,
  onPressed: () => _showMoreItems(),
)

// In a section header with responsive behavior
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(
      child: Text(
        "Recent Classifications",
        style: Theme.of(context).textTheme.titleLarge,
      ),
    ),
    ViewAllButton(
      text: "View All Classifications",
      icon: Icons.history,
      onPressed: () => _navigateToHistory(),
    ),
  ],
)

// Testing responsive behavior in constrained space
SizedBox(
  width: 70, // Forces icon-only mode
  child: ViewAllButton(
    text: "View All Items",
    onPressed: () => _showAllItems(),
  ),
)
```

## Implementation details

### Responsive breakpoints
- **< 80px**: Icon-only mode with tooltip
- **80–119px**: Abbreviated text mode
- **≥ 120px**: Full text mode

### Text abbreviation algorithm
1. **Multi-word text**: Uses the last word (e.g., "View All Items" → "Items")
2. **Single long word**: Truncates to the first **4** characters (e.g., "Classifications" → "Clas")
3. **Short single word**: Displays as-is

### Internal implementation
The widget uses `LayoutBuilder` to determine the available width and conditionally renders different `ModernButton` configurations:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 80) {
      return ModernButton.iconOnly(...);
    } else if (constraints.maxWidth < 120) {
      return ModernButton.abbreviated(...);
    } else {
      return ModernButton.fullText(...);
    }
  },
);
```

### Performance considerations
- Uses `LayoutBuilder` for efficient responsive behavior
- Minimal widget rebuilds through proper state management
- Leverages `ModernButton`'s optimized rendering

## Accessibility features

- **Automatic tooltips**: Full text shown as tooltip in icon-only mode
- **Semantic labels**: Proper screen reader support with `semanticLabel` on the underlying `ModernButton`
- **Touch targets**: Maintains minimum 44px touch target size
- **High contrast**: Works with system accessibility settings

## Best practices

### When to use
- ✅ At the end of list sections for navigation to full views
- ✅ In constrained spaces where text might overflow
- ✅ For consistent "View All" actions across the app

### When not to use
- ❌ For primary actions (use `ModernButton` instead)
- ❌ When space is not constrained (use regular buttons)
- ❌ For actions other than navigation/viewing more content

## Related components

- **`ModernButton`**: Base button component with full styling options
- **`ResponsiveText`**: For responsive text without button functionality
- **`ModernFAB`**: For floating action buttons with similar responsive features

This widget is crucial for creating clean and adaptive UIs where space is at a premium, ensuring that "View All" actions remain accessible and understandable across various device sizes while maintaining consistent user experience patterns. 