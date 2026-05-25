# Consolidated Analytics & UI Audit — ReLoop

**Date**: 2026-05-25
**Scope**: Full codebase audit: data models, UI screens, services, cloud functions, Firestore collections
**Trigger**: User questions — "can I check my profile, history, points, family invites, families, invites sent/received, failed scans, communities, and anything needing log/history/track/analytics?"
**Method**: First-principles trace from every model field to every screen/widget/service/function reference. Verified against actual code, not assumptions.
**Status**: Baseline for exploration bets F11-F14. Living reference.

---

## 1. What Was Asked

The user wanted to know what analytics/history/tracking/profile surfaces exist in the app for these questions:

1. Can I check my profile?
2. Can I check history?
3. Points collected vs used?
4. Family invites?
5. Families I'm part of?
6. I have invited vs I am invited to?
7. Scans that failed?
8. Communities created or part of?
9. Anything else needing log/history/track/analytics?

---

## 2. What Was Covered

### Codebase Audited

| Area | Files | Coverage |
|---|---|---|
| **Data models** | `lib/models/` (43 files) | Every field in every model traced to a UI/screen reference or flagged as orphaned |
| **Screens** | `lib/screens/` (49 files) | Every screen verified for what it actually renders |
| **Widgets** | `lib/widgets/` | Key widgets inspected: `profile_summary_card.dart`, `history_list_item.dart`, `analysis_progress_view.dart` |
| **Services** | `lib/services/` | `StorageService`, `FirebaseFamilyService`, `GamificationService`, `TokenService`, `AnalyticsService`, `EducationalContentAnalyticsService`, `GamificationAnalyticsService` |
| **State management** | `lib/providers/`, `lib/providers.dart` | Provider/Riverpod architecture inspected |
| **Cloud Functions** | `functions/src/` (13 files) | All backend endpoints audited |
| **Firestore schema** | `lib/services/firestore_schema_registry.dart` | All 35+ collections mapped |
| **Local storage** | Hive boxes | `userbox.hive`, `classifications.hive`, `gamificationbox.hive`, `tokenbox.hive`, etc. |
| **Exploration docs** | `docs/EXPLORATION_FRONTIER.md`, `docs/brainstorm_*.md` | Gap analysis of what exploration topics were covered vs missing |
| **Architecture docs** | `docs/architecture/`, `docs/reports/architecture/` | Verified against actual code |
| **Testing docs** | `docs/testing/` | Checked for test coverage of analytics surfaces |
| **Motto/instruction files** | `motto_v2.md`, `AGENTS.md`, `CLAUDE.md` | Ensured compliance with motto §0.3 (documentation and exploration continuity) |

### Methodology

1. **Read every model file** and listed all fields
2. **Read every screen file** and listed all rendered UI elements
3. **Cross-referenced**: for each model field, grep across entire `lib/` to find every UI consumer
4. **Flagged orphans**: fields with zero UI references
5. **Flagged dead code**: defined but never populated (e.g., 3 unused streak types)
6. **Identified missing screens**: data exists but no UI surface (12 screens)
7. **Generated unexplored features**: features requiring new product thinking (15+ concepts)
8. **Checked exploration docs**: 6 of 7 topics absent from documentation
9. **Updated frontier bets**: F11-F14 added to EXPLORATION_FRONTIER.md

---

## 3. What Was Discovered

### 3A. Verified Screen Inventory (What Actually Exists)

| Screen | Route | What It Shows | Completeness |
|---|---|---|---|
| `home_screen.dart` | `/` | Streak, challenges, educational tips, token chip, scan button | Good |
| `profile_screen.dart` | profile | Avatar, display name, email, level, rank, points total, classification count | **~30%** — 6 of ~20 available fields shown |
| `history_screen.dart` | `/history` | All classifications with filters (category, date, search, sort), per-item metadata | **~80%** — missing: points per scan, model routing |
| `result_screen.dart` | `/result` | Full classification result, impact reveal, points card, alternatives | Good |
| `token_wallet_screen.dart` | `/token-wallet` | Balance, total earned, total spent, last 20 transactions | **~70%** — missing: daily cap, conversion history, per-scan points |
| `achievements_screen.dart` | `/achievements` | 25 achievement types, 4 tiers, progress, claim status, challenges tab | Good |
| `waste_dashboard_screen.dart` | `/waste_dashboard` | Personal analytics: counts, charts, category distribution, environmental impact, streak, points | Good |
| `impact_dashboard_screen.dart` | `/impact-dashboard` | System metrics: quality, accuracy, offline queue, cost savings | Good |
| `community_screen.dart` | community | Single global feed, stats, members (placeholder) | **~40%** — no create/join/leave, members tab is stub |
| `family_dashboard_screen.dart` | family | Single family stats, members, activity, invitation stats | Single-family only |
| `family_management_screen.dart` | family | Members (roles), invitations (per-family), settings | Per-family only |
| `family_invite_screen.dart` | family | Send invite (email + QR + share) only. No received view | **~30%** — send-only |
| `family_creation_screen.dart` | family | Create family, name it, no invite during creation | Minimal |
| `classification_details_screen.dart` | detail | Reactions, comments, bookmark | Good for shared classifications |
| `model_routing_screen.dart` | `/model_routing` | **Stub** — "Future: Evidence Dashboard" | **0%** — placeholder only |
| `gamification_analytics_screen.dart` | `/gamification_analytics` | Admin: cooperative mechanic snapshots, kill criteria | Admin-only |
| `contribution_history_screen.dart` | contributions | Facility edit history (NOT classification feedback) | Different domain |
| `educational_content_screen.dart` | `/educational` | Content library, bookmarks | Good |

### 3B. Orphaned Model Fields (Data Collected, Never Rendered)

#### Category: Consumer-Facing (~25 fields)

