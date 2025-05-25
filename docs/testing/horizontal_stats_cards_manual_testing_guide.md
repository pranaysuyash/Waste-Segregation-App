# Horizontal Stat Cards Manual Testing Guide

## Overview
This guide provides step-by-step instructions for manually testing the horizontal stat cards fixes in the Waste Segregation App, focusing on overflow prevention, color standardization, and responsive behavior across different data states.

## Test Environment Setup

### Prerequisites
- Flutter development environment
- Physical devices or emulators with different screen sizes
- Access to app data manipulation for testing different states

### Recommended Test Devices
1. **Small Screen**: iPhone SE (320x568) or similar Android device
2. **Medium Screen**: iPhone 8 (375x667) or Pixel 3
3. **Large Screen**: iPhone 11 Pro Max (414x896) or Pixel 6 Pro
4. **Tablet**: iPad (768x1024) or Android tablet

## Test Cases

### 1. Basic Display Tests

#### Test 1.1: Zero Values State
**Objective**: Verify stat cards display correctly when all values are zero

**Steps**:
1. Launch the app with a fresh account (no classifications)
2. Navigate to the modern home screen
3. Observe the three stat cards: Classifications, Streak, Points

**Expected Result**:
- All cards show "0" values clearly
- No layout breaking or overflow
- Icons and labels are properly aligned
- Cards maintain consistent height and spacing

**Pass Criteria**: ✅ Zero values display cleanly without layout issues

---

#### Test 1.2: Small Values State
**Objective**: Test display with small positive values

**Steps**:
1. Perform 1-5 classifications
2. Check that streak is 1-3 days
3. Verify points are 10-50
4. Observe stat cards layout

**Expected Result**:
- Small numbers display with appropriate font size
- Trend indicators show correctly (if applicable)
- Layout remains stable and readable
- No text clipping or overflow

**Pass Criteria**: ✅ Small values display appropriately sized

---

#### Test 1.3: Large Values State
**Objective**: Test display with large values that could cause overflow

**Steps**:
1. Simulate or achieve large values:
   - Classifications: 1,000+ 
   - Streak: 100+ days
   - Points: 10,000+
2. Navigate to home screen
3. Check stat cards display

**Expected Result**:
- Large numbers automatically resize to fit
- Text uses smaller font size when needed
- FittedBox prevents overflow
- All text remains readable

**Pass Criteria**: ✅ Large values adapt gracefully without overflow

---

### 2. Responsive Layout Tests

#### Test 2.1: Narrow Screen Test
**Objective**: Verify cards adapt to narrow screen widths

**Steps**:
1. Use iPhone SE or set emulator to 320px width
2. Test with various value lengths:
   - Short: "5", "12", "100"
   - Medium: "1,234", "5,678"
   - Long: "999,999", "1,234,567"
3. Rotate to landscape mode

**Expected Result**:
- Cards maintain equal width distribution
- Text automatically resizes based on available space
- No horizontal scrolling required
- Layout remains stable in both orientations

**Pass Criteria**: ✅ Cards adapt to narrow screens without breaking

---

#### Test 2.2: Title Truncation Test
**Objective**: Test long titles are handled properly

**Steps**:
1. Modify card titles to be very long (if possible in test mode)
2. Check titles like "Very Long Classification Title"
3. Test on different screen sizes

**Expected Result**:
- Long titles truncate with ellipsis
- Icons remain visible and aligned
- Card layout doesn't break
- Truncation is visually clean

**Pass Criteria**: ✅ Long titles truncate gracefully

---

### 3. Color Standardization Tests

#### Test 3.1: Trend Chip Colors
**Objective**: Verify trend indicators use standardized colors

**Steps**:
1. Create scenarios with positive trends (+5%, +10, etc.)
2. Create scenarios with negative trends (-5%, -10, etc.)
3. Observe trend chip colors

**Expected Result**:
- Positive trends: Green color (AppTheme.successColor)
- Negative trends: Red color (AppTheme.errorColor)
- Trend chips have consistent styling
- Icons match trend direction (up/down arrows)

**Pass Criteria**: ✅ Trend colors follow design system standards

---

#### Test 3.2: Value Number Colors
**Objective**: Verify value numbers use appropriate accent colors

**Steps**:
1. Check Classifications card (should use AppTheme.infoColor)
2. Check Streak card (should use orange)
3. Check Points card (should use amber)
4. Test with different themes (light/dark)

**Expected Result**:
- Each card type has consistent color scheme
- Colors remain readable in both light and dark themes
- Value numbers stand out appropriately
- Color contrast meets accessibility standards

**Pass Criteria**: ✅ Value colors are standardized and accessible

---

#### Test 3.3: Dry Waste Color Update
**Objective**: Verify "Dry Waste" category uses new amber color

