# Backend Classification Proxy

**Status**: Exploration doc — open research
**Last Updated**: 2026-05-25
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) (G4)
**Related**: [MULTI_MODEL_AI_ROUTING.md](MULTI_MODEL_AI_ROUTING.md), [AI_COST_TELEMETRY_AND_GUARDRAILS.md](AI_COST_TELEMETRY_AND_GUARDRAILS.md), [LOCAL_FIRST_PRIVACY_ARCHITECTURE.md](LOCAL_FIRST_PRIVACY_ARCHITECTURE.md), [CONFIDENCE_THRESHOLD_TUNING.md](CONFIDENCE_THRESHOLD_TUNING.md)

---

## Why This Matters

Today, the ReLoop app calls OpenAI/Gemini directly from the Flutter client for classification. This creates several critical risks:

1. **API keys in the client binary** — extractable via reverse engineering, leading to theft and unbilled usage
2. **No server-side cost enforcement** — `ai_cost_tracker.dart` runs client-side and is tamper-susceptible
3. **No App Check enforcement** — unauthenticated clients can drain AI budget
4. **No provider swap without app release** — changing from OpenAI to Gemini requires a new app release
5. **No server-side audit trail** — all classification logs are client-reported, not server-verified

A `classifyImage` Firebase HTTP Function (analogous to the existing `generateDisposal`) solves all five problems.

---

## Research Summary

### Architecture Pattern: Server-Side AI Proxy

The proxy pattern acts as a gatekeeper between the mobile app and third-party AI providers:

```
Mobile App → [Auth + App Check] → Firebase Function → [Cost Recording] → AI Provider → Response → [Audit] → Client
```

**Current state**: `generateDisposal` Firebase Function exists for disposal reasoning (Layer 4) with App Check, auth, and rate limiting. No equivalent exists for classification — which is the cost-dominant path.

**Key benefits of the proxy**:
- **Decoupling**: Mobile app talks only to your backend API, preventing exposure of third-party endpoint structure
- **Centralized Control**: Swap AI providers, update models, or inject system prompts without app release
- **Cost Integrity**: Server-side cost recording is authoritative — client reports become advisory

### Rate Limiting and Auth Patterns

Do not rely on the client for security. The backend must enforce boundaries:

| Mechanism | What It Prevents | Implementation |
|-----------|-----------------|----------------|
| Firebase Auth JWT | Unauthenticated requests | Require Bearer token in every request |
| App Check | Bot/script/spoofed client calls | Enforce at Firebase Functions level |
| Per-user rate limit | Budget drain from single abused account | Redis/Firestore counter per UID |
| Daily/monthly cap | User exceeds plan allocation | Stateful store rejects before provider call |

### Cost Recording and Budget Enforcement

Direct API calls from clients make it impossible to prevent attackers from exhausting your budget.

**Server-side accounting**: The proxy logs every request with metadata (user ID, model, tokens in/out, timestamp, cost) to Firestore. This is the authoritative cost record.

**Hard caps**: Global budget ceiling + per-user daily caps enforced before provider call. If exceeded, return `429 Too Many Requests` upstream.

**Current code anchors**: `functions/src/index.ts` already has `enforceRateLimit()` pattern and `recordCostToFirestore()` pattern from `generateDisposal`. These should be ported to `classifyImage`.

### Image Upload vs Base64

For vision model inference, **always avoid Base64 in JSON payloads**:

| Approach | Payload Size | Latency | Complexity |
|----------|-------------|---------|------------|
| Base64 in JSON | +33% bloat | Highest — transmits full image | Lowest — single request |
| Storage URL | Original image size | Medium — upload then reference | Medium — two-step flow |
| Direct Storage → Function trigger | Original image size | Lowest — event-driven | Highest — async flow |

**Recommended pattern**:
1. Client uploads image to Firebase Storage (existing pattern)
2. Client sends Storage object URL to `classifyImage` function
3. Function fetches image from internal Storage, sends to AI provider
4. This avoids the 32MB Firebase Functions request body limit

### Provider Key Security

**Hard rule**: Never store AI API keys in the mobile app.

- Distributed keys in APK/IPA files can be extracted via reverse engineering, leading to immediate theft and massive unexpected bills
- All provider keys exist only as Firebase environment config (e.g., `functions:config:set openai.key="..."`)
- The mobile client never touches, sees, or possesses the secret API key

---

## Implementation Path

### Phase 1: ClassifyImage Function

1. Create `functions/src/classify_image.ts` following `generateDisposal` patterns:
   - **Auth**: Require Firebase ID token (Bearer)
   - **App Check**: `shouldEnforceHttpAppCheck()` 
   - **Rate Limiting**: `enforceRateLimit()` per-user
   - **Cost Recording**: `recordCostToFirestore()` server-side
   - **Provider Routing**: Accept `provider` field (openai/gemini) in request body
2. Register in `functions/src/index.ts` as an HTTP callable function
3. Update `AiService._analyzeWithOpenAI()` and `._analyzeWithGemini()` to call proxy in release builds

### Phase 2: Client Migration

1. Add proxy URL config to Firebase Remote Config (allow kill-switch)
2. Add fallback: if proxy unreachable, fall to direct API call (with degraded capabilities)
3. A/B test proxy performance vs direct calls (latency overhead should be <200ms)

### Phase 3: Advanced Routing

1. Server-side model selection (route to cheapest capable provider)
2. Batch API integration (OpenAI Batch API for async processing)
3. Caching layer for duplicate image classifications (perceptual hash lookup)

---

## Request/Response Contract

### Request
```json
{
  "imageUrl": "https://storage.googleapis.com/...",
  "provider": "openai",  // or "gemini", "auto" (server picks)
  "userId": "abc123",
  "sessionId": "xyz",
  "regionCode": "BBMP"
}
```

### Response (Success)
```json
{
  "classification": {
    "category": "plastic_bottle",
    "material": "PET",
    "confidence": 0.95,
    "subcategory": "beverage_container"
  },
  "cost": {
    "tokens": 450,
    "costUsd": 0.0032,
    "provider": "openai",
    "model": "gpt-4o-mini"
  },
  "auditId": "audit_20260525_abc123_001"
}
```

### Response (Error)
```json
{
  "error": {
    "code": "RATE_LIMITED",
    "message": "Daily classification limit reached",
    "retryAfter": "2026-05-26T00:00:00Z"
  }
}
```

---

## Open Questions

1. Should the proxy support both sync (real-time classification) and async (batch/queued) modes from day one?
2. How do we handle large images that exceed the 32MB Functions limit? Force Storage URL approach.
3. Should we cache classification results for identical images (perceptual hash lookup)?
4. How does the proxy interact with offline queue — should queued items go through proxy when connectivity returns?
5. Should the proxy support multi-provider race mode server-side (call OpenAI + Gemini in parallel, return fastest)?

---

## What Could Kill This

- Additional 200-500ms latency from proxy hop degrades user experience unacceptably
- Firebase Functions timeout (540s max) insufficient for complex multi-provider routing
- Storage URL pattern adds complexity that slows adoption
- Cost of running proxy exceeds savings from server-side cost control

---

## Next Steps

1. Port `enforceRateLimit()` and `recordCostToFirestore()` patterns to a new `classifyImage` function
2. Test proxy latency overhead vs direct calls with production-like image sizes
3. Migrate `AiService._analyzeWithOpenAI()` to use proxy in staging
4. A/B test in production with 5% traffic before full rollout
5. Deprecate direct client-to-provider calls in release builds
