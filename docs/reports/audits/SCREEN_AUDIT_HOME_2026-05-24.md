# Screen Audit Report: `HomeScreen`

**Date:** 2026-05-24  
**Scope:** Single-screen deep audit (components + flows + service contracts)  
**Screen audited:** `lib/screens/home_screen.dart`  
**Method:** Code-path audit aligned with `motto_v2.md` (root-cause focus, trust-first, architecture-safe)

---

## 1) Screen role and why it matters

`HomeScreen` is the canonical app entry surface and behavior orchestrator. It is not only a landing page—it initiates:
- scan/upload routing,
- habit-loop nudges,
- educational recommendation paths,
- gamification visibility,
- transitions into dashboard/history/achievements/settings/leaderboard.

Any UX/data drift here compounds across the whole app.

---

## 2) Flow map (ingress and egress)

## 2.1 Ingress
- Canonical home route via app navigation wrapper (`HomeScreen` is explicitly marked canonical in file header docs).
- Home can be loaded in guest mode (`isGuestMode` flag exists).

## 2.2 Primary egress destinations
- Settings (`Routes.settings`) from hero app bar.
- Scan flows:
  - Camera capture (`ImageCaptureScreen`) via mission/action cards.
  - Gallery upload (`ImageCaptureScreen`) via action cards.
  - Instant analysis (`InstantAnalysisScreen`) via instant actions.
- Learn flows:
  - `EducationalContentScreen`
  - `ContentDetailScreen` (daily tip when contentId exists)
- Progress/insights:
  - `WasteDashboardScreen` via community impact card
  - `HistoryScreen` via recent cards and view-all
  - `AchievementsScreen` via challenge and nudge cards
  - `LeaderboardScreen`

---

## 3) Lifecycle/state model

- Stateful + `TickerProviderStateMixin` with two controllers (`fade`, `slide`) started in `initState`, disposed in `dispose`.
- Riverpod async dependencies in `build()`:
  - `classificationsProvider`
  - `profileProvider`
  - `userProfileProvider`
  - nested providers: `todayGoalProvider`, `pointsManagerProvider`, `tokenWalletProvider`
- Pull-to-refresh invalidates only `classificationsProvider` and `profileProvider`.

**Observation:** Home has many independent async sources and mixed `AsyncValue` + `FutureBuilder` composition, increasing recomposition and consistency complexity.

---

## 4) Component-by-component audit

## 4.1 Hero header

**Strengths**
- Strong visual identity and contextual greeting.
- Uses user profile + time-phase messaging to personalize first impression.

**Risks**
- KPI chips pull from multiple providers with independent loading/error states, which can show mixed freshness in one row.
- `isGuestMode` parameter is currently not used in rendering decisions (possible product-intent drift).

---

## 4.2 Mission control panel

**Strengths**
- Clear “Scan / Learn” dual CTA.
- Good visual affordance and momentum.

**Risks**
- Mixed navigation style (direct `MaterialPageRoute`) vs named-route policy elsewhere.
- No explicit anti-double-tap route debouncing on mission action buttons (other than `_isNavigating` in image picker flows).

---

## 4.3 Daily progress card

**Strengths**
- Good habit-loop design: daily goal + streak + points context.
- Uses `todayGoalProvider` derived from classifications for coherence.

**Risks**
- If one provider resolves and another lags, users may read conflicting progress state.
- No timestamp/freshness badge for trust-critical numbers.

---

## 4.4 Action chips (photo/upload/instant)

**Strengths**
- High discoverability for core product workflows.
- Both standard and instant modes are explicit.

**Risks**
- Horizontal card width is fixed by screen fraction; on small devices, text truncation is frequent (some protection exists, but affordance can still degrade).
- Permission failure path shows dialog/snackbar but no persistent recovery hint in UI.

---

## 4.5 Near milestone nudge

**Strengths**
- Strong retention mechanic.
- Prioritized nudge selection in `GamificationService.getNearMilestoneNudge()` is clear.

**Risks**
- Daily-goal nudge derives “today scans” from weekly stats lookup heuristic inside gamification service, which is not guaranteed to represent today-level truth.
- This can produce misleading urgency messaging.

---

## 4.6 Community impact card

**Strengths**
- Converts home curiosity into dashboard exploration.
- Empty-state onboarding is useful.

**Risks**
- Uses estimation heuristics (`estimatedCO2Saved`, `waterSaved`) that can be interpreted as exact facts.
- Duplicate impact-story logic exists both here and dashboard; drift risk if formulas diverge.

