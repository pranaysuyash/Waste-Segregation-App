> **Review baseline:** `pranaysuyash/Waste-Segregation-App`, branch `main`, commit `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Remote commit date:** 2026-05-25
>
> **Review date:** 2026-08-02
>
> **Hard limitation:** This review does not include local, uncommitted, or unpushed work. Run `02_TASK_LOCAL_CHANGE_RECONCILIATION.md` before implementing any other task. Existing local work is authoritative where it is newer and intentional.

# Parallel Agent Orchestration

## Objective

Use multiple agents without creating conflicting implementations, lost local work or unmergeable branches.

## Mandatory gate

No agent begins until `02_TASK_LOCAL_CHANGE_RECONCILIATION.md` produces the file-ownership map.

## Workstreams

### Agent A: Security and rules

Owns:

- `firestore.rules`
- `storage.rules`
- `firestore-rules-test/**`
- R2 security changes
- referral transaction security
- security docs

Must not edit premium UI or classification schema.

### Agent B: Billing and entitlements

Owns:

- payment Functions;
- billing data model;
- purchase/premium/web-checkout services;
- premium purchase UI;
- billing tests/docs.

Coordinates any `firestore.rules` requirement with Agent A through a written contract. Agent A applies the rule change.

### Agent C: QA and release

Owns:

- `.github/workflows/**`
- CI scripts;
- release evidence;
- environment manifests;
- test orchestration.

May add tests anywhere but should avoid changing domain behaviour.

### Agent D: Privacy and data governance

Owns:

- consent/retention/deletion design;
- privacy pipeline;
- training-data governance;
- privacy docs and tests.

Coordinates storage and rules with Agent A.

### Agent E: Architecture

Starts after A/B core contracts stabilise.

Owns:

- classification facade;
- bootstrap/composition root;
- result event/outbox;
- state-management ADR;
- duplicate-service removal.

Must not redesign billing semantics or policy taxonomy.

### Agent F: AI taxonomy/eval

Starts after the canonical classification facade interface is agreed.

Owns:

- classification schema migration;
- prompts/parsers;
- policy packs;
- eval data and harness;
- AI quality report.

### Agent G: Product/BWG

Owns:

- role flows;
- organisation/site domain;
- operational UI;
- report workflow.

Coordinates schema and tenancy contracts with A, D, E and F.

### Agent H: Analytics/GTM/docs

Can run research in parallel. Code instrumentation begins after event contracts stabilise.

Owns:

- event/metric docs;
- product research;
- sales collateral;
- canonical README/current docs;
- issue reconciliation.

## Shared-file protocol

No two active branches may edit the same high-conflict file.

High-conflict files:

- `firestore.rules`
- `functions/src/index.ts`
- `lib/main.dart`
- `pubspec.yaml`
- `lib/models/waste_classification.dart`
- `lib/screens/premium_features_screen.dart`
- root `README.md`
- `docs/README.md`

For shared changes:

1. owning agent publishes an interface/contract document;
2. dependent agent works against the contract;
3. owner performs the final shared-file edit;
4. integration agent runs combined tests.

## Branch naming

```text
review/reconcile-local
p0/security-trust-boundary
p0/billing-entitlement
p0/ci-release-gate
p0/privacy-governance
p1/architecture-canonical
p1/ai-swm2026
p1/bwg-mvp
p1/analytics
p1/docs-convergence
```

## Handoff contract

Every branch must include `HANDOFF.md` containing:

- objective;
- changed files;
- schema/API changes;
- migrations;
- feature flags;
- tests run and results;
- manual checks;
- unresolved risks;
- rollout;
- rollback;
- dependent branches.

## Merge order

1. local reconciliation;
2. CI scaffolding that does not change product behaviour;
3. security rules and tests;
4. billing server model and verification;
5. privacy/storage controls;
6. architecture facade;
7. SWM 2026 schema/policy/eval;
8. BWG domain and UI;
9. analytics;
10. documentation/issue cleanup;
11. final integrated release evidence.

Some branches may develop in parallel, but merge in dependency order.

## Integration cadence

After every P0 merge:

```bash
flutter pub get
flutter analyze
flutter test
npm --prefix functions ci
npm --prefix functions run build
npm --prefix functions test
npm --prefix firestore-rules-test run test:all:emulator
```

Run the AI eval after any classification, parser, prompt, policy or model change.

## Stop conditions

An agent stops and reports rather than improvising when:

- local work conflicts with task assumptions;
- a schema owner has not approved a change;
- a security rule must be loosened to make a feature pass;
- a payment behaviour is unclear;
- an official policy source contradicts the task;
- tests reveal an unrelated P0;
- implementation would add another overlapping service.

## Final integration owner

One agent or human must own final integration. Parallel agents do not independently declare the product release-ready.
