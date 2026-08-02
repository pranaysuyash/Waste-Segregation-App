# Release Evidence

> **RELEASE-PROOF-01**: No "production ready" claim exists without corresponding release evidence.

Every release candidate produces a machine-generatable evidence file at:

```
docs/release/evidence/<version>/<sha>/RELEASE_EVIDENCE.md
```

The file is produced by `tools/generate_release_evidence.sh` (Commit 7 of the
release-proof task) and captures the inputs, outputs and rollback path for a
given commit so that a future reader (or auditor) can verify:

- which commit was shipped;
- which workflow runs produced it;
- which tool versions built it;
- which configuration produced the binaries;
- how many tests ran and how many failed;
- what the eval report said (including AI safety counts);
- the checksums of the shipped artefacts;
- the deployed Functions/rules versions;
- how to roll back.

## Why

The August 2026 remote review found: "no combined GitHub status on current
head; no associated workflow run visible; no release build or staging smoke
evidence." Without this file, a "production ready" statement is an
unverifiable claim. This directory is the place those claims get proved.

## How to generate

```bash
# From a clean checkout at the tagged commit:
tools/generate_release_evidence.sh 0.9.0
# Optionally pass an explicit SHA:
tools/generate_release_evidence.sh 0.9.0 e48a66bd6c9116e939a3eddfa5cc48c5d2171e6a
```

The script is safe to re-run; it overwrites the evidence file for the same
version/SHA. Commit the generated file with the release.

## Structure of RELEASE_EVIDENCE.md

| Section | Contents |
|---|---|
| Release | version tag, commit SHA, timestamp |
| Toolchain | Flutter/Dart/Node versions, config hashes |
| CI | workflow/run IDs for analyze, test, functions, rules, eval, release |
| Tests | total, passed, failed, skipped counts |
| Eval | golden case count, best strict rate, safety_failures, must_not_violations |
| Artefacts | paths and SHA-256 checksums of APK/AAB/web/iOS outputs |
| Deployed | Functions version, rules deployment, hosting config |
| Smoke | staging smoke checklist status (from Commit 6) |
| Known exceptions | any accepted deviations and why |
| Rollback | exact commands to restore the previous release |

## Rules

1. Never claim "production ready" without a committed evidence file in this
   directory for the exact version + SHA.
2. The script reads facts from the environment/workflow (not from memory);
   where a fact is unavailable it writes `UNVERIFIED` rather than a guess.
3. CI is the canonical producer: the release workflow runs the generator as
   its final step and uploads the file as an artefact.

## Known exceptions (deferred from the release-proof task)

These spec items are **not yet implemented** and must stay visible until they
land. They are tracked here so no one assumes they are covered.

| Spec item | Status | Where it will land |
|---|---|---|
| Commit 3 — rules/schema gate: society-path + protected-field rules tests | Not yet added | Task 04 (authorisation) adds the rules tests; this job already runs them via `npm --prefix firestore-rules-test run test:all:emulator` |
| Commit 5 — unsigned iOS build/archive in `release.yml` | Not yet added | Add a macOS runner job to `release.yml` (unsigned `flutter build ios --no-codesign` + archive) |
| Commit 6 — staging deployment + 10-step smoke checklist | Not yet added | Requires separate dev/staging/prod Firebase projects and deploy credentials; scaffold exists in this doc, deploy is manual |
| Commit 4 — eval gate extras (schema-validity %, class-specific regression limits, unknown/abstain rate bounds, taxonomy-versioned report) | Partial — safety hard gates + aggregate regression live in `tools/check_eval_gate.py`; the extended bounds are not | Extend `tools/check_eval_gate.py` with the additional bounds and a `report_version` field |

Until each row lands, the relevant line in `RELEASE_EVIDENCE.md` will read
`UNVERIFIED`, which is the honest default.
