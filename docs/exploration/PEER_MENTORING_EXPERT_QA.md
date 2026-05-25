# Peer Mentoring and Expert Q&A

**Status**: Draft — no code surface for peer mentoring or community Q&A exists yet.
**Priority**: P2 (builds on community trust layer and expert escalation network)
**Related**: MODERATION_AND_SAFETY.md, TRUST_SCORE_SEPARATION.md, HUMAN_EXPERT_ESCALATION_NETWORK.md (separate doc)
**Last Updated**: 2026-05-25

---

## Why This Is a Topic

The classification pipeline can answer "what is this?" and "where does it go?" but it cannot answer:

- "My apartment doesn't accept glass — what do I do?"
- "Is this compostable liner actually compostable in my city's facility?"
- "Does anyone know a kabadiwala who takes old mattresses?"

These questions require hyper-local, lived-experience knowledge that no model or ruleset can provide. Peer-to-peer Q&A fills this gap — but with moderation risks (incorrect disposal advice can cause real harm).

---

## Design Principles

1. **Safety first**: incorrect disposal advice can cause environmental harm, safety incidents, or municipal fines. Answers must be reviewable and correctable.
2. **Local-first**: the most valuable knowledge is hyper-local (building, neighborhood, city).
3. **Reputation, not currency**: knowledge sharing is rewarded with reputation, not tokens (anti-farming).
4. **Complementary to AI**: Q&A is the fallback when the AI is unsure, not a replacement.

---

## Q&A Flow

```
User has question → search existing Q&A → [if found] → show answer
                                → [if not found] → post question
                                  → optionally route to expert (by category)
                                  → peers + experts answer
                                  → best answer selected by votes or expert endorsement
                                  → question indexed for future searches
```

### Question Prompting

After classification, if confidence is low (< 0.6), the app shows: "Not sure about your area's rules? Ask a neighbor."

Users can also open Q&A from the main navigation (community tab).

### Question Format

| Field | Required | Notes |
|-------|----------|-------|
| Title | Yes | e.g., "Does Bangalore accept #5 plastic?" |
| Category | Yes | e-waste / plastic / hazardous / local-rules / composting / facilities |
| City/Location | Optional | Auto-filled from GPS |
| Photo | Optional | Up to 3 photos |
| Follow-up | Optional | For clarifications |

---

## Expert System

### Expert Tiers

| Tier | Criteria | Privileges |
|------|----------|------------|
| **Community member** | Any verified user | Ask questions, answer, vote |
| **Trusted contributor** | 10+ helpful answers (community-voted) | Bypass review gate for answers |
| **Domain expert** | Verified professional (waste mgmt, municipal, recycling) | Endorsed answers get priority display |
| **Moderator** | Appointed by platform team | Delete, edit, non-public appeal actions |

### Expert Verification

- **Self-declared**: user selects "I am a waste/sustainability professional" → provides supporting info.
- **Verified**: email domain check (e.g., @bbmp.gov.in, @recycler.com), LinkedIn verification, or manual review by platform team.
- **Community-voted**: users can endorse "this person knows their stuff" — threshold for "trusted contributor" status.

### Expert Badging

- Expert badge displayed next to answer (domain-specific: "e-waste expert", "composting specialist", "Bangalore rules expert").
- Verified badge (blue check) for platform-verified experts.
- Badges are per-domain (expert in one category may not be expert in another).

---

## Answer Quality Guardrails

### Pre-Submission

- For high-risk categories (hazardous, medical, e-waste), answer requires confirmation: "This advice relates to hazardous materials. Are you sure it's correct?"
- Auto-filters for common incorrect advice: "You can burn plastic" → blocked, user shown correct information.
- "Did you know?" nudge: if the answer contradicts the local rules database, user is warned before posting.

### Post-Submission

- New user answers held for review (auto-published for trusted/expert users).
- Community flagging: "This answer may be incorrect" → flags for moderator review.
- Downvoting threshold: if an answer reaches -5 karma, it's collapsed (still visible but de-emphasized).
- Platform override: if an answer is factually incorrect, moderator can replace it with correct answer + notification to all who saw it.

