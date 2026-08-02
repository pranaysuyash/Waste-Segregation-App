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

# Task: Analytics, Evaluation and Product Evidence

## Priority

P1 for pilot; P2 for optimisation.

## Objective

Create trustworthy evidence across three layers:

1. model/policy quality;
2. workflow/product outcomes;
3. revenue/commercial outcomes.

## Event contract

Context:

- event ID;
- server receipt time;
- user/account/organisation/site;
- role;
- app/version/platform/environment;
- taxonomy/policy/model/prompt version;
- experiment ID/variant;
- consent state.

No raw images, emails or unrestricted error text.

## Model/policy events

- scan requested/succeeded/abstained/failed;
- stream predicted;
- stream confirmed/corrected;
- handling flag;
- safety warning;
- policy applied/skipped;
- source trust/freshness;
- society delta/conflict;
- latency/cost/cache;
- queue state.

## Workflow events

- daily check started/completed;
- contamination detected;
- issue assigned/resolved/reopened;
- evidence captured;
- training assigned/completed;
- report generated/exported;
- processor handoff.

## Revenue events

Server only:

- checkout created;
- provider authorised;
- entitlement activated;
- renewal;
- cancellation;
- refund/reversal;
- paid pilot signed/converted/renewed.

Reconcile to billing ledger.

## Metrics

### Quality

- four-stream precision/recall;
- safety false negatives;
- correction;
- abstention;
- policy error;
- provenance completeness;
- cost/verified result.

### Product

- first useful result;
- daily-check completion;
- issues/100 checks;
- resolution time;
- repeated-error reduction;
- training impact;
- weekly active sites;
- evidence coverage.

### Commercial

- qualified opportunity;
- proposal;
- paid pilot;
- pilot-to-contract;
- MRR/ARR where applicable;
- gross margin;
- support effort;
- churn reason.

## Data quality

- schema registry;
- event versioning;
- dedupe;
- late-arrival handling;
- user/account merge;
- missing-context alerts;
- staging validation;
- revenue reconciliation;
- retention/deletion.

## Evaluation datasets

Separate:

- regression fixtures;
- reviewed real-image golden set;
- training candidates;
- training dataset;
- production sampled audit.

A user correction is not automatic truth.

## Acceptance criteria

- critical funnels and quality paths instrumented;
- server revenue is authoritative;
- policy/model versions enable regression analysis;
- dashboards surface missing data;
- real-image safety gate exists;
- product/pilot decision can be made without raw Firestore archaeology.

## Anything else?

The current pricing service logs events through the app logger. Logs are diagnostics, not experiment analytics.
