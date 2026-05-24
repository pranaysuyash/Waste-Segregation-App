# Token Economy & Pricing Coherence

**Date**: 2026-05-23
**Status**: Exploration — synthesising brainstorm into implementation plan
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) entry 27a
**Source**: 9 brainstorm files (2026-05-19) + `TOKEN_ECONOMY_TODO.md`
**Decision this unblocks**: Coherent token ledger across instant/batch/premium; defensible premium pitch tied to the same economy; server-side enforcement.
**Kill criteria**: If telemetry sprint (Phase 0) shows <10% of users notice tokens, or enforcement A/B test shows >5% churn increase, the economy should be deleted cleanly.

---

## 1. Current State

### What exists

| Component | Location | Status |
|-----------|----------|--------|
| `TokenWallet` model | `lib/models/token_wallet.dart` | Live — balance, canAfford, canConvertToday, daily conversion tracking |
| `WalletEncryption` | `lib/utils/wallet_encryption.dart` | Live — HMAC-SHA256 integrity hash |
| `TokenService` | `lib/services/token_service.dart` | Live — spend, earn, convert, daily login bonus, premium pricing |
| `AnalysisSpeed` | `lib/models/token_wallet.dart` | Live — batch=1 token, instant=5 tokens |
| Premium discount | `TokenService.getAnalysisCost(isPremiumUser: true)` | Live — instant drops from 5→2 for premium |
| Cost guardrails | `lib/services/cost_guardrail_service.dart` | Live — batch mode enforcement, budget monitoring |
| Dynamic pricing | `lib/services/dynamic_pricing_service.dart` | Live — Remote Config driven pricing |
| Free daily scan limit | `image_capture_screen.dart` | Live — Hive-backed counter, premium bypass |
| Token enforcement flag | `TokenService.enableTokenEnforcement` | Live — Remote Config kill switch, default false |
| Server-side validation | `TokenService.enableServerSideValidation` | Live — gates server calls, requires Firebase |
| Wallet backup/restore | `lib/screens/token_wallet_screen.dart` | Live — export/import with integrity verification |

### The core contradiction

Tokens are **displayed but not enforced**. The `enableTokenEnforcement` flag defaults to `false`. This means:
- Users see "5 tokens" cost on instant analysis
- Tokens are NOT deducted
- The display is either a soft-launch experiment or an unimplemented bug

All 8 brainstorm roles agree: **the current state is not sustainable.** Displaying costs without enforcement is either a bug or a lie.

### Three-territory pricing problem

| Mode | Displayed Cost | Actual Charge | Premium Interaction |
|------|---------------|---------------|-------------------|
| Instant | 5 tokens | 0 tokens (not enforced) | Drops to 2 tokens |
| Batch | 1 token | 0 tokens (not enforced) | No change |
| Premium | Subscription | N/A | Unrelated to token ledger |

Premium and tokens are two separate abstractions. They must unify into one capacity system.

---

## 2. Decisions Required

### Decision 1: Enforce or Delete?

**Options**:
- A: Enforce with telemetry first (soft-launch → hard enforcement)
- B: Delete the entire token system
- C: Keep cosmetic tokens permanently (current state)

**Resolution**: Run Phase 0 telemetry sprint with `enableTokenEnforcement=false`. Measure before deciding. The speed-vs-cost tradeoff (instant 5, batch 1) is genuinely differentiating — no other waste app offers this choice.

**Recommended**: Option A. The token system creates a behavioral lever premium alone cannot provide.

### Decision 2: Zero-balance experience

When a user with 0 tokens presses "Analyze (Instant)":

| Option | Behaviour | Risk |
|--------|----------|------|
| A | Block with error, offer batch | Hard drop-off |
| B | Soft funnel (earn/wait/convert sheet) | Complexity |
| C | Allow with warning | Trust erosion |

**Recommended**: Option B with Option C as Remote Config fallback. The `ZeroBalanceOptionsSheet` should offer three paths:
1. **Earn**: Daily login bonus (+2 tokens), correct classifications, community contributions
2. **Wait**: Switch to batch mode (1 token, 1hr delay)
3. **Convert**: Points → tokens at configured exchange rate

### Decision 3: Tokens + Premium unification

Premium should **modify** token flow, not bypass it. A bypass makes tokens optional for the most valuable users.

**Resolution**: Single capacity system where premium = token multiplier/discount, not a separate track.
- Free: instant = 5 tokens, batch = 1 token
- Premium: instant = 2 tokens, batch = 0 tokens, daily bonus = 5 tokens
- Premium should feel like "more tokens, better rate" not "tokens don't matter"

### Decision 4: Welcome bonus

Two conflicting values exist: 10 and 50 tokens. `TokenWallet.newUser()` creates 50.

**Resolution**: 50 tokens is the canonical welcome bonus. This gives ~10 instant analyses or 50 batch analyses — enough to evaluate the app meaningfully.

### Decision 5: Server-side validation

Client-side enforcement is theater. Any enforcement path requires cloud function validation.

**Resolution**: Phase 2+ uses the existing `spendUserTokens` Firebase Function with `enableServerSideValidation=true`. The function exists; it's gated behind the flag.

---

## 3. Architecture

### Token ledger (single source of truth)

