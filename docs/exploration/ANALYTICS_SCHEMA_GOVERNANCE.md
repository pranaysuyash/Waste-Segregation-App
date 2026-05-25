# Analytics Schema Governance

**Status**: Exploration — governance patterns recommended  
**Date**: 2026-05-25  
**Why this matters**: Analytics events accumulate entropy fast. Without an explicit schema + change-review process, "user activated" can mean three things in three months, none documented. Clean event data is necessary for A/B testing, retention analysis, and cost tracking.

---

## 1. Current State

**What exists:**
- `lib/services/analytics_service.dart` — analytics service
- `lib/services/analytics_schema_validator.dart` — schema validator
- `lib/models/analytics_models.g.dart` — generated analytics models
- `lib/services/analytics_consent_manager.dart` — consent management
- `docs/analytics/` — 5 analytics docs (substantial)
- Firebase Analytics integrated

**What's missing:**
- Single source of truth for event names + properties (event catalogue)
- Backward-compatibility contract for event renames/removals
- Consent-aware event firing policy (what fires pre-consent vs post-consent)
- Auto-generated event catalogue from code
- Activation/retention metric definitions that survive team changes

---

## 2. Event Catalogue Structure

### Proposed: Git-Based Markdown + Code Annotations

A single source of truth in `docs/analytics/EVENT_CATALOGUE.md` with a companion code annotation system.

```markdown
# Analytics Event Catalogue

## Activation Events

### `classification_completed`
Fired when a classification result is displayed to the user.

**Properties:**
- `classification_id` (string, required) — Firestore document ID
- `category` (string, required) — predicted waste category
- `confidence` (float, required) — model confidence score 0.0–1.0
- `provider` (string, required) — which AI provider: openai | gemini | on_device | deterministic
- `layer` (string, required) — pipeline layer: L0 | L1 | L2 | L3
- `latency_ms` (int, required) — end-to-end classification latency
- `tokens_consumed` (int, required if cloud) — API tokens used
- `was_offline` (bool, required) — was this processed offline
- `is_premium` (bool, required) — was this a premium user

**Consent level**: analytics_storage (fires pre-consent as anonymous, post-consent with user_id)
**First defined**: 2026-01-15
**Owner**: @engineering-team

---

### `correction_submitted`
Fired when a user corrects a classification result.

**Properties:**
- `classification_id` (string, required)
- `original_category` (string, required)
- `corrected_category` (string, required)
- `correction_type` (string, required) — wrong_category | wrong_disposal | other
- `provider` (string, required)
- `confidence` (float, required) — original confidence

**Consent level**: analytics_storage
**First defined**: 2026-02-10
**Owner**: @ml-team
```

### Code Annotation

```dart
@AnalyticsEvent(
  name: 'classification_completed',
  description: 'Fired when a classification result is displayed',
  properties: [
    AnalyticsProperty(name: 'category', type: String, required: true),
    AnalyticsProperty(name: 'confidence', type: double, required: true),
    AnalyticsProperty(name: 'provider', type: String, required: true),
    AnalyticsProperty(name: 'latency_ms', type: int, required: true),
    AnalyticsProperty(name: 'tokens_consumed', type: int, required: false),
  ],
)
void trackClassificationCompleted(ClassificationResult result) {
  analytics.logEvent(
    name: 'classification_completed',
    parameters: {
      'category': result.category,
      'confidence': result.confidence,
      'provider': result.provider.name,
      'latency_ms': result.latencyMs,
      if (result.tokensConsumed != null) 'tokens_consumed': result.tokensConsumed,
    },
  );
}
```

---

## 3. Backward-Compatibility Contract

### Rules

1. **Never rename an existing event** — create a new event with deprecated-old-event mapping
2. **Never remove a property from an existing event** — mark it as `deprecated` and stop firing after 60 days
3. **Additions only** — new properties are always optional (for 30 days, then may become required)
4. **Version property** — every event includes a `schema_version` int starting at 1

### Deprecation Process

```
Week 1: New event/property added (schema_version = schema_version + 1)
         Old version continues firing alongside new version (dual-write)

Week 4: Old version stopped firing
         Old version marked as `deprecated: true` in catalogue

Week 8: Old version removed from catalogue
         Queries updated to use new version only
```

### CI Check

Add a CI check that:
1. Scans `lib/services/analytics_service.dart` for `logEvent` calls
2. Validates each event name against the catalogue
3. Validates each property against the catalogue
4. Warns if an unknown event or property is being fired
5. Blocks if a removed event is being re-introduced without documented deprecation

---

## 4. Consent-Aware Event Firing

### Consent Levels

| Consent level | Events that fire | User identifier |
|---|---|---|
| **Pre-consent** (before dialog shown) | Crashlytics, essential app functionality events only | Anonymous device ID only |
| **Minimal consent** (analytics_storage granted) | All analytics events | Firebase Analytics user ID, no advertising ID |
| **Full consent** (analytics + ad_storage + personalization) | All events including behavioral | Full identifiers |

