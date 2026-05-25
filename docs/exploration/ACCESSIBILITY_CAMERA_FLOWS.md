# Accessibility for Camera & Classification Flows

**Status**: Exploration — pre-audit
**Priority**: P2 (🟡)
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Topic #36
**Related docs**: `LOW_LITERACY_MULTILINGUAL_UX.md`, `SCAN_CENTRIC_UX_PATTERNS.md`, `VOICE_TEXT_WASTE_QA.md`

---

## Why This Matters

The app is camera-first by design — the primary interaction is pointing a phone at waste and receiving a classification result. For users with visual impairments, motor disabilities, or situational impairments (holding waste, low light, single-hand operation), this flow can range from difficult to impossible.

Accessibility is not just an ethics concern — it's a **market reach** concern. In India, an estimated 40-50 million people live with some form of disability. Accessibility compliance is increasingly a store review requirement (iOS WCAG, Android accessibility guide).

---

## Key Questions

### Visual Impairments
- How do blind and low-vision users frame a waste item correctly in the camera viewfinder?
- What audio/haptic feedback signals guide the user to center the item?
- How do screen readers (TalkBack, VoiceOver) interact with live camera viewfinders?
- How should classification results be conveyed non-visually?

### Motor & Dexterity
- Users holding waste in one hand need one-hand operation for the entire scan flow.
- What's the right tap target size for a one-hand scan action?
- How do users with tremors or limited fine motor control capture a steady image?

### Situational Impairments
- Low light, glare, motion (while walking), noisy environments, wearing gloves.
- These are the most common accessibility failures — and the hardest to simulate in testing.

### Hearing Impairments
- Any audio-only feedback (haptic alerts, voice instructions) must have a visual equivalent.
- Captioning for video content.

---

## Research Findings

### 1. Guided Camera Framing Patterns

Industry leaders (Seeing AI by Microsoft, Lookout by Google, Google Pixel Guided Frame):
- **Audio beacons**: Increasing-frequency beeps as the object moves toward center of frame. Left/right panning audio indicates direction.
- **"Geiger counter" metaphor**: Faster ticks = closer to center. Continuous tone = centered.
- **Proximity guidance**: "Move closer" / "Move away" spoken guidance when object is too far or too close.
- **Auto-capture**: When the object is centered and stable, auto-capture rather than requiring a tap.
- **Text detection**: Announce when text/QR code is detected in frame — "Barcode found. Scanning..."

For waste classification specifically:
- The app needs to distinguish "item centered" from "item in frame but poorly positioned."
- Guidance should indicate *what type of item* is being framed (single vs multi-object, hazmat symbol detected).

### 2. Haptic Feedback Signatures

| Event | Haptic Pattern | Notes |
|---|---|---|
| Object detected in frame | Short, light buzz | Confirms camera is seeing something |
| Object centered | Medium tap | "Ready to scan" |
| Auto-capture triggered | Double pulse | Success — image captured |
| Classification success | Single crisp tick | High-frequency vibration |
| Classification ambiguous | Low pulsing buzz | "Not sure — waiting for more info" |
| Hazard detected | Continuous heavy vibration | Must not be ignorable |
| Error / network failure | Three short buzzes | Try again or queue |

**Key principle**: Haptic patterns must be *distinguishable by touch alone*. Don't use the same vibration for success and failure.

### 3. Screen Reader (TalkBack/VoiceOver) Patterns

Live camera viewfinders are notoriously difficult for screen readers because the visual content changes constantly.

**What works**:
- **Static state labels**: Announce current mode/status ("Camera ready", "Scanning for objects", "Object found, analyzing").
- **Action accessibility labels**: Every button must have a descriptive label ("Take photo", "Switch camera", "View result").
- **Result announcements**: When classification completes, screen reader should auto-announce the result ("Classification complete: Plastic bottle. Put in blue recycling bin.").
- **Gesture navigation**: Support for TalkBack/VoiceOver gestures to navigate result screens.

**What doesn't work**:
- Attempting to narrate every frame change (causes audio overload).
- Relying on the screen reader to interpret visual elements in the viewfinder.
- Using non-standard gestures that conflict with screen reader activation methods.

### 4. One-Hand Operation Patterns

