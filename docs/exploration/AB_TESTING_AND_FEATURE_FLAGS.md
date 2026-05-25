# A/B Testing & Feature Flag Governance

**Status**: Exploration — not yet implemented as a governed system  
**Date**: 2026-05-25  
**Why this matters**: Without an experiment harness, "is this better?" is opinion. The infrastructure to *run* experiments exists; the discipline to *interpret* them doesn't. Feature flags without governance become a graveyard.

---

## 1. Current State

**What exists:**
- `lib/models/ab_testing_config.dart` — basic flag definitions
- `lib/providers/feature_flags_provider.dart` — Riverpod provider for flags
- `analyzeWithRace` already uses an A/B percentage in `EnhancedAiApiService`
- Firebase Remote Config is wired (`lib/services/remote_config_service.dart`)
- Firebase A/B Testing is available (Firebase project has it enabled)

**What's missing:**
- No experiment-design methodology docs
- No guardrail metrics defined
- No flag naming/lifecycle/cleanup discipline
- No automated halt conditions
- No minimum sample size policy

---

## 2. Experiment Design Methodology

### 2.1 Sample Size

For a startup with <100k MAU (likely 5–20k active), the constraint is statistical power.

| Effect size (MDE) | Required users per variant (α=0.05, β=0.80) | Feasibility |
|---|---|---|
| 20% relative | ~1,500 | ✅ Yes |
| 10% relative | ~5,500 | ✅ Likely |
| 5% relative | ~25,000 | 🟡 Borderline |
| 2% relative | ~150,000 | ❌ Not feasible |

**Policy**: Minimum detectable effect of 10% relative unless MAU exceeds 50k enrolled. Run for minimum 7 days (full weekly cycle) even if significance is reached earlier, to capture weekly seasonality patterns.

### 2.2 Primary Metrics by Experiment Type

| Experiment type | Primary metric | Guardrail metrics |
|---|---|---|
| Model/prompt change | Classification accuracy (eval score) | Correction rate, cost per classification, latency p95 |
| UI/UX change | Task completion rate, time-to-scan | Crash rate, user-correction rate, session length |
| Gamification change | D7/D30 retention | Notification opt-out rate, daily classification volume, support tickets |
| Pricing/premium change | Conversion rate | Uninstall rate, churn rate (existing premium), support volume |
| Onboarding change | Activation rate (first classification) | Drop-off at each step, time-to-activation |

### 2.3 Metric Definitions (Must Be Documented, Not Implicit)

Each metric needs a canonical definition:
- **"Activation"**: User completes ≥1 classification within first 7 days of install
- **"Retention D7"**: User returns and completes ≥1 classification 6–8 days after install
- **"Correction rate"**: classifications where user tapped "correct" / total classifications
- **"Cost per classification"**: total provider spend / total classifications (must include failure costs)

**Governance**: Any metric rename or redefinition must be documented in a schema changelog. Old definitions retained for querying historical data.

---

## 3. Guardrail Metrics & Auto-Halt

Every experiment must define guardrail metrics with **automated halt thresholds**:

### Technical Health Guardrails

| Metric | Auto-halt condition | Action |
|---|---|---|
| Crash-free session rate | Drop >1% from control | Halt immediately, roll back to control |
| Classification latency p95 | Increase >20% from control | Halt, investigate |
| AI cost per active user | Increase >15% from control | Halt, review cost model |
| API error rate (4xx/5xx) | Increase >3% from control | Halt, investigate |

### Business Health Guardrails

| Metric | Auto-halt condition | Action |
|---|---|---|
| Uninstall rate | Increase >10% from control | Halt, review |
| User correction rate | Increase >15% from control | Halt, review classification quality |
| Daily active classification count | Decrease >10% from control | Flag for review (may be intentional) |

### Implementation Pattern

```dart
// Guardrail check at experiment analysis time
class ExperimentGuardrail {
  final String experimentId;
  final MetricSnapshot baseline;
  final double haltThreshold; // relative change
  final VoidCallback haltAction; // rollback function
  
  bool shouldHalt(MetricSnapshot current) { ... }
}
```

---

## 4. Flag Naming, Lifecycle & Cleanup

### Naming Convention

```
<category>_<scope>_<feature>_<variant>
```

