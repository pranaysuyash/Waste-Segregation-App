# Design Document: Frontend Issues Analysis & Resolution

## Overview

This design document provides comprehensive solutions for frontend issues in the Waste Segregation Flutter application. It addresses UI rendering problems, design system inconsistencies, animation improvements, user flow optimizations, and architectural enhancements to create a polished, performant, and delightful user experience.

### Goals

1. **Fix Critical Rendering Issues** - Eliminate overflow errors, improve responsive layouts
2. **Establish Consistent Design System** - Unified colors, typography, spacing, and components
3. **Enhance Animations** - Add delightful micro-interactions and smooth transitions
4. **Optimize User Flows** - Streamline navigation and task completion
5. **Improve Performance** - Faster load times, smoother scrolling, better perceived performance
6. **Ensure Accessibility** - WCAG 2.1 AA compliance for inclusive design

## Architecture

### Design System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Design System Layer                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Tokens     │  │    Themes    │  │  Components  │      │
│  │              │  │              │  │              │      │
│  │ • Colors     │  │ • Light      │  │ • Atoms      │      │
│  │ • Spacing    │  │ • Dark       │  │ • Molecules  │      │
│  │ • Typography │  │ • High       │  │ • Organisms  │      │
│  │ • Shadows    │  │   Contrast   │  │ • Templates  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                      Screen Layer                            │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Home → Capture → Analysis → Results → History              │
│    ↓       ↓         ↓          ↓         ↓                 │
│  Uses design system components and tokens                    │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Component Hierarchy (Atomic Design)

```
Atoms (Basic building blocks)
├── Buttons (Primary, Secondary, Text, Icon)
├── Text (Headings, Body, Labels, Captions)
├── Icons (Material, Custom)
├── Inputs (TextField, Checkbox, Radio, Switch)
└── Indicators (Progress, Loading, Badge)

Molecules (Simple combinations)
├── Cards (Info, Action, Stats)
├── List Items (Classification, Achievement, History)
├── Form Fields (Labeled inputs with validation)
├── Chips (Category, Filter, Tag)
└── Dialogs (Alert, Confirmation, Info)

Organisms (Complex components)
├── Navigation (Bottom Nav, App Bar, Drawer)
├── Headers (Home Header, Screen Headers)
├── Lists (Classification List, Achievement Grid)
├── Forms (Feedback Form, Settings Form)
└── Charts (Bar, Line, Pie, Donut)

Templates (Page layouts)
├── Single Column (Mobile)
├── Two Column (Tablet)
├── Master-Detail (Wide screens)
└── Grid Layout (Gallery, Achievements)
```

## Components and Interfaces

### 1. Design Token System

#### Color Palette

```dart
class DesignTokens {
  // Primary Colors (Eco-Green Theme)
  static const Color primary50 = Color(0xFFE8F5E9);
  static const Color primary100 = Color(0xFFC8E6C9);
  static const Color primary200 = Color(0xFFA5D6A7);
  static const Color primary300 = Color(0xFF81C784);
  static const Color primary400 = Color(0xFF66BB6A);
  static const Color primary500 = Color(0xFF4CAF50);  // Main primary
  static const Color primary600 = Color(0xFF43A047);
  static const Color primary700 = Color(0xFF388E3C);
  static const Color primary800 = Color(0xFF2E7D32);
  static const Color primary900 = Color(0xFF1B5E20);
  
  // Secondary Colors (Ocean Blue)
  static const Color secondary50 = Color(0xFFE3F2FD);
  static const Color secondary100 = Color(0xFFBBDEFB);
  static const Color secondary200 = Color(0xFF90CAF9);
  static const Color secondary300 = Color(0xFF64B5F6);
  static const Color secondary400 = Color(0xFF42A5F5);
  static const Color secondary500 = Color(0xFF2196F3);  // Main secondary
  static const Color secondary600 = Color(0xFF1E88E5);
  static const Color secondary700 = Color(0xFF1976D2);
  static const Color secondary800 = Color(0xFF1565C0);
  static const Color secondary900 = Color(0xFF0D47A1);
  
  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Waste Category Colors (Vibrant & Accessible)
  static const Color wetWaste = Color(0xFF06FFA5);      // Vibrant Green
  static const Color dryWaste = Color(0xFF00B4D8);      // Ocean Blue
  static const Color hazardousWaste = Color(0xFFFF6B6B); // Sunset Coral
  static const Color medicalWaste = Color(0xFF845EC2);   // Digital Purple
  static const Color nonWaste = Color(0xFFFF8AC1);       // Soft Pink
  
  // Neutral Colors
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral800 = Color(0xFF424242);
  static const Color neutral900 = Color(0xFF212121);
}
```

