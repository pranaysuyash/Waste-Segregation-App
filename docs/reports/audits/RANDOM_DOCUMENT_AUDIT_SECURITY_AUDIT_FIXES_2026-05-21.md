# Random Document Audit Report

## 1. Document Inventory

| Doc ID | Path | Type | Why it may matter |
|---|---|---|---|
| D01 | `README.md` | Product/Setup | Canonical app behavior and setup expectations |
| D02 | `AGENTS.md` | Execution policy | Repo-specific operating constraints |
| D03 | `motto_v2.md` | Execution discipline | Required decision/verification framework |
| D04 | `firebase_task.md` | Phase checklist | P0/P1 implementation commitments |
| D05 | `TOKEN_ECONOMY_TODO.md` | Roadmap/TODO | Guardrails, token economy, cost behavior |
| D06 | `docs/EXPLORATION_TOPICS.md` | Exploration map | Long-horizon architecture priorities |
| D07 | `docs/exploration/backlog.md` | Exploration backlog | Promotion log and pending lanes |
| D08 | `docs/security/SECURITY_BASELINE_RUNBOOK.md` | Security runbook | Baseline security validation path |
| D09 | `docs/archive/fixes/security_audit_fixes.md` | Historical fix report | Security claim set to verify against code |
| D10 | `docs/review/P0_MANDATORY_REVIEW_PACKET_2026-05-21.md` | Review packet | Recent hardening evidence |
| D11 | `docs/review/APPCHECK_RATE_LIMIT_IMPLEMENTATION_PACKET_2026-05-21.md` | Security impl notes | Runtime security control evidence |
| D12 | `docs/review/SECRET_PATH_AND_RELEASE_GUARD_AUDIT_2026-05-21.md` | Security audit | Secret and release-guard posture |
| D13 | `docs/testing/QA_CHECKLIST.md` | QA checklist | Test claims vs executable reality |
| D14 | `docs/guides/deployment/deployment_guide.md` | Deployment guide | Operational assumptions |
| D15 | `docs/archive/fixes/CRITICAL_FIREBASE_API_KEY_SECURITY_BREACH_FIX.md` | Historical incident fix | Secret handling lineage |

Candidate set was discovered by `rg --files -g '*.md'` (very large set; truncated in terminal output).

## 2. Random Selection

Chosen document: `docs/archive/fixes/security_audit_fixes.md`

Selection method: true random CLI selection via `rg --files -g '*.md' | shuf | head -n 1`.

Why this doc is worth auditing: it makes strong security-implementation claims (`Status: IMPLEMENTED`, `Priority: CRITICAL`) that should match current Android/runtime configuration.

## 3. Chosen Document Deep Analysis

| Doc Item ID | Type | Short quote / evidence | Location | Interpretation | Confidence |
|---|---|---|---|---|---|
| DI-01 | Current-State Claim | `Status: IMPLEMENTED` | `docs/archive/fixes/security_audit_fixes.md:5` | Claims security changes are complete | High |
| DI-02 | Current-State Claim | `minSdk = 24` | `...:26-27` | Android API floor raised for security | High |
| DI-03 | Security Claim | `HTTPS-only communication` | `...:49-52` | Cleartext blocked in runtime config | Medium |
| DI-04 | Security Claim | `usesCleartextTraffic="false"` | `...:105-112` | Manifest-level cleartext block | High |
| DI-05 | Security Claim | `taskAffinity=""` + `allowTaskReparenting="false"` | `...:145-149` | Task hijacking mitigation expected | Medium |
| DI-06 | Test/QA Claim | checklist includes cert pinning test | `...:206-212` | Operational verification expected | High |
| DI-07 | Deployment Claim | `~5% of users on Android 6.x excluded` | `...:229` | Numerical impact claim needing external evidence | Low |
| DI-08 | Operational Safety Claim | `Automated security scans in CI/CD` | `...:259-260` | Expects real workflow automation | Medium |
| DI-09 | Stale/Unknown | `random task affinity prevents hijacking` | `...:153` | Wording may not match actual empty affinity behavior | Medium |
| DI-10 | Question | `Certificate pinning` listed in tests | `...:211` | Is pinning implemented or only listed? | High |

## 4. Extracted Task Candidates

