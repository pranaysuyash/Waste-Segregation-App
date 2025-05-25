# Modern UI Components Overview

## Introduction

The Waste Segregation App incorporates a suite of custom "Modern UI" components designed to provide a consistent, responsive, and aesthetically pleasing user experience. These components are generally located in the `lib/widgets/modern_ui/` directory and often leverage Flutter's `LayoutBuilder` for adaptive behavior.

This document provides a high-level overview of these components. More detailed documentation for specific complex components may be available in separate files (e.g., `view_all_button.md`).

## Core Modern UI Widgets

### 1. `ModernBadge`
- **File**: `lib/widgets/modern_ui/modern_badges.dart`
- **Description**: A versatile badge widget used for displaying statuses, percentages (e.g., challenge progress), or small pieces of information. 
- **Key Features**:
    - Responsive sizing (adapts to available space).
    - Dynamic font sizing for internal text.
    - Customizable colors, icons, and text.
    - Support for progress display (circular).
    - Overflow protection.
- **Usage**: Challenge progress indicators, status tags for classification items.

### 2. `ModernButton`
- **File**: `lib/widgets/modern_ui/modern_buttons.dart`
- **Description**: An enhanced button widget providing various styles and features beyond Flutter's standard buttons.
- **Key Features**:
    - Multiple constructors for different styles (e.g., primary, secondary, outlined, text-only, icon-only).
    - Loading state indicator.
    - Customizable size, color, shape, and elevation.
    - Tooltip support.
    - **`ViewAllButton`**: A specialized variant of `ModernButton` that responsively adapts from full text to icon-only. (See `docs/widgets/view_all_button.md`)
- **Usage**: Used extensively throughout the app for actions, navigation, and calls to action.

### 3. `ModernCard` (and its variants)
- **File**: `lib/widgets/modern_ui/modern_cards.dart`
- **Description**: A base class and a collection of specialized card widgets for displaying various types of content in a structured and visually appealing manner.
- **Common Features**: Responsive layouts, consistent padding and theming, tap handling.

#### Card Variants:

- **`StatsCard`**:
    - **Purpose**: Displays key statistics like classifications, streaks, and points.
    - **Features**: Responsive layout for text and trend chips, dynamic font sizing for values, vertical fallback for very narrow cards.

- **`FeatureCard` (Quick Action Card)**:
    - **Purpose**: Used for quick actions like navigating to "Analytics" or "Learn About Waste".
    - **Features**: Responsive title and subtitle, adaptive padding, multi-line text support with ellipsis.

- **`ActiveChallengeCard`**:
    - **Purpose**: Displays a preview of an active user challenge.
    - **Features**: Responsive layout (with a 300px breakpoint), text overflow protection, integrated `ProgressBadge` and linear progress bar, flexible content handling.

- **`RecentClassificationCard`**:
    - **Purpose**: Displays an item from the user's recent classification history.
    - **Features**: Responsive layout (300px and 200px breakpoints), overflow protection for all text elements, adaptive image display, responsive badge system for categories and properties (recyclable, compostable).

- **Other Generic Card Styles**: The `ModernCard` base can be used to create other custom card layouts with consistent styling.

- **Usage**: Home screen dashboard, history lists, feature showcases.

## General Principles

- **Responsiveness**: Most modern UI components are designed to be responsive, adapting to different screen sizes and orientations using `LayoutBuilder` and flexible Flutter widgets.
- **Theming**: Components adhere to the application's theme (defined in `lib/utils/constants.dart` -> `AppTheme`) for colors, fonts, and spacing.
- **Modularity**: Designed to be reusable and easily integrated into various parts of the application.
- **User Experience**: Focus on clarity, usability, and preventing common UI issues like text overflow.

These modern UI components are central to the application's user interface, providing the building blocks for a rich and adaptive experience. 