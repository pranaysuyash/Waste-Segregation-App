# API Client Architecture & Error Handling

- **Decision it unblocks**: Whether to consolidate multiple API client patterns into a unified client factory with standardized error classification, retry strategies, and observability.
- **Key questions**:
  - Should all providers (OpenAI, Gemini, local VLM, backend proxy) share a common HTTP client with interceptors?
  - Error classification taxonomy: transient vs. permanent, auth vs. rate-limit vs. server-error — how to map to retry/fallback/user-facing messaging?
  - How to surface backend errors to users (classification failures, network errors, payment failures) in a consistent way?
  - Should API version negotiation be built into the client or handled per-endpoint?
- **Kill criteria**: Single-provider architecture where all AI inference goes through one backend endpoint.
- **Status**: Seed — 2026-05-25
- **Links**: [`unified_api_client.dart`](../../lib/services/unified_api_client.dart), [`api_client_factory.dart`](../../lib/services/api_client_factory.dart), [`api_management_service.dart`](../../lib/services/api_management_service.dart), [`enhanced_api_error_handler.dart`](../../lib/services/enhanced_api_error_handler.dart), [`ai_failure.dart`](../../lib/services/ai_failure.dart), [`cost_tracking_interceptor.dart`](../../lib/services/cost_tracking_interceptor.dart)
- **Source discovery**: Gap analysis of `lib/` services — four API-related services exist with no unifying architecture topic.
