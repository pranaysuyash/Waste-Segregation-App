# Kid-Safe Mode

**Status**: Draft — no code surface for kid-safe mode exists yet.
**Priority**: P2 (gates classroom and family modes)
**Related**: [HOUSEHOLD_ROLES_AND_PERMISSIONS.md](HOUSEHOLD_ROLES_AND_PERMISSIONS.md), [CLASSROOM_MODE_TEACHER_DASHBOARD.md](CLASSROOM_MODE_TEACHER_DASHBOARD.md), [LOW_LITERACY_MULTILINGUAL_UX.md](LOW_LITERACY_MULTILINGUAL_UX.md), [ACCESSIBILITY_CAMERA_FLOWS.md](ACCESSIBILITY_CAMERA_FLOWS.md)
**Last Updated**: 2026-05-25

---

## Why This Is a Topic

Kid-safe mode is **not** a "nice-to-have" — it's a legal and product requirement for any app that may be used by children:

1. **COPPA (US)** — prohibits collecting personal information from children under 13 without verifiable parental consent.
2. **GDPR-K (EU)** — requires explicit parental consent for children under 16 (member-state dependent).
3. **DPDP Act (India) 2023** — treats children under 18 as a special category with strict data processing rules.
4. **App Store policies** — Apple and Google require specific design patterns for apps targeting children.
5. **Product trust** — even if the app doesn't target children, families will use it. A poorly designed safety posture becomes a PR and legal risk.

Kid-safe mode must be designed **before** the app actively markets to families or schools.

---

## What Kid-Safe Mode Means

Kid-safe mode is a **separate configuration layer** that activates when:

1. **Parent/guardian creates a child profile** within their account (family/household mode).
2. **Teacher enables classroom mode** for students under 13 (school mode).
3. **App is set to "kids" audience** on app stores (App Store "Kids" category, Play Store "Teacher Approved").

When active, the following changes apply:

---

## Feature Switches in Kid-Safe Mode

| Feature | Standard Mode | Kid-Safe Mode |
|---------|---------------|---------------|
| Camera classification | ✓ | ✓ (with supervision of categories seen) |
| Cloud AI analysis | ✓ | ✓ (on-device preferred; parent toggle for cloud) |
| Community feed | ✓ | ✗ Hidden |
| Social sharing | ✓ | ✗ Blocked (parental gate for any sharing) |
| Ads (AdMob) | ✓ (free tier) | ✗ Never |
| External links | ✓ | ✗ Blocked (parental gate required) |
| User profile | Public or semi-public | ✗ No profile created |
| Location | GPS for region rules | ✗ Region selected manually by parent |
| Chat / direct messages | ✗ (not yet built) | ✗ Never (explicitly excluded from future) |
| Voice guidance | Optional | ✓ On by default |
| Quiz / education | ✓ | ✓ Age-tiered content |
| Correction feedback | Full detail | Simplified ("Great job!" / "Let's try again") |
| Gamification | Full (points, streaks, tokens) | Simplified (no token economy, no streaks) |

---

## Core Design Principles

1. **No personal data collected from the child.** No name, no email, no device ID, no location.
2. **No behavioural tracking or analytics.** Crash logs only (anonymized).
3. **No ads, no in-app purchases, no promotions.**
4. **Parent/guardian controls everything.** Child has no ability to change settings, opt out, or share data.
5. **Data is stored under the parent's account.** Child profile is a sub-key. If parent deletes account, child data is deleted.
6. **Cloud analysis is parent-opt-in.** Default: on-device classification only. Parent can enable cloud for higher accuracy, with informed consent that image leaves device.

---

## Age Bands

### 5–7 (Pre-literate / Early Literacy)

- **UI**: Icon-only, large touch targets (min 48pt), bright colours, no scroll required.
- **Voice guidance**: Tap-to-hear instructions. Every screen has a voice option.
- **Content**: "Does this go in the blue bin or the green bin?" Simplified to bin colours and actions.
- **Mechanics**: Tap the correct bin when the item appears. Reward: star + animation + happy sound.
- **No text**: Absolutely no written instructions or labels.

### 8–10 (Independent Readers)

- **UI**: Icons + short text labels. Mix of tap and swipe.
- **Classification**: "Scan this item — is it plastic, paper, or metal?" Simple 3-choice after scan.
- **Content**: Why recycling matters, what contamination is (in kid terms: "clean items recycle better!").
- **Mechanics**: Streak for consistency, badges for milestones ("Paper Pro: sorted 10 paper items!").
- **Learning**: Bite-sized facts after each classification.

