# Civic Trust, Verification & Reputation

**Status**: Seed — no implementation
**Priority**: 🟢 (P2 — civic intelligence track)
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Section F: Locality & Civic Waste Intelligence (L3/L4)
**Related**: [CIVIC_ISSUE_REPORTING.md](CIVIC_ISSUE_REPORTING.md), [CIVIC_PRIVACY_SAFETY_REVIEW.md](CIVIC_PRIVACY_SAFETY_REVIEW.md), [USER_CONTRIBUTION_UGC_PIPELINE.md](USER_CONTRIBUTION_UGC_PIPELINE.md)

---

## Overview

Civic trust is the foundation on which every other civic surface (reporting, verification, authority sharing, data export) depends. Without a trustworthy verification loop, geo-tagged reports become a stale-pin graveyard. Without civic reputation separated from gamification tokens, the token economy becomes farmable through spam reports.

**Hard constraint: civic reputation must NOT merge into the AI-token ledger.** This is non-negotiable. See separation contract below.

---

## Verification Loop Design

### 1. Waze-Style "Is It Still There?" Pattern

**Trigger**: When a user passes within proximity of an active report, show a lightweight prompt:

> "You're near [issue type] reported [time ago]. Is it still there?"
> [Yes, still there] [No, resolved] [Skip]

**Proximity threshold**: 50m for dumping/overflow, 100m for infrastructure.

**Per-user caps**:
- Max 5 verification prompts per day (prevents fatigue)
- Max 1 verification per report per user (prevents farming)
- Min 10m between prompts (cooldown)

**Confidence formula**:

```
confidence = base_weight(0.3) 
  + (positive_confirmations * 0.15)
  + (trusted_user_bonus * 0.1)
  - (negative_confirmations * 0.2)
  - (time_decay_hours * 0.01)

if confidence < 0.1: auto-archive report (hide from public, keep for audit)
if confidence < 0.3: show with "unconfirmed" badge
if confidence > 0.7: show as "confirmed" (no badge needed)
```

**Time decay rates**:
- Real-time issues (missed pickup, overflow): decay starts after 24h, auto-archive at 72h
- Semi-permanent issues (illegal dumping, broken bin): decay starts after 7d, auto-archive at 30d
- Infrastructure (damaged bin station): no auto-archive, status updates from authority required

---

## Civic Reputation: Separate Ledger Contract

### 2. Why Separation is Non-Negotiable

| | Gamification (Points/Tokens) | Civic Reputation |
|---|---|---|
| **Incentive** | Usage frequency, retention | Accuracy, reliability |
| **Earned by** | Scanning, streaks, challenges, quizzes | Verified reports, accurate verifications, quality contributions |
| **Earned by** | Scanning, streaks, challenges, quizzes | Verified reports, accurate verifications, quality contributions |
| **Spent on** | Premium features, cosmetics, unlocks | Nothing — it's a trust weight, not a currency |
| **Farming risk** | Token economy already has anti-farming | Must not create token-minting path from civic actions |
| **Ledger** | Firestore `users/{uid}/tokens` | Firestore `users/{uid}/civic_reputation` (separate doc) |
| **Public** | Yes (leaderboard visible) | No (internal for moderation/verification weighting) |

### 3. Reputation Tiers

| Tier | Trust Weight | Promotion Criteria | Demotion Criteria |
|-----|-------------|-------------------|-------------------|
| **New** | 1.0x | Default for all users | — |
| **Verified** | 1.5x | 10+ reports with >60% resolution rate | False report rate >10% |
| **Trusted** | 2.0x | 50+ reports, >80% resolution rate, no false reports in 90 days | 2+ false reports in 30 days |
| **Moderator** | 3.0x (review authority) | Manual appointment by team + consistent accuracy | Manual review |

**Earn events** (increase weight towards next tier):
- Report that gets resolved: +10
- Verification that matches outcome: +5
- Correction that improves data accuracy: +15
- Contribution accepted into rules corpus: +25

