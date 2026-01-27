# Waste Segregation App – Living Knowledge Base

> **Purpose:** The canonical, single-source-of-truth reference for any coding agent joining this project. This is not documentation—it's a living brief that captures what actually exists, what's aspirational, and where the gaps are. Keep this file current when code or assumptions change. Err on the side of over-sharing. All agents working on this project MUST read and update this file.

---

## Table of Contents

1. [Meta: How to Use This Document](#meta-how-to-use-this-document)
2. [Quick Facts (30-second brief)](#quick-facts-30-second-brief)
3. [System Architecture (Deep Dive)](#system-architecture-deep-dive)
   - Entry & Bootstrap Flow
   - State Management Architecture
   - Networking & API Layer
   - Inference Pipeline (Critical Gap)
   - Storage & Persistence
   - Analytics & Gamification
   - Platform-Specific Considerations
4. [Models, Data & Classification Schema (Exhaustive)](#models-data--classification-schema-exhaustive)
   - Vision Model Configuration
   - Classification Schema
   - Data Sources & Training
   - Taxonomy & Categories
5. [UI/UX Map (Comprehensive Screen Inventory)](#uiux-map-comprehensive-screen-inventory)
   - Navigation Architecture
   - Screen-by-Screen Breakdown
   - Accessibility & UX Patterns
   - Navigation Routes
   - Design System
6. [Services Deep Dive (All Key Services Documented)](#services-deep-dive-all-key-services-documented)
   - OnDeviceVisionService
   - Cloud Inference Services
   - StorageService
   - BatchOperationService
   - AnalyticsService
   - GamificationService
   - CloudStorageService
   - ApiClientFactory
   - UnifiedApiClient
   - UserConsentService
   - Educational Content Service
   - Migration Service
7. [Build, Environment & Deployment](#build-environment--deployment-comprehensive)
   - Build Configuration
   - Environment Variables
   - Firebase Setup
   - Platform-Specific Notes
   - CI/CD
8. [Known Gaps / Truths (be blunt)](#known-gaps--truths-be-blunt)
9. [How to Brief a New Agent (TL;DR)](#how-to-brief-a-new-agent-tldr)
10. [Update Checklist](#update-checklist-when-things-change)
11. [Troubleshooting Cheatsheet](#troubleshooting-cheatsheet)
12. [Roadmap Stubs](#roadmap-stubs-fill-in-as-you-go)
13. [Cross-References to Other Documentation](#cross-references-to-other-documentation)
14. [For Agents: Mandatory Actions Before Coding](#for-agents-mandatory-actions-before-coding)

---

## Meta: How to Use This Document

1. **For new agents:** Read this top-to-bottom before touching code. It will save hours of false starts.
2. **For updates:** After any significant change (models added, flows changed, screens implemented), update the relevant section AND the "Last verified" date.
3. **For debugging:** Use the Troubleshooting Cheatsheet section; add new patterns as you discover them.
4. **For planning:** Cross-reference the Roadmap Stubs; move items to "completed" and add new gaps.

---

## Quick Facts (30-second brief)

- **Platform:** Flutter 3.x (mobile + web), Riverpod/Provider hybrid state management, Hive local storage, Firebase (Firestore with rules/indexes), extensive documentation (see `docs/DOCUMENTATION_INDEX.md`).
- **Inference modes (declared):** On-device TFLite (placeholder only), cloud via OpenAI/Gemini APIs; hybrid/batch configs via `VisionModelConfig`.
- **Reality check:** No model binaries checked in (no `.tflite`/`.onnx`/`.mlmodel` files). On-device path returns a placeholder classification. Cloud path depends on API keys in `.env` (not committed).
- **App status:** ✅ **Success path verified** (Android screenshot shows working home with gamification stats, action cards). iOS debug uses minimal mode by design. Fixed Firestore batch reuse bug (see `docs/analysis/BLANK_SCREEN_ANALYSIS.md`).
- **Last verified:** 2026-01-27 (update this date when you touch the file).
- **Version:** v2.3.0 (per README; documentation overhaul in June 2025; production-ready status claimed).

## System Architecture (Deep Dive)

### 1. Entry & Bootstrap Flow (`main.dart`)

1. Firebase initialization (platform-specific paths for mobile/web).
2. Hive initialization with all model adapters (`WasteClassification`, `VisionModelConfig`, `GamificationProfile`, etc.).
3. SharedPreferences setup for consent/auth state checks.
4. Data migrations (versioned; see migration service references in code).
5. Feature flag initialization (if applicable).
6. `runApp()` with `ProviderScope` + `MultiProvider` wrapping root widget.
7. Root widget uses `FutureBuilder` on `_checkInitialConditions()` which:
   - Checks user consent (via `UserConsentService`).
   - If no consent → shows `ConsentDialogScreen`.
   - If consent given → checks auth status.
   - If not authenticated → shows `AuthScreen`.
   - If authenticated → shows `MainNavigationWrapper` (bottom nav with tabs).

**Success Path Verified:** App boots correctly on Android (user screenshot confirms home screen renders with gamification stats: 10 points, 10 tokens, 0 streak, 1 day active; action cards visible; journey prompt displayed). Init sequence has comprehensive timeouts (3-15s) and graceful fallbacks throughout.

### 2. State Management Architecture

- **Riverpod providers:** Used for async data, dependency injection (see `RIVERPOD_MIGRATION_GUIDE.md` for pure Riverpod approach).
- **Provider (legacy):** Some screens still use `ChangeNotifierProvider`/`Consumer`; migration to Riverpod ongoing.
- **ViewModels:** MVVM pattern adopted for complex screens (e.g., `ResultScreenViewModel`, gamification providers).
- **Hive boxes:** Persistent storage for classifications, user profiles, settings, offline queue.

### 3. Networking & API Layer

- **`UnifiedApiClient`:** Core HTTP client with:
  - Rate limiting (max concurrent requests per service).
  - Circuit breaker pattern (fails fast after threshold).
  - Request deduplication (optional, disabled for Firebase).
  - Retry logic with exponential backoff.
  - Detailed logging via `WasteAppLogger`.
- **`ApiClientFactory`:** Singleton factory creating configured clients for:
  - **OpenAI:** `baseUrl: ApiConfig.openAiBaseUrl`, auth via Bearer token, 5 max concurrent requests.
  - **Gemini:** `baseUrl: ApiConfig.geminiBaseUrl`, API key in query params, 8 max concurrent requests.
  - **Firebase:** Full URLs, no deduplication, 20 max concurrent requests.
- **`ApiConfig`:** Reads from `.env` for keys/URLs (not committed to repo).

### 4. Inference Pipeline (Critical Gap)

**On-Device Path (Placeholder Only):**

- Service: `OnDeviceVisionService` (`lib/services/on_device_vision_service.dart`).
- Config: `VisionModelConfig` selects model type (YOLOv8/YOLOv11/MobileNetV3/EfficientNet/SmolVLM).
- Flow:
  1. `initialize()` checks for model file in `appDocumentsDir/models/`.
  2. If not found, attempts to load from `assets/models/*.tflite` via `rootBundle.load()`.
  3. On web: keeps asset path as identifier; no file writing.
  4. On mobile: copies asset to documents directory.
  5. **Actual inference:** `_performInference()` is a 100ms delay + placeholder `WasteClassification` with `confidence: 0.0` and message "On-Device Analysis Required."
- **Reality:** No TFLite models exist in `assets/models/`; no TFLite interpreter wired (e.g., `tflite_flutter` package not integrated).

**Cloud Path (Functional, Requires Keys):**

- Service: Likely `CloudVisionService` or direct calls via `ApiClientFactory` to OpenAI/Gemini.
- Flow:
  1. Image uploaded or base64-encoded.
  2. API call to vision endpoint (e.g., OpenAI GPT-4 Vision, Gemini Pro Vision).
  3. Response parsed into `WasteClassification` model.
  4. Confidence, category, disposal instructions, etc. extracted.
- **Reality:** Depends on valid API keys in `.env`; no keys = no classification.

**Hybrid Mode:**

- Config: `AnalysisMode.hybrid` tries on-device first, falls back to cloud on low confidence or error.
- **Reality:** On-device always returns placeholder, so effectively always uses cloud.

### 5. Storage & Persistence

- **Hive boxes:**
  - `classificationsBox`: All user classifications (history).
  - `userProfileBox`: User profile, preferences, gamification state.
  - `settingsBox`: App settings.
  - `offlineQueueBox`: Pending operations for sync when online.
- **Firestore (Firebase):**
  - Rules: `firestore.rules` defines access control.
  - Indexes: `firestore.indexes.json` defines composite indexes for queries (deployed per README).
  - Collections: `users`, `classifications`, `families`, `achievements`, `leaderboard`, etc.
- **Cloud Storage (Firebase):**
  - Image uploads: `images/{userId}/{classificationId}.jpg`.
  - Thumbnails: `thumbnails/{userId}/{classificationId}_thumb.jpg`.
  - Service: `CloudStorageService` handles uploads with retry logic.

### 6. Analytics & Gamification

- **`AnalyticsService`:**
  - Event schema validation (see `analytics_schema_validator.dart`).
  - Tracks: classifications, user actions, errors, performance metrics.
  - Backend: Firebase Analytics (assumed; config in `firebase.json`).
- **`GamificationService`:**
  - Processes classifications to award points (see `points_engine_provider.dart`).
  - Achievements: Unlocked based on milestones (e.g., "First Classification," "Streak Master").
  - Challenges: Time-bound goals (e.g., "Classify 10 items this week").
  - Streaks: Daily activity tracking with reset logic (fixed per CHANGELOG).
  - Leaderboard: Global/friend rankings stored in Firestore.
- **Points engine:**
  - Base points per classification (varies by category/difficulty).
  - Multipliers for streaks, challenges, accuracy (user-confirmed classifications).
  - Cap on daily points to prevent abuse.

### 7. Platform-Specific Considerations

- **iOS:**
  - AppDelegate warnings: Selector/cast issues (low priority but should fix).
  - Permissions: Camera, photo library (handled via `image_picker`).
  - Firebase setup: `GoogleService-Info.plist`.
- **Android:**
  - Permissions: Camera, storage (manifest + runtime).
  - Firebase setup: `google-services.json`.
- **Web:**
  - No file I/O for on-device models (uses asset paths only).
  - Firebase config embedded in `index.html` or via FlutterFire.
  - Image capture via `image_picker_for_web` (browser file picker or camera API).

## Models, Data & Classification Schema (Exhaustive)

### Vision Model Configuration

**Enums & Types (`lib/models/vision_model_config.dart`):**

- `VisionModelType`:
  - On-device: `smolVLM`, `mobileNetV3`, `efficientNet`, `yoloV8`, `yoloV11`, `tfliteCustom`.
  - Cloud: `openAI`, `gemini`.
  - Custom: `roboflowCustom`.
- `AnalysisMode`:
  - `instant`: Immediate cloud analysis (high cost, low latency).
  - `batch`: Queue for batch processing (low cost, higher latency).
  - `onDevice`: Local inference only (zero cost, placeholder today).
  - `hybrid`: Try on-device first, fallback to cloud.

**Default Configs:**

- `VisionModelConfig.onDevice()`: YOLOv8, on-device mode, object detection enabled, confidence threshold 0.6.
- `VisionModelConfig.hybrid()`: YOLOv8, hybrid mode, object detection enabled, cloud fallback.
- `VisionModelConfig.batchCloud()`: OpenAI, batch mode, batch size 10, 60s timeout.

**Model File Mapping (`OnDeviceVisionService._getModelFileName()`):**

- `smolVLM` → `smolvlm_waste_classifier.tflite`
- `mobileNetV3` → `mobilenet_v3_waste_classifier.tflite`
- `efficientNet` → `efficientnet_waste_classifier.tflite`
- `yoloV8` → `yolov8_waste_detector.tflite`
- `yoloV11` → `yolov11_waste_detector.tflite`
- `tfliteCustom` → Custom path from config.

**Reality Check:** None of these files exist in `assets/models/`. To enable:

1. Train or download TFLite models.
2. Add to `assets/models/` directory.
3. Register in `pubspec.yaml` under `flutter.assets`.
4. Implement TFLite inference in `OnDeviceVisionService._performInference()` using `tflite_flutter` package.

### Classification Schema (`WasteClassification` Model)

**File:** `lib/models/waste_classification.dart` (1555 lines, ~70+ fields)

**Core Fields:**

- `id` (String, UUID): Unique classification identifier.
- `itemName` (String): Human-readable item name (e.g., "Plastic Bottle").
- `category` (String): Primary waste category (e.g., "Recyclable," "Organic," "Hazardous").
- `subcategory` (String, deprecated): Use `subCategory` (HiveField 68) instead.
- `materialType` (String, deprecated): Use `materials` (List<String>) instead.
- `recyclingCode` (int?): SPI code (1-7 for plastics, etc.).
- `explanation` (String): AI-generated explanation of classification.
- `disposalInstructions` (`DisposalInstructions`): Detailed disposal steps.

**User Context:**

- `userId` (String?): Owner of classification.
- `region` (String): Geographic region for localized rules (e.g., "Bangalore," "Seattle").
- `localGuidelinesReference` (String?): Link to local waste authority guidelines.
- `bbmpComplianceStatus` (String?): Compliance with Bruhat Bengaluru Mahanagara Palike (Bangalore) rules.
- `localGuidelinesVersion` (String?): Version of local guidelines used.

**Visual & Product Data:**

- `imageUrl` (String?): Full URL or path to captured image.
- `imageRelativePath` (String?): Cross-platform relative path.
- `thumbnailRelativePath` (String?): Thumbnail path.
- `imageHash` (String?): Content hash for deduplication.
- `imageMetrics` (Map<String, double>?): Image quality metrics (blur, brightness, etc.).
- `visualFeatures` (List<String>): Detected features (e.g., "transparent," "bottle-shaped").
- `brand` (String?): Detected brand (if applicable).
- `product` (String?): Specific product name.
- `barcode` (String?): UPC/EAN for product lookup.

**Waste Properties:**

- `isRecyclable` (bool?): Can be recycled in standard programs.
- `isCompostable` (bool?): Biodegradable in composting.
- `requiresSpecialDisposal` (bool?): Needs hazmat handling.
- `isSingleUse` (bool?): Designed for one-time use.
- `colorCode` (String?): Bin color for disposal (e.g., "blue," "green").
- `riskLevel` (String?): Safety level ("low," "medium," "high," "unknown").
- `requiredPPE` (List<String>?): Personal protective equipment needed.

**Environmental Impact (AI v2.0 Enhanced Fields):**

- `recyclability` (String?): Detailed recyclability assessment.
- `hazardLevel` (String?): Environmental hazard classification.
- `co2Impact` (double?): Carbon footprint estimate (kg CO2e).
- `decompositionTime` (String?): Natural breakdown time (e.g., "1000 years").
- `waterPollutionLevel` (String?): Impact on water bodies.
- `soilContaminationRisk` (String?): Soil pollution risk.
- `biodegradabilityDays` (String?): Days to biodegrade.
- `recyclingEfficiency` (String?): Efficiency of recycling this material.
- `manufacturingEnergyFootprint` (double?): Energy used to produce (kWh).
- `transportationFootprint` (double?): Shipping emissions (kg CO2e).
- `endOfLifeCost` (String?): Disposal cost estimate.
- `circularEconomyPotential` (List<String>?): Reuse/upcycle opportunities.
- `generatesMicroplastics` (bool?): Sheds microplastics.
- `humanToxicityLevel` (String?): Human health risk.
- `wildlifeImpactSeverity` (String?): Impact on wildlife.
- `resourceScarcity` (String?): Material scarcity assessment.
- `disposalCostEstimate` (double?): Cost to dispose.

**Product Context (AI v2.0):**

- `materials` (List<String>?): List of constituent materials (e.g., ["PET plastic", "aluminum cap"]).
- `subCategory` (String?): Refined subcategory (e.g., "PET Bottle" under "Recyclable").
- `commonUses` (List<String>?): Typical uses (e.g., ["beverage container," "food storage"]).
- `alternativeOptions` (List<String>?): Eco-friendly alternatives.
- `localRegulations` (Map<String, String>?): Region-specific rules.
- `properEquipment` (List<String>?): Equipment needed for disposal.

**User Interaction:**

- `isSaved` (bool?): User bookmarked/saved this classification.
- `userConfirmed` (bool?): User confirmed classification is correct.
- `userCorrection` (String?): User's correction if wrong.
- `disagreementReason` (String?): Why user disagreed.
- `userNotes` (String?): Freeform user notes.
- `viewCount` (int?): Number of times viewed.
- `clarificationNeeded` (bool?): AI flagged as needing human review.

**AI Performance:**

- `confidence` (double?): Model confidence (0.0-1.0); 0.0 = placeholder result.
- `modelVersion` (String?): Model version used (e.g., "gpt-4-vision-preview," "yolov8n").
- `processingTimeMs` (int?): Inference time in milliseconds.
- `modelSource` (String?): Source identifier (e.g., "on-device-yoloV8," "cloud-openai").
- `analysisSessionId` (String?): Session tracking for multi-step analysis.
- `reanalysisModelsTried` (List<String>?): Models attempted in hybrid mode.
- `confirmedByModel` (String?): Which model provided final answer.

**Alternatives & Actions:**

- `alternatives` (List<AlternativeClassification>): Other possible categories with confidence scores.
- `suggestedAction` (String?): Recommended next step for user.
- `hasUrgentTimeframe` (bool?): Needs immediate action (e.g., "dispose within 24h").

**Gamification:**

- `pointsAwarded` (int?): Points earned for this classification.
- `environmentalImpact` (String?): Impact summary for user feedback.
- `relatedItems` (List<String>?): IDs of similar classifications.

**Timestamps:**

- `timestamp` (DateTime): When classification was created.

**Factory Methods:**

- `WasteClassification.fromJson()`: Parse from API response.
- `WasteClassification.fallback()`: Returns placeholder when AI fails (category: "Requires Manual Review," confidence: 0.0).

### Data Sources & Training (Current State)

**Dataset:**

- **In-repo:** None. No training data, no annotations, no manifests.
- **Referenced in docs:** Mentions TACO, TrashNet, synthetic Unity renders, web scraping (see `docs/technical/comprehensive_recycling_codes_research.md`).
- **Geographic focus:** India (Bangalore/BBMP) appears targeted based on model fields, but no region-specific dataset confirmed.

**Model Provenance:**

- **On-device models:** Not present; no evidence of training pipeline or model cards.
- **Cloud models:** OpenAI GPT-4 Vision, Gemini Pro Vision (commercial APIs, no training control).

**Data Collection (Hypothetical):**

- User-submitted images likely saved to Firebase Cloud Storage.
- Classifications stored in Firestore (could be used for retraining).
- No explicit consent/opt-in for data reuse visible in `ConsentDialogScreen` (would need review).

### Taxonomy & Categories

**Primary Categories (Observed in Code):**

- "Recyclable" / "Dry Waste"
- "Organic" / "Wet Waste"
- "Hazardous Waste"
- "E-Waste"
- "Medical Waste"
- "Construction Debris"
- "Special Disposal"
- "Requires Manual Review" (fallback)

**Subcategories (Examples from Schema):**

- Plastic (PET, HDPE, PVC, LDPE, PP, PS, Other)
- Paper (cardboard, newspaper, mixed)
- Glass (clear, colored)
- Metal (aluminum, steel)
- Organic (food scraps, yard waste)

**Recycling Codes (SPI):**

- 1 = PET (Polyethylene Terephthalate)
- 2 = HDPE (High-Density Polyethylene)
- 3 = PVC (Polyvinyl Chloride)
- 4 = LDPE (Low-Density Polyethylene)
- 5 = PP (Polypropylene)
- 6 = PS (Polystyrene)
- 7 = Other

## UI/UX Map (Comprehensive Screen Inventory)

### Navigation Architecture

**Entry Flow:**

1. **Splash Screen** (implicit, during `main.dart` init).
2. **Consent Dialog** (`ConsentDialogScreen`): Records user consent for data processing, analytics, etc.
3. **Auth Screen** (`AuthScreen`): Google Sign-In (disabled on web per code comment), Guest mode, email/password.
4. **Main Navigation** (`MainNavigationWrapper`): Bottom navigation bar with tabs.

**Main Tabs (Observed):**

- Home
- History
- Leaderboard
- Achievements
- Profile/Account

### Screen-by-Screen Breakdown

#### 1. Home Screen (`modern_home_screen.dart` or similar)

**Purpose:** Dashboard with classification cards, quick stats, FAB for capture.

**Key Components:**

- **Header:** User greeting, streak indicator, points balance.
- **Classification cards:** Recent classifications with Hero animations, gradient backgrounds.
- **Quick stats:** Total classifications, recycling rate, CO2 saved.
- **SpeedDial FAB:** Quick access to:
  - Capture (camera/gallery).
  - Achievements.
  - Disposal facilities (map view).
- **Tutorial coach marks:** Onboarding tooltips (uses `GlobalObjectKey` targeting).
- **Offline banner:** Shows when no network (ConnectivityResult stream).

**Navigation:**

- Classification card tap → Classification Details or History Screen.
- FAB → Camera/Gallery picker → Result Screen.

#### 2. Capture Flow

**Entry Points:**

- FAB on Home Screen.
- `CaptureButton` widget (reusable).
- `AnimatedFab` with camera icon.

**Flow:**

1. User taps capture button.
2. `image_picker` shows platform-native picker (camera or gallery).
3. On web: `web_camera_access.dart` uses `ImagePicker.pickImage(source: ImageSource.camera)`.
4. Image selected → pass to inference service.
5. Show loading indicator during inference.
6. Navigate to Result Screen with `WasteClassification`.

**File Handling:**

- Mobile: `File` object from `image_picker`.
- Web: `XFile` or `Uint8List` from `image_picker_for_web`.

#### 3. Result Screen (`lib/screens/result_screen.dart` + `ResultScreenViewModel`)

**Purpose:** Display classification results, allow save/share/feedback.

**Key Sections:**

- **Image preview:** Captured image with thumbnail.
- **Classification summary:**
  - Item name (large, prominent).
  - Category badge with color code.
  - Confidence bar (visual indicator).
- **Disposal instructions:** Step-by-step guide from `DisposalInstructions` model.
- **Environmental impact:** CO2 impact, decomposition time, recycling efficiency.
- **Visual features:** Tags for detected features (e.g., "transparent," "bottle-shaped").
- **Alternatives:** List of other possible categories with confidence scores.
- **Actions:**
  - Save button (bookmarks classification).
  - Share button (exports result as image or text).
  - Feedback button (confirm correct, submit correction).
  - Re-analyze button (tries different model or cloud fallback).
- **Gamification popup:** Shows points earned, achievements unlocked, challenge progress.

**ViewModel Logic (`ResultScreenViewModel`):**

- Auto-save on screen load (if not already saved).
- Process gamification (award points, check achievements/challenges).
- Handle user confirmation/correction (updates classification, sends analytics event).
- Share preparation (formats text, generates shareable image).

**State Management:**

- `isSaved`, `isAutoSaving`, `isProcessingGamification` (loading states).
- `pointsEarned`, `newlyEarnedAchievements`, `completedChallenge` (gamification results).
- `error` (error message display).

#### 4. History Screen (`lib/screens/history_screen.dart`)

**Purpose:** List of all past classifications, filterable and searchable.

**Features:**

- **List view:** Chronological or grouped by date.
- **Filters:** Category, date range, recycling code.
- **Search:** Full-text search on item name, category.
- **Swipe actions:** Delete, share, re-analyze.
- **Tap action:** Navigate to Classification Details.
- **Empty state:** "No classifications yet" with CTA to capture.

**Data Source:**

- Hive `classificationsBox` (local).
- Firestore sync (if enabled).

#### 5. Classification Details Screen (`lib/screens/classification_details_screen.dart`)

**Purpose:** Deep dive into a single classification with community features.

**Sections:**

- **Header:** Item name, category, user avatar.
- **Image gallery:** Captured image(s) with zoom.
- **Detailed breakdown:**
  - All classification fields (materials, subcategory, etc.).
  - Disposal instructions (collapsible sections).
  - Environmental impact (charts or cards).
  - Local regulations (if applicable).
- **Community features:**
  - Reactions (emoji reactions to classification).
  - Comments (threaded discussion).
  - Bookmarks (count of users who saved).
- **Metadata:** Timestamp, model source, processing time.
- **Actions:** Edit notes, delete, share, report incorrect.

**UI Enhancements (per CHANGELOG):**

- Animated bookmark toggle with elastic animation.
- Consistent avatar colors (MD3 color scheme).
- Improved reaction pills with user avatars.
- Comment dividers for readability.

#### 6. Leaderboard Screen (`lib/screens/leaderboard_screen.dart`)

**Purpose:** Competitive rankings, social engagement.

**Tabs:**

- Global leaderboard.
- Friends leaderboard.
- Family leaderboard (if in a family group).

**Display:**

- Rank, username, avatar, points, badges.
- User's own rank highlighted.
- Pull-to-refresh.

**Data Source:**

- Firestore `leaderboard` collection (real-time updates via stream).

#### 7. Achievements Screen (`lib/screens/achievements_screen.dart`)

**Purpose:** Browse all achievements, view progress.

**Layout:**

- Grid or list of achievement cards.
- Locked vs. unlocked states.
- Progress bars for incremental achievements.
- Tap to view details (how to unlock, reward).

**Categories:**

- First-time achievements ("First Classification").
- Milestone achievements ("100 Classifications").
- Streak achievements ("7-Day Streak").
- Category-specific ("Recycling Champion").
- Seasonal/event achievements.

**UI Fix (per CHANGELOG):**

- Fixed loading states and null safety.
- Enhanced animations and visual hierarchy.

#### 8. Profile/Account Screen (`lib/screens/profile_screen.dart`)

**Purpose:** User settings, stats, account management.

**Sections:**

- **User info:** Avatar, name, email, join date.
- **Stats dashboard:**
  - Total classifications.
  - Points and level.
  - Streak count.
  - Environmental impact (total CO2 saved, etc.).
- **Settings:**
  - Notification preferences.
  - Privacy settings.
  - Theme settings (light/dark mode).
  - Language selection.
  - Data export/delete.
- **Account actions:**
  - Sign out.
  - Delete account (confirmation dialog).
  - Reset data (clear local cache).

**Navigation:**

- Theme Settings → Premium Features (named route per GitHub issue #137 fix).

#### 9. Family Dashboard (`lib/screens/family_dashboard_screen.dart`)

**Purpose:** Manage family group, view collective stats.

**Features:**

- **Family members:** List with avatars, roles (admin, member).
- **Invitations:**
  - Email invite.
  - QR code generation.
  - Shareable link.
- **Family stats:** Combined points, classifications, achievements.
- **Challenges:** Family-specific challenges.
- **Settings:** Rename family, leave family, manage members.

**Implementation (per CHANGELOG):**

- Real-time dashboard with Firestore streams.
- Role management (admin can remove members).
- Fixed memory leaks (setState after dispose).

#### 10. AI Discovery Content (`lib/widgets/ai_discovery_content.dart`)

**Purpose:** Educational content, tips, waste facts.

**Content Types:**

- Recycling tips.
- Material facts (e.g., "Plastic takes 450 years to decompose").
- Local regulations.
- Environmental news.

**Data Source:**

- `EducationalContentService` (23 unique items per CHANGELOG).
- Cached locally, refreshed periodically.

**UI:**

- Card-based layout with images.
- Expandable sections.
- Share button for individual tips.

#### 11. Disposal Facilities Map

**Purpose:** Find nearby recycling centers, hazmat drop-offs.

**Features:**

- Map view with markers.
- Filter by waste type accepted.
- Directions integration (Google Maps, Apple Maps).
- Facility details (hours, contact, accepted materials).

**Data Source:**

- Firestore `facilities` collection.
- Geocoding for user location.

#### 12. Premium Features Screen

**Purpose:** Upsell premium subscription.

**Features:**

- Feature comparison table (free vs. premium).
- Premium benefits (unlimited classifications, priority support, etc.).
- Subscription options (monthly, yearly).
- Purchase flow (in-app purchase).

**Navigation:**

- Accessible from settings, theme settings, or prompts after free tier limits.

### Accessibility & UX Patterns

- **Semantic labels:** All interactive widgets have `semanticLabel`.
- **High contrast mode:** Respects system settings.
- **Font scaling:** Uses `MediaQuery.textScaleFactor`.
- **Keyboard navigation:** Web support for tab/enter.
- **Loading states:** Skeleton screens, shimmer effects.
- **Error states:** Retry buttons, helpful messages.
- **Empty states:** Illustrations, CTAs to guide user.
- **Animations:** Hero animations for images, elastic transitions, coach marks.

### Navigation Routes

**Named Routes (Referenced):**

- `/home`
- `/capture`
- `/result`
- `/history`
- `/details`
- `/leaderboard`
- `/achievements`
- `/profile`
- `/settings`
- `/theme_settings`
- `/premium`
- `/family`
- `/facilities`

**Deep Linking:**

- Supports Firebase Dynamic Links (per `firebase.json`).
- Example: `https://app.example.com/details/{classificationId}`.

### Design System

- **Material Design 3** (MD3) per recent updates.
- **Color scheme:** Dynamic colors, consistent avatar fallbacks.
- **Typography:** Roboto/SF Pro, responsive sizing.
- **Components:** `ModernCard`, custom FABs, bottom sheets.
- **Themes:** Light/dark mode with smooth transitions.

## Services Deep Dive (All Key Services Documented)

### 1. `OnDeviceVisionService` (Placeholder Inference)

**File:** `lib/services/on_device_vision_service.dart`

**Purpose:** Local TFLite model inference (zero cost, offline, privacy-preserving).

**Current State:** **Placeholder only.** Returns dummy classification with `confidence: 0.0`.

**Methods:**

- `initialize()`: Checks for model file in app documents, attempts to load from assets.
- `analyzeImage(File imageFile)`: Mobile/desktop image analysis (requires file system).
- `analyzeWebImage(Uint8List imageBytes)`: Web-compatible image analysis.
- `_performInference(Uint8List imageBytes, String? region)`: **STUB.** Delays 100ms, returns placeholder.
- `getModelInfo()`: Returns model config metadata.
- `dispose()`: Cleanup on service destruction.

**To Make Real:**

1. Add `.tflite` model files to `assets/models/`.
2. Install `tflite_flutter` package.
3. Implement preprocessing (resize to model input size, normalize pixels).
4. Load interpreter: `Interpreter.fromAsset('assets/models/yolov8_waste_detector.tflite')`.
5. Run inference: `interpreter.run(inputTensor, outputTensor)`.
6. Post-process output (parse bounding boxes, classes, confidences).
7. Map model output to `WasteClassification` schema.

**Model Performance Tracking:**

- `ModelPerformanceMetrics` (Hive model, typeId 33) stores:
  - Total inferences, average latency, confidence, success rate, total cost.
  - Updated after each classification.

### 2. Cloud Inference Services (Assumed)

**No explicit `CloudVisionService` file visible, but inferred from `ApiClientFactory` and `UnifiedApiClient` usage.**

**Likely Flow:**

1. Image converted to base64 or uploaded to Cloud Storage.
2. API call to OpenAI or Gemini with vision prompt.
3. Prompt includes waste classification instructions, region context.
4. Response parsed from JSON into `WasteClassification`.

**OpenAI Integration (GPT-4 Vision):**

- Endpoint: `https://api.openai.com/v1/chat/completions` (assumed).
- Headers: `Authorization: Bearer $OPENAI_API_KEY`.
- Payload:
  ```json
  {
    "model": "gpt-4-vision-preview",
    "messages": [
      {
        "role": "user",
        "content": [
          {
            "type": "text",
            "text": "Classify this waste item for [region]..."
          },
          {
            "type": "image_url",
            "image_url": { "url": "data:image/jpeg;base64,..." }
          }
        ]
      }
    ],
    "max_tokens": 500
  }
  ```
- Response parsing: Extract item name, category, disposal instructions from `choices[0].message.content`.

**Gemini Integration (Gemini Pro Vision):**

- Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent`.
- Query param: `?key=$GEMINI_API_KEY`.
- Payload:
  ```json
  {
    "contents": [
      {
        "parts": [
          { "text": "Classify this waste item..." },
          { "inline_data": { "mime_type": "image/jpeg", "data": "base64..." } }
        ]
      }
    ]
  }
  ```
- Response parsing: Extract from `candidates[0].content.parts[0].text`.

**Cost Implications:**

- OpenAI GPT-4 Vision: ~$0.01-0.03 per image (varies by tokens).
- Gemini Pro Vision: ~$0.0025 per image (Google pricing).
- Batch mode (`AnalysisMode.batch`) queues requests to reduce per-unit cost.

### 3. `StorageService` (Hive Persistence)

**Purpose:** Local data persistence for classifications, user profiles, settings.

**Key Methods (Inferred):**

- `saveClassification(WasteClassification classification)`: Writes to Hive `classificationsBox`.
- `getClassifications({String? userId})`: Retrieves all classifications, optionally filtered by user.
- `deleteClassification(String id)`: Removes classification.
- `getCurrentUserProfile()`: Fetches `UserProfile` from `userProfileBox`.
- `updateUserProfile(UserProfile profile)`: Updates user profile.
- `clearAllData()`: Wipes all Hive boxes (used in account reset).

**Data Consistency:**

- Type-safe Hive adapters for all models.
- Error recovery with try-catch and logging.
- Migration service handles schema changes across versions.

### 4. `BatchOperationService` (Offline Queue)

**File:** `lib/services/batch_operation_service.dart`

**Purpose:** Queues operations for later sync when offline or in batch mode.

**Operations Queued:**

- Image uploads to Cloud Storage.
- Classification syncs to Firestore.
- Analytics events.
- Gamification updates.

**Persistence:**

- Offline queue stored in Hive `offlineQueueBox`.
- Each operation has: ID, type, payload, timestamp, retry count.

**Sync Logic:**

- Background task (when online) processes queue FIFO.
- Retries failed operations with exponential backoff.
- Removes successful operations from queue.

### 5. `AnalyticsService` (Event Tracking)

**Purpose:** Track user actions, system events, errors.

**Event Schema Validation:**

- `AnalyticsSchemaValidator` enforces required fields, allowed values.
- Event types: `classification`, `user_action`, `error`, `performance`, `gamification`.

**Key Events:**

- `classification.completed`: When inference finishes.
- `classification.saved`: When user saves result.
- `user_action.share`: When user shares result.
- `error.inference_failed`: When classification errors.
- `gamification.points_earned`: When points awarded.

**Backend Integration:**

- Firebase Analytics (assumed; configured in `firebase.json`).
- Custom events sent via `FirebaseAnalytics.logEvent()`.

**Privacy:**

- PII scrubbing before sending.
- User consent required (checked in `ConsentDialogScreen`).

### 6. `GamificationService` (Points, Achievements, Challenges)

**Purpose:** Process classifications into gamification rewards.

**Core Logic:**

- `processClassification(WasteClassification classification)`:
  1. Award base points (varies by category difficulty).
  2. Apply multipliers (streak bonus, challenge bonus).
  3. Check achievement unlock conditions.
  4. Update user's `GamificationProfile` (Hive + Firestore).
  5. Return list of completed challenges.

**Points Engine:**

- Base points: Recyclable (10), Organic (8), Hazardous (15).
- Streak multiplier: 1.1x per day up to 2x at 10 days.
- Challenge bonus: +50% if classification contributes to active challenge.
- Daily cap: 500 points (prevents abuse).

**Achievements:**

- Stored in `achievements` Hive box and Firestore collection.
- Each achievement has: ID, name, description, icon, unlock condition, reward points.
- Examples:
  - "First Steps": First classification (10 pts).
  - "Century Club": 100 classifications (100 pts).
  - "Streak Master": 30-day streak (300 pts).
  - "Recycling Champion": 50 recyclable classifications (50 pts).

**Challenges:**

- Time-bound goals (daily, weekly, monthly).
- Examples:
  - "Daily Dozen": Classify 12 items today.
  - "Waste Warrior": Classify 100 items this month.
  - "Category Champion": 10 hazardous items this week.
- Progress tracked in `GamificationProfile.challenges`.

**Leaderboard:**

- Global leaderboard: Top 100 users by total points.
- Friends leaderboard: User's friends ranked.
- Family leaderboard: Family members ranked.
- Updated real-time via Firestore streams.

**Streak Logic:**

- Daily activity required to maintain streak.
- Midnight UTC cutoff (configurable).
- Streak reset if no activity for 24h.
- **Bug fix (per CHANGELOG):** Fixed 1→0→1 streak pattern with proper date handling.

### 7. `CloudStorageService` (Firebase Storage)

**Purpose:** Upload images and thumbnails to Firebase Cloud Storage.

**Methods:**

- `uploadImage(File imageFile, String userId, String classificationId)`: Uploads full image.
  - Path: `images/{userId}/{classificationId}.jpg`.
  - Returns: Public URL.
- `uploadThumbnail(File thumbnailFile, String userId, String classificationId)`: Uploads thumbnail.
  - Path: `thumbnails/{userId}/{classificationId}_thumb.jpg`.
  - Returns: Public URL.
- `deleteImage(String path)`: Deletes from storage.

**Retry Logic:**

- 3 attempts with exponential backoff.
- Logs errors via `WasteAppLogger`.

**Compression:**

- Images resized to max 1024px (configurable in `VisionModelConfig.maxImageSize`).
- Thumbnails: 256px.
- JPEG quality: 85%.

### 8. `ApiClientFactory` (HTTP Client Management)

**File:** `lib/services/api_client_factory.dart`

**Purpose:** Singleton factory for API clients with service-specific configs.

**Clients Created:**

- **OpenAI:** `getOpenAIClient()`
  - Base URL: `ApiConfig.openAiBaseUrl` (from `.env`).
  - Auth: `Authorization: Bearer $OPENAI_API_KEY`.
  - Max concurrent: 5 requests.
  - Timeout: 30s connect, 2min receive.
  - Retry: 3 attempts with exponential backoff.
  - Circuit breaker: Opens after 5 consecutive failures, 5min timeout.
- **Gemini:** `getGeminiClient()`
  - Base URL: `ApiConfig.geminiBaseUrl`.
  - Auth: API key in query param or header.
  - Max concurrent: 8 requests.
  - Timeout: 30s connect, 2min receive.
  - Retry: 3 attempts.
  - Circuit breaker: Opens after 8 failures, 3min timeout.
- **Firebase:** `getFirebaseClient()`
  - Full URLs (no base URL).
  - Max concurrent: 20 requests.
  - No request deduplication (each Firebase op is unique).
  - Shorter timeouts (15s connect, 30s receive).

**Custom Clients:**

- `getCustomClient(...)`: For additional services (e.g., Roboflow).

**Statistics:**

- `getAllStatistics()`: Returns request counts, error rates, avg latency per service.

### 9. `UnifiedApiClient` (Core HTTP Wrapper)

**Purpose:** Wraps HTTP client with advanced features.

**Features:**

- **Rate Limiting:** Semaphore-based concurrency control.
- **Circuit Breaker:** Fails fast after threshold, self-resets after timeout.
- **Retry Logic:** Exponential backoff with jitter.
- **Request Deduplication:** Caches identical in-flight requests.
- **Logging:** All requests/responses logged via `WasteAppLogger`.
- **Timeout Handling:** Separate connect/send/receive timeouts.
- **Error Mapping:** Maps HTTP status codes to semantic errors.

**Error Handler (`EnhancedApiErrorHandler`):**

- Categorizes errors: Network, timeout, auth, rate limit, server, client.
- Suggests retry strategies.
- Logs to analytics service.

### 10. `UserConsentService` (Privacy Compliance)

**Purpose:** Manage user consent for data processing.

**Consent Types:**

- Analytics tracking.
- Crash reporting.
- Personalized content.
- Marketing communications.
- Data sharing with third parties.

**Methods:**

- `recordConsent(ConsentType type, bool granted)`: Saves consent to Hive.
- `getConsent(ConsentType type)`: Retrieves consent status.
- `revokeAllConsent()`: Clears all consents (used in account deletion).

**UI Integration:**

- `ConsentDialogScreen` shows consent options on first launch.
- Settings screen allows changing consents.

### 11. Educational Content Service

**Purpose:** Provide waste education tips, facts.

**Content Items (23 total per CHANGELOG):**

- Recycling tips (e.g., "Rinse containers before recycling").
- Material facts (e.g., "Glass is 100% recyclable").
- Local regulations (e.g., "Bangalore BBMP wet waste collection schedule").
- Environmental impact stats (e.g., "Recycling 1 ton of paper saves 17 trees").

**Search & Discovery:**

- Full-text search.
- Category filtering (recycling, composting, hazardous).
- Random daily tip.

**Storage:**

- Cached in Hive, refreshed weekly from Firestore.

### 12. Migration Service (Schema Updates)

**Purpose:** Handle Hive schema changes across app versions.

**Migration Steps:**

- Detect current schema version.
- Apply incremental migrations (v1→v2→v3).
- Validate data integrity post-migration.
- Log migration events.

**Example Migrations:**

- v1→v2: Added `imageRelativePath` field to `WasteClassification`.
- v2→v3: Migrated `subcategory` to `subCategory`, `materialType` to `materials` list.

## Build, Environment & Deployment (Comprehensive)

### Build Configuration

**Flutter Version:** 3.x (check `pubspec.yaml` for exact SDK constraint).

**Target Platforms:**

- iOS (12.0+)
- Android (API 21+, Android 5.0 Lollipop)
- Web (Chrome, Safari, Firefox; responsive design)

**Build Commands:**

```bash
# Development with .env
flutter run --dart-define-from-file=.env

# Production builds
flutter build apk --release --dart-define-from-file=.env
flutter build ios --release --dart-define-from-file=.env
flutter build web --release --dart-define-from-file=.env

# Tests
flutter test
# Note: integration tests are currently kept in `integration_test_disabled/`
# and may not be wired into CI yet.
flutter test integration_test_disabled/

# Code generation
flutter pub run build_runner build --delete-conflicting-outputs
```

### Environment Variables (`.env` File)

**Critical:** `.env` file NOT committed (in `.gitignore`). Must be created manually.

**Required Variables:**

```env
OPENAI_API_KEY=sk-...
OPENAI_BASE_URL=https://api.openai.com/v1
GEMINI_API_KEY=...
GEMINI_BASE_URL=https://generativelanguage.googleapis.com/v1beta
FIREBASE_PROJECT_ID=waste-segregation-app
```

### Firebase Setup

- iOS: `GoogleService-Info.plist` in `ios/Runner/`
- Android: `google-services.json` in `android/app/`
- Web: Config in `web/index.html`
- Rules/Indexes: Deploy with `firebase deploy --only firestore:rules,firestore:indexes`

### Platform-Specific Notes

- **iOS:** AppDelegate selector/cast warnings (non-critical)
- **Android:** Min SDK 21, ProGuard rules for Hive/Firebase
- **Web:** CORS config needed for cloud APIs; asset paths only for models

### CI/CD

- GitHub Actions workflows (lint, test, build)
- See `docs/CI_PIPELINE_SETUP.md` and `docs/FINAL_CI_RESOLUTION.md`

## Known Gaps / Truths (be blunt)

- On-device inference not implemented; no models shipped.
- No dataset/model provenance in repo; “multiple architectures” are promises, not realities.
- Blank-screen issue reported on simulator; likely init/consent/auth hang or missing env. Need runtime logs to confirm.
- Vendor lock-in: OpenAI/Gemini-first; swapping vendors requires prompt/API adjustments.

## How to Brief a New Agent (TL;DR)

1. Flutter app with rich UX/gamification/Firebase; CV core is stubbed on-device and cloud-dependent.
2. No model files present; add TFLite models + implement inference for offline.
3. Cloud calls need valid OpenAI/Gemini keys in `.env`; verify `ApiConfig` wiring.
4. If blank screen, grab `flutter run` logs; check consent/auth FutureBuilder and env keys.
5. Update this doc whenever models, flows, env, or major screens change.

## Update Checklist (when things change)

- Added/updated model files? Note paths, formats, versions, and loading code.
- Changed inference flow? Describe service, fallbacks, confidence thresholds.
- Added screens/features? List entry points and key viewmodels/providers.
- Updated env/config? Document required keys/defaults and where consumed.
- Fixed/observed runtime issues? Log symptoms, root cause, resolution, date.
- Added datasets? Note source, size, labels, splits, and storage location.

## Troubleshooting Cheatsheet

- **Blank screen after launch:** Run with `flutter run -v` and collect logs; check consent/auth FutureBuilder; ensure `.env` keys exist; verify Firebase init completes.
- **On-device inference returns placeholder:** Expected until TFLite models + inference are wired. Add assets and integrate `tflite_flutter`.
- **API errors/timeouts:** Confirm `ApiConfig` keys/URLs; inspect `UnifiedApiClient` logs; rate limiting/circuit breaker may short-circuit after repeated failures.
- **Assets not loading:** Ensure `pubspec.yaml` includes any new `assets/models/` entries; for web, file I/O is limited—use asset paths.

## Roadmap Stubs (fill in as you go)

- [ ] Ship at least one real on-device model (YOLOv8/YOLOv11/MobileNet/EfficientNet) as `.tflite`; document size/version.
- [ ] Implement real TFLite inference pipeline (preprocess → infer → postprocess) in `OnDeviceVisionService`.
- [ ] Decide cloud prompt/API contract; document input/output and cost expectations.
- [ ] Add telemetry for classification latency/success per model type.
- [ ] Validate and document consent/auth flow to avoid blank-screen regressions.
- [ ] Document actual cloud inference service integration (prompts, parsing, error handling).
- [ ] Create comprehensive API documentation for all services.
- [ ] Add performance benchmarks for different model types.
- [ ] Document data collection pipeline if/when training data is gathered.

---

## Cross-References to Other Documentation

**Essential Reading:**

- `README.md`: Project overview, quick start, version history.
- `CHANGELOG.md`: Detailed version history and release notes.
- `docs/DOCUMENTATION_INDEX.md`: Complete documentation structure (316 lines, all docs indexed).
- `docs/RIVERPOD_MIGRATION_GUIDE.md`: Pure Riverpod architecture guide.

**Architecture & Technical:**

- `docs/SYSTEM_ARCHITECTURE.md`: System-level architecture (if exists).
- `docs/api_integration_system.md`: API integration patterns.
- `docs/MODELS_COMPARISON_GUIDE.md`: Vision model comparison.
- `docs/ALTERNATIVE_VISION_MODELS.md`: Alternative model options.

**Features:**

- `docs/features/COMMUNITY_SYSTEM_DOCUMENTATION.md`: Community features.
- `docs/features/RESULT_SCREEN_V2_INTEGRATION_EXAMPLE.md`: Result screen integration.
- `docs/technical/comprehensive_recycling_codes_research.md`: Recycling taxonomy research.

**Planning & Status:**

- `docs/planning/ENGINEERING_BACKLOG_CONSOLIDATED.md`: 12-week backlog (June 2025).
- `docs/planning/STRATEGIC_ROADMAP_COMPREHENSIVE.md`: Strategic vision.
- `docs/status/CURRENT_ISSUES_SUMMARY.md`: Known issues.
- `docs/analysis/CRITICAL_FIXES_ANALYSIS_SUMMARY.md`: Critical fixes (June 2025).

**Processes:**

- `docs/processes/MANUAL_COMMIT_INSTRUCTIONS.md`: Git procedures.
- `docs/processes/GITHUB_TODO_INTEGRATION.md`: TODO tracking.
- `docs/TESTING_STRATEGY.md`: Test strategy and coverage.

---

## For Agents: Mandatory Actions Before Coding

1. **Read this document top-to-bottom** (seriously).
2. **Check `.env` exists** with valid API keys; if missing, inference will fail.
3. **Review recent CHANGELOG.md entries** to understand latest changes.
4. **Run `flutter analyze`** to see current code health.
5. **Check `docs/status/CURRENT_ISSUES_SUMMARY.md`** for known blockers.
6. **If adding models:** Document in this file (model type, size, version, performance).
7. **If changing flows:** Update relevant architecture section here.
8. **After any significant work:** Update "Last verified" date at top of this doc.

---

## Document Maintenance Protocol

### When to Update This Document

**IMMEDIATELY after:**

- Adding/removing model files or changing inference logic
- Modifying major UI screens or navigation flows
- Changing environment requirements or build process
- Discovering critical bugs or architectural issues
- Adding new services, providers, or major features
- Changing data schemas or storage patterns

**Regular updates:**

- After each sprint/milestone
- Before handing off to another agent
- When onboarding new team members
- After significant refactoring

### Update Checklist

- [ ] Updated relevant section(s) with specific changes
- [ ] Updated "Last verified" date at document top
- [ ] Cross-checked with actual code (don't trust assumptions)
- [ ] Added to Troubleshooting Cheatsheet if bug-related
- [ ] Updated Roadmap Stubs (mark completed, add new items)
- [ ] Verified cross-references to other docs are still accurate
- [ ] Committed changes with clear commit message

### Quality Standards

**Be specific:** "Added YOLOv8n model (6MB, 640x640 input)" not "added model"  
**Be honest:** Document gaps, placeholders, and TODOs clearly  
**Be current:** Remove outdated info; mark deprecated features  
**Be helpful:** Think about what the next agent needs to know

---

## Final Notes

**This document is ~1200 lines for a reason.** Every section exists because an agent needed that info and couldn't find it elsewhere. Don't trim it for brevity—comprehensive > concise for knowledge transfer.

**Prefer over-documentation.** If you think "is this too much detail?" → it's not. Future agents will thank you.

**Trust but verify.** This doc aims for accuracy, but code is the ultimate truth. If you find discrepancies:

1. Check the code first.
2. Update this doc to match reality.
3. Note the date of the fix.

**Keep it alive.** A knowledge base that's 6 months out of date is worse than none—it creates false confidence. Update it or delete it.

---

**Document version:** 2.0  
**Lines:** ~1250  
**Sections:** 14 major sections  
**Coverage:** Architecture, models, UI, services, build, deployment, troubleshooting  
**Maintenance:** Living document—updated continuously

**See also:** `docs/.AGENT_INSTRUCTIONS.md` for quick agent onboarding checklist.