### 11–13 (Critical Thinkers)

- **UI**: Standard UI but with content restrictions. More detailed results.
- **Classification**: Full categories but limited to safe materials (no detailed hazardous descriptions unless parent approves).
- **Content**: Recycling codes, local rules, environmental impact, composting.
- **Mechanics**: Quizzes, habit challenges, family goals.

---

## Parental Controls

### What Parents Control

| Setting | Options |
|---------|---------|
| **Age band** | 5–7 / 8–10 / 11–13 |
| **Cloud analysis** | On / Off (default Off) |
| **Quiz difficulty** | Easy / Medium / Hard |
| **Daily usage limit** | 15 / 30 / 45 / 60 minutes |
| **Content categories** | Which waste categories to show/hide (hide hazardous if too scary) |
| **Streak on/off** | Show streaks / don't show |
| **Data export** | Export child's progress report |

### How Parents Access Controls

- Parental gate: simple arithmetic (e.g., "What is 3 + 5?") or long-press on a specific icon.
- Settings are in the parent's account settings, not the child's interface.
- Changes apply immediately.

---

## App Store Compliance

### Apple App Store ("Kids" Category)

- No third-party analytics or advertising SDKs.
- Parental gate for all external links and in-app purchases (IAPs must be non-functional in Kids mode).
- Privacy policy must explicitly describe data handling for children.
- App must not collect any personal information from child users.
- Sign-in with Apple required if authentication is used (but kid mode should not require auth).

### Google Play ("Teacher Approved")

- No ad SDKs that use behavioural profiling.
- Data safety section must disclose no data collected from children.
- Content rated for "Everyone" or "Everyone 10+" — no mature themes.
- Parental controls must be described in app description.

---

## Technical Implementation Notes

### Data Model

```
parent_account (Firebase Auth)
  └── profiles/
       └── child_profile_1 (subcollection)
            ├── display_name: "Kid" (parent-set, not real name)
            ├── age_band: "5-7"
            ├── created_at: timestamp
            ├── settings: { cloud_analysis: false, daily_limit_min: 30 }
            └── progress: { items_classified: 42, badges: [...], quizzes_completed: 5 }
```

- `display_name` is set by parent, not requested from child. Can be a nickname.
- No email, no phone, no device ID stored in child profile.
- Progress data is limited to gameplay metrics — no location, no photo history, no correction details.

### Pipeline Impact

- Child-mode classification bypasses cloud AI unless parent explicitly opts in (client-side feature flag).
- On-device classification path is the default.
- Community feed routes are disabled at the router level (feature flag).
- Social sharing APIs are not registered.

### Security

- Parental gate is a client-side check (not server-enforceable for offline). For security-critical operations (purchase, data export), require parent re-auth via Firebase Auth.
- Child cannot escalate privileges — role enforcement is server-side in Firestore security rules.

---

## Open Questions

1. **Should kid-safe mode be available outside a parent account?** E.g., a standalone "Kids Waste Sorting Game"? Proposal: No — kid-safe mode requires parent/guardian supervision. A standalone kids app is a separate product decision.
2. **How to handle hazardous materials?** Kids may scan a battery, cleaning product, or broken glass. Positive framing ("this needs special care — tell a grown-up!") + parent notification.
3. **What about teenagers (14–17)?** Not covered by COPPA, but still minors. Proposal: standard mode with safety defaults (no public profile, limited sharing). Parent can adjust settings as needed.
4. **Offline kid mode?** Classification works offline. Progress syncs when parent's device is online.

---

## Related Work

- [HOUSEHOLD_ROLES_AND_PERMISSIONS.md](HOUSEHOLD_ROLES_AND_PERMISSIONS.md) — child role within household model
- [CLASSROOM_MODE_TEACHER_DASHBOARD.md](CLASSROOM_MODE_TEACHER_DASHBOARD.md) — student safety in school context
- [LOW_LITERACY_MULTILINGUAL_UX.md](LOW_LITERACY_MULTILINGUAL_UX.md) — icon-first, non-text interface design
- [ACCESSIBILITY_CAMERA_FLOWS.md](ACCESSIBILITY_CAMERA_FLOWS.md) — voice guidance and large-target interaction
- [CONSENT_ARCHITECTURE.md](CONSENT_ARCHITECTURE.md) — consent foundations that must support minor-data limitations
