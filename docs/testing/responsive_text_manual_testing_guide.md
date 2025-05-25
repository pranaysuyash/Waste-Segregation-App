# Responsive Text Manual Testing Guide

## Overview
This guide provides step-by-step instructions for manually testing the responsive text fixes for AppBar titles and greeting cards in the Waste Segregation App.

## Test Environment Setup

### Prerequisites
- Flutter development environment
- Physical devices or emulators with different screen sizes
- Access to device developer options for font size changes

### Recommended Test Devices
1. **Small Screen**: iPhone SE (320x568) or similar Android device
2. **Medium Screen**: iPhone 8 (375x667) or Pixel 3
3. **Large Screen**: iPhone 11 Pro Max (414x896) or Pixel 6 Pro
4. **Tablet**: iPad (768x1024) or Android tablet

## Test Cases

### 1. AppBar Title Tests

#### Test 1.1: Normal App Name Display
**Objective**: Verify the default app name displays correctly without overflow

**Steps**:
1. Launch the app on a standard device (iPhone 8 or similar)
2. Navigate to the home screen
3. Observe the AppBar title

**Expected Result**:
- "Waste Segregation" displays fully without truncation
- Text is centered and readable
- No visual overflow or clipping

**Pass Criteria**: ✅ Title is fully visible and properly formatted

---

#### Test 1.2: Long App Name Handling
**Objective**: Test how the app handles extended app names

**Steps**:
1. Temporarily modify `AppStrings.appName` to "Waste Segregation Pro Edition with Advanced Features"
2. Hot reload the app
3. Check AppBar on different screen sizes

**Expected Result**:
- Text automatically resizes to fit available space
- Minimum font size maintained for readability
- No text overflow or clipping occurs

**Pass Criteria**: ✅ Long title adapts gracefully to screen constraints

---

#### Test 1.3: Very Narrow Screen Test
**Objective**: Verify AppBar behavior on extremely narrow screens

**Steps**:
1. Use iPhone SE or set emulator to 320px width
2. Test with both normal and long app names
3. Rotate device to landscape mode

**Expected Result**:
- Title abbreviates appropriately (e.g., "WS" for "Waste Segregation")
- Abbreviation is readable and makes sense
- No layout breaking or crashes

**Pass Criteria**: ✅ Graceful degradation on narrow screens

---

### 2. Greeting Card Tests

#### Test 2.1: Standard Greeting Display
**Objective**: Verify normal greeting behavior with typical usernames

**Steps**:
1. Sign in with a normal username (e.g., "John", "Sarah")
2. Test at different times of day:
   - Morning (before 12 PM): "Good Morning"
   - Afternoon (12-5 PM): "Good Afternoon"  
   - Evening (after 5 PM): "Good Evening"
3. Observe greeting card on home screen

**Expected Result**:
- Greeting changes based on time of day
- Username displays correctly
- Text fits within card boundaries
- Icon matches time of day

**Pass Criteria**: ✅ Dynamic greetings work correctly with normal usernames

---

#### Test 2.2: Long Username Handling
**Objective**: Test greeting card with very long usernames

**Steps**:
1. Create test account with long username: "AVeryLongUserNameThatShouldCauseTextOverflow"
2. Navigate to home screen
3. Test on different screen sizes
4. Check both modern and classic home screen layouts

**Expected Result**:
- Text automatically wraps to multiple lines (max 2)
- Font size reduces if necessary to maintain readability
- No text clipping or overflow
- Card layout remains intact

**Pass Criteria**: ✅ Long usernames handled gracefully without breaking layout

---

#### Test 2.3: Narrow Screen Greeting Test
**Objective**: Verify greeting card behavior on narrow screens

**Steps**:
1. Use narrow device or emulator (320px width)
2. Test with various username lengths
3. Check both portrait and landscape orientations

**Expected Result**:
- Greeting text adapts to available space
- Icon and text remain properly aligned
- Card maintains visual hierarchy
- Text remains readable

**Pass Criteria**: ✅ Greeting card responsive on narrow screens

---

### 3. Accessibility Tests

#### Test 3.1: Screen Reader Compatibility
**Objective**: Ensure responsive text works with screen readers

