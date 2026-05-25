# Low-Literacy & Multilingual Waste Disposal UX

**Status**: Exploration — pre-design
**Priority**: P2 (🟡)
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Topic #35
**Related docs**: `ACCESSIBILITY_CAMERA_FLOWS.md`, `CROSS_PLATFORM_PARITY.md`, `ONBOARDING_AND_ACTIVATION.md`

---

## Why This Matters

The app serves a user base that spans literacy levels and languages — particularly in India (Kannada, Hindi, Tamil, Telugu, Marathi, Bengali) and emerging markets. Waste disposal is a **functional, safety-critical task** that must be understood regardless of reading ability. A text-only interface for disposal instructions is a failure mode for a significant portion of the target audience.

Three distinct gaps:
1. **Low-literacy users** need icon-first, voice-guided, visual communication — not text-dependent screens.
2. **Multilingual users** expect the app to work seamlessly in their OS language, not just English.
3. **Hazard communication** must be universally understood regardless of language — incorrect disposal of hazardous/medical waste has real consequences.

---

## Key Questions

### Sourcing & Representation
- Which languages are the minimum viable set for an India-first launch (Kannada, Hindi, Tamil, Telugu, Marathi, Bengali, English)?
- Should AI-generated disposal content be translated on-the-fly or pre-curated per language?
- How do we handle language switching mid-session (user changes OS language)?

### Icon-First Communication
- What is the minimum set of universally understood icons for waste categories (organic, plastic, paper, metal, glass, e-waste, hazardous, medical)?
- Do ISO waste symbols translate cross-culturally, or do they need local adaptation?
- How do we communicate nuanced instructions (rinse before disposing, remove labels) without text?

### Voice & Audio
- Should the app speak disposal instructions aloud after each scan (auto-play vs tap-to-play)?
- What languages support TTS on the target device range?
- How do voice instructions degrade when the phone is on silent / in quiet mode?

### Hazard Safety
- How do we ensure hazard warnings are unmistakable regardless of language: red backgrounds, pulsing icons, haptic alarms?
- Do we need a separate "emergency mode" for hazardous items that overrides sound/vibration settings?

---

## Research Findings

### 1. Icon-First Design Principles for Low-Literacy

UPI/payments apps in India (PhonePe, GPay) demonstrate effective patterns:
- **Recognition over recall**: Consistent, familiar icons across the app — users learn one visual vocabulary.
- **Hyper-real 3D icons** work better than abstract symbols for item identification (photo of a plastic bottle vs generic "container" icon).
- **One-task-per-screen**: Linear flow with clear visual progression — no multi-column menus.
- **Color coding** reinforced by bin color (green for wet, blue for dry, red for hazardous, black for reject).

For waste disposal, this means:
- Disposal instructions should be primarily visual: "this item → that bin" with a photo of the item and a photo/icon of the bin matched to the city's actual bin colors.
- Action buttons should be large, color-coded, and sit at the bottom of the screen (thumb zone).
- Confirmation should be visual + haptic — a green flash + vibration rather than "Item classified successfully" text.

### 2. Multilingual Architecture

- **OS-level language detection** is the baseline — respect the device language setting.
- **Per-session language override** in settings for users who want a different language than their OS.
- **Translation strategy**: For AI-generated content (disposal advice, educational blurbs), translate on-the-fly using the cloud AI provider's response language parameter. For curated content (hazard warnings, city rules, common items), pre-translate and store in Firestore.
- **Voice output**: Use device TTS engines (Android has strong Kannada/Hindi/Tamil support via Google TTS). Fall back to pre-recorded audio clips for safety-critical instructions where TTS quality is poor.
- **Right-to-left languages**: Arabic support may be needed for Gulf market expansion — verify Flutter's RTL support.

### 3. Voice-First Patterns

- **Auto-play**: After classification, the app speaks the disposal instruction aloud. User can tap to replay.
- **"Ask me" mode**: User says "What is this?" in their language → app classifies and responds via voice.
- **Earcons**: Distinct audio cues for each waste category (crumpling paper sound for paper, glass clink for glass, etc.) — reinforces category without language.
- **Hazard override**: If the item is hazardous/medical, the app speaks the hazard warning first, then the disposal instruction.

