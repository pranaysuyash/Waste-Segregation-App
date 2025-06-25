# Consolidated Engineering Backlog

**Generated**: June 24, 2025  
**Status**: Ready for Implementation  
**Timeline**: 12-week rollout plan  

> This backlog is distilled from seven feature/architecture documents and current repo analysis. Each item is copy-paste ready for GitHub Issues, Linear, Jira, or Trello.

## 0 · Immediate "Keep-the-lights-on" fixes (CRITICAL)

**Why it matters**: Test infra currently blocks release, points system has race conditions affecting user experience.

### 🔥 Priority 1: CI Pipeline Unblocking
**Issue**: Test infrastructure blocks release (0/21 test suites passing)
**Task**: CI-pipeline un-blocking spike – reproduce timeout locally, profile longest tests, add 1 flaky-test quarantine job, publish root-cause doc.
**Definition of Done**: `flutter test` passes in <5 min locally and in GitHub Actions.
**Effort**: ⚡ (1-2 days)
**Status**: ✅ COMPLETED (June 24, 2025)

### 🔥 Priority 2: Points Race Condition Fix
**Issue**: Race condition in points engine causes mis-awarded points (downstream of every classification)
**Task**: Refactor GamificationService.processClassification to transactional write using Firestore runTransaction; add unit test that simulates 3 concurrent calls.
**Definition of Done**: No duplicate points awarded under concurrent classification scenarios.
**Effort**: ⚡ (1 day)
**Status**: ✅ ANALYZED - Race condition protection already exists via PointsEngine atomic operations and Firestore merge writes

### 🔥 Priority 3: Points Earned Popup Fix
**Issue**: Missing "points earned" popup degrades reinforcement loop
**Task**: Delay popup until navigation completes (see roadmap implementation) and add widget test for regression.
**Definition of Done**: Points popup shows consistently after classification with proper timing.
**Effort**: ⚡ (0.5 days)
**Status**: ✅ COMPLETED (June 25, 2025) - Added _showPointsEarnedPopup with navigation timing fixes

### 🔥 Priority 4: Cloud Function Crash Safety
**Issue**: Cloud function crashes cascade to user errors
**Task**: Wrap classifyWaste endpoint with circuit-breaker + 503 retry-after pattern.
**Definition of Done**: Cloud function returns 503 for retryable errors, fallback responses for others.
**Effort**: ⚡ (0.5 days)
**Status**: ✅ COMPLETED (June 25, 2025) - Implemented circuit-breaker pattern with 503 responses

**Source**: [Batch Processing Implementation Roadmap](../features/ai-batch-processing-implementation-roadmap.md)

---

## 1 · Cost & Scalability (Batch-processing + Token Economy)

**Goal**: Cut OpenAI costs by ~40% while adding freemium upsell path

### 1.1 Token Wallet Infrastructure
**Task**: Create wallet sub-collection under each user (schema provided) and write Firebase security rules (read = owner, write = server or owner via Cloud Functions).
**Dependencies**: Hot-fixes above
**Effort**: 🔨 (2-3 days)

### 1.2 Batch Job Queue System
**Task**: Implement job queue (aiJobs) with fields & statuses in roadmap; schedule batchWorker every 5 min; integrate OpenAI Batch API.
**Dependencies**: Token wallet infrastructure
**Effort**: 🔨🔨 (1 week)

### 1.3 Speed Toggle UI
**Task**: Build client "speed toggle" widget (Cupertino sliding segmented control).
**Dependencies**: Token wallet, job queue
**Effort**: 🔨 (2-3 days)

### 1.4 Dynamic Pricing Service
**Task**: Remote Config-driven pricing service – read batch_token_price, instant_token_price, points_to_token_rate.
**Dependencies**: Token wallet
**Effort**: 🔨 (1 day)

### 1.5 Cost Guardrails
**Task**: Daily cost guardrail function – if spend > 80% budget, force force_batch_mode=true.
**Dependencies**: Pricing service
**Effort**: 🔨 (1 day)

