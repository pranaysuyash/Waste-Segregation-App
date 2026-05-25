# Home Screen Information Architecture

**Status**: Exploration doc — open research
**Last Updated**: 2026-05-25
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) (A10-N3)
**Related**: [NAVIGATION_IA.md](NAVIGATION_IA.md), [GAMIFICATION_MOMENT_QUALITY.md](GAMIFICATION_MOMENT_QUALITY.md), [REAL_WORLD_IMPACT_PERSONALIZATION.md](REAL_WORLD_IMPACT_PERSONALIZATION.md)

---

## Why This Matters

The home screen currently does four jobs at once — personal greeting, stats dashboard, quick-action launcher, and activity feed. Each has a different mental model and visit frequency.

Stat chips (Points, Tokens, Streak, Days) are engagement metrics, not decision-making inputs. They're most prominent when least useful (first open) and hidden when most relevant (during a session). The `SliverAppBar` collapsing header has already caused visual bugs (excess blank space, greeting truncation at 360dp).

---

## Research Summary

### Dashboard vs Launcher vs Hybrid

| Pattern | Description | Best For | Examples |
|---------|-------------|----------|----------|
| **Dashboard** | Overview of stats, progress, recent activity | Tracking-oriented apps, returning users | Strava feed, banking apps |
| **Launcher** | Minimal chrome, primary CTA prominent | Task-oriented apps, new users | Timer apps, note-taking |
| **Hybrid** (recommended) | Dashboard header + actionable content below | Habit/utility apps | Duolingo path + streak header |

**Recommendation**: Hybrid pattern — dashboard-style header with high-level stats + launcher content below (quick actions, recent scans, challenges).

### Where to Place Engagement Stats

Duolingo's pattern is the industry benchmark: stats pinned at top (streak, gems) but unobtrusive. The primary focus is the learning path below.

**Best practices**:
- Stats should be **secondary**, not primary content
- Use **pills/badges** rather than large counters
- **Pinning** streak info on scroll is helpful — users want streak awareness without interruption
- **Avoid red-state overload** — only use vibrant colors for milestones, use neutral colors for routine display
- **Progressive stats** — show detailed stats only after user has enough data (2+ weeks of activity)

### Progressive Disclosure

| User Stage | Home Screen Content |
|------------|-------------------|
| **New (0 scans)** | Welcome + large scan CTA + minimal interface. Hide stats until first scan. |
| **Early (1-10 scans)** | Simple stat display (scans count, streak). Quick actions prominent. |
| **Active (10-100 scans)** | Full stat chips. Recent scans. Challenge suggestions. Impact preview. |
| **Power user (100+ scans)** | Advanced stats. Trends over time. Community highlights. Premium upgrade prompts (if free). |

### SliverAppBar Design

Current issues:
- `expandedHeight` tuned for specific content height → blank space on smaller devices
- Greeting truncation at 360dp logical width
- Collapsed state shows nothing (`toolbarHeight: 0`)

**Recommendation**:
- **Expanded state**: Greeting + 1-2 primary stats (streak, today's progress) — not all 4 chips
- **Collapsed state (pinned)**: Minimal progress indicator (thin bar) + streak counter pill
- **Elastic overscroll**: Subtle parallax effect on the background header image
- **Responsive**: Wrap stat layout in a `Wrap` widget to avoid overflow at small widths

---

## Proposed Home Screen Layout

```
┌─────────────────────────────────┐
│ [Greeting + Avatar]    [Streak] │  ← SliverAppBar (expanded)
│ ┌────┐ ┌────┐                   │
│ │ 🎯 │ │  ⚡ │                   │  ← 2 primary stats only
│ │Goal│ │Point│                   │
│ └────┘ └────┘                   │
├─────────────────────────────────┤
│ [Scan now — large CTA button]   │  ← Primary action (always visible)
├─────────────────────────────────┤
│ Today's scans (1/3) ———░░░░░░░░░│  ← Daily goal progress bar
├─────────────────────────────────┤
│ Recent Activity                  │
│ ┌─────────────────────────────┐ │
│ │ Plastic Bottle identified   │ │
│ │ 2 min ago · PET             │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ Newspaper — compost bin     │ │
│ │ 15 min ago · Paper          │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ Active Challenge: Zero Waste Wk │  ← Challenges (carousel)
│ [░░░░░░░░░░] 3/7 days          │
├─────────────────────────────────┤
│ [Impact Card] [Community] [Quiz]│  ← Quick actions (horizontal cards)
└─────────────────────────────────┘
```

### Collapsed SliverAppBar State

```
┌─────────────────────────────────┐
│ [=] [Greeting]         🔥 Streak│  ← Only streak survives pin
├─────────────────────────────────┤
│ (regular content continues...)  │
```

---

## Design Principles

1. **Actions over stats** — The primary job of home is to help users scan. Stats support this goal, they don't replace it.
2. **Progressive disclosure** — Don't show advanced data to new users. Reveal depth as the user gains history.
3. **Coalesced celebrations** — Post-session summary (Strava pattern) rather than per-action popups.
4. **Empty states that guide** — "No scans yet? Let's classify your first item" rather than blank screens.
5. **Personalized content** — Show different challenges, impact stats, and suggestions based on archetype and history.

---

## Open Questions

1. Should Home default to the camera for returning users (Google Lens pattern)?
2. Should the scan CTA be a full-width banner, a circular FAB, or a large icon card?
3. How does the Home screen differ for premium vs free users?
4. Should Impact Dashboard be a Home section or its own screen?
5. Should recent activity show classification results or just item names?

---

## Next Steps

1. Reduce stat chips from 4 to 2 primary (streak + daily goal)
2. Add daily goal progress bar below greeting
3. Fix SliverAppBar `expandedHeight` to be dynamic/responsive
4. Add empty state guidance for new users
5. A/B test: launch pad (scan CTA top) vs dashboard (stats top)