**Steps**:
1. Enable VoiceOver (iOS) or TalkBack (Android)
2. Navigate to home screen
3. Focus on AppBar title and greeting card
4. Verify screen reader announces content correctly

**Expected Result**:
- Screen reader announces full app name
- Greeting text is read as complete sentence
- No truncated or garbled announcements

**Pass Criteria**: ✅ Full accessibility maintained

---

#### Test 3.2: Font Size Accessibility
**Objective**: Test with system font size changes

**Steps**:
1. Go to device Settings > Accessibility > Font Size
2. Set to largest available font size
3. Return to app and check text display
4. Test with smallest font size as well

**Expected Result**:
- App respects system font size preferences
- Text remains readable at all sizes
- Layout adapts appropriately
- No text overflow occurs

**Pass Criteria**: ✅ Responsive to system font size changes

---

### 4. Performance Tests

#### Test 4.1: Smooth Rendering
**Objective**: Verify responsive text doesn't impact performance

**Steps**:
1. Navigate rapidly between screens
2. Rotate device multiple times
3. Switch between apps and return
4. Monitor for any lag or stuttering

**Expected Result**:
- Smooth transitions and animations
- No noticeable performance degradation
- Text renders quickly and consistently

**Pass Criteria**: ✅ No performance impact from responsive text

---

### 5. Edge Case Tests

#### Test 5.1: Empty Username Handling
**Objective**: Test behavior with missing or empty usernames

**Steps**:
1. Test guest mode
2. Test with account that has no display name
3. Check fallback behavior

**Expected Result**:
- Graceful fallback to "Guest" or "User"
- No crashes or empty greetings
- Consistent formatting maintained

**Pass Criteria**: ✅ Handles edge cases gracefully

---

#### Test 5.2: Special Characters in Username
**Objective**: Test with usernames containing special characters

**Steps**:
1. Test with usernames containing:
   - Emojis: "John 😊"
   - Special characters: "María José"
   - Numbers: "User123"
   - Mixed case: "CamelCaseUser"

**Expected Result**:
- All character types display correctly
- Text measurement works accurately
- No encoding or display issues

**Pass Criteria**: ✅ Special characters handled correctly

---

## Test Results Documentation

### Test Execution Checklist

| Test Case | Device 1 (Small) | Device 2 (Medium) | Device 3 (Large) | Device 4 (Tablet) | Status |
|-----------|-------------------|-------------------|-------------------|-------------------|---------|
| AppBar Normal | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| AppBar Long | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| AppBar Narrow | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Greeting Normal | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Greeting Long | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Greeting Narrow | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Accessibility | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Performance | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Edge Cases | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

### Issue Reporting Template

```markdown
## Issue Report

**Test Case**: [Test case name]
**Device**: [Device model and screen size]
**OS Version**: [iOS/Android version]
**App Version**: [App version]

**Issue Description**:
[Detailed description of the issue]

**Steps to Reproduce**:
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Behavior**:
[What should happen]

**Actual Behavior**:
[What actually happened]

**Screenshots**:
[Attach relevant screenshots]

**Severity**: [Critical/High/Medium/Low]
```

## Automated Test Verification

After manual testing, run the automated tests to ensure consistency:

```bash
# Run widget tests
flutter test test/widgets/responsive_text_test.dart

# Run golden tests (generates reference images)
flutter test test/golden/responsive_text_golden_test.dart

# Update golden files if needed
flutter test test/golden/responsive_text_golden_test.dart --update-goldens
```

## Success Criteria

The responsive text implementation is considered successful when:

1. ✅ All manual test cases pass on all target devices
2. ✅ Automated tests pass consistently
3. ✅ No performance degradation observed
4. ✅ Accessibility requirements met
5. ✅ Visual consistency maintained across screen sizes
6. ✅ No text overflow or clipping in any scenario
7. ✅ Graceful degradation on edge cases

## Notes for Testers

- Take screenshots of any issues for documentation
- Test with both light and dark themes
- Verify behavior with different system languages if applicable
- Pay attention to text alignment and visual hierarchy
- Report any unexpected behavior, even if minor

## Post-Testing Actions

1. Document all test results
2. Create bug reports for any failures
3. Update golden test files if visual changes are intentional
4. Verify fixes for any reported issues
5. Re-run full test suite after fixes 