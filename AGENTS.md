# Repo Agent Instructions (waste_segregation_app)

<!-- PROJECTS_MEMORY_AGENT_ALIGNMENT_BEGIN -->

## Projects-Level Agent Alignment (Workspace Memory)

**Purpose:** ensure any agent/LLM (Codex, Copilot, Claude Code, Qwen, GLM, etc.) starts aligned with the same workspace memory + project context.

### Step 0 (first time in this folder)
Generate the per-project context pack:
```bash
/Users/pranay/Projects/agent-start
```

### Step 1 (per shell)
Load the shared defaults for this project session:
```bash
source Docs/context/agent-start/STEP1_ENV.sh
# Or (no file read) print exports and eval:
/Users/pranay/Projects/agent-start --print-step1 --skip-index
```

### Step 2 (generate aligned context pack)
```bash
/Users/pranay/Projects/agent-start
```

Outputs:
- Canonical project-local pack:
  - `Docs/context/agent-start/SESSION_CONTEXT.md`
  - `Docs/context/agent-start/AGENT_KICKOFF_PROMPT.txt`
  - `Docs/context/agent-start/STEP1_ENV.sh`
- Compatibility mirrors when present:
  - `.agent/SESSION_CONTEXT.md`
  - `.agent/AGENT_KICKOFF_PROMPT.txt`
  - `.agent/STEP1_ENV.sh`
  - `frontend/docs/context/agent-start/*`

### Automation (already configured)
- Terminal auto-loads `Docs/context/agent-start/STEP1_ENV.sh` when you `cd` into a project under `/Users/pranay/Projects` (zsh hook).
- VS Code/Antigravity can run `agent-start --skip-index` on folder open via `.vscode/tasks.json`.

### How agents should use this
- Provide the canonical `Docs/context/agent-start/AGENT_KICKOFF_PROMPT.txt` and `Docs/context/agent-start/SESSION_CONTEXT.md` as the first context for the agent.
- If sources conflict, the agent must cite concrete file paths and ask before proceeding.
- If the canonical context pack is missing or stale, run `/Users/pranay/Projects/agent-start --skip-index` before planning changes.
- Treat `.agent/` files as compatibility mirrors only.
- Do not start implementation until `Docs/context/agent-start/AGENT_KICKOFF_PROMPT.txt` and `Docs/context/agent-start/SESSION_CONTEXT.md` are loaded.

### Mandatory agent operating mandate
- Begin every substantial task by refreshing ground truth: read the applicable instruction stack, repo-local `AGENTS.md`/`CLAUDE.md`, and any Qwen, Codex, Copilot, or other agent-specific instruction files relevant to the repo.
- Check the current codebase, docs, worklogs, and project status before planning or coding. Parallel agents may have changed files, decisions, or docs since the last session.
- Treat drift as normal: before editing and again before finalizing, re-check the files and docs you rely on, then adapt rather than assuming older context still holds.
- Use relevant skills and workflow guidance after checking the configured skill locations. Do not default to one toolset when a better domain skill exists.
- Think from first principles and optimize for long-term, scalable, architecturally sound solutions. Existing code is evidence, not a boundary; if current implementation no longer fits the product reality or architecture, propose or implement the proper path.
- Avoid building duplicate or parallel systems. Extend canonical routes, pipelines, validation, docs, and tools unless the project explicitly calls for a new replacement path.
- Git safety: read-only git inspection is allowed; no destructive commands, staging, commits, pushes, resets, or checkouts without explicit permission in the current conversation.
- Research online when facts may be current, external, or uncertain; cite sources when research affects decisions.
- Test changes, verify for regressions, and document findings, decisions, open questions, and follow-up work in durable project artifacts.

### Mandatory commit gate
Install or refresh the managed repo-local git hooks. They resolve the repo's effective hook path, block commit creation in `prepare-commit-msg` until the current full `motto_v3.md` has a fresh attestation, then enforce objective diff checks plus commit trailers in `pre-commit` and `commit-msg`:
```bash
python3 /Users/pranay/Projects/workspace_memory/scripts/install_git_precommit_agent_hook.py
```

Refresh the current repo's motto attestation before committing:
```bash
python3 /Users/pranay/Projects/workspace_memory/scripts/attest_motto.py --repo "$PWD"
```

### Shared Idea Pad Protocol (Required)
- Canonical file: `/Users/pranay/Projects/idea_pad/IDEA_PAD.md`
- Raw capture file: `/Users/pranay/Projects/idea_pad/IDEA_DUMP.md`
- Do not create per-model primary copies of the idea pad.
- Do not overwrite the whole file; use append/update workflow with validation.
- Capture rough ideas in `IDEA_DUMP.md`, then promote high-signal items into `IDEA_PAD.md`.
- Before edits:
```bash
python3 /Users/pranay/Projects/idea_pad/scripts/idea_pad_tool.py validate
```
- Add new ideas safely:
```bash
python3 /Users/pranay/Projects/idea_pad/scripts/idea_pad_tool.py add --title "<title>" --owner "<agent>" --type build
```
- After updates, refresh shared memory index:
```bash
cd /Users/pranay/Projects
./projects-memory index
```

<!-- PROJECTS_MEMORY_AGENT_ALIGNMENT_END -->


## Scope
This file applies to the repository root: /Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app

## Priority context
1. /Users/pranay/AGENTS.md
2. /Users/pranay/Projects/AGENTS.md
3. This file
4. motto_v2.md
5. firebase_task.md

If instructions conflict, use the most specific one and cite file paths.

## Execution rules
- Follow motto_v2.md execution discipline.
- Use firebase_task.md as the source-of-truth checklist for Phase/P0 tasks.
- Keep changes additive and architecture-safe; no temporary hacks in production paths.
- Document decisions and outcomes under docs/.

## Git safety
- Read-only git inspection allowed.
- Do not run destructive git operations.
- Do not stage/commit/push/reset/checkout without explicit user permission in current chat.

## Security and secrets
- Do not hardcode API keys or tokens.
- Prefer runtime env vars / secure config.
- If a secret is found in source, replace with placeholder and document migration.

## Verification minimum before completion
- Run relevant tests/validation commands for touched areas.
- Report remaining risks/blockers explicitly.
- Provide exact file paths for all new/updated artifacts.