### 1.6 Priority Upgrade Flow
**Task**: Upgrade flow: allow user to spend 4 extra tokens to bump queued job to instant.
**Dependencies**: Job queue, token wallet
**Effort**: 🔨 (2 days)

**Source**: [Cost-Optimization + Batch Implementation Roadmap](../features/COMPREHENSIVE_ROADMAP_FEEDBACK_IMPLEMENTATION.md)

---

## 2 · Enhanced AI Analysis v2.0 Rollout

### 2.1 Expand Classification Model
**Task**: Expand WasteClassification model to 21 data points; add generated fromJson/toJson methods.
**Migration Strategy**: Keep old fields optional for one release to avoid breaking cached results.
**Effort**: 🔨 (2-3 days)

### 2.2 Enhanced Prompt Builder
**Task**: Update prompt builder in AIService to match new spec (environmental impact, CO₂, PPE, local guidelines).
**Dependencies**: Expanded model
**Effort**: 🔨 (1-2 days)

### 2.3 Interactive Tag Renderer
**Task**: Add interactive tag renderer (green "Multi-Use", orange "Single-Use", etc.).
**Dependencies**: Enhanced model
**Effort**: 🔨 (1 day)

### 2.4 Gamification Integration
**Task**: Replace old fixed points with calculatePoints() logic from documentation.
**Dependencies**: Enhanced model
**Effort**: 🔨 (1 day)

### 2.5 Local Guidelines Plugin
**Task**: Local guideline plugin layer – pull Bangalore BBMP rules now, design interface so other cities can plug in later.
**Dependencies**: Enhanced AI system
**Effort**: 🔨🔨 (3-4 days)

**Source**: [Enhanced AI Analysis System](../features/enhanced-ai-analysis-system.md)

---

## 3 · UI/UX Modernization

