# Consent Architecture

**Status**: Exploration doc
**Last Updated**: 2026-05-25
**Category**: Compliance & Trust / Data, Cost & Reliability
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md#a19-consent-architecture-)
**Related**: Privacy / Photo PII (#32), Data Retention & PII (#14), Regional Regulations (#33), Analytics Schema Governance (A18), Launch & Store Compliance (A14)

---

## Why This Is a Topic

Consent is currently fragmented across the app: analytics consent, ATT prompt, ad consent, training-data consent (via `UserConsentService`), photo-upload consent. Each domain fires independently; there is no unified record of "what has this user consented to?" across all touchpoints. This doesn't survive a GDPR / DPDP audit.

The app operates in multiple consent-sensitive domains:
- **Analytics**: Firebase Analytics events pre- vs post-consent
- **Ads**: AdMob personalization opt-in
- **Training data**: user photos used for model improvement
- **Photo upload**: community posts / correction images
- **Community**: public profile, social features
- **Location**: region detection for rules
- **Notifications**: push / local
- **ATT**: iOS App Tracking Transparency

A versioned consent ledger is needed as the single source of truth — and all eight domains need to read from it rather than maintaining independent booleans.

---

## Key Questions

1. **Granular vs blanket consent** — should the consent dialog present a single "accept all" toggle, per-domain toggles, or tiered (essential + optional)?
2. **Ledger design** — where does the ledger live (Firestore collection), what schema, how versioned?
3. **Withdrawal mechanics** — when a user revokes training-data consent, what happens to already-labelled data and ongoing model training cycles?
4. **Re-prompt cadence** — when should a consent prompt re-fire after the user has already answered (policy update, long dormancy, new feature)?
5. **Just-in-time consent** — should non-essential consents be requested only at the moment the feature is used, rather than in an upfront dialog?
6. **Cross-service cascade** — if analytics consent is revoked, should Firebase Analytics be fully disabled or allowed to send minimal telemetry?

---

## Research Summary

### Granular vs Blanket

GDPR and DPDP both mandate **granular consent**. A single "I agree to all" checkbox is non-compliant for distinct processing purposes. Each domain (analytics, ads, training data, location, community) must have a separate opt-in.

**Recommendation**: Tiered consent screen:
- **Essential** (no opt-out): app functionality, crash reporting — no toggle
- **Analytics & Improvement**: single toggle for Firebase Analytics + model improvement
- **Personalization**: ads + recommendation — single toggle
- **Community & Social**: profile visibility + content sharing — per-toggle
- **Location**: single toggle (region detection)

### Single Consent Ledger Design

Each consent event writes to a `consent_ledger` Firestore collection:
```
{
  user_id: string,
  consent_type: enum (analytics, ads, training, photo_upload, community, location, notifications, att),
  status: enum (GRANTED, REVOKED, NOT_ASKED),
  timestamp: Timestamp,
  policy_version: string (semver of privacy policy at time of event),
  app_version: string,
  metadata: { source: "onboarding_dialog" | "settings" | "just_in_time" | "re_prompt" }
}
```

Current state for each user is computed as `latest event per consent_type`. The ledger is append-only — never mutate a past grant.

### Withdrawal Mechanics for Training Data

When training-data consent is revoked:
- Immediate: stop including new user data in training queues
- Existing data: mark as `do_not_use` in the dataset pipeline — remove from active training queues and flag for exclusion from future model retraining runs
- Full erasure: if user also requests deletion, cascade to `TrainingDataService` to purge images and labels

### Re-prompt Cadence

- **Just-in-time strategy**: ask for non-essential consent when the feature is first used, not during onboarding
- **Policy updates**: re-prompt when `policy_version` changes, but only for the domains affected by the change
- **Dormancy**: do not re-prompt automatically on activity resumption; use a 12-month expiry window per consent type
- **Rate limit**: maximum 1 re-prompt per domain per 90 days

### Just-in-Time Consent Pattern

For consents that aren't essential at onboarding (training, community, location):
- Defer the prompt until the user taps the feature
- Show a contextual dialog explaining the data use and value proposition
- Allow "not now" which sets NOT_ASKED status (not REVOKED)
- This improves onboarding conversion while maintaining compliance

### Firebase vs Custom Ledger

Two parallel systems needed:
- **Firebase / Google Consent Mode v2** — for Google SDK compliance (Analytics, Ads). Handles the signaling layer.
- **Custom ledger** (Firestore) — the source of truth for business logic. All backend services read from this.

The custom ledger is authoritative; the Firebase SDK state is derived from it.

---

## Design Recommendations

### Schema: User Consent State (computed view)

```
UserConsentState {
  analytics: GRANTED | REVOKED | NOT_ASKED
  ads_personalized: GRANTED | REVOKED | NOT_ASKED
  training_data: GRANTED | REVOKED | NOT_ASKED
  photo_upload: GRANTED | REVOKED | NOT_ASKED
  community: GRANTED | REVOKED | NOT_ASKED
  location: GRANTED | REVOKED | NOT_ASKED
  notifications: GRANTED | REVOKED | NOT_ASKED
  att: GRANTED | REVOKED | NOT_ASKED
  policy_version: string (current)
  last_updated: Timestamp
  consent_ledger_last_id: string (for incremental sync)
}
```

### Implementation Path

1. Create `consent_ledger` Firestore collection with the schema above
2. Create `ConsentLedgerService` that wraps all write operations to the ledger
3. Create `UserConsentState` computed model (reads latest event per type)
4. Migrate existing `UserConsentService` and `AnalyticsConsentManager` to read from the ledger
5. Wire `ConsentDialogScreen` to write to the ledger
6. Add consent-version header to all `generateDisposal` and `classifyImage` proxy calls
7. Add re-prompt logic triggered by `policy_version` drift
8. Build a privacy dashboard in Settings showing current consent state with per-domain revoke toggles
9. Add audit export: admin can dump a user's consent ledger as JSON

### Kill Criteria

- Single ledger adds more complexity than the independent booleans it replaces (measure: implementation cost > 2 weeks)
- Just-in-time consent prompts confuse more users than the blanket upfront dialog (A/B test the two patterns)

---

## Open Questions

- Should `NOT_ASKED` and `REVOKED` be treated identically by consumers, or should the system behave differently?
- How long should we retain consent ledger entries after account deletion (GDPR retention vs audit trail)?
- Should location consent be treated as essential in India under DPDP given the regional-rules dependency?
