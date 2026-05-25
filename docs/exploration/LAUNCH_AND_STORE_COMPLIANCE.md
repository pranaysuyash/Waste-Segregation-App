# Launch Readiness & App Store Compliance

**Status**: Exploration — compliance readiness assessment  
**Date**: 2026-05-25  
**Why this matters**: App Store / Play Store rejections (privacy disclosures, ATT, in-app purchase rules, content moderation, kid-targeted features) are recurring product-shaping forces, not one-off chores. Getting these right before launch prevents last-minute scrambling.

---

## 1. Current State

**What exists:**
- `docs/launch/CLOSED_BETA_SMOKE_CHECKLIST.md` — smoke checklist for beta launch
- `docs/launch/LAUNCH_BLOCKERS.md` — known launch blockers
- `docs/planning/app_store_publication_p0_features.md` — P0 feature list for store publication
- Privacy policy in `assets/docs/privacy_policy.md`
- Terms of service in `assets/docs/terms_of_service.md`
- `lib/services/moderation_service.dart` — content moderation (alpha)
- `lib/services/user_consent_service.dart` — consent management (alpha)

**What's missing:**
- Current target App Store privacy nutrition label mapping
- Current target Play Store data safety form mapping
- ATT (App Tracking Transparency) implementation status
- In-app purchase compliance for token economy
- AI-generated content moderation evidence for store review
- GDPR / DPDP compliance checklist
- Kid/classroom policy implications assessment

---

## 2. App Store Privacy Nutrition Labels

### What Must Be Disclosed

The App Store requires disclosure for all data the app or its third-party SDKs collect:

| Data type | Collected? | Purpose | Linked to identity? | Tracking? |
|---|---|---|---|---|
| Photos/Images | Yes (camera roll) | App functionality (classification), Product personalization | Yes | No |
| Camera | Yes | App functionality | No | No |
| User ID (Firebase Auth) | Yes | App functionality, Analytics | Yes | No |
| Device ID | Yes (Firebase) | Analytics, App functionality | Yes | No |
| Crash data | Yes (Crashlytics) | Analytics | No | No |
| Purchase history | Yes (IAP) | App functionality | Yes | No |
| Product interaction | Yes (analytics events) | Analytics | Yes | No |
| Search history | Yes (classification history) | App functionality | Yes | No |
| Location (coarse) | Planned (city for local rules) | App functionality | No | No |

### Key Decisions Needed

1. **Classification images**: Are they sent to OpenAI/Gemini servers for processing? If so, this is "Data Used to Train/Improve" if the provider uses the data. Must verify each provider's data usage policy.
2. **On-device vs cloud**: If images are processed on-device, they never leave the user's device — reduces disclosure scope significantly.
3. **Third-party SDKs**: Firebase, Crashlytics, Google Ads, AdMob all have their own data collection. Must audit exactly what each SDK collects.

### Recommended Label

```
App Privacy:
- Data Used to Track You: Device ID, User ID
- Data Linked to You: 
  - Photos/Images (Product Personalization)
  - Purchase History (App Functionality)
  - Search/Classification History (App Functionality)
  - User ID (App Functionality)
- Data Not Linked to You:
  - Crash Data (Analytics)
  - Camera Usage (App Functionality)
```

---

## 3. Play Store Data Safety Form

### Declaration Items

| Category | Collected? | Shared? | Protected? | Notes |
|---|---|---|---|---|
| Location (approx) | Planned | No | Yes (encrypted) | City-level only, no precise GPS |
| Personal info (name, email) | Yes (if registered) | No | Yes | Firebase Auth |
| Financial info (purchase history) | Yes (IAP) | No | Yes | |
| Photos | Yes | Yes (to AI providers) | Yes (in transit) | Must disclose third-party sharing |
| App activity (scans, corrections) | Yes | No | Yes | |
| App diagnostics (crash data) | Yes | Yes (Crashlytics) | No | |
| Device IDs | Yes | Yes (analytics) | No | |