#### Spacing System (8pt Grid)

```dart
class Spacing {
  static const double xs = 4.0;   // 0.5 units
  static const double sm = 8.0;   // 1 unit
  static const double md = 16.0;  // 2 units
  static const double lg = 24.0;  // 3 units
  static const double xl = 32.0;  // 4 units
  static const double xxl = 48.0; // 6 units
  static const double xxxl = 64.0; // 8 units
}
```

#### Typography Scale

```dart
class Typography {
  // Display (Large headings)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57.0,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 45.0,
    fontWeight: FontWeight.w400,
    height: 1.16,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontSize: 36.0,
    fontWeight: FontWeight.w400,
    height: 1.22,
  );
  
  // Headline (Section headings)
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.w400,
    height: 1.25,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.w400,
    height: 1.29,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w400,
    height: 1.33,
  );
  
  // Title (Card titles, list headers)
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.w400,
    height: 1.27,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.50,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  // Body (Main content)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );
  
  // Label (Buttons, chips)
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );
}
```

#### Elevation and Shadows

```dart
class Elevation {
  static const double level0 = 0.0;
  static const double level1 = 1.0;
  static const double level2 = 3.0;
  static const double level3 = 6.0;
  static const double level4 = 8.0;
  static const double level5 = 12.0;
  
  static List<BoxShadow> getShadow(double level) {
    switch (level) {
      case 1:
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ];
      case 2:
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
      case 3:
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ];
      case 4:
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ];
      case 5:
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ];
      default:
        return [];
    }
  }
}
```

### 2. Animation System

#### Animation Durations and Curves

```dart
class AnimationTokens {
  // Durations
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 700);
  
  // Curves
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve spring = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;
  
  // Standard transitions
  static const Curve standardCurve = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Curve decelerateCurve = Cubic(0.0, 0.0, 0.2, 1.0);
  static const Curve accelerateCurve = Cubic(0.4, 0.0, 1.0, 1.0);
}
```

#### Micro-interaction Patterns

```dart
// Button Press Animation
class ButtonPressAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.95).animate(
          CurvedAnimation(
            parent: _controller,
            curve: AnimationTokens.fast,
          ),
        ),
        child: child,
      ),
    );
  }
}

// Shimmer Loading Effect
class ShimmerLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// Achievement Celebration Animation
class AchievementCelebration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti particles
        ConfettiWidget(
          blastDirectionality: BlastDirectionality.explosive,
          particleDrag: 0.05,
          emissionFrequency: 0.05,
          numberOfParticles: 50,
          gravity: 0.1,
        ),
        // Scale and fade animation for achievement card
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _controller,
            curve: Curves.elasticOut,
          ),
          child: FadeTransition(
            opacity: _controller,
            child: AchievementCard(),
          ),
        ),
      ],
    );
  }
}
```

### 3. Responsive Layout System

#### Breakpoints

```dart
class Breakpoints {
  static const double mobile = 0;
  static const double mobileLarge = 360;
  static const double tablet = 600;
  static const double tabletLarge = 840;
  static const double desktop = 1024;
  static const double desktopLarge = 1440;
  
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tablet;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tablet && width < desktop;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }
}
```

