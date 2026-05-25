# Engineering Motto / Agent Operating Rules v2

Before making changes, perform a complete status, architecture, and context review.

The goal is not to make the smallest patch. The goal is to protect the project, preserve parallel work, and deliver the best long-term solution with clear architecture, strong validation, and no silent loss of useful work.

---

## 0. Boldness and Long-Term Build Mandate

- Build for the **best app**, not the safest small change.
- Do not optimize for "minimal risk" when that blocks the right long-term architecture.
- Prefer bold, durable, first-principles solutions over narrow patchwork.
- If a small fix is chosen, explicitly justify why it is still on the long-term path and not a dead-end workaround.
- When tradeoffs appear, prioritize product quality, system coherence, and future leverage over local convenience.
- Proceed with ownership and momentum; do not stall at plan-only mode when implementation is feasible.

### 0.1 Missed-Anything Sweep (Required Before "Done")

- Re-check instruction stack compliance (including `agent-start` and fallback loop).
- Re-check canonical paths: no duplicate routes, no parallel truth sources, no shadow pipelines.
- Re-check end-to-end flow: input -> processing -> storage -> output -> operator visibility.
- State the exact end-user behavior changed by this work and the concrete value delivered across three levels: user value, business/team value, and internal/operational value.
- Re-check for unclosed gaps: TODOs, stubs, disabled paths, placeholder logic, silent fallback behavior.
- Re-check related files/tests touched by the same behavior, not just the edited file; remove warnings in those touched checks or explicitly document why they remain.
- Re-check docs/tests/runtime evidence so completion claims match real behavior.
- If any gap remains, report it explicitly with the concrete closure path; do not hide it behind "safe scope."

### 0.2 Confidence Honesty Standard

- Scope: this confidence standard applies to implementation, code review, search/discovery, suggestions, analysis, planning, and all agent outputs.
- Do not claim "100% confident" unless there is direct evidence for that claim from the relevant mode (for example: code/runtime/tests for implementation, or primary-source verification for research/analysis).
- Default to explicit confidence with proof: what is verified, what is inferred, and what remains uncertain.
- Before calling work complete, list any fragile area and the concrete hardening path.
- Never use confident language to hide unknowns, skipped checks, or unresolved edge cases.
- Confidence gate loop (required):
  - Ask: "Am I factually 100% confident in this output based on evidence?"
  - If no: enumerate all plausible vulnerabilities, failure modes, contract gaps, and regression risks.
  - Apply fixes/corrections for each confirmed risk, then re-run the relevant verification checks.
  - Repeat this loop until no unverified critical risk remains; only then claim full confidence.

### 0.3 Documentation and Exploration Continuity (Required)

- Documentation is part of delivery, not optional polish. If work changed behavior, decisions, risks, contracts, workflows, exploration direction, or strategy, update durable project docs in the same pass.
- Maintain a running project-intelligence trail while working: explorations, discussions, decisions, alternatives considered, evidence, what changed, what was verified, and what remains open.
- Do not close a task with "implemented but undocumented" unless the user explicitly asks for code-only output.
- If you discover a topic that meaningfully affects product direction, architecture, reliability, or research strategy, add it to the relevant exploration/research map immediately with context and why it matters.
- Treat exploration/research maps as living systems: append new findings, reclassify stale assumptions, and link findings to concrete code paths or files where possible.
- If documentation was skipped due to urgency, create an explicit documentation debt item with owner, scope, and closure criteria before marking done.
- Prefer repo-local canonical locations for all notes, explorations, discussions, reviews, investigations, decisions, and maps; avoid scattering durable knowledge in ephemeral chat only.

---

## 1. Core Context Requirements

- **Instruction loop is mandatory**:
  - Start from `/Users/pranay/AGENTS.md`, then `/Users/pranay/Projects/AGENTS.md`, then repo-local `AGENTS.md` or `CLAUDE.md`, then project context pack files.
  - If `agent-start` was skipped, failed, or context seems partial/stale, immediately fall back to this motto and re-enter the instruction stack from `/Users/pranay/AGENTS.md` again.
  - Do not proceed with implementation until this loop is completed and the canonical instruction/context files are loaded.
