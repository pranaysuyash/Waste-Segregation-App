# G6: Offline Degradation UX

## Context

G1 (Deterministic Pre-processing Classifier / Layer 0) is now complete. Layer 0 handles ~30-40% of common items with zero AI cost and zero network. This fundamentally changes the offline story: **offline users can now get real classifications for many items instead of just queuing everything.**

Currently, when a user is offline:
1. The app queues the image and shows "Queued for offline processing" (22% progress)
2. User sees "Position #X in queue" then navigated back
3. No classification result is shown until connectivity returns
4. Auto-processing happens silently when back online

This is a poor experience. G6 introduces three offline degradation tiers:

| Tier | Available Layers | UX |
|------|-----------------|-----|
| **Tier 1**: Full offline | Layer 0 + Layer 1 | Normal result screen (future — needs real on-device model) |
| **Tier 2**: Deterministic only | Layer 0 only | Full result screen for accepted items; graceful "more detail when connected" for unclassifiable items |
| **Tier 3**: Nothing available | Neither layer | Current queue behaviour (existing) |

**What this plan delivers**: Tier 2 — the only actionable tier right now since G1 exists but Layer 1 (on-device VLM) doesn't yet.

## Current Architecture (what exists)

### Offline flow in `image_capture_screen.dart`
- `_isOnline` flag (line 96), connectivity listener (lines 212-232)
- `_tryLocalClassification()` (lines 703-718) — tries Layer 0 before offline queue
- Lines 825-829: If offline AND Layer 0 didn't accept → queues via `_queueAnalysisOffline()`
- Lines 818-823: Layer 0 attempt happens BEFORE the offline check

### Result display
- `_showResultOrFallback()` (lines 351-373) — navigates to `ResultScreenWrapper`
- ResultScreen already has confidence-based UI: low confidence banner (<70%), "needs review" banner for fallback
- No offline-specific badges exist

### Classification state machine
- `queuedOffline` state exists with proper transitions
- `localClassifying` → can transition to `queuedOffline`

### What's already correct
- Layer 0 runs before the offline check, so accepted items already show results offline
- The classification pipeline is already wired in `_tryLocalClassification()`

## The Gap

When Layer 0 rejects/escalates offline, the user gets queued with zero feedback about what the item might be. The fix: show a **degraded result** that indicates "this is our best guess, but it needs cloud verification when you're back online."

## New Files

### 1. `lib/models/offline_degradation_tier.dart`
- `enum OfflineDegradationTier { fullOffline, deterministicOnly, queued }`
- Helper function `OfflineDegradationTier currentTier` that checks Layer 0 + Layer 1 availability

### 2. `lib/widgets/offline_result_banner.dart`
- A banner widget shown on the ResultScreen when a classification was produced offline
- Shows: "Analysed offline (deterministic)" for Layer 0 accepted results
- Shows: "Best guess — will verify when connected" for Layer 0 hint results
- Colour: blue/teal info theme (not warning/error)
- Icon: cloud-off or wifi-off

## Existing Files to Modify

### 3. `lib/screens/image_capture_screen.dart`
**Changes to `_analyzeImage()` offline path (around lines 820-835)**:

Current flow:
```
Layer 0 attempt → if offline → queue everything
```

New flow:
```
Layer 0 attempt → if Layer 0 accepted → show result (ALREADY WORKS)
                → if offline AND Layer 0 hinted → show degraded result with hint + queue for cloud verification
                → if offline AND Layer 0 rejected/escalated → queue (existing behaviour)
```

Specific changes:
- After `_tryLocalClassification()` returns false (line 822), check if Layer 0 produced a `hint` decision
- If hint: show a degraded `WasteClassification` using the hint data, mark it with `classificationLayer = 'layer0_hint_pending_cloud'`
- Also queue it for cloud verification in the background
- ~25 lines of new code

