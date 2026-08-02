> **Review baseline:** `pranaysuyash/Waste-Segregation-App`, branch `main`, commit `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Remote commit date:** 2026-05-25
>
> **Review date:** 2026-08-02
>
> **Hard limitation:** This review does not include local, uncommitted, or unpushed work. Run `02_TASK_LOCAL_CHANGE_RECONCILIATION.md` before implementing any other task. Existing local work is authoritative where it is newer and intentional.

# Task: Reconcile Local and Unpushed Changes

## Priority

P0. Mandatory first task.

## Objective

Create an accurate working baseline that combines this remote review with the newer local changes, without losing or overwriting any local work.

## Why this task exists

The reviewed remote commit is more than two months old. The user explicitly stated that incoming changes exist locally and are not pushed. Every later task may be invalid, already resolved or in conflict with that work.

## Non-goals

- Do not refactor.
- Do not fix findings.
- Do not delete or reset files.
- Do not run `git clean`, `git reset --hard`, forced checkout, rebase or any destructive command.
- Do not auto-format the entire repository.

## Required preflight

Read:

- `motto_v2.md`
- repository-level `AGENTS.md` if the local workspace contains one;
- any parent-directory `AGENTS.md`;
- `docs/.AGENT_INSTRUCTIONS.md`;
- this entire task file.

## Procedure

### 1. Capture repository state

Run and save output:

```bash
git rev-parse --show-toplevel
git status --short --branch
git branch --show-current
git rev-parse HEAD
git log --oneline --decorate -30
git remote -v
git diff --stat
git diff --cached --stat
git ls-files --others --exclude-standard
```

Create:

`docs/review/LOCAL_REMOTE_RECONCILIATION_2026-08-02.md`

### 2. Preserve the current state

Without modifying tracked files:

- produce a patch of unstaged changes;
- produce a patch of staged changes;
- list untracked files with size and likely purpose;
- record local-only commits;
- identify generated files and secrets that must not be committed.

Suggested commands:

```bash
mkdir -p .local-review-snapshots
git diff > .local-review-snapshots/unstaged.patch
git diff --cached > .local-review-snapshots/staged.patch
git log --oneline main..HEAD > .local-review-snapshots/local-commits.txt
```

Do not commit `.local-review-snapshots/`. Add it to a local exclude if necessary:

```bash
printf "\n.local-review-snapshots/\n" >> .git/info/exclude
```

### 3. Compare against the reviewed remote SHA

Use:

```bash
git diff --name-status d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171..HEAD
git diff --stat d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171..HEAD
```

Also inspect uncommitted changes relative to `HEAD`.

### 4. Classify every review finding

For each finding in `00_REMOTE_BASELINE_REVIEW.md`, assign:

- `still_present`
- `partially_addressed`
- `resolved_locally`
- `changed_direction`
- `cannot_verify`
- `new_conflict`

Required high-risk checks:

- Firestore billing-field protection;
- subscription verification;
- Dodo webhook idempotency;
- external billing policy integration;
- R2 controls;
- SWM 2026 taxonomy;
- real-image eval data;
- CI backend testing;
- premium placeholder claims;
- duplicate AI orchestration;
- canonical documentation paths.

### 5. Produce a conflict-safe execution map

For each later task, record:

- files already modified locally;
- local intent inferred from changes;
- whether another agent may touch those files;
- merge sequence;
- whether the task should be rewritten.

## Required output format

`LOCAL_REMOTE_RECONCILIATION_2026-08-02.md` must contain:

1. baseline SHAs;
2. branch and worktree state;
3. local-only commits;
4. staged/unstaged/untracked inventory;
5. secrets and generated-file risks;
6. finding-by-finding status table;
7. file ownership conflicts;
8. revised execution order;
9. explicit statement that no local work was discarded.

## Acceptance criteria

- Every changed and untracked file is accounted for.
- Patches exist outside the tracked source tree.
- No destructive Git operation was used.
- Each P0 finding has a local-status verdict with evidence.
- The remaining task files are annotated or amended where local changes supersede them.
- The user can review the delta report before implementation begins.

## Handoff

End with:

```markdown
## Safe next branches

| Task | Base commit | Files owned | Conflicts | Ready |
|---|---|---|---|---|
```

Do not begin another task in the same branch.