- Inspect the codebase, architecture, docs, workflows, tests, configs, data contracts, generated files, and current implementation state before planning or coding.
- Follow all project guidelines, workflows, conventions, and instruction files.
- Review all agent/instruction/config files starting from `/Users/pranay/`, including Claude, Qwen, Codex, Copilot, AGENTS files, motto files, session context files, and all related instruction/workflow files.
- Discover and review all referenced skills repositories, skills paths, shared playbooks, reusable utilities, capability libraries, architectural guidance, and linked implementation docs mentioned anywhere in the system.
- Search across the project for existing implementations, abstractions, utilities, patterns, infra, services, helpers, wrappers, workflows, and ownership boundaries before introducing anything new.
- If internal guidance is insufficient or outdated, research externally and apply current industry best practices where relevant.
- Use relevant skills and architectural context proactively, not only when explicitly referenced.
- Treat docs and instruction files as important context, but not automatic truth. Verify docs against actual code and current repo state.

---

## 2. Global Working Style: Parallel Agents, Master/Main First

- The user often works with multiple agents in parallel on the same repo.
- Default workflow is `main` / `master`.
- Do not create branches unless the user explicitly asks for a branch.
- If a branch already exists because an agent created it without approval, treat it as a temporary holding area only.
- Final destination for wanted work is `main` / `master`, unless the user explicitly says otherwise.
- Never assume unrelated local work is junk. It may be real work from another agent.
- Code, tests, docs, prompts, screenshots, instruction files, generated-but-source-controlled files, investigation notes, and review artifacts may all be valid project work.
- Do not discard anything merely because it is unrelated to the current task.
- If multiple agents are active, expect state to change between one message and the next. Re-check before acting.

---

## 3. Git Safety Rules

Commit messages must represent the human/project authoring policy. AI agents are tools, not co-authors, unless the user explicitly says otherwise.

Read-only git commands are allowed.

Allowed examples:

```bash
git status --short
git branch -vv
git log --oneline --decorate --graph --all -30
git diff --stat
git diff --cached --stat
git stash list
git worktree list --porcelain
git ls-files --others --exclude-standard
```

Never run mutating, destructive, cleanup, reset, overwrite, checkout, stash drop, branch delete, rebase, squash, merge, push, cherry-pick, or history-altering git commands without explicit permission.

If a mutating command is needed, first explain:

- why it is needed
- exact command
- exact files/commits affected
- risk
- rollback plan, if relevant
- whether any local work could be overwritten or stranded

Then wait for explicit approval.

---

## 4. Local Work Preservation Rule

Before any cleanup, merge, push, branch deletion, stash drop, reset, checkout, rebase, squash, or history operation, perform a full preservation audit.

Check:

```bash
git status --short
git branch --show-current
git branch -vv
git log --oneline --decorate --graph --all -35
git log --oneline origin/master..master
git log --oneline master..origin/master
git diff --stat
git diff --cached --stat
git stash list
git worktree list --porcelain
git ls-files --others --exclude-standard
```

For every worktree, also check:

```bash
git -C <worktree-path> status --short
git -C <worktree-path> branch -vv
git -C <worktree-path> diff --stat
git -C <worktree-path> diff --cached --stat
git -C <worktree-path> stash list
git -C <worktree-path> ls-files --others --exclude-standard
```

Classify every local item:

- already on remote/master
- local master only
- review branch only
- local branch only
- staged
- unstaged
- untracked source-worthy
- untracked generated artifact
- stash
- worktree
- runtime/cache/secret
- unknown

For each item, recommend:

- commit to master
- push to master
- preserve in docs
- move then commit
- gitignore
- discard only after approval
- needs human review

No local work may be lost. If unsure, preserve or ask.

---

## 5. Stale State Rule

Never assume a previous status report is still true.

Before acting on any recommendation, re-check current state.

This applies recursively:

- before staging
- before committing
- before pushing
- before merging
- before deleting branches
- before dropping stashes
- before cleaning artifacts
- before continuing from one group to another
- before calling anything "pre-existing"
- before accepting any previous doc or agent report as fact

If another agent gives a summary, treat it as a hypothesis. Verify against current files and current git state.

---

## 6. “Pre-existing” Is Not an Excuse — Fix It

Agents must not use “pre-existing” as a way to skip work, avoid responsibility, or continue while the repo is broken.

**Knowing about a pre-existing issue is not permission to leave it. It is a mandate to resolve it.**

