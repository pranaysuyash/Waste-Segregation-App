# Waste Segregation App: API Specification

Reference documentation for all API services, endpoints, data models, and integration patterns.

## Overview

The app uses a layered API architecture:

- **HTTP Transport Layer** — `UnifiedApiClient` wraps Dio with rate limiting, retry, versioning, and statistics.
- **Factory Layer** — `ApiClientFactory` creates pre-configured clients for OpenAI, Gemini, and Firebase.
- **Service Layer** — `EnhancedAiApiService` (AI classification), `ApiManagementService` (monitoring), `ResilientNetworkService` (circuit breaker).
- **Error & Cost Layer** — `EnhancedApiErrorHandler`, `CostTrackingInterceptor`.

Service files at `lib/services/`, models at `lib/models/`.

---

## 1. Core HTTP Client: UnifiedApiClient

**File:** `lib/services/unified_api_client.dart`

Generic HTTP client wrapping Dio with built-in rate limiting, API versioning, retry, and statistics. Used by all API services.

### Constructor

```dart
UnifiedApiClient({
  String? baseUrl,
  Map<String, String>? defaultHeaders,
  Duration? connectTimeout,
  Duration? receiveTimeout,
  Duration? sendTimeout,
  EnhancedApiErrorHandler? errorHandler,
  bool enableRequestDeduplication = false,
  bool enableRateLimiting = true,
  int maxConcurrentRequests = 10,
})
```

### HTTP Methods

All methods return `Future<ApiResponse<T>>` and accept a required named `endpoint` parameter plus optional named parameters.

| Method | Notable parameters |
|--------|--------------------|
| `get` | `endpoint`, `queryParameters`, `headers`, `apiVersion`, `timeout`, `operationId` |
| `post` | `endpoint`, `data`, `queryParameters`, `headers`, `apiVersion`, `timeout`, `operationId`, `onSendProgress` |
| `put` | `endpoint`, `data`, `queryParameters`, `headers`, `apiVersion`, `timeout`, `operationId` |
| `patch` | `endpoint`, `data`, `queryParameters`, `headers`, `apiVersion`, `timeout`, `operationId`, `onSendProgress` |
| `delete` | `endpoint`, `queryParameters`, `headers`, `apiVersion`, `timeout`, `operationId` |

### Versioning

```dart
void configureApiVersions({
  required Map<String, ApiVersion> versions,
  ApiVersion? defaultVersion,
})
```

Registers named API versions (e.g., `'v1'`, `'v1beta'`) with their service endpoint details. The `apiVersion` parameter on each HTTP method selects which configured version to use.

### Statistics

| Method | Return Type | Description |
|--------|-------------|-------------|
| `getStatistics()` | `Map<String, dynamic>` | Active requests, queue depth, dedup state, rate-limiter stats, circuit-breaker status, API version info |
| `dispose()` | `void` | Releases resources: cancels cleanup timer, closes Dio, completes queued requests with error |

### Security & Privacy

- Logged URIs are sanitized: query strings stripped, IDs normalized to `:id`.
- Headers are redacted case-insensitively: `authorization`, `x-goog-api-key`, `api-key`, `x-api-key`, `cookie`, `set-cookie`.
- Deduplication keys are hashed from sanitized method/path/query-shape — no raw body or query strings stored. Dedup keys are not logged.
- Rate-limit acquire/release is wrapped in a single `try/finally` to prevent leaked request counts.
- Periodic cleanup timer is stored and cancelled in `dispose()`.
- On `dispose()`, all queued request completers are completed with an error so no future hangs. Subsequent calls throw `StateError`.

---

## 2. API Client Factory: ApiClientFactory

**File:** `lib/services/api_client_factory.dart`

Singleton factory that creates and caches pre-configured `UnifiedApiClient` instances.

### `getOpenAIClient()`

```dart
static UnifiedApiClient getOpenAIClient()
```

- **Base URL:** `https://api.openai.com`
- **Circuit breaker:** Threshold 8 failures, 3-minute timeout
- **API versions:** `v1` (default), `v1beta` (with `beta` path prefix)
- **Rate limits:** 60 RPM, 100,000 TPM

### `getGeminiClient()`

```dart
static UnifiedApiClient getGeminiClient()
```

- **Base URL:** `https://generativelanguage.googleapis.com`
- **Circuit breaker:** Threshold 10 failures, 2-minute timeout
- **API versions:** `v1beta` (default), `v1`
- **Rate limits:** 60 RPM, 60,000 TPM

### `getFirebaseClient()`

```dart
static UnifiedApiClient getFirebaseClient()
```

