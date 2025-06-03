# Waste Segregation App - Testing Guide

## Overview

This guide covers the comprehensive test suite for the Waste Segregation App, including unit tests, integration tests, widget tests, and golden tests.

## Test Categories

### 1. Model Tests (`test/models/models_test.dart`)

Tests for data models validation, serialization, and business logic:

#### WasteClassification Model Tests
- ✅ **Valid object creation**: Tests all properties are correctly set
- ✅ **Serialization**: toJson/fromJson round-trip testing
- ✅ **Fallback classification**: Tests error handling scenarios
- ✅ **Disposal instructions**: Validates urgent/non-urgent instructions
- ✅ **Edge cases**: Empty fields, long strings, future dates
- ✅ **Confidence validation**: Tests invalid confidence values

#### Gamification Model Tests
- ✅ **GamificationProfile creation**: Points, streaks, achievements
- ✅ **Level calculation**: Points to level conversion logic
- ✅ **Streak tracking**: Date-based streak calculations
- ✅ **Achievement validation**: Properties and earned status
- ✅ **Challenge progress**: Active and completed challenges

#### UserProfile Model Tests
- ✅ **Complete profile creation**: With gamification data
- ✅ **Serialization**: User data persistence
- ✅ **Minimal profiles**: Handling optional fields

### 2. Service Tests

#### AI Service Tests (`test/services/ai_service_test.dart`)
- ✅ **Image classification validation**: Model structure tests
- ✅ **Confidence score validation**: Range checking
- ✅ **Category validation**: Valid waste categories
- ✅ **Error handling**: Network errors, invalid files
- ✅ **Disposal instructions**: Different waste types

#### Gamification Service Tests (`test/services/gamification_service_test.dart`)
- ✅ **Points earning**: Classification-based rewards
- ✅ **Achievement unlocking**: Progress tracking
- ✅ **Challenge completion**: Requirements validation
- ✅ **Error handling**: Hive database issues
- ✅ **Profile management**: User data consistency

### 3. Integration Flow Tests (`test/flows/classification_flow_test.dart`)

Tests the complete user workflows:

#### Full Classification Flow
- ✅ **Complete workflow**: Image → AI → Gamification → Storage
- ✅ **Error recovery**: AI service failures
- ✅ **Gamification integration**: Points and achievements
- ✅ **Storage persistence**: Classification history
- ✅ **Performance**: Large image handling

#### Storage and Persistence
- ✅ **Classification saving**: Metadata validation
- ✅ **History retrieval**: User-specific data
- ✅ **Batch operations**: Multiple classifications

#### Error Recovery
- ✅ **Low confidence handling**: Unclear classifications
- ✅ **Network timeouts**: Graceful degradation
- ✅ **Field validation**: Required vs optional data

### 4. Screen/Widget Tests

#### Existing Widget Tests
- ✅ **Responsive Text**: Golden tests for text scaling
- ✅ **Stats Cards**: Visual regression testing
- ✅ **Family Dashboard**: UI component testing
- ✅ **Classification Details**: Result display testing

### 5. Golden Tests

Visual regression testing for UI components:
- ✅ **Text Scaling**: Different screen sizes
- ✅ **Card Layouts**: Consistent visual appearance
- ✅ **Color Schemes**: Light/dark mode consistency

## Running Tests

### Quick Test Run
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/models_test.dart

# Run with coverage
flutter test --coverage
```

### Comprehensive Test Suite
```bash
# Make the test runner executable
chmod +x test_runner.sh

# Run the complete test suite
./test_runner.sh
```

The test runner will:
1. Clean build artifacts
2. Run all test categories
3. Generate coverage reports
4. Provide summary and next steps

### Test Coverage

Generate HTML coverage reports:
```bash
# Install lcov (macOS)
brew install lcov

# Generate coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Test Data and Mocking

### Mock Services
Tests use manual mocks for external dependencies:
- `MockAiService`: Simulates AI classification responses
- `MockGamificationService`: Handles points and achievements
- `MockStorageService`: Manages data persistence

### Test Data Patterns
- **Valid data**: Comprehensive objects with all properties
- **Edge cases**: Empty fields, null values, extreme values
- **Error scenarios**: Network failures, invalid inputs
- **Boundary conditions**: Confidence scores, date ranges

## Key Testing Scenarios

### 1. Classification Workflow
```dart
// Image → AI Analysis → Gamification → Storage
final result = await aiService.analyzeWebImage(imageBytes, 'test.jpg');
await gamificationService.processClassification(result);
await storageService.saveClassification(result);
```

