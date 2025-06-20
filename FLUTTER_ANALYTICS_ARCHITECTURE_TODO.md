# Flutter Analytics Architecture Implementation TODO

**Created:** June 20, 2025  
**Status:** Ready for Implementation  
**Priority:** HIGH - Cost-Effective Analytics Strategy

## 🎯 Executive Summary

This document outlines the complete implementation plan for analytics architecture improvements in the Waste Segregation Flutter app, based on comprehensive cost analysis showing BigQuery sandbox is FREE for our current scale.

## 📊 Cost-Effective Strategy Overview

### Current Recommendation: BigQuery Sandbox + Flutter Web Dashboard
- **Cost:** $0 for months/years at current scale
- **Free Limits:** 10GB storage + 1TB queries/month
- **Migration Trigger:** Only when costs exceed $50/month consistently

## ✅ Completed Tasks

### ✅ Task 1: RouteObserver Implementation
- [x] Created `AnalyticsRouteObserver` class
- [x] Added `navigatorObservers` to MaterialApp in main.dart
- [x] Implemented `AnalyticsRouteAware` wrapper widget
- [x] Enhanced route tracking with timing and navigation methods

### ✅ Task 2: Frame Performance Monitoring  
- [x] Created `FramePerformanceMonitor` class
- [x] Implemented slow frame detection (>16ms) and jank tracking (>32ms)
- [x] Added rate limiting and analytics integration
- [x] Resolved duplicate class conflicts

### ✅ Task 3: Sentry Integration Planning
- [x] Created implementation plan document
- [x] Defined integration strategy with existing analytics

### ✅ Task 4: Architecture Decision Records
- [x] Created ADR template following MADR format
- [x] Implemented ADR-001: Clean Architecture adoption
- [x] Implemented ADR-002: Riverpod state management
- [x] Documented migration strategy and folder structure

### ✅ Task 5: Cost-Effective Analytics Strategy
- [x] Analyzed BigQuery costs vs alternatives
- [x] Updated strategy to use FREE BigQuery sandbox
- [x] Created comprehensive implementation guide
- [x] Documented migration paths for future scale

## 🔄 Next Implementation Phase

### Task 6: BigQuery Export Setup (Priority: HIGH)
**Effort:** 15 minutes  
**Cost:** $0

- [ ] Go to Firebase Console → Integrations → BigQuery
- [ ] Click "Link" and follow setup wizard
- [ ] Choose dataset location (us-central1 recommended for lowest cost)
- [ ] Enable daily export (free)
- [ ] Verify events are flowing to BigQuery

### Task 7: Flutter Web Admin Dashboard (Priority: HIGH)
**Effort:** 1-2 days  
**Cost:** $0

#### Architecture Setup
```
lib/
  admin/
    screens/
      admin_dashboard_screen.dart
      analytics_screen.dart
      users_screen.dart
    widgets/
      metric_card.dart
      chart_widget.dart
      data_table.dart
    services/
      bigquery_service.dart
      admin_analytics_service.dart
```

#### Implementation Checklist
- [ ] Create `BigQueryService` class for data queries
- [ ] Build metric cards for key KPIs:
  - [ ] Daily Active Users (DAU)
  - [ ] Monthly Active Users (MAU)
  - [ ] Classifications today/month
  - [ ] Error count and crash rate
  - [ ] Premium users and conversion rate
- [ ] Implement time-series charts for trends
- [ ] Add user detail views and event listings
- [ ] Create export functionality (CSV/JSON)

### Task 8: Cost Monitoring Setup (Priority: HIGH)
**Effort:** 30 minutes  
**Cost:** $0

- [ ] Set up Cloud Billing alerts at $25/month threshold
- [ ] Configure notification channels (email + Slack)
- [ ] Monitor BigQuery storage usage
- [ ] Track query bytes processed
- [ ] Document cost escalation procedures

### Task 9: Advanced Analytics Features (Priority: MEDIUM)
**Effort:** 2-3 days  
**Cost:** $0

- [ ] Build funnel analysis queries
- [ ] Implement retention cohort analysis
- [ ] Add real-time updates via Cloud Functions + Firestore
- [ ] Create automated reporting (daily/weekly summaries)
- [ ] Build custom dashboard widgets

## 📈 Analytics & Instrumentation Plan

### Event Taxonomy Implementation
Based on the notepad review, implement comprehensive event tracking:

#### Core Events to Track
```dart
// Lifecycle Events
- session_start / session_end
- app_foreground / app_background

// Navigation Events  
- screen_view (auto-tracked via RouteObserver)
- navigation_action

// Interaction Events
- tap (primary CTAs)
- scroll_depth (25%, 50%, 75%, 100%)
- long_press
- swipe_action

// Feature Events
- file_uploaded
- analysis_started  
- analysis_finished
- classification_saved
- export_tapped
- share_action

// Quality Events
- app_error
- slow_frame (>16ms)
- crash_detected
- api_timeout
```

