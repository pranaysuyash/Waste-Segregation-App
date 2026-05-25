# AI Race & Multi-Provider Concurrency

**Purpose**: Explore racing multiple AI providers in parallel vs quality ladder vs failover patterns for classification.
**Status**: Exploration — `analyzeWithRace` already exists as opt-in behind A/B flag
**Last Updated**: 2026-05-25
**Related**: [MULTI_MODEL_AI_ROUTING.md](MULTI_MODEL_AI_ROUTING.md), [AI_COST_TELEMETRY_AND_GUARDRAILS.md](AI_COST_TELEMETRY_AND_GUARDRAILS.md), [BACKEND_CLASSIFICATION_PROXY.md](BACKEND_CLASSIFICATION_PROXY.md)

---

## Problem Statement

The app currently classifies through a single provider path (OpenAI or Gemini, configurable). For latency-sensitive paths, premium users, or retry-after-failure scenarios, racing multiple providers in parallel could improve speed and reliability. But it doubles cost and creates winner-selection challenges.

The question: when should we race, when should we ladder, and when should we just failover?

---

## Concurrency Patterns

| Pattern | Description | Primary Goal | Cost Impact |
|---------|-------------|-------------|-------------|
| **Race** | Hit both providers simultaneously, accept first complete response | Latency (TTFT) | 2-3x (high) |
| **Ladder (Cascade)** | Start cheap/small, escalate if confidence low | Cost/quality balance | Low (optimal) |
| **Failover** | Try primary, switch to secondary only on failure | Reliability | Minimal (failure only) |
| **Best-of-N** | Race both, compare outputs, pick best | Quality | 2x + judge cost |

### Race Mode

- **When it pays off**: Latency-sensitive paths where jitter is unacceptable (real-time scan flow, premium tier SLA)
- **Cost**: 2x tokens consumed for winning request + wasted tokens from losing request (no refunds on most APIs)
- **Winner selection**: Use a judge model (cheap, fast) or logprobs comparison

### Ladder (Quality Ladder)

- **How it works**: Start with on-device model (free) → escalate to cheap cloud → escalate to premium cloud
- **Escalation triggers**: Low confidence, safety-critical category, provider disagreement
- **Cost**: Only pay for what you need — most items handled by cheapest tier
- **Default recommendation**: Ladder is the recommended default for production; race is for special cases only

### Failover

- **How it works**: Primary provider is always preferred; secondary used only when primary errors/timeout
- **Cost**: Nearly identical to single-provider in normal operation
- **Use case**: Reliability-critical paths where redundancy matters more than speed

---

## Winner Selection on Disagreement

When racing produces two different answers:

1. **Confidence comparison**: If both provide confidence scores, pick the higher
2. **Judge model**: Small, fast model evaluates both outputs and selects
3. **Utility heuristic**: If structured output, validate both against schema; accept first that passes
4. **Human-in-loop**: If disagreement is significant and safety-critical, surface both to user

---

## Telemetry Requirements

To optimize the concurrency strategy, collect per-request:
- TTFT delta between winner and loser
- Win rate by provider per input category
- Disagreement frequency and magnitude
- Cost efficiency margin: `(latency_savings / extra_token_cost)`
- Failure rate per provider over rolling 24h window

---

## Key Decisions Needed

1. **Default strategy**: Should the default path be ladder (recommended) or single-provider?
2. **Race eligibility**: Should race mode be premium-only, or available to all users for certain paths?
3. **Provider pairing**: If racing, which pairs? (OpenAI+Gemini, or OpenAI+Anthropic, or variants?)
4. **Cost cap**: What maximum extra cost per user per day is acceptable for race mode?

---

## Open Questions

- Does race mode meaningfully improve user-perceived latency given classification takes 2-5 seconds anyway?
- What happens when both providers return the same wrong answer?
- Should the losing provider's output be saved for eval/analysis?
- How does race mode interact with the backend classification proxy (G4)?

---

## Implementation Paths

1. **Phase 1**: Ladder (on-device → cloud) — already implemented in `ClassificationPipeline`
2. **Phase 2**: Failover (primary → secondary on error) — extend existing error handling
3. **Phase 3**: Race (premium tier only) — extend `analyzeWithRace` with proper cost tracking
4. **Never**: Default race for all users — cost is too high
