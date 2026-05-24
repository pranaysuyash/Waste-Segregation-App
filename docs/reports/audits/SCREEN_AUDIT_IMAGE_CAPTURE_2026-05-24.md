# Screen Audit Report: `ImageCaptureScreen`

**Date:** 2026-05-24  
**Scope:** Component-by-component review (capture → quality gate → local/cloud analysis → queue → navigation)  
**Screen audited:** `lib/screens/image_capture_screen.dart`  
**Method:** Evidence-first static architecture and flow audit (no app code changes)

---

## 1) Screen role and criticality

`ImageCaptureScreen` is the highest-risk conversion surface in the app. It gates:
- image intake quality,
- local/cloud routing,
- token/quota monetization enforcement,
- offline queue behavior,
- navigation into user-visible result flows.

Any semantic mismatch here directly affects trust, cost, and revenue controls.

---

## 2) Flow map (ingress/egress)

## 2.1 Ingress
- Entered with one of:
  - `File imageFile`,
  - `XFile xFile`,
  - `Uint8List webImage`.
- Supports `autoAnalyze` mode that bypasses manual review UI.
- If no image is present, triggers `_captureImage()` on init.

## 2.2 Processing phases
1. Restoration + image bootstrap (`RestorationMixin` path restoration).
2. Connectivity + offline queue listeners startup.
3. Optional auto-region suggestion using `SegmentationService`.
4. User trigger `_analyzeImage()`:
   - guardrail mode refresh,
   - token affordability + daily scan check,
   - quality gate,
   - local classification attempt (`classificationPipelineProvider`),
   - offline hint or offline queue if disconnected,
   - cloud classification fallback,
   - token spend,
   - result/fallback navigation.

## 2.3 Egress
- Single result path: `ResultScreenWrapper` via `Navigator.pushReplacement`.
- Multi-region path: `CombinedResultScreen`.
- Batch path: `JobQueueScreen` / pop to root.
- Offline queue path may pop current screen after queue.

---

## 3) Component-level findings

## 3.1 State ownership and lifecycle machine

**Evidence:**
- Canonical lifecycle enum in `lib/models/classification_state.dart`.
- State provider in `lib/providers/classification_state_provider.dart`.
- Progress UI in `lib/widgets/analysis_progress_view.dart` derives visuals from `ClassificationState`.

**Strengths:**
- Explicit state graph is strong and auditable.
- Progress rendering is consistent with state-machine model.

**Risk:**
- Screen still uses local booleans (`_isSelectingRegions`, `_isOnline`, `_useSegmentation`, `_hasShownSuggestion`, etc.) alongside state machine for material flow behavior.
- This creates dual-state authority risk (state machine + local branch state), especially around cancel/retry/select-regions transitions.

---

## 3.2 Dependency style consistency (Riverpod + Provider)

**Evidence:**
- `ConsumerStatefulWidget` + `ref.read(...)` throughout.
- Also uses `context.read<PremiumService>()` from Provider package.

**Strengths:**
- Works functionally.

**Risk:**
- Mixed DI pattern at the most critical flow increases accidental drift and test complexity.
- Monetization gate (`PremiumService`) is not read through same DI boundary as token and pipeline providers.

---

## 3.3 Token and quota enforcement ordering

**Evidence:**
- Intent logging happens before affordability checks.
- Affordability checked early and re-checked before cloud call.
- Token spend happens after successful instant cloud path.

**Strengths:**
- Re-check before network call is good anti-race protection.
- Clear zero-balance sheet fallback exists.

**Risk (P1):**
- Local classification acceptance path (`_tryLocalClassification`) can return before token spend path for instant analysis is executed.
- If business rule expects any successful analysis to be billable, this may undercharge local-accepted paths.
- If local path is intentionally free, this must be explicitly documented to avoid policy ambiguity.

---

## 3.4 Offline flow + hint fallback

**Evidence:**
- Offline queue service integrated.
- Tier-2 offline hint path controlled by Remote Config (`offline_degradation_tier2_enabled`).
- Queue processor in `offline_queue_service.dart` includes token spend/refund handling.