### 2. Points and Achievements
```dart
// Test points calculation
const points = UserPoints(total: 150); // Should be level 1
expect(points.level, equals(1));

// Test achievement progress
const achievement = Achievement(progress: 1.0);
expect(achievement.isEarned, isTrue);
```

### 3. Error Handling
```dart
// Test graceful failure
when(aiService.analyzeWebImage(any, any))
    .thenThrow(Exception('Network timeout'));
expect(() => aiService.analyzeWebImage(...), throwsException);
```

## Coverage Goals

Target coverage by component:
- **Models**: 95%+ (high business logic)
- **Services**: 90%+ (critical app functionality)
- **Flows**: 85%+ (integration scenarios)
- **Widgets**: 80%+ (UI consistency)

## Best Practices

### 1. Test Structure
```dart
group('Component Name', () {
  test('should do specific thing', () {
    // Arrange
    final testData = createTestData();
    
    // Act
    final result = performAction(testData);
    
    // Assert
    expect(result, expectedValue);
  });
});
```

### 2. Mock Usage
```dart
// Arrange mocks
when(mockService.method(any)).thenAnswer((_) async => mockResult);

// Verify interactions
verify(mockService.method(any)).called(1);
```

### 3. Edge Case Testing
```dart
test('should handle edge cases', () {
  // Test null values
  expect(() => createObject(null), throwsArgumentError);
  
  // Test empty values
  final result = createObject('');
  expect(result.field, equals(''));
  
  // Test extreme values
  final longString = 'A' * 1000;
  expect(() => createObject(longString), returnsNormally);
});
```

## Adding New Tests

### 1. Model Tests
When adding new models:
1. Test object creation with all properties
2. Test serialization (toJson/fromJson)
3. Test validation logic
4. Test edge cases and null handling

### 2. Service Tests
When adding new services:
1. Test primary functionality
2. Test error handling
3. Test async operations
4. Test integration with other services

### 3. Flow Tests
When adding new workflows:
1. Test happy path
2. Test error scenarios
3. Test performance with large data
4. Test state management

## Continuous Integration

### Test Requirements
- All tests must pass before merge
- Coverage must not decrease
- Golden tests must match baselines
- Performance tests within limits

### Test Automation
```yaml
# .github/workflows/test.yml
- name: Run Tests
  run: |
    flutter test --coverage
    flutter test --no-pub integration_test/
```

## Troubleshooting

### Common Issues

#### Mock Errors
```dart
// Issue: Type mismatch in mock setup
when(mock.method(any)).thenReturn(wrongType);

// Fix: Use correct return type
when(mock.method(any)).thenAnswer((_) async => correctType);
```

#### Golden Test Failures
```bash
# Update golden files
flutter test --update-goldens test/golden/
```

#### Coverage Issues
```bash
# Exclude generated files
flutter test --coverage --exclude-tags=generated
```

## Performance Testing

### Large Data Tests
```dart
test('should handle large datasets efficiently', () async {
  final largeList = List.generate(10000, (i) => createTestItem(i));
  final stopwatch = Stopwatch()..start();
  
  await processLargeDataset(largeList);
  
  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 second limit
});
```

### Memory Usage Tests
```dart
test('should not leak memory', () {
  final initialMemory = getMemoryUsage();
  
  for (int i = 0; i < 1000; i++) {
    createAndDisposeObject();
  }
  
  final finalMemory = getMemoryUsage();
  expect(finalMemory - initialMemory, lessThan(memoryThreshold));
});
```

## Future Test Enhancements

### Planned Additions
1. **Integration Tests**: Full app workflow testing
2. **Performance Tests**: Memory and speed benchmarks
3. **Accessibility Tests**: Screen reader compatibility
4. **Localization Tests**: Multi-language support
5. **Security Tests**: Data validation and sanitization

### Test Infrastructure
1. **Test Database**: Isolated test data
2. **Test Services**: Mock external APIs
3. **Test Fixtures**: Reusable test data
4. **Test Utilities**: Common helper functions

---

## Quick Reference

### Test Commands
```bash
# Run all tests
flutter test

# Run specific category
flutter test test/models/
flutter test test/services/
flutter test test/flows/

# Generate coverage
flutter test --coverage

# Update golden files
flutter test --update-goldens

# Run in watch mode
flutter test --watch
```

### Key Test Files
- `test/models/models_test.dart` - Data model validation
- `test/services/ai_service_test.dart` - AI classification tests
- `test/flows/classification_flow_test.dart` - Integration workflows
- `test_runner.sh` - Comprehensive test suite runner

This testing guide ensures comprehensive coverage of the Waste Segregation App's functionality, from basic model validation to complex integration workflows. The tests provide confidence in app reliability and maintainability. 