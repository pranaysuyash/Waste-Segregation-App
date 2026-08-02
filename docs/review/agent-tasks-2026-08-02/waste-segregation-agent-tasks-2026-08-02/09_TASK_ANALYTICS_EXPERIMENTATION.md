> **Review baseline:** `pranaysuyash/Waste-Segregation-App`, branch `main`, commit `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Remote commit date:** 2026-05-25
>
> **Review date:** 2026-08-02
>
> **Hard limitation:** This review does not include local, uncommitted, or unpushed work. Run `02_TASK_LOCAL_CHANGE_RECONCILIATION.md` before implementing any other task. Existing local work is authoritative where it is newer and intentional.

# Task: Analytics, Product Evidence and Experiments

## Priority

P1 for pilot learning; P2 for scale.

## Objective

Instrument the minimum metrics needed to determine whether the product is accurate, useful, retained and commercially viable.

## Principle

Do not track everything. Track decisions.

Each event must answer one of:

- did the user reach value?
- was the classification safe and useful?
- did behaviour improve?
- did the operator close work?
- did the buyer receive evidence?
- did the account pay or renew?

## Canonical identity and context

Every event must include, where applicable:

- anonymous/session user ID;
- authenticated UID;
- organisation ID;
- site ID;
- role;
- app version;
- platform;
- environment;
- taxonomy version;
- policy pack;
- model/prompt version;
- experiment assignment.

Do not include raw personal data or image URLs in analytics.

## Event schema

### Acquisition/onboarding

- `app_opened`
- `role_selected`
- `organisation_joined`
- `site_created`
- `onboarding_completed`

### Classification

- `scan_started`
- `capture_failed`
- `classification_requested`
- `classification_succeeded`
- `classification_abstained`
- `classification_failed`
- `result_confirmed`
- `result_corrected`
- `safety_warning_shown`
- `policy_guidance_opened`

### Operations

- `daily_check_started`
- `daily_check_completed`
- `issue_created`
- `issue_assigned`
- `issue_resolved`
- `issue_reopened`
- `evidence_uploaded`
- `report_generated`
- `report_exported`

### Training

- `training_assigned`
- `training_started`
- `training_completed`
- `training_check_passed`
- `training_check_failed`

### Revenue

- `paywall_viewed`
- `checkout_started`
- `checkout_completed_server`
- `entitlement_activated_server`
- `entitlement_expired_server`
- `refund_processed_server`
- `pilot_started`
- `pilot_converted`
- `account_renewed`
- `account_churned`

Server revenue events must not be emitted from client success UI.

## Metric hierarchy

### North-star candidate for pilot

**Verified correct segregation actions per active site per week**

This combines use and confirmed correctness. Validate whether it predicts buyer value.

### Activation

Consumer/user:

- first useful result within first session;
- result confirmation/correction completed.

Operator:

- first daily check completed;
- first issue created and resolved.

Buyer:

- first report generated;
- second weekly return.

### Quality

- safety-critical false-negative rate;
- correction rate by category;
- abstention rate;
- policy-guidance usefulness;
- repeat error rate;
- latency p50/p95;
- cost per verified action.

### Retention

- weekly active sites;
- operator return rate;
- daily checklist completion;
- four-week buyer report recurrence.

### Commercial

- qualified conversations;
- pilot acceptance;
- pilot-to-paid conversion;
- monthly recurring revenue;
- gross margin after AI/storage/support;
- sales cycle;
- churn reason.

## Data quality controls

- version the event schema;
- reject unknown required fields;
- deduplicate by event ID;
- separate client timestamp and server receipt time;
- monitor event volume anomalies;
- document metric definitions;
- reconcile payment analytics with the billing ledger;
- sample events in staging.

## Experiments

### E1. Scan-first vs education-first onboarding

Hypothesis: reaching a useful result before account creation improves activation.

### E2. Confidence display

Compare:

- numeric confidence;
- plain-language certainty;
- explicit “needs confirmation.”

Measure correction quality, not just clicks.

### E3. Site issue follow-up

Test whether assigning a concrete action reduces repeated contamination.

### E4. Buyer report

Test a compliance-style report against a simpler operational scorecard. Measure which drives weekly return and purchase intent.

### E5. Consumer payment

Do not build more consumer premium features first. Run a price/value smoke test with truthful current capabilities.

## Required artifacts

- `docs/analytics/EVENT_CATALOG.md`
- `docs/analytics/METRIC_DICTIONARY.md`
- `docs/analytics/DATA_QUALITY_CHECKS.md`
- dashboard specification
- experiment registry with hypothesis, guardrails and decision rule

## Acceptance criteria

- Every critical funnel step has a validated event.
- Revenue events reconcile to server ledger.
- Quality metrics are versioned by model/policy/taxonomy.
- Dashboards expose missing or delayed data.
- Experiments have a decision rule before launch.
- Product decisions can be made without querying raw production documents manually.
