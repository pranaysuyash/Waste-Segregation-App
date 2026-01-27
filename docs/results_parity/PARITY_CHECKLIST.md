# ResultScreen Parity Checklist

> **Purpose:** Ensure ResultScreen V2 maintains behavioral parity with Legacy  
> **Usage:** Copy this checklist into every ResultScreen-related PR  
> **Status:** ⬜ Not Started | 🟡 In Progress | ✅ Complete | ⚠️ N/A

---

## PR Information

- **PR Title:** 
- **Related Issue:** 
- **Migration Phase:** ⬜ Phase 1 (Foundation) | ⬜ Phase 2 (Features) | ⬜ Phase 3 (Cleanup)
- **Date:** 

---

## Pre-Implementation

### Understanding
- [ ] I have read `INVARIANTS.md` and understand the contracts
- [ ] I know which Legacy features this PR ports
- [ ] I have identified potential parity risks

### Test Coverage
- [ ] New fixtures added if needed (`test/fixtures/classifications/`)
- [ ] Golden tests updated for pipeline changes
- [ ] Widget tests added for new UI states
- [ ] Analytics parity tests updated

---

## Display Parity

### Classification Display
- [ ] **Category name matches Legacy exactly**
  - Test with: `plasticBottleFixture`, `wetWasteFoodFixture`, `eWastePhoneFixture`
  - Verify: Same text, same capitalization

- [ ] **Confidence percentage displayed**
  - Test with: `unknownLowConfidenceFixture` (low), `plasticBottleFixture` (high)
  - Verify: Format "XX%" matches Legacy

- [ ] **Item name displayed prominently**
  - Test with: All fixtures
  - Verify: No truncation issues

- [ ] **Visual indicators match (colors, icons)**
  - Test with: `medicalWasteFixture` (red), `wetWasteFoodFixture` (green)
  - Verify: Same color codes (`#F44336`, `#4CAF50`)

### Disposal Instructions
- [ ] **Primary method text matches Legacy**
  - Test with: `plasticBottleFixture`
  - Verify: "Rinse and place in recycling bin"

- [ ] **Steps are identical in content and order**
  - Test with: `medicalWasteFixture` (has 5 steps)
  - Verify: Step count matches, content matches

- [ ] **Warnings displayed with same emphasis**
  - Test with: `medicalWasteFixture`, `hazardousBatteryFixture`
  - Verify: Warning icons, text styling

- [ ] **Tips section present and accurate**
  - Test with: `singleUsePlasticFixture`
  - Verify: "Switch to reusable metal/bamboo straws"

---

## CTA (Call-to-Action) Parity

### Primary Actions
- [ ] **Share button present when `showActions=true`**
  - Test: Navigate from camera, verify share icon visible
  - Test: Navigate from history, verify share icon visible

- [ ] **Save button present when not already saved**
  - Test: Fresh classification, verify save button
  - Test: Already saved, verify "Saved" state

- [ ] **Re-analyze button present when `showActions=true`**
  - Test: Tap re-analyze, returns to camera
  - Verify: Same image available for re-analysis

- [ ] **Actions hidden when `showActions=false`**
  - Test: Deep link with `showActions=false`
  - Verify: No action buttons visible

### Action Behavior
- [ ] **Share opens native share sheet**
  - Test: Tap share
  - Verify: Native sheet opens with pre-populated text
  - Verify: Dynamic link included in text

- [ ] **Save persists to storage**
  - Test: Tap save
  - Verify: Success feedback shown
  - Verify: Appears in history

- [ ] **Save is idempotent**
  - Test: Tap save twice quickly
  - Verify: Only one entry in database
  - Verify: No error on second tap

- [ ] **Re-analyze returns to camera**
  - Test: Tap re-analyze
  - Verify: Camera screen opens
  - Verify: Previous image available

---

## Analytics Parity

### Event Names
- [ ] **`result_screen_viewed` fired on screen load**
  - Check: Debug logs show event
  - Check: Analytics dashboard receives event

- [ ] **`classification_shared` fired on share**
  - Check: Event fires once per tap
  - Check: Not fired on failed share

- [ ] **`classification_saved` fired on save**
  - Check: Event fires once per successful save
  - Check: Not fired if already saved

### Event Parameters
- [ ] **All required params present on screen view**
  - Required: `classification_id`, `category`, `item_name`, `confidence`, `show_actions`, `auto_analyze`
  - Verify: No missing params in debug logs

- [ ] **Parameter values match classification data**
  - Test: `category` matches actual category
  - Test: `confidence` is correct decimal
  - Test: `item_name` matches display name