#### Responsive Layout Builder

```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.desktop) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= Breakpoints.tablet) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
```

## Data Models

### UI State Models

```dart
// Loading State
enum LoadingState {
  idle,
  loading,
  success,
  error,
}

class UIState<T> {
  final LoadingState state;
  final T? data;
  final String? error;
  
  const UIState({
    required this.state,
    this.data,
    this.error,
  });
  
  bool get isLoading => state == LoadingState.loading;
  bool get hasData => data != null;
  bool get hasError => error != null;
}

// Navigation State
class NavigationState {
  final int currentIndex;
  final List<String> history;
  final Map<String, dynamic> arguments;
  
  const NavigationState({
    required this.currentIndex,
    required this.history,
    required this.arguments,
  });
}

// Animation State
class AnimationState {
  final bool isAnimating;
  final double progress;
  final AnimationType type;
  
  const AnimationState({
    required this.isAnimating,
    required this.progress,
    required this.type,
  });
}

enum AnimationType {
  fade,
  slide,
  scale,
  rotate,
  custom,
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property Reflection

After analyzing all 175 acceptance criteria, I've identified the following patterns:

**Redundancy Elimination:**
- Properties 1.1-1.5 (rendering) can be consolidated into comprehensive layout validation
- Properties 11.1-11.5 (design system) overlap with specific spacing/color properties
- Properties 18.1-18.5 (spacing) are specific instances of 11.1 (spacing system)
- Performance timing properties (8.1-8.3, 5.1, 4.4) are difficult to unit test and better suited for integration tests

**Property Consolidation:**
- Combine all spacing properties into one comprehensive spacing compliance property
- Combine all color properties into one palette compliance property
- Combine all typography properties into one typography system property
- Combine accessibility properties into comprehensive WCAG compliance property

**Unique Value Properties:**
After consolidation, we have 45 unique, testable properties that provide comprehensive validation coverage.

### Correctness Properties

#### UI Rendering Properties

**Property 1: Layout Boundary Compliance**
*For any* screen configuration and content, all UI elements should render within their container boundaries without overflow errors
**Validates: Requirements 1.1, 1.2, 1.3**

**Property 2: Responsive Layout Adaptation**
*For any* screen size and orientation, the layout should adapt appropriately using breakpoint-specific configurations
**Validates: Requirements 1.4, 1.5, 6.1, 6.2, 6.5**

**Property 3: Text Truncation Consistency**
*For any* text widget with constrained space, text should either wrap or truncate with ellipsis, never overflow
**Validates: Requirements 1.2**

#### Home Screen Properties

**Property 4: Home Screen Structure**
*For any* user state, the home screen should display stats, quick actions, and recent activity sections in the correct hierarchy
**Validates: Requirements 2.1**

**Property 5: Progressive Loading**
*For any* async data loading, the UI should remain interactive and show loading states without blocking
**Validates: Requirements 2.2**

**Property 6: Navigation Debouncing**
*For any* rapid button taps, only one navigation event should be triggered
**Validates: Requirements 2.5, 10.5**

#### Classification Result Properties

**Property 7: Feedback Widget Visibility**
*For any* classification, the feedback widget should be visible if and only if it's a new classification (not from history)
**Validates: Requirements 3.2**

**Property 8: Feedback Submission Round Trip**
*For any* feedback submission, the UI should update immediately and the feedback should be persisted correctly
**Validates: Requirements 3.3**

**Property 9: Progressive Disclosure**
*For any* long content (disposal instructions, explanations), expandable sections should be used
**Validates: Requirements 3.4**

#### History Screen Properties

**Property 10: Pagination Consistency**
*For any* history data set, items should be loaded in batches of exactly 20
**Validates: Requirements 4.1**

**Property 11: Infinite Scroll Behavior**
*For any* scroll to bottom event, more items should load automatically without blocking the UI
**Validates: Requirements 4.2**

**Property 12: Filter State Preservation**
*For any* filter application, the scroll position should be preserved unless the filtered results require reset
**Validates: Requirements 4.3**

#### Image Capture Properties

**Property 13: Analysis Cancellation**
*For any* analysis in progress, cancellation should immediately stop the operation and return to the previous screen
**Validates: Requirements 5.5**

#### Responsive Design Properties

**Property 14: Touch Target Compliance**
*For any* interactive button or element, the minimum touch target size should be 44x44dp
**Validates: Requirements 6.4**

**Property 15: Text Scaling Adaptation**
*For any* text element, font sizes should scale appropriately based on screen size and user preferences
**Validates: Requirements 6.3**

#### Accessibility Properties

**Property 16: Semantic Label Coverage**
*For any* interactive element, semantic labels should be provided for screen readers
**Validates: Requirements 7.1**

**Property 17: Keyboard Navigation Support**
*For any* focusable element, tab navigation should work correctly in logical order
**Validates: Requirements 7.2**

**Property 18: Color Independence**
*For any* information conveyed by color, alternative indicators (icons, text) should also be present
**Validates: Requirements 7.3**

**Property 19: Contrast Ratio Compliance**
*For any* text on colored background, the contrast ratio should meet WCAG AA standards (4.5:1 for normal text)
**Validates: Requirements 7.4**

**Property 20: Reduced Motion Respect**
*For any* animation, it should be disabled or reduced when user's reduced motion preference is enabled
**Validates: Requirements 7.5**

#### Performance Properties

**Property 21: Image Caching Effectiveness**
*For any* image loaded multiple times, subsequent loads should use cache and not make redundant network requests
**Validates: Requirements 8.4**

#### Error Handling Properties

**Property 22: User-Friendly Error Messages**
*For any* error occurrence, the error message should be user-friendly and provide actionable guidance
**Validates: Requirements 9.1**

**Property 23: Network Error Recovery**
*For any* network request failure, retry options should be provided without crashing
**Validates: Requirements 9.2**

**Property 24: Validation Feedback**
*For any* validation failure, problematic fields should be highlighted with clear error messages
**Validates: Requirements 9.3**

**Property 25: Success Feedback**
*For any* successful operation, positive feedback should be provided (snackbar, animation, or confirmation)
**Validates: Requirements 9.4**

**Property 26: Offline Status Indication**
*For any* offline state, the app should clearly indicate offline status and available offline features
**Validates: Requirements 9.5**

#### Navigation Properties

**Property 27: State Preservation**
*For any* back navigation, the previous screen state should be preserved appropriately
**Validates: Requirements 10.1**

**Property 28: Tab State Maintenance**
*For any* tab switch, the tab state should be maintained without unnecessary reloading
**Validates: Requirements 10.2**

**Property 29: Deep Link Routing**
*For any* deep link URL, the app should navigate to the correct screen with proper context
**Validates: Requirements 10.3**

**Property 30: Lifecycle State Management**
*For any* app backgrounding and foregrounding, state should be saved and restored correctly
**Validates: Requirements 10.4**

#### Design System Properties

**Property 31: Spacing System Compliance**
*For any* UI element, spacing values should be multiples of 8dp from the design system
**Validates: Requirements 11.1, 18.1, 18.2, 18.3, 18.4, 18.5**

**Property 32: Color Palette Compliance**
*For any* color usage, colors should come from the defined design token palette
**Validates: Requirements 11.2, 13.1, 13.3, 13.4**

**Property 33: Typography Consistency**
*For any* text element, typography should match design system specifications (font family, size, weight)
**Validates: Requirements 11.3, 19.1, 19.2, 19.4**

**Property 34: Container Styling Consistency**
*For any* card or container, border radius and elevation should match design system tokens
**Validates: Requirements 11.4**

**Property 35: Icon Set Consistency**
*For any* icon usage, icons should come from the consistent icon set with uniform sizing
**Validates: Requirements 11.5, 17.1, 17.2**

#### Animation Properties

**Property 36: Button Feedback Animation**
*For any* button tap, ripple or scale feedback animation should be provided
**Validates: Requirements 12.1**

**Property 37: Screen Transition Animation**
*For any* screen navigation, appropriate transition animations should be used
**Validates: Requirements 12.2**

**Property 38: Loading State Animation**
*For any* data loading, skeleton screens or shimmer effects should be displayed
**Validates: Requirements 12.3, 16.3, 20.1**

**Property 39: List Animation**
*For any* list update (insertion/removal), items should animate smoothly
**Validates: Requirements 12.5**

#### Theme Properties

**Property 40: Dark Mode Contrast**
*For any* dark mode activation, colors should have sufficient contrast for readability
**Validates: Requirements 13.2**

**Property 41: Theme Transition Smoothness**
*For any* theme change, the transition should be smooth without jarring flashes
**Validates: Requirements 13.5**

#### Empty State Properties

**Property 42: Empty State Presence**
*For any* screen with no data, an illustrative empty state with clear messaging should be displayed
**Validates: Requirements 16.1**

**Property 43: Empty State Actionability**
*For any* empty state, actionable next steps or CTAs should be provided
**Validates: Requirements 16.2**

**Property 44: Error State Recovery**
*For any* error preventing data display, error states with retry options should be shown
**Validates: Requirements 16.4**

#### Loading State Properties

**Property 45: Progress Indication**
*For any* operation taking longer than 2 seconds, progress indication should be shown
**Validates: Requirements 20.2**

## Error Handling

### Error Categories and Handling Strategies

```dart
enum ErrorCategory {
  network,
  validation,
  permission,
  storage,
  rendering,
  unknown,
}

