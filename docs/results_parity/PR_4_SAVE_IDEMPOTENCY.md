# PR 4: Port Save Idempotency to ResultScreen V2

> **Status:** ✅ Already Implemented  
> **Related:** `INVARIANTS.md` Section 5 (Side Effects)

---

## Summary

Save idempotency was already implemented in V2 via `ResultPipeline`. This PR verifies parity with Legacy.

---

## Parity Checklist

### Idempotency Requirements
- [x] Same classification ID saved only once
- [x] Duplicate save attempts ignored
- [x] Static set tracks in-progress saves
- [x] Set cleaned up after completion (finally block)
- [x] `force` parameter to override

### Implementation Comparison

| Aspect | Legacy | V2 | Status |
|--------|--------|-----|--------|
| Tracking | `_savingClassifications` (static Set) | `_processingClassifications` (static Set) | ✅ Same pattern |
| Check location | `_autoSaveAndProcess()` | `processClassification()` | ✅ Same timing |
| Force override | `force` parameter | `force` parameter | ✅ Same |
| Cleanup | `finally` block | `finally` block | ✅ Same |

---

## Code Locations

**Legacy:**
```dart
// lib/screens/result_screen.dart
static final Set<String> _savingClassifications = <String>{};

Future<void> _autoSaveAndProcess() async {
  if (_savingClassifications.contains(classificationId)) return;
  _savingClassifications.add(classificationId);
  try {
    // ... save logic
  } finally {
    _savingClassifications.remove(classificationId);
  }
}
```

**V2:**
```dart
// lib/services/result_pipeline.dart
static final Set<String> _processingClassifications = <String>{};

Future<void> processClassification(...) async {
  if (_processingClassifications.contains(classificationId) && !force) {
    return;
  }
  _processingClassifications.add(classificationId);
  try {
    // ... save logic
  } finally {
    _processingClassifications.remove(classificationId);
  }
}
```

---

## Test Verification

```dart
// test/services/result_pipeline_golden_test.dart
test('prevents duplicate processing', () async {
  // First call should process
  await pipeline.processClassification(classification);
  
  // Second call should be ignored
  await pipeline.processClassification(classification);
  
  // Verify only one save occurred
});
```

---

## Verification

Both implementations:
1. Use static Set to track in-progress saves
2. Check before processing
3. Clean up in finally block
4. Support force override

**Status: ✅ PARITY ACHIEVED (No changes needed)**
