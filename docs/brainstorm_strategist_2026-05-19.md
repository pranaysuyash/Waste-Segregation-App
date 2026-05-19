# Strategist Memo: Token Economy Brainstorm
**Role:** Strategist
**Date:** 2026-05-19
**Subject:** What the Token Economy Is Actually For (And Why Fixing the Bug Might Be the Wrong Move)

---

## 1. The Product Thesis (10,000ft)

**First principle:** The best token economy is not a monetization layer. It is a *behavior-shaping interface*.

Most waste apps compete on accuracy, speed, or "eco-points." They are all competing on the same axis: information delivery. Users upload trash, the app says "recyclable," everyone feels good for 3 seconds, and nothing changes.

Our thesis: **Tokens are not currency. Tokens are attention allocation.**

Every token spent is a user making a tradeoff between *now* and *later*, *fast* and *batch*, *impulse* and *patience*. The token economy is the only part of the app that forces the user to become conscious of their own consumption rhythm. That is the product. Not the AI. Not the classification. The moment a user thinks, "Do I really need this answer in 3 seconds, or can I wait 4 hours and save 4 tokens?"

That thought -- that micro-moment of friction -- is where habits form.

**The bug is the thesis.** The fact that instant analysis is currently free while the UI claims it costs 5 tokens is not merely an enforcement gap. It is a live experiment. Users have been voting with their behavior in a system where the displayed cost is *cosmetic* but the *signal* is real. We have data (even if unmeasured) about what happens when people see a price but do not pay it. That is a behavioral economics study running in production. Do not waste it.

---

## 2. Competitive Positioning: What We Are NOT

| What Others Do | What We Do |
|----------------|------------|
| Gamification: "Log in daily for eco-points!" | Behavioral economics: "Your impatience has a real cost." |
| Premium tier: "Pay $4.99/month for unlimited scans" | Token pacing: "You have 50 tokens. Fast answers burn 5. Slow answers burn 1. Choose." |
| Leaderboards: "You recycled more than 83% of users!" | Market simulation: "Batch demand is high right now. Prices may rise." |
| Sustainability guilt: "Save the planet!" | Honest friction: "Convenience costs something here. So does waiting." |

We are not the "best AI classifier." We are the only waste app that treats the user as an economic agent rather than an eco-citizen. That is a different category entirely.

---

## 3. The One Thing That Makes This Genuinely Different

**We have a live two-speed market running inside a consumer app.**

Instant analysis (5 tokens, now) vs batch analysis (1 token, 2-6 hours) is not just a pricing tier. It is a *market for immediacy*. The user is simultaneously the buyer and the seller of their own attention span. No other waste app does this. Most apps either give you instant answers (making them feel cheap) or force a single path (making the app feel slow). We are the only one that makes the speed-vs-cost tradeoff explicit, legible, and reversible.

The current bug -- where instant is free despite the 5-token sticker -- is actually proving something valuable: users *prefer* instant even when they do not have to pay for it. The UI already trained them that instant is "premium." When we flip enforcement on, the psychology is already baked in. The cost will feel earned, not punitive.

---

## 4. Altitude Decomposition

### 4A. 10,000ft -- Strategy

**Decision 1: Do NOT "fix" the bug by simply adding token deduction.**

That is the naive path. It turns tokens into a paywall and users into adversaries. Instead, treat the current "cosmetic tokens" state as a *discovery phase* and run a 3-week telemetry sprint before enforcing anything.

**The real question is not "Should we deduct tokens?" It is "What do tokens actually measure?"**

Three hypotheses to test before enforcement:
- H1: Tokens measure patience. If users switch to batch when instant is free, the token cost is too low.
- H2: Tokens measure trust. If users ignore batch mode entirely, the 2-6h wait promise is not believable.
- H3: Tokens measure nothing. If users do not even notice the token display, the UI is decorative and the economy needs redesign.

**Decision 2: Unify tokens and premium into a single "capacity system."**

Two disconnected monetization systems is a product confession: "We do not know what we are selling." The fix is not a bridge. The fix is a merger.

Proposed unified model:
- **Tokens** = spendable capacity for AI analysis (speed-based)
- **Premium** = non-spendable unlocks that change the *rules* of the token economy (e.g., "Premium users earn 2x tokens from daily login" or "Premium users can queue 5 batch jobs instead of 1")

Premium does not bypass tokens. Premium modifies how tokens flow. This makes premium feel like a *strategy upgrade*, not a *skip button*.

**Decision 3: Make the token economy observable.**

Current state: no analytics, no success metrics, no cost tracking. The token system is a black box with a pretty UI. Before enforcement, add:
- Token velocity: tokens earned vs spent per user per week
- Speed preference ratio: instant vs batch selection rate
- Zero-balance behavior: what do users do when they hit 0?
- Token price elasticity: if we A/B test 3-token instant vs 5-token instant, does behavior change?