**Penalty events** (decrease weight, can demote):
- False report (confirmed by moderator): -20
- Verification that contradicts outcome: -5
- Coordinated false report ring: -100 + flag for review

### 4. Time Decay for Reports

**Active report lifecycle**:
1. Report submitted → status: `Pending`
2. Within 48h: if no verification action, auto-prompts 2 nearby users
3. At 72h: if <2 confirmations, show with "unconfirmed" badge
4. At 7d (missed pickup) / 30d (dumping): if no resolution, auto-archive
5. Resolved reports: visible for 30 days post-resolution, then hidden (retained for audit 90 days)

**Archive ≠ delete**: Archived reports remain in Firestore with `isArchived: true` for audit trail and trend analysis. Not shown on public map.

### 5. Dispute Workflow

**When a reporter and a verifier disagree**:
1. Auto-escalation: if report status (resolved) contradicts verifier response (still there), flag for moderator review
2. Evidence requirement: disputed reports require photo evidence from both sides
3. Peer voting: if moderator unavailable within 24h, prompt 3 trusted-tier users in area to vote
4. Final arbiter: moderator override always available

**When a report subject contests**:
- Subject submits takedown request with evidence (photo, official confirmation)
- Moderator reviews within 24h SLA
- If approved: report removed, reporter reputation penalized
- If denied: report remains, subject can appeal to team

### 6. Anti-Spam & Anti-Farming

**Detection signals**:
- Multiple accounts from same device fingerprint creating same-category reports in same area → flag ring
- Verification rates >90% from same device → check for auto-tapping
- New account with no scan history submitting reports → hold for manual review
- IP clustering of reports from same network → check for organized farming

**Defenses**:
- New accounts: reports held in review queue until 5 verified scans completed
- Rate caps: max 3 reports/day for new users, graduated to 10/day for Trusted tier
- Device binding: report submission requires unique device ID (not just auth UID)
- Cooldown: same user cannot verify their own report, or report in same category within same 50m radius within 48h

---

## Trust Model Summary

```
                    ┌─────────────────────┐
                    │  Report Submitted    │
                    │  (weighted by        │
                    │   reporter trust)    │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Duplicate Check    │
                    │  (proximity +       │
                    │   category + time)  │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
    ┌─────────────────┐ ┌──────────────┐ ┌──────────────┐
    │ Auto-Accept     │ │ Needs        │ │ Reject       │
    │ (trusted user + │ │ Verification │ │ (duplicate)  │
    │  high severity) │ │ (default)    │ │              │
    └─────────────────┘ └──────┬───────┘ └──────────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Verification       │
                    │  Loop (proximity    │
                    │  prompts + conf     │
                    │  formula)           │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
    ┌─────────────────┐ ┌──────────────┐ ┌──────────────┐
    │ Confirmed       │ │ Unconfirmed  │ │ Disputed     │
    │ (>0.7 conf)     │ │ (<0.3 conf)  │ │ (conflicting │
    │                 │ │ → auto-      │ │  evidence)   │
    │                 │ │   archive    │ │  → moderator │
    └─────────────────┘ └──────────────┘ └──────────────┘
```

---

## Implementation Path

1. **Phase 0**: Civic reputation Firestore schema + service. Separate doc path from tokens/points. No user-facing surface.
2. **Phase 1**: Trust-weighted report visibility. New users' reports held for review. Trusted users' reports surfaced immediately.
3. **Phase 2**: Verification loop prompts with proximity triggers. Confidence formula tuned with real data.
4. **Phase 3**: Dispute workflow + moderator dashboard. Anti-farming detection.
5. **Phase 4**: Automated moderation tier (machine learning for false report detection) at scale.

---

## Open Questions

- Can civic reputation be migrated across account merges (anonymous → identified)? Yes but with tier cap: max "Verified" on merge.
- Should moderator appointments be time-limited (e.g., 6-month renewable term)?
- How do we handle cross-region reputation? Does a Trusted user in Bangalore start as New in Mumbai?
- Should there be a mechanism for users to appeal reputation penalties?
