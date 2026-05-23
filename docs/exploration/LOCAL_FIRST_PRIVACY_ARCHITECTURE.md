# Local-First Privacy Architecture

**Date**: 2026-05-23
**Status**: Exploration — privacy-by-layer architecture
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) G2
**Decision this unblocks**: Privacy-conscious users, school/classroom mode, GDPR-safe default
**Kill criteria**: If on-device inference never achieves acceptable quality, the privacy architecture has no Layer 1 to stand on

---

## 1. Privacy by Layer

The 4-layer cascade creates a natural privacy spectrum:

| Layer | Image Transmission | Third-Party Exposure | Privacy Level |
|-------|-------------------|---------------------|---------------|
| Layer 0 (deterministic) | None — all computation on-device | Zero | Full privacy |
| Layer 1 (on-device VLM) | None — model runs locally | Zero | Full privacy |
| Layer 2 (cloud cheap) | Image bytes → OpenAI or Google | Provider ToS | Provider-dependent |
| Layer 3 (cloud strong) | Image bytes → OpenAI or Google | Provider ToS | Provider-dependent |
| Layer 4 (disposal reasoning) | Text only → Firebase backend | Minimal | High (no image) |

### Key insight

Routing policy IS privacy policy. The layer that handles each classification determines what happens to the user's image.

---

## 2. Privacy Modes

### Mode 1: Default (balanced)

All layers available. Escalate as needed. User sees per-classification privacy indicator.

```
Layer 0 → Layer 1 → Layer 2 → Layer 3
```

### Mode 2: Local-only (privacy-first)

Only Layer 0 + Layer 1. Refuse to escalate. If local can't classify, show "Not available offline."

```
Layer 0 → Layer 1 → "Cannot classify locally"
```

Target users: schools, corporate BYOD, GDPR-sensitive users, kids mode.

### Mode 3: Cloud-only (accuracy-first)

Skip local layers entirely. Always use cloud.

```
Layer 2 → Layer 3
```

Target users: premium, enterprise, accuracy-critical scenarios.

---

## 3. Per-Classification Privacy Signal

Every classification result should display a privacy indicator:

| Indicator | Meaning | UI |
|-----------|---------|-----|
| Shield icon (green) | Classified on-device, no image transmitted | Badge on result screen |
| Shield icon (amber) | Classified in cloud, image sent to provider | Badge with provider name |
| Shield icon (blue) | Offline classification, queued for cloud verification | Badge with sync icon |

### Implementation

Add `privacyLevel` field to `WasteClassification`:

```dart
enum ClassificationPrivacy {
  localOnly,      // Layer 0 or Layer 1
  cloudAnalyzed,  // Layer 2 or Layer 3
  offlinePending, // Queued for cloud
}
```

Set during classification pipeline based on which layer accepted.

---

## 4. Consent Flow

### Before first cloud classification

Show consent dialog:
> "This item couldn't be classified on your device. To get an accurate result, your photo will be sent to [OpenAI/Google] for analysis. Your image is processed according to their privacy policy."
>
> [Always allow cloud] [Just this once] [Keep local]

### User choice persistence

- `alwaysAllowCloud`: skip future prompts
- `alwaysLocalOnly`: never escalate, refuse cloud
- `askEveryTime`: prompt each time

### Revocation

User can change this preference in Settings → Privacy at any time.

---

## 5. What's Possible Now vs. Blocked

### Now (Layer 0 exists)

- Deterministic classification is fully private (barcode + color histogram)
- Privacy signal already possible for Layer 0 classifications
- Consent flow for cloud escalation can be built
- `local-only` mode works for items Layer 0 accepts (~30% of cases)

### Blocked (needs Layer 1)

- True local-only mode for all items requires on-device VLM
- Privacy-first mode only covers ~30% of cases without Layer 1
- Face detection/blur capability comes with on-device ML framework

---

## 6. Data Flow Diagram

```
┌─────────────┐    ┌──────────────┐    ┌──────────────┐
│ Camera      │───▶│ Layer 0      │───▶│ Layer 1      │
│ Image       │    │ Deterministic│    │ On-Device VLM│
│             │    │ (local only) │    │ (local only) │
└─────────────┘    └──────┬───────┘    └──────┬───────┘
                          │ confident          │ confident
                          ▼                    ▼
                   ┌────────────────────────────────┐
                   │       Result (local only)       │
                   │  Privacy: localOnly             │
                   │  No image leaves device         │
                   └────────────────────────────────┘
                          │ not confident        │ not confident
                          ▼                      ▼
                   ┌─────────────┐    ┌──────────────┐
                   │ Check user  │    │ Layer 2/3    │
                   │ privacy     │    │ Cloud        │
                   │ preference  │    │ OpenAI/Google│
                   └──────┬──────┘    └──────┬───────┘
                          │                   │
              ┌───────────┴───────┐   ┌───────┴────────┐
              │ local-only: refuse│   │ Result (cloud) │
              │ "Cannot classify  │   │ Privacy: cloud │
              │  locally"         │   │ Image sent to  │
              └───────────────────┘   │ provider       │
                                      └────────────────┘
```

---

## 7. Related

- [Privacy / Photo PII](PRIVACY_PHOTO_PII.md) — PII protection mechanisms
- [Multi-Model AI Routing](MULTI_MODEL_AI_ROUTING.md) — routing architecture
- [On-Device Inference](../EXPLORATION_TOPICS.md#6-on-device-inference-) — Layer 1 implementation
- `docs/review/LOCAL_FIRST_VLM_AI_ROADMAP_2026-05-21.md` — 4-layer cascade architecture
