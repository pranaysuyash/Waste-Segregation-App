# AI Service Refactoring (motto_v2 Discipline)

**Date**: 2026-05-24
**Status**: Exploration — architectural refactoring analysis
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md)
**Decision this unblocks**: Whether to refactor `AiService` now vs defer to post-launch

---

## 1. Current State Assessment

`lib/services/ai_service.dart` is a monolithic service class (~950 lines) with multiple responsibilities:

| Responsibility | Lines (approx) | Concerns |
|---|---|---|
| Image compression (OpenAI) | ~80 | Tight coupling to image library |
| Image compression (Gemini) | ~50 | Duplicated logic paths |
| MIME type detection | ~25 | Utility logic mixed with orchestration |
| API calling (OpenAI) | ~50 | HTTP logic mixed with compression |
| API calling (Gemini) | ~40 | HTTP logic mixed with prompts |
| API calling (Backend proxy) | ~30 | Different auth/transport |
| Response orchestration | ~120 | Routing, retry, fallback logic |
| Cache checking | ~60 | Dual-hash, context-aware key building |
| User correction handling | ~80 | Correction flow directly in service |
| Region/crop analysis | ~80 | Image processing in service |
| Budget/guardrail delegation | ~40 | Passthrough to sub-services |
| Initialization/logging | ~60 | Config state, logging |
| Dispose/cleanup | ~20 | Resource management |

### Anti-patterns identified

1. **God Class** — `AiService` handles image processing, API networking, response parsing, caching, routing, correction, segmentation, and budget management
2. **Shotgun Surgery** — A change to the AI response format requires updates across compression, parsing, caching, orchestration, and model classes
3. **Code Duplication** — Image compression logic duplicated for OpenAI vs Gemini paths, hash generation duplicated for mobile vs web entry points
4. **Mixed Abstraction Levels** — High-level orchestration (`_orchestrateAnalysis`) contains low-level details (Dio timeouts, image format detection)
5. **Constructor Bloat** — Factory constructor accepts 15+ optional parameters, most with complex defaulting logic

---

## 2. Proposed Service Split

### Target Architecture

```
AiService (Orchestrator Facade)
├── ImageProcessingService      — compression, EXIF stripping, format detection, cropping
├── AiApiGateway                — HTTP transport, auth, retry, cancellation (OpenAI/Gemini/Backend)
├── AiResponseParser            — JSON cleaning, schema validation, fallback creation
├── ClassificationCacheService  — dual-hash caching, context-aware keys (EXISTS)
├── AiProviderRouter            — provider selection, fallback chain (EXISTS)
├── AiUsageAccountingService    — cost tracking, budget monitoring (EXISTS)
└── CorrectionService           — correction flow orchestration (extracted)
```

### What stays vs what moves

| Current `AiService` method | Target | Rationale |
|---|---|---|
| `initialize()` | Stays in facade | Sequence coordination |
| `analyzeImage()` / `analyzeWebImage()` | Stays in facade | Entry-point orchestration |
| `_compressImageForOpenAI()` | → `ImageProcessingService` | Pure image utility |
| `_compressImageForGemini()` | → `ImageProcessingService` | Same target |
| `_detectImageMimeType()` | → `ImageProcessingService` | Format utility |
| `_callOpenAiProvider()` | → `AiApiGateway` | HTTP transport |
| `_callGeminiProvider()` | → `AiApiGateway` | Same target |
| `_callBackendProvider()` | → `AiApiGateway` | Same target |
| `_orchestrateAnalysis()` | Stays in facade | Routing coordination |
| `handleUserCorrection()` | → `CorrectionService` | Separate concern |
| `analyzeImageRegions()` / `_analyzeSingleRegion()` | → `ImageProcessingService` | Image operation |
| `buildContextualCacheKey()` | Stays in `ClassificationCacheService` | Already delegated |
| `cleanJsonString()` | → `AiResponseParser` | Response processing |
| Budget passthroughs | Stays in facade | Thin delegation |

---

## 3. Clean Architecture Mapping

```
┌──────────────────────────────────────────┐
│           Presentation Layer             │
│  (providers, screens, widgets)           │
│  Depends on: AiService facade only       │
└────────────────┬─────────────────────────┘
                 │ calls
┌────────────────▼─────────────────────────┐
│            Domain Layer                  │
│  AiService (orchestrator interface)      │
│  WasteClassification (entity)           │
│  ClassificationResult (entity)          │
│  Pure Dart — no SDK dependency           │
└────────────────┬─────────────────────────┘
                 │ delegates to
┌────────────────▼─────────────────────────┐
│             Data Layer                   │
│  ImageProcessingService                  │
│  AiApiGateway (Dio, Firebase)            │
│  AiResponseParser                        │
│  ClassificationCacheService (Hive)       │
│  CorrectionService                       │
└──────────────────────────────────────────┘
```