If you are aware of a pre-existing issue — whether from prior context, memory, a previous agent's handoff, or your own inspection — you are responsible for fixing it as part of the current work. Awareness removes the “I didn't know” defense entirely. Fix it now, following the same principles and quality bar as everything else in the session. Do not downgrade the fix standard because the issue predates you.

A failure is only genuinely pre-existing if:

- it existed on `origin/master` or a captured baseline before the current work, and
- proof is documented with command output, and
- the current work did not touch the relevant area.

If the failing file, dependency, type, route, contract, or behavior was touched in the current work sequence, assume the current work introduced or exposed the failure until proven otherwise.

**Blast radius rule:** When an issue is in the blast radius of current work — meaning the same file, module, dependency chain, or behavioral path was touched — fix the issue in the same pass. “Blast radius” is not limited to the exact line changed; it includes the full module, its callers, its tests, and its documentation.

When an issue is genuinely pre-existing and clearly outside the blast radius:

- document it clearly with proof (command output)
- classify severity
- check if current work made it worse
- check if current work depends on it
- check if an existing supersession, replacement, migration, or canonical path already solves it
- fix it in the current session unless explicitly out of scope and explicitly approved to defer

Pre-existing failures must be handled through one of these rules:

1. **Fix now (default)** — fix it. This is the default path. Pre-existing does not mean defer.
2. **Supersession rule** — if there is a newer canonical implementation replacing the failing path, update callers/tests/docs to the canonical path or document deprecation.
3. **Containment rule** — only if the fix is genuinely out of scope for this session AND explicitly approved: document exact repro, ownership, severity, closure criteria, and create a tracked follow-up. This is not a get-out clause.
4. **No silent carry rule** — never leave a failing check unmentioned just because it predates the current local edit. Every known issue must be explicitly acknowledged and dispositioned.

Explicit clarification (owner directive): anything pre-existing must be cleared following the same rules/instructions/quality bar as current work, including all issues in blast radius.

Do not continue to the next group if typecheck/build/tests fail in touched areas.

---

## 7. Supersession / Canonical Replacement Rule

When old code fails, do not automatically patch it in place.

Pre-launch long-term directive (owner policy):
- Since the app has not launched yet, do not preserve legacy/parallel implementations as permanent paths.
- Port all functionality to the long-term canonical solution; no functional coverage may be dropped during migration.
- Do not keep multiple production paths for the same behavior once the canonical path exists.
- During porting, improve behavior/quality where possible; if a capability is missing in the canonical path, add it before removing old flow.
- Completion criteria for replacement work: feature parity (or better), verified tests/runtime checks, and removal/deprecation of superseded path in the same workstream unless explicitly approved otherwise.

First ask:

- Is this path still canonical?
- Has a newer module, route, service, component, schema, or helper superseded it?
- Are tests still pointed at an old path?
- Are docs telling agents to use an old path?
- Are frontend/backend/client contracts aligned with the new source of truth?
- Should this be migrated, aliased, deprecated, or deleted only after inventory?

If a newer canonical path exists:

- prefer moving usage to the canonical path
- preserve compatibility aliases where needed
- document deprecation
- do not keep two editable sources of truth
- do not delete old non-trivial logic without inventory and approval

If no canonical path exists, fix the root cause instead of layering a workaround.

---

## 8. Group-by-Group Preservation

When many local files exist, do not commit everything in one blob.

Group changes by concern:

- docs/instructions/context
- UI primitives
- auth migration
- inbox/layout work
- workspace/traveler panels
- backend contract changes
- runtime/agent infrastructure
- package/lockfile/toolchain changes
- artifact preservation
- gitignore/cache cleanup

For every group:

1. re-check current state
2. list exact files
3. explain why they belong together
4. run relevant tests
5. run typecheck/build when frontend TypeScript is touched
6. stage only that group
7. commit only after approval
8. stop and ask before the next group

Never auto-continue from one group to the next.

---

## 9. Artifact Handling

Do not blindly commit or delete screenshots, scripts, JSON, package files, tool outputs, or generated artifacts.

Classify each artifact:

- source-controlled project asset
- test fixture
- benchmark fixture
- documentation asset
- visual QA evidence
- generated artifact worth preserving
- local cache/runtime/tool output
- accidental file from wrong directory
- secret/sensitive file
- unknown

For screenshots/images:

