# Virtual Garden, Avatar & Mascot System

**Status**: Draft — no code surface for virtual garden or mascot exists yet.
**Priority**: P2 (delight/retention feature, not core utility)
**Related**: [GAMIFICATION_DEPTH.md](GAMIFICATION_DEPTH.md), [MOTIVATION_ARCHETYPES.md](MOTIVATION_ARCHETYPES.md), [POINTS_ECONOMY_V2.md](POINTS_ECONOMY_V2.md)
**Last Updated**: 2026-05-25

---

## Why This Is a Topic

A virtual garden or mascot system serves as **progress embodiment** — making abstract sustainability actions feel tangible and personal:

1. **Emotional connection** — a growing garden or a learning mascot creates attachment that streaks and points alone cannot.
2. **Non-competitive progress** — not everyone responds to leaderboards. Garden growth is personal, intrinsic, and cooperative with the environment.
3. **Token sink** — cosmetic items (garden decorations, mascot outfits) are a healthy token sink that doesn't affect gameplay.
4. **Education vehicle** — the garden can teach ecological concepts (biodiversity, composting, nutrient cycles) through its growth.

---

## Concept Options

### Option A: Virtual Garden (Recommended)

A garden that grows as the user sorts waste correctly.

- **Growth triggers**:
  - Correctly sorted item → seed sprouts → grows into a plant
  - Streak milestones → special flowers bloom
  - Hazardous items correctly sorted → "guardian plant" appears
  - Community participation → pollinator flowers for cross-pollination
  - Quizzes completed → fruit-bearing plants
