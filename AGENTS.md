# Repo Agent Instructions (waste_segregation_app)

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
