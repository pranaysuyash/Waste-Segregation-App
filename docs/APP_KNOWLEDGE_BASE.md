# Waste Segregation App – Living Knowledge Base

> **Purpose:** The canonical, single-source-of-truth reference for any coding agent joining this project. This is not documentation—it's a living brief that captures what actually exists, what's aspirational, and where the gaps are. Keep this file current when code or assumptions change. Err on the side of over-sharing. All agents working on this project MUST read and update this file.

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
- **Current risk:** App can render blank screen if init/consent/auth stalls or if cloud keys are missing. Runtime logs needed to confirm root cause.
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

**Critical:** Any hang in this future chain = blank screen. Debug with `flutter run -v` and logs from `WasteAppLogger`.

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

## Models & Config
- **Enums:** `VisionModelType` (smolVLM, MobileNetV3, EfficientNet, YOLOv8, YOLOv11, OpenAI, Gemini, Roboflow custom, tfliteCustom); `AnalysisMode` (instant, batch, onDevice, hybrid).
- **Defaults:** `VisionModelConfig.onDevice()` = YOLOv8, on-device, object detection enabled, confidence 0.6.
- **Assets missing:** No `assets/models/*.tflite` checked in. To make edge work: add models, register in `pubspec.yaml`, and implement TFLite inference (e.g., `tflite_flutter`).
- **API keys:** `.env` must define OpenAI/Gemini keys (and any ApiConfig values). Without them, cloud inference fails.

## Data & Taxonomy
- **Data presence:** No dataset or manifests in-repo. No training scripts. Classification schema is rich but data-less.
- **Schema:** `WasteClassification` has dozens of fields (category/subcategory/materials, disposal instructions, impacts, gamification hooks, local regs incl. BBMP, environmental metrics).
- **Storage:** Hive for local persistence; Firestore indexes present. No evidence of user-image retention policies; assume classification history saved locally and possibly synced.

## UI / Navigation Map
- **Entry flow:** Splash/init → Consent dialog → Auth screen (Google/guest) → MainNavigationWrapper (tabs).
- **Core screens (observed/referenced):**
  - Home (modern home screen)
  - History (`history_screen.dart`)
  - Leaderboard
  - Achievements & Streaks
  - Classification Result/Details (uses `ResultScreenViewModel` for save/share/gamification)
  - Points/Challenges views
  - AI Discovery content
  - Disposal instructions
  - Family dashboard (per README)
  - Premium routes/features
- **Capture:** Camera/gallery via `image_picker`; web helper `web_camera_access.dart`; `CaptureButton` and `AnimatedFab` for quick actions.
- **UX notes:** Confidence thresholds configurable; on-device/offline claims currently aspirational; coach marks and gamification present.

## Services (grab bag)
- `OnDeviceVisionService`: Placeholder on-device inference; loads/creates model path; returns dummy classification.
- `ApiClientFactory`: Builds OpenAI/Gemini/Firebase clients with rate limiting/circuit breaking.
- `StorageService`: Hive persistence for classifications/profile.
- `BatchOperationService`: Batched uploads/sync (recent edits noted).
- `AnalyticsService`: Event tracking with schema validation.
- `GamificationService`: Processes classifications into points/achievements/challenges.
- `CloudStorageService`: Uploads images/thumbnails.

## Build & Environment
- **Flutter:** Run with `.env` dart-defines. Check `pubspec.yaml` for assets (add models there when available).
- **Env vars:** `.env` should include OpenAI/Gemini keys and any ApiConfig URLs. Missing keys → cloud inference fails.
- **iOS:** Minor AppDelegate warnings (selector/cast). Verify after adding any native plugins (e.g., TFLite).

## Known Gaps / Truths (be blunt)
- On-device inference not implemented; no models shipped.
- No dataset/model provenance in repo; “multiple architectures” are promises, not realities.
- Blank-screen issue reported on simulator; likely init/consent/auth hang or missing env. Need runtime logs to confirm.
- Vendor lock-in: OpenAI/Gemini-first; swapping vendors requires prompt/API adjustments.

## How to Brief a New Agent (TL;DR)
1) Flutter app with rich UX/gamification/Firebase; CV core is stubbed on-device and cloud-dependent. 
2) No model files present; add TFLite models + implement inference for offline. 
3) Cloud calls need valid OpenAI/Gemini keys in `.env`; verify `ApiConfig` wiring. 
4) If blank screen, grab `flutter run` logs; check consent/auth FutureBuilder and env keys. 
5) Update this doc whenever models, flows, env, or major screens change.

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