class ErrorHandler {
  static String getUserFriendlyMessage(ErrorCategory category, dynamic error) {
    switch (category) {
      case ErrorCategory.network:
        return 'Network connection issue. Please check your internet and try again.';
      case ErrorCategory.validation:
        return 'Please check your input and try again.';
      case ErrorCategory.permission:
        return 'Permission required. Please grant access in settings.';
      case ErrorCategory.storage:
        return 'Storage error. Please ensure you have enough space.';
      case ErrorCategory.rendering:
        return 'Display error. Please try refreshing the screen.';
      case ErrorCategory.unknown:
        return 'Something went wrong. Please try again.';
    }
  }
  
  static Widget buildErrorWidget(ErrorCategory category, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getErrorIcon(category),
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            getUserFriendlyMessage(category, null),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  static IconData _getErrorIcon(ErrorCategory category) {
    switch (category) {
      case ErrorCategory.network:
        return Icons.wifi_off;
      case ErrorCategory.validation:
        return Icons.error_outline;
      case ErrorCategory.permission:
        return Icons.lock_outline;
      case ErrorCategory.storage:
        return Icons.storage;
      case ErrorCategory.rendering:
        return Icons.broken_image;
      case ErrorCategory.unknown:
        return Icons.help_outline;
    }
  }
}
```

### Error Recovery Patterns

```dart
// Retry with exponential backoff
class RetryStrategy {
  static Future<T> withExponentialBackoff<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) rethrow;
        