### Pre-Consent vs Post-Consent by Event Category

| Event category | Pre-consent | Post-consent |
|---|---|---|
| Crash/error (Crashlytics) | ✅ Always | ✅ Always |
| App lifecycle (install, launch) | ✅ Anonymized | ✅ With user ID |
| Classification events | ✅ Anonymized | ✅ With user ID |
| Gamification events | ❌ Blocked | ✅ With user ID |
| Ad interaction events | ❌ Blocked | ✅ With user ID (if consented) |
| Experiment assignment | ❌ Blocked | ✅ With user ID |
| Personalization events | ❌ Blocked | ✅ With user ID (if consented) |

### Implementation Pattern

```dart
class ConsentAwareAnalyticsService {
  void trackEvent(String name, Map<String, dynamic> params, {EventCategory category = EventCategory.classification}) {
    if (!_canFire(category)) return;
    
    if (_consentLevel == ConsentLevel.preConsent) {
      // Strip PII, fire as anonymous
      params = _anonymize(params);
    }
    
    _firebaseAnalytics.logEvent(name: name, parameters: params);
  }
}
```

---

## 5. Metric Definitions (Must Survive Team Changes)

### Canonical Metric Definitions

Every metric needs:
- **Name**: Single canonical name
- **SQL/Code definition**: How it's computed (in a versioned file)
- **Why it matters**: Business context
- **Owner**: Team or person
- **History**: Changelog of definition changes

```markdown
## metric: activation_rate

**Definition**: Percentage of new users who complete ≥1 classification within 7 days of install.

**SQL**:
```sql
SELECT
  COUNT(DISTINCT CASE WHEN first_classification_date <= install_date + 7 THEN user_id END) * 1.0 /
  COUNT(DISTINCT user_id) AS activation_rate
FROM user_cohorts
WHERE install_date BETWEEN @start_date AND @end_date
```

**Why it matters**: Activation is the leading indicator of retention. Users who don't classify within 7 days rarely return.

**History**:
| Date | Change | Author |
|---|---|---|
| 2026-01-01 | Initial definition (3-day window) | @alice |
| 2026-03-15 | Changed to 7-day window based on data analysis | @bob |
```

### Metric Review Process

1. Any metric definition change requires a PR to `docs/analytics/METRICS.md`
2. PR must include rationale + data supporting the change
3. Old definition preserved in changelog section
4. Dashboard queries must reference metric version or date

---

## 6. Auto-Generated Event Catalogue

### Generator

Build a codegen tool that:
1. Scans `lib/services/analytics_service.dart` for `@AnalyticsEvent` annotations
2. Generates `docs/analytics/AUTO_GENERATED_EVENT_CATALOGUE.md`
3. CI checks that the generated catalogue matches the version-controlled canonical catalogue (with tolerance for pre-approved new events)

### Generator Output Format

```markdown
# Auto-Generated Event Catalogue
*Generated: 2026-05-25 14:30:00 UTC*

## Events (42 total)

| Event name | Properties | Consent level | Last modified |
|---|---|---|---|
| classification_completed | 9 | analytics_storage | 2026-05-20 |
| correction_submitted | 5 | analytics_storage | 2026-05-18 |
| ... | ... | ... | ... |

## Properties (184 total)

| Property name | Used in events |
|---|---|
| classification_id | classification_completed, correction_submitted, ... |
| category | classification_completed, correction_submitted, ... |
```

---

## 7. Key Activation & Retention Metrics

| Metric | Definition | Target |
|---|---|---|
| Activation D7 | % of new users who classify within 7 days | >40% |
| Retention D1 | % who return day after install | >50% |
| Retention D7 | % who return day 6–8 | >25% |
| Retention D30 | % who return day 27–33 | >15% |
| Weekly active scannners | % of MAU who scanned that week | >60% |
| Scan frequency | Avg classifications per active user per week | >3 |
| Correction rate | corrections / total classifications | <10% |
| Share rate | shares / total classifications | >5% |

---

## 8. Open Questions

1. **Who owns the event catalogue?** Product manager? Engineering lead? Data analyst? Recommended: engineering team owns schema, PM owns metric definitions, both approve changes.
2. **How do we handle partner SDK events?** Firebase Analytics, Crashlytics, AdMob each fire their own events. Should they be included in the catalogue? Recommended: document them as "third-party events" with provider attribution.
3. **Event volume management**: Firebase Analytics has free limits (10M events/month). What's the current volume estimate? Should we sample high-frequency events?

---

## 9. Related Docs

- `docs/exploration/AB_TESTING_AND_FEATURE_FLAGS.md` — experiments as consumers of clean events
- `docs/exploration/CONSENT_ARCHITECTURE.md` — consent levels
- `docs/exploration/LAUNCH_AND_STORE_COMPLIANCE.md` — ATT and data safety
- `docs/exploration/AI_COST_TELEMETRY_AND_GUARDRAILS.md` — cost events
- `lib/services/analytics_service.dart` — current implementation
- `docs/analytics/` — existing analytics docs
