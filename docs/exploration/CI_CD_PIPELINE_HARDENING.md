# CI/CD Pipeline Hardening

**Date**: 2026-05-25
**Status**: Seed — no dedicated CI/CD doc exists; build pipelines are ad-hoc
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) entry 173
**Decision this unblocks**: Whether to invest in build time reduction, test flakiness management, and deployment automation
**Kill criteria**: If build times are <3 min and test flakiness <0.5% across all platforms, pipeline hardening is low ROI

---

## 1. Current State

The project uses:

| Platform | CI Provider | Config |
|----------|------------|--------|
| Firebase Functions | GitHub Actions (likely) | Not explicitly audited |
| Flutter (Android/iOS) | Unknown | `patrol.toml`, `integration_test_disabled/` |
| Web hosting | Firebase Hosting | `web_hosting/` directory |
| Linting | `analysis_options.yaml`, `.markdownlint.json` | Pre-commit hook |

Several scripts exist in `scripts/`:
- `run_all_tests.sh` — test runner
- `run_e2e_tests.sh` — E2E test runner
- `ai_test_validator.sh` — AI-specific test validation
- `setup_testing.sh` — test environment setup
- `setup-git-hooks.sh` — git hook installer
- `ai_dev_runner.sh` — dev workflow automation

**Known gaps**:
- No explicit CI/CD pipeline configuration visible at the project root
- Integration tests disabled (`integration_test_disabled/`) — not running in CI
- No build time tracking or alerting
- No automated deployment pipeline for Flutter builds to stores

---

## 2. Areas to Address

### 2.1 Build Time Optimization

| Area | Current State | Target |
|------|-------------|--------|
| Flutter build (Android) | Full rebuild on every CI run | Cache Gradle/dependencies, incremental builds |
| Flutter build (iOS) | Full rebuild, no cache | Cache CocoaPods, derived data |
| Firebase Functions deploy | Full deploy | Incremental deploy (affected functions only) |
| CI cold start | Dependency install every run | Cache `pub get`, `npm ci`, CocoaPods |

**Approaches**:
- GitHub Actions `actions/cache` for `.pub-cache`, `.gradle`, `Pods/`, `node_modules/`
- Flutter `--local-engine` for CI (if self-hosted runner)
- Gradle build caching with remote cache (gradle enterprise or simpler)
- Separate lint/test/build jobs so lint failures fail fast before build

### 2.2 Test Flakiness Management

| Test Type | Current Coverage | Flakiness Risk |
|-----------|-----------------|----------------|
| Unit tests | Present (`test/`) | Low |
| Widget tests | Present | Medium (timing-dependent) |
| Integration tests | Disabled (`integration_test_disabled/`) | High (device/emulator variability) |
| Firestore rules tests | Present (`firestore-rules-test/`) | Low |
| Storage rules tests | Present (`storage-rules-test.spec.js`) | Medium |
| Functions unit tests | Present (`functions/test/`) | Low |

**Anti-flakiness strategies**:
- Retry wrapper for integration tests (up to 3 attempts)
- Golden file comparison with tolerance thresholds
- Timeout hardening — increase default timeouts for CI environments
- Flaky test quarantine — auto-tag tests that fail >2/N runs, notify, don't block CI
- Test splitting — run unit/widget/integration in parallel jobs

### 2.3 Deployment Automation

| Artifact | Current Deploy Method | Target |
|----------|----------------------|--------|
| Firebase Functions | Manual `firebase deploy --only functions` | Automated on merge to main |
| Firestore Rules | Manual deploy | Automated with CI |
| Firebase Hosting | Manual deploy | Automated preview deploys on PR |
| iOS App Store | Manual via Xcode | Fastlane + CI (TestFlight auto-deploy) |
| Google Play | Manual via Play Console | Fastlane + CI (internal track auto-deploy) |

**Approaches**:
- GitHub Actions workflow: lint → test → build → deploy (gated per environment)
- Preview deployments for Firebase Hosting on every PR
- Fastlane setup for iOS/Android store deployments
- Deploy to staging env on merge to `develop`, production on tag/release

### 2.4 CI/CD Observability

- Build duration tracking per job (alert when >2× baseline)
- Test pass/fail rate trending
- Deployment success/failure rate
- Cost tracking for CI minutes (GitHub Actions macOS runners are expensive)

---

## 3. Key Questions

- **CI provider**: GitHub Actions (current) vs dedicated CI (Buildkite, Cirrus CI) for Flutter?
- **macOS runner cost**: iOS builds require macOS runners at 10× the cost of Linux. Self-hosted Mac mini or GitHub's hosted?
- **Test device matrix**: How many Android API levels + iOS versions to test against on each PR?
- **Deploy frequency**: Deploy on every merge to main, or batch into daily/weekly releases?
- **Code signing**: How to manage iOS certificates + provisioning profiles in CI without manual intervention? (Fastlane match?)
- **Secrets management**: API keys, Firebase service accounts, store credentials — stored in GitHub Secrets or external vault?

---

## 4. Dependencies

| Dependency | Status | Notes |
|-----------|--------|-------|
| GitHub Actions workflow | Unknown | Check `.github/` directory for existing configs |
| Fastlane | Not configured | Must check if Fastfile exists |
| Firebase CLI | Available | Used in scripts |
| Flutter test runner | Available | `flutter test`, `flutter drive` |
| Patrol for E2E | `patrol.toml` exists | Integration tests disabled |

---

## 5. Recommendations

### Phase 1: Baseline + Fast Feedback (P1)
- Add GitHub Actions workflow for lint + unit test on every PR
- Enable `firebase emulators:exec` for functions + rules tests in CI
- Add build caching for Flutter dependencies

### Phase 2: Integration + Deployment (P2)
- Re-enable integration tests (move from `integration_test_disabled/`)
- Add Firebase Hosting preview deploys on PR
- Set up Fastlane for iOS TestFlight + Android internal track

### Phase 3: Observation + Hardening (P2)
- Add build duration tracking + alerting
- Implement flaky test quarantine
- Set up deployment success/failure dashboards

---

## 6. Related

- [Lint / Static Analysis / Type Safety](LINT_STATIC_ANALYSIS_TYPE_SAFETY.md) — code quality foundation for CI gates
- [Firebase Hosting Basics](../AGENTS.md) — not a doc, but relevant to web deploys
- [Secrets and Environment Governance](../EXPLORATION_TOPICS.md#93-secrets-and-environment-governance) — CI secrets management
- `scripts/run_all_tests.sh` — existing test runner
- `.github/` directory — check for existing CI configs
