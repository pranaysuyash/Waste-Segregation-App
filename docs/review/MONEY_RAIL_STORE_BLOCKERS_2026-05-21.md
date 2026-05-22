# P0/P1 Money-Rail Blockers — Store & Platform Setup Guide

**Date**: 2026-05-21
**Context**: These items require merchant accounts, store configuration, or Firebase Console access — not IDE code changes. Code scaffolding is already in place for all three.

---

## 1. Production AdMob IDs (P0)

### What's already done
- `AdService` (`lib/services/ad_service.dart`) has full ad display logic
- Test IDs used in debug/profile builds
- Release IDs accepted via `--dart-define` environment variables
- Ad placement logic, frequency capping, and premium suppression all live
- GDPR/UMP consent infrastructure is scaffolded (TODO at line 110)

### What needs a human with an AdMob account

```
1. Go to https://admob.google.com
2. Create or log in to AdMob account
3. Register app (Android + iOS) in AdMob
4. Generate ad unit IDs:
   - Banner Android + iOS
   - Interstitial Android + iOS
5. Install the AdMob app on physical test devices
6. Verify test ads render before going live
```

### Build command (after IDs are generated)

```bash
flutter build apk --release \
  --dart-define=ADMOB_ANDROID_BANNER_AD_UNIT_ID=ca-app-pub-XXXXXXXXX/YYYYY \
  --dart-define=ADMOB_IOS_BANNER_AD_UNIT_ID=ca-app-pub-XXXXXXXXX/YYYYY \
  --dart-define=ADMOB_ANDROID_INTERSTITIAL_AD_UNIT_ID=ca-app-pub-XXXXXXXXX/YYYYY \
  --dart-define=ADMOB_IOS_INTERSTITIAL_AD_UNIT_ID=ca-app-pub-XXXXXXXXX/YYYYY
```

### Platform configs needed

| Platform | File | Change |
|----------|------|--------|
| Android | `android/app/src/main/AndroidManifest.xml` | Add `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="ca-app-pub-XXXXXXXXX~XXXXXXXXXX"/>` |
| iOS | `ios/Runner/Info.plist` | Add `<key>GADApplicationIdentifier</key><string>ca-app-pub-XXXXXXXXX~XXXXXXXXXX</string>` |

### Gradle issue (known)
```gradle
// android/app/build.gradle
implementation("com.google.android.gms:play-services-ads:23.3.0") // ✅ explicit (workaround for issue #144)
```

---

## 2. In-App Purchase / Subscription (P0)

### What's already done
- `PurchaseService` (`lib/services/purchase_service.dart`) — real IAP gateway abstraction
- `WebCheckoutService` (`lib/services/web_checkout_service.dart`) — web payment alternative
- `PremiumService` (`lib/services/premium_service.dart`) — entitlement model with canonical `hasActivePremiumPlan()`, legacy bridge, Hive persistence
- Firestore schema includes `tier: "free" | "premium" | "enterprise"` field
- Server-side `spendUserTokens` already reads `tier` from Firestore to apply discounts
- Functions create/dodo payment webhook exists

### What's blocked by store accounts

```
1. APP STORE CONNECT (iOS):
   a. Enroll in Apple Developer Program ($99/yr)
   b. Create App ID and bundle identifier
   c. Configure In-App Purchases in App Store Connect
   d. Create subscription product (waste_premium_monthly)
   e. Upload screenshots, set pricing tiers
   f. Add "Manage" family test users in Sandbox

2. GOOGLE PLAY CONSOLE (Android):
   a. Enroll in Google Play Developer account ($25 one-time)
   b. Create app listing
   c. Set up Managed Products / Subscriptions
   d. Create same subscription SKU
   e. Add test accounts (license testers)

3. DODOPAYMENTS (web/alternative):
   a. Configure webhook endpoint in dodo dashboard
   b. Set STRIPE_SECRET and DODOPAYMENTS_SECRET env vars
   c. Functions webhook already created at createCheckoutSession + dodopaymentsWebhook
```

### Code path for binding (when store products exist)

```dart
// lib/screens/premium_features_screen.dart (~line 303)
// Currently: purchase section exists but store products aren't loaded
// Fix: PurchaseService loads products from store on init
//      → PremiumService.setPremiumPlanEntitlement(true) on successful purchase
//      → Firestore tier updated to 'premium'
```

### Verification checklist
- [ ] Test purchase completes without error on Sandbox/Test card
- [ ] Premium entitlement persists across app restart (Hive)
- [ ] Premium entitlement syncs to Firestore
- [ ] Ad suppression activates immediately after purchase
- [ ] Token discount applies (50% off classify cost)
- [ ] Restore purchases works across devices
- [ ] Subscription renews and lapses correctly

---

## 3. App Check Enforcement (P1 → P0 before public launch)

### What's already done
- Client-side App Check activation (all platforms) in `lib/main.dart:_initializeAppCheck()`
- Web: `ReCaptchaV3Provider` (needs site key)
- iOS debug: `AppleProvider.debug`
- iOS release: `AppleProvider.appAttest`
- Android debug: `AndroidProvider.debug`
- Server-side: `validateAppCheckProductionGuardrails()` + `enforceHttpAppCheck()` + `enforceCallableAppCheck()` already in functions

### What needs Firebase Console access

```
1. Go to Firebase Console > your-project > App Check
2. For each platform (iOS, Android, Web):
   a. Register the App Check key / token provider
   b. Toggle "Enforcement" ON
3. For Android release: update the code to use Play Integrity:
```

### Code change needed for Android release

```dart
// lib/main.dart — currently only sets appleProvider for production (line 377-382)
// Missing: androidProvider for release builds
// Fix: add AndroidProvider.playIntegrity

await FirebaseAppCheck.instance
    .activate(
      appleProvider: AppleProvider.appAttest,
      androidProvider: AndroidProvider.playIntegrity,  // ← ADD THIS
    )
    .timeout(const Duration(seconds: 10));
```

### Env vars needed for Functions

| Variable | Purpose | Required |
|----------|---------|----------|
| `REQUIRE_APPCHECK_HTTP` | Enforce App Check on HTTP functions | Yes (true) |
| `REQUIRE_APPCHECK_CALLABLE` | Enforce App Check on callable functions | Yes (true) |
| `ENFORCE_APPCHECK_IN_EMULATOR` | Test App Check in local emulator | Optional (false) |

### Verification

```bash
# Deploy functions after enforcement is on
firebase deploy --only functions

# Verify HTTP endpoint returns 403 without valid App Check token
curl -X POST https://asia-south1-<project>.cloudfunctions.net/generateDisposal \
  -H "Content-Type: application/json" \
  -d '{"material":"test"}'
# Expected: 403 Forbidden (not 200 or 500)
```

---

## Dependency order

```
AdMob setup ──────→ can ship free tier with ads
       │
IAP setup ────────→ can ship premium tier
       │
AppCheck enforce ──→ must be live before public release (prevents API abuse)
```

**Recommended execution order:**
1. App Check — lowest effort, highest security ROI
2. AdMob — generates immediate free-tier revenue
3. IAP — unlocks premium revenue but requires most setup