### Key Decisions

1. **Data sharing with third parties**: Images are sent to OpenAI/Gemini. This must be declared.
2. **Encryption in transit**: All image uploads use HTTPS. Document implementation.
3. **Data deletion**: User can delete history and photos. Document process.

---

## 4. ATT (App Tracking Transparency)

### Do We Need ATT?

- If the app uses analytics (Firebase Analytics) that collect IDFA / Google Ad ID and this data is used for *cross-app tracking*: **Yes, ATT required**
- If analytics data is used solely for *own app* analytics and NOT shared for tracking/advertising: **May not require ATT**
- If AdMob is used with personalized ads: **ATT required**

### Current Position

The app uses:
- `lib/services/analytics_service.dart` (Firebase Analytics)
- `lib/services/ad_service.dart` (AdMob)

If AdMob is enabled with personalized ads, ATT prompt is **required on iOS**.

### Recommendation

1. If premium model (no ads for paid users, minimal ads for free users): Implement ATT for free users who see personalized ads
2. If contextual-only ads (no tracking): Document why ATT is not needed
3. If no ads: No ATT needed (analytics only, own app)

---

## 5. In-App Purchase Compliance

### Token Economy Classification

| Purchase | Type | Replenishes? | Restore? |
|---|---|---|---|
| Token pack (N scans) | Consumable | Yes (buy again) | No (consumed) |
| Premium subscription | Auto-renewable | N/A | Yes (restore) |
| Premium lifetime | Non-consumable | N/A | Yes (restore) |
| Cosmetic (theme, badge) | Non-consumable | N/A | Yes (restore) |

### Rules

1. **Consumable tokens**: Must be purchasable via StoreKit / Play Billing
2. **Non-consumable cosmetics**: Must support restore purchases
3. **Subscription management**: Must provide in-app option to manage/cancel subscription
4. **No external payment**: Any digital good (tokens, premium, cosmetics) MUST use Apple/Google IAP. External payment is only for physical goods (none currently)
5. **Free trials**: Must clearly state duration, price after trial, and auto-renewal terms

### Recommended Implementation

```dart
enum IAPProduct {
  tokenPack100,     // consumable - 100 classifications
  tokenPack500,     // consumable - 500 classifications
  premiumMonthly,   // auto-renewable
  premiumAnnual,    // auto-renewable
  themeDarkMode,    // non-consumable
  badgeEarthWeek,   // non-consumable
}
```

---

## 6. AI-Generated Content Moderation

### Store Requirements

Both stores now require proactive moderation for AI-generated or AI-assisted content:

1. **Content filters**: Must filter hate speech, self-harm, dangerous instructions, explicit content
2. **User reporting**: In-app mechanism to report inappropriate content
3. **Demonstration**: During store review, must show moderation system working

### Current Status

- `lib/services/moderation_service.dart` exists (alpha)
- No user reporting UI for AI-generated content
- No demonstrated moderation pipeline

### Pre-Launch Requirements

1. Complete `ModerationService` with:
   - Pre-display content filtering (regex + LLM-based for education content)
   - Post-display reporting flow
2. Build demo flow for store reviewers showing:
   - A harmless prompt → allowed content
   - A harmful prompt → blocked content with explanation
   - User report flow for problematic content
3. Document moderation policy in app (visible in settings)

---

## 7. GDPR / DPDP Compliance (Indian Market)

### GDPR Requirements (EU Users)

| Requirement | Status | Action needed |
|---|---|---|
| Lawful basis for processing | Consent + Legitimate interest | Consent dialog for non-essential processing |
| Data Processing Agreement (DPA) with providers | OpenAI, Google | Verify current DPAs cover classification use case |
| Right to access | Export feature needed | Build export my data flow |
| Right to erasure | Delete account flow exists | Verify cascade deletes all related data |
| Data portability | Not implemented | Build export in machine-readable format (JSON) |
| Consent records | Partial | Versioned consent consent ledger needed |
| Privacy by design | On-device processing roadmap | Document in privacy policy |