- **Base URL:** Configured at runtime
- **Circuit breaker:** Threshold 5 failures, 5-minute timeout
- **API versions:** `v1` (default)
- **Rate limits:** 120 RPM, 50,000 TPM

### `getCustomClient()`

```dart
static UnifiedApiClient getCustomClient({
  required String baseUrl,
  Map<String, String>? defaultHeaders,
  Duration? timeout,
  int circuitBreakerThreshold = 5,
  Duration circuitBreakerTimeout = const Duration(minutes: 5),
  bool enableRateLimiting = true,
  Map<String, ApiVersion>? apiVersions,
  ApiVersion? defaultVersion,
})
```

Fully configurable client for custom API integrations.

### Utility Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `getAllClients()` | `Map<String, UnifiedApiClient>` | All cached client instances |
| `getAllStatistics()` | `Map<String, Map<String, dynamic>>` | Statistics for all clients, keyed by name |
| `resetAllClients()` | `void` | Clears cached clients and resets stats |
| `configureRateLimit(String serviceName, {int? rpm, int? tpm})` | `void` | Updates rate limits for a cached client |

---

## 3. AI Analysis Service: EnhancedAiApiService

**File:** `lib/services/enhanced_ai_api_service.dart`

Primary service for classifying waste items from images using OpenAI and Gemini with automatic fallback and race strategy.

### Constructor

```dart
EnhancedAiApiService({Duration? timeout})
```

API keys are read from `RemoteConfigService` at runtime.

### `analyzeWaste(String imagePath)`

```dart
Future<WasteClassification> analyzeWaste(String imagePath)
```

**Flow:**
1. Checks both providers are configured (have API keys).
2. Launches parallel requests to both providers (default timeout: 60s).
3. First successful response wins the race.
4. On failure: falls back to the other provider.
5. On all failures: returns `WasteClassification.fallback(imagePath)`.

### `analyzeWasteWithProvider(String imagePath, {required AIProvider provider})`

```dart
Future<WasteClassification> analyzeWasteWithProvider(
  String imagePath, {
  required AIProvider provider,  // AIProvider.openAI or AIProvider.gemini
})
```

Bypasses the race strategy, uses a specific provider.

### `reanalyzeWithAlternativeProvider(String imagePath, {required WasteClassification previousResult})`

```dart
Future<WasteClassification> reanalyzeWithAlternativeProvider(
  String imagePath, {
  required WasteClassification previousResult,
})
```

Re-runs analysis with the provider NOT used initially. Used for low-confidence results.

### Provider Status

| Method | Returns |
|--------|---------|
| `isOpenAIConfigured()` | `bool` — API key available |
| `isGeminiConfigured()` | `bool` — API key available |
| `getProviderStatus()` | `Map<AIProvider, bool>` — configured status per provider |

---

## 4. Error Handling: EnhancedApiErrorHandler

**File:** `lib/services/enhanced_api_error_handler.dart`

### Error Categories

| Category | Cause | Recoverable? |
|----------|-------|-------------|
| `network` | DNS, connection, socket errors | Yes |
| `timeout` | Request exceeded timeout | Yes |
| `rate_limit` | HTTP 429 — Too Many Requests | Yes (with backoff) |
| `auth` | HTTP 401/403 — invalid API key | No |
| `server` | HTTP 5xx — server-side errors | Yes |
| `client` | HTTP 4xx — bad request, not found | Varies |
| `unknown` | Unclassified errors | Unknown |

### Methods

| Method | Description |
|--------|-------------|
| `handleApiError(error, {String? serviceName})` | Classifies error → `ApiError` |
| `hasRecoverableError(error)` | `true` if safe to retry |
| `getRetryDelay(error)` | Adaptive delay: 1s network, 30s rate-limit, 1s timeout, 0.5s server |
| `getUserFriendlyMessage(error)` | User-readable error message |

### ApiError Structure

```dart
class ApiError {
  final String category;       // network, timeout, rate_limit, auth, server, client, unknown
  final String message;        // Human-readable description
  final int? statusCode;       // HTTP status code if applicable
  final dynamic originalError; // Original exception
  final String? serviceName;   // Service identifier
  final bool isRecoverable;    // Can be retried
  final Duration retryDelay;   // Recommended delay before retry
}
```

---

## 5. Resilient Network Service

**File:** `lib/services/resilient_network_service.dart`

### Circuit Breaker States

| State | Behavior |
|-------|----------|
| `closed` | Normal — requests pass through |
| `open` | Requests rejected. Transitions to half-open after timeout |
| `halfOpen` | Test requests allowed. Success → closed, Failure → open |

### Methods

