# Quick-action Cards Manual Testing Guide

## Overview
This guide provides comprehensive manual testing procedures for the Quick-action Cards ("Analytics", "Learn About Waste") to ensure proper overflow handling, padding consistency, and navigation functionality.

## Test Environment Setup

### Prerequisites
- Flutter app running on test device/emulator
- Access to both home screens (classic and modern)
- Various screen sizes for testing
- Different text scaling settings

### Test Devices Matrix
| Device Type | Screen Size | Orientation | Text Scale |
|-------------|-------------|-------------|------------|
| Phone Small | 320x568 | Portrait | 1.0x |
| Phone Medium | 375x667 | Portrait | 1.0x |
| Phone Large | 414x896 | Portrait | 1.0x |
| Tablet | 768x1024 | Portrait | 1.0x |
| Phone Small | 320x568 | Portrait | 1.5x |
| Phone Medium | 375x667 | Portrait | 2.0x |

## Test Cases

### TC-QAC-001: Basic Display and Layout
**Objective**: Verify cards display correctly with proper spacing and alignment

**Steps**:
1. Navigate to Modern Home Screen
2. Scroll to Quick Actions section
3. Observe both cards: "Analytics Dashboard" and "Learn About Waste"

**Expected Results**:
- Both cards are visible and properly aligned
- Icons are displayed with correct colors (blue for Analytics, green for Learn)
- Titles and subtitles are clearly readable
- Cards have consistent spacing between them
- Chevron icons are visible on the right side

**Pass Criteria**: ✅ All elements display correctly without overlap or misalignment

---

### TC-QAC-002: Text Overflow Handling - Long Titles
**Objective**: Verify long titles don't cause overflow issues

**Test Data**:
- Modify title to: "Very Long Analytics Dashboard Title That Should Not Overflow Under Any Circumstances"

**Steps**:
1. Navigate to Quick Actions section
2. Observe title display on different screen sizes
3. Check for text truncation or wrapping

**Expected Results**:
- Text wraps to maximum 2 lines
- Ellipsis (...) appears if text is too long
- No horizontal overflow occurs
- Card maintains proper height

**Pass Criteria**: ✅ No overflow errors, text handled gracefully

---

### TC-QAC-003: Text Overflow Handling - Long Subtitles
**Objective**: Verify long subtitles don't cause overflow issues

**Test Data**:
- Modify subtitle to: "Very long subtitle that describes detailed insights and statistics with comprehensive data analysis and reporting features that should be handled gracefully"

**Steps**:
1. Navigate to Quick Actions section
2. Observe subtitle display on different screen sizes
3. Check for text truncation or wrapping

**Expected Results**:
- Subtitle wraps to maximum 2 lines
- Ellipsis (...) appears if text is too long
- No horizontal overflow occurs
- Proper spacing maintained between title and subtitle

**Pass Criteria**: ✅ No overflow errors, subtitle handled gracefully

---

### TC-QAC-004: Responsive Padding - Narrow Screens
**Objective**: Verify padding adapts correctly on narrow screens

**Steps**:
1. Test on device with width < 300px (or use developer tools)
2. Navigate to Quick Actions section
3. Observe card padding and spacing

**Expected Results**:
- Cards use smaller padding on narrow screens
- Content remains readable and accessible
- Icons and text maintain proper spacing
- No content cutoff occurs

**Pass Criteria**: ✅ Padding adapts appropriately for narrow screens

---

### TC-QAC-005: Responsive Padding - Wide Screens
**Objective**: Verify padding works correctly on wide screens

**Steps**:
1. Test on device with width > 300px
2. Navigate to Quick Actions section
3. Observe card padding and spacing

**Expected Results**:
- Cards use standard padding on wide screens
- Content is well-spaced and visually appealing
- No excessive white space
- Consistent with design guidelines

**Pass Criteria**: ✅ Padding is appropriate for wide screens

---

### TC-QAC-006: Navigation - Analytics Dashboard
**Objective**: Verify Analytics card navigation works correctly

**Steps**:
1. Navigate to Quick Actions section
2. Tap on "Analytics Dashboard" card
3. Verify navigation occurs
4. Check destination screen

**Expected Results**:
- Tap is registered immediately
- Navigation animation is smooth
- Waste Dashboard Screen opens
- Back navigation works correctly

**Pass Criteria**: ✅ Navigation functions correctly without errors

---

### TC-QAC-007: Navigation - Learn About Waste
**Objective**: Verify Learn About Waste card navigation works correctly

**Steps**:
1. Navigate to Quick Actions section
2. Tap on "Learn About Waste" card
3. Verify navigation occurs
4. Check destination screen

**Expected Results**:
- Tap is registered immediately
- Navigation animation is smooth
- Educational Content Screen opens
- Back navigation works correctly

**Pass Criteria**: ✅ Navigation functions correctly without errors

---

### TC-QAC-008: Tap Area Coverage
**Objective**: Verify entire card area is tappable

**Steps**:
1. Navigate to Quick Actions section
2. Tap on different areas of each card:
   - Icon area
   - Title text
   - Subtitle text
   - Empty space within card
   - Chevron icon

**Expected Results**:
- All areas within card boundaries are tappable
- Consistent tap response across entire card
- Visual feedback (if any) is consistent

**Pass Criteria**: ✅ Entire card area responds to taps

---

### TC-QAC-009: Color Consistency
**Objective**: Verify colors match design specifications