| Task Candidate ID | Source Doc Item IDs | Task | Explicit or Implicit | Why this is a task | Expected repo area | Initial priority guess |
|---|---|---|---|---|---|---|
| TC-01 | DI-03, DI-04 | Verify HTTPS-only claim against real network config | Explicit | Security guarantee must match runtime config | `android/app/src/main/res/xml/network_security_config.xml` | P1 |
| TC-02 | DI-06, DI-10 | Verify certificate pinning implementation vs checklist claim | Explicit | Checklist can mislead release-readiness | Android network stack/docs | P1 |
| TC-03 | DI-05, DI-09 | Validate task-hijacking mitigation claim wording | Implicit | Security docs should reflect exact semantics | `AndroidManifest.xml` + doc | P2 |
| TC-04 | DI-08 | Validate CI/CD security scanning existence | Explicit | Operational controls must be executable | `.github/workflows/security.yml` | P1 |
| TC-05 | DI-07 | Validate user-impact % claim or mark unknown/stale | Explicit | Numeric claims require source evidence | Doc only | P3 |
| TC-06 | DI-01 | Reclassify doc status completeness (implemented vs partially verified) | Implicit | Prevent false closure | doc/archive + review docs | P1 |

## 5. Static Codebase Reality Check

| Task Candidate ID | Codebase Status | Evidence | What exists today | Gap | Actual Work Needed |
|---|---|---|---|---|---|
| TC-01 | Contradictory Evidence | `android/app/src/main/AndroidManifest.xml:30-31`; `android/app/src/main/res/xml/network_security_config.xml:12-16` | App-wide cleartext disabled, but explicit localhost/10.0.2.2 cleartext exception exists | Doc says blanket HTTPS-only | Update doc to “production endpoints HTTPS-only; localhost dev exception present” |
| TC-02 | Missing | `docs/archive/fixes/security_audit_fixes.md:211`; no pin-set config in `network_security_config.xml:1-24` | Pinning test is listed | No cert pinning implementation/evidence in Android config | Either implement pinning or remove/retarget checklist item |
| TC-03 | Partially Done | `android/app/src/main/AndroidManifest.xml:42-43` | `taskAffinity=""` and `allowTaskReparenting="false"` set | Doc phrase “random task affinity” is inaccurate | Correct doc language to “empty task affinity + no reparenting” |
| TC-04 | Already Done | `.github/workflows/security.yml:1-40`, `:66-120` | Trivy, SARIF upload, dependency + secrets scans defined | Doc should reference concrete workflow | Link workflow in doc |
| TC-05 | Unknown | `docs/archive/fixes/security_audit_fixes.md:229` | Numeric estimate present | No in-repo data source for `%` | Mark as unknown or cite Play Console/analytics source |
| TC-06 | Stale Doc | `docs/archive/fixes/security_audit_fixes.md:5`, `:206-212` | Claims implemented; checklist still open and partially unbacked | Status overstates closure | Reclassify as “implemented with residual validation gaps” |

Search evidence for “missing” statements:
- `rg -n "certificate pinning|pinning" android/app/src/main/res/xml/network_security_config.xml docs/archive/fixes/security_audit_fixes.md`
- `rg -n "localhost|10.0.2.2|cleartextTrafficPermitted=\"true\"" android/app/src/main/res/xml/network_security_config.xml`
- `nl -ba .github/workflows/security.yml | sed -n '1,120p'`

## 6. Dynamic Verification and Test Baseline

Baseline command set executed in this audit run:
- `flutter test test/services/model_selection_service_test.dart test/screens/image_capture_screen_test.dart test/widgets/analysis_speed_selector_test.dart` -> pass
- `flutter test test/services/ai_service_test.dart` -> pass
- `dart analyze ...` targeted slices -> warnings/info only in touched slices

Security-doc-specific dynamic checks:
- No Android runtime/proxy traffic capture was executed in this pass.
- No emulator-level task hijacking exercise was executed in this pass.

Evidence strength note:
- Runtime app tests prove adjacent system health, but they are weaker than dedicated Android security instrumentation for TC-01/TC-02/TC-03.

## 7. Critical Implementation and Test Traps Checked

- Environment/config loading: checked Android static config path references in manifest + network security XML.
- Module cache/state leakage: not central to selected Android doc; no new leakage patterns introduced.
- Full-suite vs targeted distinction: targeted tests were run; full repo-wide test/analyze remains noisy and not used as closure evidence for this security doc.
- Proof-of-concept probe: not required; static evidence is sufficient to classify the doc/code mismatches.

