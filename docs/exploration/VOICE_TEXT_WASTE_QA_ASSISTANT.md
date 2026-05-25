# Voice/Text Waste Q&A Assistant

**Status**: Exploration | P2 | Advanced Classification Modalities
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Entry 56
**Last Updated**: 2026-05-25

---

## Why This Matters

Not every waste query starts with a photo. Users standing at a bin with an unlabelled item, wondering what to search online, or asking "how do I dispose of old paint?" — these are text-first interactions. A Q&A assistant answers these queries using local rules and the app's knowledge base, without requiring the full scan pipeline.

This also serves as the **fallback path** when the camera can't get a clear image — "I'm having trouble seeing this — could you describe it instead?"

---

## Core Architecture

```
User input (text or voice)
    │
    ▼
Intent classifier
├── "What do I do with X?" → Material lookup + local rules
├── "Where can I recycle X?" → Facility search
├── "Is X recyclable?" → Policy lookup + local rules
├── [Ambiguous] → Clarify (working vs broken? full vs empty?)
└── [Unknown] → "I'm not sure — here are resources to help"
    │
    ▼
RAG over local policy rules + facility DB + waste knowledge base
    │
    ▼
Grounded response with citations + follow-up suggestions
```

---

## Key Design Decisions

### 1. Grounding in Local Rules

The assistant MUST be grounded in the user's local rules corpus. A generic answer ("put it in the blue bin") is dangerous if the user's city doesn't accept that material.

**Architecture**: RAG (Retrieval-Augmented Generation) over the region-specific policy ruleset. The retrieval step is scoped by the user's active city or GPS location.

### 2. Ambiguity Resolution

Many common queries are ambiguous:

| Query | Ambiguity | Clarification |
|-------|-----------|---------------|
| "What do I do with old batteries?" | Single-use vs rechargeable vs lithium | "Are these AA/AAA, phone batteries, or car batteries?" |
| "How do I dispose of an old phone?" | Working vs broken | "Is the phone still functional or is it broken?" |
| "Can I recycle pizza boxes?" | Clean vs greasy | "Is the box clean cardboard or does it have food/grease on it?" |
| "What about plastic bags?" | Plastic bags are often recyclable but NOT in curbside bins | "Plastic bags: they can be recycled at grocery store drop-offs, but NOT in your home recycling bin." |

**Clarification rule**: Maximum one follow-up question before escalation ("Would you like to scan a photo instead?").

### 3. Answer Sources

| Source | Authority | When Used |
|--------|-----------|-----------|
| Local policy engine (own rules corpus) | High | Primary — city-specific |
| Product DB (e.g., Open Food Facts) | Medium | Barcode-linked items |
| Verified facility data | High | "Where to take it" queries |
| LLM general knowledge | Low | Fallback only — with disclaimer |
| User corrections (aggregated) | Medium | "Others in your area also asked..." |

### 4. Safety Guardrails

- **Must-not categories** (batteries, chemicals, sharps, medical waste) — always escalate to authoritative source (municipal helpline or verified facility), never give casual advice
- **Consent note**: "This answer is based on [City Name] rules as of [Date]. Rules may change. Verify with your local authority for the most up-to-date guidance."
- **No medical/disposal-as-treatment advice**: "We don't provide guidance on disposing of medical waste. Please contact your municipal health department."

---

## Voice Input

- **Input**: Speech-to-text (Google Speech / iOS Speech) → same NLP pipeline as text
- **Output**: Text-to-speech reading of the answer, with link/facility info sent to chat for reference
- **Multilingual**: Kannada, Hindi, Tamil, Marathi, English for Indian market
- **Hinglish support**: Handle code-mixed queries ("old phone kaise dispose karein?")

---

## Integration Points

| Surface | What to Show |
|---------|-------------|
| Scan result — low confidence vision | "I'm unsure. Can you describe what you see?" → Switch to Q&A |
| Home screen | Search bar: "Ask about any waste item..." |
| Disposal guidance fallback | "Need more detail? Ask me about any item" |
| Voice shortcut | Microphone button on home + scan screens |
| Community tab | "Others asked about... " — trending questions |

---

## Competitive References

- **San Francisco Recology "Waste Wizard"**: City-specific, searchable, well-maintained. The gold standard for municipal waste Q&A.
- **Yuka text search**: Searches product DB for barcode-linked info. Not city-specific.
- **Google Search**: Not grounded in local rules — often gives conflicting generic advice.
- **Municipal WhatsApp chatbots (India)**: Some cities (Indore, Pune) use WhatsApp-based waste Q&A bots. Good UX precedent.

---

## Open Questions

1. **Multilingual coverage**: Can we achieve parity across Kannada, Hindi, Tamil, Bengali, Marathi, and English?
2. **Voice accuracy**: How well does speech-to-text perform for city-specific waste terms (e.g., "kabadiwala", "BBMP", specific bin colours)?
3. **Grounding eval**: How do we measure whether the RAG system is returning city-accurate answers vs generic LLM hallucinations?
4. **Content maintenance**: What's the refresh cadence for the rules corpus that feeds the RAG system?

---

## Phasing

| Phase | Scope | Key Dependency |
|-------|-------|----------------|
| 0 | Text Q&A over existing local policy rules + facility DB | Local policy engine |
| 1 | Voice input (speech-to-text) | Speech recognition integration |
| 2 | Multilingual support | Translation pipeline |
| 3 | "Describe instead of photo" fallback in scan pipeline | Classification pipeline integration |
| 4 | Trending questions / common queries dashboard | Analytics |
