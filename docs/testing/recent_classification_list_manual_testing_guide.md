# Recent Classification List Manual Testing Guide

## Overview
This guide provides comprehensive manual testing procedures for the Recent Classification List Items to ensure proper overflow handling, responsive behavior, badge display, and navigation functionality.

## Test Environment Setup

### Prerequisites
- Flutter app running on test device/emulator
- Access to both home screens (classic and modern)
- Various screen sizes for testing
- Different text scaling settings
- Mock classification data with various properties

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

### TC-RCL-001: Basic Display Functionality
**Objective**: Verify that Recent Classification List Items display all information correctly

**Steps**:
1. Navigate to modern home screen with recent classifications
2. Locate the Recent Classifications section
3. Verify the following elements are displayed for each item:
   - Item name
   - Category badge
   - Subcategory badge (if available)
   - Date/time stamp
   - Property indicators (recyclable, compostable, special disposal)
   - Navigation arrow
   - Thumbnail image (if available)

**Expected Results**:
- All elements display correctly
- Text is readable and properly formatted
- Category badges use correct colors
- Property indicators show appropriate icons
- Date formatting is user-friendly (Today, Yesterday, or date)

**Test Data**:
```dart
RecentClassificationCard(
  itemName: 'Plastic Water Bottle',
  category: 'Dry Waste',
  subcategory: 'Plastic',
  timestamp: DateTime.now(),
  imageUrl: 'test_image.jpg',
  isRecyclable: true,
  isCompostable: false,
  requiresSpecialDisposal: false,
)
```

### TC-RCL-002: Text Overflow Handling
**Objective**: Verify that long text content doesn't cause overflow

**Steps**:
1. Test with extremely long item names
2. Test with extremely long category names
3. Test with extremely long subcategory names
4. Test on narrow screens (< 280px width)
5. Test on very narrow screens (< 200px width)

**Expected Results**:
- No horizontal overflow errors
- Text truncates with ellipsis when necessary
- Layout remains stable
- All text remains readable
- Category badges adapt to available space

**Test Data**:
```dart
RecentClassificationCard(
  itemName: 'Very Long Item Name That Should Not Cause Overflow Issues In The Layout System',
  category: 'Very Long Category Name',
  subcategory: 'Very Long Subcategory Name That Should Not Break',
  timestamp: DateTime.now(),
  isRecyclable: true,
  isCompostable: true,
  requiresSpecialDisposal: true,
)
```

### TC-RCL-003: Responsive Layout Behavior
**Objective**: Verify that layout adapts to different screen sizes

**Steps**:
1. Test on screen width < 280px (very narrow)
2. Test on screen width 280-350px (narrow)
3. Test on screen width 350-500px (medium)
4. Test on screen width > 500px (wide)
5. Verify element sizing and spacing
6. Check badge layout (horizontal vs vertical)

**Expected Results**:
- Layout adapts smoothly to different widths
- Text sizes adjust appropriately for narrow screens
- Images hide on very narrow screens
- Badge layout switches to vertical when needed
- Spacing remains proportional

### TC-RCL-004: Property Indicators Display
**Objective**: Verify that property indicators show/hide correctly

**Steps**:
1. Test item with only recyclable property
2. Test item with only compostable property
3. Test item with only special disposal property
4. Test item with all properties
5. Test item with no properties
6. Test with property indicators disabled

**Expected Results**:
- Correct icons display for each property
- Icons have appropriate colors (blue, green, orange)
- Tooltips show on hover/long press
- Missing properties don't leave empty spaces
- Layout adjusts gracefully when properties are missing

### TC-RCL-005: Badge Layout and Overflow
**Objective**: Verify that category and subcategory badges handle overflow correctly

**Steps**:
1. Test with short category and subcategory names
2. Test with long category and subcategory names
3. Test on narrow screens with multiple badges
4. Test vertical badge layout on very narrow screens
5. Verify badge spacing and alignment

**Expected Results**:
- Badges display correctly at all screen sizes
- Long text in badges truncates with ellipsis
- Subcategory badge hides when space is insufficient
- Vertical layout activates on very narrow screens
- Badge colors are consistent with category

### TC-RCL-006: Navigation Functionality
**Objective**: Verify that tapping classification items navigates correctly

**Steps**:
1. Tap on a classification item
2. Verify navigation to result screen
3. Test tap responsiveness
4. Verify visual feedback on tap
5. Test navigation with different classification types

**Expected Results**:
- Tapping navigates to correct result screen
- Visual feedback (ripple effect) appears on tap
- Navigation is smooth and responsive
- Correct classification details are shown on destination screen
- Navigation works for all classification types

### TC-RCL-007: Image Display Options
**Objective**: Verify that image display works correctly

**Steps**:
1. Test items with images
2. Test items without images
3. Test with image display disabled
4. Test image sizing on different screen sizes
5. Test image placeholder display

**Expected Results**:
- Images display correctly when available
- Placeholder shows when image is missing
- Image sizing adapts to screen size
- Images hide on very narrow screens
- Image display toggle works correctly