All fields below exist in the data model, are populated during classification, have a UI purpose a user would understand, but are never displayed.

| # | Field | Model | Type | Why Orphaned |
|---|---|---|---|---|
| 1 | `waterPollutionLevel` | WasteClassification | `int?` (1-5) | Part of 13-field V2.0 Environmental Impact suite. Computed, stored, discarded |
| 2 | `soilContaminationRisk` | WasteClassification | `int?` (1-5) | Same |
| 3 | `biodegradabilityDays` | WasteClassification | `int?` | Same |
| 4 | `recyclingEfficiency` | WasteClassification | `int?` (0-100) | Same |
| 5 | `manufacturingEnergyFootprint` | WasteClassification | `double?` (kWh) | Same |
| 6 | `transportationFootprint` | WasteClassification | `double?` | Same |
| 7 | `endOfLifeCost` | WasteClassification | `String?` | Same |
| 8 | `circularEconomyPotential` | WasteClassification | `List<String>?` | Same |
| 9 | `generatesMicroplastics` | WasteClassification | `bool?` | Same |
| 10 | `humanToxicityLevel` | WasteClassification | `int?` (1-5) | Same |
| 11 | `wildlifeImpactSeverity` | WasteClassification | `int?` (1-5) | Same |
| 12 | `resourceScarcity` | WasteClassification | `String?` | Same |
| 13 | `disposalCostEstimate` | WasteClassification | `double?` | Same |
| 14 | `isSingleUse` | WasteClassification | `bool?` | Computed, never badged on any screen |
| 15 | `properEquipment` | WasteClassification | `List<String>?` | Richer than `requiredPPE` (which IS shown). Never rendered |
| 16 | `commonUses` | WasteClassification | `List<String>?` | LLM-generated usage context, never shown |
| 17 | `disagreementReason` | WasteClassification | `String?` | User's reason for correction, never displayed back |
| 18 | `product` | WasteClassification | `String?` | Product name (e.g. "Coca-Cola"), never shown |
| 19 | `barcode` | WasteClassification | `String?` | Barcode string, never displayed |
| 20 | `localGuidelinesVersion` | WasteClassification | `String?` | Regulation version used, never shown |
| 21 | `instructionsLang` | WasteClassification | `String?` | Translation language tracked. No i18n toggle in UI |
| 22 | `translatedInstructions` | WasteClassification | `Map<String, String>?` | Translated text stored. UI always shows single default |
| 23 | `pointsAwarded` | WasteClassification | `int?` | Per-scan points never shown in history list |
| 24 | `routeDecision` | WasteClassification | `String?` | Model routing decision. Zero UI (screen is stub) |
| 25 | `routeReason` | WasteClassification | `String?` | Same |
| 26 | `routeLatencyMs` | WasteClassification | `int?` | Same |
| 27 | `routeCostUsd` | WasteClassification | `double?` | Same |
| 28 | `modelRoute` | WasteClassification | `String?` | Same |
| 29 | `modelSelectionStrategy` | WasteClassification | `String?` | Same |
| 30 | `needsReview` | WasteClassification | `bool?` | Confusion with `clarificationNeeded`. Never surfaced as value |
| 31 | `reviewReason` | WasteClassification | `String?` | Why this needs review. Never shown |
| 32 | `familyId` | UserProfile | `String?` | Stored but never displayed on profile screen |
| 33 | `role` | UserProfile | `UserRole?` | Same |
| 34 | `createdAt` | UserProfile | `DateTime?` | Account creation date, not shown |
| 35-39 | `trainingConsent.*` | UserProfile | 5 sub-fields | Consent status, policy version, dates — no user-facing view |
| 40 | `GamificationProfile.weeklyStats` | Gamification | `WeeklyStats?` | Weekly classification counts/correctness — never surfaced |
| 41 | `StreakDetails.longestCount` | Gamification | `int` | Longest streak tracked, only current streak shown |
| 42 | `StreakDetails.streakFreezesAvailable` | Gamification | `int` | Freeze mechanic exists in model, no UI |
| 43 | `UserPoints.categoryPoints` | Gamification | `Map<String, int>` | Per-category point breakdown, never shown |
| 44 | `FamilyStats.categoryCounts` | Family | `Map<String, int>?` | Per-category breakdown within family, not shown |
| 45-52 | `BatchInvitation.*` | Family | 8 fields | Entire batch invite model has zero UI |
| 53+ | `ClassificationFeedback.*` | Feedback | ~16 fields | User corrections stored but no browsable history |

**Total: ~65+ fields with no UI surface.**

#### Category: ML/Ops Observability (15 fields, internal)

| Field | Model | Used In |
|---|---|---|
| `qualityScore`, `qualityReasons` | WasteClassification | `training_data_service.dart` exports only |
| `duplicateScore`, `duplicateClusterId` | WasteClassification | No UI reference |
| `rawConfidence`, `calibratedConfidence` | WasteClassification | No UI reference |
| `analysisSource`, `analysisFallbackReason` | WasteClassification | No UI reference |
| `policyPackId` | WasteClassification | No UI reference |
| `modelSource`, `analysisSessionId` | WasteClassification | No UI reference |
| `imageHash`, `imageMetrics` | WasteClassification | Internal dedup, no UI |

### 3C. Dead Code (Defined, Never Populated)

