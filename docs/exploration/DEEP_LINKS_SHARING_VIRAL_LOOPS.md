# Deep Links, Sharing & Viral Loops

**Status**: Exploration — patterns and recommendations for growth loops  
**Date**: 2026-05-25  
**Why this matters**: An app whose classification result can be *shared* and produces a *recipient install* is a fundamentally different growth model. Dynamic links exist; the loop they enable isn't designed.

---

## 1. Current State

**What exists:**
- `lib/services/dynamic_link_service.dart` — Firebase Dynamic Links (pre-deprecation)
- `lib/screens/social_screen.dart` — social/community screen
- `lib/models/shared_waste_classification.dart` — shared classification model
- `lib/services/referrals.dart` — referral tracking (`functions/src/referrals.ts`)

**What's missing:**
- Shareable artifact design (what gets shared)
- Attribution model (sharer gets credit for install)
- Deep-link landing UX (shared item vs onboarding)
- Anti-spam rules for referral programs
- Firebase Dynamic Links is deprecated — migration plan needed

---

## 2. Shareable Artifacts

### Classification Result Card

The most shareable artifact is the **classification result card** — a visually rich image showing:

```
┌─────────────────────┐
│  ♻️ ReLoop          │
│                     │
│   [PLASTIC BOTTLE]  │
│   PET-1             │
│   Confidence: 94%   │
│                     │
│   → Blue bin (clean)│
│   → Remove cap &    │
│     label first     │
│                     │
│   🔥 15-day streak  │
│   🌳 2.3kg CO₂ saved│
│                     │
│  [Scan with ReLoop]  │
└─────────────────────┘
```

**Key features:**
- Dynamic image generation (server-side or client-side)
- Clear CTA: "Scan with ReLoop" (deep link to install or open)
- Social proof: streak + impact metrics
- Categories: result card, impact summary, streak badge, challenge completion, achievement unlock

### Other Shareable Formats

| Artifact | Trigger | Shares install? |
|---|---|---|
| Classification result card | After each scan (opt-in) | ✅ Yes |
| Weekly/Monthly impact summary | Automated (weekly digest) | ✅ Yes |
| Streak milestone (30, 100, 365 days) | On achievement | ✅ Yes |
| Challenge completion card | On challenge deadline | ✅ Yes |
| Eco Wrapped (yearly) | Annual (Dec 31) | ✅ Yes |
| Badge unlock | On new badge | ✅ Yes |

---

## 3. Attribution & Referral Model

### How Attribution Works

```
1. User A taps "Share" on a classification result
2. App generates a deep link: https://reloop.app/s/c/abc123?ref=userA_uid
3. User A shares to WhatsApp/Instagram/etc.
4. User B taps the link:
   a. If app installed → opened to classification result card
   b. If app not installed → App Store / Play Store → install
5. User B opens app → deferred deep link resolves → User A credited as referrer
6. If User B completes activation (≥1 classification in first 7 days) → referral reward
```

### Attribution Scheme

For <100k MAU, a **custom URL-parameter-based system** (no third-party attribution vendor) is recommended:

```dart
// Deep link structure
Uri(
  scheme: 'https',
  host: 'reloop.app',
  path: '/s/c/{classification_id}',
  queryParameters: {
    'ref': 'userA_uid',
    'source': 'whatsapp', // optional, for channel tracking
  },
);
```

**Firebase Dynamic Links note**: Dynamic Links is deprecated (Mar 2025 — Aug 2026 sunset). Migrate to custom URL scheme + `apple-app-site-association` / `assetlinks.json` before the sunset date. The current `lib/services/dynamic_link_service.dart` needs a migration plan.

### What the Sharer Gets

| Condition | Reward |
|---|---|
| Referred user installs and completes 1 classification | +50 bonus points |
| Referred user completes 10 classifications | +100 bonus tokens |
| Referred user subscribes to premium | +500 bonus tokens + "Referral Hero" badge |

### Anti-Spam Rules

1. **Device fingerprinting**: Prevent self-referral (same device creating multiple accounts)
2. **Activity validation**: Reward only after meaningful engagement (≥1 classification within 7 days)
3. **Rate limiting**: Max 50 invites per day per user
4. **Suspicious pattern detection**: Abnormally high send-to-conversion rate triggers review
5. **Fraudulent referral ban**: Referrer banned from referral program if detected

---

## 4. Deep-Link Landing UX

### Flow for First-Time Users

```
Tap deep link → App Store/Play Store → Install → First open

Landing screen options:
[Option A] Show the shared content immediately (no onboarding)
           → After viewing: "Want to scan your own items? Let's start!"
[Option B] Show minimal onboarding → Then the shared content
           → "Here's what [Friend] found. Now try it yourself!"
[Option C] Full onboarding → Then shared content

Recommendation: Option B + contextual onboarding
```

### Flow for Returning Users

```
Tap deep link → App opens → Navigate to shared content directly
→ After viewing: return to previous state (home / result screen)
```

### Fallback (Content No Longer Available)

If the shared classification result has been deleted or privacy-expired:
```
"Oops — this item was classified on [date] and is no longer available.
Here are some popular items our community has scanned!"
[Show featured classifications]
```

---

## 5. Sharing Surfaces

| Platform | Implementation | Notes |
|---|---|---|
| WhatsApp | Share image + link via share sheet | Most popular in India |
| Instagram | Share image to stories (with app link sticker) | Requires Instagram app |
| Twitter/X | Share image + short text + link | Text: "I just recycled a..." |
| Facebook | Share classification card | |
| SMS/MMS | Share link (with fallback text) | For older devices |
| Copy link | Copy to clipboard | Fallback for all platforms |

---

## 6. Viral Loop Metrics

| Metric | Definition | Target |
|---|---|---|
| Share rate | shares / total classifications | >5% |
| Install rate (shared link) | installs / link taps | >15% |
| Activation rate (referred) | activated / installed referred users | >50% |
| Referral K-factor | avg referrals per user × conversion rate | >1.0 for viral growth |
| Cost per referral | total reward cost / activated referred users | <$0.50 |

---

## 7. Open Questions

1. **Firebase Dynamic Links migration**: Should we build a custom redirect server or use a lightweight solution like Branch.io (paid) or custom URL scheme?
2. **Should share be automatic or opt-in?** Some apps auto-share milestones — this feels spammy. Recommend opt-in for every share, but make it one tap.
3. **Reward economics**: Are the proposed referral rewards sustainable with the token economy? 50 points per referral = 5 free cloud classifications. Must not exceed token budget.
4. **Deep link to onboarding**: For first-time users, should we prioritize the shared content or the onboarding flow?

---

## 8. Related Docs

- `docs/exploration/SOCIAL_SHARING.md` — social features
- `docs/exploration/TOKEN_ECONOMY_AND_PRICING_COHERENCE.md` — referral reward economics
- `docs/exploration/LAUNCH_AND_STORE_COMPLIANCE.md` — ATT and sharing
- `lib/services/dynamic_link_service.dart` — current implementation
- `lib/services/referrals.dart` — referral tracking
