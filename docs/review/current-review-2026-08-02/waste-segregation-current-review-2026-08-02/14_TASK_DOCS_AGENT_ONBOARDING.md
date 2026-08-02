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

# Task: Portable Agent Onboarding and Current Documentation

## Priority

P1. Small prerequisite before parallel coding agents.

## Objective

Make repository instructions self-contained, current and consistent with `motto_v4.md`.

## Current defects

- absolute `/Users/pranay/...` requirements;
- private workspace scripts mandatory for all agents;
- `Docs/` versus `docs/`;
- references to retired `motto_v2.md`/`motto_v3.md`;
- README link to missing `docs/APP_KNOWLEDGE_BASE.md`;
- stale “latest” and “production ready” claims;
- pure-Riverpod claim inconsistent with runtime;
- open issues generated from old TODO snapshots.

## Commit units

### Commit 1: portable instruction stack

Root `AGENTS.md`:

- canonical `motto_v4.md`;
- repository-local required files;
- optional local workspace enhancements clearly optional;
- current test commands;
- Git safety;
- branch/file ownership;
- evidence tiers;
- acceptance report;
- current task/status path.

No external file can be mandatory for a fresh clone.

### Commit 2: current-doc layer

Recommended:

```text
docs/current/
  PRODUCT.md
  ARCHITECTURE.md
  SECURITY.md
  BILLING.md
  POLICY_AND_TAXONOMY.md
  DATA_LIFECYCLE.md
  RELEASE_STATUS.md
  KNOWN_ISSUES.md
```

Historical audits remain archived and labelled.

### Commit 3: README rewrite

Keep concise:

- what the product currently does;
- what is experimental;
- supported platforms;
- current release evidence;
- setup;
- tests;
- architecture links;
- no unsupported readiness claims.

Move historical release narrative to archive/changelog.

### Commit 4: link/status validation

CI checks:

- required paths;
- case sensitivity;
- broken links;
- canonical motto only;
- status headers;
- production claim linked to release evidence;
- duplicate canonical docs.

### Commit 5: issue reconciliation

Review open generated issues.

Examples now stale/partial:

- offline queue;
- Riverpod migration;
- feedback;
- security rules testing.

Close, rewrite or merge based on current code. Do not retain an old issue merely because implementation is imperfect; create a current precise issue.

## Acceptance criteria

- clean clone can onboard without `/Users/pranay`;
- only motto v4 is canonical;
- README paths resolve;
- current docs describe actual runtime;
- historical docs cannot be mistaken for instruction;
- open issues map to current tasks;
- no “production ready” without evidence.

## Anything else?

The documentation volume is already high. The solution is not more undifferentiated documents; it is current-versus-historical authority.
