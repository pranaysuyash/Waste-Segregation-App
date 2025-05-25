# Active Challenge Preview Manual Testing Guide

## Overview
This guide provides comprehensive manual testing procedures for the Active Challenge Preview to ensure proper overflow handling, responsive behavior, progress display, and navigation functionality.

## Test Environment Setup

### Prerequisites
- Flutter app running on test device/emulator
- Access to both home screens (classic and modern)
- Various screen sizes for testing
- Different text scaling settings
- Mock challenge data with various progress states

### Test Devices Matrix
| Device Type | Screen Size | Orientation | Text Scale |
|-------------|-------------|-------------|------------|
| Phone Small | 320x568 | Portrait | 1.0x |
| Phone Medium | 375x667 | Portrait | 1.0x |
| Phone Large | 414x896 | Portrait | 1.0x |
| Tablet Small | 768x1024 | Portrait | 1.0x |
| Tablet Large | 1024x1366 | Portrait | 1.0x |
| Phone Small | 320x568 | Portrait | 1.5x |
| Phone Medium | 375x667 | Portrait | 2.0x |

## Test Cases

### TC-ACP-001: Basic Display Functionality
**Objective**: Verify that Active Challenge Preview displays all information correctly

**Steps**:
1. Navigate to home screen with active challenges
2. Locate the Active Challenge Preview section
3. Verify the following elements are displayed:
   - Challenge title
   - Challenge description
   - Progress badge with percentage
   - Progress bar
   - Time remaining (if available)
   - Reward points (if available)
   - Challenge icon (if available)

**Expected Results**:
- All elements display correctly
- Text is readable and properly formatted
- Progress badge shows correct percentage
- Progress bar reflects the same progress as badge
- Colors are consistent with challenge theme

**Test Data**:
```dart
ActiveChallengeCard(
  title: 'Daily Recycling Goal',
  description: 'Classify 5 items today to earn points',
  progress: 0.6,
  icon: Icons.emoji_events,
  timeRemaining: '8 hours left',
  reward: '50 pts',
  challengeColor: Colors.green,
)
```

### TC-ACP-002: Text Overflow Handling
**Objective**: Verify that long text content doesn't cause overflow

**Steps**:
1. Test with extremely long challenge title
2. Test with extremely long description
3. Test with extremely long time remaining text
4. Test with very large reward numbers
5. Verify on narrow screens (< 300px width)

**Expected Results**:
- No horizontal overflow errors
- Text truncates with ellipsis when necessary
- Layout remains stable
- All text remains readable

**Test Data**:
```dart
ActiveChallengeCard(
  title: 'Very Long Challenge Title That Should Not Cause Overflow Issues',
  description: 'Extremely long description that explains in great detail what the user needs to do to complete this challenge successfully and earn the maximum reward points',
  progress: 0.75,
  timeRemaining: 'Very long time remaining description',
  reward: '999999 pts',
)
```

### TC-ACP-003: Progress Display Accuracy
**Objective**: Verify that progress is displayed accurately across different values

**Steps**:
1. Test with progress = 0.0 (0%)
2. Test with progress = 0.25 (25%)
3. Test with progress = 0.5 (50%)
4. Test with progress = 0.75 (75%)
5. Test with progress = 1.0 (100%)
6. Test with invalid values (negative, > 1.0)

**Expected Results**:
- Progress badge shows correct percentage
- Progress bar fills to correct level
- Invalid values are clamped to valid range (0.0-1.0)
- 100% completion shows full progress
- 0% shows empty progress bar

### TC-ACP-004: Responsive Layout Behavior
**Objective**: Verify that layout adapts to different screen sizes

**Steps**:
1. Test on screen width < 300px (narrow)
2. Test on screen width 300-600px (medium)
3. Test on screen width > 600px (wide)
4. Verify element sizing and spacing
5. Check text size adjustments

**Expected Results**:
- Layout adapts smoothly to different widths
- Text sizes adjust appropriately for narrow screens
- Progress badge scales correctly
- Spacing remains proportional
- No elements overlap or get cut off

### TC-ACP-005: Navigation Functionality
**Objective**: Verify that tapping the challenge card navigates correctly

**Steps**:
1. Tap on the Active Challenge Preview card
2. Verify navigation to achievements/challenges screen
3. Test tap responsiveness
4. Verify visual feedback on tap

**Expected Results**:
- Tapping navigates to correct screen
- Visual feedback (ripple effect) appears on tap
- Navigation is smooth and responsive
- Correct challenge details are shown on destination screen

### TC-ACP-006: Optional Elements Display
**Objective**: Verify that optional elements show/hide correctly