| Method | Description |
|--------|-------------|
| `executeWithCircuitBreaker(operation, {operationName, failureThreshold = 5, timeout = 30s})` | Wraps operation with circuit breaker |
| `executeWithRetry(operation, {maxRetries = 3, baseDelay = 1s})` | Wraps operation with exponential backoff |
| `executeWithQueue(operation)` | Queues requests that are rate-limited |

### Retry Behavior

Exponential backoff: `baseDelay * 2^attempt` with jitter.

---

## 6. Rate Limiting

**File:** `lib/services/rate_limiter.dart`

### RateLimiter (token bucket)

```dart
RateLimiter({
  required int maxRequestsPerMinute,   // RPM
  required int maxTokensPerMinute,     // TPM
  String? serviceName,
})
```

### CostAwareRateLimiter

Extends `RateLimiter` to track dollar cost alongside token usage.

```dart
CostAwareRateLimiter({
  required int maxRequestsPerMinute,
  required int maxTokensPerMinute,
  double costPerRequest = 0.0,
  double costPerToken = 0.0,
  String? serviceName,
  double maxCostPerMinute = double.infinity,
})
```

### Default Limits

| Service | RPM | TPM | Cost/Request | Cost/Token |
|---------|-----|-----|-------------|------------|
| OpenAI | 60 | 100,000 | $0.01 (GPT-3.5) / $0.03 (GPT-4) | $0.001/1K (GPT-3.5) / $0.01/1K (GPT-4) |
| Gemini | 60 | 60,000 | $0.0025 | $0.0005/1K |
| Firebase | 120 | 50,000 | $0.00 | $0.00 |

---

## 7. Cost Tracking: CostTrackingInterceptor

**File:** `lib/services/cost_tracking_interceptor.dart`

Dio interceptor that provides rough telemetry estimates for API usage costs. **Not a billing-grade source of truth.** Cost values are approximate and labeled as such in logs.

**IMPORTANT:** This interceptor provides rough telemetry estimates for usage
analysis. It is **not** a billing-grade source of truth.

| Method | Return Type | Description |
|--------|-------------|-------------|
| `getCostStatistics()` | `Map<String, dynamic>` | Total cost, request count, avg cost per service (rough telemetry) |
| `resetCostTracking()` | `void` | Resets all cost counters |
| `setServiceCost(String serviceName, double costPerRequest)` | `void` | Sets custom cost-per-request for a service |

### Cost Statistics Output

```json
{
  "openai": {
    "service_name": "openai",
    "total_requests": 60,
    "total_cost": 0.12,
    "average_cost": 0.002,
    "error_rate": 0.05,
    "average_duration_ms": 3200,
    "total_data_bytes": 450000,
    "recent_requests_1h": 15,
    "recent_cost_1h": 0.03,
    "most_expensive_endpoint": "/v1/chat/completions",
    "slowest_endpoint": "/v1/chat/completions"
  },
  "summary": {
    "total_cost": 0.12,
    "total_requests": 60,
    "average_cost_per_request": 0.002,
    "tracked_services": ["openai"]
  }
}
```

Log fields are labeled `rough_telemetry_cost_estimate` to disclaim billing accuracy. Service names are normalized; unknown names from headers become `"custom"`. Tracker count is bounded at 32 services.

---

## 8. API Management & Monitoring: ApiManagementService

**File:** `lib/services/api_management_service.dart`

Central monitoring for all API integrations. Used by settings/admin UI.

| Method | Description |
|--------|-------------|
| `getHealthStatus()` | Health of all providers (`operational`, `degraded`, `down`) |
| `getDetailedStatistics()` | Per-provider stats with circuit-breaker and rate-limiter state |
| `checkProviderHealth(provider)` | Health check for a specific provider |
| `getOptimizationRecommendations()` | Adaptive recommendations from usage patterns |
| `getCostAnalysis()` | Cost analysis with daily/monthly breakdowns |
| `tuneRateLimit(provider, type)` | Adjusts rate limits based on error rates |
| `getServiceStatusSummary()` | Current status of all monitored services |
| `resetAllStatistics()` | Resets all monitoring stats |

### Enums

```dart
enum HealthStatus { operational, degraded, down, unknown }

enum OptimizationType {
  increaseRateLimit, decreaseRateLimit, switchProvider,
  reduceTimeout, increaseRetry, decreaseRetry,
  enableCaching, disableCaching,
}
```

---

## 9. Data Models

### ApiVersion

**File:** `lib/models/api_version.dart`

