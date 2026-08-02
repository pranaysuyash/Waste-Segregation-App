> **Repository:** `pranaysuyash/Waste-Segregation-App`
>
> **Reviewed branch:** `main`
>
> **Reviewed commit:** `e48a66bd6c9116e939a3eddfa5cc48c5d2171e6a`
>
> **Commit timestamp:** 2026-08-02T03:40:33Z
>
> **Review timestamp:** 2026-08-02
>
> **Previous review baseline:** `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Evidence limit:** Static remote-code inspection plus current official/public-source research. The latest GitHub commit exposes no combined status checks or associated workflow runs, so build, test, deployment and runtime claims remain unverified until the release-proof task is executed.

# Master Execution Plan

## First-principles dependency chain

The product can be sold only when this chain holds:

1. the reviewed commit builds and runs;
2. clients cannot forge paid, role or reward state;
3. money events are verified and retry-safe;
4. policy outputs use current official categories and authority precedence;
5. images and evidence have explicit consent/retention/deletion;
6. site/organisation records are tenant isolated;
7. the buyer receives a measurable job outcome;
8. pricing is tested with a statistically valid and truthful experiment.

## P0: block launch and monetisation

| ID | Work | Task file | Exit property |
|---|---|---|---|
| P0-01 | Prove the current head builds, tests and deploys | `03_TASK_RELEASE_PROOF_AND_CI.md` | Traceable release evidence exists |
| P0-02 | Deny client writes to server-owned fields | `04_TASK_AUTHORIZATION_FIRESTORE.md` | Premium/roles/rewards cannot be forged |
| P0-03 | Scope family/invitation/society access | `04_TASK_AUTHORIZATION_FIRESTORE.md` | Non-members cannot read or mutate tenant data |
| P0-04 | Establish server entitlement ledger | `05_TASK_BILLING_ENTITLEMENTS.md` | Client state is cache only |
| P0-05 | Repair webhook idempotency/reconciliation | `05_TASK_BILLING_ENTITLEMENTS.md` | Retry cannot lose or duplicate value |
| P0-06 | Implement platform/storefront billing rules | `05_TASK_BILLING_ENTITLEMENTS.md` | Only eligible rails are displayed |
| P0-07 | Protect queued/dead-letter/cache images | `09_TASK_OFFLINE_QUEUE_PRIVACY.md` | Retention and deletion are explicit |
| P0-08 | Remove unsafe public R2 upload assumptions | `10_TASK_STORAGE_R2_DATA_LIFECYCLE.md` | Uploads are bounded, private and finalised |

## P1: establish correct domain authority

| ID | Work | Task file | Exit property |
|---|---|---|---|
| P1-01 | Canonical SWM 2026 four streams | `06_TASK_POLICY_TAXONOMY_SWM2026.md` | Stream schema matches current rules |
| P1-02 | Verify policy sources and versions | `06_TASK_POLICY_TAXONOMY_SWM2026.md` | Production packs have reviewed provenance |
| P1-03 | Conservative low-confidence safety | `06_TASK_POLICY_TAXONOMY_SWM2026.md` | Uncertainty cannot suppress safe handling |
| P1-04 | Authority hierarchy for society rules | `07_TASK_SOCIETY_POLICY_AUTHORITY.md` | Society cannot weaken statutory/safety rules |
| P1-05 | Secure and correct society geolocation/admin | `07_TASK_SOCIETY_POLICY_AUTHORITY.md` | Only authorised roles can publish verified deltas |
| P1-06 | Finish runtime convergence | `08_TASK_RUNTIME_ARCHITECTURE_CONVERGENCE.md` | One instance/owner per workflow dependency |
| P1-07 | Idempotent downstream effects | `08_TASK_RUNTIME_ARCHITECTURE_CONVERGENCE.md` | Retry cannot double-award/post/train/sync |

## P1: build a sellable wedge

| ID | Work | Task file | Exit property |
|---|---|---|---|
| P1-08 | Define pre-handover segregation-quality product | `12_TASK_PRODUCT_WEDGE_BWG.md` | One buyer/job/non-goal contract |
| P1-09 | Tenant/site/operator workflow | `12_TASK_PRODUCT_WEDGE_BWG.md` | Design partner can complete daily check and issue closure |
| P1-10 | Processor integration contract | `12_TASK_PRODUCT_WEDGE_BWG.md` | Evidence can hand off to AWP/platform |
| P1-11 | Buyer validation and paid pilot | `13_TASK_GTM_SALEABILITY.md` | Qualified buyer accepts measurable pilot |

## P2: validate economics and growth

| ID | Work | Task file | Exit property |
|---|---|---|---|
| P2-01 | Rebuild pricing experiment | `11_TASK_PRICING_EXPERIMENT_REBUILD.md` | Stable assignment, truthful variants, valid power |
| P2-02 | Server-side exposure/revenue events | `16_TASK_ANALYTICS_EVAL_EVIDENCE.md` | Experiment facts reconcile to billing ledger |
| P2-03 | Repair referral/reward economy | `15_TASK_REFERRALS_GAMIFICATION_ECONOMY.md` | Exactly-once, fraud-aware rewards |
| P2-04 | Current portable docs | `14_TASK_DOCS_AGENT_ONBOARDING.md` | New agent can work without private workspace dependencies |

## Hard release gates

### Gate A: static and build integrity

- clean dependency install;
- strict formatter/analyser;
- Flutter unit/widget/golden tests;
- Functions TypeScript build/tests;
- rule emulator tests;
- AI eval;
- release artefacts;
- no repository mutation in CI.

### Gate B: trust

- client cannot create entitlement, reward, role or verification state;
- non-member cannot read family/society/invitation data;
- billing events are provider verified;
- webhook retry is safe;
- raw images are private and deletable.

### Gate C: policy

- four-stream regulatory schema;
- source and version verified;
- safety handling remains conservative under uncertainty;
- society rules are subordinate and auditable;
- real-image safety eval passes.

### Gate D: commercial pilot

- defined buyer;
- defined operator workflow;
- evidence report;
- measurable baseline and target;
- explicit conversion decision;
- no unsupported compliance promise.

## Definition of done for every agent task

A task is complete only when:

1. current worktree and instruction stack were inspected;
2. behaviour and authority contracts were written;
3. implementation is complete;
4. negative and positive tests pass;
5. migration and rollback are documented;
6. telemetry exists for failure modes;
7. current docs are updated;
8. exact commands and evidence tier are recorded;
9. an “Anything else?” sweep is included.