## 8. Data, Privacy, and PII Boundary Checks

Relevant outcomes:
- `android:hasFragileUserData="true"` confirmed in `AndroidManifest.xml:29`.
- No direct PII serialization guard changes were implicated by this selected document.
- Privacy claim quality issue: compliance claims (GDPR/CCPA/SOC2) in doc are unreferenced to executable controls (`docs/archive/fixes/security_audit_fixes.md:252-255`) and should be treated as unsupported unless linked to concrete controls/evidence.

## 9. Deduped Issue / Task Register

## ISSUE-001: HTTPS-Only Claim Overstates Runtime Policy

Category:
- security / docs

Origin:
- Explicit
- Source doc: `docs/archive/fixes/security_audit_fixes.md:49-52`
- Related doc items: `DI-03`, `DI-04`

Codebase Evidence:
- `android/app/src/main/AndroidManifest.xml:30-31` - cleartext disabled globally
- `android/app/src/main/res/xml/network_security_config.xml:12-16` - explicit cleartext allowlist for localhost/dev emulator

Static Verification:
- Claim “all traffic encrypted” conflicts with dev cleartext exception.

Dynamic Verification:
- Baseline command: targeted Flutter test runs
- Baseline result: pass
- Targeted test command: N/A for Android net policy
- Targeted result: N/A
- Full-suite result after probe: N/A
- New failures vs baseline: N/A

Current Behavior:
- Production domains are configured for TLS; localhost/dev cleartext remains allowed.

Expected Behavior / Decision Needed:
- Decide whether to keep dev cleartext exception and document it, or remove it.

Gap:
- Documentation precision mismatch.

Impact:
- Medium: policy misunderstanding can create false assurance.

Risk:
- OperationalRisk

Confidence:
- High

Acceptance Criteria:
- [ ] Doc updated to explicitly describe localhost/dev exception or exception removed.
- [ ] Security checklist distinguishes production vs local-dev transport policy.

Test Plan:
- Automated:
  - Static config check in CI for forbidden cleartext domains outside localhost/dev.
- Manual:
  - Emulator traffic check confirms production endpoints are TLS.

Rollback / Kill Switch:
- Revert doc-only change or restore prior XML domain config if necessary.

Open Questions:
- Should local cleartext remain allowed in release builds?

## ISSUE-002: Certificate Pinning Listed but Not Implemented

Category:
- security / docs / operational-safety

Origin:
- Explicit
- Source doc: `docs/archive/fixes/security_audit_fixes.md:211`
- Related doc items: `DI-06`, `DI-10`

Codebase Evidence:
- `docs/archive/fixes/security_audit_fixes.md:211` - checklist requires certificate pinning test
- `android/app/src/main/res/xml/network_security_config.xml:1-24` - no pin-set configuration

Static Verification:
- No pinning configuration located.

Dynamic Verification:
- Baseline command: targeted tests
- Baseline result: pass
- Targeted test command: N/A
- Targeted result: N/A
- Full-suite result after probe: N/A
- New failures vs baseline: N/A

Current Behavior:
- Trust anchors rely on system CAs.

Expected Behavior / Decision Needed:
- Either implement cert pinning or remove claim/checklist item and document rationale.

Gap:
- Verification checklist implies stronger control than exists.

Impact:
- Medium-High for threat model requiring pinning.

Risk:
- SecurityRisk / FalsePositiveRisk

Confidence:
- High

Acceptance Criteria:
- [ ] Pinning decision documented (implement vs explicitly out-of-scope).
- [ ] Checklist item reflects actual control.

Test Plan:
- Automated:
  - Network security config lint check for pin-set presence if pinning required.
- Manual:
  - MITM simulation in test env if pinning implemented.

Rollback / Kill Switch:
- Feature-flag or build-variant-scoped pinning if rollout risk emerges.

Open Questions:
- Is pinning required by current release policy or only aspirational?

## ISSUE-003: Security Doc Status Is Over-Closed

Category:
- docs / operational-safety

Origin:
- Implicit
- Source doc: `docs/archive/fixes/security_audit_fixes.md:5`, `:206-212`
- Related doc items: `DI-01`, `DI-06`

