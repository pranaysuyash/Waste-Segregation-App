# Analytics / Tracking / History UI Gap Analysis

**Date**: 2026-05-25
**Scope**: Full codebase audit: data models vs actual UI surfaces, missing screens, unexplored features
**Method**: First-principles trace from every model field to every screen/widget reference
**Status**: Baseline for exploration bets F11-F14

---

## Part 1: What Exists (Verified Against Actual Code)

### Screens That Answer Your Questions Today

| Your Question | Screen | What It Actually Shows |
|---|---|---|
| Check my profile | `profile_screen.dart` | Avatar, display name, email, level, rank name, points total, classification count. **NOT shown**: token wallet, achievements, streaks, family membership, environmental impact, `createdAt`, `trainingConsent` |
| Check history | `history_screen.dart` | All classifications with filters (category, date, search, sort). Per-item: name, thumbnail, timestamp, confidence%, category/subcategory/material tags, recyclability icons, "Needs review"/"Confirmed"/"Corrected" badges, feedback button |
| Points collected vs used | `token_wallet_screen.dart` | Balance, total earned, total spent, last 20 transactions (delta + description + timestamp). **NOT shown**: per-scan points, points-vs-tokens conversion history, daily conversion cap remaining, monthly totals, category breakdown |
| Family invites | `family_invite_screen.dart` | **Send** invites only (email + QR code + share link). No view of sent vs received. No cross-family invite hub |
| Families I'm part of | `family_dashboard_screen.dart` | **Single** family dashboard only. Architecture is single-family (`UserProfile.familyId` is one `String?`). No "My Families" list, no historical family membership |
| I have invited vs I am invited to | `family_management_screen.dart` (Invitations tab) | Shows invites **per family** only. **No** user-centric "My Invitations" hub across all families |
| Scans that failed | No dedicated screen | Failures are transient in `ClassificationState` machine. Persisted as fallback classifications ("Requires Manual Review", "Unidentified Item - Fallback"). No failure count, no retry history, no "error" badge |
| Communities created / part of | `community_screen.dart` | Single **global** community feed. No community creation, no "my communities" list, no membership management. Members tab is a "coming soon" placeholder |
| Log/history/track/analytics | `waste_dashboard_screen.dart` | Personal: classification count, active days, category spotlight, daily/weekly bar chart, category pie chart, top subcategories, recent classifications grid, environmental impact (CO2, water, recycling rate), streak, points |
| | `impact_dashboard_screen.dart` | System: classification quality (high/low confidence), accuracy rate, offline queue stats, cost savings |
| | `gamification_analytics_screen.dart` | Admin: cooperative mechanic snapshots, participation rate, goal completion, household streaks |
| | `achievements_screen.dart` | 25 achievement types across 4 tiers, earned dates, progress, claim status |
| | `classification_details_screen.dart` | Single shared classification: reactions, comments, bookmark |

---

## Part 2: What Exists in Data Models but Has NO UI Surface

### 2A. Consumer-Facing Data, Never Rendered (~25 fields)

| Field | Model | Why This Is a Gap |
|---|---|---|
| `waterPollutionLevel` | WasteClassification | One of 13 V2.0 environmental impact fields. Full "Enhanced AI Analysis" feature computed then discarded |
| `soilContaminationRisk` | WasteClassification | Same — computed, stored, never shown |
| `biodegradabilityDays` | WasteClassification | Same |
| `recyclingEfficiency` | WasteClassification | Same |
| `manufacturingEnergyFootprint` | WasteClassification | Same |
| `transportationFootprint` | WasteClassification | Same |
| `endOfLifeCost` | WasteClassification | Same |
| `circularEconomyPotential` | WasteClassification | Same |
| `generatesMicroplastics` | WasteClassification | Same |
| `humanToxicityLevel` | WasteClassification | Same |
| `wildlifeImpactSeverity` | WasteClassification | Same |
| `resourceScarcity` | WasteClassification | Same |
| `disposalCostEstimate` | WasteClassification | Same |
| `isSingleUse` | WasteClassification | Computed per-classification, never badged |
| `properEquipment` | WasteClassification | Richer safety list than `requiredPPE`, never shown |
| `commonUses` | WasteClassification | LLM-generated usage context, never shown |
| `disagreementReason` | WasteClassification | User's reason for correction, never displayed back |
| `product` | WasteClassification | Product name (e.g. "Coca-Cola"), never shown |
| `barcode` | WasteClassification | Barcode string, never displayed |
| `localGuidelinesVersion` | WasteClassification | Which regulation version was applied, never shown |
| `instructionsLang` | WasteClassification | Translation language tracked but no i18n toggle in UI |
| `translatedInstructions` | WasteClassification | Translated text stored in Map, UI always shows single default |
| `pointsAwarded` | WasteClassification | Per-scan points never shown in history list |
| `routeDecision` / `routeReason` / `routeLatencyMs` / `routeCostUsd` / `modelRoute` / `modelSelectionStrategy` | WasteClassification | Full model routing telemetry — never surfaced. `model_routing_screen.dart` is a stub that says "Future: Evidence Dashboard" |
| `familyId` / `role` | UserProfile | Stored but never displayed on profile screen |
| `createdAt` | UserProfile | Account creation date, not shown |
| `trainingConsent` (5 sub-fields) | UserProfile | Consent status/policy version/dates, no user-facing view |
| `GamificationProfile.weeklyStats` | Gamification | Weekly classification counts, correctness, categories — never surfaced |
| `StreakDetails.longestCount` | Gamification | Longest streak tracked, only current streak shown |
| `StreakDetails.streakFreezesAvailable` | Gamification | Freeze mechanic exists in model, no UI |
| `UserPoints.categoryPoints` | Gamification | Per-category point breakdown, never shown |
| `FamilyStats.categoryCounts` | Family | Per-category breakdown within family, not shown |
| `BatchInvitation` (all fields) | Family | Entire batch invite model has zero UI |
| `ClassificationFeedback` (all fields) | Feedback | User corrections stored but no browsable history — only aggregate accuracy rate is computed |

