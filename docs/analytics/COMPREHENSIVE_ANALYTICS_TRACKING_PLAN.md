# Comprehensive Analytics Tracking Plan
## Waste Segregation App

**Document Version:** 1.0  
**Date:** June 19, 2025  
**Status:** Implementation Ready

## Executive Summary

This analytics implementation moves beyond basic "items classified" metrics to provide a 360° view of user behavior, feature adoption, performance bottlenecks, and retention drivers. The plan enables answering critical questions like "Which educational content increases classification accuracy?", "Do users abandon the flow during AI processing?", and "How does gamification impact long-term engagement?"

Implementing this plan provides immediate insights for product optimization, performance monitoring, and user experience enhancement while maintaining GDPR/CCPA compliance.

---

## 1. Objectives & Stakeholders

| Objective | Stakeholder | Primary KPIs |
|-----------|-------------|--------------|
| Increase daily active classification users | Product/Growth | DAU, Classification completion rate, Feature adoption % |
| Reduce churn from AI processing delays | Engineering | p95 AI response time, Rage-click rate, Session abandonment |
| Optimize gamification for retention | Product | Points engagement rate, Achievement unlock rate, Streak maintenance |
| Provide actionable usage insights | Admin/Analytics | Screen engagement depth, User journey analysis, Conversion funnels |

---

## 2. Event Taxonomy

### 2.1 Global Lifecycle Events

| Event Name | Fires When | Required Properties |
|------------|------------|-------------------|
| `session_start` | App launch or 30min+ idle return | `device_type`, `app_version`, `user_segment`, `anonymous_id` |
| `session_end` | App backgrounded or timeout | `session_duration_ms`, `events_in_session`, `classifications_count` |
| `page_view` | Screen navigation change | `screen_name`, `previous_screen`, `navigation_method`, `time_on_previous_screen_ms` |

### 2.2 Core Interaction Events

| Event Name | Trigger | Key Properties |
|------------|---------|----------------|
| `click` | Any button/CTA tap | `element_id`, `screen_name`, `element_type`, `user_intent` |
| `link_click` | External link taps | `url_destination`, `link_type`, `context` |
| `rage_click` | ≥3 taps same element in 1s | `element_id`, `tap_count`, `screen_name` |
| `scroll_depth` | 25/50/75/100% screen scroll | `depth_percent`, `screen_name`, `content_type` |
| `long_press` | Long press interactions | `element_id`, `action_taken`, `duration_ms` |

### 2.3 Waste Classification Events

| Event Name | Fires When | Extra Properties |
|------------|------------|------------------|
| `file_classified` | Classification completes | `model_version`, `processing_duration_ms`, `confidence_score`, `category`, `method`, `result_accuracy` |
| `classification_started` | User initiates analysis | `input_method`, `image_size_kb`, `source` |
| `classification_retried` | User retries analysis | `original_confidence`, `retry_reason`, `attempt_number` |
| `disposal_guidance_viewed` | User views disposal info | `category`, `guidance_type`, `time_spent_ms` |
| `classification_shared` | User shares result | `share_method`, `category`, `confidence_score` |

### 2.4 Gamification Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `points_earned` | Points awarded | `points_amount`, `source_action`, `total_points`, `level`, `category` |
| `achievement_unlocked` | Achievement earned | `achievement_id`, `achievement_type`, `points_awarded`, `rarity_level` |
| `streak_updated` | Streak count changes | `streak_type`, `current_count`, `is_new_record`, `maintenance_bonus` |
| `level_up` | User levels up | `new_level`, `previous_level`, `points_required`, `benefits_unlocked` |
| `challenge_completed` | Challenge finished | `challenge_id`, `completion_time_ms`, `difficulty`, `reward_earned` |

### 2.5 Educational Content Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `content_viewed` | Educational content opened | `content_id`, `content_type`, `source`, `user_level` |
| `content_completed` | Content fully consumed | `content_id`, `time_spent_ms`, `completion_rate`, `quiz_score` |
| `search_performed` | User searches content | `query`, `results_count`, `selected_result_position` |
| `bookmark_added` | Content bookmarked | `content_id`, `content_type`, `user_notes` |

### 2.6 Performance & Error Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `client_error` | JavaScript/Dart error | `error_message`, `stack_trace`, `screen_name`, `user_action` |
| `api_error` | Non-2xx API response | `endpoint`, `status_code`, `latency_ms`, `retry_count` |
| `slow_resource` | >250ms operations | `operation_name`, `duration_ms`, `resource_type` |
| `network_failure` | Connectivity issues | `error_type`, `retry_successful`, `offline_duration_ms` |

### 2.7 Social & Family Events

| Event Name | Trigger | Properties |
|------------|---------|------------|
| `family_created` | New family group | `family_size`, `creator_level`, `initial_settings` |
| `family_joined` | User joins family | `family_size`, `invitation_method`, `user_level` |
| `classification_reacted` | Reaction to family member's classification | `reaction_type`, `target_user_id`, `classification_category` |
| `leaderboard_viewed` | Leaderboard access | `leaderboard_type`, `user_rank`, `time_period` |

---

## 3. Event Schema & Naming Conventions

### 3.1 Naming Standards
- **snake_case** for event names
- **camelCase** for properties
- **Object-Action** pattern (e.g., `file_classified`, `content_viewed`)
- Consistent verb tenses (past tense for completed actions)

### 3.2 Required Properties
Every event MUST include:
- `user_id` (authenticated) or `anonymous_id` (guest)
- `session_id` (UUID for session tracking)
- `timestamp` (ISO 8601 format)
- `app_version` (semantic version)
- `platform` (iOS/Android/Web)