---

## 4.7 Leaderboard card

**Strengths**
- Clear entry point, lightweight surface.

**Risks**
- No preflight eligibility/loading indicator before navigating.

---

## 4.8 Active challenge section

**Strengths**
- Good progression framing with visible percentage and count.

**Risks**
- Selected challenge is deterministic by day modulo active list (`selectHomeChallenge`), not by nearest-value or user priority; may surface lower-value task while a higher-impact one exists.

---

## 4.9 Daily tip card

**Strengths**
- Category-aware personalization (`getDailyTipForHome(preferredCategory: ...)`).
- Deterministic date hash gives stable daily experience.

**Risks**
- `preferredCategory` derived from latest classification can overfit to recency and reduce content diversity.

---

## 4.10 Recent classifications

**Strengths**
- Useful memory/continuity surface.
- Error state supports tap-to-retry.

**Risks**
- Tapping any recent card routes to full history, not item-specific detail; interaction expectation mismatch.

---

## 4.11 Image capture/route handling

**Strengths**
- `_isNavigating` lock prevents duplicate launches.
- Permission checks and platform camera setup are handled.

**Risks**
- Single lock variable governs all action pathways; edge-case failures could leave lock true if unexpected branch escapes.
- Web/non-web path divergence is substantial and lightly abstracted.

---

## 5) Dependency and contract audit

## Verified contracts
- `classificationsProvider` → `StorageService.getAllClassifications()`.
- `profileProvider` → `GamificationService.getProfile()`.
- `todayGoalProvider` computes from classifications directly.
- `getDailyTipForHome` is deterministic and category-aware.

## Contract risks
1. **Nudge truth source risk (P1):** `getNearMilestoneNudge()` uses weekly stats to infer daily scans for daily-goal nudge.
2. **Cross-surface estimation drift (P1):** Home impact card and dashboard impact logic are separate implementations.
3. **Provider freshness mismatch (P2):** Multiple independent async values can display mixed-age metrics.
4. **Refresh scope mismatch (P2):** pull-to-refresh invalidates only two providers, while home consumes additional async data sources.

---

## 6) Prioritized findings

## P1

### H-01: Daily-goal nudge may be calculated from non-daily proxy
- Source: `GamificationService.getNearMilestoneNudge()`.
- Why it matters: retention messaging must be trustworthy.

### H-02: Impact estimation logic duplicated across surfaces
- Source: `CommunityImpactCard._computeStats()` vs dashboard impact computations.
- Why it matters: users can see different “impact truths” depending on surface.

### H-03: `isGuestMode` appears underused
- Source: `HomeScreen` constructor accepts guest mode, but rendering logic does not branch on it.
- Why it matters: guest flows may not be intentionally constrained or explained.

## P2

### H-04: Mixed navigation policy increases route drift
- Home uses both named and direct route pushes.

### H-05: Async composition complexity can yield mixed-freshness UI
- Multiple provider and future streams in one screen with no unified freshness indicator.

### H-06: Pull-to-refresh invalidation is partial
- Currently invalidates only `classificationsProvider` + `profileProvider`.

## P3

### H-07: Recent card tap-to-history may violate detail expectation
- Better alignment would deep-link to selected classification context.

### H-08: Horizontal action cards can over-truncate on compact screens
- Mostly cosmetic but impacts comprehension.

---

## 7) Verified vs inferred

## Verified (code-evidenced)
- Navigation targets and route styles.
- Provider dependency graph.
- Nudge and daily-tip algorithm behavior.
- Impact card local computation heuristics.

## Inferred (needs runtime validation)
- User-perceived trust impact from mixed freshness.
- Real-world incidence of nudge inaccuracies.
- Device-specific truncation severity under low-width conditions.

---

## 8) Suggested no-code follow-up (documentation/product)

1. Define a **single metric contract** doc for “daily scans”, “impact”, and “streak” used by all home/dashboard widgets.
2. Add a **route policy doc** for analytics/habit surfaces (named route preferred or explicit exceptions).
3. Add a **guest-mode behavior matrix** documenting expected home deltas.
4. Add a **data freshness UX guideline** (timestamp/last-sync hint) for trust-sensitive cards.

---

## 9) Final assessment

`HomeScreen` has excellent engagement architecture and high UX ambition, but currently carries **truth-consistency risks** due to distributed calculations and mixed async freshness.

**Overall status:** Strong engagement surface; needs contract hardening before further gamified complexity is added.
