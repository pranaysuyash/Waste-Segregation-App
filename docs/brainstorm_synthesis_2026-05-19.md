# Token Economy Brainstorm — Synthesis

**Date:** 2026-05-19
**Participants:** Strategist, Operator, Skeptic, Executioner, Trickster, Cartographer, Future Self, Champion

---

## 1. North Star / Product Thesis

Tokens are not currency. They are **attention allocation and behavioral commitment devices**. The app's unique value is making the speed-vs-cost tradeoff explicit. The instant (5 token) vs batch (1 token) choice is a market for immediacy that no other waste app offers.

The current bug — tokens displayed but not deducted on instant analysis — is simultaneously:
- A broken enforcement mechanism (Skeptic, Operator)
- An accidental behavioral experiment with irreplaceable data (Strategist)
- Evidence that the economy is unnecessary in its current form (Executioner)
- A trust violation that will get worse if not resolved (Cartographer)

---

## 2. Convergent Threads

**All 8 roles agree on these points:**

1. **The current state is not sustainable.** Displaying costs without enforcement is either a bug or a lie. It must be resolved into one of: honest enforcement, honest removal, or intentional soft-launch with telemetry.

2. **The zero-balance experience is undefined.** Every role flagged this. There is no earning path for depleted tokens, no UI for 0-balance state, no batch-switching nudge. This is the single most important missing workflow.

3. **Tokens and premium must unify.** The disconnect between `token_service.dart` and `premium_service.dart` is a product confession. One capacity system, not two competing abstractions.

4. **Legibility before enforcement.** The Cartographer's rule: users must be able to answer "how many tokens do I have," "what can I do with them," and "how do I get more" from any screen. Currently, none of these questions have visual answers.

5. **Server-side validation is a prerequisite, not a feature.** Client-side enforcement is theater. Any enforcement path requires cloud function validation.

---

## 3. Strongest Remaining Contradictions

| Contradiction | Position A | Position B | Resolution Path |
|--------------|-----------|-----------|----------------|
| **Enforce vs. Delete** | Strategist/Champion: Tokens are the product differentiator. Enforce with telemetry first. | Executioner: Tokens are a failed hypothesis. Delete the entire system. | Run 2-week telemetry sprint with `ENABLE_TOKEN_ENFORCEMENT=false`. Measure behavior before deciding. |
| **Soft-launch vs. Hard-block at 0** | Operator: Soft funnel (earn/wait/convert) | Skeptic: Hard block will cause 60%+ drop | Instrument both paths with Remote Config. A/B test. |
| **Global token pricing** | Future Self: Needs PPP-adjusted pricing | Skeptic: Global scope with no regional flexibility is fragile | Build token costs as Remote Config values, not hardcoded constants. |
| **Welcome bonus discrepancy** | Operator found 10 vs 50 token bonus | Codebase has both values | Reconcile to a single source of truth before any enforcement. |

---

## 4. Decisions That Must Be Made Now

1. **What happens when a user with 0 tokens presses "Analyze (Instant)"?**
   - Option A: Block with error, offer batch switch
   - Option B: Soft funnel (earn/wait/convert sheet)
   - Option C: Allow with warning (soft enforcement phase)
   - **Recommendation:** Option B with Option C as Remote Config fallback

2. **Is the current cosmetic-token state intentional soft-launch or an unimplemented bug?**
   - This determines whether we add telemetry first (soft-launch) or enforcement first (bug)
   - **Recommendation:** Treat as accidental telemetry phase. Add real telemetry before deciding.

3. **Should the phantom `token_wallets`/`token_transactions` Firestore collections be migrated to or removed?**
   - **Recommendation:** Remove from schema registry and rules for now. If/when server-side enforcement is built, reintroduce with actual writers.

---

## 5. What the Brainstorm Collectively Got Wrong (And Corrected)