### 3.3 Schema Validation
```json
{
  "type": "object",
  "required": ["event_name", "user_id", "session_id", "timestamp", "properties"],
  "properties": {
    "event_name": {"type": "string", "pattern": "^[a-z_]+$"},
    "user_id": {"type": "string"},
    "session_id": {"type": "string", "format": "uuid"},
    "timestamp": {"type": "string", "format": "date-time"},
    "properties": {"type": "object"}
  }
}
```

---

## 4. Implementation Architecture

### 4.1 Current Infrastructure Enhancement
Building upon existing robust foundation:
- **AnalyticsService**: Enhanced with new event types and consent management
- **WasteAppLogger**: Extended with performance tracking integration
- **Firebase Backend**: Maintained with additional event collections
- **Offline Support**: Enhanced pending event queue with schema validation

### 4.2 New Components
- **AnalyticsConsentManager**: GDPR/CCPA compliance handling
- **AnalyticsSchemaValidator**: Event validation before transmission
- **AnalyticsTrackingWrapper**: UI interaction auto-capture
- **PerformanceTracker**: Client-side performance monitoring

### 4.3 Data Flow
```
User Action → TrackingWrapper → ConsentManager → SchemaValidator → AnalyticsService → Firebase/Local Storage
```

---

## 5. Privacy & Compliance

### 5.1 Consent Management
- Display GDPR-compliant consent banner on first launch
- Granular consent options (Essential, Analytics, Marketing)
- Consent state tracked with every event
- "Delete my data" API integration

### 5.2 Data Minimization
- Anonymous ID for non-authenticated users
- Automatic PII scrubbing in event properties
- Configurable data retention periods
- User-controlled data export/deletion

### 5.3 Identity Stitching
- Generate stable `anonymous_id` on first visit
- Link to `user_id` on authentication via `identify()` call
- Maintain privacy boundaries for guest users

---

## 6. QA & Governance

### 6.1 Validation Pipeline
- JSON Schema validation in CI/CD
- Event property type checking
- Required field enforcement
- Staging environment event mirroring

### 6.2 Quality Assurance
- Automated tests for all tracking methods
- Schema drift detection
- Event naming consistency checks
- Performance impact monitoring

### 6.3 Governance Process
- Monthly schema review meetings
- Quarterly tracking plan updates
- Event deprecation lifecycle management
- Cross-team analytics requirements gathering

---

## 7. Implementation Roadmap

### Week 1: Foundation
- [x] Create tracking plan documentation
- [ ] Implement consent management system
- [ ] Add schema validation framework
- [ ] Enhance existing event taxonomy

### Week 2: Core Events
- [ ] Implement session lifecycle tracking
- [ ] Add page view navigation tracking
- [ ] Enhance classification event details
- [ ] Add performance monitoring

### Week 3: Advanced Features
- [ ] Implement interaction tracking wrapper
- [ ] Add rage-click detection
- [ ] Create scroll depth monitoring
- [ ] Integrate error tracking

### Week 4: Testing & Deployment
- [ ] Comprehensive test suite
- [ ] Staging environment validation
- [ ] Feature flag controlled rollout
- [ ] Production monitoring setup

---

## 8. Success Metrics

### 8.1 Implementation Success
- [ ] 100% event schema compliance
- [ ] <50ms tracking overhead
- [ ] 99.9% event delivery rate
- [ ] Zero PII leakage incidents

### 8.2 Business Impact
- [ ] 20% improvement in feature adoption insights
- [ ] 50% reduction in performance issue detection time
- [ ] 30% better user journey understanding
- [ ] 15% increase in retention through data-driven optimizations

---

## 9. Technical Integration Points

### 9.1 Existing Codebase Integration
- **lib/services/analytics_service.dart**: Enhanced with new tracking methods
- **lib/models/gamification.dart**: Extended event types and names
- **lib/utils/waste_app_logger.dart**: Performance tracking integration
- **lib/providers/app_providers.dart**: New service providers

### 9.2 New Service Files
- **lib/services/analytics_consent_manager.dart**: Consent handling
- **lib/services/analytics_schema_validator.dart**: Event validation
- **lib/widgets/analytics_tracking_wrapper.dart**: UI interaction capture
- **lib/services/performance_tracker.dart**: Client performance monitoring

---

## 10. Monitoring & Alerting

### 10.1 Real-time Monitoring
- Event delivery rate tracking
- Schema validation failure alerts
- Performance impact monitoring
- Consent compliance verification

### 10.2 Analytics Health Dashboard
- Daily event volume trends
- Error rate monitoring
- User segment distribution
- Feature adoption metrics

---

## Appendices

### A. Event Implementation Examples

```dart
// Session lifecycle
analyticsService.trackSessionStart();
analyticsService.trackPageView('HomeScreen', previousScreen: 'OnboardingScreen');

// Classification events
analyticsService.trackFileClassified(
  classificationId: 'uuid',
  category: 'recyclable_plastic',
  confidence: 0.95,
  processingDuration: 1500,
  modelVersion: 'v2.1'
);

// Interaction tracking
analyticsService.trackClick(
  elementId: 'classify_button',
  screenName: 'HomeScreen',
  userIntent: 'start_classification'
);
```

### B. Schema Validation Examples

```dart
final validator = AnalyticsSchemaValidator();
final isValid = await validator.validateEvent(event);
if (!isValid) {
  WasteAppLogger.warning('Invalid event schema', event.toJson());
}
```

### C. Consent Management Integration

```dart
final consentManager = AnalyticsConsentManager();
if (await consentManager.hasAnalyticsConsent()) {
  analyticsService.trackEvent(event);
}
```

---

**Implementation Status:** Ready for development  
**Next Steps:** Begin Week 1 foundation implementation  
**Owner:** Development Team  
**Review Date:** July 19, 2025 