| Item | Location | Detail |
|---|---|---|
| `StreakType.dailyLearning` | `models/gamification.dart:1277` | Enum value defined, never written by any service |
| `StreakType.dailyEngagement` | `models/gamification.dart:1278` | Same |
| `StreakType.itemDiscovery` | `models/gamification.dart:1279` | Same |
| `StreakDetails` for non-classification types | `models/gamification.dart` | `GamificationProfile.streaks` Map holds all 4 types but only `dailyClassification` has data |
| `PrivacySettings` | `models/enhanced_family.dart` | Full model with 3 fields. Zero UI |
| `NotificationSettings` | `models/enhanced_family.dart` | Full model with 5 fields. Zero UI |
| `EnvironmentalImpact` (family) | `models/enhanced_family.dart` | Full model with 6 fields. Never displayed |
| `WeeklyProgress` | `models/enhanced_family.dart` | Full model with 4 fields. Never displayed |
| `model_routing_screen.dart` entire file | `screens/model_routing_screen.dart` | 112-line stub saying "Future: Evidence Dashboard" |
| `FilterOptions.subcategories` | `models/filter_options.dart` | Exists in model, not exposed in history screen filter dialog |
| `FilterOptions.materialTypes` | `models/filter_options.dart` | Same |
| `FilterOptions.isRecyclable` | `models/filter_options.dart` | Same |

### 3D. Missing Screens (Data Exists, No UI)

#### Tier 1 — High Impact (Data Available)

| # | Missing Screen | Data Source | What Would Show | Effort |
|---|---|---|---|---|
| MS1 | **Unified Activity Timeline** | Classifications + Gamification + Family + Community + Feedback + Tokens (6+ sources) | Chronological cross-cutting feed of ALL user activity. Filterable by type. Timeline narrative | High (integration) |
| MS2 | **Points Earning Breakdown** | `PointableAction` enum (10 types), `GamificationResult.pointsEarned`, `UserPoints.categoryPoints`, `pointsAwarded` per classification | Per-action earnings: "classification +10, streak +5, challenge +25". Category breakdown. Weekly/monthly totals. Level ladder | Medium |
| MS3 | **Classification Feedback History** | `ClassificationFeedback` model (16 fields), `StorageService.getAllClassificationFeedback()` | List of every correction/confirmation submitted. Before/after comparison. Review status. Admin notes | Medium |
| MS4 | **Scan Failure History** | `ClassificationState.failedRetryable/permanent` (runtime), `WasteClassification.fallback()` (persisted) | List of failed scans. Retry button. Failure reason. Image preserved for retry. Offline queue status | Medium |
| MS5 | **Streak Overview** | `StreakDetails` for all 4 types, `GamificationProfile.streaks` | Current/longest count per streak type. Calendar view. Freeze availability. Next milestone | Low |
| MS6 | **Environmental Impact on Profile** | 13 V2.0 fields per classification, aggregate impact | CO2 saved, water saved, items diverted, top categories, monthly trend | Low |
| MS7 | **Token Wallet Summary on Profile** | `TokenWallet` model (balance, earned, spent) | Balance chip, quick stats, link to full wallet | Low |

#### Tier 2 — Medium Impact

| # | Missing Screen | Gap | Effort |
|---|---|---|---|
| MS8 | **My Invitations Hub** (cross-family) | Invitations are per-family only in `family_management_screen.dart`. No user-centric "sent/received" view across all families | Medium |
| MS9 | **My Families List** | Architecture is single-family (`UserProfile.familyId` is one `String?`). No historical membership tracking | Large (architectural) |
| MS10 | **Model Routing Dashboard** | `model_routing_screen.dart` is a 112-line stub with "Future: Evidence Dashboard" text | Medium |
| MS11 | **Data Completeness Dashboard** | No aggregate view of unconfirmed classifications, items needing review, pending corrections | Low |
| MS12 | **Challenge Tracking (Comprehensive)** | Achievements screen has a Challenges tab but no standalone all-challenges-with-progress view | Low |

### 3E. Backend/Cloud Function Gaps

| Function | Purpose | Gap |
|---|---|---|
| `classifyImage` (callable) | Backend classification gateway | No user-facing operation metrics |
| `spendUserTokens` (callable) | Server-authoritative token deduction | No user-facing spend dashboard |
| `createBatchAiJob` (callable) | Batch processing | No user-facing job history |
| `processBatchJobs` (PubSub) | Scheduled batch processor | No user-facing completion notifications |
| `getBatchStats` (HTTP) | Batch statistics | Admin-only |
| `aggregateFamilyDashboardAnalytics` | Pre-computes 7d/28d family reports | No user-facing consumption dashboard |
| `evaluateOpsThresholdAlerts` | Operational hardening | No user-facing alert history |
| `healthCheck` (HTTP) | Health check | No user-facing value |
| `createReferralCode` / `redeemReferralCode` / `getReferralStats` | Referral system | No user-facing referral dashboard |

### 3F. Firestore Collection Gaps

| Collection | Used For | Gap |
|---|---|---|
| `analytics_events` | Analytics event storage | No user-facing analytics query UI |
| `family_dashboard_reports` | Pre-computed analytics | Reports exist but no user-facing consumption |
| `classification_feedback` | User corrections | Data stored, no browsing UI |
| `token_spend_ledger` | Token spend audit | Server-side only, no user-facing view |
| `community_stats` | Community aggregates | Single document, limited UI consumption |
| `subscriptions` | Subscription records | No user-facing subscription history |

### 3G. Exploration Docs Gaps

| Topic | Covered in Docs? |
|---|---|
| Analytics gap / personal analytics dashboard | **NOT COVERED** (closest: F6 touches impact numbers only) |
| Scan failure history / failed scan UI | **NOT COVERED** (closest: F9 mentions failure mode as motivation) |
| Invitation management hub | **NOT COVERED** (zero mentions in any doc) |
| Multi-family support | **NOT COVERED** |
| Points breakdown per scan | **NOT COVERED** (closest: token spend history noted as missing in synthesis) |
| Streak overview screen | **NOT COVERED** (closest: daily login bonus mentioned in strategist memo) |
| Classification feedback history | **PARTIALLY COVERED** (F3 covers corrections-as-data, but no user-facing UI discussed) |