**Steps**:
1. Classify items as "Dry Waste"
2. Check any dry waste statistics or badges
3. Verify color is amber (#FFC107) not blue

**Expected Result**:
- Dry waste items show amber color
- Color is consistent across all UI elements
- Amber provides good contrast and visibility
- No blue remnants from old color scheme

**Pass Criteria**: ✅ Dry waste color updated to amber throughout app

---

### 4. Interactive Behavior Tests

#### Test 4.1: Tap Navigation
**Objective**: Verify cards navigate to correct destinations

**Steps**:
1. Tap Classifications card → should go to History screen
2. Tap Streak card → should go to Achievements screen
3. Tap Points card → should go to Achievements screen
4. Verify navigation works on all screen sizes

**Expected Result**:
- Each card navigates to appropriate screen
- Navigation is responsive and immediate
- Back navigation returns to home screen
- Tap targets are appropriately sized

**Pass Criteria**: ✅ All cards navigate correctly

---

#### Test 4.2: Visual Feedback
**Objective**: Test visual feedback during interactions

**Steps**:
1. Tap and hold cards to see press states
2. Check for appropriate visual feedback
3. Test on different devices

**Expected Result**:
- Cards show visual feedback when pressed
- Feedback is consistent across all cards
- No lag or delayed responses
- Visual states are clear and appropriate

**Pass Criteria**: ✅ Interactive feedback is responsive and clear

---

### 5. Data State Transition Tests

#### Test 5.1: Real-time Updates
**Objective**: Verify cards update when data changes

**Steps**:
1. Start with zero values
2. Perform a classification
3. Observe immediate updates to cards
4. Check that animations are smooth

**Expected Result**:
- Cards update immediately after classification
- Value changes are smooth and clear
- Layout remains stable during updates
- No flickering or layout jumps

**Pass Criteria**: ✅ Cards update smoothly with data changes

---

#### Test 5.2: Trend Calculation
**Objective**: Test trend indicators update correctly

**Steps**:
1. Note current values and trends
2. Perform several classifications over time
3. Check that trends reflect actual changes
4. Verify trend direction and magnitude

**Expected Result**:
- Trends accurately reflect data changes
- Positive/negative indicators are correct
- Trend percentages are reasonable
- Updates happen in real-time

**Pass Criteria**: ✅ Trends accurately reflect data changes

---

### 6. Edge Case Tests

#### Test 6.1: Extreme Values
**Objective**: Test with very large or unusual values

**Steps**:
1. Test with values like 999,999,999
2. Test with decimal values (if applicable)
3. Test with negative values (if possible)
4. Check for any crashes or layout breaks

**Expected Result**:
- Extreme values handled gracefully
- No crashes or errors
- Layout adapts appropriately
- Text remains readable

**Pass Criteria**: ✅ Extreme values don't break the layout

---

#### Test 6.2: Network/Loading States
**Objective**: Test behavior during data loading

**Steps**:
1. Force network delays or loading states
2. Check how cards behave during loading
3. Verify loading indicators if present

**Expected Result**:
- Cards show appropriate loading states
- No empty or broken layouts during loading
- Smooth transition from loading to data
- Error states handled gracefully

**Pass Criteria**: ✅ Loading states are handled properly

---

## Test Results Documentation

### Test Execution Checklist

| Test Case | iPhone SE | iPhone 8 | iPhone 11 Pro | iPad | Status |
|-----------|-----------|----------|---------------|------|---------|
| Zero Values | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Small Values | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Large Values | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Narrow Screen | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Title Truncation | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Trend Colors | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Value Colors | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Dry Waste Color | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Tap Navigation | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Visual Feedback | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Real-time Updates | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Trend Calculation | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Extreme Values | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Loading States | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

### Issue Reporting Template

```markdown
## Stat Cards Issue Report

**Test Case**: [Test case name]
**Device**: [Device model and screen size]
**OS Version**: [iOS/Android version]
**App Version**: [App version]

**Issue Description**:
[Detailed description of the issue]

**Data State**:
- Classifications: [number]
- Streak: [number] days
- Points: [number]
- Trends: [trend values]

**Steps to Reproduce**:
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Behavior**:
[What should happen]

**Actual Behavior**:
[What actually happened]

**Screenshots**:
[Attach relevant screenshots showing the issue]

**Severity**: [Critical/High/Medium/Low]
```

## Automated Test Verification

After manual testing, run the automated tests to ensure consistency:

```bash
# Run stat card widget tests
flutter test test/widgets/stats_card_test.dart

# Run golden tests (generates reference images)
flutter test test/golden/stats_card_golden_test.dart

# Update golden files if needed
flutter test test/golden/stats_card_golden_test.dart --update-goldens
```

## Success Criteria

The horizontal stat cards implementation is considered successful when:

1. ✅ All overflow issues are resolved across all screen sizes
2. ✅ Color standardization is consistent throughout the app
3. ✅ Cards adapt gracefully to different data states (0, small, large, negative)
4. ✅ Layout remains stable during data transitions
5. ✅ Accessibility requirements are met
6. ✅ Performance is maintained with real-time updates
7. ✅ Visual hierarchy and design consistency are preserved
8. ✅ Interactive behavior is responsive and intuitive

## Notes for Testers

- Pay special attention to text sizing and overflow on narrow screens
- Verify color consistency across light and dark themes
- Test with realistic data ranges that users might encounter
- Check that trend indicators accurately reflect data changes
- Report any visual inconsistencies or layout breaks
- Test both portrait and landscape orientations

## Post-Testing Actions

1. Document all test results in the checklist
2. Create detailed bug reports for any failures
3. Update golden test files if visual changes are intentional
4. Verify fixes for any reported issues
5. Re-run full test suite after fixes
6. Update documentation if behavior changes are made 