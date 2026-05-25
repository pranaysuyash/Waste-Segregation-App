# User Contribution / UGC Pipeline

**Status**: Exploration doc
**Last Updated**: 2026-05-25
**Category**: Community & Social / Disposal Facilities
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md#a21-user-contribution--ugc-pipeline-)
**Related**: Region-Aware Rulesets (#4), Disposal Facilities Directory (A20), Community Trust Layer (#20), Gamification Depth (#16), Civic Trust & Verification (L3/L4)

---

## Why This Is a Topic

User contributions power the data flywheel: corrections, facility updates, rule updates, recycling code clarifications. But treating all contributions the same is dangerous — a wrong disposal rule correction could cause real-world harm, while a typo fix on a facility address should auto-accept.

The app currently has `ContributionSubmissionScreen`, `ContributionHistoryScreen`, and `UserContribution` model, but the review pipeline, reputation system, and incentive design are not defined. This doc covers the UGC pipeline **separately from the social community feed** — contributions are structured data input, not social posts.

---

## Key Questions

1. **Review pipeline** — what auto-accepts vs queues for moderator vs flags for community review?
2. **Reputation system** — how to weight contributions from trusted users higher than new users?
3. **Incentive design** — what motivates quality contributions (tokens, badges, recognition, impact score)?
4. **Content type separation** — does each contribution type need different review depth?
5. **Abuse detection** — how to detect coordinated false-report attacks and spam rings?
6. **Moderation at <100k MAU** — what tier model works at this scale?
7. **Integration with rules corpus** — how does a user-proposed rule update flow into the regional policy engine?

---

## Research Summary

### Review Pipeline Tiers

| Content Type | Auto-Accept? | Review Depth | Example |
|---|---|---|---|
| Typo/address correction (existing facility) | ✅ If from trusted user | Community flag only | "The phone number is wrong" |
| New facility submission | ❌ Queue for moderator | Moderator + community verify | New e-waste drop-off point |
| Disposal rule correction | ❌ Expert review required | Moderator + source citation | "BBMP now accepts #5 in this ward" |
| Recycling code clarification | ⚠️ Queue for community | Community verify after 3 confirms | "This #6 is actually recyclable here" |
| Photo/evidence for existing item | ✅ Auto-accept | Flag system | "This is what a clean #1 looks like" |

### Reputation System Design

Learning from Wikipedia and OpenStreetMap:

- **Edit history** = primary trust signal (count, quality, reverted rate)
- **Account age** = secondary signal (older accounts get higher weight)
- **Domain focus** = users who only edit facilities they've visited get higher trust than users who edit across 10 cities
- **Verification** = email-verified users get auto-confirm status after N quality contributions
- **Decay** = inactive accounts (>6 months without contribution) lose auto-confirm status

**Trust tiers**:
1. **New** (0-5 contributions, <30 days old): all edits queued
2. **Confirmed** (5+ accepted contributions, 30+ days): low-risk edits auto-accepted
3. **Trusted** (50+ accepted contributions, domain-specific): high-risk edits auto-accepted with confidence window
4. **Moderator** (manual assignment): can approve/reject/override any edit

### Incentive Design

Research shows extrinsic rewards alone (badges) can be gamed. Focus on **impact-driven incentives**:
- **Impact score**: "Your edit helped 200 people find the correct disposal for batteries"
- **Public recognition**: contributor leaderboard per region (opt-in)
- **Tiered access**: trusted contributors earn ability to edit field metadata, not just surface data
- **Token rewards**: small token bonus for high-quality, verified-as-correct contributions (anti-gaming: capped per day, requires verification by 3 other users)
- **Feature unlock**: contribution milestones unlock cosmetic badges, profile frames, custom themes

**Anti-gaming constraints**:
- Per-user daily contribution cap (prevents bulk spam)
- Quality-weighted tokens (reverted edit = negative token adjustment)
- Verification requirement for token-earning contributions (must be confirmed by community or moderator)

### Abuse Detection

Patterns to monitor:
- **Bulk same-edit**: 50 accounts editing the same 10 records within 5 minutes → coordinated attack signature
- **False-report ring**: group targeting a legitimate contributor with reports
- **Self-verification**: account A edits → account B (same IP/similar metadata) verifies

**Defenses**:
- Rate limiting per user + IP on edit operations
- Reputation-weighted reporting (new account report = low weight, trusted account report = high weight)
- Email verification gate for high-impact editing (new facility, rule change)
- Confidence scoring: an edit with 3 independent confirmations from distinct trusted users is verified

### Community Moderation at <100k MAU

The most efficient tier at this scale:
- **Level 1 (Automated)**: regex/AI filters for prohibited keywords, spam links, duplicate detection
- **Level 2 (Community)**: users can "verify" or "report" contributions; a dashboard queues items with >3 reports
- **Level 3 (Manual)**: team handles edge cases — escalated reports, sensitive rule changes, moderator disputes

At this MAU, a small active contributor community (50-200 users) can handle most moderation needs through community verification.

### Rules Corpus Integration

When a user proposes a rule update:
1. Submission writes to `contribution_rules` collection (pending state)
2. Expert moderation queue — a change to disposal advice requires:
   - Source citation (municipal document link, photo of notice, verified jurisdiction URL)
   - Affected city/ward and material categories
   - Confidence gate: auto-promoted only after 2 moderator approvals
3. Once approved, the rule update is written to `local_policy_rule_packs` with provenance back to the contribution
4. Users who contributed to the rule are notified when it goes live

---

## Design Recommendations

### Contribution Flow

```
User submits contribution
        │
        ▼
Content type classifier (auto)
        │
        ├── Low risk (typo, photo, address edit) → Auto-accept if from Confirmed+
        │       │
        │       └── If New user → Community verify queue
        │
        ├── Medium risk (new facility) → Moderator queue
        │       │
        │       └── Appears in community "verify" feed for 7 days → If 3 confirms from Confirmed+, promote
        │
        └── High risk (rule change, sensitive category) → Expert queue
                │
                └── Requires 2 moderator approvals + source citation → write to rules corpus
```

### Implementation Path

1. Define contribution schema with `reviewState` enum (pending, auto_accepted, community_verify, expert_review, approved, rejected, reverted)
2. Create `ContributionReviewService` that routes contributions to correct queue based on content type + user reputation
3. Build community verification UI — show pending contributions with verify/report buttons
4. Implement reputation tier promotion (auto-promote at thresholds)
5. Wire approved rule changes into `LocalPolicyEngine` with provenance links
6. Build moderator dashboard — queue management, bulk operations, contributor history
7. Add daily contribution caps and anti-abuse rate limiting
8. Implement impact score calculation (number of users who saw the contribution's effect)

### Kill Criteria

- If >80% of contributions need manual review at 10k MAU, the auto-accept criteria is too strict or the contributor quality is too low
- If contribution volume is <100/week at 10k MAU, the incentive design isn't working
- If false-report attacks succeed against a legitimate user despite anti-abuse defenses, the system needs redesign

---

## Open Questions

- Should contribution reputation be separate from gamification points, or can they share the same ledger? (Risk: gamification-cantered users may contribute low-quality edits purely for points.)
- What's the minimum contribution volume for rule-corpus updates to be viable before the expert review bottleneck chokes the pipeline?
- Should disputed contributions trigger a "second opinion" workflow where a different moderator reviews?