```
UserProfile
  ├── tokenWallet: TokenWallet
  │     balance, totalEarned, totalSpent
  │     dailyConversionsUsed, lastConversionDate
  │     schemaVersion, integrityHash
  └── tokenTransactions: List<TokenTransaction>
        id, delta, type, timestamp, description, reference, metadata
```

### Token flow (all modes unified)

```
User presses "Analyze"
  ├── Check canAffordAnalysisWithPricing(speed, isPremiumUser)
  │     ├── balance >= cost → proceed
  │     └── balance < cost → ZeroBalanceOptionsSheet
  │           ├── Earn (daily login, contributions)
  │           ├── Wait (switch to batch, 1 token)
  │           └── Convert (points → tokens)
  ├── Deduct tokens via spendTokens(cost, description)
  │     ├── If enableTokenEnforcement → validate server-side
  │     └── Else → log only (telemetry)
  └── Execute classification
```

### Earning paths

| Source | Amount | Frequency | Gating |
|--------|--------|-----------|--------|
| Welcome bonus | 50 tokens | Once (new user) | None |
| Daily login | 2 tokens | Once per day | Last login > 24h ago |
| Correct classification | 1 token | Per correction accepted | User correction → system agrees |
| Community contribution | 1 token | Per approved contribution | Moderation approval |
| Points conversion | 200 points → 2 tokens | Up to 3/day | `canConvertToday` check |

### Spending paths

| Sink | Cost | Speed | Premium Cost |
|------|------|-------|-------------|
| Instant AI analysis | 5 tokens | Real-time | 2 tokens |
| Batch AI analysis | 1 token | Delayed | 0 tokens |

---

## 4. Implementation Phases

### Phase 0: Observation (current — 2 weeks, no enforcement)

Already partially complete:
- [x] `enableTokenEnforcement` Remote Config kill switch (default false)
- [x] Token wallet model with integrity hash
- [x] Free daily scan limit (Hive-backed)
- [x] Token service with spend/earn/convert
- [ ] Token balance header widget on home screen
- [ ] Telemetry events for token display/press/complete/fail
- [ ] Remove phantom `token_wallets`/`token_transactions` Firestore collections from schema registry

**Metric threshold**: ≥1,000 token-display events before Phase 1 decision.

### Phase 1: Legibility (2 weeks, still no enforcement)

- [ ] `ZeroBalanceOptionsSheet` with 3 paths
- [ ] Transaction history visible for instant analysis
- [ ] Analysis choice screen shows balance + cost + affordance
- [ ] Token balance visible on home screen stats

**Metric threshold**: ≥70% of users who see token cost can answer "how many tokens do I have."

### Phase 2: Limited Enforcement (4 weeks, 10% of users)

- [ ] Flip `enableTokenEnforcement` for 10% via Remote Config
- [ ] Monitor churn, batch-switch rate, zero-balance encounters
- [ ] Server-side logging (non-blocking)

**Metric threshold**: <5% churn increase vs control.

### Phase 3: Full Enforcement

- [ ] Server-side validation of spend operations
- [ ] Remove kill switch default (enforcement = standard)
- [ ] Reintroduce Firestore collections with actual writers

---

## 5. Cost Model

### Per-user cost envelope

| Scenario | Monthly Classifications | Token Cost | AI Provider Cost |
|----------|------------------------|------------|-----------------|
| Free batch-only | 60 | 60 tokens | ~$0.06 (batch API) |
| Free mixed (50/50) | 60 | 180 tokens | ~$0.18 |
| Free instant-only | 30 | 150 tokens | ~$0.15 |
| Premium mixed | 120 | 120 tokens | ~$0.12 (discounted rate) |
| Power user | 200 | Depletes tokens | Must earn/convert |

### Provider cost per classification

| Provider | Model | Cost | Latency |
|----------|-------|------|---------|
| OpenAI | gpt-4.1-nano | ~$0.002 | ~2s |
| OpenAI | gpt-4o-mini | ~$0.00015 | ~1.5s |
| Gemini | gemini-2.0-flash | ~$0.000075 | ~1.2s |
| Layer 0 (local) | deterministic | $0 | ~50ms |
| Layer 1 (future) | SmolVLM-500m | $0 | ~800ms |

---

## 6. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Enforcement causes churn | Medium | High | A/B test with 10%, Remote Config kill switch |
| Users game earning paths | Medium | Low | Daily caps, conversion limits, fraud detection |
| Server-side validation latency | Low | Medium | Async validation, client optimistic, server audit |
| Premium users feel nickel-and-dimed | Medium | High | Premium = generous token allocation, not bypass |
| Regional pricing mismatch | High | Medium | Remote Config per-region token costs (PPP) |

---

## 7. Related

- [TOKEN_ECONOMY_TODO.md](../../TOKEN_ECONOMY_TODO.md) — phase-by-phase execution checklist
- [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md#27a-token-economy--pricing-coherence---in-flight--2026-05-19) — parent index entry
- [AI Cost Telemetry & Guardrails](AI_COST_TELEMETRY_AND_GUARDRAILS.md) — cost tracking infrastructure
- [Gamification Redesign Spec](../planning/gamification-redesign-spec.md#10-token-economy-separation) — token separation contract (one-way + event-only, §10) and integration design (§12.1)
- [Gamification Depth](../EXPLORATION_TOPICS.md#16-gamification-depth-) — token earning through gamification
- [Habit Formation Loop](../EXPLORATION_TOPICS.md#17-habit-formation-loop-) — token economy as habit driver