**Steps**:
1. Navigate to Quick Actions section
2. Compare icon colors with design specifications
3. Check card background colors
4. Verify text colors for readability

**Expected Results**:
- Analytics icon uses AppTheme.infoColor (blue)
- Learn About Waste icon uses AppTheme.successColor (green)
- Card backgrounds are consistent
- Text colors provide good contrast

**Pass Criteria**: ✅ Colors match specifications and provide good contrast

---

### TC-QAC-010: Theme Compatibility - Light Theme
**Objective**: Verify cards work correctly in light theme

**Steps**:
1. Ensure app is using light theme
2. Navigate to Quick Actions section
3. Observe card appearance and readability

**Expected Results**:
- Cards are clearly visible
- Text is readable with good contrast
- Icons are properly colored
- No visual artifacts

**Pass Criteria**: ✅ Cards display correctly in light theme

---

### TC-QAC-011: Theme Compatibility - Dark Theme
**Objective**: Verify cards work correctly in dark theme

**Steps**:
1. Switch app to dark theme
2. Navigate to Quick Actions section
3. Observe card appearance and readability

**Expected Results**:
- Cards adapt to dark theme
- Text remains readable
- Icons maintain proper colors
- Background provides good contrast

**Pass Criteria**: ✅ Cards display correctly in dark theme

---

### TC-QAC-012: Accessibility - Screen Reader
**Objective**: Verify cards are accessible to screen readers

**Steps**:
1. Enable screen reader (TalkBack/VoiceOver)
2. Navigate to Quick Actions section
3. Use screen reader to interact with cards

**Expected Results**:
- Cards are announced by screen reader
- Title and subtitle content is read aloud
- Cards are focusable and activatable
- Navigation announcements are clear

**Pass Criteria**: ✅ Cards are fully accessible to screen readers

---

### TC-QAC-013: Accessibility - Large Text
**Objective**: Verify cards work with large text settings

**Steps**:
1. Set device text size to largest setting
2. Navigate to Quick Actions section
3. Observe card layout and readability

**Expected Results**:
- Text scales appropriately
- Cards adjust height as needed
- No text cutoff occurs
- Layout remains functional

**Pass Criteria**: ✅ Cards handle large text gracefully

---

### TC-QAC-014: Performance - Multiple Interactions
**Objective**: Verify cards perform well under repeated use

**Steps**:
1. Navigate to Quick Actions section
2. Rapidly tap cards multiple times
3. Navigate away and back repeatedly
4. Monitor for performance issues

**Expected Results**:
- No lag or stuttering
- Smooth animations
- No memory leaks
- Consistent response times

**Pass Criteria**: ✅ Cards maintain good performance

---

### TC-QAC-015: Edge Case - Missing Content
**Objective**: Verify cards handle missing or null content gracefully

**Test Scenarios**:
- Card with no subtitle
- Card with empty title
- Card with null onTap handler

**Steps**:
1. Test each scenario
2. Observe card behavior
3. Check for crashes or errors

**Expected Results**:
- Cards handle missing content gracefully
- No crashes or exceptions
- Layout adjusts appropriately
- Fallback behavior is appropriate

**Pass Criteria**: ✅ Cards handle edge cases without errors

---

## Test Results Template

### Test Execution Summary
| Test Case | Status | Notes | Tester | Date |
|-----------|--------|-------|--------|------|
| TC-QAC-001 | ⏳ | | | |
| TC-QAC-002 | ⏳ | | | |
| TC-QAC-003 | ⏳ | | | |
| TC-QAC-004 | ⏳ | | | |
| TC-QAC-005 | ⏳ | | | |
| TC-QAC-006 | ⏳ | | | |
| TC-QAC-007 | ⏳ | | | |
| TC-QAC-008 | ⏳ | | | |
| TC-QAC-009 | ⏳ | | | |
| TC-QAC-010 | ⏳ | | | |
| TC-QAC-011 | ⏳ | | | |
| TC-QAC-012 | ⏳ | | | |
| TC-QAC-013 | ⏳ | | | |
| TC-QAC-014 | ⏳ | | | |
| TC-QAC-015 | ⏳ | | | |

### Status Legend
- ✅ Pass
- ❌ Fail
- ⏳ Pending
- ⚠️ Partial/Issues

### Critical Issues Found
(Document any critical issues that prevent core functionality)

### Minor Issues Found
(Document any minor issues that don't prevent functionality but should be addressed)

### Recommendations
(Provide recommendations for improvements or additional testing)

---

## Automated Test Verification

Before manual testing, ensure all automated tests pass:

```bash
# Run unit tests
flutter test test/widgets/quick_action_cards_test.dart

# Run golden tests
flutter test test/golden/quick_action_cards_golden_test.dart

# Run all tests
flutter test
```

## Regression Testing Checklist

When making changes to Quick-action Cards, verify:
- [ ] All existing functionality still works
- [ ] New changes don't break existing tests
- [ ] Performance hasn't degraded
- [ ] Accessibility remains intact
- [ ] Visual design is consistent

## Notes for Testers

1. **Focus Areas**: Pay special attention to text overflow, navigation, and responsive behavior
2. **Common Issues**: Watch for text cutoff, navigation failures, and layout breaks
3. **Device Coverage**: Test on at least 3 different screen sizes
4. **Theme Testing**: Always test both light and dark themes
5. **Accessibility**: Don't skip accessibility testing - it's crucial for user experience

## Contact Information

For questions about this testing guide or to report issues:
- Development Team: [team@example.com]
- QA Lead: [qa@example.com]
 