# Multi-Sensory Classification

**Status**: Exploration | P2 | Advanced Classification Modalities
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Entry 57
**Last Updated**: 2026-05-25

---

## Why This Matters

Vision alone is ambiguous for many waste items. A white, cylindrical object could be plastic, aluminium, cardboard, or glass. Audio (tap sound), haptics (weight), and user-guided manipulation (bend test) can disambiguate where vision cannot.

Multi-sensory classification also serves a critical accessibility function — blind and low-vision users cannot visually classify items but can interact with them physically. Sound/touch-based material identification makes the app usable for everyone.

---

## Sensor Modalities

### 1. Audio Signatures (Tap Test)

| Material | Sound Signature | Distinguishable? |
|----------|----------------|-----------------|
| Glass | High-pitched chime, sustained ring | Yes — distinctive |
| Metal (aluminum) | Medium-high resonant ring | Yes — distinct from plastic |
| Metal (steel/tin) | Lower metallic ring | Yes |
| Plastic (hard) | Muted thud, low frequency | Distinguishable from metal |
| Plastic (soft) | Very dull, short decay | Distinguishable |
| Paper/cardboard | Dry rustle, no resonance | Distinct |
| Compostable bioplastic | Dull — similar to soft plastic | Harder to distinguish |

**Feasibility**: High. Smartphone microphones can reliably capture spectral footprints of tap sounds. CNN-based audio classification is mature and well-suited for on-device deployment.

**Method**: User taps the object twice on the phone's back (or on a hard surface next to the phone). Microphone captures the impulse response. 1-second clip sufficient for classification.

### 2. Weight Heuristic (Lift Profile)

- **Feasibility**: Moderate. Phone accelerometers measure gravity during lift.
- **Method**: User lifts item with phone in hand → accelerometer records force profile
- **Reliability**: Relative differentiation (aluminum can ~15g vs plastic bottle ~30g vs glass bottle ~200g) is achievable with consistent lift motion
- **Limitation**: Not a gram-scale measurement — works best for clearly different weight classes

### 3. User-Guided Manipulation (Bend/Squeeze)

| Test | What It Reveals | Material Signal |
|------|----------------|-----------------|
| "Bend the edge" | Elasticity, spring-back | Aluminum springs back; paper stays bent |
| "Squeeze the middle" | Crush resistance | Hard plastic resists; soft compresses |
| "Crinkle the corner" | Crinkle sound | Paper/polymer crinkles; metal doesn't |
| "Scratch with fingernail" | Surface hardness | Glass: nothing; plastic: soft mark |

**Feasibility**: Moderate. Best paired with audio capture (crinkle sound). User instructions must be clear and simple.

### 4. Sequential Triage (Bayesian Fusion)

Combining modalities in sequence improves accuracy over any single sensor:

```
Step 1: Vision → "Looks like a white cylindrical container"
          Candidates: plastic bottle, aluminium can, glass bottle, cardboard tube
          
Step 2: Tap test → "Audio matches metal"
          Narrows to: aluminium can
          
Step 3: Bend test → "Edge springs back"
          Confirms: aluminium can
          
Result: Aluminium can (confidence: 0.94)
```

Each ambiguous case becomes an opportunity to involve the user in a guided interaction — which also educates them about material properties.

---

## UX: Guided Interaction Flow

```
"Tap the item twice on a hard surface near your phone"
    [🎤 Listening...]
    ✅ "That sounds like metal or glass"

"Try bending the edge slightly"
    [🔄 Waiting for user action]
    ✅ "It springs back — that's aluminum!"

Result: 🥫 Aluminum can — recyclable in your city
```

**Design principles**:
1. **One interaction at a time** — sequential, not parallel
2. **Clear instructions** — use verbs, not jargon ("tap" not "strike resonance")
3. **Visual demonstration** — show a short animation/gif of the action
4. **No wrong answers** — if the user's action doesn't produce a clear signal, fall back gracefully
5. **Accessibility-first** — all interactions work without visual feedback

---

## Accessibility Impact

| Modality | Benefit for Blind/Low-Vision | 
|----------|------------------------------|
| Audio tap test | Works entirely without vision |
| Bend/crinkle test | Haptic + audio, no vision needed |
| Voice guidance | Assistant narrates each step |
| Lift weight heuristic | Simple, intuitive, no vision |

Multi-sensory classification transforms the app from "show me what you have" to "let me help you figure this out together" — a fundamentally more inclusive interaction model.

---

## Technical Requirements

| Requirement | Level | Notes |
|-------------|-------|-------|
| Microphone access | Always required | For audio-based tests |
| Accelerometer access | Required for weight heuristic | Motion sensors |
| Voice guidance | Text-to-speech | Platform native |
| On-device audio classifier | Small model (< 5MB) | TFLite compatible |
| User interaction UI | Simple step wizard | Minimalist, animation-based |

---

## Integration Points

| Surface | What to Show |
|---------|-------------|
| Scan result — low confidence | "I'm not sure what this is. Can you help me test it?" |
| Accessibility mode | Multi-sensory flow as default for accessibility-enabled users |
| Education | "Learn how to tell materials apart" |
| Gamification | "Material detective" — identify items using touch + sound |

---

## Open Questions

1. **Audio classifier training dataset**: Where do we source labelled tap sounds for each material? Self-collected? Published datasets?
2. **User adoption**: Will users do a multi-step interaction, or is this too much friction for a "quick scan" use case?
3. **Environmental noise**: Will background noise in kitchens, markets, or streets disrupt the audio classifier?
4. **Calibration**: Does the audio classifier need per-device calibration (different mics on different phones)?
5. **Gamification potential**: Could "material detective" mini-games drive adoption of multi-sensory scanning?

---

## Phasing

| Phase | Scope | Key Dependency |
|-------|-------|----------------|
| 0 | Audio tap test for 4 material classes (glass, metal, plastic, paper) | Audio training dataset |
| 1 | Sequential triage — vision + audio combined | Pipeline integration |
| 2 | Bend/crinkle test via audio (user says "done" after action) | Audio action detection |
| 3 | Weight heuristic (lift profile) | Accelerometer data pipeline |
| 4 | Full accessibility mode — all non-visual interactions | Voice guidance + haptics integration |