- **Initial assumption:** "The token system just needs enforcement wired in." **Correction:** The system needs legibility first. An enforced but illegible economy angers users faster than an unenforced one.
- **Initial assumption:** "Premium users should bypass tokens." **Correction:** Premium should modify token flow, not bypass it. A bypass makes tokens optional for the most valuable users.
- **Initial assumption:** "Welcome bonus is 10 tokens." **Correction:** There are two conflicting constants (10 and 50). Must reconcile.
- **Executioner's claim:** "No users complained about missing enforcement." **Correction:** Absence of complaint does not prove absence of problem. Users may have noticed and silently distrusted the economy without reporting.

---

## 6. Time Horizons

### 6 Months
- Telemetry sprint (2 weeks): instrument token display events, button presses, analysis completions
- Reconcile welcome bonus to single value
- Implement `ENABLE_TOKEN_ENFORCEMENT` Remote Config kill switch (default: off)
- Kill phantom Firestore collections
- Add token balance visibility to home screen and analysis choice screen
- Implement ZeroBalanceOptionsSheet (soft funnel: earn/wait/convert)

### 12 Months
- Server-side validation (Phase 0 → 1 → 2 per Strategist's phased rollout)
- Unify tokens + premium into single capacity system
- PPP-adjusted token pricing via Remote Config
- Token velocity analytics dashboard
- A/B test: 3-token instant vs 5-token instant

### 24 Months
- Dynamic token pricing based on AI cost forecasting
- Municipal/institutional bulk token accounts
- Token earning through data contribution (verify classifications, teach the AI)

---

## 7. What to Build First vs. What to Dream About

### Build First (Phase 0)
1. `ENABLE_TOKEN_ENFORCEMENT` kill switch via Remote Config
2. Token balance header widget on home screen
3. ZeroBalanceOptionsSheet with 3 paths (earn/wait/convert)
4. Token telemetry events (display, press, complete, fail)
5. Reconcile welcome bonus constants (10 vs 50 → pick one, document it)
6. Remove phantom Firestore collections from schema registry

### Dream About (Do Not Build Yet)
1. Dynamic pricing based on AI demand
2. Token futures / market view
3. Municipal bulk accounts
4. Rotating premium-free-day benefit
5. Cross-app token portability

---

## 8. Kill Test Verdict

The Executioner argued: DELETE the entire token economy. The idea survived the kill test, but barely. The executioner's strongest argument — "the absence of enforcement is the market's answer" — is valid only if we treat the current state as the final state. Since the current state was never a deliberate design (it is an unimplemented feature, not a conscious strategy), the executioner's evidence is circumstantial.

**The idea survives because:** The speed-vs-cost tradeoff (instant 5, batch 1) is genuinely differentiating. No other waste app offers this choice. The token system creates a behavioral lever that premium alone cannot provide. But it must be built honestly — with enforcement, server-side validation, and a defined zero-balance experience — or deleted honestly.

**The kill test forces a binary:** Enforce properly or delete cleanly. The worst option is the current state: display without enforcement.

---

## 9. Execution Sequence

### Phase 0: Observation (2 weeks, no enforcement)
- Add `ENABLE_TOKEN_ENFORCEMENT` Remote Config (default false)
- Add token telemetry events to image_capture_screen.dart
- Add token balance header to home screen
- Reconcile welcome bonus
- Remove phantom Firestore collections
- **Metric threshold:** ≥1,000 token-display events collected before Phase 1 decision

### Phase 1: Legibility (2 weeks, still no enforcement)
- ZeroBalanceOptionsSheet
- Transaction history for instant analysis (currently missing)
- Analysis choice screen shows balance + cost + affordance
- Premium/token bridge provider
- **Metric threshold:** ≥70% of users who see the token cost can answer "how many tokens do I have" in a survey

### Phase 2: Limited Enforcement (4 weeks, 10% of users)
- Flip `ENABLE_TOKEN_ENFORCEMENT` for 10% via Remote Config
- Monitor churn, batch-switch rate, zero-balance encounters
- Server-side logging of token operations (non-blocking)
- **Metric threshold:** <5% churn increase vs control group before expanding

### Phase 3: Full Enforcement (when Phase 2 passes)
- Server-side validation of spend operations
- Remove kill switch default (enforcement becomes standard)
- Reintroduce `token_wallets`/`token_transactions` Firestore collections with actual writers

---

*End of synthesis. Next: Decision discussion with project owner.*