# Model/Prompt/Ruleset Registry

**Status**: Seed — concept only, no implementation
**Priority**: 🔴 (P1 — gates model changes, rollouts, and audits)
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — P1/P2 Technical Architecture (topic 85)
**Related**: [AI_DRIFT_MONITORING.md](AI_DRIFT_MONITORING.md), [EVAL_LEADERBOARD_AND_MODEL_CARDS.md](EVAL_LEADERBOARD_AND_MODEL_CARDS.md), [LABEL_ONTOLOGY_GOVERNANCE.md](LABEL_ONTOLOGY_GOVERNANCE.md), [REMOTE_CONFIG_AND_KILL_SWITCHES.md](REMOTE_CONFIG_AND_KILL_SWITCHES.md)

---

## Overview

A canonical registry for every versioned artifact in the AI stack: model versions, prompt templates, city rulesets, router policies, and their active rollout state.

Without this registry:
- "What model was running when this misclassification happened?" is unanswerable
- Rollbacks are manual and error-prone
- Eval results can't be linked to the exact artifacts they tested
- Audit trail for safety incidents is incomplete

---

## What the Registry Tracks

### 1. Model Versions

| Field | Type | Example |
|-------|------|---------|
| `model_id` | string | `gemini-flash-2-0` |
| `version` | semver | `1.2.0` |
| `provider` | enum | `openai`, `gemini`, `anthropic`, `ondevice` |
| `eval_snapshot_id` | string ref | links to eval leaderboard snapshot |
| `training_data_version` | string | `td_v3` (for fine-tuned models) |
| `rollout_state` | enum | `dev`, `staging`, `canary`, `production`, `deprecated`, `retired` |
| `rollout_percentage` | float | `0.05` (for canary) |
| `rollback_target` | string ref | previous stable version URI |
| `owner` | string | team or individual |
| `deployed_at` | timestamp | when this version went live |
| `signature` | string | hash/checksum for supply chain integrity |

### 2. Prompt Versions

| Field | Type | Example |
|-------|------|---------|
| `prompt_id` | string | `classification_system_prompt_v4` |
| `version` | int | `4` |
| `hash` | string | SHA256 of the prompt text |
| `model_target` | string ref | which model(s) this prompt is designed for |
| `eval_snapshot_id` | string ref | eval results for this prompt+model combination |
| `author` | string | who last edited |
| `changelog` | string | "Added safety-critical category handling for hazardous waste" |

### 3. Ruleset Versions

| Field | Type | Example |
|-------|------|---------|
| `ruleset_id` | string | `bbmp_v3`, `city_policy_global_v2` |
| `version` | int | `3` |
| `effective_date` | date | when the rules take effect |
| `expiry_date` | date | optional — for temporary regulations |
| `source` | string | "BBMP official notification 2025-08" |
| `city_targets` | string[] | list of city IDs this applies to |
| `rollout_state` | enum | same state machine as models |

### 4. Router Policy Versions

| Field | Type | Example |
|-------|------|---------|
| `policy_id` | string | `production_router_policy_v3` |
| `version` | int | `3` |
| `escalation_rules` | JSON | confidence thresholds per layer and category |
| `provider_priority` | string[] | e.g., `["ondevice", "gemini_flash", "openai"]` |
| `safety_overrides` | JSON | categories that always escalate |
| `eval_snapshot_id` | string ref | overall policy evaluation |

---

## Rollout State Machine

```
                          ┌──────────┐
                          │   DEV    │  (internal testing)
                          └────┬─────┘
                               │
                          ┌────▼─────┐
                          │  STAGING  │  (dogfood, internal users)
                          └────┬─────┘
                               │
                          ┌────▼─────┐
                          │  CANARY   │  (1-5% of live users)
                          └────┬─────┘
                               │
                    ┌──────────┼──────────┐
                    ▼          ▼          ▼
              ┌──────────┐ ┌──────────┐ ┌──────────┐
              │PRODUCTION│ │ ROLLBACK │ │  KILLED  │
              │(full)    │ │(auto to  │ │(manual)  │
              └────┬─────┘ │ previous)│ └──────────┘
                   │       └──────────┘
                   ▼
              ┌──────────┐
              │DEPRECATED│
              └────┬─────┘
                   │
              ┌────▼─────┐
              │  RETIRED  │
              └──────────┘
```

**State transitions**:
- DEV → STAGING: manual approval + surface-level eval pass
- STAGING → CANARY: safety gate pass + accuracy gate pass
- CANARY → PRODUCTION: canary duration met + no regression in key metrics
- Any → KILLED: manual kill switch (emergency)
- CANARY → ROLLBACK: auto if hard threshold breached
- PRODUCTION → DEPRECATED: new version promoted to production
- DEPRECATED → RETIRED: after N days with no active users on this version

---

## Implementation Lightweight Approach

**Firebase Remote Config** can serve as the active version registry at runtime:

```json
{
  "active_model_version": "gemini_flash_2_0_v1.2.0",
  "active_prompt_version": "classification_system_prompt_v4",
  "active_ruleset_version": "bbmp_v3",
  "active_policy_version": "production_router_policy_v3",
  "rollout_override": null,
  "kill_switch": false
}
```

Full version history and metadata live in Firestore (separate collection). FRC points to the active version; Firestore stores the full artifact trail.

**Firestore schema**:
```
registries/
  models/{model_id}/
    versions/{version}/
      metadata, eval links, rollout history
  prompts/{prompt_id}/
    versions/{version}/
      prompt text, hash, changelog
  rulesets/{ruleset_id}/
    versions/{version}/
      rules JSON, effective dates, source
  policies/{policy_id}/
    versions/{version}/
      policy JSON, eval snapshot
```

---

## Audit Trail

Every state transition emits an event:

```json
{
  "event_type": "model_promoted",
  "artifact_type": "model",
  "artifact_id": "gemini_flash_2_0",
  "from_state": "staging",
  "to_state": "canary",
  "version": "1.2.0",
  "actor": "system (eval gate passed)",
  "timestamp": "...",
  "eval_snapshot_id": "..."
}
```

Events stored in `registries/audit_log/{artifact_type}/{artifact_id}` — append-only, never mutated.

---

## Rollback Automation

**Trigger conditions** for auto-rollback:
- Accuracy drop >5% on latest eval snapshot compared to previous version
- Safety-critical category failure rate >0.5%
- User correction rate spike >20% above 7-day moving average
- Provider error rate >2% for canary segment
- Cost per classification >200% of estimated budget

**Rollback action**:
1. FRC key `active_model_version` reverted to previous stable version
2. Incident event logged in audit trail
3. On-call notified via PagerDuty/slack
4. Canary automatically scaled to 0%

---

## Open Questions

- Should the registry be a separate microservice or a Firestore collection + FRC overlay?
- How long should retired versions be retained in the registry (audit requirement)?
- Who has permission to promote versions through the state machine?
- Should prompt versions be git-backed (source of truth in repo, synced to registry) or registry-first?
- How do we handle model versioning when the provider doesn't expose versions (e.g., OpenAI model aliases like `gpt-4o` that silently update)?