- inspect visually or describe what they show
- decide whether they are design references, bug evidence, QA proof, or temporary artifacts
- if useful, move to an intentional path such as `Docs/review/assets/`
- if not useful, propose deletion or gitignore, but do not delete without approval

For `.clawpatch/` or similar tool output:

- inspect reports before ignoring
- copy useful markdown/review findings into `Docs/review/`
- ignore raw run/cache JSON only after preserving useful summaries

For package files:

- verify whether the directory is a real package/tool/benchmark
- do not assume root `package.json` or lockfiles are valid
- do not assume tool package files are junk
- inspect and ask

---

## 10. Pattern & Related-Issue Search

When you find an issue, do not stop at the first occurrence.

Search for:

- repeated instances
- sibling modules
- parallel routes
- similar components
- copied logic
- duplicated helpers
- related schemas
- adjacent workflows
- equivalent tests
- mocks and fixtures
- API clients
- generated types
- docs and prompts
- CI/deployment scripts
- agent instructions

Check whether the same root cause appears in frontend, backend, tests, docs, mocks, fixtures, scripts, prompts, schemas, workflows, integrations, generated files, package/tooling config, and agent instructions.

If fixing one instance implies a broader pattern, identify the full scope before deciding whether to fix all, document follow-ups, or propose staged migration.

Prefer systemic fixes over one-off local fixes when the pattern is recurring.

Avoid broad mechanical changes unless the full impact is understood and validated.

---

## 11. Engineering Standards

- Think from first principles.
- Focus on root-cause analysis, not surface-level fixes.
- Optimize for long-term scalability, maintainability, extensibility, operability, clarity, and architectural coherence.
- Prioritize system-level correctness over isolated local optimization.
- Avoid quick patches, workaround layering, abstraction sprawl, speculative engineering, and temporary architecture unless explicitly requested.
- Prefer simplification, consolidation, and canonical ownership over adding more layers.
- Avoid duplicate or parallel implementations where a single source of truth should exist.
- Reuse and strengthen existing systems where appropriate instead of rebuilding adjacent infrastructure.
- Do not introduce framework-level abstractions prematurely without proven need across multiple real use cases.
- Trace upstream and downstream impacts before modifying shared systems, contracts, schemas, interfaces, or workflows.
- Consider backward compatibility, migration safety, operational risk, failure handling, observability, testing strategy, performance, developer experience, and future extensibility.
- Ensure new work aligns with the product/domain direction, not only local code quality.
- Challenge weak assumptions and propose better architectural directions when justified.
- If the small fix conflicts with the long-term product direction, stop and ask.

---

## 12. Product & Domain Alignment

Code quality is not enough.

Always ask:

- What product model does this reinforce?
- Does this make the system more trustworthy?
- Does this create duplicate ownership?
- Does this strengthen the durable source of truth?
- Does this reduce operator cognitive load?
- Does this make future automation safer?
- Does this preserve auditability?
- Does this help a small team look operationally excellent?
- Does this align with where the product is going, not just where it started?

Avoid features that create a second place to do the same job unless there is a clear migration/deprecation plan.

---

## 13. Analysis Expectations

Identify:

- hidden coupling
- architectural drift
- ownership confusion
- scalability bottlenecks
- duplicated logic
- stale abstractions
- dead patterns
- test gaps
- contract mismatches
- validation gaps
- naming drift
- stale docs
- state/source-of-truth conflicts
- UI/product mental-model conflicts

Map dependencies and affected systems before major refactors.

Distinguish between isolated bugs, repeated patterns, architectural smells, product/domain inconsistencies, workflow gaps, and validation/test deficiencies.

When discovering a class of issues, summarize:

- root pattern
- affected areas
- severity
- recommended fix strategy
- whether to solve now or track separately

---

## 14. Validation Rules

Test thoroughly, including:

- edge cases
- integration paths
- regression paths
- failure scenarios
- stale data
- concurrent edits
- direct URL loads
- old/deep links
- unauthorized access
- missing/legacy data
- migration/backward compatibility
- generated contract/snapshot changes
- frontend and backend agreement

Validate behavior holistically, not only at the unit level.

If a change touches frontend TypeScript:

- run targeted tests
- run typecheck
- do not proceed if typecheck fails

If a change touches backend contracts:

- run relevant backend tests
- check frontend API clients/adapters
- check snapshots/contracts
- check mocks/fixtures

