# Trust Score Separation Model

**Status**: Exploration — pre-design
**Priority**: P2 (🟡)
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Topic #63
**Related docs**: `CIVIC_TRUST_AND_VERIFICATION.md`, `USER_CONTRIBUTION_UGC_PIPELINE.md`, `MODERATION_AND_SAFETY.md`, `TOKEN_ECONOMY_AND_PRICING_COHERENCE.md`, `POINTS_ECONOMY_V2.md`

---

## Why This Matters

The app has multiple domains where user trust and reputation matter:

| Domain | What Users Do | Why Trust Matters |
|---|---|---|
| **AI training** | Submit corrections, validate classifications | High trust = auto-accept corrections; low trust = review flags |
| **Civic reporting** | Report missed pickup, illegal dumping, overflowing bins | High trust = reports surfaced publicly; low trust = hidden/queued |
| **Community** | Comments, likes, shares on community feed | High trust = visible posts; low trust = moderated/hidden |
| **Gamification** | Points, tokens, streaks, achievements | High gamification level = cosmetic perks; doesn't affect other domains |

**The core constraint**: Trust gained in one domain must NOT automatically grant privilege in another domain. Otherwise:
- A user who submits 1000 spam civic reports earns enough "civic trust" to auto-validate AI corrections (wrong — cross-domain farming).
- A user with high gamification level gets their community posts auto-approved (wrong — gamification != moderation quality).

---

## Key Questions

- What are the separate trust domains, and what are their boundaries?
- How do trust scores compute (weighting, decay, caps)?
- How do we enforce separation at the data layer (Firestore schemas)?
- What cross-domain visibility should users and moderators have?
- How do we handle the "global emergency" case where a user is bad in all domains?

---

## Research Findings

### 1. Domain Definitions

**Domain A: AI Training Trust**
- **Signal sources**: Correction accuracy rate, dispute resolution acceptance rate, training data quality ratings.
- **Privileges**: Auto-accept corrections, faster review queue, influence on golden set admission.
- **Anti-farming**: Cannot earn this trust from civic or gamification actions.
- **Decay**: 3-month half-life — inactive users lose AI training trust.

**Domain B: Civic Report Trust**
- **Signal sources**: Report accuracy rate (validation by other users/staff), report timeliness, resolution rate.
- **Privileges**: Reports appear on public map without review, faster verification triggers, influence on issue lifecycle.
- **Anti-farming**: Correct classification of waste doesn't earn civic trust. Must be civic-specific actions.
- **Decay**: 6-month half-life — older reports matter less.

**Domain C: Community Trust**
- **Signal sources**: Post quality (upvotes/downvotes), helpfulness ratings, reporting accuracy, no moderation actions.
- **Privileges**: Posts auto-published (no moderation queue), ability to moderate others (at high trust), influence on community feed.
- **Anti-farming**: Gamification activity doesn't earn community trust.
- **Decay**: 2-month half-life for recent activity; base trust preserved for old accounts.

**Domain D: Gamification Level**
- **Signal sources**: Scans, streaks, challenges completed, quiz scores, points accumulated.
- **Privileges**: Cosmetic rewards, avatar unlocks, special challenge access. NO moderation influence.
- **Anti-farming**: High gamification level should NEVER gate auto-approval of content.
- **Decay**: No decay — gamification is achievement, not trust.

### 2. Firestore Schema Design

**Recommended**: Separate collections per domain. This is cleaner for security rules and prevents cross-domain confusion.

```
Collections:
  trust_ai/{userId}
    - score: double (0.0 - 1.0)
    - tier: string (starter | trusted | verified | expert)
    - totalCorrections: int
    - acceptanceRate: double
    - lastActiveAt: timestamp
    - history: map<date, event[]>

  trust_civic/{userId}
    - score: double (0.0 - 1.0)
    - tier: string (observer | contributor | verifier | moderator)
    - totalReports: int
    - verificationRate: double
    - lastActiveAt: timestamp

  trust_community/{userId}
    - score: double (0.0 - 1.0)
    - tier: string (newcomer | member | regular | leader)
    - totalPosts: int
    - helpfulnessScore: double
    - moderationActions: int

  gamification_level/{userId}
    - level: int
    - points: int
    - tokens: int
    - achievements: map<string, bool>
    - (NO cross-domain trust influence)
```

### 3. Cross-Domain Visibility Rules

| Domain | Public | User sees own | Moderator sees |
|---|---|---|---|
| AI Training Trust | Badge only ("Trusted Corrector") | Full score + history | Full + raw events |
| Civic Trust | Badge only ("Verified Reporter") | Full score + history | Full + raw events |
| Community Trust | Badge only ("Community Leader") | Full score + history | Full + raw events |
| Gamification Level | Visible level + achievements | Full breakdown | Read-only |

**Key rule**: No domain's score is visible in another domain's context. A user's profile shows each badge separately.

### 4. Trust Score Computation

