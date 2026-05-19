# Lockfile SOP (Standard Operating Procedure)

Use this SOP when deciding whether lockfiles should be tracked.

## Default Rule

Track lockfiles in application and deployable service repos.

Rationale:
- Reproducible installs across machines and CI
- Reduced dependency drift and "works on my machine" issues
- Safer incident/debug rollback behavior

## Common Defaults by Ecosystem

- npm: `package-lock.json` -> tracked
- pnpm: `pnpm-lock.yaml` -> tracked
- Yarn: `yarn.lock` -> tracked
- Dart/Flutter apps: `pubspec.lock` -> tracked for apps (libraries may choose not to)

## When It Is Acceptable to Not Track

Only if there is an explicit, documented team policy and CI flow that intentionally regenerates dependencies.

If lockfiles are untracked by policy:
- Document policy in repo docs
- Enforce exact install command/version pinning in CI
- Expect higher drift risk

## Audit Decision Rule

1. Check for explicit repo policy in docs/instructions.
2. If policy exists, follow it.
3. If policy does not exist, default to tracking lockfiles.
4. Never silently untrack a lockfile without explicit policy confirmation.
