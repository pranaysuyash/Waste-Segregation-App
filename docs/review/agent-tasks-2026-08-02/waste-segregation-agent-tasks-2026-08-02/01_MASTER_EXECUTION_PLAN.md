> **Review baseline:** `pranaysuyash/Waste-Segregation-App`, branch `main`, commit `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Remote commit date:** 2026-05-25
>
> **Review date:** 2026-08-02
>
> **Hard limitation:** This review does not include local, uncommitted, or unpushed work. Run `02_TASK_LOCAL_CHANGE_RECONCILIATION.md` before implementing any other task. Existing local work is authoritative where it is newer and intentional.

# Master Execution Plan

## Operating principle

A release is not a set of merged features. It is a chain of verified properties.

The chain for this product is:

1. the user cannot forge access or credits;
2. payment state survives retries, refunds, expiry and reinstall;
3. the classification taxonomy matches current rules;
4. the output is demonstrably correct on real examples;
5. the app produces a reproducible build;
6. the buyer receives a measurable operational outcome;
7. documentation describes the actual system.

Work that does not strengthen this chain is lower priority.

## Priority definitions

- **P0:** prevents charging, deployment or safe pilot use.
- **P1:** required for a credible paid pilot.
- **P2:** required for repeatable sales and retention.
- **P3:** optional leverage after evidence of demand.

## Master backlog

### P0: establish a trusted baseline

| ID | Work | Owner file | Exit gate |
|---|---|---|---|
| P0-01 | Reconcile local/unpushed work against reviewed SHA | `02_TASK_LOCAL_CHANGE_RECONCILIATION.md` | Delta report approved; no local work lost |
| P0-02 | Protect server-owned user fields in Firestore | `03_TASK_SECURITY_AUTHZ_FIRESTORE.md` | Emulator tests prove clients cannot grant premium or alter billing |
| P0-03 | Restrict family, invitation and shared-classification reads | `03_TASK_SECURITY_AUTHZ_FIRESTORE.md` | Non-members receive permission denied |
| P0-04 | Build authoritative entitlement service | `04_TASK_PAYMENTS_ENTITLEMENTS_STORE_COMPLIANCE.md` | Client state cannot create paid access |
| P0-05 | Correct webhook idempotency and reconciliation | `04_TASK_PAYMENTS_ENTITLEMENTS_STORE_COMPLIANCE.md` | Failed side effects retry safely |
| P0-06 | Decide and implement store-compliant billing per platform/region | `04_TASK_PAYMENTS_ENTITLEMENTS_STORE_COMPLIANCE.md` | Store policy checklist and test evidence complete |
| P0-07 | Lock down R2 upload path | `03_TASK_SECURITY_AUTHZ_FIRESTORE.md` | MIME, size, quota, ownership and read policy tested |
| P0-08 | Add backend build/tests to CI | `10_TASK_QA_CI_RELEASE.md` | CI compiles and tests Functions on every PR |
| P0-09 | Make warnings and release build failures blocking | `10_TASK_QA_CI_RELEASE.md` | Clean or approved baseline; release artifacts built |
| P0-10 | Prove deployed rules/configuration | `10_TASK_QA_CI_RELEASE.md` | Staging deployment and smoke evidence captured |
| P0-11 | Establish consent, retention and deletion controls | `11_TASK_PRIVACY_DATA_GOVERNANCE.md` | Data inventory and tested deletion flow complete |

### P1: converge the product core

| ID | Work | Owner file | Exit gate |
|---|---|---|---|
| P1-01 | Select one AI orchestration path | `06_TASK_ARCHITECTURE_CANONICALIZATION.md` | One production classification entry point |
| P1-02 | Select one entitlement authority | `04_TASK_PAYMENTS_ENTITLEMENTS_STORE_COMPLIANCE.md` | Server state is canonical; local state is cache only |
| P1-03 | Split result side effects into idempotent stages | `06_TASK_ARCHITECTURE_CANONICALIZATION.md` | Retry does not duplicate points, posts, ads or training rows |
| P1-04 | Update taxonomy to SWM 2026 four streams | `05_TASK_AI_POLICY_TAXONOMY_EVAL.md` | Schema, prompts, UI and policy packs use canonical taxonomy |
| P1-05 | Replace synthetic-only eval with reviewed real images | `05_TASK_AI_POLICY_TAXONOMY_EVAL.md` | Quality gate reports by class and safety severity |
| P1-06 | Remove or hide unimplemented paid claims | `07_TASK_PRODUCT_WEDGE_AND_UX.md` | Every paid claim has a passing feature contract |
| P1-07 | Repair agent onboarding and source-of-truth docs | `12_TASK_DOCS_REPO_HYGIENE_AGENT_ONBOARDING.md` | Root `AGENTS.md` and canonical docs pass link checks |
| P1-08 | Archive/reconcile stale issues | `12_TASK_DOCS_REPO_HYGIENE_AGENT_ONBOARDING.md` | Open issues map to real current work |

### P1: build the paid pilot

| ID | Work | Owner file | Exit gate |
|---|---|---|---|
| P1-09 | Define one buyer and one job | `07_TASK_PRODUCT_WEDGE_AND_UX.md` | Signed product brief with non-goals |
| P1-10 | Build site/organisation data model | `08_TASK_BWG_COMPLIANCE_PRODUCT.md` | Tenant isolation and role tests pass |
| P1-11 | Add four-stream daily logging and evidence | `08_TASK_BWG_COMPLIANCE_PRODUCT.md` | Pilot site can complete daily workflow |
| P1-12 | Add training/contamination workflow | `08_TASK_BWG_COMPLIANCE_PRODUCT.md` | Staff can correct and resolve uncertain items |
| P1-13 | Generate compliance-ready export | `08_TASK_BWG_COMPLIANCE_PRODUCT.md` | PDF/CSV output traceable to immutable source events |
| P1-14 | Instrument activation and quality | `09_TASK_ANALYTICS_EXPERIMENTATION.md` | Funnel and quality dashboards populate in staging |
| P1-15 | Run design-partner validation | `13_TASK_GTM_SALES_MARKET_VALIDATION.md` | Buyer evidence, objections and willingness-to-pay documented |

### P2: make sales repeatable

- Organisation onboarding and role administration.
- Vendor/processor integration contract.
- Site-level SLA and support runbook.
- Pricing and packaging test.
- Case-study evidence.
- Data export and audit retention policy.
- Multilingual training for English, Kannada and Hindi.
- Referral/partner channel only after the core conversion funnel is measured.

### P3: optional leverage

- On-device inference for obvious cases.
- Local model training.
- Additional municipalities.
- Brand-sponsored challenges.
- Hardware or smart-bin integration.
- Public API.
- Advanced carbon accounting.

## Release gates

### Gate A: repository truth

- local delta reconciled;
- canonical docs exist;
- no broken mandatory paths;
- task branch created from the intended baseline.

### Gate B: trust

- client cannot change billing, entitlement, token credits or server-owned audit fields;
- sensitive reads are tenant/member scoped;
- webhook retries are idempotent;
- App Check and rate limits are enforced where declared;
- secrets are server-side.

### Gate C: correctness

- four-stream taxonomy;
- safety-critical false-negative threshold defined;
- real-image eval set;
- provider and policy provenance visible;
- uncertain results require confirmation.

### Gate D: release

- Flutter analysis passes with agreed severity;
- Flutter tests pass;
- Functions compile and tests pass;
- rules emulator tests pass;
- Android release build passes;
- iOS archive or CI build passes if iOS is in scope;
- staging smoke test passes;
- rollback procedure is exercised.

### Gate E: commercial pilot

- buyer, operator and end-user roles are defined;
- onboarding takes place without developer intervention;
- daily evidence can be generated;
- buyer can understand the report;
- price and renewal decision are tested.

## Definition of done

A task is complete only when:

1. code and documentation are updated;
2. automated tests cover the corrected property;
3. verification commands pass;
4. migration and rollback are documented;
5. telemetry exists for the new failure mode;
6. the task's acceptance criteria are demonstrated in a handoff note.
