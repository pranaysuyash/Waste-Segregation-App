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

# Parallel Agent Orchestration

## Goal

Run agents in parallel without reintroducing multiple truths or conflicting edits.

## Preflight for every agent

1. read root `AGENTS.md`, `motto_v4.md`, `CONTEXT.md`;
2. inspect worktree and latest SHA;
3. read this bundle's relevant task;
4. identify overlapping active branches/files;
5. preserve unpushed work;
6. write a task handoff contract.

Until Task 14 fixes onboarding, treat external `/Users/pranay` workspace steps as optional context, not portable repository requirements.

## Workstreams

### Agent A: release proof

Owns:

- workflows;
- test orchestration;
- release evidence.

Does not modify business behaviour.

### Agent B: authorisation

Owns:

- Firestore/Storage rules;
- access matrix;
- rule tests.

Final owner of shared rules edits.

### Agent C: billing

Owns:

- payment Functions;
- server ledger;
- client entitlement cache;
- purchase UI eligibility.

Requests rule contract from B.

### Agent D: policy/taxonomy

Owns:

- four-stream schema;
- prompts/parsers/policy packs;
- eval dataset.

Coordinates model changes with runtime owner.

### Agent E: society governance

Owns:

- society policy model/service;
- authority hierarchy;
- publication/verification;
- role tests.

Coordinates rules with B and stream schema with D.

### Agent F: runtime convergence

Owns:

- composition root;
- orchestrator dependencies;
- outbox;
- legacy AI path removal.

Does not change policy meanings or billing state.

### Agent G: offline/storage/privacy

Owns:

- queue/dead-letter;
- image lifecycle;
- R2 upload/finalisation;
- deletion.

Coordinates rules with B.

### Agent H: product/GTM/analytics/docs

Owns:

- BWG product contracts;
- research;
- analytics taxonomy;
- current docs;
- issue reconciliation.

Code instrumentation begins after contracts stabilise.

## High-conflict files

Single active owner:

- `firestore.rules`
- `lib/main.dart`
- `lib/models/waste_classification.dart`
- `lib/services/local_policy_engine.dart`
- `lib/services/result_pipeline.dart`
- `lib/services/premium_service.dart`
- `functions/src/index.ts`
- `pubspec.yaml`
- `README.md`
- `AGENTS.md`

## Interface-first protocol

When two agents need a shared file:

1. write contract/ADR;
2. dependent agent codes against interface;
3. owner edits shared file;
4. integration agent runs combined suite.

## Branch examples

```text
p0/release-proof
p0/authz-trust-boundary
p0/billing-ledger
p0/image-lifecycle
p1/swm2026-streams
p1/society-authority
p1/runtime-outbox
p1/bwg-product
p1/current-docs
```

## Merge order

1. CI scaffolding;
2. authorisation tests/rules;
3. billing ledger/verification;
4. image lifecycle/R2;
5. stream schema/policy;
6. society authority;
7. runtime outbox/convergence;
8. BWG product;
9. analytics/pricing;
10. docs/issues;
11. integrated release evidence.

Development can overlap. Merge follows dependencies.

## Handoff file

Every branch creates:

```text
docs/work_logs/<task>/<sha>-HANDOFF.md
```

Include:

- user/business/operational value;
- files;
- contracts;
- migrations;
- flags;
- exact tests/results;
- verified versus inferred;
- rollout/rollback;
- conflicts;
- remaining risks;
- Anything else.

## Stop conditions

Stop and report rather than improvise when:

- authority contract is unclear;
- fix requires loosening rules;
- provider billing semantics are unknown;
- official policy contradicts current model;
- another branch changed shared contract;
- a new parallel service would be introduced;
- runtime validation is unavailable for a high-risk path.

## Anything else?

The August update bundled roughly 180 files into one commit. Future work should use small gated commits aligned to one property, not one topic dump.