### 4. Hazard Communication That Crosses Languages

Universal hazard communication patterns:
- **Red background + pulsing border** for hazardous items — works regardless of literacy.
- **ISO hazard symbol** displayed prominently (skull for toxic, flame for flammable, biohazard for medical).
- **Three-tier alert system**:
  - **Level 1 (Informational)**: Green — safe disposal, no special handling.
  - **Level 2 (Caution)**: Yellow/amber — special handling needed (e-waste, aerosol).
  - **Level 3 (Warning)**: Red with haptic pulse — hazardous/medical. Must not be ignored.
- **Haptic signatures**: Assign distinct vibration patterns to each category (3 short pulses for hazardous, continuous buzz for medical).

### 5. Bin Color Mapping Across Cities

Not all cities use the same bin color system. The app must map disposal advice to the *user's local* bin colors:
- **Bangalore (BBMP)**: Green (wet), Blue (dry), Red (reject), Separate (hazardous/medical).
- **Mumbai (BMC)**: Green (wet), Blue (dry), Red (hazardous), White (reject).
- **Delhi (MCD)**: Green (biodegradable), Blue (non-biodegradable), Red (hazardous), Black (reject).

The result screen should show the bin color that matches the user's configured city, not a generic color.

---

## Design Patterns for Implementation

### Pattern 1: Icon-First Disposal Card
```
┌───────────────────────────┐
│  [Item Photo]             │
│                           │
│  PLÁSTICO                 │  ← Language-aware label
│                           │
│  [Green Bin Icon]         │  ← City-matched bin color
│  Put in Wet Waste         │  ← Text (can be translated)
│                           │
│  [🔊] [📋] [↻]            │  ← Voice, details, correct
└───────────────────────────┘
```

### Pattern 2: Hazard Overlay
```
┌───────────────────────────┐
│ ⚠️ [HAZARD SYMBOL] ⚠️   │  ← Pulsing red overlay
│                           │
│  HA-ZAR-DOUS              │  ← Spoken aloud, bold text
│                           │
│  Do NOT put in            │
│  regular bin              │
│                           │
│  [Where to dispose]       │  ← Large, high-contrast button
└───────────────────────────┘
```

### Pattern 3: Quick-Language Switcher
- A persistent language pill at the top of the result screen (e.g., "English ▾")
- Tapping shows 3-5 most-common languages for this user's region
- Change is immediate and persists for the session

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why |
|---|---|
| Small text-heavy buttons | Unusable for low-literacy users; inaccessible on small screens |
| Machine-translated only without review | Incorrect hazard translations create safety risk |
| Color-only communication | Colorblind users (8-10% of male population) miss critical info |
| Audio-only for hazard warnings | User may have phone on silent; must have redundant visual warning |
| Western imagery (green bin = paper) | Indian bin colors differ by city — must be localized |

---

## Open Questions

1. **TTS quality in regional languages**: How good is Google TTS for Kannada waste-specific vocabulary? Should we pre-record audio for safety-critical instructions?
2. **Icon testing**: Do ISOsymbols (biohazard, toxic, flammable) need local contextualization for Indian users?
3. **Low-literacy onboarding**: Should the first-run experience offer a purely visual mode (no text at all)?
4. **Language coverage**: What's the cost/benefit trade-off for adding additional languages beyond the top 6 Indian languages?
5. **Voice input**: When should we invest in voice Q&A (user asks "what is this?" in their language) vs text-only classification?

---

## Next Steps

1. Conduct icon comprehension testing with ~20 users across literacy levels and languages.
2. Prototype the icon-first disposal card and test with low-literacy users.
3. Audit current result screen for text-dependent elements — identify minimum changes for icon-first fallback.
4. Map bin colors per existing city plugins and add `binColor` to `CityPolicyData`.
5. Research TTS quality in target languages — identify pre-recording needs for hazard warnings.