### 3.1 Classification Details Screen v2.2.2
- Adopt ModernCard package app-wide for visual consistency
- Integrate intl for all human-readable dates
- Add bookmark button (prep work – doesn't need persistence yet)

**Effort**: 🔨 (2-3 days)
**Source**: [Classification Details Modernization](../features/classification-details-screen-modernization.md)

### 3.2 Enhanced Classification Cards
- Swap list tiles → gradient cards (category-specific colours)
- Confidence badge colour rules (≥80% green, etc.)
- Hero animation link into Detail modal
- Today indicator overlay

**Note**: Roll out cards first; details screen already expects new theme tokens.
**Effort**: 🔨 (2-3 days)
**Source**: [Classification Cards Guide](../features/enhanced-classification-cards.md)

---

## 4 · Social & Community Roadmap

### 4.1 Community Cloud Sync
**Task**: Community feed cloud sync (currently local Hive only). Design simple Firestore collection (community_feed/{docId}) with same model; behind Remote Config kill-switch.
**Effort**: 🔨 (2-3 days)

### 4.2 Reactions & Comments
**Task**: Add reactions & comments – extend CommunityFeedItem model, build like/emoji bar (reuse colour mapping from Detail screen).
**Dependencies**: Cloud sync
**Effort**: 🔨 (2-3 days)

### 4.3 Weekly Leaderboard
**Task**: Aggregate points; display in new tab.
**Dependencies**: Community sync
**Effort**: 🔨 (1-2 days)

**Source**: [Community System Documentation](../features/COMMUNITY_SYSTEM_DOCUMENTATION.md)

---

## 5 · Disposal Facilities – Phase 2

### 5.1 GPS + Map View
**Task**: GPS + map view (Google Maps Flutter) – show nearest facilities; clustering for dense areas.
**Effort**: 🔨🔨 (4-5 days)

### 5.2 Image Upload Backend
**Task**: Wire Firebase Storage; thumbnails in list; moderation path.
**Effort**: 🔨 (2-3 days)

### 5.3 Push Notifications
**Task**: Send when user contribution status changes.
**Dependencies**: Image upload
**Effort**: 🔨 (1-2 days)

### 5.4 Admin Web Panel
**Task**: Firebase Console extension or small React app for reviewing contributions.
**Dependencies**: Image upload, notifications
**Effort**: 🔨🔨 (1 week)

**Source**: [Disposal Facilities Feature](../features/disposal_facilities_feature.md)

---

## 6 · AI Discovery "Easter-egg" Engine v2.2.3

### 6.1 Strongly-typed Value Objects
**Task**: Integrate strongly-typed value objects into existing discovery rule parser.
**Effort**: 🔨 (2-3 days)

### 6.2 Rule Optimization
**Task**: Index rules with RuleEvaluationOptimizer for O(1) look-ups.
**Dependencies**: Value objects
**Effort**: 🔨 (1-2 days)

### 6.3 Template Interpolation
**Task**: Template interpolation library – add to utils/ with unit tests for placeholder validation.
**Effort**: 🔨 (1 day)

### 6.4 Validation Back-fill
**Task**: Back-fill validation on all existing rules (rule.validate()) in CI.
**Dependencies**: Template system
**Effort**: 🔨 (1 day)

**Optional**: Expose authoring UI for non-devs in later sprint.
**Source**: [Enhanced AI Discovery Content System](../features/enhanced-ai-discovery-content-system.md)

---

## 7 · Quality & Observability

### 7.1 Comprehensive Testing
- Golden tests for new UI components (cards, detail screen)
- Widget tests for speed toggle, job tracker, wallet balance
**Effort**: 🔨 (2-3 days)

### 7.2 Error Monitoring
- Crashlytics + Sentry – ensure Cloud Functions errors are surfaced with context (jobId, uid)
**Effort**: 🔨 (1 day)

### 7.3 Cost Analytics
- Cost dashboard – simple Firestore → BigQuery export + Looker Studio chart for daily OpenAI spend
**Effort**: 🔨 (2-3 days)

---

## 📅 Suggested Sequencing (12-week view)

| Week | Focus Area | Key Deliverables |
|------|------------|------------------|
| **1-2** | 🔥 Hot-fixes + CI | Test pipeline working, points system stable |
| **3-4** | 💰 Token Economy | Wallet system, job queue, speed toggle |
| **5-6** | 🤖 Enhanced AI | 21-field model, new prompts, points refactor |
| **7-8** | 🎨 UI Modernization | New cards, detail screen, golden tests |
| **9-10** | 🌐 Community | Cloud sync, reactions, leaderboard |
| **11** | 📍 Facilities | Map view, image upload |
| **12** | 🔍 Discovery | Rule optimizer, template system |

**Delivery Philosophy**: Each stage leaves main branch releasable and cost-positive.

---

## Implementation Notes

### Effort Legend
- ⚡ = 0.5-1 day (quick fix)
- 🔨 = 1-3 days (small feature)
- 🔨🔨 = 4-7 days (medium feature)

### Current Status (June 24, 2025)
- ✅ **CI Pipeline**: Test compilation issues resolved
- ✅ **Codebase Analysis**: All implementation paths verified
- 📋 **Ready to Start**: Points popup fix, token wallet foundation
- 🔍 **Analysis Complete**: Race condition patterns identified

### Success Metrics
- **Cost Reduction**: 40-50% savings via batch processing
- **User Engagement**: 80% adoption of speed toggle
- **System Reliability**: 99.5% uptime for batch operations
- **Development Velocity**: All features ship on schedule

---

**Next Action**: Implement Week 1-2 hot-fixes, starting with points popup timing issue.

**Related Documentation**:
- [Comprehensive Roadmap Implementation](../features/COMPREHENSIVE_ROADMAP_FEEDBACK_IMPLEMENTATION.md)
- [Test Compilation Progress](../../TEST_COMPILATION_FIXES_2025_06_24.md)
- [Current Architecture Status](../../CLAUDE.md)