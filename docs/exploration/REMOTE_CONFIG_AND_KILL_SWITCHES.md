# Remote Config & Kill Switches

**Status**: Exploration — governance patterns recommended, not yet enforced  
**Date**: 2026-05-25  
**Why this matters**: Remote config is the lever to disable a misbehaving feature without a release. It's load-bearing for safety (model swap rollback, cost spike halt, regional disable) and deserves a deliberate contract.

---

## 1. Current State

**What exists:**
- `lib/services/remote_config_service.dart` — Remote Config service wrapper
- Firebase Remote Config wired and accessible from Dart
- `lib/providers/feature_flags_provider.dart` — Riverpod provider using Remote Config

**What's missing:**
- No governance doc for config structure
- No audit log for who changed what when
- No fail-safe default contract
- No multi-tier kill switch architecture
- No gradual rollout pattern documentation

---

## 2. What MUST Be Remote-Controllable

### Tier 1 — Safety-critical (P0, always remote-controllable)

| Config key | Purpose | Default | Failure behaviour |
|---|---|---|---|
| `kill_switch_all_ai_inference` | Disable ALL cloud AI inference | false | Fall back to on-device only (if available) or show "service unavailable" |
| `kill_switch_ai_provider_openai` | Disable OpenAI specifically | false | Route all to Gemini |
| `kill_switch_ai_provider_gemini` | Disable Gemini specifically | false | Route all to OpenAI |
| `kill_switch_on_device_inference` | Disable on-device models | false | Route all to cloud |
| `kill_switch_community_feed` | Disable community features | false | Hide community tab |
| `safety_max_classification_cost_per_user_daily` | Per-user daily AI cost cap | 0.50 USD | Block classification, show "daily limit reached" |
| `safety_max_classifications_per_user_daily` | Per-user daily scan cap | 100 | Block classification |
| `safety_critical_category_routing` | Which categories MUST go to highest confidence tier | ["hazardous", "medical", "chemical"] | Enforce at router level |

### Tier 2 — Operational (P1, configurable per release cycle)

| Config key | Purpose | Default |
|---|---|---|
| `model_routing_provider_priority` | Ordered list of providers | ["gemini", "openai"] |
| `model_routing_on_device_threshold` | Confidence threshold for on-device pass | 0.75 |
| `model_routing_race_enabled` | Enable race mode (multi-provider) | false |
| `model_routing_race_percentage` | % of users in race mode | 0.0 |
| `cost_daily_budget_hard` | Hard daily AI budget across all users | 25.00 USD |
| `cost_daily_budget_soft` | Soft daily budget (alert only) | 20.00 USD |
| `onboarding_gradual_enabled` | Enable gradual onboarding flow | true |
| `onboarding_minimum_scans_before_social` | Scans required before social features shown | 5 |

### Tier 3 — Tuning (P2, available for experiments)

| Config key | Purpose | Default |
|---|---|---|
| `gamification_points_multiplier` | Global points multiplier | 1.0 |
| `gamification_daily_challenge_count` | Challenges per day | 2 |
| `gamification_streak_freeze_enabled` | Allow streak freeze mechanic | true |
| `notification_coaching_enabled` | Enable coaching notifications | true |
| `notification_frequency_cap_daily` | Max notifications per day | 3 |

---

## 3. Fail-Safe Defaults

### Principle

The app must never crash or block core functionality because Remote Config is unreachable.

### Implementation

```dart
class SafeRemoteConfigService {
  static const Map<String, dynamic> _builtInDefaults = {
    'kill_switch_all_ai_inference': false,
    'kill_switch_ai_provider_openai': false,
    'safety_max_classifications_per_user_daily': 100,
    'model_routing_provider_priority': ['gemini', 'openai'],
    // ... all keys with safe defaults
  };
  
  // Cache last fetched config for offline scenarios
  Map<String, dynamic> _cachedConfig = {..._builtInDefaults};
  
  Future<void> initialize() async {
    try {
      await remoteConfig.fetchAndActivate();
      _cachedConfig = {..._cachedConfig, ...remoteConfig.getAll()};
    } catch (e) {
      // Silently use defaults + last cached
    }
  }
}
```

### Cache Strategy

1. **First launch (no network)**: Use built-in bundled defaults
2. **Subsequent launches**: Use last successfully fetched config from local cache
3. **Expired cache**: Defaults expire after 12 hours — fresh fetch attempted, fall back to cached if that fails
4. **Stale data**: Config older than 48 hours triggers a prominent visual indicator in debug/dev builds

