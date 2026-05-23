# Moderation & Safety Baseline

**Date**: 2026-05-23
**Status**: Exploration — baseline policy for community safety
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) entry 23
**Decision this unblocks**: Any social/community growth investment; no social surface should scale without this
**Kill criteria**: If the app removes all social features, moderation is unnecessary

---

## 1. Current State

### What exists

| Feature | Implementation | Status |
|---------|---------------|--------|
| AI confidence display | Result screen shows confidence percentage | Live |
| Error logging | `WasteAppLogger` with context | Live |
| Firestore security rules | Basic data protection | Live |
| Community feed | `community_feed` Firestore collection | Live |
| User corrections | `CorrectionDialog` for user feedback | Live |

### What's missing

| Gap | Severity | Detail |
|-----|----------|--------|
| No content reporting | Critical | Users cannot flag inappropriate content |
| No moderation queue | Critical | No way to review flagged content |
| No user trust scoring | High | No system to identify reliable vs unreliable contributors |
| No safety warnings | High | Missing guidance for hazardous/medical waste handling |
| No appeals process | Medium | No way to challenge moderation decisions |
| No automated toxicity detection | Medium | No profanity/harassment filter |

---

## 2. Moderation Tiers

### Tier 1: Automated (always on)

- AI confidence threshold: reject classifications below 30% from community feed
- Spam detection: rate-limit posts per user per hour (max 10)
- Content hash: detect and block exact duplicate images
- Prohibited content: block images flagged by AI safety filters

### Tier 2: Community-driven (scaled)

- User reporting: "Report" button on every community post
- Confidence voting: users can upvote/downvote classifications
- Trust score: users with high correction accuracy get more weight
- Automatic takedown: 3+ reports auto-hides pending moderator review

### Tier 3: Human moderation (for scale)

- Moderation queue for flagged content
- Moderator dashboard (web or admin screen)
- Appeals flow for moderated content
- Escalation path for safety-critical content

---

## 3. Safety Protocols

### Hazardous waste classification

When AI detects hazardous/medical waste:
1. Show safety warning: "This item requires special disposal"
2. Never show "Recyclable" or "Compostable" for hazardous items
3. Always display nearest hazardous waste disposal facility
4. Disable community sharing for hazardous waste photos (privacy risk)
5. Log as safety-critical for eval harness tracking

### User-generated content safety

For community posts and contributions:
1. Strip EXIF data before upload
2. Auto-detect and blur faces (when face detection is implemented)
3. Block images containing prescription labels, addresses, license plates
4. Require user acknowledgment before posting publicly

---

## 4. Trust Scoring

### User trust model

| Level | Trust Score | Capabilities |
|-------|-------------|-------------|
| New | 0–10 | Post with moderation delay |
| Contributor | 11–50 | Post appears immediately, can report |
| Expert | 51–80 | Posts highlighted, reports carry more weight |
| Trusted | 81–100 | Posts auto-approved, moderation bypass |

### Score calculation

```
trustScore = (correctionsAccepted * 5)
           + (classificationsCorrect * 1)
           - (reportsReceived * 10)
           + (daysActive * 0.5)
           - (spamFlags * 20)
```

Score range: 0–100, decays 1 point per week of inactivity.

---

## 5. Implementation Sequence

1. Add "Report" button to community feed items
2. Create `moderation_queue` Firestore collection
3. Implement report counting and auto-hide at 3 reports
4. Add hazardous waste safety warning overlay
5. Build moderator queue screen (admin)
6. Implement trust score calculation
7. Add face detection + EXIF stripping for community images

---

## 6. Related

- [Community Trust Layer](../EXPLORATION_TOPICS.md#20-community-feed-trust-layer-) — broader trust model
- [Privacy / Photo PII](PRIVACY_PHOTO_PII.md) — image safety
- [Data Retention](DATA_RETENTION_AND_PII_STRATEGY.md) — content retention