### DPDP Requirements (Indian Users)

| Requirement | Status | Action needed |
|---|---|---|
| Notice (Sections 5–6) | Privacy policy exists | Verify covers all processing purposes |
| Consent (Section 7) | Partial consent dialogs | Unified consent flow needed |
| Data fiduciary registration | Not registered | Check if registration is required based on volume |
| Data Protection Officer | Not appointed | Appoint DPO or designate contact |
| Data localisation | Firebase is US-hosted | Evaluate if processing critical personal data |
| Children's data (Section 9) | Not assessed | If classroom/school mode pursued, verifiable parental consent needed |

---

## 8. Kid / Classroom Policy Implications

### If pursuing classroom/school B2B (entry #29)

1. **COPPA (US)**: Requires verifiable parental consent for users under 13
2. **GDPR-K (EU)**: Age of digital consent varies (13–16 by country)
3. **DPDP (India)**: Age of consent = 18; requires verifiable parental consent
4. **Play Store Families Policy**: Must use Google-certified ad SDKs only; no persistent identifiers for advertising
5. **App Store Kids Category**: No ads, limited analytics, specific age-rating rules

### Pre-Kid-Mode Requirements

- Separate kid-safe app configuration
- No ads in kid mode
- No public community in kid mode
- Guardian dashboard for managing child's data and activity
- Age-gating at account creation

---

## 9. Pre-Launch Compliance Checklist

### Required Before App Store / Play Store Submission

- [ ] Privacy policy finalized (covers all data types, providers, third parties)
- [ ] Terms of service finalized (covers AI usage, user-generated content, liability)
- [ ] App Store Privacy Nutrition Labels filled accurately
- [ ] Play Store Data Safety form filled accurately
- [ ] ATT prompt implemented (if ads / tracking data used)
- [ ] IAP products configured in App Store Connect + Play Console
- [ ] IAP restore purchases tested
- [ ] Moderation system demonstrated for harmful content filtering
- [ ] User reporting flow for AI-generated / UGC content
- [ ] Data deletion flow tested end-to-end
- [ ] Data export flow tested
- [ ] Consent dialogs for all non-essential processing
- [ ] Crash-free session rate >99.5% (Crashlytics)
- [ ] App size within store limits (<500MB including assets)

### Recommended Within 30 Days of Launch

- [ ] GDPR/DPDP Data Protection Officer designated
- [ ] Data Processing Agreements updated with all providers
- [ ] Consent ledger (versioned, per-user) implemented
- [ ] Automated privacy compliance dashboard
- [ ] Penetration test / security audit (OWASP Top 10)

---

## 10. Open Questions

1. **Should we launch without ads initially** to avoid ATT complexity? (Reduces compliance surface, improves UX, but loses ad revenue.)
2. **Should classroom/school mode be a separate app** with its own store listing and compliance posture?
3. **On-device privacy positioning**: Can "your images never leave your device" be a marketing differentiator for on-device Layer 0+1?
4. **App Store Review risk**: AI-generated educational content — will Apple/Google require demonstration of moderation system during review?

---

## 11. Related Docs

- `docs/exploration/CONSENT_ARCHITECTURE.md` — consent ledger design
- `docs/exploration/PRIVACY_PHOTO_PII.md` — photo privacy pipeline
- `docs/exploration/DATA_RETENTION_AND_PII_STRATEGY.md` — data retention policies
- `docs/exploration/ACCOUNT_IDENTITY_LIFECYCLE.md` — account deletion cascade
- `docs/launch/CLOSED_BETA_SMOKE_CHECKLIST.md` — beta launch checklist
- `docs/launch/LAUNCH_BLOCKERS.md` — known blockers
