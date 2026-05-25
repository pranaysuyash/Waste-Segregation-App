# Dependency Supply Chain Security

**Date**: 2026-05-25
**Status**: Seed — no dependency audit or supply chain policy exists
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) entry 174
**Decision this unblocks**: Whether to invest in automated dependency auditing, lockfile governance, and vulnerability scanning in CI
**Kill criteria**: If automated scans find zero actionable vulnerabilities across all ecosystems for 3 consecutive quarters, further investment is low priority

---

## 1. Current State

The project uses dependencies across multiple ecosystems:

| Ecosystem | Manifest | Lockfile | Package Count (approx) |
|-----------|----------|----------|----------------------|
| Dart/Flutter | `pubspec.yaml` | `pubspec.lock` | 200+ |
| Node.js (Functions) | `functions/package.json` | `functions/package-lock.lock` | ~30 |
| Node.js (Firestore tests) | `firestore-rules-test/package.json` | `firestore-rules-test/package-lock.lock` | ~10 |
| Node.js (Storybook) | `.storybook/package.json` | Unknown | ~10 |
| CocoaPods | `ios/Podfile` | `ios/Podfile.lock` | ~30 |
| Gradle (Android) | `android/build.gradle` | Unknown | ~20 |

**Known risks**:
- No automated vulnerability scanning (Dart `dart pub audit` or Node `npm audit`)
- No lockfile freshness enforcement in CI
- No license compliance audit
- Transitive dependencies are unaudited
- Some packages in `pubspec.lock` may be stale or unmaintained

---

## 2. Areas to Address

### 2.1 Vulnerability Scanning

| Ecosystem | Tool | Integration |
|-----------|------|------------|
| Dart/Flutter | `dart pub audit` | CI gate — fail on critical/high |
| Node.js | `npm audit` | CI gate — fail on critical/high |
| CocoaPods | `pod lib lint` + CocoaPods trunk | Manual scan (no CI integration) |
| Gradle | OWASP Dependency Check | Optional — Gradle plugin available |

**Recommended CI gates**:
- `dart pub audit` in every PR — fail on `CRITICAL` or `HIGH` severity
- `npm audit --audit-level=high` in every Functions PR
- Weekly full scan across all ecosystems with report to Slack/email

### 2.2 Lockfile Governance

| Policy | Description |
|--------|-------------|
| **Lockfile must be committed** | All lockfiles checked into git, never `.gitignore`d |
| **Lockfile must be fresh** | CI checks `pubspec.lock` matches `pubspec.yaml` |
| **No manual lockfile edits** | Lockfile changes only through `pub get` / `npm install` |
| **PR lockfile diff review** | Lockfile changes flagged in PR review checklist |

### 2.3 License Compliance

| License | Action |
|---------|--------|
| MIT, Apache 2.0, BSD | Allowed |
| GPL, LGPL | Requires legal review (Flutter app distribution) |
| AGPL | Prohibited (server-side Functions could be affected) |
| Custom/Unknown | Blocked until reviewed |

**Tool**: `flutter pub license` / `npx license-checker` to generate SBOM (Software Bill of Materials) per release.

### 2.4 Dependency Freshness

| Check | Tool | Frequency |
|-------|------|-----------|
| Outdated Flutter deps | `dart pub outdated` | Weekly |
| Outdated Node deps | `npm outdated` | Weekly |
| Abandoned packages | Manual review + `dart pub deps` | Monthly |
| Major version drift | Manual review of changelogs | Per-release cycle |

---

## 3. Key Questions

- **Which dependencies are on the critical path?** A vulnerability in `http`, `firebase_core`, or `flutter` itself has different severity than a dev dependency like `build_runner`.
- **What's the remediation SLA?** Critical vulns patched within 24h, high within 72h, medium within 1 week?
- **Should we pin exact versions or allow semver ranges?** Exact pins reduce supply chain risk but increase maintenance burden.
- **How do we handle transitive vulnerabilities we can't directly fix?** Force-override in dependency_overrides or wait for upstream fix?
- **What's the policy for new dependencies?** Any new package requires: (1) approval, (2) license check, (3) download count >1k/week, (4) recent update (<1 year)?
- **Should we vendor critical dependencies?** Copy key packages into the repo to eliminate supply chain risk for security-critical code?

---

## 4. Threat Model

| Threat | Impact | Likelihood | Mitigation |
|--------|--------|------------|------------|
| Typosquatting package | Code execution in CI | Low | `dart pub get` only from pub.dev, signature verification |
| Compromised maintainer account | Malicious update pushed | Low-Medium | Pin versions, review changelog on update |
| Transitive dependency hijack | Unreviewed code in production | Medium | `dart pub audit`, SBOM generation |
| Build-time dependency injection | Malicious code via compromised build tool | Low | CI in isolated environment, checksum verification |
| Deprecated package with known vuln | Unpatched vulnerability | Medium | `dart pub outdated` scan, automated update PRs (Dependabot/Renovate) |

---

## 5. Recommendations

### Phase 1: Baseline Scanning (P2)
- Add `dart pub audit` to CI (fail on critical/high)
- Add `npm audit` to Functions CI
- Run license check on current dependencies, document findings

### Phase 2: Governance (P2)
- Establish dependency add/update policy
- Set up Dependabot (or Renovate) for automated update PRs
- Add lockfile freshness check to CI

### Phase 3: Deep Supply Chain (P3)
- Generate SBOM per release
- Implement transitive dependency review process
- Evaluate vendor decision for critical-path packages
- Set up weekly dependency health report

---

## 6. Related

- [CI/CD Pipeline Hardening](CI_CD_PIPELINE_HARDENING.md) — CI gates for dependency scanning
- [Secrets and Environment Governance](../EXPLORATION_TOPICS.md#93-secrets-and-environment-governance) — API key rotation, token hygiene
- [Lint / Static Analysis / Type Safety](LINT_STATIC_ANALYSIS_TYPE_SAFETY.md) — code quality foundations
- `pubspec.yaml`, `pubspec.lock` — dependency manifests
- `functions/package.json` — Node.js dependency manifest