        final delay = initialDelay * math.pow(2, attempt - 1);
        await Future.delayed(delay);
      }
    }
  }
}

// Graceful degradation
class GracefulDegradation {
  static Widget buildWithFallback({
    required Widget Function() primary,
    required Widget Function() fallback,
  }) {
    try {
      return primary();
    } catch (e) {
      return fallback();
    }
  }
}
```

## Testing Strategy

### Unit Testing Approach

**Test Coverage Goals:**
- 80%+ code coverage for UI components
- 100% coverage for design system tokens and utilities
- 90%+ coverage for error handling logic

**Testing Framework:**
- Flutter Test for widget testing
- Mockito for mocking dependencies
- Golden tests for visual regression

**Property-Based Testing:**
- Use `package:test` with custom generators
- Minimum 100 iterations per property test
- Focus on properties that validate design system compliance

### Property-Based Test Structure

```dart
import 'package:test/test.dart';
import 'package:flutter_test/flutter_test.dart';

// Example property test for spacing compliance
void main() {
  group('Design System Properties', () {
    test('Property 31: Spacing System Compliance', () {
      // **Feature: frontend-issues-analysis, Property 31: Spacing System Compliance**
      
      // Generate random UI configurations
      for (int i = 0; i < 100; i++) {
        final spacing = generateRandomSpacing();
        
        // Verify spacing is multiple of 8
        expect(spacing % 8, equals(0),
          reason: 'Spacing $spacing is not a multiple of 8dp');
      }
    });
    
    test('Property 32: Color Palette Compliance', () {
      // **Feature: frontend-issues-analysis, Property 32: Color Palette Compliance**
      
      // Generate random color usages
      for (int i = 0; i < 100; i++) {
        final color = generateRandomColorUsage();
        
        // Verify color exists in design tokens
        expect(DesignTokens.isValidColor(color), isTrue,
          reason: 'Color $color is not from design token palette');
      }
    });
  });
}
```

### Visual Regression Testing

```dart
// Golden test for home screen
testWidgets('Home screen matches golden', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: UnifiedHomeScreen()),
  );
  
  await expectLater(
    find.byType(UnifiedHomeScreen),
    matchesGoldenFile('goldens/home_screen.png'),
  );
});