### Corrections

- If a user corrects a classification result, and the correction highlights a systemic gap, the system should offer to turn it into a Q&A thread: "Many users have this question — want to help others?".
- If an answer is later found to be incorrect:
  1. Answer is flagged as "corrected."
  2. Original answerer is notified (not penalized — good faith).
  3. All upvotes on the incorrect answer are refunded.
  4. Correct answer is promoted to top.

---

## Incentive Design

### What's Rewarded

| Action | Reward | Notes |
|--------|--------|-------|
| Answering (community-voted helpful) | +10 reputation | Per upvote |
| Expert-endorsed answer | +50 reputation | Bonus |
| Accepted answer | +25 reputation | When asker accepts |
| Flagging incorrect answer | +5 reputation | Anti-abuse: penalized for false flags |
| Asking a good question | +5 reputation | Questions that get 3+ upvotes from community |
| Mentoring new users | +15 reputation | Per acknowledged-mentoring interaction |

### What's NOT Rewarded (Anti-Farming)

- Answering volume alone (answers with 0 upvotes nor downvotes give no reputation).
- Quick, low-effort answers (minimum 50 characters, must be on-topic).
- Answering and downvoting competitors (impossible — users cannot downvote answers on their own questions).

### No Token Rewards

Knowledge sharing rewards reputation, not tokens. This separates the gamification economy from the knowledge economy — preventing users from farming tokens by spamming answers.

---

## Community Notes Model

Inspired by X/Twitter's Community Notes:

- If an answer is flagged as potentially incorrect by 2+ users, a "community note" is appended below it.
- The note is written by another user (or expert) and must cite a source (link to city rules, photo of bin label, etc.).
- Community notes are themselves rateable: if helpful, they're promoted; if unhelpful, collapsed.
- This is a lightweight alternative to full moderator review for borderline cases.

---

## Question Routing and Discovery

- **By location**: questions from same city/neighborhood are prioritized in the feed.
- **By category**: user can browse "hazardous" questions only.
- **By unanswered**: filter to see questions with no answers yet — low-hanging fruit for experts.
- **Notification**: when a question matches a user's expertise + location, they receive a notification.
- **FAQ generation**: top-answered questions auto-curate into a searchable FAQ.

---

## Moderation Overhead Estimate

At <100k MAU:

| Activity | Daily Volume | Review Needed |
|----------|-------------|---------------|
| Questions | 50–200 | 10% flagged for review |
| Answers | 200–800 | 5% flagged |
| Flags/reports | 10–50 | 100% reviewed |
| **Total review load** | ~25–100 items/day | Feasible for 0.5–1 FTE |

Automated moderation (spam filter, rule contradiction detection, high-risk keyword flag) covers 70–80% of volume. Human review focuses on flagged content and high-risk categories.

---

## Open Questions

1. **Language**: should Q&A support multiple languages (English, Hindi, Kannada)? Proposal: Yes — classification is already multilingual. Q&A should be too. Users can set their preferred language; answers in that language are prioritized.
2. **Should there be a "private" Q&A option?** For questions about specific buildings/societies? Proposal: no — all Q&A should be public (the knowledge is a community good). Private questions can go through the support channel.
3. **How to seed content?** Initially, the platform team should create 50–100 starter Q&A pairs based on common support queries. This gives new users something to search before the first question is asked.
4. **Expert onboarding**: should experts be recruited (invite-only) or self-select? Proposal: self-select with verification gate for high-trust categories.

---

## Related Work

- MODERATION_AND_SAFETY.md — moderation infrastructure shared with Q&A
- TRUST_SCORE_SEPARATION.md — reputation scoring that Q&A trust builds on
- HUMAN_EXPERT_ESCALATION_NETWORK.md (separate doc) — formal expert referral for high-risk cases
- [USER_CONTRIBUTION_UGC_PIPELINE.md](USER_CONTRIBUTION_UGC_PIPELINE.md) — related UGC review pipeline
- [WHY_THIS_ANSWER_EXPLANATION.md](WHY_THIS_ANSWER_EXPLANATION.md) — explaining AI decisions, which Q&A can help when AI is uncertain