**Key principle**: The facade (`AiService`) stays in domain layer as a thin coordinator. All implementation details move to data layer. Presentation code depends only on the facade.

---

## 4. Dependency Injection Strategy

**Current**: Factory constructor with cascading defaults — resolves dependencies inline, creates sub-services with same instances

**Target**: Use existing Riverpod providers for clean DI:

```dart
// Providers already exist for some sub-services
final imageProcessingServiceProvider = Provider((ref) => ImageProcessingService());
final aiApiGatewayProvider = Provider((ref) => AiApiGateway(
  openAiConfig: ref.watch(openAiConfigProvider),
  geminiConfig: ref.watch(geminiConfigProvider),
));
final aiResponseParserProvider = Provider((ref) => AiResponseParser());
final correctionServiceProvider = Provider((ref) => CorrectionService(
  apiGateway: ref.watch(aiApiGatewayProvider),
  parser: ref.watch(aiResponseParserProvider),
));
final aiServiceProvider = Provider((ref) => AiService(
  imageProcessing: ref.watch(imageProcessingServiceProvider),
  apiGateway: ref.watch(aiApiGatewayProvider),
  parser: ref.watch(aiResponseParserProvider),
  cacheService: ref.watch(classificationCacheServiceProvider),
  router: ref.watch(aiProviderRouterProvider),
  usageAccounting: ref.watch(aiUsageAccountingServiceProvider),
  correctionService: ref.watch(correctionServiceProvider),
));
```

**Benefits**:
- Compile-time safety with Riverpod
- Each service independently testable
- Lifecycle management via `autoDispose`
- No constructor bloat in the facade

---

## 5. Testing Strategy

| Service | Test Approach | Key Behaviors |
|---|---|---|
| `ImageProcessingService` | Unit test with real image bytes | Compression ratio, format detection, crop bounds, EXIF stripping |
| `AiApiGateway` | Unit test with mocked HTTP | Timeouts, retries, cancellation, auth errors |
| `AiResponseParser` | Unit test with fixture JSON strings | Valid JSON, malformed JSON, markdown-wrapped JSON, incomplete responses |
| `CorrectionService` | Unit test with mocked gateway + parser | Correction flow, provenance tracking, error fallback |
| `AiService` (facade) | Integration test with mocked sub-services | Orchestration, retry chain, cache hit/miss, fallback creation |

**Mocking approach**: Use `mocktail` (no code generation) for sub-service mocks. Each sub-service gets an abstract interface.

---

## 6. Migration Sequence

### Phase A: Extract pure utilities (no behavior change)
1. Create `ImageProcessingService` — move compression, MIME detection, crop logic
2. Create `AiResponseParser` — move `cleanJsonString()`, JSON validation
3. Create `AiApiGateway` — move `_callOpenAiProvider`, `_callGeminiProvider`, `_callBackendProvider`
4. `AiService._fromResolved` becomes thinner; existing factory still works via delegation

### Phase B: Extract CorrectionService
5. Create `CorrectionService` — move `handleUserCorrection`, correction prompt building
6. Add Riverpod providers for all new services
7. Update tests to use mocked sub-services

### Phase C: Facade slim-down (optional)
8. Consider whether `AiService` facade is still needed or if callers can go directly to sub-services
9. If kept: make it a stateless coordinator with pure delegation only

---

## 7. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Breaking existing callers | Medium | High | Phase A is extract-only; keep original method signatures as delegation |
| Test fixture duplication | Medium | Low | Create shared test fixtures for AI responses |
| Performance regression from extra indirection | Low | Low | Facade is zero-cost abstraction; sub-services are singletons |
| Regressions in correction flow | High | Medium | Add regression tests before refactoring correction path |
| Provider/provider ordering | Low | Medium | Riverpod resolves automatically; integration test verifies |

---

## 8. Decision Points

1. **Extract now vs post-launch**: Current `AiService` works. Refactoring reduces friction for future changes (e.g., new AI providers, schema changes). Recommend: Phase A (pure extraction) before next AI provider integration.
2. **Keep facade vs eliminate**: If all callers can use Riverpod providers directly, the facade may become unnecessary. Recommend: keep facade for now, evaluate after Phase B.
3. **Abstract interfaces for all sub-services**: Adds up-front cost but enables full mocking. Recommend: yes for `AiApiGateway` and `CorrectionService` (where HTTP/IO is involved); less critical for pure utility services.

---

## 9. Related

- [motto_v2.md](../../motto_v2.md) — Clean architecture, single responsibility, testability
- [Gamification Redesign Spec](../planning/gamification-redesign-spec.md) — Depends on archetype service, which would also benefit from clean DI
- [EXPLORATION_FRONTIER.md](../EXPLORATION_FRONTIER.md) — AI service growth is a frontier item