```javascript
function computeScore(events, params) {
  // Recency-weighted moving average
  const weightedSum = events
    .filter(e => withinTimeWindow(e, params.decayDays))
    .map(e => e.weight * decayFactor(e.timestamp))
    .sum();
  
  // Logarithmic cap — harder to increase at high scores
  const cappedScore = Math.log(1 + weightedSum) / Math.log(1 + params.maxWeightedSum);
  
  // Clamp to [0, 1]
  return Math.max(0, Math.min(1, cappedScore));
}
```

- **Positive events** (correction accepted, report verified) increase score.
- **Negative events** (correction rejected, report found false, moderation action) decrease score.
- **Recency weight**: Events > 30 days ago decay by 50%; > 90 days ago decay to 10%.
- **Cap**: No single event can increase score by more than 0.05 (prevents farming).
- **Floor**: Users start at 0.2 (default trust for new users). Can go to 0.0 (banned) or 1.0 (highest trust).

### 5. Cross-Domain Enforcement

| Scenario | What Happens | Why |
|---|---|---|
| User A has high community trust | User A's civic reports still go through normal review queue | Different domains |
| User B has high AI trust | User B's community posts still moderated until community trust earned | Different domains |
| User C has high gamification level | User C's corrections still reviewed unless AI trust is high | Gamification != trust |
| User D is banned in civic trust | User D's AI corrections and community posts are unaffected | Domain isolation |
| User E is malicious in ALL domains | Admin-level global ban overrides all domain trust | Emergency safety valve |

### 6. Global Emergency Bypass

A single "trust kill switch" that overrides all domains:
- **Triggered by**: Manual admin action (not automated — too risky for false positive).
- **Effect**: User's actions in ALL domains go to mandatory review.
- **Duration**: 7 days, renewable.
- **Use case**: Detected bot farm, coordinated spam attack, malicious user exploiting cross-domain gaps.

---

## Design Patterns

### Pattern 1: Profile Badge Display
```
┌─────────────────────────────────────┐
│ User Profile                        │
│                                     │
│ Jane Doe                            │
│ ─────────────────────────────       │
│                                     │
│ 🏆 Level 15 Eco Warrior             │ ← Gamification
│ 🔬 Trusted Corrector (AI)          │ ← AI trust badge
│ 🏙️ Verified Reporter (Civic)       │ ← Civic trust badge
│ 👥 Community Leader                 │ ← Community trust badge
│                                     │
│ [View details ▸]                    │
└─────────────────────────────────────┘
```

### Pattern 2: Trust Detail Screen (Self-Only)
```
┌─────────────────────────────────────┐
│ Your Trust Profile                  │ ← User sees only own
│                                     │
│ AI Training Trust                   │
│ 🌟 Trusted Corrector                │
│ Corrections: 47 | 91% accepted     │
│ Last active: 3 days ago             │
│                                     │
│ Civic Report Trust                  │
│ 🌟 Verified Reporter                │
│ Reports: 12 | 83% verified         │
│ Last active: 2 weeks ago            │
│                                     │
│ Community Trust                     │
│ 🌟 Community Leader                 │
│ Posts: 8 | 95% helpful             │
│ Last active: 1 week ago             │
│                                     │
│ [How trust works ▸]                 │
└─────────────────────────────────────┘
```

---

## Implementation Recommendations

### Phase 1 (Foundations)
1. Define trust domain schema in Firestore (separate collections).
2. Implement base trust score computation (recency-weighted + capped).
3. Create trust badge system for user profiles.
4. Wire AI training trust into correction auto-approval.

### Phase 2 (Domain Separation Enforcement)
5. Ensure no code path reads trust from wrong domain.
6. Add trust gating to civic report publishing.
7. Add trust gating to community feed posting.
8. Implement global emergency bypass for admin.

### Phase 3 (Advanced Features)
9. Public badge display on profile.
10. Trust score decay for inactive users.
11. Cross-domain routing for user reports.
12. Automated anomaly detection for cross-domain farming.

---

## Audit Checklist

Before shipping any civic or community feature that uses trust:
- [ ] Is AI training trust immutable from civic/gamification actions?
- [ ] Is civic report trust immutable from AI/gamification actions?
- [ ] Is gamification level explicitly prevented from influencing trust scores?
- [ ] Are trust collections separate in Firestore (no `domain` discriminator hack)?
- [ ] Are security rules scoped per collection?
- [ ] Is there a manual global ban override?
- [ ] Is there a rate limit on trust-granting actions?

---

## Open Questions

1. Should trust scores be visible to other users (with privacy controls) or completely private?
2. What is the correct decay half-life for each domain?
3. Should new users start at 0 trust (all actions reviewed) or 0.2 (basic trust)?
4. How do we handle trust portability if a user is also a moderator/admin in real life?
5. Should we offer an appeal for trust score changes ("my correction was incorrectly rejected")?

---

## Next Steps

1. Design Firestore schema for separate trust collections.
2. Implement `TrustScoreService` with recency-weighted computation.
3. Wire trust gating into correction auto-approval path.
4. Create trust badge components for user profiles.
5. Write security rules enforcing cross-domain separation.
6. Add trust score monitoring to operator dashboard.
