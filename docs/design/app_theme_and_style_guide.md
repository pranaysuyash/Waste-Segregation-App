# App Theme and Style Guide

## Overview
This document defines the visual language for the Waste Segregation App, ensuring consistency across all screens and components. It provides guidelines for colors, typography, spacing, and UI components, with special attention to handling different subscription tiers visually.

## Color System

### Primary Palette
- **Primary Green**: #4CAF50 (RGB: 76, 175, 80)
  - Used for: Primary buttons, key icons, progress indicators
- **Secondary Blue**: #2196F3 (RGB: 33, 150, 243)
  - Used for: Secondary actions, links, highlights
- **Warning Orange**: #FF9800 (RGB: 255, 152, 0)
  - Used for: Alerts, important notifications
- **Error Red**: #F44336 (RGB: 244, 67, 54)
  - Used for: Error states, critical warnings

### Category Colors
- **Wet Waste**: #8BC34A (Light Green)
- **Dry Waste**: #FFC107 (Amber)
- **Hazardous Waste**: #FF5722 (Deep Orange)
- **Medical Waste**: #E91E63 (Pink)
- **Non-Waste**: #9C27B0 (Purple)

### Neutrals
- **Background Light**: #FFFFFF
- **Background Dark**: #121212
- **Text Primary Light**: #212121 (87% black)
- **Text Secondary Light**: #757575 (54% black)
- **Text Primary Dark**: #FFFFFF (100% white)
- **Text Secondary Dark**: #B0BEC5 (70% white)

### Subscription Tier Indicators
- **Free Tier**: No special indicator
- **Premium Tier**: #FFD700 (Gold) for badges and highlights
- **Pro Tier**: #00BCD4 (Cyan) with #E040FB (Purple) accents

### Theme Variations
- **Light Theme**: Default for free users
- **Dark Theme**: Available to Premium and Pro users
- **Custom Themes**: Available only to Pro users
  - Eco Theme (Green-focused)
  - Ocean Theme (Blue-focused)
  - Forest Theme (Earth tones)

## Typography

### Font Family
- **Primary**: Roboto
- **Secondary** (Pro tier only): Montserrat

### Text Styles
- **Heading 1**: 24sp, Medium (500), 1.2 line height
- **Heading 2**: 20sp, Medium (500), 1.2 line height
- **Heading 3**: 18sp, Medium (500), 1.3 line height
- **Subtitle**: 16sp, Medium (500), 1.3 line height
- **Body**: 14sp, Regular (400), 1.5 line height
- **Caption**: 12sp, Regular (400), 1.4 line height
- **Button**: 14sp, Medium (500), ALL CAPS

## Iconography

### Style Guidelines
- **Line weight**: 2dp consistent stroke
- **Corner radius**: 2dp for angular corners
- **Size**: 24x24dp standard, 20x20dp compact

### Custom Icons
- **Waste Type Icons**:
  - Wet Waste: Leaf icon
  - Dry Waste: Recycle icon
  - Hazardous Waste: Warning icon
  - Medical Waste: Medical cross icon
  - Non-Waste: Reuse icon

- **Premium Feature Indicators**:
  - Premium-only feature: Gold lock icon
  - Pro-only feature: Cyan/purple star icon

## Spacing System

### Base Unit
- 8dp as base unit

### Spacing Scale
- **Tiny**: 4dp (half-unit)
- **Small**: 8dp (1x)
- **Medium**: 16dp (2x)
- **Large**: 24dp (3x)
- **Extra Large**: 32dp (4x)
- **Huge**: 48dp (6x)

### Component Spacing
- **Card padding**: 16dp
- **List item padding**: 16dp vertical, 16dp horizontal
- **Section spacing**: 24dp
- **Screen margins**: 16dp

## Component States

### Buttons
- **Default**: Solid fill, 8dp rounded corners
- **Hover/Focused**: Slight overlay (8% white)
- **Pressed**: Darker overlay (12% black)
- **Disabled**: 38% opacity, no interaction

### Input Fields
- **Default**: Outlined with 4dp rounded corners
- **Focused**: Filled bottom border, primary color
- **Error**: Error color, error message below
- **Disabled**: 38% opacity, no interaction

## Premium Feature Styling

### Visual Indicators for Tiered Features
- **Free Features**: Standard styling
- **Premium Features**: 
  - Gold accent line or icon badge
  - "Premium" label where applicable
  - Unlock icon for unavailable features
- **Pro Features**:
  - Cyan/purple gradient accent
  - "Pro" label where appropriate
  - Star lock icon for unavailable features

