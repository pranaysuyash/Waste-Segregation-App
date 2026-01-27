# 🗄️ Admin/ML Data Retention & User Data Flow

**Last Updated:** June 5, 2025

---

## 1. Overview
This document describes how all user and guest classification data is handled for admin/ML purposes, the privacy and compliance implications, and the user experience for data deletion and messaging. It reflects the latest product direction: **all classifications (including guest) are always synced to the admin/ML dataset, with no linkage to signed-in user data.**

---

## 2. Data Retention & Sync Logic

### 2.1 What is retained?
- **Every classification** (guest or signed-in) is anonymized and stored in the `admin_classifications` Firestore collection.
- No personal identifiers are stored; only a one-way hash of the user ID (or a guest marker) is included.
- This data is used for:
  - ML model training
  - Analytics and business intelligence
  - Data recovery (for signed-in users only)

### 2.2 Guest User Data
- **Guest classifications** are always synced to the admin/ML dataset, even if the user never signs in.
- These entries are marked as guest and are never linked to any future signed-in user account.
- If a guest later signs in, their new classifications are stored as a separate user in the admin dataset.
- **No migration or merging** of guest and signed-in user data in the admin/ML dataset.

### 2.3 Signed-in User Data
- Signed-in user classifications are anonymized and stored in the admin/ML dataset with a hashed user ID.
- Data recovery is possible for signed-in users via admin support (see `ADMIN_DATA_RECOVERY_SERVICE.md`).

---

## 3. User Messaging & UX

### 3.1 Data Deletion Flow
- When a user (guest or signed-in) clears data:
  - All local and cloud data for that user is deleted.
  - **Admin/ML dataset is NOT affected**; anonymized data is retained for research and improvement.
  - Show a message: "Your personal data has been deleted. Anonymized classification data may be retained for research and AI improvement."

### 3.2 Guest User Messaging
- Guest users are informed that their classifications are always contributed anonymously to the admin/ML dataset.
- Data is not recoverable for guests.

### 3.3 Privacy Policy (TODO)
- Update privacy policy and onboarding to state:
  - "All classification data, including from guest users, may be anonymized and retained for research, analytics, and AI model improvement. No personal identifiers are stored."

---

## 4. Compliance & Privacy

- All admin/ML data is fully anonymized (SHA-256 hash for signed-in users, guest marker for guests).
- No personal identifiers, emails, or device IDs are stored in the admin dataset.
- Data is used for ML, analytics, and recovery (signed-in only).
- **TODO:**
  - [ ] Update privacy policy and in-app messaging.
  - [ ] Add onboarding explanation for all users.
  - [ ] Review GDPR/CCPA compliance for anonymized data retention.

---

## 5. Technical Implementation Notes

- All classifications (guest and signed-in) are pushed to `admin_classifications` on every save.
- For guests, use a consistent guest marker (e.g., `guest_user` or `guest_{deviceId}` if needed for deduplication, but never link to a future signed-in user).
- No opt-in or opt-out for guest ML data contribution; it is always included.
- Data deletion for users only affects their personal/local/cloud data, not the admin/ML dataset.

---

## 6. References
- `docs/admin/ADMIN_DATA_RECOVERY_SERVICE.md`
- `docs/technical/data_storage/DUAL_STORAGE_ARCHITECTURE.md`
- `docs/fixes/user_data_isolation_fix.md`
- `docs/planning/business/strategy/data_privacy_and_compliance.md`
- `assets/docs/privacy_policy.md`

---

## 7. Open TODOs
- [ ] Update privacy policy and onboarding as above
- [ ] Implement new user messaging in clear data and onboarding flows
- [ ] Ensure all guest classifications are always synced to admin/ML dataset
- [ ] Document and test compliance with all relevant privacy regulations

---

**This document is the canonical reference for admin/ML data retention and user data flow as of June 2025.** 