- [ ] **Version parameter included for migration tracking**
  - Verify: `version: 'v2'` in params
  - This is NEW - not in Legacy, but required

### Event Frequency
- [ ] **Screen view fires exactly once per display**
  - Test: Navigate to result, back, then forward
  - Verify: One event per display

- [ ] **Actions fire exactly once per tap**
  - Test: Rapid double-tap on share
  - Verify: One event (debounced)

---

## Navigation Parity

### Back Navigation
- [ ] **Back from camera result → CameraScreen**
  - Test: Classify from camera → result → back
  - Verify: Returns to camera

- [ ] **Back from history result → HistoryScreen**
  - Test: Tap history item → result → back
  - Verify: Returns to history

- [ ] **Back from deep link → HomeScreen**
  - Test: Open shared link → result → back
  - Verify: Returns to home

### Forward Navigation
- [ ] **Re-analyze → ImageCaptureScreen**
  - Verify: Camera opens with existing image

- [ ] **Educational content → EducationalContentScreen**
  - Test: Tap "Learn more"
  - Verify: Educational screen opens with correct content

- [ ] **Disposal facilities → DisposalFacilitiesScreen**
  - Test: Tap "Find facilities"
  - Verify: Facilities screen opens

---

## Side Effect Parity

### Save Idempotency
- [ ] **Multiple saves = single database entry**
  - Test: Save same classification 3 times
  - Query: Database has 1 entry

- [ ] **Same ID prevents duplicate**
  - Test: Create classification with same ID
  - Verify: No duplicate in history

### Gamification
- [ ] **Points awarded exactly once per classification**
  - Test: Same classification processed twice
  - Verify: Points increase only once

- [ ] **Achievements trigger exactly once**
  - Test: Achievement condition met
  - Verify: Achievement shows once
  - Verify: Not shown on re-view

### Cloud Sync
- [ ] **Syncs when enabled**
  - Test: Google sync ON
  - Verify: Classification appears in Drive

- [ ] **No sync when disabled**
  - Test: Google sync OFF
  - Verify: No network calls to Drive

---

## Performance Parity

### Render Performance
- [ ] **First frame < 16ms**
  - Measure: DevTools performance tab
  - Target: 60fps

- [ ] **Full content < 100ms**
  - Measure: Time to interactive
  - Target: < 100ms from navigation

### Memory
- [ ] **No memory leaks on open/close**
  - Test: Open/close result 10 times
  - Measure: Memory returns to baseline

---

## Debug Verification

### Debug Logging
- [ ] **Version logged on screen load**
  - Check logs: `[RESULT_SCREEN] Version selected`

- [ ] **Pipeline output logged**
  - Check logs: `[RESULT_SCREEN] Pipeline completed`

- [ ] **Analytics events logged**
  - Check logs: `[RESULT_SCREEN] Analytics event`

### Feature Flag Overrides
- [ ] **`?legacyResults=1` forces Legacy**
  - Test: Add param to URL
  - Verify: Legacy screen loads

- [ ] **`?v2Results=1` forces V2**
  - Test: Add param to URL
  - Verify: V2 screen loads

---

## Regression Testing

### Critical User Flows
- [ ] **Happy path: Camera → Result → Save → History**
  - Full flow works end-to-end

- [ ] **Share flow: Result → Share → Social app**
  - Share sheet opens
  - Content is correct

- [ ] **Re-analysis flow: Result → Re-analyze → Camera → New Result**
  - Previous image available
  - New result shows

### Edge Cases
- [ ] **Low confidence classification**
  - UI: Shows "Manual Review" state
  - Actions: Feedback prompt visible

- [ ] **No internet connection**
  - Save: Works locally
  - Share: Fails gracefully
  - Analytics: Queued for later

- [ ] **Very long item name**
  - UI: No overflow
  - Text: Ellipsis or wraps correctly

---

## Sign-Off

### Developer
- [ ] I have completed all relevant checklist items
- [ ] I have run all tests: `flutter test test/services/result_pipeline_golden_test.dart test/screens/result_screen_widget_test.dart test/services/analytics_parity_test.dart`
- [ ] All tests pass

### Reviewer
- [ ] I have verified critical parity items (Display, CTAs, Analytics)
- [ ] I have checked test coverage
- [ ] I approve this PR for merge

### Post-Merge
- [ ] Monitor analytics for 24 hours
- [ ] Check crashlytics for new issues
- [ ] Verify feature flag metrics

---

## Notes

<!-- Add any special considerations, known issues, or deviations from parity -->

