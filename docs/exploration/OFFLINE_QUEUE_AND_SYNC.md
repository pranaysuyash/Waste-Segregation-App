# Offline Queue & Sync Contract

**Date**: 2026-05-23
**Status**: Decision doc — specifying the offline queue contract
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) entry 11
**Decision this unblocks**: Shipping offline as a first-class promise rather than best-effort
**Kill criteria**: If <5% of users ever trigger the offline queue, the reconciliation complexity isn't justified

---

## 1. Current Architecture

### Services

| Service | File | Role |
|---------|------|------|
| `OfflineQueueService` | `lib/services/offline_queue_service.dart` | Queue management with Hive persistence |
| `OfflineClassificationService` | `lib/services/offline_classification_service.dart` | Degradation tier logic |
| `OfflineDegradationTier` | `lib/models/offline_degradation_tier.dart` | Enum: `fullOffline`, `deterministicOnly`, `queued` |
| `OfflineResultBanner` | `lib/widgets/offline_result_banner.dart` | UI for offline classification status |

### Data model (`QueuedClassification`)

Stored in Hive:
- `id`: unique identifier
- `imageBytes`: the captured image
- `region`: user's region
- `queuedAt`: timestamp
- `retryCount`: retry attempts (max 3)
- `userId`: user ID
- `imageName`: filename

### Flow

```
Capture → Check connectivity → Try Layer 0 → Show hint if available → Queue if offline
  → Listen for connectivity → Process queue when online → Save result → Notify
```

### Degradation tiers

| Tier | Available | UX |
|------|-----------|-----|
| `fullOffline` | Layer 0 + Layer 1 | Normal result screen |
| `deterministicOnly` | Layer 0 only | Accepted: full result; Hint: degraded banner; Reject: queue |
| `queued` | Neither | Queue everything (existing behaviour) |

---

## 2. The Contract

### Guarantees

1. **Queue persistence**: Every queued item survives app restart (Hive-backed)
2. **Order preservation**: Items process in FIFO order when connectivity returns
3. **Token accounting**: Tokens deducted on successful processing, refunded on permanent failure
4. **Max retries**: 3 attempts before marking as permanently failed
5. **Idempotent processing**: Each queued item has a unique ID; duplicate processing is detected

### Offline hint lifecycle

```
1. Layer 0 produces hint (confidence < accept threshold but > reject threshold)
2. Build degraded WasteClassification with isOfflineHint = true
3. Show result with OfflineResultBanner
4. Queue same image for cloud verification
5. When cloud processes:
   a. If result matches hint → upgrade confidence, remove hint flag
   b. If result differs → show "Updated" notification, replace classification
   c. If result confirms safety concern → upgrade to full result
6. History entry gets updated in-place (not duplicated)
```

### What the user sees

| State | UI |
|-------|-----|
| Queued, not yet processed | "Position #N in queue" on job queue screen |
| Offline hint shown | Result screen with blue "Offline result — will verify when connected" banner |
| Cloud processing complete (match) | Banner updates to "Verified" (green), auto-dismisses after 3s |
| Cloud processing complete (different) | "Classification updated" notification with diff summary |
| Cloud processing failed (after 3 retries) | "Classification unavailable" — hint result remains with disclaimer |

---

## 3. Gaps

### Critical: No result reconciliation

When cloud processes a queued item, there is no mechanism to update the offline hint result. The user sees two separate results for the same image — the offline hint in history and the cloud result as a new entry.

**Fix**: When processing a queued item, check if an offline hint already exists for the same image (match by `queuedAt` timestamp + user ID). If found, update in-place rather than creating a new classification.

### Critical: No conflict resolution

If the user provides manual feedback on an offline hint, and the cloud later returns a different classification, the cloud result overwrites the user's correction.

**Fix**: User corrections take precedence. If the user corrected the hint, the cloud result is logged but the user's correction stands. Show a dismissable "Cloud suggests X instead" notification.

### High: Queue items invisible in history

Queued items don't appear in classification history until processed. User has no way to see "I took 5 photos offline, they're all in the queue."

**Fix**: Show queued items in history with a "Pending" badge and progress indicator. Remove badge when processed.

### Medium: No pause/resume

Queue processes automatically when online. No way to pause (e.g., on limited mobile data).

**Fix**: `OfflineQueueService.pauseQueue()` / `resumeQueue()` with a settings toggle "Only sync on Wi-Fi."

---

## 4. Acceptance Tests

### AT-OQ-1: Queue survives restart

- Queue 3 items offline
- Kill and restart app
- Verify: queue count = 3
- Go online
- Verify: all 3 process successfully

### AT-OQ-2: Token refund on failure

- Queue 1 item offline (user has 10 tokens)
- Go online, simulate API failure × 3
- Verify: tokens refunded = cost of 1 classification
- Verify: item marked as permanently failed

### AT-OQ-3: Offline hint upgraded on match

- Capture item offline, Layer 0 produces hint "Wet Waste" at confidence 0.6
- Queue for cloud
- Go online, cloud returns "Wet Waste" at confidence 0.92
- Verify: hint updated to confidence 0.92, `isOfflineHint = false`, banner removed

### AT-OQ-4: Offline hint corrected on mismatch

- Capture item offline, Layer 0 hints "Dry Waste" at confidence 0.55
- Queue for cloud
- Go online, cloud returns "Wet Waste" at confidence 0.88
- Verify: classification updated to "Wet Waste", notification shown
- Verify: history entry updated in-place, not duplicated

### AT-OQ-5: User correction preserved

- Capture item offline, Layer 0 hints "Dry Waste"
- User manually corrects to "Wet Waste"
- Go online, cloud returns "Dry Waste"
- Verify: user's "Wet Waste" correction stands
- Verify: cloud result logged but not applied

### AT-OQ-6: FIFO order preserved

- Queue items A, B, C offline
- Go online
- Verify: processing order = A → B → C

---

## 5. Related

- [Offline Degradation UX](../EXPLORATION_TOPICS.md#g6-offline-degradation-ux-) — G6 tier system
- [Offline-First Flow](../EXPLORATION_TOPICS.md#9-offline-first-flow-) — broader offline architecture
- [OfflineQueueService](../../lib/services/offline_queue_service.dart) — implementation
- [OfflineClassificationService](../../lib/services/offline_classification_service.dart) — tier determination