### 2B. Defined but Never Populated (Dead Code)

| Item | Type | Detail |
|---|---|---|
| `StreakType.dailyLearning` | Enum value | Defined, never written to by any service |
| `StreakType.dailyEngagement` | Enum value | Defined, never written to by any service |
| `StreakType.itemDiscovery` | Enum value | Defined, never written to by any service |
| `StreakDetails` for non-classification types | Model | `GamificationProfile.streaks` can hold all 4 types but only `dailyClassification` is populated |
| `NotificationSettings` | Model | Full notification preference model with zero UI |
| `PrivacySettings` | Model | Full privacy toggle model with zero UI |
| `EnvironmentalImpact` (family) | Model | Environmental impact stats in family model, never displayed |
| `WeeklyProgress` | Model | Weekly goal tracking in data, no UI |

---

## Part 3: What SHOULD Exist (Missing Screens/Views)

### Tier 1: High Impact, Existing Data

| Missing Screen | Data Available | Why It Matters |
|---|---|---|
| **Unified Activity Timeline** | 6+ event sources (classifications, gamification, family, community, feedback, tokens) | Today, activity is siloed across 10+ screens. No cross-cutting narrative |
| **Points Earning Breakdown** | `PointableAction` enum (10 action types), `GamificationResult.pointsEarned`, `UserPoints.categoryPoints` | User sees "+10 points" but can't trace source or see per-category breakdown |
| **Classification Feedback History** | `ClassificationFeedback` model, `StorageService.getAllClassificationFeedback()` | User corrections are stored but user can't browse their own feedback history |
| **Scan Failure History** | `ClassificationState.failedRetryable/permanent`, `WasteClassification.fallback()` | Failures are transient — no persistent record, no retry surface |
| **Environmental Impact on Profile** | `WasteClassification` V2.0 environmental fields (13 fields) | Zero impact metrics on the one screen users visit most |
| **Streak Overview (All 4 Types)** | `StreakDetails` model, 4 streak types defined | Only daily classification streak is shown; other 3 are dead code |
| **Token Wallet Summary on Profile** | `TokenWallet` model, `token_wallet_screen.dart` exists separately | Profile has no token balance display despite home screen showing it |

### Tier 2: Medium Impact, Partial/No Data

| Missing Screen | Gap |
|---|---|
| **My Invitations Hub** (cross-family) | Invitations are per-family only. No user-centric "sent/received" view across all families |
| **My Families List** | Architecture is single-family. No historical family membership tracking |
| **Model Routing Dashboard** | `model_routing_screen.dart` is a stub saying "Future: Evidence Dashboard" |
| **Data Completeness Dashboard** | No aggregate view of "N items need your review," "M corrections pending admin review" |
| **Challenge Tracking (Comprehensive)** | Achievements screen has a Challenges tab but no standalone all-challenges-with-progress view |

---

## Part 4: What COULD Exist (Unexplored Features)

These are features not derivable from existing data models — they require new product thinking:

### Category A: Behavioral Analytics & Motivation

| Feature | Concept |
|---|---|
| **Personal Waste Audit (periodic report card)** | Weekly/monthly "Spotify Wrapped for waste" — trends, milestones, comparisons, recommendations |
| **Waste Reduction Goal Tracker** | Set personal goals ("reduce plastic by 20%") with progress bar, streak, deadline |
| **Peer Benchmarking** | "You sorted 15% more than similar households in Bangalore" — anonymized cohort comparison |
| **Waste-Free Shopping List** | Before buying, scan to check packaging recyclability. Builds over time into a personal database |
| **Carbon Offset Integration** | One-click offset for unavoidable waste — connects to offset programs |
| **Waste Diary / Journal** | Chronological photo story of your waste journey with notes, tagged by category |

### Category B: Social & Community

| Feature | Concept |
|---|---|
| **Community Challenges Marketplace** | User-created challenges others can join ("Plastic-Free Week Challenge") |
| **Family Points Competition Dashboard** | Per-member contribution breakdown, friendly competition, weekly winners |
| **Waste Pledge / Commitment System** | Public commitments ("I will compost for 30 days") with social accountability |
| **Neighborhood Heatmap** | Aggregated anonymous waste data shown on a map — what does your area throw away most? |
| **Environmental Impact Badges (Shareable)** | Generate Instagram/LinkedIn cards showing your impact |

