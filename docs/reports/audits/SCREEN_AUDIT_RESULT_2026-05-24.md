# Screen Audit Report: `ResultScreen`

**Date:** 2026-05-24  
**Scope:** Single-screen deep audit (component, flow, state, pipeline contracts)  
**Screen audited:** `lib/screens/result_screen.dart`  
**Method:** Evidence-first audit aligned with `motto_v2.md` (root-cause, trust, long-term maintainability)

---

## 1) Screen role and criticality

`ResultScreen` is the app’s decision-closure surface: users trust this screen to decide *how to dispose*. It is also tightly coupled to persistence, rewards, correction loops, and analytics. Any inconsistency here can directly produce wrong disposal behavior or trust erosion.

---

## 2) Flow map (ingress/egress)

## 2.1 Ingress
- Reached after classification from capture/instant flows with a `WasteClassification` payload.
- Supports `autoAnalyze` and manual-action contexts (`showActions` flag).

## 2.2 Internal pipeline flow
1. `initState` post-frame:
   - `_processClassification()` (ResultPipeline)
   - `_trackScreenView()`
   - `_selectEducationCard()`
   - optional `_checkRetroactiveGamification()`
2. Build subscribes to `resultPipelineProvider`.
3. `_processGamificationState(...)` reacts to pipeline completion to show points/achievement UI.

## 2.3 Egress
- Scan another → `ImageCaptureScreen` (replacement)
- Find facility → `DisposalFacilitiesScreen`
- Analytics → `WasteDashboardScreen`
- Learn more → `EducationalContentScreen` / `ContentDetailScreen`
- Correction loop can re-analyze in-place.

---

## 3) Component-by-component audit

## 3.1 Top shell and app bar actions

**Strengths**
- Compact app bar with back, refresh, share actions.
- `showActions` gating keeps screen reusable in constrained contexts.

**Risks**
- `_handleReanalyze()` currently just pops screen; action label can imply true re-analysis but behavior is “go back and rescan”.

---

## 3.2 Pipeline progress block

**Strengths**
- Uses `AnalysisProgressView` with mapped `ClassificationState` semantics.
- Retry path exists for retryable failures.

**Risks**
- State mapping is partly UI-derived (`_pipelineProgressState`) from a lightweight `ResultPipelineState`; it does not expose full underlying state-machine state, so user-facing status may underrepresent real transition position.

---

## 3.3 Confidence/review banners

**Strengths**
- Good safeguards for low confidence, fallback, and clarification-needed states.
- Explicit user prompt to verify before disposal.

**Risks**
- Banner logic depends on multiple fields (`confidence`, `clarificationNeeded`, category fallback), increasing edge-condition complexity and potential inconsistent precedence.

---

## 3.4 Disposal + explanation + educational cards

**Strengths**
- Strong progressive disclosure:
  - disposal accordion,
  - explanation panel,
  - story cards,
  - education card engine,
  - learn-more recommendations.

**Risks**
- Recommendation paths may branch to broad category screens rather than exact item-level content; educational relevance can dilute for niche items.

---

## 3.5 Impact and category analytics blocks

**Strengths**
- Rich informational UX (impact reveal, impact journey, snapshot, checklists, safety).
- Good user education density.

**Risks**
- Environmental score and impact labels risk being interpreted as precise rather than model-based estimates.
- Same “impact truth” duplication risk exists relative to Home/Dashboard.

---

## 3.6 Feedback/correction loop

**Strengths**
- Robust correction dialog integration.
- Re-analysis path updates local classification and tracks analytics.
- Auto-save after correction is convenient.

**Risks**
- Auto-save after correction can surprise users who expected confirm-before-save semantics.
- Correction flow composes many async actions (dialog, AI correction, save, analytics); error handling is present but UX state can still feel complex under slow networks.

---

## 3.7 Gamification popups and celebrations

**Strengths**
- Prevents duplicate popup firing via local guards.
- Delayed celebration sequence is user-friendly.

**Risks**
- UI-level duplicate guards + pipeline-level processing can still produce timing sensitivity if provider state mutates rapidly.

---

## 4) Dependency and contract audit

## Core dependency chain
- `ResultScreen` → `ResultPipeline` (`resultPipelineProvider`)
- `ResultPipeline` orchestrates:
  - `StorageService` save + dedup
  - `GamificationService` processing
  - optional cloud sync
  - community post
  - ads
  - analytics

## Strong contracts observed
- Duplicate classification short-circuit with content-hash path.
- Feedback dedup via stable key (`userId + classificationId`) with cloud existence check.
- State-machine guard in pipeline prevents duplicate processing transitions.

## Contract risks
1. **R-01 (P1): Dual-state modeling complexity**
   - Pipeline has its own simplified `ResultPipelineState` while also using classification state-machine transitions.
   - Risk: UI can drift from authoritative workflow state.

2. **R-02 (P1): Reanalyze action semantics mismatch**
   - App-bar “reanalyze” pops instead of in-place re-run.
   - Risk: user mental model mismatch in critical disposal flow.

3. **R-03 (P2): Overloaded screen responsibility**
   - Result UI handles many domains (education, disposal, impact, gamification, correction, sharing).
   - Risk: harder safe iteration and testing.

4. **R-04 (P2): Multiple side effects in one completion pass**
   - Save, gamification, sync, community, ads, analytics.
   - Non-critical failures are tolerated, but ordering and consistency under partial failure need explicit policy visibility.

---

## 5) Prioritized findings

## P1

### RS-01: State authority split between simplified pipeline state and lifecycle state machine
- Root cause: two overlapping abstractions for flow status.
- Impact: status messaging and retry decisions can become inconsistent.

### RS-02: “Re-analyze” action label can mislead
- Root cause: action semantics not aligned with implementation.
- Impact: users may think model reprocessing occurred when they only navigated back.

### RS-03: Disposal-trust surface uses estimate-heavy impact framing without explicit confidence language
- Root cause: model/heuristic metrics surfaced as concise facts.
- Impact: trust erosion if perceived as deterministic.

## P2

### RS-04: Result screen is highly multi-concern and large
- Root cause: incremental feature accumulation in a single screen file.
- Impact: maintainability, regression surface.

### RS-05: Correction pipeline auto-saves by default
- Root cause: convenience-first design choice.
- Impact: can conflict with user expectations in sensitive flows.

## P3

### RS-06: Educational relevance can degrade for edge categories
- Root cause: category-first fallback recommendation routing.
- Impact: lower educational click-through quality.

---

## 6) Verified vs inferred

## Verified
- Pipeline orchestration stages and dedup logic.
- Feedback idempotency behavior and cloud dedup check path.
- Reanalyze action behavior and navigation targets.
- Multi-section rendering and async coupling.

## Inferred
- Real-world frequency of UI-state race conditions under adverse network conditions.
- User perception impact of auto-save-after-correction.

---

## 7) No-code recommendations (documentation/product)

1. Define a canonical **result-state source-of-truth policy** (UI state derivation contract).
2. Clarify action wording for “reanalyze” vs “rescan” in UX spec.
3. Add explicit “estimated” framing guidelines for impact values on result/home/dashboard.
4. Create a result-screen decomposition plan doc (workflow/presentation cards/action handlers).

---

## 8) Final assessment

`ResultScreen` is feature-rich and operationally robust, but it carries high trust responsibility and currently has **state-model and semantics clarity risks** that should be hardened before additional complexity is added.

**Overall status:** Strong capability, medium-high complexity risk; prioritize trust and state-contract simplification.
