# Release Classification Path Micro-Audit

**Date**: 2026-05-24  
**Status**: Exploration / no-code micro-audit  
**Parent context**: Backend proxy hardening reality check  
**Scope**: Smaller surface check: `AiService` and `BackendProxyProvider` release routing.  
**Non-goal**: No code changes; not a full app-wide path audit.

## Question

For the primary `AiService` classification paths, do release builds route through the backend proxy or can they still call OpenAI/Gemini directly?

## Evidence reviewed

- `lib/utils/production_safety_config.dart`
- `lib/services/providers/backend_proxy_provider.dart`
- `lib/services/ai_service.dart`

## Findings

### 1. Primary full-image paths are designed to fail closed in release

`AiService.analyzeImage()` and `AiService.analyzeWebImage()` both flow into `_orchestrateAnalysis()`.

`_orchestrateAnalysis()` first tries `_analyzeWithBackend()` when `_backendRoutingEnabled` is true. The release invariant is implemented by `_backendRoutingEnabled` / `_backendRoutingFailClosed` logic: release builds are expected to use the backend route and not fall through to direct providers on terminal failures.

If direct OpenAI/Gemini paths are reached in release, provider clients call `ProductionSafetyConfig.guardClientAiCall(...)`, which throws unless `ALLOW_CLIENT_AI_IN_RELEASE=true`.

### 2. Backend provider is a thin callable client

`BackendProxyProvider` calls Firebase Callable `classifyImage` and deliberately does not call `ProductionSafetyConfig.guardClientAiCall` because it is not a direct provider call. It forwards:

- `imageBase64`,
- `mimeType`,
- optional `clientHash`,
- `region`,
- `lang`,
- `requestId`.

The returned `classification` map is normalized into the existing `AiProviderResponse` flow, so `AiService` can reuse its parser/result processor.

### 3. Smaller-surface risk found: cropped region analysis calls `_analyzeWithOpenAI()` directly

`AiService._analyzeSingleRegion()` crops the selected region and then calls `_analyzeWithOpenAI(...)` directly, not `_orchestrateAnalysis(...)`.

That means region analysis does not intentionally go through `_analyzeWithBackend()` first.

In release, this should still be blocked by `ProductionSafetyConfig.guardClientAiCall` inside the OpenAI provider path unless `ALLOW_CLIENT_AI_IN_RELEASE=true`; so this looks more like a **release functionality gap** than a silent key leak in normal release settings.

But it is still a bypass of backend proxy hardening semantics:

- no backend token reservation,
- no backend rate limit,
- no backend `ai_cost_events`,
- no backend OpenAI->Gemini fallback,
- no server cache / server pHash path,
- likely fails or falls back for users instead of working through proxy.

## Current label

For this smaller surface:

- **Primary full-image classification**: backend-proxy aligned in release.
- **Manual/multi-region cropped classification**: release-risk path because it bypasses `_orchestrateAnalysis()` and calls direct OpenAI first.

## Follow-up implementation

`_analyzeSingleRegion()` now calls `_orchestrateAnalysis()` with the cropped bytes, so manual/cropped region analysis follows the same backend-first orchestration path as full-image classification.

Validation added:

1. `test/services/ai_service_backend_test.dart` now exercises `analyzeWebImageRegion()` through the backend proxy.
2. The same test file also asserts backend failures remain terminal when fail-closed routing is forced for the region path.
3. Region/language/request metadata still flows through the backend proxy contract unchanged.

Telemetry and router implications:

- Cropped/manual region scans now contribute to the same backend `classifyImage` request accounting as normal scans.
- That means reservation/refund logic, cache-hit logging, cost events, and `route: 'classifyImage'` telemetry all apply to region analysis too.
- Router metrics and backend proxy logs should now reflect region scans instead of treating them as a separate direct-provider lane.
- The client-side direct OpenAI/Gemini path remains the fallback only when the shared orchestrator is not backend-enabled or when non-fail-closed behavior is explicitly allowed in non-release contexts.

## Caveat

This was intentionally a smaller surface, not a full classification path audit. Other services still need separate checks, especially `EnhancedAiApiService`, `ModelSelectionService`, and any direct provider usage outside `AiService`.

## Missed-anything sweep

- **Instruction compliance**: No code changed; documented the focused finding.
- **Canonical paths**: Recommended extending existing `_orchestrateAnalysis()` path, not adding a duplicate route.
- **End-to-end flow checked**: `analyzeImage` / `analyzeWebImage` -> `_orchestrateAnalysis` -> backend; region crop -> `_analyzeWithOpenAI` direct.
- **User value**: Region/multi-item classification should work under the same secure backend path as normal scans.
- **Business/team value**: Prevents a future launch surprise where multi-item classification silently fails in release or bypasses cost controls if direct AI is enabled.
- **Operational value**: Keeps token/cost/rate telemetry complete for region scans.
- **Unclosed gaps**: Full app-wide release path audit still open.
- **Confidence**: High confidence for this `AiService` finding based on direct code inspection. Not claiming all classification paths are covered.
