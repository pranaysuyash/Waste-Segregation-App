# Force-Update & Version Deprecation Strategy

**Date**: 2026-05-25
**Status**: Seed — no version deprecation or force-update mechanism exists
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) entry 175
**Decision this unblocks**: Whether to implement a force-update system and version deprecation policy
**Kill criteria**: If API surface changes <1/quarter and no breaking backend changes are anticipated, deprecation mechanism is unnecessary overhead

---

## 1. Current State

The app has:
- **No version check on startup** — the app does not verify whether its version is compatible with the current backend
- **No force-update mechanism** — users on old versions can continue using the app indefinitely, even if backend APIs change
- **No graceful degradation path** — if a backend function signature changes, old clients receive parse errors or unexpected behavior
- **No deprecation policy** — no defined timeline for when old versions stop being supported

**Code anchors**:
- `pubspec.yaml` — `version: x.y.z` (app version)
- `functions/package.json` — Node.js version for Firebase Functions
- Firebase Remote Config (`lib/services/remote_config_service.dart`) — could serve as the delivery mechanism for force-update flags

---

## 2. The Problem

Without a version deprecation strategy, the following scenarios are possible:

| Scenario | Impact |
|----------|--------|
| Backend function `classifyImage` changes its response schema | Old app crashes with JSON parse error |
| Firebase security rules update reference a field old clients don't send | Write operations silently fail |
| Cloud Firestore document schema changes | Old app reads fields it expects but no longer exist |
| Provider API key rotated | Old app has stale key, all classifications fail |
| Security vulnerability in old app version | Users on unpatched versions remain vulnerable |

---

## 3. Key Questions

### Detection
- How does the app know what version it is? (Flutter `package_info_plus` or manual version string?)
- How does the backend know what client version is making the request? (Version header in API calls?)
- What constitutes a breaking change? (Schema change only? UI change? Prompt change?)

### Enforcement
- **Soft block**: Show a banner "Update available" — user can dismiss and continue
- **Hard block**: Show a full-screen "Update required" — user must update to proceed
- **Graceful degradation**: Old API versions supported but limited feature set (e.g., no batch mode, no new local rules)

### Policy
- How long after a new release is the old version deprecated? (30 days? 60 days? 90 days?)
- Are there exempt versions (e.g., users who can't upgrade due to device OS)?
- How do we notify users before a hard block? (In-app banner → push notification → email?)

### Communication
- What does the "Update required" screen say? (Reason, changelog link, store button)
- How do we handle users who defer the update? (Re-prompt frequency, escalation)
- How do we test the force-update flow without breaking production?

---

## 4. Architecture Options

### Option A: Remote Config–Driven Version Gates

**How it works**:
- `minimum_version_code` and `deprecated_version_code` stored in Firebase Remote Config
- On app startup, compare `package_info.versionCode` against these values
- If below `minimum_version_code`: show hard-block screen → app store link
- If below `deprecated_version_code`: show soft-block banner → dismissable

**Pros**: No backend changes needed, instant roll-out via Remote Config
**Cons**: Remote Config is client-side with caching — user could circumvent by going offline
**Mitigation**: Cache the last known Remote Config values; fall back to hard block on cache expiry

### Option B: API Version Header

**How it works**:
- All Firebase Function HTTP endpoints accept an `X-App-Version` header
- Backend checks version against a `supported_versions` allowlist (Firestore doc or env var)
- If version is unsupported, return `426 Upgrade Required` with new version info
- Client handles 426 by showing force-update screen

**Pros**: Enforced server-side, cannot be circumvented
**Cons**: Requires changes to every Firebase Function; Functions on `onCall` don't have HTTP headers

### Option C: Hybrid (Recommended)

Combine both:
- **Primary enforcement**: API version header on all cloud function calls (Option B)
- **Fallback**: Remote Config version check on startup (Option A) for cached/delayed enforcement
- **Graceful**: Old versions continue to work for non-breaking changes (e.g., prompt updates)

---

## 5. API Versioning Strategy

| Approach | Description | Best For |
|----------|-------------|----------|
| **URL versioning** | `/v1/classifyImage`, `/v2/classifyImage` | Simple, explicit, but duplicates code |
| **Header versioning** | `Accept: application/vnd.reloop.v1+json` | Clean, no URL pollution, but harder to debug |
| **Query param versioning** | `?version=1` | Simple, but clutters URLs |
| **Body field versioning** | Include `apiVersion: 1` in request body | Explicit, but only works for POST |

**Recommended**: Header versioning for Firebase Functions using `Content-Type` or a custom header `X-API-Version`. Each function handler reads the header and dispatches to the appropriate versioned handler.

---

## 6. Deprecation Policy Proposal

| Phase | Condition | UX |
|-------|-----------|----|
| **Supported** | Current version ±1 minor | Full functionality |
| **Deprecated** | Version N-2 or older | Soft banner "Update recommended", full functionality |
| **Minimum** | Version N-3 or older | Update required banner (dismissable for 7 days) |
| **Blocked** | Version N-4 or older | Hard-block: must update to use app |

**Timeline**: Each app release resets the clock. A version stays fully supported for ~60 days (±2 minor releases), then enters deprecation.

---

## 7. Recommendations

### Phase 1: Baseline (P1)
- Add `package_info_plus` to read app version
- Store `minimum_version_code` and `deprecated_version_code` in Remote Config
- Implement startup version check with Remote Config values
- Add soft/hard block screens (reuse or extend existing UI patterns)
- Add app store deep links (Google Play / App Store)

### Phase 2: Backend Enforcement (P2)
- Add `X-App-Version` header to all Firebase Function calls from the client
- Implement version check middleware in Firebase Functions
- Return `426 Upgrade Required` response for unsupported versions
- Add `supported_versions` allowlist to Firestore or env config

### Phase 3: Policy + Observability (P2)
- Define deprecation timeline and document in CONTRIBUTING.md
- Add version distribution tracking in analytics (what % on each version)
- Add alerting when old version usage drops below threshold
- Implement grace period for users who can't upgrade

---

## 8. Related

- [A13. Remote Config & Kill Switches](../EXPLORATION_TOPICS.md#a13-remote-config--kill-switches) — Remote Config as the delivery mechanism
- [A15. Account / Identity Lifecycle](../EXPLORATION_TOPICS.md#a15-account--identity-lifecycle) — version affects account-merge and migration logic
- [CI/CD Pipeline Hardening](CI_CD_PIPELINE_HARDENING.md) — deployment pipeline that delivers updates
- `lib/services/remote_config_service.dart` — existing Remote Config service
- `pubspec.yaml` — app version definition point