```dart
class ApiVersion {
  final String version;        // e.g., "v1", "v1beta"
  final String serviceName;    // e.g., "openai", "gemini", "firebase"
  final String? pathPrefix;    // URL path prefix, e.g., "/v1/chat"

  factory ApiVersion.openAI({String version = 'v1', String? pathPrefix});
  factory ApiVersion.gemini({String version = 'v1beta', String? pathPrefix});
  factory ApiVersion.firebase({String version = 'v1', String? pathPrefix});
  factory ApiVersion.defaultVersion();
  factory ApiVersion.fromMap(Map<String, dynamic> map);

  Map<String, dynamic> toMap();
}
```

### ApiResponse\<T\>

**File:** `lib/models/api_response.dart`

```dart
class ApiResponse<T> {
  final T data;                             // Response payload
  final int statusCode;                     // HTTP status code
  final String? statusMessage;              // HTTP status message
  final Map<String, List<String>>? headers; // Response headers
  final String? operationId;                // Operation tracking ID
  final RequestOptions? requestOptions;      // Original request options
  final ApiTiming? timing;                  // Request timing
  final CacheInfo? cacheInfo;               // Cache metadata

  bool get isSuccessful;     // statusCode 200-299
  bool get isFromCache;      // from cache
  Map<String, dynamic> toMap();
}
```

### ApiTiming

```dart
class ApiTiming {
  final DateTime startTime;
  final DateTime endTime;
  final Duration? dnsLookupTime;
  final Duration? connectionTime;
  final Duration? tlsHandshakeTime;
  final DateTime? requestSentTime;
  final DateTime? responseReceivedTime;
  Duration get totalDuration;  // endTime - startTime
}
```

### CacheInfo

```dart
class CacheInfo {
  final bool isFromCache;
  final String? cacheKey;
  final DateTime? cachedAt;
  final DateTime? expiresAt;
  final Duration? maxAge;
  final String? etag;
  final DateTime? lastModified;
  bool get isExpired;
  Duration? get timeUntilExpiration;
}
```

---

## 10. Classification Processing Pipeline: ResultPipeline

**File:** `lib/services/result_pipeline.dart`

Riverpod `StateNotifier` that orchestrates post-classification processing.

### Pipeline Stages

| # | Stage | Action | Critical |
|---|-------|--------|----------|
| 1 | Local Save | Persist to Hive/device storage | Yes |
| 2 | Gamification | Award points, check achievements/challenges | Yes |
| 3 | Cloud Sync | Sync to Firestore (`isGoogleSyncEnabled`) | No |
| 4 | Community Post | Share to community feed (`shareToFeed`) | No |
| 5 | Interstitial Ad | Show ad if conditions met | No |

### Key Methods

| Method | Description |
|--------|-------------|
| `processClassification(classification, {force, autoAnalyze})` | Full pipeline with duplicate prevention |
| `submitFeedback(...)` | User feedback with dedup via `ClassificationFeedback.dedupKey()` |
| `shareClassification(classification)` | Dynamic link + system share sheet |
| `saveClassificationOnly(classification, {force})` | Save without full pipeline |
| `processRetroactiveGamification()` | Award points for existing unprocessed classifications |
| `trackScreenView(classification)` | Analytics screen view |
| `trackUserAction(action, classification)` | Analytics user action |
| `reset()` | Reset pipeline state |

### FeedbackResult

```dart
class FeedbackResult {
  final bool saved;
  final int pointsAwarded;
  final int nominalPoints;
  final bool wasDuplicate;
  final bool cloudSynced;
}
```

---

## 11. Default Configuration

### Timeouts

| Context | Default | Configurable |
|---------|---------|--------------|
| UnifiedApiClient base | 30s | Via constructor `timeout` |
| AI analysis (per provider) | 60s | Via `EnhancedAiApiService` constructor |
| Retry base delay | 1s | Via `executeWithRetry` `baseDelay` |
| Circuit breaker (Firebase) | 5 min | Via `getCustomClient()` |
| Circuit breaker (Gemini) | 2 min | Fixed in `getGeminiClient()` |
| Circuit breaker (OpenAI) | 3 min | Fixed in `getOpenAIClient()` |

### Retry Counts

| Context | Default |
|---------|---------|
| Standard retry | 3 attempts |
| Router-based retry | 2 attempts |

---

## 12. API Key Configuration

API keys are managed through `RemoteConfigService` (Firebase Remote Config) — not hardcoded, not in source:

- **OpenAI:** `api_key` / `openai_api_key` remote config key
- **Gemini:** `gemini_api_key` remote config key

---

## Related

- [Service source files](../lib/services/)
- [Data model source files](../lib/models/)
- [QA testing checklist](../../testing/QA_CHECKLIST.md)
- [AI service refactor decisions](../../ai_service_refactor_motto_v2_2026-05-19.md)