Codebase Evidence:
- `docs/archive/fixes/security_audit_fixes.md:5` - `Status: IMPLEMENTED`
- `docs/archive/fixes/security_audit_fixes.md:206-212` - unchecked checklist with unresolved pinning

Static Verification:
- Status label and checklist evidence are inconsistent.

Dynamic Verification:
- Baseline command: targeted tests
- Baseline result: pass (not sufficient to close Android security checklist)

Current Behavior:
- Mix of implemented config changes + unresolved verification/control items.

Expected Behavior / Decision Needed:
- Reclassify status to “implemented with open verification tasks”.

Gap:
- Status inflation.

Impact:
- Medium: risk of premature closure in release governance.

Risk:
- OperationalRisk

Confidence:
- High

Acceptance Criteria:
- [ ] Status text corrected.
- [ ] Open checklist items mapped to owners/commands.

Test Plan:
- Automated:
  - None (doc governance).
- Manual:
  - Review packet signoff.

Rollback / Kill Switch:
- Revert doc edit if superseded by stronger evidence.

Open Questions:
- Which team owns security checklist closure?

## ISSUE-004: Unsupported Numeric/User-Impact and Compliance Claims

Category:
- docs / product-decision

Origin:
- Explicit
- Source doc: `docs/archive/fixes/security_audit_fixes.md:229`, `:252-255`
- Related doc items: `DI-07`

Codebase Evidence:
- Numeric `%` impact and regulatory claims present without source attachment.

Static Verification:
- No in-repo analytics/compliance evidence linked.

Dynamic Verification:
- N/A

Current Behavior:
- Claims exist as prose.

Expected Behavior / Decision Needed:
- Add provenance or mark as estimates/unknown.

Gap:
- Evidence attribution missing.

Impact:
- Low-Medium (trust and decision quality).

Risk:
- FalsePositiveRisk

Confidence:
- Medium

Acceptance Criteria:
- [ ] Each numeric/compliance claim has source link or is relabeled unknown/estimate.

Test Plan:
- Manual:
  - Documentation review against authoritative source registry.

Rollback / Kill Switch:
- Doc-only rollback.

Open Questions:
- Do we have authoritative Play Console compatibility share for Android 6.x now?

## 10. Prioritization

| ID | Title | Severity | Blast Radius | Effort | Confidence | Priority | Why |
|---|---|---:|---:|---:|---:|---|---|
| ISSUE-001 | HTTPS-only claim overstates runtime policy | 4 | 4 | 2 | 5 | P1 | Security documentation mismatch can cause wrong threat assumptions |
| ISSUE-002 | Certificate pinning listed but absent | 4 | 3 | 3 | 5 | P1 | Checklist/control mismatch in security-sensitive area |
| ISSUE-003 | Status over-closed | 3 | 4 | 1 | 5 | P1 | Release governance risk from false closure |
| ISSUE-004 | Unsupported numeric/compliance claims | 2 | 2 | 1 | 3 | P2 | Trust/evidence quality issue |

## Priority Queues

### P0
- None proven in this selected-doc scope.

### P1
- ISSUE-001
- ISSUE-002
- ISSUE-003

### P2
- ISSUE-004

### P3
- None

### Quick Wins
- ISSUE-003
- ISSUE-004

### Risky Changes
- ISSUE-002 (if implementing pinning)

### Needs Discussion Before Work
- ISSUE-002
- ISSUE-001

### Not Worth Doing
- None

## 11. Proof-of-Concept Validation

No proof-of-concept probe was needed. Static and existing dynamic evidence were sufficient.

## 12. Assumptions Challenged by Implementation

| Assumption | Why it seemed true | What disproved it | Evidence | How recommendation changed |
|---|---|---|---|---|
| “HTTPS-only for all traffic” | Doc states full encryption | Localhost cleartext exception exists | `network_security_config.xml:12-16` | Reframed as production-only TLS with explicit dev exception |
| “Security checklist implies pinning exists” | Checklist includes pinning validation | No pinning config found | `network_security_config.xml:1-24` | Added decision item: implement or de-scope pinning |

## 13. Parallel Agent / Multi-Model Findings

No subagents were used in this pass. Role split (document analyst, verifier, test/runtime, skeptic) was simulated sequentially in one agent.

## 14. Discussion Pack

## My Recommendation

