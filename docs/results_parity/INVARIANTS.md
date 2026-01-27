# ResultScreen Consolidation - Non-Negotiable Invariants

> **Status:** Contract for ResultScreen V2 ← Legacy parity  
> **Last Updated:** 2026-01-27  
> **Owner:** @pranay

These invariants are **contracts**. If any change, it's not a "refactor"—it's a product change requiring PM approval.

---

## 1. Display Invariants

### 1.1 Classification Display
**Given:** Same `WasteClassification` input  
**Then:** User sees identical:
- Category name (e.g., "Recyclable", "Wet Waste")
- Confidence percentage
- Item name
- Key visual indicators (color coding, icons)

**Verification:** Golden test fixtures in `test/fixtures/classifications/`

### 1.2 Disposal Instructions
**Given:** Classification with known category  
**Then:** Disposal instructions match legacy exactly (text + order)

**Exception:** If instructions are fetched from server, verify cache behavior matches.

---

## 2. CTA (Call-to-Action) Invariants

### 2.1 Primary Actions Presence
| Action | Condition | Must Be Present |
|--------|-----------|-----------------|
| Share | `showActions = true` | ✅ Yes |
| Save | `showActions = true` AND not already saved | ✅ Yes |
| Re-analyze | `showActions = true` | ✅ Yes |
| Educational | Always (if content available) | ✅ Yes |

### 2.2 Action Behavior
- **Share:** Opens native share sheet with pre-populated text + dynamic link
- **Save:** Persists to local storage, shows confirmation, idempotent
- **Re-analyze:** Returns to camera with same image
- **Back:** Returns to previous screen (camera or history)

---

## 3. Analytics Invariants

### 3.1 Event Names (Exact Match)
```dart
// Screen view
'result_screen_viewed'

// User actions
'classification_shared'
'classification_saved'
'reanalyze_tapped'
'educational_content_viewed'
'achievement_celebration_shown'
```

### 3.2 Required Parameters
```dart
// All events must include:
'classification_id': string
'category': string
'confidence': double

// Screen view adds:
'item_name': string
'show_actions': bool
'auto_analyze': bool
'version': 'legacy' | 'v2'  // NEW: for migration tracking
```

### 3.3 Event Frequency
- **Screen view:** Exactly once per screen display
- **Actions:** Exactly once per user tap
- **Gamification:** Fired when achievements/points awarded

---

## 4. Navigation Invariants

### 4.1 Back Navigation
| From | Action | To |
|------|--------|-----|
| Result (from camera) | Back/Close | CameraScreen |
| Result (from history) | Back | HistoryScreen |
| Result (from deep link) | Back | HomeScreen |

### 4.2 Forward Navigation
| Action | Destination |
|--------|-------------|
| Re-analyze | ImageCaptureScreen (with existing image) |
| Educational | EducationalContentScreen |
| Disposal facilities | DisposalFacilitiesScreen |

---

## 5. Side Effect Invariants

### 5.1 Save Idempotency
```dart
// Critical: Multiple saves with same ID = single database entry
expect(await save(classification), succeeds);
expect(await save(classification), succeeds); // No duplicate
expect(await save(classification.copyWith(id: sameId)), succeeds); // No duplicate
```

### 5.2 Gamification Processing
- Points awarded exactly once per classification
- Achievements triggered exactly once per user
- Challenges completed at most once

### 5.3 Cloud Sync
- If enabled: Syncs exactly once per classification
- If disabled: No network calls
- Retry logic: Exponential backoff, max 3 attempts

---

## 6. State Management Invariants

### 6.1 Loading States
| State | UI Indicator | Duration |
|-------|--------------|----------|
| Initial | Skeleton/placeholder | < 100ms |
| Processing | Progress indicator | Until pipeline completes |
| Success | Content + animations | Persistent |
| Error | Error widget + retry | Until user dismisses |

### 6.2 State Persistence
- Result state **not** persisted across app restarts
- If user kills app on result screen, return to home

---

## 7. Performance Invariants

### 7.1 Render Budget
- First frame: < 16ms
- Full content: < 100ms
- Animations: 60fps

### 7.2 Memory
- Image disposal: Immediate after navigation
- No memory leaks on repeated open/close

---

## Parity Checklist

Use this in every ResultScreen PR:

```markdown
## ResultScreen Parity Checklist

- [ ] Display: Category, confidence, labels match legacy
- [ ] CTAs: All primary actions present under correct conditions
- [ ] Analytics: Event names and params verified
- [ ] Navigation: Back/forward destinations correct
- [ ] Side effects: Save idempotency tested
- [ ] Golden tests: Pipeline output matches snapshots
- [ ] Widget tests: Critical UI states pass
```

---

## Debug Tools

### Feature Flag Override
```dart
// In dev builds, add to URL:
?legacyResults=1  // Force legacy screen
?v2Results=1      // Force V2 screen
```

### Runtime Logging
Enable in debug builds:
```dart
ResultScreenConfig.debugLogging = true;
// Logs: version used, pipeline output, analytics events
```

---

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-01-27 | Initial invariants | @pranay |