#### Implementation Tasks
- [ ] Create centralized `AnalyticsService` facade
- [ ] Implement `AnalyticsRouteAware` for all screens
- [ ] Add scroll depth tracking to ScrollControllers
- [ ] Wrap primary CTAs with analytics tracking
- [ ] Add error boundary analytics
- [ ] Implement performance metrics collection

### Data Quality & Governance
- [ ] Add analytics unit tests
- [ ] Create JSON schema validation for events
- [ ] Set up BigQuery monitoring for unknown events
- [ ] Document event naming conventions
- [ ] Create analytics debugging tools

## 🏗️ Architecture Improvements

### Clean Architecture Migration
Following ADR-001, implement feature-slice organization:

```
lib/
  core/
    errors/
    usecases/
    entities/
  features/
    classification/
      data/
        datasources/
        repositories/
        models/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        bloc/
        pages/
        widgets/
    analytics/
      data/
      domain/
      presentation/
    user_management/
      data/
      domain/
      presentation/
```

#### Migration Tasks
- [ ] Refactor classification feature to clean architecture
- [ ] Move analytics logic to dedicated feature slice
- [ ] Create core shared components
- [ ] Update import statements across codebase
- [ ] Add feature-level testing

### State Management Standardization
Following ADR-002, standardize on Riverpod:

- [ ] Audit current state management approaches
- [ ] Migrate Provider usage to Riverpod
- [ ] Create consistent notifier patterns
- [ ] Add state management documentation
- [ ] Update testing approaches for Riverpod

## 🧪 Testing Strategy

### Testing Pyramid Implementation
```
Integration Tests (E2E)
├── Widget Tests (UI Components)  
└── Unit Tests (Business Logic)
```

#### Testing Tasks
- [ ] Achieve 80% unit test coverage
- [ ] Add golden tests for UI components
- [ ] Create integration tests for core flows:
  - [ ] Upload → Analyze → Export flow
  - [ ] User registration → Classification → Save
  - [ ] Admin dashboard → Analytics → Export
- [ ] Set up Firebase Test Lab for device matrix testing
- [ ] Add performance regression tests

### CI/CD Pipeline Enhancement
- [ ] Update GitHub Actions with `subosito/flutter-action@v2`
- [ ] Add matrix testing (stable, beta channels)
- [ ] Build APK/AAB/IPA artifacts in CI
- [ ] Add automated testing gates
- [ ] Set up release automation

## 📱 Performance & Quality

### Performance Monitoring
- [ ] Enable Performance Overlay in profile builds
- [ ] Fix all frames >16ms (treat as blockers)
- [ ] Add automated performance regression detection
- [ ] Monitor app start time and memory usage
- [ ] Implement performance budgets

### Accessibility & Internationalization
- [ ] Add Semantics widgets throughout app
- [ ] Implement proper focus order
- [ ] Add color contrast validation
- [ ] Create accessibility testing in CI
- [ ] Document accessibility guidelines

## 🔍 Observability & Monitoring

### Error Tracking & RUM
- [ ] Complete Sentry Flutter integration
- [ ] Set up error alerting and dashboards
- [ ] Add custom error boundaries
- [ ] Implement user session replay
- [ ] Create error resolution workflows

### Logging & Debugging
- [ ] Standardize logging patterns
- [ ] Add structured logging
- [ ] Create debug tools for development
- [ ] Implement log aggregation
- [ ] Add performance profiling tools

## 📋 90-Day Implementation Roadmap

### Weeks 1-2: Foundation (HIGH Priority)
- [ ] **Week 1:** Enable BigQuery export + basic dashboard
- [ ] **Week 2:** Implement core analytics events + cost monitoring

### Weeks 3-4: Analytics Enhancement (HIGH Priority)  
- [ ] **Week 3:** Build advanced dashboard features + funnel analysis
- [ ] **Week 4:** Add real-time updates + automated reporting

### Weeks 5-8: Architecture Migration (MEDIUM Priority)
- [ ] **Week 5:** Start Clean Architecture migration (classification feature)
- [ ] **Week 6:** Complete Riverpod standardization
- [ ] **Week 7:** Implement comprehensive testing strategy
- [ ] **Week 8:** Enhanced CI/CD pipeline

### Weeks 9-12: Quality & Performance (MEDIUM Priority)
- [ ] **Week 9:** Performance optimization + accessibility
- [ ] **Week 10:** Complete Sentry integration + monitoring
- [ ] **Week 11:** Advanced analytics features
- [ ] **Week 12:** Documentation + team training

