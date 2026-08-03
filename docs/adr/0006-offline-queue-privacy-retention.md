# ADR-0006: Offline Queue Privacy and Retention Contract

**Status:** Accepted  
**Date:** 2026-08-02  
**Deciders:** Engineering, Privacy, Security  
**Risk Class:** HIGH — stores user-provided personal imagery

## Context

Before this decision, the offline classification queue stored raw user-provided image bytes (potentially containing faces, personal items, location metadata) in Hive local storage with no retention limit, no consent binding, and no expiry mechanism. The dead-letter queue duplicated these raw bytes. A single `ProductionSafetyException` cleared the entire queue indiscriminately.

This violates the principle of data minimisation and creates unnecessary privacy exposure for a feature that may never complete.

## Decision

### 1. Maximum Queue Retention

- **Active queue:** 24 hours maximum. Items older than 24 hours are auto-expired and deleted.
- **Dead-letter queue:** 72 hours maximum. Items older than 72 hours are auto-expired and deleted.
- Items are NOT retained beyond these limits regardless of retry state.

### 2. Raw Image Retention

- **Newly queued and migrated items do NOT store raw image bytes in Hive
  metadata boxes.** Legacy records may retain bytes until startup migration or
  age-based expiry handles them.
- Images are written to temporary files under the app's OS sandbox.
- Hive stores only: temp-file reference, SHA-256 content hash, byte length, and queue metadata.
- On queue completion or expiry, the temp file is deleted.
- On dead-letter expiry, the temp file is deleted.

### 3. Storage Protection

- Queue images live in temporary files under the app's OS sandbox. The shipped
  strategy is platform-protected temp-file handling with Hive metadata-only
  persistence.
- Files are deleted on queue completion, expiry, logout, and orphan cleanup.

### 4. Logout / Account-Switch Behaviour

- On logout: delete all active queue items and their temp files.
- On account switch: delete all active queue items and their temp files.
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

- On service init, scan the OS-sandbox-protected temp directory for files older than 72 hours.
- Delete orphaned files that have no corresponding Hive metadata entry.
- Log the count of cleaned orphan files for diagnostics.

### 9. Failed Migration Degrades to Expiry (not Immortality)

- Legacy raw-bytes records carry no `expiresAt` (added after they were written).
- If the one-time migration to file references fails (e.g. temp-dir write error),
  the item stays in legacy raw-bytes format. It MUST NOT linger indefinitely.
- `_expireOldItems` therefore also expires legacy-format items by age:
  active queue compares `queuedAt` to the 24h limit, dead-letter compares
  `failedAt` to the 72h limit — even when `expiresAt` is null.
- Hard deletion is chosen over moving to dead-letter because a dead-letter move
  would re-store the raw bytes in Hive, re-creating the exact exposure this
  ADR exists to eliminate.

### 10. Backward-Compatibility Schema Generations

- **Gen 1 (pre-migration, shipped):** `Uint8List imageBytes` at Hive field
  index 1 — the raw-bytes exposure this ADR exists to eliminate.
- **Gen 2 (intermediate, never released):** commit `b33b0616` (2026-08-02)
  briefly wrote `String imageRefPath` at field 1, `imageRefHash` at 12 and
  `imageRefByteLength` at 13. It was corrected the same day by the
  backward-compat fix below **before any release, tag, or store build**
  contained it. Records written under Gen 2 would be unreadable by Gen 3
  (field-1 type flip String→Uint8List, field 12/13 remapped); no such records
  exist because the schema never shipped.
- **Gen 3 (current):** restores `Uint8List? imageBytes` at field 1 so
  pre-migration (Gen 1) records read correctly, and moves file-reference
  fields to higher indices (`imageRefPath` 9, `imageRefHash` 10,
  `imageRefByteLength` 11 for dead-letter; 7/8/9 for active queue), all
  nullable. `isLegacyFormat` keys on `imageBytes` alone so partially-migrated
  items (bytes still set after a failed file save) are picked up by
  migration/age-expiry rather than evading both.
- Migration assigns `expiresAt` to legacy records (24h active / 72h
  dead-letter) so unmigrated items honour the retention contract.

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
- Slight increase in storage complexity (sandboxed temp-file indirection)

### Risks
- If the app crashes between writing the temp file and updating Hive metadata,
  orphaned files may accumulate — mitigated by a cleanup sweep on init.

## Implementation

- **Commit 1:** ADR (this document)
- **Commit 2:** Storage migration — move image bytes to sandboxed temp-file references
- **Commit 3:** Failure classification — typed failures, no error string inspection
- **Commit 4:** Safe configuration failure — blocked_configuration state, don't clear queue
- **Commit 5:** Deletion and user controls — auto-expiry, logout purge, redacted errors
