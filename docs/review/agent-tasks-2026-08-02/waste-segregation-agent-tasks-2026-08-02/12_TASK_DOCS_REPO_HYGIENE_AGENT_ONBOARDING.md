> **Review baseline:** `pranaysuyash/Waste-Segregation-App`, branch `main`, commit `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Remote commit date:** 2026-05-25
>
> **Review date:** 2026-08-02
>
> **Hard limitation:** This review does not include local, uncommitted, or unpushed work. Run `02_TASK_LOCAL_CHANGE_RECONCILIATION.md` before implementing any other task. Existing local work is authoritative where it is newer and intentional.

# Task: Documentation, Repository Hygiene and Agent Onboarding

## Priority

P1, with a small P0 prerequisite to avoid agent errors.

## Objective

Establish one navigable source of truth, repair broken mandatory paths, and make issue/document status reflect current code.

## Findings

- `docs/.AGENT_INSTRUCTIONS.md` points to `docs/APP_KNOWLEDGE_BASE.md`; the remote canonical file is under `docs/reference/`.
- It also points to a current-issues file that is not present at the expected path.
- Root and docs READMEs contain conflicting versions and production-readiness claims.
- Many historical reports are mixed with current instructions.
- Generated TODO issues remain open even when code has changed.
- The repository contains broad audit/grep artefacts that obscure current decisions.

## Target information architecture

```text
/
  AGENTS.md
  README.md
  docs/
    README.md
    current/
      PRODUCT.md
      ARCHITECTURE.md
      SECURITY.md
      DATA_MODEL.md
      BILLING.md
      AI_POLICY.md
      RELEASE_STATUS.md
      KNOWN_ISSUES.md
    adr/
    tasks/
    release/
    research/
    archive/
```

The exact layout may adapt to local changes, but there must be one current layer and an explicit archive.

## Work breakdown

### T1. Create root `AGENTS.md`

It must state:

- required reading order;
- local-work preservation rules;
- canonical current docs;
- test commands;
- branch/file ownership protocol;
- definition of done;
- prohibited claims;
- how to update task status.

Do not duplicate all documentation inside it.

### T2. Repair canonical paths

Choose either to move the knowledge base or update every reference. Do not leave aliases that silently diverge.

Add a link checker for mandatory files.

### T3. Rewrite root README

Root README should answer:

- what the product is now;
- supported platforms;
- current release status;
- quick start;
- architecture summary;
- required configuration;
- testing;
- security warning;
- links to current docs.

Remove historical changelogs and repeated “production-ready” claims from the README.

### T4. Establish document status headers

Every substantial document must contain:

```yaml
status: current | proposed | historical | superseded
owner:
last_verified:
supersedes:
superseded_by:
scope:
```

Archive documents are evidence, not instructions.

### T5. Reconcile issues

For each open issue:

- verify whether the problem still exists;
- close implemented or obsolete generated TODOs;
- merge duplicates;
- rewrite vague issues with acceptance criteria;
- label by `P0/P1/P2/P3`, domain and status;
- link active issues to task files.

Do not retain hundreds of open issues as a substitute for prioritisation.

### T6. Remove repository noise

Review:

- generated grep dumps;
- raw TODO exports;
- temporary audit files;
- local paths;
- obsolete screenshots/build artifacts;
- commented dependency plans;
- duplicate READMEs.

Move necessary historical evidence to archive; delete only after local reconciliation and explicit review.

### T7. Add docs CI

Validate:

- Markdown links;
- required files;
- duplicate canonical titles;
- status headers;
- version references;
- forbidden “production-ready” claim unless release evidence exists;
- generated-file policy.

Do not fail merely because the word TODO exists. Fail on unmanaged TODO format or broken task linkage.

## Acceptance criteria

- A new agent can find the current product, architecture, known issues and tests in under five minutes.
- Mandatory paths exist and are checked in CI.
- One current document exists per core domain.
- Historical content cannot be mistaken for current instructions.
- Open issues represent real remaining work.
- README version/status matches the build.
- No local absolute path is presented as a repository path.