Examples:
- `model_routing_race_enabled_treatment`
- `gamification_challenge_completion_v2`
- `onboarding_gradual_takeover`
- `ui_scan_fab_persistent`
- `kill_switch_provider_openai`

**Categories**: `model_routing`, `gamification`, `onboarding`, `ui`, `pricing`, `safety`, `kill_switch`

### Lifecycle States

```
DRAFT → ACTIVE (with % rollout) → EVALUATING → PROMOTED (remove flag code) / KILLED (remove flag code)
```

**Cleanup policy**:
- Every flag must have a documented owner and sunset date at creation
- 30 days after 100% rollout or kill, the flag code must be removed
- Automated tracking through a flag registry in `docs/flags/` or a code-searchable list
- Quarterly graveyard sweep (search for non-`kill_switch` flags older than 90 days)

---

## 5. Server-Driven vs Build-Time Flags

| Aspect | Server-driven (Remote Config) | Build-time (compile flag) |
|---|---|---|
| **Change speed** | Instant (next fetch) | Requires app release |
| **Safety** | Risk of bad config reaching all users | Compiler-checked, safe |
| **Use case** | UI parameters, model selection, % rollouts | Core architecture, security changes |
| **Offline behavior** | Falls back to cached or default | Always present |
| **Governance need** | Audit log for changes | Code review |

**Policy**: 
- Kill switches, provider selection, and cost caps → **server-driven** (must be instant)
- Core architecture changes, new service integrations → **build-time** (must be safe)
- UI/UX experiments → **server-driven** (iteration speed matters)
- Gamification parameter changes → **server-driven** (tuning without releases)

---

## 6. Firebase A/B Testing vs Custom Harness

| Criterion | Firebase A/B Testing | Custom harness |
|---|---|---|
| Setup effort | Minutes | Days–weeks |
| Statistical engine | Built-in (frequentist) | Full control (Bayesian optional) |
| Custom metrics | Limited to Firebase Analytics events | Any metric from any source |
| Guardrail auto-halt | No built-in | Implementable |
| Cost | Free | Engineering hours |
| Flag cleanup | Manual | Tied to registry |

**Recommendation**: Start with Firebase A/B Testing for all experiments. Build custom analysis layer (Python/Jupyter, BigQuery export) when:
1. Need Bayesian analysis
2. Need custom guardrail auto-halt
3. Need multi-variate experiments beyond Firebase's capability

Do **not** build a custom experiment harness until MAU > 100k or dedicated data engineer is on team.

---

## 7. Experiment Design Template

Every experiment should have a documented design:

```markdown
## Experiment: [Name]

**Hypothesis**: [statement]
**Primary metric**: [metric + definition link]
**Guardrails**: [list + thresholds]
**Variants**: [description of each]
**Sample size needed**: [calculation]
**Duration**: [7/14/21 days]
**Owner**: [person]
**Flags involved**: [list]

### Rollout plan
- Day 1: 1% internal dogfood → verify
- Day 3: 5% targeted segment → verify guardrails
- Day 7: 50% → evaluate significance
- Day 10: 100% or kill

### Kill criteria
- Guardrail thresholds breached → auto-halt
- No statistically significant improvement after 21 days → kill
- Negative user feedback via support → manual halt
```

---

## 8. Open Questions

1. **Who owns the experiment registry?** Should there be a `docs/experiments/` directory with one file per experiment?
2. **How do we handle experiment overlap?** Two simultaneous experiments touching the same metric can confound results. Policy: no overlapping experiments on the same primary metric.
3. **Should there be a "novelty effect" grace period?** Some experiments show artificial improvement in the first 3 days (Hawthorne effect). Policy: no early termination before day 7.
4. **How do we experiment on the experiment harness itself?** Changes to flag infrastructure should be validated with a dummy experiment before being trusted.

---

## 9. Related Docs

- `docs/exploration/REMOTE_CONFIG_AND_KILL_SWITCHES.md` — infra side of flags
- `docs/exploration/NEGATIVE_MECHANICS_AB.md` — specific experiment design for negative mechanics
- `docs/exploration/ANALYTICS_SCHEMA_GOVERNANCE.md` — metric definitions
- `lib/providers/feature_flags_provider.dart` — current flag provider
- `lib/services/remote_config_service.dart` — Remote Config service