### 4B. 1,000ft -- Workflows

**Workflow 1: The 0-Balance Experience (Currently Undefined)**

This is the most important workflow in the entire economy. Every token system dies at 0 balance. We need three paths, not one:

| Path | Trigger | Experience |
|------|---------|------------|
| **Earn** | User hits 0, has time | Show daily login bonus, correction rewards, "teach the AI" tasks |
| **Wait** | User hits 0, has patience | Auto-switch to batch mode (1 token) with an "earn while you wait" mini-queue |
| **Convert** | User hits 0, has points | One-click convert gamification points to tokens (with daily cap) |

The worst thing we can do at 0 balance is show a "Buy Tokens" screen. The second-worst is a hard block. The best is a *soft funnel* that teaches the user how the economy works while still letting them proceed.

**Workflow 2: Server-Side Validation Rollout**

Current state: client-side only. Future state: cloud function validation. But we do not need to jump there immediately.

Phased rollout:
- Phase 0 (now): Client-side enforcement with `ENABLE_TOKEN_ENFORCEMENT` kill switch. Telemetry on balance manipulation attempts.
- Phase 1: Add server-side *logging* of token operations (cloud function records spend/earn events, does not block)
- Phase 2: Add server-side *validation* for spend operations only (cloud function checks balance before approving AI API call)
- Phase 3: Add server-side *settlement* (cloud function reconciles batch job completions with token spends)

This keeps the app working if Firebase hiccups, and gives us fraud signal before we lock down.

**Workflow 3: Premium-Token Bridge**

Current state: `premium_service.dart` and `token_service.dart` have never met. Proposed introduction:

- Premium subscription adds a "token multiplier" passive (e.g., 1.5x tokens from all earn sources)
- Premium unlocks "token-free instant analysis" one day per week (rotating benefit, creates habit loops)
- Premium users get a "token futures" view: estimated batch wait time, demand curve, best-time-to-analyze nudges

This makes premium feel like *market intelligence*, not *gate removal*.

### 4C. Ground Level -- Next Clicks

**Click 1: Add telemetry, not enforcement.**

Before we deduct a single token, log every token-display event, every button press, and every analysis completion. We need to know: do users even see the token cost? Does it change their behavior? Right now we are guessing.

File: `lib/screens/image_capture_screen.dart` -- add analytics events at lines ~1087 (display) and ~360 (analysis start).

**Click 2: Implement the 0-balance soft funnel.**

Create a new screen or dialog: `ZeroBalanceOptionsSheet`. Three buttons: "Switch to Batch (1 token, free now)", "Earn 5 Tokens (2 minutes)", "Convert Points (you have 230 points = 2 tokens)". No "Buy" button yet.

File: new -- `lib/screens/zero_balance_sheet.dart`

**Click 3: Kill switch for token enforcement.**

Add `ENABLE_TOKEN_ENFORCEMENT` as a Remote Config boolean (default: false). When false, instant analysis is free (current behavior). When true, tokens are deducted. This lets us flip enforcement on for 10% of users, measure churn, and roll back in 30 seconds without a deploy.

File: `lib/services/remote_config_service.dart` and `lib/screens/image_capture_screen.dart`

**Click 4: Connect token providers to premium providers.**

In `lib/providers/cost_management_providers.dart`, add a provider that reads both `tokenServiceProvider` and `premiumServiceProvider` and computes an "effective token cost" for instant analysis. Premium users might see "3 tokens" (discounted) instead of "5 tokens". This is the first bridge.

**Click 5: Reconcile Firestore collections.**

Either migrate TokenService to write to `token_wallets` and `token_transactions` (making the existing rules useful) or delete the phantom collections from schema and rules. Do not leave architectural lies in the codebase. It confuses every future developer.

Files: `lib/services/token_service.dart`, `firestore.rules`, `lib/services/firestore_schema_registry.dart`

---

## 5. The Thing Most People Miss About This

**The cosmetic-token state is not a bug. It is a soft-launch A/B test that nobody designed -- and the results are already in.**

Users have been using instant analysis for free while seeing a 5-token price tag. That means we have, in effect, run a massive study on the *salience* of token costs. If users still chose instant when it was "free," the token display did not change behavior. If users never noticed the display, the UI is noise. If users would have switched to batch had the cost been real, we now know the price point that creates the behavior we want.

Most teams would rush to "fix" the bug and start deducting tokens immediately. That is a mistake. The current state is *data*. Before we make the economy real, we should snapshot the behavioral patterns of users who lived under a *displayed* but *unenforced* cost. That is a rare natural experiment. Once we enforce, we can never run it again.

The thing most people miss: **You do not need a functioning economy to learn what your economy should be. You just need a believable fiction and enough users to believe it.**

We accidentally built exactly that. Do not throw away the accident.

---

*End of memo. Next: Synthesize with Engineer and Product Owner outputs for consensus roadmap.*
