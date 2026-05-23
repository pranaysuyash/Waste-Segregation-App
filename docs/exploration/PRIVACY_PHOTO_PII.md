# Privacy / Photo PII

**Date**: 2026-05-23
**Status**: Exploration — gap analysis and remediation plan
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) entry 32
**Decision this unblocks**: Data deletion compliance, user trust, GDPR/DPDP readiness
**Kill criteria**: If the app never launches in a jurisdiction with privacy enforcement, these gaps have no legal consequence — but they remain a trust risk.

---

## 1. Current Privacy Posture

### What works

| Control | Implementation | Strength |
|---------|---------------|----------|
| Consent management | `UserConsentService` with granular categories, versioning, audit trail | Strong |
| Training data consent | Explicit `training-data-v1` consent, consent-gated pipeline | Strong |
| User ID hashing | Salted HMAC for training candidates | Moderate |
| User data export | JSON export with metadata | Adequate |
| Production safety | `ProductionSafetyConfig` blocks client-side AI in release | Strong |

### What's broken

| Gap | Severity | Detail |
|-----|----------|--------|
| On-device images never deleted | Critical | `EnhancedImageService.saveFilePermanently()` stores forever; "Clear Data" doesn't clear images |
| Firebase Storage never deleted | Critical | No code calls `storage.ref().delete()` — `batch_images/`, `contribution_photos/` accumulate indefinitely |
| Device paths leaked to Firestore | High | `WasteClassification.toJson()` includes local filesystem path in `imageUrl` |
| No EXIF stripping for regular images | High | Training candidates strip EXIF; regular classifications do not |
| No face detection | High | Waste photos can capture faces, license plates, prescriptions |
| Analytics events no TTL | Medium | `analytics_events` collection grows indefinitely |
| Hardcoded admin email | Medium | Single admin email in source code |
| No AI transmission consent | High | No specific consent for sending images to OpenAI/Gemini |

---

## 2. Remediation Plan

### Critical (P0): Right to Erasure

1. **Image deletion on account delete**:
   - `EnhancedImageService.deleteAllImages()` — delete all files in `<appDocs>/images/`
   - `CloudStorageService.deleteAllUserStorage()` — delete `batch_images/{userId}/`, `contribution_photos/{userId}/`
   - Wire both into the account deletion flow

2. **Firebase Storage cleanup**:
   - Add `deleteUserStorage(userId)` to cloud functions
   - Delete all objects under `batch_images/{userId}/` and `contribution_photos/{userId}/`
   - Called from account deletion callable function

3. **Firestore cleanup**:
   - Verify `FirebaseCleanupService.performCleanup()` deletes all user collections
   - Add missing collections: `rate_limits/{userId}`, `analytics_events` by user

### High (P1): PII Protection

4. **EXIF stripping for all images**:
   - Strip EXIF data before saving any image (not just training candidates)
   - Use `dart:io` EXIF library or platform channel
   - Remove GPS coordinates, device info, timestamps

5. **Device path sanitization**:
   - `WasteClassification.toJson()` should NOT include `imageUrl` when syncing to Firestore
   - Store a storage-relative path or hash instead

6. **Face detection + blur**:
   - On-device face detection (ML Kit or Apple Vision)
   - Automatic blur for detected faces before any storage/transmission
   - User notification: "Face detected and blurred for privacy"

### Medium (P2): Consent Enhancement

7. **AI transmission consent**:
   - Add consent category: `aiImageTransmission`
   - Explain: "Your photos are sent to AI providers for classification"
   - Allow per-session or blanket consent
   - Show privacy layer indicator on result screen

8. **Coarse location**:
   - Two-fidelity model: `coords_public` (city-level) vs `coords_exact` (precise, ACL-gated)
   - Only coarse location stored in Firestore public collections
   - Precise location stored in user-private collections only

---

## 3. Compliance Status

| Regulation | Status | Key Gap |
|------------|--------|---------|
| GDPR (EU) | Non-compliant | Right to erasure not implemented, no DPO, no data processing agreement |
| CCPA (US) | Partially compliant | Consent exists, deletion incomplete |
| DPDP (India) | Non-compliant | No localization, no registration, incomplete deletion |

---

## 4. Related

- [Data Retention & PII Strategy](DATA_RETENTION_AND_PII_STRATEGY.md) — retention policies
- [Local-First Privacy Architecture](LOCAL_FIRST_PRIVACY_ARCHITECTURE.md) — privacy by layer
- [Consent Architecture](../EXPLORATION_TOPICS.md#a19-consent-architecture-) — consent model
- `lib/services/user_consent_service.dart` — consent implementation
- `lib/services/firebase_cleanup_service.dart` — cleanup implementation