// Golden test for dark mode
testWidgets('Home screen dark mode matches golden', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: UnifiedHomeScreen(),
    ),
  );
  
  await expectLater(
    find.byType(UnifiedHomeScreen),
    matchesGoldenFile('goldens/home_screen_dark.png'),
  );
});
```

### Accessibility Testing

```dart
testWidgets('All buttons meet minimum touch target size', (tester) async {
  // **Feature: frontend-issues-analysis, Property 14: Touch Target Compliance**
  
  await tester.pumpWidget(MaterialApp(home: UnifiedHomeScreen()));
  
  final buttons = find.byType(ElevatedButton);
  for (int i = 0; i < buttons.evaluate().length; i++) {
    final button = buttons.at(i);
    final size = tester.getSize(button);
    
    expect(size.width, greaterThanOrEqualTo(44.0));
    expect(size.height, greaterThanOrEqualTo(44.0));
  }
});

testWidgets('All text meets contrast requirements', (tester) async {
  // **Feature: frontend-issues-analysis, Property 19: Contrast Ratio Compliance**
  
  await tester.pumpWidget(MaterialApp(home: UnifiedHomeScreen()));
  
  // Find all Text widgets
  final textWidgets = find.byType(Text);
  for (int i = 0; i < textWidgets.evaluate().length; i++) {
    final text = textWidgets.at(i);
    final textColor = getTextColor(text);
    final backgroundColor = getBackgroundColor(text);
    
    final contrastRatio = calculateContrastRatio(textColor, backgroundColor);
    expect(contrastRatio, greaterThanOrEqualTo(4.5));
  }
});
```

## Implementation Priorities

### Phase 1: Critical Fixes (Week 1-2)
1. Fix overflow errors and rendering issues
2. Implement responsive layout system
3. Add proper error handling and recovery
4. Fix navigation state management

### Phase 2: Design System (Week 3-4)
1. Establish design tokens (colors, spacing, typography)
2. Create atomic components library
3. Implement consistent theming
4. Add dark mode support

### Phase 3: Animations & Polish (Week 5-6)
1. Add micro-interactions to buttons
2. Implement screen transitions
3. Add loading state animations
4. Create achievement celebrations

### Phase 4: Accessibility & Performance (Week 7-8)
1. Add semantic labels
2. Implement keyboard navigation
3. Optimize image loading and caching
4. Add performance monitoring

### Phase 5: Advanced Features (Week 9-10)
1. Implement offline support
2. Add progressive disclosure
3. Create contextual suggestions
4. Optimize user flows

## Migration Strategy

### Gradual Migration Approach

```dart
// Step 1: Create new design system alongside old constants
// lib/design_system/tokens.dart
class DesignTokens {
  // New design system
}

