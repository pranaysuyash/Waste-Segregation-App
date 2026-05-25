# Batch Classification & Background Processing

**Date**: 2026-05-25
**Status**: Exploration — design concepts exist in code, no implementation
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) entry G5
**Decision this unblocks**: Whether to invest in batch API integration and background processing infrastructure
**Kill criteria**: If OpenAI Batch API discount is <20% (not the advertised 50%), or if user scan patterns show <5% of scans would benefit from deferred processing

---

## 1. Current State

The codebase has two scaffolding traces:

- **`VisionModelConfig.AnalysisMode.batch`** — an enum value exists for batch mode but no pipeline reads it
- **`CostGuardrailService.isBatchModeEnforced`** — a guard that can force batch mode when budgets are exceeded, but the batch processing path itself is not implemented

No background task management exists. No queue for deferred classification. No pre-warming cache.

---

## 2. Two Complementary Ideas

### 2.1 Batch Classification

**Concept**: Classify multiple images in one API call (or queue them for off-peak processing) rather than one-at-a-time.

**OpenAI Batch API**: Offers a **50% cost reduction** at the cost of up to **24-hour turnaround**. Create a batch file of multiple classification requests, submit, poll for completion, collect results.

| Dimension | Real-Time | Batch |
|-----------|-----------|-------|
| Latency | 2-5 seconds | Up to 24 hours |
| Cost (GPT-4.1-nano) | ~$0.0014/image | ~$0.0007/image |
| UX | Instant result | "Analyzing in background" |
| Use case | Live scan at bin | Review history, impact stats, bulk upload |

**UX patterns**:
- **Explicit queue**: User taps "Analyze Later" on the result screen, item goes into a batch queue. Later, user opens the queue and sees results trickle in.
- **Automatic batch**: Batch mode engages when the user is on Wi-Fi + charging, or when the daily budget is near its cap.
- **Batch as premium feature**: Offer instant analysis on free tier with a per-day cap, then switch to batch for overage.

**OpenAI Batch API workflow**:
1. Create a `.jsonl` file with N classification requests following the batch format
2. Upload file via OpenAI Files API
3. Create batch job referencing the file
4. Poll `/batches/{id}` for completion
5. Retrieve results and reconcile with the local queue

### 2.2 Background Processing

**Concept**: When the device is idle (charging + Wi-Fi), opportunistically:
- Process recently captured but unclassified images
- Pre-warm the disposal cache for likely follow-up queries
- Download model updates for Layer 1 (on-device VLM)

**Platform infrastructure**:

| Platform | Background Task API | Constraints |
|----------|-------------------|-------------|
| Android | WorkManager | Minimum 15-min interval, battery/network constraints, Doze mode exemptions |
| iOS | BGTaskScheduler | `BGProcessingTask` for non-critical, `BGAppRefreshTask` for short fetches, both limited by iOS budget |
| Flutter | workmanager package | Wraps both platforms, supports periodic tasks, constraints |

**Pre-warming strategy**:
If the user recently classified "plastic bottle", pre-fetch `generateDisposal` results for the top-3 most common follow-up items. This requires:
- A `DisposalCache` service with TTL-based expiry
- A prediction model (Markov chain or simple frequency table) mapping `current_item → likely_next_items`
- Background task triggers this pre-warming

---

## 3. Key Questions

### Batch Classification

- **Which API path**: OpenAI Batch API (server-side, implemented in Firebase Function) or client-side queue with batched individual calls?
- **Queue persistence**: Store pending items in Hive or Firestore? Hive is faster for local reads; Firestore enables cross-device sync.
- **Completion notification**: Push notification when batch results are ready? Or just in-app badge/indicator?
- **Batch window**: 24h is OpenAI's SLA. Do we let users check earlier? (Some results may complete in 1-2 hours.)
- **Cost vs quality trade-off**: Does the 50% cost reduction justify the latency hit for which user segments?

### Background Processing

- **Queue management**: FIFO vs priority queue (hazardous items classify first)?
- **Network cost**: Background processing on Wi-Fi only vs cellular allowed (with user consent)?
- **Battery impact**: How much processing per background run before it's wasteful?
- **Cache invalidation**: How long do pre-warmed disposal results stay fresh? What triggers a refresh?
- **Offline-first interaction**: If the user captures 5 items offline and background processing classifies them later, how does the UI update?

---

## 4. Dependencies

| Dependency | Status | Notes |
|-----------|--------|-------|
| `VisionModelConfig.AnalysisMode.batch` | Exists | Not wired to any pipeline |
| `CostGuardrailService.isBatchModeEnforced` | Exists | Flag exists, no queue processor |
| OpenAI Batch API (server-side) | Not implemented | Requires `classifyImageBatch` Firebase Function |
| Background task infrastructure | Not implemented | `workmanager` package in pubspec? Need to verify |
| Disposal pre-warm cache | Not implemented | Needs cache service + prediction model |
| Push notification for batch completion | Not implemented | Firebase Cloud Messaging integration exists |

---

## 5. Recommendations

### Phase 1: Batch Queue Scaffold (P2)
- Implement `BatchClassificationQueue` service (Hive-backed, priority-aware)
- Add "Analyze Later" button to result screen
- Store queued items with capture timestamp, image path, priority

### Phase 2: Server-Side Batch API (P2)
- Add `classifyImageBatch` to Firebase Functions
- Implement OpenAI Batch API file creation + polling
- Wire `generateDisposal` to run after batch classification

### Phase 3: Background Task Infrastructure (P3)
- Add `workmanager` package if not present
- Implement periodic background classification task
- Add pre-warming cache for disposal hints

### Phase 4: Batch as Premium Lever (P3)
- Free tier: N instant scans/day, then batch-only
- Premium tier: unlimited instant scans, optional batch for history
- Surface batch results in history with "Batch" badge

---

## 6. Related

- [G4. Backend Classification Proxy](../EXPLORATION_TOPICS.md#g4-backend-classification-proxy-) — server-side proxy that would host batch API
- [Token Economy & Pricing Coherence](TOKEN_ECONOMY_AND_PRICING_COHERENCE.md) — batch pricing as a premium lever
- [Offline Queue & Sync Contract](OFFLINE_QUEUE_AND_SYNC.md) — related queue infrastructure
- [AI Cost Telemetry & Guardrails](AI_COST_TELEMETRY_AND_GUARDRAILS.md) — cost monitoring that triggers batch mode
- Entry 10 (AI Cost Telemetry) — budget-based batch enforcement