### Category C: Education & Growth

| Feature | Concept |
|---|---|
| **AI Training Progress Dashboard** | "You've helped the AI learn X new things" — make correction feedback visible as contribution |
| **Structured Learning Paths** | "Composting 101" → "Plastic Reduction" → "Zero Waste Home" with certifications |
| **Seasonal Waste Guide** | Location-aware tips for festival wrapping, holiday food waste, seasonal items |
| **Multi-Language Disposal Guides** | Full i18n surface for translated disposal instructions (pipeline exists, UI doesn't) |

### Category D: Power User & Ops

| Feature | Concept |
|---|---|
| **Recycling Barcode Scanner Database** | Scan barcode → instant disposal. Community-contributed database |
| **Subscription / Recurring Item Tracker** | Track regularly disposed items, get reminders for sustainable alternatives |
| **Waste API for Smart Home** | Webhook/API for smart bins, voice assistants, home automation integration |
| **Bulk / Community Buying Groups** | Organize group purchases of eco-friendly products with neighbors |
| **Full Data Export with Format Options** | Currently CSV only — add JSON, PDF report, per-category extracts |

---

## Part 5: Exploration Bets Added to Frontier

See `EXPLORATION_FRONTIER.md` for the following new frontier bets:

| Bet | Focus | Related Gaps |
|---|---|---|
| **F11. Personal Waste Analytics Engine** | Trended, benchmarked, actionable personal analytics | 13 orphaned V2.0 environmental fields, points breakdown, category trends |
| **F12. Unified Activity Timeline** | Cross-cutting chronological feed of all activity | 10+ siloed screens, no narrative coherence |
| **F13. Scan Failure Resilience & Recovery** | Durable failure recording, retry, offline queue | Transient failures, no retry history, no failure dashboard |
| **F14. Gamification Transparency Layer** | Legible points economy, streaks, achievements, level ladder | 3 dead streak types, hidden mechanics, no points breakdown |

---

## Part 6: Summary by User Question

| Your Question | Exists? | Gap | Priority |
|---|---|---|---|
| Can I check my profile? | Partial | 6 of ~20 available fields shown. Missing: token wallet, achievements, streaks, family, environmental impact, `createdAt`, `trainingConsent` | High |
| Can I check history? | Yes | Missing: per-scan points, model routing info, analysis source. No unified timeline | Medium |
| Points collected vs used? | Partial | Token wallet shows earned/spent/transactions. Missing: per-scan breakdown, points-vs-tokens conversion history, daily cap, category breakdown | High |
| Family invites? | Partial | Send invites works. No "invitations I received" view. No cross-family invitation hub | Medium |
| Families I'm part of? | Partial | Only current single family. No historical family list, no multi-family support | Low (architectural) |
| I have invited vs I am invited to? | No | Per-family invitation list exists. No user-centric sent/received view across all families | Medium |
| Scans that failed? | No | Persisted as fallback classifications with "Needs review" badge. No dedicated failure screen, no retry history | High |
| Communities created / part of? | No | Single global community feed. No create/join/leave. Members tab is placeholder | High |
| Anything else needing log/history/analytics? | Yes | Classification feedback history, model routing dashboard, streak overview, challenge tracking, environmental impact on profile, data completeness dashboard, unified activity timeline, points breakdown — all missing | High |

---

## Appendix: Files Referenced

| File | Path |
|---|---|
| Profile screen | `lib/screens/profile_screen.dart` |
| History screen | `lib/screens/history_screen.dart` |
| Token wallet | `lib/screens/token_wallet_screen.dart` |
| Family dashboard | `lib/screens/family_dashboard_screen.dart` |
| Family management | `lib/screens/family_management_screen.dart` |
| Family invite | `lib/screens/family_invite_screen.dart` |
| Family creation | `lib/screens/family_creation_screen.dart` |
| Community | `lib/screens/community_screen.dart` |
| Waste dashboard | `lib/screens/waste_dashboard_screen.dart` |
| Impact dashboard | `lib/screens/impact_dashboard_screen.dart` |
| Gamification analytics | `lib/screens/gamification_analytics_screen.dart` |
| Achievements | `lib/screens/achievements_screen.dart` |
| Classification details | `lib/screens/classification_details_screen.dart` |
| Model routing | `lib/screens/model_routing_screen.dart` |
| User profile model | `lib/models/user_profile.dart` |
| Waste classification model | `lib/models/waste_classification.dart` |
| Gamification model | `lib/models/gamification.dart` |
| Enhanced family model | `lib/models/enhanced_family.dart` |
| Family invitation model | `lib/models/family_invitation.dart` |
| Classification state | `lib/models/classification_state.dart` |
| Storage service | `lib/services/storage_service.dart` |
| Firebase family service | `lib/services/firebase_family_service.dart` |
| Profile summary card | `lib/widgets/profile_summary_card.dart` |
| History list item | `lib/widgets/history_list_item.dart` |
| Exploration frontier | `docs/EXPLORATION_FRONTIER.md` |