**Steps**:
1. Test challenge without icon
2. Test challenge without time remaining
3. Test challenge without reward
4. Test challenge with all optional elements
5. Test challenge with only required elements

**Expected Results**:
- Missing optional elements don't leave empty spaces
- Layout adjusts gracefully when elements are missing
- Present elements display correctly
- No layout shifts or misalignments

### TC-ACP-007: Color Theme Consistency
**Objective**: Verify that colors are applied consistently

**Steps**:
1. Test with different challenge colors
2. Test with light theme
3. Test with dark theme
4. Verify color contrast and readability

**Expected Results**:
- Challenge color is applied to icon, progress elements
- Colors maintain good contrast ratios
- Theme colors are respected
- Text remains readable in all color combinations

### TC-ACP-008: Progress Badge Functionality
**Objective**: Verify that ProgressBadge component works correctly

**Steps**:
1. Test with different progress values
2. Test with custom text instead of percentage
3. Test with different sizes
4. Test with very long text
5. Test in constrained spaces

**Expected Results**:
- Progress badge displays correctly at all sizes
- Custom text displays properly
- Long text is handled without overflow
- Badge adapts to available space
- Circular progress indicator works smoothly

### TC-ACP-009: Accessibility Testing
**Objective**: Verify that the component is accessible

**Steps**:
1. Enable screen reader (TalkBack/VoiceOver)
2. Navigate to Active Challenge Preview
3. Verify all text content is announced
4. Test with high contrast mode
5. Test with large text settings

**Expected Results**:
- All text content is accessible to screen readers
- Component is focusable and navigable
- High contrast mode works correctly
- Large text settings are respected
- Semantic information is properly conveyed

### TC-ACP-010: Performance Testing
**Objective**: Verify that component performs well

**Steps**:
1. Display multiple challenge cards simultaneously
2. Rapidly tap the challenge card multiple times
3. Scroll through list of challenges quickly
4. Monitor memory usage and frame rate

**Expected Results**:
- Smooth rendering with multiple instances
- No lag or stuttering during interactions
- Memory usage remains stable
- 60 FPS maintained during animations

### TC-ACP-011: Edge Cases Testing
**Objective**: Verify handling of edge cases

**Steps**:
1. Test with empty/null challenge data
2. Test with special characters in text
3. Test with very small screen sizes
4. Test with extreme text scaling (200%+)
5. Test with network connectivity issues

**Expected Results**:
- Graceful handling of missing data
- Special characters display correctly
- Component remains functional on very small screens
- Extreme text scaling doesn't break layout
- Network issues don't crash the component

### TC-ACP-012: Animation and Transitions
**Objective**: Verify that animations work smoothly

**Steps**:
1. Observe progress bar animations
2. Test tap feedback animations
3. Verify smooth transitions between states
4. Test on different device performance levels

**Expected Results**:
- Progress animations are smooth and responsive
- Tap feedback provides clear visual indication
- State transitions are seamless
- Performance is consistent across devices

## Test Results Documentation

### Test Execution Template
```
Test Case: TC-ACP-XXX
Date: [Date]
Tester: [Name]
Device: [Device Info]
OS Version: [OS Version]
App Version: [App Version]

Results:
- Step 1: [PASS/FAIL] - [Notes]
- Step 2: [PASS/FAIL] - [Notes]
- Step 3: [PASS/FAIL] - [Notes]

Overall Result: [PASS/FAIL]
Issues Found: [List any issues]
Screenshots: [Attach if needed]
```

### Common Issues to Watch For
1. **Text Overflow**: Look for yellow/black striped overflow indicators
2. **Layout Shifts**: Watch for elements jumping or repositioning
3. **Color Inconsistencies**: Verify colors match design specifications
4. **Performance Issues**: Monitor for lag, stuttering, or memory leaks
5. **Accessibility Problems**: Test with assistive technologies
6. **Navigation Failures**: Ensure taps navigate to correct screens

### Regression Testing
- Run full test suite after any code changes
- Pay special attention to layout and overflow handling
- Verify that existing functionality isn't broken
- Test on multiple devices and screen sizes

### Automated vs Manual Testing
- **Automated**: Basic functionality, overflow detection, progress calculations
- **Manual**: Visual appearance, user experience, accessibility, edge cases
- **Both**: Navigation, theme consistency, performance

## Conclusion
This manual testing guide ensures comprehensive coverage of the Active Challenge Preview functionality. Regular execution of these tests will help maintain high quality and user experience standards.

For any issues found during testing, please document them thoroughly and include:
- Steps to reproduce
- Expected vs actual behavior
- Screenshots or screen recordings
- Device and environment information
- Severity and impact assessment 