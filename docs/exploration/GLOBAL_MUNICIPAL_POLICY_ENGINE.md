# Global Municipal Policy Engine

Date: 2026-05-21
Status: Active Build Track
Scope: Global policy-pack architecture for municipal disposal correctness.

## Why This Exists

Classification answers "what is this?".
Policy answers "what should be done here, under this jurisdiction?".

To become the best waste app globally, policy cannot be a local hardcoded side-path. It must be a first-class, auditable, versioned platform surface.

## Current Architecture Anchors

- `lib/services/local_policy_engine.dart`
- `lib/services/local_policy_rule_packs.dart`
- `lib/services/local_guidelines_plugin.dart`
- `lib/services/ai_service.dart`

Current state includes:

- canonical policy evaluation/apply path
- rule-pack registry abstraction
- multi-city plugin scaffolds (BBMP/BMC/MCD)
- policy provenance attached to classification metadata

## Policy Pack Contract

Each policy pack must declare:

1. `rulePackId` (`pluginId:guidelinesVersion`)
2. `pluginId`
3. `authorityName`
4. `region`
5. `guidelinesVersion`
6. `governanceStage` (`draft`, `pilot`, `production`)
7. `owningTeam`
8. `rules[]`

Each rule must declare:

1. `ruleId`
2. `categoryKey`
3. `severity` (`warning`/`violation`)
4. `checkType`
5. `message`
6. optional `targetValue`

## Governance Lifecycle

Policy packs move through stages:

1. `draft`
- authored with citations and local authority mapping
- tested in synthetic scenarios
- hidden behind non-production routing

2. `pilot`
- active in limited city population / controlled cohorts
- monitored for false-positive and false-negative rates
- weekly review with policy ops

3. `production`
- full traffic eligibility
- rollback target documented
- telemetry + audit trail mandatory

## Promotion Gates

A pack can be promoted only if all pass:

1. Rule coverage tests (category-by-category)
2. Compliance regression suite pass
3. No unresolved severe false-positive class
4. Provenance fields present in decision metadata
5. Rollback strategy validated (`previous stable pack`)

## Rollback Rules

Any pack can be rolled back if:

- policy false-positive rate breaches threshold
- severe jurisdiction mismatch is detected
- authority update invalidates current rule set

Rollback action:

- switch to last known stable pack
- mark incident in audit timeline
- emit policy rollback telemetry event

## Global Rollout Strategy

Phase 1: India metro core

- Bangalore (production baseline)
- Mumbai (pilot)
- Delhi (pilot)

Phase 2: India expansion

- Tier-2 city templates + authority adaptation kit
- localized aliases and terminology packs

Phase 3: International expansion

- jurisdiction onboarding playbook
- translation/legal compliance adaptations
- regional policy QA harness

## Open Questions

1. Should policy packs be loaded from static app bundles, remote config, or signed backend payloads?
2. Who is final approver for promotion to `production` by jurisdiction?
3. What is acceptable false-positive budget for policy warnings by category?
4. How do we expose policy uncertainty to users without eroding trust?

## Near-Term Execution (Now)

1. Fill BMC and MCD packs with first real rule sets and tests.
2. Add pack-level provenance card in result UI.
3. Add pack-stage telemetry and rollback controls.
4. Introduce pack source-of-truth validation script under `tools/`.
