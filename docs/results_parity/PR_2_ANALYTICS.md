# PR 2: Port Analytics Tracking to ResultScreen V2

> **Status:** In Progress  
> **Related:** `INVARIANTS.md` Section 3 (Analytics)  
> **Risk Level:** High (data integrity critical)

---

## Summary

Ensure ResultScreen V2 fires the exact same analytics events as Legacy with identical parameters. This is critical for:
- Conversion tracking
- User behavior analysis
- Funnel optimization
- Business metrics

---

## Parity Checklist

### Event Name Contracts
- [ ] `result_screen_viewed` - Screen load
- [ ] `classification_shared` - Share button tap
- [ ] `classification_saved` - Save button tap
- [ ] `reanalyze_tapped` - Re-analyze button tap
- [ ] `educational_content_viewed` - Educational content tap
- [ ] `dispose_correctly_tapped` - Disposal instructions tap

### Required Parameters (All Events)
- [ ] `classification_id` - Unique ID
- [ ] `category` - Waste category
- [ ] `item_name` - Item name (screen view only)
- [ ] `confidence` - AI confidence (screen view only)

### Screen View Parameters
- [ ] `show_actions` - Boolean
- [ ] `auto_analyze` - Boolean
- [ ] `version` - 'v2' for tracking

### Event Frequency
- [ ] Screen view: Exactly once per display
- [ ] Actions: Exactly once per tap
- [ ] No duplicate events

---

## Implementation Plan

### 1. Analytics Service Integration

V2 currently uses `WasteAppLogger.aiEvent()` - need to verify this maps to actual analytics.

```dart
// Current V2
WasteAppLogger.aiEvent('result_screen_v2_viewed', context: {...});

// Should be
_analyticsService.trackScreenView('ResultScreen', parameters: {...});
```

### 2. Event Mapping

| Legacy Event | V2 Event | Status |
|--------------|----------|--------|
| `result_screen_viewed` | `result_screen_v2_viewed` | ⚠️ Different name! |
| `classification_shared` | Not implemented | ❌ Missing |
| `classification_saved` | Not implemented | ❌ Missing |
| `reanalyze_tapped` | Not implemented | ❌ Missing |

### 3. Required Changes

1. **Fix event names** - Use Legacy names for parity
2. **Add missing events** - Share, save, re-analyze
3. **Verify parameters** - Match exactly
4. **Add tests** - Analytics parity verification

---

## Files to Modify

1. `lib/screens/result_screen_v2.dart` - Fix event names, add missing events
2. `lib/services/result_pipeline.dart` - Add analytics for pipeline actions
3. `test/services/analytics_parity_test.dart` - Expand tests

---

## Testing Strategy

### Unit Tests
- Event names match Legacy
- All required parameters present
- Event frequency correct

### Integration Tests
- Events fire on actual user actions
- Parameters match classification data
- Events appear in analytics dashboard

---

## Critical Notes

⚠️ **Event Name Mismatch**: V2 uses `result_screen_v2_viewed` but Legacy uses `result_screen_viewed`. This breaks parity!

**Decision needed:**
- Option A: Keep `result_screen_v2_viewed` (new event, clean separation)
- Option B: Use `result_screen_viewed` (true parity, harder to distinguish)

**Recommendation:** Option B with `version` parameter for distinction.

---

## Migration Plan

1. Update V2 to use Legacy event names
2. Add `version: 'v2'` parameter for tracking
3. Verify in analytics dashboard
4. Update queries to use `version` parameter if needed

---

## Verification

```dart
// Expected events after PR
[
  {
    "event": "result_screen_viewed",
    "parameters": {
      "classification_id": "...",
      "category": "Dry Waste",
      "item_name": "Plastic Bottle",
      "confidence": 0.94,
      "show_actions": true,
      "auto_analyze": false,
      "version": "v2"
    }
  },
  {
    "event": "classification_shared",
    "parameters": {
      "category": "Dry Waste",
      "item": "Plastic Bottle"
    }
  }
]
```
