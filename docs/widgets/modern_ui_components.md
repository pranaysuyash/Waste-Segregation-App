# Modern UI Components Overview

## Introduction

The Waste Segregation App incorporates a suite of custom "Modern UI" components designed to provide a consistent, responsive, and aesthetically pleasing user experience. These components are generally located in the `lib/widgets/modern_ui/` directory and often leverage Flutter's `LayoutBuilder` for adaptive behavior.

This document provides a high-level overview of these components. More detailed documentation for specific complex components may be available in separate files (e.g., `view_all_button.md`).

## Core Modern UI Widgets

### 1. Badge Components (`modern_badges.dart`)

#### `ModernBadge`
- **Description**: A versatile badge widget with multiple styles and animations
- **Key Features**:
    - Multiple styles: filled, outlined, soft, glassmorphism
    - Three sizes: small, medium, large
    - Icon support with automatic sizing
    - Pulse animation capability
    - Tap handling with callbacks
    - Responsive sizing and overflow protection
- **Usage**: Status indicators, category tags, notification badges

#### `ModernChip`
- **Description**: Interactive chip with selection and filtering capabilities
- **Key Features**:
    - Selection state management
    - Delete functionality with callback
    - Multiple styles matching ModernBadge
    - Icon support
    - Animated state transitions
- **Usage**: Filter tags, selectable options, removable items

#### `ModernChipGroup`
- **Description**: Group of chips with multi-selection support
- **Key Features**:
    - Single or multi-selection modes
    - Wrap layout with configurable spacing
    - Selection change callbacks
    - Consistent styling across chips
- **Usage**: Filter groups, category selection, tag management

#### `WasteCategoryBadge`
- **Description**: Specialized badge for waste categories with predefined colors
- **Key Features**:
    - Automatic color mapping for waste types
    - Category-specific icons
    - Consistent styling across the app
- **Usage**: Waste classification results, category indicators

#### `StatusBadge`
- **Description**: Status indicator with predefined states and colors
- **Key Features**:
    - Automatic color/icon mapping for common statuses
    - Consistent visual language for states
- **Usage**: Process status, completion indicators, error states

#### `ProgressBadge`
- **Description**: Circular progress indicator with text overlay
- **Key Features**:
    - Responsive sizing based on available space
    - Percentage display or custom text
    - Overflow protection for text
    - Customizable colors and stroke width
- **Usage**: Challenge progress, loading states, completion percentages

### 2. Button Components (`modern_buttons.dart`)

#### `ModernButton`
- **Description**: Enhanced button widget with multiple styles and animations
- **Key Features**:
    - Multiple styles: filled, outlined, text, glassmorphism
    - Three sizes: small, medium, large
    - Loading state with spinner
    - Icon support with automatic spacing
    - Scale animation on press
    - Tooltip support
    - Expanded width option
    - Custom child widget support
- **Usage**: Primary actions, navigation, form submissions

#### `ModernSearchBar`
- **Description**: Animated search input with modern styling
- **Key Features**:
    - Animated clear button (appears when text is entered)
    - Glassmorphism background effect
    - Search and clear callbacks
    - Autofocus option
    - Smooth fade animations
- **Usage**: Search functionality, filtering interfaces

#### `ModernFAB`
- **Description**: Floating Action Button with modern styling and animations
- **Key Features**:
    - Extended mode with label
    - Badge support for notifications
    - Scale animation on press
    - Custom colors and icons
    - Responsive design
- **Usage**: Primary floating actions, quick access features

#### `ViewAllButton`
- **Description**: Specialized responsive button that adapts from full text to icon-only
- **Key Features**:
    - Responsive text/icon switching based on available space
    - Smooth transitions between states
    - Consistent styling with other modern buttons
- **Usage**: "View All" actions in constrained spaces (See `docs/widgets/view_all_button.md`)

### 3. Card Components (`modern_cards.dart`)

#### `ModernCard`
- **Description**: Base card widget with modern styling and optional glassmorphism effect
- **Key Features**:
    - Glassmorphism effect with blur and opacity controls
    - Responsive padding and margins
    - Tap handling with haptic feedback
    - Customizable border radius and colors
    - Shadow and elevation support
- **Usage**: Base for all other card components, custom card layouts

#### `GlassmorphismCard`
- **Description**: Specialized card with glassmorphism effect
- **Key Features**:
    - Built-in blur effect
    - Transparent background with opacity control
    - Modern glass-like appearance
    - Customizable blur intensity
- **Usage**: Modern UI overlays, premium feature highlights

#### `FeatureCard`
- **Description**: Card for displaying features with icon and content
- **Key Features**:
    - Icon container with modern styling
    - Responsive title and subtitle
    - Adaptive padding based on screen width
    - Overflow protection for text
    - Optional trailing widget or chevron
    - Multi-line text support
- **Usage**: Quick actions, feature navigation, settings options

