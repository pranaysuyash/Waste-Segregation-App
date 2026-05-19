---
name: gitignore-audit
description: 'Audit and fix Git ignore policy drift. Use when files that should be ignored appear in source control, when generated artifacts are staged, when backup/temp files leak into commits, or when you need a keep-vs-ignore decision with exact git rm --cached actions and verification checks.'
argument-hint: '[optional] docs policy, lockfile policy, and directories to protect (example: "docs tracked except .agent/context; keep golden masters")'
user-invocable: true
---

# Gitignore Audit & Cleanup

Create a reliable, evidence-first workflow to decide what should be tracked vs ignored, then apply minimal safe cleanup.

## When to Use

- Source control shows noisy generated files, backup files, temp files, logs, or local machine artifacts.
- `git rm --cached` behavior is confusing (staged `D` entries, files still on disk).
- Team needs consistent policy decisions (especially docs, golden tests, lockfiles, local scaffolding).
- You want a reusable, verifiable ignore audit process instead of one-off fixes.

## Inputs to Collect Up Front

- Repository policy defaults (if defined), especially docs handling and local scaffolding rules.
- Current `.gitignore` content.
- Any explicit user constraints, e.g.:
  - "Docs should always be tracked except `.agent` and `context/agent-start`."
  - "Do not keep backups/temp files on remote."
  - Lockfile preference per package manager and folder.
  - Whether `.kiro/` is local-only in this repo or intentionally versioned.

## Procedure

### 1) Inventory current Git state

Run an evidence pass:

1. Current status (`git status --short --untracked-files=all`)
2. Files currently tracked that match ignore rules (`git ls-files -ci --exclude-standard`)
3. Untracked files not ignored (`git ls-files -o --exclude-standard`)
4. Spot-check suspicious files with `git check-ignore -v <file>`

Outcome: three buckets with hard evidence.

### 2) Classify with decision rules

For each candidate file/path, classify as **TRACK** or **IGNORE**:

#### TRACK

- Product/source code, tests, and intentional fixtures.
- Documentation, unless explicitly local/session scaffolding.
- Golden masters intentionally versioned (e.g., `test/golden/golden/**`).

#### IGNORE

- Build outputs, generated code artifacts, temp files, logs.
- Local machine/session scaffolding (`.agent/`, `context/agent-start/`, etc. per policy).
- Backup and scratch files (`*.backup`, `*.bak`, `*.temp`, `temp/**`).
- Local-only DB/cache files (e.g., `*.hive`) if not intentionally versioned.

### 3) Resolve policy conflicts (branching)

- **If docs are disputed:** default to TRACK unless user policy explicitly excludes a docs subpath.
- **If golden images are disputed:** keep golden masters tracked; ignore generated diff/failure artifacts only.
- **If lockfiles are disputed:** apply [lockfile SOP](./references/lockfile-sop.md): follow explicit repo policy first; if absent, default to tracking lockfiles.
- **If `.kiro/` is disputed:** treat as optional; only ignore/untrack when user or repo policy marks it local-only.
- **If file is already tracked but should be ignored:** keep ignore rule + untrack via `git rm --cached`.

### 4) Apply minimal `.gitignore` changes

Only add rules for genuinely local/generated paths not already covered. Prefer explicit comments and narrow patterns.

Examples:

- Local addon files: `.gitignore_addon`
- Tool-specific local scaffolding: `.kiro/` (only if policy says local-only)

Avoid broad rules that unintentionally hide real source/docs.

### 5) Untrack leaked files safely

For files that should be ignored but are already tracked:

- Use `git rm --cached <file>` (or `-r --cached <dir>`)
- Do **not** delete working-copy files unless explicitly requested

Remember: staged `D` after `git rm --cached` means "removed from index", not "deleted from disk".

### 6) Verify completion gates

Run all gates before declaring done:

1. `git ls-files -ci --exclude-standard` returns only intentionally tracked exceptions (ideally none).
2. `git check-ignore -v` confirms new rules match expected local files.
3. `git status --short` shows expected staged deletions for untracking and expected `.gitignore` edits.
4. No unexpected docs/source files moved into ignored state.

## Quality Criteria (Definition of Done)

- Evidence-based keep-vs-ignore decisions documented.
- `.gitignore` changes are minimal, scoped, and commented.
- All tracked files that violate ignore policy are untracked from index.
- Documentation policy is preserved explicitly.
- Verification commands demonstrate clean, predictable behavior.

## Common Explanations to Provide

- Why `git rm --cached` shows staged `D` entries.
- Why ignored files may disappear from source-control views after commit.
- Why broad patterns (e.g., `test/golden/**`) are dangerous when golden masters are intended to be versioned.

## Suggested Invocation Prompts

- "/gitignore-audit: clean up tracked generated files but keep docs tracked"
- "/gitignore-audit docs tracked except .agent/context; remove backup/temp artifacts from remote"
- "/gitignore-audit explain staged deletions after git rm --cached and finish cleanup"
