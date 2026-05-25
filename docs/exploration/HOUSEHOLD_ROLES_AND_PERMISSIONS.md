# Household Roles & Permission Model

**Status**: Draft — no code surface for family/household roles exists yet.
**Priority**: P2 (next after core VLM/MLOps maturity)
**Related**: [FAMILY_COOPERATIVE_MECHANICS.md](FAMILY_COOPERATIVE_MECHANICS.md), [FAMILY_DASHBOARD_UI.md](FAMILY_DASHBOARD_UI.md), Kid-Safe Mode (separate doc), Classroom Mode (separate doc)
**Last Updated**: 2026-05-25

---

## Why This Is a Topic

Family/household waste management is a fundamentally different product surface from individual use:

1. **Shared bins, shared responsibility** — a family's waste is a collective output, but individual members contribute differently.
2. **Adult-child dynamics** — parents want to teach, monitor, and reward. Children need safe, encouraging, age-appropriate experiences.
3. **Accountability boundaries** — what a child sees about a parent's waste habits (and vice versa) needs careful design to avoid shame, nagging, or privacy violations.
4. **Multi-device, same-household** — who can join, who can leave, who can manage membership.

The current app assumes a single-user model. Household mode requires a new permission layer that sits above individual accounts.

---

## Household Role Models

### Proposed Tier: 3-Role Model

| Role | Capabilities | Constraints |
|------|-------------|-------------|
| **Admin** (1-2 per household) | Invite/remove members, edit shared goals, manage linked devices, access household analytics, set reward thresholds, configure local society rules | Cannot view individual member correction history without consent |
| **Member** (N per household) | Log classifications, view shared impact, participate in household goals, see own history | Cannot manage membership, cannot see other members' individual history (only aggregated) |
| **Guest / Child** (N per household) | Log simplified classifications, view team progress, see own rewards, use kid-safe UI | Cannot modify others' logs, no public community, no sharing, no ads |

### Alternative: Flat model (all members equal)

Simpler but loses parent-child teaching value. Works for roommate/co-living scenarios.

### Decision: Start with flat Member + Child, add Admin later

- **Phase 1**: Create household, invite by link/QR, all members equal. No roles.
- **Phase 2**: Add Child role (kid-safe UI, limited permissions, parent oversight).
- **Phase 3**: Add Admin role (manage members, household-level settings, analytics).

This avoids overbuilding role infrastructure before the household feature is validated.

---

## What Carries Between Household Roles

When a user joins a household, what data is visible to whom:

| Data Type | Visible to Admin | Visible to Other Members | Visible to Child |
|-----------|-----------------|------------------------|-------------------|
| Individual classification history | Sum of all, not per-person | Own only | Own only (simplified) |
| Household total impact | ✓ | ✓ | ✓ (kid-friendly) |
| Individual gamification points | Can see own, cannot see others' | Own | Own |
| Household gamification points | ✓ | ✓ | ✓ |
| Correction history | Cannot see others' without consent | Own | Own |
| Household goals/progress | Full edit + view | View, suggest | View, participate |
| Society rules/overrides | ✓ (if admin role exists) | View only | View only |

---

## Invite and Join Flow

### Options

1. **QR code scan**: Admin generates QR. New member scans to join. Simple, physical-proximity-gated.
2. **Deep link with token**: Admin shares a one-time-use link. Works remotely.
3. **Manual add by email/phone**: Requires contact permission. Higher friction but works for remote families.

### Recommendation

- Default: QR code (for in-home setup) + deep link fallback (for remote family members).
- One-time-use tokens with 24h expiry. Token is valid for joining only — membership management is role-gated.

### Join verification

- No join approval needed for invite-based flow (the sharer controls who gets the link/QR).
- Admin can revoke membership at any time.

---

## Child Account Considerations

### COPPA / GDPR-K Implications

- Children under 13 (US) or 16 (EU): must not create standalone accounts.
- **Solution**: Child is appended to a parent/guardian's existing account. No email, no password, no personal data collection beyond what the parent provides.
- Progress data is stored under the parent's account with a "child profile" sub-key.

### Child UX Boundaries

- No public community feed, no sharing to social media.
- No ads or promotional content.
- No external links without parental gate (math problem or long-press pattern).
- Simplified classification result: icon + bin colour + action, no technical detail.
- Large touch targets (minimum 44pt), voice guidance for pre-literate children.
- Reward framing: team-focused ("we diverted X kg!") not individual competition.

---

## Household Goals

### Goal Types

| Type | Description | Success Metric |
|------|-------------|----------------|
| Diversion target | "Divert 50kg from landfill this month" | kg diverted, tracked by material |
| Consistency | "Classify every day for 7 days" | Streak days, per household |
| Learning | "Identify 5 hazardous items correctly" | Accuracy on hazardous category |
| Challenge | "Beat your best month" | Compare current vs previous period |

### Goal Setting

- Admin creates goals during household setup or anytime via settings.
- Goals are visible to all members in the household dashboard.
- Progress is aggregated across all members (team achievement).

### Rewards

- Household-level milestone badges (e.g., "Bronze Household: 100kg diverted").
- Tokens earned per household milestone, split equally or pooled (design decision).
- No individual ranking within household — cooperative framing is deliberate.

---

## Multi-Device Semantics

- Each user signs in with their own Firebase Auth account.
- "Join household" links the auth UID to a Firestore `households/{householdId}/members/{userId}` subcollection.
- A user can be in at most one household at a time (simplicity constraint — revisit if needed).
- History from before joining the household remains private to the individual and is not shared retroactively.

---

## Open Questions

1. **Leaving a household**: does the user's household-contributed data stay (aggregated) or get deleted? Proposal: contributions stay in aggregate, but the user's individual history disconnects.
2. **Household deletion**: admin can delete the household. What happens to member data? Proposal: members' individual histories survive; only the household-level aggregate is removed.
3. **Token sharing**: should household tokens be pooled or separate? Risk: token farming through household expansion. Proposal: tokens remain individual; only impact/stats are shared.
4. **Non-family households**: roommates, co-living, eco-communities. Same model applies? Proposal: yes — the role model is household-first, not family-first. Rename "Family" → "Household" in UI.

---

## Related Work

- [FAMILY_COOPERATIVE_MECHANICS.md](FAMILY_COOPERATIVE_MECHANICS.md) — game mechanics for cooperative play (pre-dates this doc)
- [FAMILY_DASHBOARD_UI.md](FAMILY_DASHBOARD_UI.md) — dashboard design for family impact visualization
- Kid-Safe Mode (separate doc) — safety, content filtering, and parent controls for child users
- Classroom Mode (separate doc) — school/teacher version with different role semantics
