# UGC Challenge Builder

**Status**: Draft — no code surface for user-created challenges exists yet.
**Priority**: P2 (builds on challenge system maturity)
**Related**: POST_MVP_ROADMAP_POINTS_CHALLENGES_COMMUNITY.md, [COMMUNITY_EVENT_LAYER.md](COMMUNITY_EVENT_LAYER.md), [DYNAMIC_CHALLENGE_WEIGHTING.md](DYNAMIC_CHALLENGE_WEIGHTING.md)
**Last Updated**: 2026-05-25

---

## Why This Is a Topic

The current challenge system (pre-defined, system-generated) works for baseline engagement but has limits:

1. **Community-specific relevance** — only local users know what matters for their neighborhood (e.g., "Wing A vs Wing B sorting challenge this month").
2. **Creative expression** — letting users design challenges unlocks organic, peer-driven engagement patterns the platform team would never think of.
3. **Scalability** — the platform team can't design 1,000 interesting challenges. A UGC system scales challenge diversity without the platform team being the bottleneck.

However, UGC challenges require anti-farming, moderation, and reward budgets that must be designed before launch.

---

## Challenge Template Types

Provide structured templates, not blank canvases:

| Template | Parameters | Verification |
|----------|-----------|-------------|
| **Volume** (sort N items of type X) | Category, target count, time window | Auto-tracked from scans |
| **Accuracy** (no contamination streak) | Category, streak length | Auto-tracked from correction rate |
| **Consistency** (classify every day) | Streak days | Auto-tracked from daily activity |
| **Learning** (identify X hazardous items) | Category, target count | Auto-tracked from quiz/scans |
| **Local** (use your city's rule pack) | City | Auto-tracked from GPS + rules used |
| **Social** (invite N friends to join) | Target invites | Invite link tracking |
| **Custom** (free-form) | User-defined goal, required proof type | Photo + verification needed |

**Phase 1**: Only structured templates (no custom). Custom is Phase 2 after moderation pattern is proven.

---

## Challenge Lifecycle

```
Draft → Submit → [Auto-review gate] → Published → Active → [Reminder at 50% time] → Completed → Archived
```

1. **Draft**: User selects template, fills parameters.
2. **Submit**: System validates parameters (target ≥ 3, duration ≤ 30 days, not a duplicate of active challenge).
3. **Auto-review gate**:
   - For trusted users (10+ scans, 7+ days active, no abuse history): auto-publish.
   - For new users: pending human or automated review.
4. **Published**: Appears in challenge discovery feed.
5. **Active**: N days long. Participants can join, progress is tracked.
6. **Reminder**: At 50% time elapsed, push notification to participants.
7. **Completed**: Results finalized, rewards distributed, challenge archived.

---

## Anti-Farming & Abuse Prevention

### Challenge-Level Guards

| Guard | Implementation |
|-------|---------------|
| **Minimum target** | At least 3 items/days/actions |
| **Maximum duration** | At most 30 days |
| **Maximum participants** | 500 per challenge (Phase 1) |
| **No duplicate active** | Same creator cannot have 2 identical challenges running simultaneously |
| **Rate limit creation** | Max 2 new challenges per week per user |
| **Auto-reject impossible challenges** | "Classify 1000 hazardous items in 1 day" — rejected as infeasible |

### Participation-Level Guards

| Guard | Implementation |
|-------|---------------|
| **No auto-join** | Users must opt in (not auto-enrolled) |
| **Max concurrent challenges** | 5 per user |
| **No token farming** | Challenge rewards capped per day |
| **Verification threshold** | Volume challenges: min 1 scan/day to count toward progress |
| **Accuracy check** | If user's correction rate > 20% during challenge, rewards reduced |

### Anti-Sybil

- Only verified accounts (email or phone) can create challenges.
- New accounts (first 7 days) cannot create challenges.
- Multiple accounts from same device flagged for review.

---

## Reward Allocation

### Reward Pool

- System allocates a daily global budget for challenge rewards (prevents token inflation).
- Per-challenge reward pool is calculated: `base_reward × participant_count × difficulty_multiplier × completion_rate`.
- Rewards split among completing participants.

### Reward Types

| Reward | Source | Notes |
|--------|--------|-------|
| **XP / points** | System budget | Scales with difficulty |
| **Badge** | Auto-generated | "Challenge Champion: completed 10 challenges" |
| **Recognition** | Social | Top 3 performers shown in challenge completion screen |
| **Token** | System budget | Small amount — anti-farming capped |
| **Cosmetic unlock** | Completion reward | Theme, badge, profile frame for 1st place |

### No Token Minting From Challenges

Challenges reward points and badges, not tokens. Tokens must be purchased or earned through premium plans. This prevents UGC challenge creation from becoming a token farming vector.

---

## Challenge Discovery

- **Feed**: challenges are shown in a dedicated feed, sorted by popularity + recency + relevance (city match, category match).
- **Search**: by category, city, creator, type.
- **Recommendations**: system suggests challenges based on user's scan history (e.g., "You classify a lot of plastic — here are plastic-related challenges").
- **Social**: "Friends in this challenge" shows when a user has friends already participating.

---

## Moderation

### Automated Moderation

- Challenge title/description scanned for prohibited content (violence, self-harm, spam, brand mentions without permission).
- Duplicate detection: if the challenge is identical (or near-identical) to an existing active challenge, prompt creator to join that one instead.
- Target feasibility: reject challenges with clearly impossible targets.

### Human Moderation

- Flagged challenges reviewed within 24 hours (target).
- Repeat offenders (3+ rejected challenges) lose challenge creation rights for 30 days.
- Appeal process: user can dispute rejection.

---

## Phase Plan

### Phase 1: System-Generated Challenges Only (current)
- No UGC. All challenges created by platform team.
- Learn what challenge types drive engagement.

### Phase 2: Template-Only UGC
- Trusted users create from templates.
- Strict anti-farming, human review gate.
- Max 10 concurrent publicly-visible challenges.

### Phase 3: Custom Challenges + Teams
- Free-form goals with photo verification.
- Team creation within challenges.
- Sponsor-funded challenge rewards.

---

## Open Questions

1. **Challenge visibility**: should all created challenges be public, or can they be private (family/society only)? Proposal: default public, but creator can set to "invite only."
2. **Cross-user challenge**: can a user challenge another user (e.g., "I bet you can't sort 50 items this week")? Proposal: Phase 3 feature.
3. **Recurring challenges**: can a challenge auto-restart weekly? Proposal: yes, but creator must check "repeat weekly" — system creates a new instance each week.
4. **Challenge templates from top completed challenges**: system auto-promotes popular completed challenges to template library.

---

## Related Work

- [DYNAMIC_CHALLENGE_WEIGHTING.md](DYNAMIC_CHALLENGE_WEIGHTING.md) — how challenges are balanced for different motivation profiles
- [COMMUNITY_EVENT_LAYER.md](COMMUNITY_EVENT_LAYER.md) — events and challenges share participation infrastructure
- POST_MVP_ROADMAP_POINTS_CHALLENGES_COMMUNITY.md — sequencing relative to other engagement features
- [NEGATIVE_MECHANICS_AB.md](NEGATIVE_MECHANICS_AB.md) — loss mechanics design philosophy applied to challenge failure