// Step 2: Create adapter to map old constants to new tokens
class DesignSystemAdapter {
  static Color getPrimaryColor() {
    return DesignTokens.primary500; // Maps AppTheme.primaryColor
  }
}

// Step 3: Gradually migrate screens one by one
// Old: AppTheme.primaryColor
// New: DesignTokens.primary500

// Step 4: Remove old constants once migration is complete
```

### Component Migration Pattern

```dart
// Before: Inconsistent button styling
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    padding: EdgeInsets.all(16),
  ),
  child: Text('Submit'),
)

// After: Using design system
DSButton.primary(
  label: 'Submit',
  onPressed: () {},
)

// Design system button component
class DSButton extends StatelessWidget {
  static Widget primary({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: DesignTokens.primary500,
        padding: EdgeInsets.all(Spacing.md),
        minimumSize: Size(44, 44), // WCAG compliance
      ),
      onPressed: onPressed,
      child: Text(label, style: Typography.labelLarge),
    );
  }
}
```

## Performance Optimization Strategies

### 1. Widget Optimization

```dart
// Use const constructors
const Text('Hello'); // ✓ Good
Text('Hello');       // ✗ Avoid

// Use RepaintBoundary for expensive widgets
RepaintBoundary(
  child: ExpensiveWidget(),
)

// Use ListView.builder for long lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

### 2. Image Optimization

```dart
// Use cached network images
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => ShimmerPlaceholder(),
  errorWidget: (context, url, error) => ErrorPlaceholder(),
)

// Optimize image size
Image.network(
  url,
  width: 200,
  height: 200,
  cacheWidth: 400, // 2x for retina displays
  cacheHeight: 400,
)
```

### 3. State Management Optimization

```dart
// Use selective rebuilds with Consumer
Consumer<Model>(
  builder: (context, model, child) {
    return Text(model.value);
  },
  child: ExpensiveStaticWidget(), // Won't rebuild
)

// Use ChangeNotifierProvider for granular updates
ChangeNotifierProvider(
  create: (_) => MyModel(),
  child: MyApp(),
)
```

## Monitoring and Analytics

### Performance Metrics

```dart
class PerformanceMonitor {
  static void trackScreenLoad(String screenName, Duration duration) {
    FirebasePerformance.instance
      .newTrace('screen_load_$screenName')
      ..setMetric('duration_ms', duration.inMilliseconds)
      ..start()
      ..stop();
  }
  
  static void trackFrameRate(String screenName, double fps) {
    FirebaseAnalytics.instance.logEvent(
      name: 'frame_rate',
      parameters: {
        'screen': screenName,
        'fps': fps,
      },
    );
  }
}
```

### User Experience Metrics

```dart
class UXMetrics {
  static void trackUserFlow(String flowName, Map<String, dynamic> steps) {
    FirebaseAnalytics.instance.logEvent(
      name: 'user_flow_$flowName',
      parameters: steps,
    );
  }
  
  static void trackErrorRecovery(String errorType, bool recovered) {
    FirebaseAnalytics.instance.logEvent(
      name: 'error_recovery',
      parameters: {
        'error_type': errorType,
        'recovered': recovered,
      },
    );
  }
}
```

## Conclusion

This design document provides a comprehensive solution for all identified frontend issues in the Waste Segregation app. By implementing the design system, animation improvements, responsive layouts, and accessibility enhancements, we will create a polished, performant, and delightful user experience that meets modern mobile app standards.

The phased implementation approach allows for gradual migration while maintaining app stability, and the property-based testing strategy ensures correctness throughout the development process.