- **Degradation**:
  - Incorrect sorting → weeds appear (but garden doesn't die — non-punitive)
  - Inactivity → garden becomes dormant (can be revived with one scan)
  - Contamination streak → mushrooms/ferns (neutral, interesting aesthetic)
- **Seasons**: garden changes with real seasons (monsoon lush, autumn colours, winter sparse)
- **Real-world tie-in**: at major milestones, a real tree is planted (optional, with partner)

### Option B: Learning Mascot

A companion animal that evolves as the user learns.

- **Growth triggers**:
  - Correct classifications → mascot gains knowledge/skills
  - Learning milestones (quizzes, corrections) → mascot evolves appearance
  - Streak milestones → mascot learns new tricks/animations
- **Personality**: mascot reacts to user's actions — happy for correct sort, curious when user asks a question, proud when user teaches someone else.
- **Evolution path**: baby → adolescent → adult → elder sage. Each stage unlocks new interactions.

### Option C: Minimal — Progress Forest

A simple collection of trees. Each tree is a discrete unit representing a block of classifications.

- No animation, no mascot interaction.
- Minimal performance cost.
- Works as a background or periodic unlock.

### Recommendation

Start with **Option A (Virtual Garden)** because:
1. Gardens are culturally universal (Indian, European, East Asian aesthetics all work).
2. Gardens naturally teach ecological concepts.
3. Space for expansion to mascot (a garden creature can be added later).
4. Non-punitive design (weeds instead of death) is healthier for a sustainability app.

---

## Growth Mechanics

### Seed → Sprout → Bloom

| Stage | Trigger | Visual |
|-------|---------|--------|
| **Seed** | User classifies first item | Small seed in soil |
| **Sprout** | 10 correct classifications | Tiny green sprout |
| **Growing** | 50 correct classifications | Small plant with leaves |
| **Bloom** | 100 correct classifications | First flower bloom |
| **Flourishing** | 500 correct classifications | Full plant with multiple blooms |
| **Ecosystem** | 1000+ correct classifications | Small ecosystem with fauna |

### Special Events

| Event | Visual |
|-------|--------|
| 7-day streak | Rainbow glow on one plant |
| 30-day streak | Seasonal bloom burst |
| First hazardous item correctly sorted | Cactus/spiky plant (guardian) |
| First community share | Pollinator butterfly appears |
| First quiz completed | Fruit appears on tree |
| 100 items in one category | Category-themed plant (e.g., "Plastic Palm") |

### Degradation (Non-Punitive)

| Condition | Effect |
|-----------|--------|
| 7 days inactive | Leaves droop slightly |
| 14 days inactive | Garden goes dormant (grey tint, no animation) |
| 30 days inactive | Overgrown with moss/ivy (aesthetic change, still beautiful) |
| After reactivation | One scan returns garden to full health |

**Philosophy**: The garden never dies. It changes state but is always welcoming. This keeps the experience positive for users who take breaks.

---

## Visual Style

### Design Direction

- **2D illustration**, not 3D (lower performance cost, more expressive).
- **Stylized, not realistic** — vector art with warm colors.
- **Indian inspiration**: native plants (tulsi, neem, marigold, jasmine) for cultural relevance.
- **Dark mode variant**: moonlight garden with glowing elements.

### Target Performance

- Lottie (JSON) animations for all flora.
- Static garden when not actively viewed (minimal battery impact).
- < 2MB asset bundle for initial garden.

---

## Implementation Architecture

### Data Model (Firestore)

```
users/{userId}/garden/
  ├── state: "dormant" | "active" | "flourishing"
  ├── plants: [
  │     { id, type, stage, plantedAt, lastWateredAt, milestones: [...] }
  │   ]
  ├── decorations: [
  │     { id, type, slot, unlockedAt }
  │   ]
  ├── totalGrowthContributions: 0
  └── lastActivityAt: timestamp
```

### Growth Computation

Growth is computed from classification history queries (not real-time, for performance):

```
growth_score = sum(classification_events[last_30_days].weight)
where weight = 1 for correct sort, 0.5 for low-confidence, 0 for incorrect
```

Plants are spawned every N growth points. The max plant count caps garden density (e.g., 20 plants).

### Client Rendering

- Flutter CustomPainter or Lottie for animated elements.
- Garden is rendered as a scrollable landscape with parallax (depth effect).
- Plants are positioned semi-randomly within a bounded "garden box."
- Tapping a plant shows a fun fact: "This Tulsi was planted when you sorted your 100th item!"

---

## Token Sink Integration

| Item | Token Cost | Effect |
|------|-----------|--------|
| Garden bench | 50 tokens | Decoration — resting point for mascot |
| Bird bath | 75 tokens | Attracts virtual birds |
| Rare flower seed | 30 tokens | Special bloom not achievable by progress alone |
| Mascot outfit | 100 tokens | Changes mascot appearance |
| Seasonal theme | 150 tokens | Monsoon, winter, festival, night theme |
| Garden expansion | 200 tokens | Wider/layered garden area |
| Tree planting dedicated | 500 tokens | App plants a real tree (if partnership exists) |

All items are strictly cosmetic. No gameplay advantage.

---

## Mascot (Phase 2)

### Concept

A garden sprite/creature that lives in the garden and interacts with it:

- **Appearance**: small, friendly, animal-like (garden gnome, squirrel, or bird — Indian-appropriate like a sparrow or mongoose).
- **Behaviour**: wanders garden, reacts to user actions (waves for correct sort, looks curious for low confidence).
- **Interaction**: tap to pet → heart animation. Tap while sorting → encouragement animation.
- **Customization**: hats, scarves, accessories (paid — token sink).

### Mascot vs Garden Interaction

- When user sorts correctly: mascot waters plants.
- When user completes streak: mascot does a happy dance.
- When user is inactive: mascot sits on bench, looking peaceful (not sad — never guilt-tripping).
- When user corrects a mistake: mascot gives a thumbs-up.

### Performance

- Mascot uses a single Lottie animation set (~200KB).
- Mascot is idle 90% of the time (single frame rendering).
- Only active when garden screen is open.

---

## Open Questions

1. **Should the garden be visible to others?** (family members, community). Proposal: optional. User can choose to show garden on profile. Garden status is "flourishing" or "dormant" — not plant-by-plant detail.
2. **Should there be a houseplant version for privacy-conscious users?** Some users may not want to reveal activity patterns through garden health. Proposal: "privacy mode" where garden always looks healthy regardless of actual activity.
3. **Real-life planting partnership**: any plan to partner with tree-planting organizations? Proposal: Phase 3 feature. Requires trust, verification, and per-tree cost budget. But high-value for Eco Wrapped and social sharing.
4. **Offline garden growth**: proposals — growth is calculated from local classification history and synced. Garden state is determined server-side.

---

## Related Work

- [GAMIFICATION_DEPTH.md](GAMIFICATION_DEPTH.md) — gamification foundations that garden supports
- [MOTIVATION_ARCHETYPES.md](MOTIVATION_ARCHETYPES.md) — garden appeals to "Nurturer" and "Explorer" archetypes specifically
- [POINTS_ECONOMY_V2.md](POINTS_ECONOMY_V2.md) — token sink design that garden cosmetic items are part of
- [ECO_WRAPPED_ANNUAL_IMPACT_STORY.md](ECO_WRAPPED_ANNUAL_IMPACT_STORY.md) — annual impact story can reference garden milestones