### TC-RCL-008: Date Formatting
**Objective**: Verify that date/time formatting is user-friendly

**Steps**:
1. Test with today's date
2. Test with yesterday's date
3. Test with dates from this week
4. Test with older dates
5. Test with different time zones

**Expected Results**:
- Today's items show "Today"
- Yesterday's items show "Yesterday"
- Older items show formatted date (DD/MM/YYYY)
- Date formatting is consistent
- Time zone handling is correct

### TC-RCL-009: Category Color Consistency
**Objective**: Verify that category colors are applied consistently

**Steps**:
1. Test with different waste categories
2. Test with custom category colors
3. Test with light theme
4. Test with dark theme
5. Verify color contrast and readability

**Expected Results**:
- Each category uses correct predefined color
- Custom colors are applied correctly
- Colors maintain good contrast ratios
- Theme colors are respected
- Text remains readable in all color combinations

### TC-RCL-010: Accessibility Testing
**Objective**: Verify that the component is accessible

**Steps**:
1. Enable screen reader (TalkBack/VoiceOver)
2. Navigate to Recent Classifications section
3. Verify all text content is announced
4. Test with high contrast mode
5. Test with large text settings
6. Test keyboard navigation

**Expected Results**:
- All text content is accessible to screen readers
- Components are focusable and navigable
- High contrast mode works correctly
- Large text settings are respected
- Semantic information is properly conveyed
- Keyboard navigation works smoothly

### TC-RCL-011: Performance Testing
**Objective**: Verify that component performs well with multiple items

**Steps**:
1. Display list with 10+ classification items
2. Rapidly scroll through the list
3. Rapidly tap items multiple times
4. Monitor memory usage and frame rate
5. Test with complex layouts (all properties enabled)

**Expected Results**:
- Smooth rendering with multiple instances
- No lag or stuttering during scrolling
- Memory usage remains stable
- 60 FPS maintained during interactions
- Complex layouts don't impact performance

### TC-RCL-012: Edge Cases Testing
**Objective**: Verify handling of edge cases

**Steps**:
1. Test with empty classification data
2. Test with null/missing properties
3. Test with special characters in text
4. Test with extreme text scaling (200%+)
5. Test with very old timestamps

**Expected Results**:
- Graceful handling of missing data
- Special characters display correctly
- Extreme text scaling doesn't break layout
- Old timestamps format correctly
- No crashes or errors with edge cases

### TC-RCL-013: Theme Compatibility
**Objective**: Verify that component works with different themes

**Steps**:
1. Test with light theme
2. Test with dark theme
3. Test with custom theme colors
4. Test with high contrast themes
5. Verify color inheritance and overrides

**Expected Results**:
- Component adapts to theme changes
- Colors remain readable in all themes
- Custom theme colors are respected
- High contrast themes work correctly
- No visual artifacts or inconsistencies

### TC-RCL-014: Multiple Property Indicators
**Objective**: Verify handling of items with multiple properties

**Steps**:
1. Test item with all three properties (recyclable, compostable, special disposal)
2. Test on narrow screens with all properties
3. Test vertical layout with multiple indicators
4. Verify indicator spacing and alignment
5. Test tooltip functionality for each indicator

**Expected Results**:
- All property indicators display correctly
- Indicators don't overlap or crowd layout
- Vertical layout accommodates all indicators
- Tooltips work for each indicator
- Spacing remains consistent

### TC-RCL-015: Integration Testing
**Objective**: Verify integration with home screen and navigation

**Steps**:
1. Test within modern home screen context
2. Test with real classification data
3. Test navigation to result screen
4. Test back navigation
5. Test with different user states (guest, logged in)

**Expected Results**:
- Integrates seamlessly with home screen
- Real data displays correctly
- Navigation flows work properly
- Back navigation maintains state
- Works correctly for all user types

## Test Results Documentation

### Test Execution Template
```
Test Case: TC-RCL-XXX
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
2. **Badge Crowding**: Watch for badges overlapping or being cut off
3. **Layout Shifts**: Monitor for elements jumping or repositioning
4. **Color Inconsistencies**: Verify colors match design specifications
5. **Performance Issues**: Monitor for lag, stuttering, or memory leaks
6. **Accessibility Problems**: Test with assistive technologies
7. **Navigation Failures**: Ensure taps navigate to correct screens

### Regression Testing
- Run full test suite after any code changes
- Pay special attention to layout and overflow handling
- Verify that existing functionality isn't broken
- Test on multiple devices and screen sizes

### Automated vs Manual Testing
- **Automated**: Basic functionality, overflow detection, property display
- **Manual**: Visual appearance, user experience, accessibility, edge cases
- **Both**: Navigation, theme consistency, performance

## Conclusion
This manual testing guide ensures comprehensive coverage of the Recent Classification List Items functionality. Regular execution of these tests will help maintain high quality and user experience standards.

For any issues found during testing, please document them thoroughly and include:
- Steps to reproduce
- Expected vs actual behavior
- Screenshots or screen recordings
- Device and environment information
- Severity and impact assessment 