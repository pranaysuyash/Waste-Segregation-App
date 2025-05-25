# Testing Strategy and Guidelines

## Overview

This document outlines the testing strategy for the Waste Segregation App, covering unit tests, widget tests, integration tests, golden image tests, and manual testing procedures. A robust testing approach is crucial for ensuring app stability, correctness, and a high-quality user experience.

## Types of Tests

### 1. Unit Tests
- **Location**: `test/services/`, `test/models/`, `test/utils/`
- **Purpose**: To test individual functions, methods, and classes in isolation. Focuses on the business logic within services, data transformations in models, and utility functions.
- **Tools**: `flutter_test`, `mockito` (for mocking dependencies).

### 2. Widget Tests
- **Location**: `test/widgets/`, `test/screens/` (for screen-level widget compositions)
- **Purpose**: To test individual Flutter widgets or compositions of widgets. Verifies UI rendering, user interactions (tapping, scrolling), and state changes within the widget tree.
- **Tools**: `flutter_test`.

### 3. Golden Image Tests (Visual Regression Testing)
- **Location**: `test/golden/`
- **Purpose**: To capture a "golden" image (screenshot) of a widget or screen under specific conditions and compare it against future test runs. This helps detect unintended visual changes or regressions in the UI.
- **Key Areas Covered**:
    - `ResponsiveText` and `ResponsiveAppBarTitle`
    - `StatsCard` (Horizontal Stat Cards)
    - `FeatureCard` (Quick Action Cards)
    - `ActiveChallengeCard`
    - `RecentClassificationCard`
    - `ViewAllButton` (implicitly tested via screens using it)
- **Tools**: `flutter_test`, `golden_toolkit` (or custom matcher setup).
- **Maintenance**: Golden images need to be updated (regenerated) when intentional UI changes are made.

### 4. Integration Tests
- **Location**: `test_driver/` or `integration_test/`
- **Purpose**: To test complete app flows or interactions between multiple parts of the app, including navigation, service calls, and state persistence.
- **Tools**: `flutter_driver`, `integration_test`.

### 5. Manual Testing
- **Purpose**: To perform exploratory testing, verify user experience across different devices, and test scenarios that are difficult to automate.
- **Guides**: Detailed manual testing guides are provided for newly developed or significantly refactored UI components. These guides outline specific scenarios, expected outcomes, and device configurations to test.
    - [Responsive Text & Greeting Card Manual Testing Guide](responsive_text_manual_testing_guide.md)
    - [Horizontal Stat Cards Manual Testing Guide](horizontal_stats_cards_manual_testing_guide.md)
    - [Quick Action Cards Manual Testing Guide](quick_action_cards_manual_testing_guide.md)
    - [Active Challenge Preview Manual Testing Guide](active_challenge_preview_manual_testing_guide.md)
    - [Recent Classification List Manual Testing Guide](recent_classification_list_manual_testing_guide.md)
- **Focus Areas**: UI responsiveness, overflow issues, theming, navigation, and overall usability.

## Running Tests

- **All Tests**: `flutter test`
- **Specific File**: `flutter test test/widgets/my_widget_test.dart`
- **Update Golden Images**: Typically involves a command like `flutter test --update-goldens` (may vary based on the golden testing package used).

## Test Coverage

Strive for high test coverage, especially for critical business logic and complex UI components. Coverage reports can be generated using `flutter test --coverage`.

## Continuous Integration (CI)

Automated tests (unit, widget, golden, integration) should be part of the CI pipeline to ensure that new changes do not break existing functionality or introduce regressions.

This comprehensive testing approach helps maintain the quality and reliability of the Waste Segregation App. 