### 3H. New Explorer Bets Added (F11-F14)

See `docs/EXPLORATION_FRONTIER.md` for full definitions:

| Bet | Focus | Preconditions |
|---|---|---|
| **F11. Personal Waste Analytics Engine** | Trended, benchmarked, actionable personal analytics | Trend computation layer, sufficient user data volume |
| **F12. Unified Activity Timeline** | Cross-cutting chronological feed of all activity | Timeline data adapter normalizing 6+ event sources |
| **F13. Scan Failure Resilience & Recovery** | Durable failure recording, retry orchestration, failure UI | `FailedClassification` persistence model (doesn't exist yet) |
| **F14. Gamification Transparency Layer** | Legible points economy, streaks, achievements, level ladder | 3 dead streak types need populating; level ladder model |

---

## 4. Detailed Screen Analysis

### 4.1 Profile Screen (`lib/screens/profile_screen.dart`)

**Current size**: ~116 lines (one of the smallest screens)

**Currently renders**:
- AppBar: "Profile"
- Loading: CircularProgressIndicator
- Error: "Failed to load profile"
- Avatar (CircleAvatar, photoUrl or fallback icon)
- Display name (conditional)
- Email (conditional)
- `ProfileSummaryCard`:
  - Level number + rank name (computed from level)
  - Points total + points to next level
  - Progress bar (level remainder %)
- Classification count (from `getAllClassifications().length`)

**Not rendered (all available in profile/gamification models)**:
- Token wallet balance, earned, spent
- Achievements (any preview or count)
- Streaks (current, longest, any type)
- Family membership (`familyId`, `role`)
- Environmental impact summary
- `createdAt` (account age)
- `trainingConsent` status
- Weekly/monthly stats mini-card
- Navigation to: token wallet, achievements, family dashboard, impact dashboard, waste dashboard

### 4.2 History Screen (`lib/screens/history_screen.dart`)

**Filters available**: Category chips (All/Wet/Dry/Hazardous/Manual Review/Saved), date range picker, search text, sort by date/name/category

**Per-item metadata**: Item name, thumbnail, timestamp, confidence%, category/subcategory/material tags, recyclability icons, status badges ("Needs review"/"Confirmed"/"Corrected"), feedback button

**Not rendered**:
- `pointsAwarded` per scan (field exists in model, never referenced)
- `routeDecision` / `modelRoute` / `analysisSource` (available in model, not shown)
- `isSingleUse` badge
- `product` / `barcode` display
- Retry button for failed/fallback scans

### 4.3 Token Wallet (`lib/screens/token_wallet_screen.dart`)

**Renders**: Balance, total earned, total spent, last updated, last 20 transactions (delta, description, timestamp), storefront (buy packs)

**Not rendered**:
- `dailyConversionsUsed` / `lastConversionDate` (model fields)
- Points-to-tokens conversion history
- Per-scan token earnings
- Daily cap remaining (shown in ZeroBalanceSheet but not here)
- Monthly spend chart

### 4.4 Family Screens

**`family_dashboard_screen.dart`**:
- Single-family dashboard only
- Family header, management buttons, achievements card (classifications/points/streak)
- Cooperative mechanics section, members horizontal scroll, invitation stats
- Recent family activity (last 5), environmental impact cards
- No-family state: create or join buttons

**`family_management_screen.dart`**:
- 3 tabs: Members (list with roles/actions), Invitations (per-family list), Settings (editable fields)
- Gaps: no "families I've been part of" history, no cross-family invitation view

**`family_invite_screen.dart`**:
- Send-only: email invite form + QR code generation + share link
- No received invitations view
- No cross-family invitation hub

### 4.5 Community Screen (`lib/screens/community_screen.dart`)

**Renders**: 3 tabs: Feed (global activity stream), Stats (aggregate community numbers), Members (placeholder)
**Not rendered**: No community creation, no "my communities" list, no join/leave flow

### 4.6 Waste Dashboard (`lib/screens/waste_dashboard_screen.dart`)

**Renders**: Mission Control (ring+stats), Quick Actions, Daily Highlight, Category Spotlight, Summary Stats, Activity charts (daily/weekly), Category pie chart, Top subcategories bar chart, Recent classifications grid, Environmental impact, Gamification section

**Gap**: No trendlines over configurable time ranges, no peer benchmarking, no export

### 4.7 Impact Dashboard (`lib/screens/impact_dashboard_screen.dart`)

**Renders**: Classification Quality (high/low confidence), Accuracy Score (confirmations vs corrections), Offline Queue Performance, Cost Savings

**Gap**: System-focused, not user-behavior-focused

### 4.8 Result Screen (`lib/screens/result_screen.dart`)

**Renders**: Classification result, environmental impact reveal, points card, alternatives, educational content, share/feedback

**Gap**: 13 V2.0 environmental fields computed but only a subset shown on the "Impact Reveal" section. Fields like `waterPollutionLevel`, `soilContaminationRisk`, `biodegradabilityDays` not rendered

### 4.9 Model Routing Screen (`lib/screens/model_routing_screen.dart`)

**State**: **Stub/placeholder** — 112 lines total, shows only:
- Available Strategies (enum values listed)
- Evidence Collection (what data is recorded)
- "Future: Evidence Dashboard" (line 79)

### 4.10 Gamification Analytics (`lib/screens/gamification_analytics_screen.dart`)

**Renders**: Admin-only cooperative mechanic engagement snapshots. Participation rate, goal completion rate, household streak, kill criteria, charts
**Gap**: Admin-only, no user-facing gamification breakdown

---

## 5. Services Analysis

### 5.1 `AnalyticsService` (`lib/services/analytics_service.dart`)

**Capabilities**: Full session management, event tracking with consent gating, classification tracking, gamification tracking, social tracking, performance tracking, interaction tracking, content tracking, error tracking, analytics queries
**Gaps**:
- Analytics queries return raw data but no pre-built UI consumes them as a user-facing dashboard
- `getUserAnalytics()`, `getSystemAnalytics()`, `getComprehensiveAnalytics()` exist but have no dedicated screen
- Pending event queue (max 1000 events) but no user visibility into queued/synced state

### 5.2 `StorageService` (`lib/services/storage_service.dart`)

**Capabilities**: Full Hive-based local storage for classifications, gamification, tokens, settings
**Gaps**:
- `getAllClassificationFeedback()` exists (line 1462) but no screen consumes it as a browsable list
- No aggregation method for failed scan count
- No method for retrieving "pending review" classifications

### 5.3 `FirebaseFamilyService` (`lib/services/firebase_family_service.dart`)

**Gaps**:
- No `getUserFamilies()`, `getFamiliesForUser()`, or `getUserFamilyHistory()` methods
- All operations scoped to a single `familyId`
- No cross-family invitation query

### 5.4 `TokenService` (`lib/services/token_service.dart`)

**Gaps**:
- Daily conversion limit (5/day, 100:1 rate) enforced but not visible in token wallet UI
- No per-scan token cost breakdown in UI
- No token velocity/usage analytics

### 5.5 `GamificationService` (`lib/services/gamification_service.dart`)

**Gaps**:
- Only `StreakType.dailyClassification` is populated (lines 180-181, 217-218, 257-258, 1120, 1868-1869, 1993)
- `dailyLearning`, `dailyEngagement`, `itemDiscovery` are never written to
- `PrivacySettings` and `NotificationSettings` models have zero service consumption

---

## 6. Cloud Functions / Backend Analysis

| Endpoint | Type | Purpose | User-Facing UI Exists? |
|---|---|---|---|
| `classifyImage` | Callable | Backend classification | Yes (result screen) |
| `spendUserTokens` | Callable | Token deduction | Partial (token wallet shows balance) |
| `createBatchAiJob` | Callable | Create batch job | No dedicated progress UI |
| `processBatchJobs` | PubSub | Process batches | No |
| `getBatchStats` | HTTP GET | Batch statistics | No (admin) |
| `createCheckoutSession` | Callable | Subscription checkout | Yes (purchase flow) |
| `dodopaymentsWebhook` | HTTP POST | Payment webhook | No |
| `getR2UploadUrl` | Callable | File upload | Yes (image capture) |
| `createReferralCode` | Callable | Create referral | No user-facing referral dashboard |
| `redeemReferralCode` | Callable | Redeem referral | No |
| `getReferralStats` | Callable | Referral stats | No |
| `aggregateFamilyDashboardAnalytics` | PubSub | Pre-compute family reports | Reports exist, no consumption UI |
| `aggregateCommunityStats` | PubSub | Community aggregates | Yes (community stats tab) |
| `generateDisposal` | Callable | Disposal instructions | Yes (result screen) |
| `getTrainingReviewQueue` | Callable | Training queue | No (admin) |
| `evaluateOpsThresholdAlerts` | PubSub | Ops alerts | No |
| `healthCheck` | HTTP GET | Health | No |

---

## 7. Data Model ↔ Screen Mapping (Master Table)

### WasteClassification (85+ fields)

| Field | Screen | Status |
|---|---|---|
| `id` | All | ✅ |
| `itemName` | History, Result, Dashboard, Detail, Feed | ✅ |
| `category` | History, Result, Dashboard, Detail, Feed | ✅ |
| `subCategory` | History, Result, Detail | ✅ |
| `recyclingCode` | Result | ✅ |
| `explanation` | Result | ✅ |
| `disposalMethod` | None (internal) | ⛔ Not displayed |
| `disposalInstructions` | Result | ✅ |
| `disposalInstructions.steps` | Result | ✅ |
| `imageUrl` | History, Result, Dashboard, Detail | ✅ |
| `confidence` | History, Result | ✅ |
| `rawConfidence` | None | ⛔ |
| `calibratedConfidence` | None | ⛔ |
| `modelVersion` | Result (Category Snapshot) | ✅ |
| `modelSource` | None | ⛔ |
| `classificationLayer` | None (runtime) | ⛔ |
| `processingTimeMs` | None | ⛔ |
| `analysisSessionId` | None | ⛔ |
| `isRecyclable` | History, Result, Dashboard | ✅ |
| `isCompostable` | History, Result | ✅ |
| `isSingleUse` | None | ⛔ |
| `requiresSpecialDisposal` | History, Result | ✅ |
| `colorCode` | None (internal) | ⛔ |
| `riskLevel` | Result | ✅ |
| `requiredPPE` | Result | ✅ |
| `properEquipment` | None | ⛔ |
| `brand` | Result | ✅ |
| `product` | None | ⛔ |
| `barcode` | None | ⛔ |
| `isSaved` | History | ✅ |
| `userConfirmed` | History (badge) | ✅ |
| `userCorrection` | History (badge), Result | ✅ |
| `disagreementReason` | None | ⛔ |
| `userNotes` | None (Result has space?) | ⛔ |
| `viewCount` | None | ⛔ |
| `clarificationNeeded` | History (badge) | ✅ |
| `confidence` | History, Result | ✅ |
| `alternatives` | Result | ✅ |
| `suggestedAction` | Result | ✅ |
| `hasUrgentTimeframe` | Result | ✅ |
| `instructionsLang` | None | ⛔ |
| `translatedInstructions` | None | ⛔ |
| `source` | None (internal) | ⛔ |
| `timestamp` | History, Result, Dashboard, Detail | ✅ |
| `pointsAwarded` | None | ⛔ |
| `environmentalImpact` | Result (partial) | Partial |
| `waterPollutionLevel` | None | ⛔ |
| `soilContaminationRisk` | None | ⛔ |
| `biodegradabilityDays` | None | ⛔ |
| `recyclingEfficiency` | None | ⛔ |
| `manufacturingEnergyFootprint` | None | ⛔ |
| `transportationFootprint` | None | ⛔ |
| `endOfLifeCost` | None | ⛔ |
| `circularEconomyPotential` | None | ⛔ |
| `generatesMicroplastics` | None | ⛔ |
| `humanToxicityLevel` | None | ⛔ |
| `wildlifeImpactSeverity` | None | ⛔ |
| `resourceScarcity` | None | ⛔ |
| `disposalCostEstimate` | None | ⛔ |
| `bbmpComplianceStatus` | Result | ✅ |
| `localGuidelinesVersion` | None | ⛔ |
| `qualityScore` | None (training data only) | ⛔ |
| `qualityReasons` | None (training data only) | ⛔ |
| `duplicateScore` | None | ⛔ |
| `duplicateClusterId` | None | ⛔ |
| `needsReview` | None (used for training) | ⛔ |
| `reviewReason` | None | ⛔ |
| `routeDecision` | None | ⛔ |
| `routeReason` | None | ⛔ |
| `policyPackId` | None | ⛔ |
| `modelRoute` | None | ⛔ |
| `routeLatencyMs` | None | ⛔ |
| `routeCostUsd` | None | ⛔ |
| `modelSelectionStrategy` | None | ⛔ |
| `isOfflineHint` | Transient (not persisted) | N/A |
| `relatedItems` | Result | ✅ |
| `commonUses` | None | ⛔ |
| `alternativeOptions` | Result | ✅ |
| `localRegulations` | Result | ✅ |
| `materials` | History (tag) | ✅ |

### UserProfile

| Field | Screen | Status |
|---|---|---|
| `id` | Internal | ✅ |
| `displayName` | Profile, Home, Family, Community | ✅ |
| `email` | Profile | ✅ |
| `photoUrl` | Profile, Home, Family, Community | ✅ |
| `familyId` | None (internal lookup) | ⛔ Not displayed |
| `role` | None | ⛔ |
| `createdAt` | None | ⛔ |
| `lastActive` | None (internal) | ⛔ |
| `preferences` | Settings (consumed indirectly) | ✅ (indirect) |
| `gamificationProfile` | Home, Dashboard (consumed) | ✅ (partial) |
| `tokenWallet` | Token Wallet screen | ✅ (separate screen) |
| `tokenWallet.balance` | Profile? | ⛔ Not on profile |
| `tokenTransactions` | Token wallet (last 20) | ✅ (partial) |
| `trainingConsent` | None | ⛔ |

### Gamification Models

| Model/Field | Screen | Status |
|---|---|---|
| `UserPoints.total` | Profile, Home, Dashboard | ✅ |
| `UserPoints.weeklyTotal` | None | ⛔ |
| `UserPoints.monthlyTotal` | None | ⛔ |
| `UserPoints.level` | Profile, Home, Dashboard | ✅ |
| `UserPoints.categoryPoints` | None | ⛔ |
| `StreakDetails.dailyClassification.currentCount` | Home, Dashboard | ✅ |
| `StreakDetails.dailyClassification.longestCount` | Achievements (partial) | ✅ (partial) |
| `StreakDetails.dailyClassification.streakFreezesAvailable` | None | ⛔ |
| `StreakDetails.dailyLearning.*` | None (never populated) | ⛔ Dead code |
| `StreakDetails.dailyEngagement.*` | None (never populated) | ⛔ Dead code |
| `StreakDetails.itemDiscovery.*` | None (never populated) | ⛔ Dead code |
| `Achievement.*` | Achievements screen | ✅ |
| `Achievement.progress` | Achievements screen | ✅ |
| `Achievement.threshold` | Achievements screen | ✅ |
| `Achievement.unlocksAtLevel` | None | ⛔ |
| `GamificationProfile.achievements` | Achievements screen | ✅ |
| `GamificationProfile.activeChallenges` | Home, Achievements | ✅ |
| `GamificationProfile.completedChallenges` | Achievements | ✅ |
| `GamificationProfile.weeklyStats` | None | ⛔ |
| `Challenge.*` | Home, Achievements | ✅ (partial) |
| `PointableAction.*` | None | ⛔ Not shown as breakdown |

### Family Models

| Model/Field | Screen | Status |
|---|---|---|
| `Family.name` | Dashboard, Management | ✅ |
| `Family.description` | Dashboard, Management | ✅ |
| `Family.imageUrl` | Dashboard | ✅ |
| `Family.members.*` | Dashboard (scroll), Management (list) | ✅ |
| `Family.settings.*` | Management (Settings tab) | ✅ |
| `FamilyStats.totalClassifications` | Dashboard | ✅ |
| `FamilyStats.totalPoints` | Dashboard | ✅ |
| `FamilyStats.currentStreak` | Dashboard | ✅ |
| `FamilyStats.categoryCounts` | None | ⛔ |
| `FamilyStats.memberCount` | Dashboard | ✅ |
| `UserStats.totalPoints` | Management (member list) | ✅ |
| `UserStats.totalClassifications` | Management (member list) | ✅ |
| `UserStats.currentStreak` | None | ⛔ |
| `UserStats.bestStreak` | None | ⛔ |
| `UserStats.categoryBreakdown` | None | ⛔ |
| `UserStats.achievements` (list) | None | ⛔ |
| `FamilyInvitation.invitedEmail` | Management (Invitations tab) | ✅ |
| `FamilyInvitation.status` | Management (Invitations tab) | ✅ |
| `FamilyInvitation.respondedAt` | None | ⛔ |
| `BatchInvitation.*` | None | ⛔ Zero UI |
| `FamilyGoal.*` | Dashboard (Cooperative section) | ✅ |
| `FamilyTask.*` | Dashboard (Cooperative section) | ✅ |
| `HouseholdStreak.*` | Dashboard | ✅ |
| `CooperativeChallenge.*` | Dashboard | Partial |

---

## 8. Firestore Schema (All Collections)

From `lib/services/firestore_schema_registry.dart`:

| Collection | Purpose | UI Surface |
|---|---|---|
| `users` | User profiles | ✅ Profile, Settings |
| `classifications` | Subcollection — waste classifications | ✅ History, Result, Dashboard |
| `gamification` | Gamification data | ✅ Home, Achievements, Dashboard |
| `leaderboard_allTime` | All-time leaderboard | ✅ Leaderboard screen |
| `leaderboard_weekly` | Weekly leaderboard | ✅ Leaderboard screen |
| `community_feed` | Community activity feed | ✅ Community screen |
| `community_stats` | Aggregate community stats | ✅ Community Stats tab |
| `community_challenges` | Community challenges | ✅ Partial |
| `families` | Family documents | ✅ Dashboard, Management |
| `invitations` | Family invitations | ✅ Per-family Management tab |
| `shared_classifications` | Family-shared classifications | ✅ Family Dashboard |
| `family_stats` | Family aggregated stats | ✅ Family Dashboard |
| `family_goals` | Subcollection — family goals | ✅ Family Dashboard |
| `family_tasks` | Subcollection — family tasks | ✅ Family Dashboard |
| `cooperative_challenges` | Subcollection — coop challenges | ✅ Family Dashboard |
| `household_streaks` | Subcollection — household streaks | ✅ Family Dashboard |
| `parent_child_missions` | Subcollection — missions | ✅ Family Dashboard |
| `cooperative_snapshots` | Mechanic engagement snapshots | ⛔ Admin-only `gamification_analytics_screen.dart` |
| `classification_feedback` | User corrections | ⛔ **No browsing UI** |
| `training_candidates` | Training data candidates | ⛔ Admin-only |
| `training_labels` | Labels for candidates | ⛔ Admin-only |
| `training_dataset_versions` | Dataset manifests | ⛔ Admin-only |
| `ai_jobs` | AI batch jobs | ⛔ Partial (`job_queue_screen.dart`) |
| `analytics_events` | App analytics events | ⛔ **No user-facing UI** |
| `family_dashboard_reports` | Pre-computed family analytics | ⛔ **Reports exist, no consumer UI** |
| `admin_classifications` | Admin review | ⛔ Admin-only |
| `admin_user_recovery` | Admin recovery | ⛔ Admin-only |
| `admin` | General admin data | ⛔ Admin-only |
| `society_policies` | Society/RWA waste policies | ⛔ No direct UI |
| `disposal_instructions` | Reference disposal instructions | ✅ (used in classification) |
| `disposal_locations` | Disposal facilities | ✅ Map/list screens |
| `user_contributions` | Facility edit suggestions | ✅ Contribution history |
| `subscriptions` | Subscription records | ✅ Premium flow |
| `webhook_events` | Idempotency tracking | ⛔ Server-side only |
| `referral_codes` | Referral codes | ⛔ **No user-facing referral UI** |
| `referral_redemptions` | Referral redemptions | ⛔ **No user-facing referral UI** |
| `token_spend_ledger` | Token spend audit trail | ⛔ Server-side only |
| `notifications` | Push notification records | ⛔ Internal |

---

## 9. Hive Local Storage (Boxes)

| Box | Purpose | UI Surface |
|---|---|---|
| `userbox.hive` | User profile, settings | Profile, Settings |
| `classifications.hive` | Classification history | History, Dashboard |
| `gamificationbox.hive` | Points, streaks, achievements | Home, Achievements, Dashboard |
| `tokenbox.hive` | Token wallet | Token Wallet |
| `classification_queue.hive` | Offline classification queue | Impact Dashboard |
| `cachebox.hive` | Classification cache | Internal |
| `settingsbox.hive` | App settings | Settings |
| `premium_features.hive` | Premium state | Premium screen |

---

## 10. Unexplored Features (No Data, No UI — New Product Concepts)

### Category A: Behavioral Analytics & Motivation

| Concept | Description | Relationship to Existing |
|---|---|---|
| **Personal Waste Audit (Report Card)** | Periodic (weekly/monthly) summary: trends, milestones, comparisons, recommendations | Extends waste dashboard & impact dashboard |
| **Waste Reduction Goal Tracker** | Set personal goals ("reduce plastic 20%") with progress, streak, deadline | Extends gamification challenges |
| **Peer Benchmarking** | "You sorted 15% more than similar households in Bangalore" | Requires aggregation service |
| **Waste-Free Shopping List** | Pre-purchase packaging recyclability check | New feature, uses classification pipeline |
| **Carbon Offset Integration** | One-click offset for unavoidable waste | New feature, external integration |
| **Waste Diary / Journal** | Chronological photo story with notes | New view over existing classification data |

### Category B: Social & Community

| Concept | Description | Relationship to Existing |
|---|---|---|
| **Community Challenges Marketplace** | User-created, joinable challenges | Extends challenge system |
| **Family Points Competition** | Per-member breakdown, weekly winners | Extends family dashboard |
| **Waste Pledge / Commitment** | Public commitments with social accountability | New social feature |
| **Neighborhood Heatmap** | Aggregated anonymous waste data on map | New visualization |
| **Shareable Impact Badges** | Instagram/LinkedIn cards | New export feature |

### Category C: Education & Growth

| Concept | Description | Relationship to Existing |
|---|---|---|
| **AI Training Progress Dashboard** | "You taught the AI X things" — visible contribution | Uses feedback data |
| **Structured Learning Paths** | Composting 101 → Zero Waste Home, with certifications | Extends educational content |
| **Seasonal Waste Guide** | Location-aware tips for festivals, holidays | New content type |
| **Multi-Language Disposal UI** | Full i18n surface (pipeline exists, UI doesn't) | Unlocks existing translatedInstructions |

### Category D: Power User & Ops

| Concept | Description | Relationship to Existing |
|---|---|---|
| **Recycling Barcode Database** | Scan barcode → instant disposal. Community-contributed | Extends classification pipeline |
| **Recurring Item Tracker** | Track regular disposals, get sustainable alternatives | New tracking feature |
| **Waste API for Smart Home** | Webhook/API for voice assistants, smart bins | New infrastructure |
| **Full Data Export (JSON/PDF)** | Beyond current CSV-only export | Extends data_export_screen |

---

## 11. Key Metrics

| Metric | Count |
|---|---|
| Model files | 43 |
| Screen files | 49 |
| Database collections (Firestore) | 35+ |
| Cloud Functions | 18 |
| Total WasteClassification fields | ~85+ |
| Fields with no UI surface | ~65+ |
| Missing screens (data exists, no UI) | 12 |
| Dead code (defined, never populated) | 4+ models, 3 enum values |
| Unexplored feature concepts | 15+ |
| Exploration doc gaps (topics absent) | 6 of 7 |
| New frontier bets added | 4 (F11-F14) |
| Streak types defined but unused | 3 of 4 |
| Hive local boxes | 8 |

---

## 12. Files Created/Updated

| File | Action |
|---|---|
| `docs/EXPLORATION_FRONTIER.md` | **Updated** — added F11 (Personal Waste Analytics Engine), F12 (Unified Activity Timeline), F13 (Scan Failure Resilience & Recovery), F14 (Gamification Transparency Layer) |
| `docs/reports/analytics/ANALYTICS_UI_GAP_ANALYSIS_2026-05-25.md` | **Created** — full gap analysis with parts 1-6, file references, severity ratings |
| `docs/reports/analytics/CONSOLIDATED_ANALYTICS_AUDIT_2026-05-25.md` | **Created** — this document |

---

## 13. Recommendations (Priority Order)

### Immediate (Low Effort, High Impact)

1. **Surface `pointsAwarded` in history list** — add a "+X pts" badge on each history item. Data exists, 1 field to render.
2. **Add token balance chip to profile screen** — `TokenWallet.balance` already loaded in providers. 1-line widget addition.
3. **Add streak types `dailyLearning`/`dailyEngagement`/`itemDiscovery` population** — populate from existing activity signals (content viewed = learning, social interaction = engagement, unique categories = discovery). Unlocks 3 dead code paths.
4. **Show `isSingleUse` badge on result screen** — bool field, single badge render.

### Short Term (Medium Effort, High Impact)

5. **Build Points Earning Breakdown (MS2)** — `PointableAction` enum + `GamificationResult` already structured for this. New screen or bottom sheet.
6. **Build Classification Feedback History (MS3)** — `getAllClassificationFeedback()` exists. New screen with filterable list.
7. **Build Scan Failure History (MS4)** — requires `FailedClassification` persistence model. Most complex of the short-term items.
8. **Build Streak Overview (MS5)** — `GamificationProfile.streaks` Map already populated for `dailyClassification`. New screen with all 4 types once populated.

### Medium Term

9. **Build Unified Activity Timeline (MS1)** — requires event normalizer/adapter across 6+ sources. Architectural investment.
10. **Build My Invitations Hub (MS8)** — requires cross-family query support in `FirebaseFamilyService`.
11. **Build Model Routing Dashboard (MS10)** — replace 112-line stub with real evidence display.
12. **Surface 13 V2.0 environmental fields** — determine which subset to show, where, and how.

### Long Term

13. **Multi-family support (MS9)** — architectural change to `UserProfile.familyId` → `List<String> familyIds`.
14. **Peer benchmarking** — requires aggregation service and sufficient user base.
15. **Personal Waste Audit** — requires trend computation layer.

---

## 14. References

### Screens
- `lib/screens/profile_screen.dart`
- `lib/screens/history_screen.dart`
- `lib/screens/token_wallet_screen.dart`
- `lib/screens/family_dashboard_screen.dart`
- `lib/screens/family_management_screen.dart`
- `lib/screens/family_invite_screen.dart`
- `lib/screens/family_creation_screen.dart`
- `lib/screens/community_screen.dart`
- `lib/screens/waste_dashboard_screen.dart`
- `lib/screens/impact_dashboard_screen.dart`
- `lib/screens/gamification_analytics_screen.dart`
- `lib/screens/achievements_screen.dart`
- `lib/screens/classification_details_screen.dart`
- `lib/screens/model_routing_screen.dart`
- `lib/screens/result_screen.dart`
- `lib/screens/contribution_history_screen.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/data_export_screen.dart`
- `lib/screens/educational_content_screen.dart`

### Models
- `lib/models/waste_classification.dart`
- `lib/models/user_profile.dart`
- `lib/models/gamification.dart`
- `lib/models/enhanced_family.dart`
- `lib/models/family_invitation.dart`
- `lib/models/classification_state.dart`
- `lib/models/filter_options.dart`

### Services
- `lib/services/storage_service.dart`
- `lib/services/firebase_family_service.dart`
- `lib/services/gamification_service.dart`
- `lib/services/token_service.dart`
- `lib/services/analytics_service.dart`
- `lib/services/firestore_schema_registry.dart`

### Cloud Functions
- `functions/src/` (13 files)

### Docs
- `docs/EXPLORATION_FRONTIER.md`
- `docs/reports/analytics/ANALYTICS_UI_GAP_ANALYSIS_2026-05-25.md`
- `motto_v2.md`
