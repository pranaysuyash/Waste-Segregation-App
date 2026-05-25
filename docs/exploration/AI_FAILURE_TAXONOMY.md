# AI Failure Modes Taxonomy

**Purpose**: Define a shared taxonomy of AI failure modes so the app can handle, instrument, and communicate each type distinctly.
**Status**: Exploration — `ai_failure.dart` exists but collapses most failures into one bucket
**Last Updated**: 2026-05-25
**Related**: [AI_COST_TELEMETRY_AND_GUARDRAILS.md](AI_COST_TELEMETRY_AND_GUARDRAILS.md), [TRUTHFUL_AI_EVAL_GATES.md](TRUTHFUL_AI_EVAL_GATES.md), [SAFETY_CRITICAL_AUTONOMY_RULES.md](SAFETY_CRITICAL_AUTONOMY_RULES.md)

---

## Problem Statement

"AI failed" is the single most user-affecting and least-instrumented event class. Today, most failure modes are collapsed into a generic error. This makes it impossible to:

- Distinguish transient provider errors (auto-retry) from permanent input errors (user must retake photo)
- Track provider reliability over time per failure type
- Ensure tokens are not charged for failures that shouldn't consume credit
- Deliver appropriate user-facing copy per failure type

---

## Failure Mode Taxonomy

| Failure Mode | Code | Token Cost | Auto-Retry | User Action |
|-------------|------|-----------|------------|-------------|
| Provider Error (5xx) | `provider_error` | No | Yes (3x, backoff) | None (retry) |
| Timeout | `timeout` | Partial (depends on provider) | Yes (2x) | None (retry) |
| Safety Refusal | `safety_refusal` | Yes (safety check consumed) | No | User must provide different image |
| Parse Failure | `parse_failure` | Yes (inference completed) | Maybe (1x, if non-deterministic) | Logged for engineering |
| Quality Gate Rejection | `quality_gate` | No | No | User must retake/upload better image |
| Low Confidence | `low_confidence` | Yes | No | Escalate to next tier or ask user |
| Contradictory Answers | `contradiction` | Yes (both providers) | No | Judge model or user clarification |
| Rate Limited | `rate_limited` | No | Yes (with backoff) | None (wait) |
| Auth Failure (App Check) | `auth_failure` | No | No | User must re-authenticate |

---

## User-Facing Copy per Failure Mode

| Mode | User Message |
|------|-------------|
| Provider Error | "We're having trouble reaching our AI service. Trying again..." |
| Timeout | "This is taking longer than expected. Please try again." |
| Safety Refusal | "We couldn't process this image. Please upload a different photo." |
| Quality Gate | "This image looks blurry or too dark. Please take a clearer photo." |
| Low Confidence | "We aren't quite sure what this is. Could you provide more detail?" |
| Contradiction | "Our AI services disagree on this one. Which option looks right to you?" |
| Rate Limited | "You've reached the limit. Please wait a moment and try again." |

---

## Instrumentation Requirements

Every failure event should record:
- `failure_mode`: One of the taxonomy codes above
- `provider`: Which provider was being called
- `duration_ms`: How long before the failure
- `tokens_consumed`: Whether tokens were burned
- `retry_count`: How many retries this attempt has made
- `category_context`: What waste category was being classified (if known)
- `device_tier`: Device tier (affects reliability expectations)

---

## Monitoring & Drift Detection

Build a dashboard that tracks per-provider failure rates by mode over a rolling 24h window:

```
Provider: OpenAI
  timeout_rate: 2.3% (baseline 1.1% — ⚠ elevated)
  parse_failure_rate: 0.8% (normal)
  provider_error_rate: 0.2% (normal)

Provider: Gemini
  timeout_rate: 0.9% (normal)
  safety_refusal_rate: 4.1% (baseline 2.0% — ⚠ elevated, check safety policy drift)
```

Alert thresholds:
- Any failure mode > 2x rolling 7-day average
- Any provider total failure rate > 5%
- Parse failure rate > 2% (indicates prompt/response format drift)

---

## Key Decisions Needed

1. **Token refund policy**: Should low-confidence and parse-failure results be free/refunded tokens?
2. **Retry limits**: What are the max retries per user per session before degrading UX?
3. **Failure severity tiers**: Which failures are P0 (show stopper), P1 (experience degraded), P2 (cosmetic)?
4. **Safety refusal handling**: Should safety-refused images be logged (for moderation analysis) or discarded?

---

## Open Questions

- How do we distinguish provider-side safety refusal from app-initiated content blocking?
- Should users ever see the specific failure code, or always translated copy?
- How do we handle partial failures in multi-object detection (some items classified, some failed)?

---

## Next Steps

1. Update `ai_failure.dart` to use the taxonomy enum above
2. Wire failure events into analytics service
3. Build per-provider failure dashboard
4. Implement auto-retry policies per failure mode
