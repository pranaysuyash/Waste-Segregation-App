# Sponsor Rewards & Donation Matching

**Status**: Seed — P2, not yet funded
**Last Updated**: 2026-05-26
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Item 75
**Related**: AFFILIATE_MARKETPLACE.md, TOKEN_ECONOMY_AND_PRICING_COHERENCE.md, CORPORATE_ESG_TEAM_MODE.md

---

## 1. Why This Matters

Sponsor-funded rewards turn app actions into real-world impact without charging the user. The pattern is proven by Ecosia (ad revenue → tree planting), Forest (productivity → real trees), and Charity Miles (exercise → corporate donations).

For the ReLoop app, a user sorting correctly or completing a challenge could trigger a corporate donation to a verified environmental cause. This creates:
- **Retention**: User sees their actions have measurable real-world impact.
- **Revenue**: Corporates pay for verified impact attribution and brand association.
- **Mission alignment**: No user payment required for the core experience.

---

## 2. Existing Patterns

| Platform | Model | Trigger | Outcome |
|----------|-------|---------|---------|
| **Ecosia** | Search ad revenue | Any search | Trees planted (fixed % of revenue) |
| **Forest** | App purchase + in-app | Focus session completed | Real tree planted via Trees for the Future |
| **Charity Miles** | Corporate sponsorship | Mile logged | $0.10–0.25 donated to user's chosen charity |
| **Too Good To Go** | Marketplace commission | Food rescue completed | Food saved, CO₂ avoided (built into model) |
| **Goodwall** | Brand challenges | User completes challenge | Scholarship or grant awarded |

---

## 3. Sponsorship Models

### 3.1 Action-Based Sponsorship (Recommended)
- **Mechanic**: Brand sponsors a specific user action (e.g., "For every correctly sorted hazardous item, [Brand] donates $0.05").
- **Pricing**: CPS (Cost Per Success) — brand pays per verified action.
- **Advantage**: Aligned incentives — brand pays for real impact, not impressions.

### 3.2 Campaign Sponsorship
- **Mechanic**: Brand sponsors a time-bound challenge (e.g., "[Brand] Earth Month Challenge: sort 50 items this month").
- **Pricing**: Flat fee for campaign duration + per-completion bonus.
- **Advantage**: Predictable cost for brand, event-based marketing for app.

### 3.3 CPM-Based Sponsorship (NOT Recommended)
- Brand pays per impression of sponsored content.
- Misaligned with mission — incentivises volume, not impact.
- Risk of feeling like ads masquerading as impact.

---

## 4. Conflict of Interest Guardrails (Non-Negotiable)

The app's core job — telling users how to dispose of waste correctly — must be **completely independent** of sponsor relationships.

### 4.1 Sponsor Vetting
- Establish a published "Sponsor Eligibility Policy" — sponsors must align with the app's mission and have no history of environmental violations.
- A sponsor that produces single-use plastics cannot fund "plastic recycling challenges" — too high conflict risk.
- Independent third-party verification of sponsor impact claims.

### 4.2 Disclosure Everywhere
- Every sponsor-funded reward is labelled: "Sponsored by [Brand] to fund this impact."
- The user must always know *who* is paying and *why*.
- Opt-out: users can decline sponsor attribution and still earn the impact.

### 4.3 No Influence on Core Advice
- Sponsor relationships MUST NOT influence which disposal advice is shown, which materials are prioritised, or which categories get challenges.
- Hard technical gate: the sponsor pipeline and the advice pipeline are separate code paths with no data cross-contamination.

### 4.4 Impact Verification
- If a sponsor claims to fund a tree/donation/offset, use an independent third party (e.g., verra.org, Gold Standard) to verify.
- Publish aggregate impact totals so users see the sum is real.

---

## 5. User Agency Design

### 5.1 Choice of Cause
- Users choose which cause their actions support (local tree planting, ocean cleanup, school recycling programs, e-waste processing).
- Sponsor contributions are pooled and allocated per user preference.
- The "attribution" the sponsor gets is aggregate, not per-user.

### 5.2 Opt-In, Not Default
- Sponsor-funded challenges are opt-in — users see them in a "Sponsored Impact" section of the app.
- The user's core scan-and-learn experience is never interrupted by sponsor content.
- If no sponsor is active for a given action, the action still earns points/tokens (core economy is sponsor-independent).

### 5.3 Impact Dashboard
- Separate tab/section showing: "Your actions this month helped fund [X] trees / [Y] kg of ocean plastic removed / [Z] meals of food waste avoided."
- Aggregate numbers from sponsor contributions, not individual attribution.

---

## 6. Minimum Viable Sponsor Program

### Phase 1: Single Partner, Single Action, Manual Fulfillment
1. **Select one aligned partner**: A local NGO, a tree-planting organisation, or a brand with genuine sustainability credentials.
2. **Define one action**: E.g., "User correctly classifies 10 hazardous waste items."
3. **Manual fulfillment**: Track total actions in the app → share monthly total with partner → partner cuts one check. Notify users: "Your sorting helped [Brand] donate $X to [Cause]."
4. **Timeframe**: 1-2 months to launch.

### Phase 2: Add Causes, Scale Partners
- Let users choose among 3-5 verified causes (local, national, global).
- Add 2-3 sponsor partners at different commitment levels.
- Semi-automate reporting (monthly CSV export from Firestore).

### Phase 3: Automated Sponsor Marketplace
- Sponsor dashboard to create campaigns, set budgets, view impact metrics.
- Automated donation fulfillment via API-connected giving platforms (e.g., Benevity, GlobalGiving).
- Only pursue when manual matching is clearly bottlenecking partner acquisition.

---

## 7. Integration with Token Economy

Sponsor rewards must NOT create a minting path into the paid AI token economy:

- **Civic/environmental impact** is a separate ledger from **AI tokens**.
- Sponsor-funded rewards should be visible as "impact units" (trees planted, kg diverted, $ donated) — not convertible to scan credits.
- If a sponsor reward *does* grant bonus AI tokens, it must be server-authoritative and capped to prevent farming.

---

## 8. Kill Criteria

- Sponsor vetting pipeline can't find enough aligned partners within 3 months.
- User surveys show sponsor engagement degrades trust in disposal advice.
- Manual fulfillment overhead exceeds value delivered in first 6 months.
- Sponsor demand is strong but all viable partners have environmental conflict of interest.