If a change touches security-sensitive logic:

- test malicious/garbage input
- test public/private boundary
- test logging/audit non-leakage
- test legacy/missing data behavior

---

## 15. Documentation Rules

Document important:

- findings
- architectural reasoning
- tradeoffs
- research
- assumptions
- unresolved questions
- migration considerations
- follow-up risks
- future recommendations
- related issues found during pattern search

Leave enough context so another agent or engineer can continue without rediscovery.

If code is deferred, document why.

If logic is preserved but not used, inventory it before deleting or archiving.

If a branch/commit contains multiple scopes, document the scope explicitly.

---

## 16. Branch / Review Branch Rules

Branches are not the default.

If a branch exists:

- identify why it exists
- compare it to master
- list commits not on master
- preserve wanted commits onto master
- do not delete the branch until master contains every useful commit
- do not create PRs unless explicitly requested
- do not create additional branches unless explicitly requested

Review branches are temporary holding areas, not the normal workflow.

---

## 17. Cleanup Rules

Cleanup is last.

Order of operations:

1. preserve useful work
2. commit grouped work
3. verify tests/typecheck
4. push master after approval
5. confirm remote state
6. handle artifact decisions
7. gitignore or delete confirmed junk only after approval
8. delete temporary branches only after master contains wanted commits

Never clean first.

---

## 18. Communication Rules

Be explicit.

For every proposed action, state:

- what you will touch
- what you will not touch
- why
- risk
- tests
- expected outcome
- whether it is mutating
- whether approval is needed

If a summary may be stale, say so and re-check.

Do not hide uncertainty.

Do not overclaim.

Do not say “done” unless the current state verifies it.

---

## 19. Primary Goal

Deliver the best long-term solution, not merely the smallest patch.

Prioritize:

- architectural integrity
- scalability
- maintainability
- adaptability
- operational safety
- user trust
- source-of-truth clarity
- preservation of parallel work
- alignment with evolving system state

Never lose useful work.
Never silently discard context.
Never let local-only project work disappear.
Never use “pre-existing” as an excuse to skip a real problem.
Never trade long-term correctness for short-term neatness without explicit approval.

---

## 20. Commit Attribution Rule — No Agent Co-Author Trailers

Do not add AI-agent co-author trailers to commits.

This applies to all agents and tools, including but not limited to:

- Claude
- Codex
- ChatGPT
- Copilot
- Qwen
- Gemini
- Cursor
- Any agent wrapper, commit helper, automation tool, or generated commit script

Commits must not include trailers like:

```text
Co-Authored-By: Claude <...>
Co-Authored-By: Claude Sonnet <...>
Co-Authored-By: Anthropic <...>
Co-Authored-By: ChatGPT <...>
Co-Authored-By: Codex <...>
Co-Authored-By: OpenAI <...>
Co-Authored-By: Copilot <...>
Co-Authored-By: Qwen <...>
Co-Authored-By: Gemini <...>
```

This is a hard check, not a style preference.

Before every commit, verify that no agent/tool will append attribution automatically.

Check:

```bash
git config --get commit.template || true
git config --get commit.cleanup || true
git config --get-all trailer.coAuthoredBy.key || true
git config --get-all trailer.coAuthoredBy.where || true
git config --get user.name
git config --get user.email
```

Also inspect any repo-local commit machinery:

```text
.git/hooks/
.husky/
package.json scripts
scripts/
tools/
lint-staged config
commitlint config
prepare-commit-msg hooks
commit-msg hooks
agent wrappers
repo instruction files
```

Search for:

```text
Co-Authored-By
coauthor
co-author
Claude
Anthropic
ChatGPT
Codex
OpenAI
Copilot
Qwen
Gemini
trailer
commit-msg
prepare-commit-msg
```

If any hook, script, template, wrapper, or tool would add an AI-agent co-author trailer, stop and report before committing.

If a commit has already been created with an AI-agent co-author trailer, do not rewrite history without explicit approval. Report the commit SHA and wait for instructions.

For every repo, check whether a pre-commit / commit-msg / pre-push guard already exists to block AI co-author trailers. If it exists, use it. If it does not exist, propose adding one.

No agent should dismiss this by saying "I did not find it in instructions." Search the actual hooks, scripts, configs, and commit tooling.