#### `StatsCard`
- **Description**: Card for displaying statistics with trend indicators
- **Key Features**:
    - Large value display with responsive font sizing
    - Trend indicators with color coding
    - Icon support with color theming
    - Responsive layout for narrow screens
    - Overflow protection for all text elements
- **Usage**: Dashboard statistics, metrics display, progress indicators

#### `ActionCard`
- **Description**: Card optimized for actionable content
- **Key Features**:
    - Prominent action button integration
    - Icon and content layout
    - Responsive design patterns
    - Consistent spacing and typography
- **Usage**: Call-to-action sections, feature promotions

#### `ActiveChallengeCard`
- **Description**: Specialized card for displaying active challenges
- **Key Features**:
    - Integrated progress indicators (circular and linear)
    - Responsive layout with 300px breakpoint
    - Challenge-specific styling and colors
    - Progress badge integration
    - Overflow protection for challenge descriptions
- **Usage**: Challenge displays, progress tracking, gamification

#### `RecentClassificationCard`
- **Description**: Card for displaying recent waste classification items
- **Key Features**:
    - Responsive layout with multiple breakpoints (300px, 200px)
    - Adaptive image display
    - Badge system for categories and properties
    - Overflow protection for all text elements
    - Classification-specific styling
- **Usage**: History lists, recent activity, classification results

## Styling Enums and Options

### Badge and Chip Styles
- **`ModernBadgeStyle`**: `filled`, `outlined`, `soft`, `glassmorphism`
- **`ModernBadgeSize`**: `small`, `medium`, `large`
- **`ModernChipStyle`**: `filled`, `outlined`, `soft`

### Button Styles
- **`ModernButtonStyle`**: `filled`, `outlined`, `text`, `glassmorphism`
- **`ModernButtonSize`**: `small`, `medium`, `large`

## Related Modern UI Components

### Components in Other Directories
While the core modern UI components are in `lib/widgets/modern_ui/`, several other widgets follow the same design principles:

#### `InteractiveTag` (`lib/widgets/interactive_tag.dart`)
- **Description**: Advanced tag system with multiple interaction modes
- **Key Features**: Category tags, filter tags, info tags, property tags with animations
- **Usage**: Waste classification tags, interactive filtering

#### `AnimatedFAB` (`lib/widgets/animated_fab.dart`)
- **Description**: Floating Action Button with advanced animations
- **Key Features**: Morphing animations, state transitions, custom icons
- **Usage**: Dynamic action buttons, context-sensitive actions

#### `ResponsiveText` (`lib/widgets/responsive_text.dart`)
- **Description**: Text widget that automatically adjusts to available space
- **Key Features**: Auto-sizing, overflow protection, responsive font scaling
- **Usage**: Dynamic text in constrained spaces

#### `EnhancedAnalysisLoader` (`lib/widgets/enhanced_analysis_loader.dart`)
- **Description**: Modern loading interface with educational content
- **Key Features**: Multi-step progress, particle animations, educational tips
- **Usage**: Analysis progress, long-running operations

#### `GenZMicrointeractions` (`lib/widgets/gen_z_microinteractions.dart`)
- **Description**: Modern micro-interactions and animations
- **Key Features**: Success animations, haptic feedback, smooth transitions
- **Usage**: User feedback, state changes, celebrations

## Implementation Guidelines

### Responsive Design Patterns
- Use `LayoutBuilder` for adaptive layouts
- Implement breakpoints at 200px, 300px for mobile optimization
- Provide fallback layouts for very narrow screens
- Use `FittedBox` and `Flexible` widgets for text overflow protection

### Animation Standards
- Use `AppTheme.animationFast` (150ms) for quick interactions
- Use `AppTheme.animationMedium` (300ms) for state changes
- Use `AppTheme.animationSlow` (500ms) for complex transitions
- Implement scale animations for button presses (0.95 scale)

### Color and Theming
- Follow Material Design 3 color system
- Use theme-aware colors from `Theme.of(context).colorScheme`
- Implement dark mode support automatically
- Use semantic colors for waste categories (defined in `AppTheme`)

### Accessibility Features
- Provide semantic labels for screen readers
- Ensure minimum touch target sizes (44px)
- Implement proper focus management
- Use sufficient color contrast ratios

## General Principles

- **Responsiveness**: All components adapt to different screen sizes using `LayoutBuilder` and flexible Flutter widgets
- **Theming**: Components follow Material Design 3 and app-specific theme (defined in `lib/utils/constants.dart`)
- **Modularity**: Designed for reusability across different parts of the application
- **Performance**: Optimized with proper widget lifecycle management and animation disposal
- **Accessibility**: Built-in support for screen readers, keyboard navigation, and touch accessibility
- **User Experience**: Focus on clarity, usability, and preventing common UI issues like text overflow

These modern UI components form the foundation of the application's design system, providing consistent, accessible, and performant building blocks for a rich user experience. 