I recommend working on:

1. `ISSUE-003` - Security doc status reclassification and checklist ownership
2. `ISSUE-001` - HTTPS policy wording correction with explicit dev exception
3. `ISSUE-002` - Pinning decision (implement vs out-of-scope)

Reason:
- These resolve trust gaps between documented security posture and executable controls with minimal risk.

## Why These Matter Now

- They prevent false security closure while release hardening is active.

## What Breaks If Ignored

- Security and release decisions may rely on overstated controls.

## What I Would Not Work On Yet

- Full pinning implementation before policy decision and rollout plan.

## What Is Ambiguous

- Whether pinning is a mandatory policy requirement for this app phase.

## Questions For You

1. Should localhost cleartext remain allowed for release builds, or be build-variant scoped only?
2. Do you want certificate pinning as a hard requirement in the next release stage?
3. Should we relabel this archive doc as historical and move active controls to `docs/security/SECURITY_BASELINE_RUNBOOK.md`?

## Needs Runtime Verification

- Android MITM/pinning behavior if pinning is implemented.

## Needs Online Research

- None required for this repo-grounded pass.

## Needs ChatGPT / External Review

- Optional only if pinning design tradeoffs need second-opinion architecture review.

## 15. Online Research

No online research needed. Current findings are repo-evidence based.

## 16. ChatGPT / External Review Escalation Writeup

Not needed for this pass.

## 17. Recommended Next Work Unit

## Unit-1: Security Doc Truth-Map and Policy Alignment

Goal:
- Align `security_audit_fixes.md` claims with actual Android/network controls and explicit policy decisions.

Issues covered:
- ISSUE-001
- ISSUE-002
- ISSUE-003
- ISSUE-004

Scope:
- In:
  - Update doc claims/checklist/status language
  - Add explicit decision log for pinning and localhost cleartext
- Out:
  - Runtime pinning implementation
  - Broad CI/security refactor

Likely files touched:
- `docs/archive/fixes/security_audit_fixes.md`
- `docs/security/SECURITY_BASELINE_RUNBOOK.md`
- `docs/reports/status/CURRENT_ISSUES_SUMMARY.md` (if status sync desired)

Acceptance criteria:
- [ ] Status line no longer overstates closure.
- [ ] HTTPS policy wording matches manifest/XML reality.
- [ ] Pinning is either implemented or explicitly de-scoped with rationale.
- [ ] Numeric/compliance claims are sourced or relabeled as estimates.

Tests to run:
- Baseline:
  - `flutter test test/services/ai_service_test.dart`
- Targeted:
  - Static grep checks for manifest/network policy consistency
- Full suite:
  - `flutter test` (when runtime budget allows) with pre-existing vs new failure separation

Manual verification:
- Review updated doc text line-by-line against config files.

Docs to update:
- `docs/archive/fixes/security_audit_fixes.md`
- `docs/security/SECURITY_BASELINE_RUNBOOK.md`

Operational safety:
- Kill switch / rollback:
  - Doc-only rollback if required; no runtime code behavior change in this unit.

Risks:
- Low (documentation and policy-alignment unit).

Rollback plan:
- Revert changed markdown files.

## 18. Appendix: Searches Performed

1. `rg --files -g '*.md'`
2. `rg --files -g '*.md' | shuf | head -n 1`
3. `nl -ba docs/archive/fixes/security_audit_fixes.md | sed -n '1,260p'`
4. `nl -ba android/app/build.gradle | sed -n '1,140p'`
5. `nl -ba android/app/src/main/AndroidManifest.xml | sed -n '1,220p'`
6. `nl -ba android/app/src/main/res/xml/network_security_config.xml | sed -n '1,220p'`
7. `rg -n "certificate pinning|pinning|networkSecurityConfig|usesCleartextTraffic|hasFragileUserData|taskAffinity|allowTaskReparenting" ...`
8. `rg -n "localhost|10.0.2.2|cleartextTrafficPermitted=\"true\"" android/app/src/main/res/xml/network_security_config.xml`
9. `nl -ba .github/workflows/security.yml | sed -n '1,120p'`
10. Targeted verification commands run in this session:
   - `flutter test test/services/model_selection_service_test.dart`
   - `flutter test test/screens/image_capture_screen_test.dart`
   - `flutter test test/services/ai_service_test.dart`