**Strengths:**
- Good resilience and queue telemetry.
- Reconciliation path for offline hint replacement exists in queue processor.

**Risks:**
- UI path sets `classificationSucceeded` after queueing offline then pops screen; this can semantically imply completed classification instead of queued intent.
- Offline queue stats API notes processed count as always zero (pending-only representation), which can mislead dashboard consumers if interpreted as true throughput.

---

## 3.5 Navigation and result semantics

**Evidence:**
- Primary result path uses `pushReplacement(ResultScreenWrapper)`.
- Multi-item selection path uses `push(CombinedResultScreen)`.

**Strengths:**
- Explicit fallback path to awaiting confirmation is clear.

**Risk:**
- Divergent result routes from one screen can generate inconsistent post-result back stack/user expectations.
- This aligns with existing cross-screen route policy inconsistency risk already flagged in master backlog.

---

## 3.6 Segmentation pathways

**Evidence:**
- Two segmentation pathways:
  - debug grid segmentation (`ENABLE_DEBUG_GRID_SEGMENTATION`),
  - manual region selector + auto-detected suggested regions.

**Strengths:**
- Good exploration UX for multi-item photos.

**Risk:**
- Segmentation mode complexity is high and partially feature-flagged, increasing branch behavior variance between builds.
- Needs explicit product contract per mode (production vs debug/demo).

---

## 4) Prioritized findings

## P1 findings

### IC-01: Billing-policy ambiguity on local-accepted classifications
- Local acceptance can short-circuit before token-spend path associated with instant cloud analysis.
- Needs explicit product policy decision: local-accepted classification = free or billed?

### IC-02: Dual state authority in critical flow
- State machine is canonical, but many control branches still live in local booleans.
- Increases risk of inconsistent UI/transition behavior under retries, cancellation, and region-selection mode.

## P2 findings

### IC-03: Mixed DI pattern in monetization-critical flow
- Riverpod + Provider mixture in same screen raises maintenance and test friction.

### IC-04: Queued-offline success semantics can overstate completion
- Transition to `classificationSucceeded` after queueing can be interpreted as final success rather than deferred processing.

### IC-05: Multi-route result behavior from same source screen
- Increases user flow and back-stack inconsistency risk.

## P3 findings

### IC-06: Segmentation mode complexity is high and partially debug-gated
- Valuable feature set, but requires tighter contract docs for production behavior expectations.

---

## 5) Dependency map (screen-local)

- **State control:**
  - `classification_state_provider.dart`
  - `classification_state.dart`
  - `analysis_progress_view.dart`
- **Local routing / inference:**
  - `classification_pipeline_providers.dart`
  - `classification_pipeline.dart`
- **Cloud + queue path:**
  - `aiServiceProvider` (app providers)
  - `offline_queue_service.dart`
  - `ai_job_providers.dart`
- **Monetization controls:**
  - `tokenServiceProvider`
  - `PremiumService` (Provider-based read)
- **Policy controls:**
  - `RemoteConfigService` for offline hint flag and routing strategy.

---

## 6) Verified vs inferred

## Verified
- Canonical state machine exists and is used by progress UI.
- Screen uses mixed Riverpod and Provider reads.
- Local classification path can short-circuit before cloud branch token-spend logic.
- Offline queue and hint fallback are both active code paths.

## Inferred
- Exact charging intent for local-accepted results is not explicit in current screen contract and may be policy-dependent.

---

## 7) No-code recommendations

1. Define explicit monetization contract for local-accepted classification outcomes and enforce it uniformly.
2. Reduce local boolean control branches where feasible by moving more flow intent into explicit state-machine substates/events.
3. Normalize DI boundary for monetization and classification dependencies in this screen.
4. Clarify queue-success language/state so “queued” and “completed” are not conflated.
5. Standardize result-route policy across single-item and multi-item outcomes.

---

## 8) Final assessment

`ImageCaptureScreen` is architecturally ambitious and operationally strong, but it carries **high complexity concentration** in one surface. The main risks are not missing features; they are **policy clarity and state-consistency under branching paths**.

**Overall status:** Powerful implementation, medium-high consistency risk; prioritize billing-policy clarity and state/route unification next.