**New method: `_tryShowOfflineHint()`**
- Takes the Layer 0 result from the router
- If `Layer0Decision.hint`, builds a `WasteClassification` with hint data
- Adds `isOfflineHint = true` metadata
- Calls `_showResultOrFallback()` to show it
- Returns `true` if a hint was shown

### 4. `lib/services/classification_pipeline.dart`
- Add method `tryLocalWithHint()` that returns both the Layer 0 result AND the decision, so the caller can distinguish accept/hint/reject
- Currently `tryLocalOnly()` only returns accepted classifications (or null) — it discards hint data
- New method returns a record `(WasteClassification? accepted, Layer0Result? layer0Result)`

### 5. `lib/widgets/analysis_progress_view.dart`
- Update the `queuedOffline` state (around line for 22% progress)
- If Layer 0 produced a hint, show a different message: "Offline — best guess saved, will verify when connected"
- Instead of just queuing and navigating back, show the hint result

### 6. `lib/models/waste_classification.dart`
- Add `bool isOfflineHint` field (defaults to false, Hive-field compatible)
- When `true`, the ResultScreen shows the offline result banner
- Not persisted to cloud (transient display flag) — or if persisted, marked so history can show the badge

### 7. `lib/screens/result_screen.dart`
- Show `OfflineResultBanner` when `classification.isOfflineHint == true`
- Place it above the existing confidence/needs-review banners
- Shows "Offline result — will verify when connected" with a sync icon
- Tappable: explains the degradation tier system

### 8. Remote config
- `offline_degradation_tier2_enabled: true` — kill switch for the hint-based degraded result feature

## Implementation Order

1. `offline_degradation_tier.dart` — enum + helper
2. `waste_classification.dart` — add `isOfflineHint` field
3. `classification_pipeline.dart` — add `tryLocalWithHint()` method
4. `image_capture_screen.dart` — new offline hint path + `_tryShowOfflineHint()`
5. `offline_result_banner.dart` — banner widget
6. `result_screen.dart` — integrate banner
7. `analysis_progress_view.dart` — updated offline state messaging
8. `remote_config_service.dart` — add feature flag
9. Tests for pipeline hint path + screen integration
10. `flutter analyze` + `flutter test`

## Key Decisions

- **Hint results shown offline are real results** — not a modal or dialog. User sees a full result screen with disposal instructions, just with an added banner explaining it's an offline best guess.
- **Hint results are queued for cloud verification** — when back online, the item gets a cloud classification. If the cloud result differs, the user gets a notification or the history item updates.
- **Rejected/escalated items still queue** — the existing queue behaviour is unchanged for items Layer 0 can't help with.
- **`isOfflineHint` is not persisted in Hive** — it's a transient UI flag set during the flow. History items won't show the badge after restart. This avoids schema migration complexity.
- **Tier 1 (full offline) is NOT in scope** — needs a real on-device VLM. Only Tier 2 is actionable now.
- **Barcode lookup won't work offline** — it calls Open Food Facts API (network). The barcode service already fails fast (3s timeout) and returns `found: false`, so the router falls through to color histogram. No code change needed — color histogram is the only working sub-path offline.
- **`tryLocalOnly()` discards hint data** — it returns `null` for hints, rejects, and escalations. We need `tryLocalWithHint()` to expose the `Layer0Result` so the caller can check `decision == hint` and build a degraded classification.

## Verification

1. `flutter analyze` — zero new errors
2. `flutter test` — all tests pass + new tests pass
3. Manual test flow:
   - Go offline (airplane mode)
   - Capture image of a clear waste item (plastic bottle, food scraps)
   - Verify: Layer 0 accepts → full result shown (no banner needed)
   - Capture image of ambiguous item
   - Verify: Layer 0 hints → degraded result with "offline best guess" banner
   - Capture image of safety item (battery, medical)
   - Verify: Layer 0 escalates → queued (existing behaviour)
   - Go back online
   - Verify: queued items process and appear in history
4. Check logs for `Layer 0 hint shown offline` or `Layer 0 queued (offline)`