### Upgrade Prompts
- **Subtle Indicators**: Small badge on feature icons
- **Contextual Prompts**: Banner appears when attempting to use higher-tier feature
- **Upgrade Buttons**: Prominent CTA with tier-specific color

## UI Components for Classification Pipeline

### Image Capture Screen
- Clean, minimal interface with large viewfinder
- Camera controls at bottom (capture, gallery, flash)
- Simple instructions overlay for best results

### Analysis Screen
- Clear preview of selected image
- Segmentation toggle - visually distinct based on tier:
  - Free: Basic toggle (disabled with upgrade prompt)
  - Premium: "Auto-Segment" toggle (enabled)
  - Pro: "Segment" dropdown with options (Auto/Interactive)
- Interactive segmentation tools (Pro tier):
  - Object selection tool: Cyan highlight on tap
  - Boundary refinement: Purple editing handles
  - Component analysis: Dotted boundary indicators

### Results Screen
- Material card with category color accent
- Structured information sections with clear hierarchy
- Disposal instructions with iconography
- Share/save buttons with consistent positioning
- Feedback collection UI (for AI accuracy)
- Dynamic recycling code display

## Implementation in Flutter

### ThemeData Configuration
```dart
// Pseudocode for theme implementation
ThemeData buildAppTheme(SubscriptionTier tier) {
  // Base theme values
  final baseTheme = ThemeData(
    primaryColor: AppColors.primaryGreen,
    // Other base theme properties
  );
  
  // Apply tier-specific modifications
  switch (tier) {
    case SubscriptionTier.free:
      return baseTheme;
    case SubscriptionTier.premium:
      return baseTheme.copyWith(
        // Premium enhancements
      );
    case SubscriptionTier.pro:
      return baseTheme.copyWith(
        // Pro enhancements
      );
  }
}
```

### Custom Theme Extensions
```dart
// Pseudocode for custom theme extensions
extension AppThemeExtension on ThemeData {
  Color get categoryWetWaste => AppColors.wetWaste;
  Color get categoryDryWaste => AppColors.dryWaste;
  // Other custom theme properties
  
  Color getPremiumIndicatorColor(SubscriptionTier userTier, SubscriptionTier requiredTier) {
    // Return appropriate color based on access level
  }
}
```

## Responsive Design Guidelines

### Device Categories
- **Phone**: < 600dp width
- **Small Tablet**: 600-840dp width
- **Large Tablet/Desktop**: > 840dp width

### Layout Adjustments
- Phone: Single column layout, full-width cards
- Small Tablet: Two-column grid where appropriate
- Large Tablet/Desktop: Multi-column layout with sidebars

### Component Adaptations
- **Results Screen**: 
  - Phone: Vertical stack of sections
  - Tablet: Two-column layout with image and core info in first column
- **Educational Content**: 
  - Phone: Full-width cards in a vertical list
  - Tablet: Grid layout with larger previews

## Accessibility Guidelines

### Color Contrast
- Maintain minimum 4.5:1 contrast ratio for text
- Use color + icon/text for status indicators, never color alone
- Test all themes with accessibility tools

### Touch Targets
- Minimum size of 48x48dp for all interactive elements
- Adequate spacing between touchable elements (at least 8dp)

### Text Scaling
- All text should support dynamic sizing up to 200%
- Layouts should adapt to larger text sizes without overflow

## Premium Visual Details

### Premium Tier Visual Enhancements
- Subtle gold accents on cards and buttons
- Enhanced animations for rewards
- Custom progress indicators

### Pro Tier Visual Enhancements
- Cyan/purple dual-color accents
- Advanced transition animations
- Custom interface options (adjustable density, etc.)
- Interactive visual effects for segmentation

## Implementation Priorities

1. **Core Theme Implementation**:
   - Base color system and typography
   - Essential component styles
   - Basic responsive layouts

2. **Tier Indicator System**:
   - Visual language for premium features
   - Upgrade prompt styling
   - Badge and lock icons

3. **Enhanced UI for Premium Features**:
   - Auto-segmentation interface
   - Advanced result displays
   - Premium content styling

4. **Pro UI Elements**:
   - Interactive segmentation tools
   - Component analysis interface
   - Custom theme controls

## Conclusion

This style guide ensures a consistent, high-quality visual experience across the app while clearly communicating the value of premium features. By establishing a distinctive visual language for each subscription tier, we enhance the perceived value of upgrades while maintaining a clean, intuitive interface for all users.

The guidelines are designed to be implementable in phases, with core styling implemented first, followed by tier-specific enhancements. This approach aligns with the feature development roadmap and supports the monetization strategy.
