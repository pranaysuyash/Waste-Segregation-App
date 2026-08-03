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

## PMF-first recurring-core update (2026-08-03)

The feedback route is a recurring disposal loop for a Bengaluru household plus
housekeeping team, with the BWG quality layer as the sellable extension. The
loop is: select an area, see a source-qualified next action or an honest
unavailable state, prepare the correct stream, record an observed handover
outcome, and turn a missed or unconfirmed outcome into an accountable issue.

This is a task-allocation update only. Area calendars, pickup events, reminders
and the completion layer remain design-only, as recorded in
`20_TASK_CHATGPT_FEEDBACK_PMFMODEL_AND_CONFIDENCE_HARDENING_2026-08-02.md`.
No new P0-P2 ID is introduced and no collector, municipal or processor
operation is implied.

### Recurring-loop dependency order

1. P0-03 and P0-07 protect tenant access and any permitted evidence.
2. P1-01 to P1-05 establish canonical stream, source, safety and operational-authority facts.
3. P1-06 to P1-07 make event, sync and downstream effects convergent and idempotent.
4. P1-08 to P1-10 define and implement the recurring pre-handover workflow and its processor handoff boundary.
5. P1-11 tests whether the repeated job has a buyer and conversion path.
6. P2-02 measures the loop alongside paid-pilot and experiment facts.

The schedule is an input to a user or operator action, not proof that a
collection service will arrive. The completion record is observed workflow
evidence, not a statutory, municipal or processor certificate.

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

## P1: build a sellable recurring wedge

| ID | Work | Task file | Exit property |
|---|---|---|---|
| P1-08 | Define recurring pre-handover segregation-quality product | `12_TASK_PRODUCT_WEDGE_BWG.md` | One buyer/job/non-goal/recurring-cycle contract |
| P1-09 | Tenant/site/area/operator workflow | `12_TASK_PRODUCT_WEDGE_BWG.md` | Design partner can see a source-qualified next action, complete a daily check and close an observed pickup outcome or issue |
| P1-10 | Processor integration and completion-evidence boundary | `12_TASK_PRODUCT_WEDGE_BWG.md` | Evidence and observed outcome state can hand off to AWP/platform without creating a collector operation |
| P1-11 | Buyer validation and paid recurring pilot | `13_TASK_GTM_SALEABILITY.md` | Qualified buyer accepts a measurable recurring pilot |

## P2: validate economics and growth

| ID | Work | Task file | Exit property |
|---|---|---|---|
| P2-01 | Rebuild pricing experiment | `11_TASK_PRICING_EXPERIMENT_REBUILD.md` | Stable assignment, truthful variants, valid power |
| P2-02 | Server-side exposure/revenue and recurring-loop events | `16_TASK_ANALYTICS_EVAL_EVIDENCE.md` | Experiment and recurring-loop facts reconcile to the billing ledger where applicable |
| P2-03 | Repair referral/reward economy | `15_TASK_REFERRALS_GAMIFICATION_ECONOMY.md` | Exactly-once, fraud-aware rewards |
| P2-04 | Current portable docs | `14_TASK_DOCS_AGENT_ONBOARDING.md` | New agent can work without private workspace dependencies |

## PMF hypothesis to task and file ownership

The following map preserves the current task numbering. Each row gives the
single review artifact that owns the acceptance contract for that concern.

| Task ID | Exact review-file owner | Acceptance criterion for the PMF hypothesis |
|---|---|---|
| P0-03 | `docs/review/current-review-2026-08-02/waste-segregation-current-review-2026-08-02/04_TASK_AUTHORIZATION_FIRESTORE.md` | Tenant/site/role access prevents one resident, operator or processor from reading or changing another tenant's schedule, event or evidence. |
| P0-07 | `docs/review/current-review-2026-08-02/waste-segregation-current-review-2026-08-02/09_TASK_OFFLINE_QUEUE_PRIVACY.md` | Event evidence follows consent, retention, deletion and offline-recovery rules. |
| P1-01 to P1-03 | `docs/review/current-review-2026-08-02/waste-segregation-current-review-2026-08-02/06_TASK_POLICY_TAXONOMY_SWM2026.md` | The loop uses canonical streams, reviewed schedule provenance and conservative special-care handling when an exact schedule is unavailable. |
| P1-04 to P1-05 | `docs/review/current-review-2026-08-02/waste-segregation-current-review-2026-08-02/07_TASK_SOCIETY_POLICY_AUTHORITY.md` | Site operational windows are additive, reviewed and cannot replace stream or safety authority. |
| P1-06 to P1-07 | `docs/review/current-review-2026-08-02/waste-segregation-current-review-2026-08-02/08_TASK_RUNTIME_ARCHITECTURE_CONVERGENCE.md` | Retry and delayed sync cannot duplicate a completion, issue, notification, training or reward effect. |
| P1-08 to P1-10 | `docs/review/current-review-2026-08-02/waste-segregation-current-review-2026-08-02/12_TASK_PRODUCT_WEDGE_BWG.md` | The selected area, source-qualified next action, observed outcome, issue path and processor handoff remain a pre-handover quality product. |
| P1-11 | `docs/review/current-review-2026-08-02/waste-segregation-current-review-2026-08-02/13_TASK_GTM_SALEABILITY.md` | A buyer confirms the recurring workflow solves a budgeted, repeated quality problem and agrees a conversion decision. |
| P2-02 | `docs/review/current-review-2026-08-02/waste-segregation-current-review-2026-08-02/16_TASK_ANALYTICS_EVAL_EVIDENCE.md` | The team can distinguish schedule availability, preparation, observed completion, unresolved events and commercial outcome without client-only facts. |

### Explicitly deferred

- collection dispatch, booking, marketplace, routing, vehicle tracking, collector support, invoicing and payment operations;
- nationwide or inferred area calendars, including a reminder based only on a generic city frequency;
- treating a self-reported or elapsed event as proof of municipal or processor collection;
- official certification, statutory-return claims, a full EPR platform and broad society ERP;
- per-scan monetisation or gamification as the primary retention mechanism.

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
- source-qualified schedule coverage for the selected pilot area, or an explicit unavailable state;
- preparation, observed outcome and missed/unconfirmed event states that remain distinct;
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
10. recurring-core work identifies its schedule source/status, event-state semantics and explicit non-collector boundary.

## Anything else?

The recurring consumer loop is not permission to bypass the existing trust and
policy gates. The first operational decision remains a bounded pilot area plus
a reviewed schedule source. If that fact is unavailable, the product must keep
the safe-handling and issue workflow while showing an honest unavailable state,
not manufacture a calendar, reminder or collection claim.