## 💰 Cost Projections & Migration Planning

### Current Scale Projections
| Timeline | MAU | Events/Month | Storage | Queries | BigQuery Cost |
|----------|-----|--------------|---------|---------|---------------|
| **Current** | 1K | 750K | 2GB | 100GB | **$0** |
| **6 months** | 5K | 3.75M | 8GB | 400GB | **$0** |
| **12 months** | 15K | 11.25M | 25GB | 1.2TB | **$30/month** |
| **18 months** | 50K | 37.5M | 80GB | 4TB | **$150/month** |

### Migration Strategy (Future)
When BigQuery costs exceed $50/month consistently:

#### Option A: PostHog OSS (~$25/month)
- DigitalOcean Droplet: 2 vCPU, 4GB RAM
- ClickHouse database + PostHog UI
- Ready-made product analytics features

#### Option B: ClickHouse + Metabase (~$30/month)  
- Custom ClickHouse cluster
- Metabase for visualization
- Unlimited customization and scale

#### Option C: Supabase Analytics (~$15/month)
- PostgreSQL with real-time features
- Integrated auth and storage
- Familiar SQL interface

### Migration Preparation Tasks
- [ ] Document all BigQuery queries and dashboards
- [ ] Create data export scripts
- [ ] Test PostHog OSS in staging environment
- [ ] Prepare infrastructure automation scripts
- [ ] Create migration runbooks

## 🎯 Success Metrics

### Technical KPIs
- [ ] Dashboard loads in <2 seconds
- [ ] All queries execute in <10 seconds  
- [ ] Zero BigQuery costs for first 6 months
- [ ] 99%+ dashboard uptime
- [ ] 80%+ test coverage maintained

### Business KPIs
- [ ] Admin team uses dashboard daily
- [ ] Data-driven decisions increase by 50%
- [ ] User support resolution time decreases 30%
- [ ] Feature prioritization based on usage data
- [ ] Reduced time-to-insight for business questions

## 📚 Documentation & Knowledge Transfer

### Documentation Tasks
- [ ] Create analytics implementation guide
- [ ] Document BigQuery query patterns
- [ ] Write admin dashboard user guide
- [ ] Create troubleshooting runbooks
- [ ] Document migration procedures

### Team Training
- [ ] Train admin team on dashboard usage
- [ ] Educate developers on analytics best practices
- [ ] Create analytics review processes
- [ ] Establish data governance policies
- [ ] Document escalation procedures

## 🔧 Tools & Dependencies

### Required Packages
```yaml
dependencies:
  firebase_analytics: ^10.8.0
  firebase_core: ^2.24.2
  sentry_flutter: ^7.14.0
  riverpod: ^2.4.9
  charts_flutter: ^0.12.0
  http: ^1.1.0
  
dev_dependencies:
  flutter_test: ^3.16.0
  integration_test: ^3.16.0
  golden_toolkit: ^0.15.0
  mocktail: ^1.0.2
```

### Infrastructure Requirements
- Firebase project with BigQuery linking enabled
- Google Cloud project with billing enabled
- GitHub repository with Actions enabled
- Development environment with Flutter 3.16+

## 🚨 Risk Mitigation

### Data Backup Strategy
- [ ] Set up automated BigQuery data exports
- [ ] Create query history backups
- [ ] Document data recovery procedures
- [ ] Test restore processes regularly

### Fallback Plans
- [ ] Maintain Firebase Analytics as primary source
- [ ] Keep Firestore caching for dashboard resilience
- [ ] Prepare manual reporting procedures
- [ ] Document emergency procedures

## 📞 Next Steps

### Immediate Actions (This Week)
1. **Enable BigQuery export** (15 minutes)
2. **Set up billing alerts** (30 minutes)  
3. **Create Flutter Web project structure** (2 hours)
4. **Implement basic metric cards** (4 hours)

### Short-term Goals (Next 2 Weeks)
1. **Complete admin dashboard MVP** (1-2 days)
2. **Add comprehensive event tracking** (2-3 days)
3. **Test dashboard with production data** (1 day)
4. **Document usage and procedures** (1 day)

### Long-term Vision (3 Months)
1. **Full Clean Architecture migration**
2. **Comprehensive testing coverage**
3. **Advanced analytics capabilities**
4. **Scalable monitoring and alerting**

---

## 📝 Notes

- This plan prioritizes cost-effectiveness while building professional-grade analytics
- BigQuery sandbox provides enterprise capabilities at zero cost for our scale
- Migration paths are documented but only needed when scale justifies the cost
- Focus remains on building core app features while analytics run in background

**Total Implementation Time:** 3-4 weeks for core features, 12 weeks for complete roadmap  
**Total Cost:** $0 for foreseeable future with clear migration path when needed 