---

## 4. Audit Log & Change Management

### Required

Every Remote Config change must be traceable:

1. **Version control**: Push config changes through Git (config as code). Use Firebase CLI to fetch/apply from config files in repo.
2. **Change metadata per update**:
   - Author (person/system)
   - Reason code (`cost_mitigation`, `safety_incident`, `experiment_start`, `tuning`, `emergency`)
   - Impact scope (`global`, `region:in`, `segment:premium`, `experiment:exp_123`)
   - Rollback plan (previous value documented in commit message)
3. **Emergency overrides**: Direct Firebase Console changes allowed only for safety incidents. Must be followed by a Git commit within 24h documenting the change.

### Degradation Detection

- Monitor Remote Config fetch failure rate in analytics
- Alert if >5% of fetches fail for >30 minutes
- Alert if stale config age exceeds 48 hours

---

## 5. Multi-Tier Kill Switch Architecture

```
Level 1 — Feature Level
└─ Disable single feature (e.g., community feed, race mode, quiz)
   └─ kill_switch_<feature_name>: boolean

Level 2 — Model/Provider Level
└─ Disable a provider or model version
   └─ kill_switch_ai_provider_openai: boolean
   └─ model_routing_provider_priority: ordered list

Level 3 — Inference Level
└─ Disable all cloud or all on-device inference
   └─ kill_switch_all_ai_inference: boolean
   └─ kill_switch_on_device_inference: boolean

Level 4 — Global App Level
└─ Show maintenance screen
   └─ kill_switch_app_maintenance: boolean
   └─ kill_switch_app_maintenance_message: string
```

### Detection & Activation Policy

- Level 1–2: Manual activation via config change (Git PR + merge)
- Level 3: Manual or automated (if crash rate >5% or cost anomaly detected)
- Level 4: Manual only (requires engineering lead approval)

---

## 6. Gradual Rollout Patterns

### Standard Rollout

```
Day 1: 1% internal dogfood (email domain filter)
Day 3: 5% (random sample)
Day 5: 25% (if no guardrail breach)
Day 7: 50%
Day 10: 100%
```

### Percentage Ramping with Firebase

Firebase Remote Config supports percentage-based rollouts natively. Use `condition` filters with user property matching.

```dart
// User property-based targeting
await remoteConfig.setUserProperty('experiment_group', 'treatment');
```

### Targeted Segments

| Segment | Filter | Use case |
|---|---|---|
| Internal team | Email domain | Dogfood |
| Beta testers | User property `is_beta_tester: true` | Early validation |
| Premium users | Subscription status | Premium-only features |
| Region | Country code | Regional rollouts |
| App version | Version number | Phased feature launch |

---

## 7. Config Structure Convention

```yaml
# config/remote_config_defaults.yaml
kill_switches:
  all_ai_inference: false
  ai_provider_openai: false
  ai_provider_gemini: false
  on_device_inference: false
  community_feed: false
  
model_routing:
  provider_priority: ["gemini", "openai"]
  on_device:
    confidence_threshold: 0.75
    escape_categories: ["hazardous", "medical"]
  race:
    enabled: false
    user_percentage: 0.0
    
cost:
  daily_budget_hard_usd: 25.00
  daily_budget_soft_usd: 20.00
  per_user_daily_max_usd: 0.50
  per_user_daily_max_classifications: 100

safety:
  always_route_to_highest: ["hazardous", "medical", "chemical", "aerosol"]

gamification:
  points_multiplier: 1.0
  daily_challenge_count: 2
  streak_freeze_enabled: true
```

---

## 8. Open Questions

1. **Config review frequency**: How often should the full config be audited for stale/obsolete keys?
2. **Config as code maturity**: Should we use `firebase-tools` to deploy config from a YAML file in CI, or is manual console editing sufficient?
3. **Multi-environment config**: How to maintain dev/staging/production config separation?
4. **Canary config**: Should a small % of production users receive a "canary" config version before full rollout?

---

## 9. Related Docs

- `docs/exploration/AB_TESTING_AND_FEATURE_FLAGS.md` — experiment side of flags
- `docs/exploration/BACKEND_CLASSIFICATION_PROXY.md` — server-side cost enforcement
- `lib/services/remote_config_service.dart` — current implementation
- `lib/providers/feature_flags_provider.dart` — current provider