For users carrying waste in one hand:
- **Full-screen tap target**: The entire viewfinder area acts as a shutter button (tap anywhere to capture).
- **Bottom-mounted controls**: All non-camera UI (settings, flash toggle, language switch) in the bottom thumb zone.
- **Auto-capture priority**: Don't require a tap if the object is well-framed — auto-capture after 1-second stable frame.
- **Quick re-scan**: After result, a large "Scan another" button at the bottom — no need to navigate back to camera.

### 5. High Contrast & Dynamic Type

| Element | Minimum Standard |
|---|---|
| Text contrast ratio | 4.5:1 (WCAG AA) for body text, 3:1 for large text |
| Button contrast | 3:1 against background |
| Color independence | Classification must use icon + text + pattern — never color alone |
| Dynamic type | All result screens must respect system font size settings |
| Spacing | Minimum 48dp touch targets; generous padding between interactive elements |

### 6. Hearing Impairment Patterns

- **Visual alerts**: Audio hazard warnings must have a visual equivalent (pulsing red screen, flashing icon).
- **Captioning**: Any video/audio educational content must have captions.
- **Vibration for audio confirmation**: If the app plays a sound on classification success, provide a haptic confirmation too.
- **No audio dependency**: Classification result and disposal instructions must be readable on screen — not audio-only.

---

## Current Accessibility Assessment

Based on review of current code:

| Area | Status | Gap |
|---|---|---|
| **Camera viewfinder** | No audio guidance | Blind users cannot center items |
| **Result screen** | Screen reader labels unknown | Needs accessibility audit |
| **Haptic feedback** | Not implemented | No vibration patterns for scan events |
| **High contrast mode** | Not verified | Unknown if WCAG AA compliant |
| **Dynamic type** | Not verified | Unknown if text scales correctly |
| **One-hand operation** | Tap target sizes unknown | May be too small in some screens |
| **Color independence** | Partial risk | Bin recommendations may rely on color alone |

---

## Implementation Recommendations

### Phase 1 (Minimum Viable Accessibility)
1. Add accessibility labels to all interactive elements (buttons, icons, links) for TalkBack/VoiceOver.
2. Ensure color is never the sole indicator of a classification category or disposal instruction.
3. Support system font size settings (Dynamic Type / Accessibility Scaling).
4. Add haptic feedback for scan events (success, failure, hazard).

### Phase 2 (Guided Experience)
5. Implement audio guidance for camera framing (spatial audio + beep frequency).
6. Add auto-capture when object is centered and stable.
7. Support one-hand capture mode (full-screen tap target).
8. Add screen reader announcements for classification results.

### Phase 3 (Complete Coverage)
9. Voice-controlled scan flow ("take photo", "scan again").
10. Situational impairment modes (glove mode, low-vision mode, one-hand mode).
11. Accessibility testing with real users across impairment categories.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why |
|---|---|
| Color-only indicators for bin categories | 8-10% of male users have color vision deficiency |
| Small touch targets near viewfinder edge | Users with tremors cannot reliably tap small targets |
| Non-standard gestures | Conflicts with TalkBack/VoiceOver navigation |
| Audio-only hazard warnings | User may have phone on silent; must have visual equivalent |
| Dismissable accessibility mode | Users who need it may not know how to re-enable |
| Relying on one-handed mode only at bottom | Left-handed vs right-handed vs holding item specific needs |

---

## Metrics to Track

- **Scan success rate by impairment group** (do we know how many of our users have accessibility needs?)
- **Time from camera open to capture** — if it takes much longer for screen reader users, the guidance is insufficient.
- **Correction rate by group** — if blind users correct more often, the result screen is not accessible.
- **Hazard verbatim** — for hazardous items, is the warning reaching the user regardless of impairment?

---

## Open Questions

1. What is the minimum Android/iOS version that supports good-enough TTS for audio guidance?
2. Should accessibility features be discoverable at onboarding ("Enable one-hand mode?") or only in settings?
3. How do we test accessibility on the target device range (₹10,000-₹20,000 Android phones)?
4. Should we invest in a separate "accessibility mode" UI or integrate accessibility into the main UI?
5. What accessibility testing tools are available for Flutter (accessibility scanner, automated audit)?

---

## Next Steps

1. Run accessibility scan on current app using Flutter's accessibility tools.
2. Audit all result screen elements for screen reader readiness.
3. Prototype haptic feedback for scan events and test with 3-5 visually impaired users.
4. Define minimum viable accessibility checklist for launch.
5. Research Indian-language TTS quality for audio guidance (Kannada, Hindi, Tamil).
