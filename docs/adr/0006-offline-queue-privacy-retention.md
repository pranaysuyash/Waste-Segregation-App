# ADR-0006: Offline Queue Privacy and Retention Contract

**Status:** Accepted  
**Date:** 2026-08-02  
**Deciders:** Engineering, Privacy, Security  
**Risk Class:** HIGH — stores user-provided personal imagery

## Context

The offline classification queue stores raw user-provided image bytes (potentially containing faces, personal items, location metadata) in Hive local storage with no retention limit, no consent binding, and no expiry mechanism. The dead-letter queue duplicates these raw bytes. A single `ProductionSafetyException` clears the entire queue indiscriminately.

This violates the principle of data minimisation and creates unnecessary privacy exposure for a feature that may never complete.

## Decision

### 1. Maximum Queue Retention

- **Active queue:** 24 hours maximum. Items older than 24 hours are auto-expired and deleted.
- **Dead-letter queue:** 72 hours maximum. Items older than 72 hours are auto-expired and deleted.
- Items are NOT retained beyond these limits regardless of retry state.

### 2. Raw Image Retention

- **Raw image bytes are NOT stored in Hive metadata boxes.**
- Images are written to encrypted temporary files in the app's sandboxed documents directory.
- Hive stores only: encrypted file reference, content hash, metadata.
- On queue completion or expiry, the encrypted file is deleted.
- On dead-letter expiry, the encrypted file is deleted.

### 3. Encryption / Key Strategy

- Use AES-256-GCM with a per-app key derived from `flutter_secure_storage`.
- Key is stored in the platform keystore (iOS Keychain / Android Keystore).
- Each queue item gets a unique IV; IV is stored alongside the encrypted file reference in Hive.
- Key is destroyed on logout (platform keystore handles this).

### 4. Logout / Account-Switch Behaviour

- On logout: delete all active queue items and their encrypted files.
- On account switch: delete all active queue items and their encrypted files.
- Dead-letter items are deleted on logout (they contain image data).
- Queue processing is paused during account switch.

### 5. Child / Family Handling

- Family accounts share no queue data between members.
- Each member's queue is scoped to their UID.
- Queue items tagged with `userId` are filtered by the current user.

### 6. Training Exclusion

- Images in the offline queue are NEVER used for training data.
- The queue analytics tracker must NOT include raw error strings or image data.
- Consent status is checked before queuing; if consent is withdrawn, the queue is purged.

### 7. ProductionSafetyException Handling

- When `ProductionSafetyException` is thrown, mark the specific item as `blocked_configuration`.
- Do NOT clear unrelated items from the queue.
- Show the user a clear message that client AI is disabled in this build.
- Server/backend route can resume later when the build is corrected.
- Configuration/safety failures do NOT consume retry count.

### 8. Orphaned File Cleanup

- On service init, scan the encrypted temp directory for files older than 72 hours.
- Delete orphaned files that have no corresponding Hive metadata entry.
- Log the count of cleaned orphan files for diagnostics.

### 7. Consent / Purpose Binding

- Each queue item stores: `consentVersion`, `purpose: 'classification'`.
- If consent version changes, items with old versions are expired.
- If consent is withdrawn, all queue items are deleted.

## Consequences

### Positive
- No indefinite raw-image retention
- Privacy-respecting data lifecycle
- Clean logout/account-switch behaviour
- Auditable retention/compliance

### Negative
- Migration cost for existing queue items (one-time)
- Slight increase in storage complexity (encrypted temp files)
- Platform keystore dependency

### Risks
- If the platform keystore is wiped (factory reset), encrypted files become unreadable — acceptable since they're temporary.
- If the app crashes between writing the encrypted file and updating Hive metadata, orphaned files may accumulate — mitigated by a cleanup sweep on init.

## Implementation

- **Commit 1:** ADR (this document)
- **Commit 2:** Storage migration — move image bytes to encrypted file references
- **Commit 3:** Failure classification — typed failures, no error string inspection
- **Commit 4:** Safe configuration failure — blocked_configuration state, don't clear queue
- **Commit 5:** Deletion and user controls — auto-expiry, logout purge, redacted errors
