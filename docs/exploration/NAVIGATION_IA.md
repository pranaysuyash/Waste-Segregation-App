# Navigation Information Architecture

**Status**: Exploration doc — open research
**Last Updated**: 2026-05-25
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) (A10-N1)
**Related**: [HOME_SCREEN_IA.md](HOME_SCREEN_IA.md), [SCAN_CENTRIC_UX_PATTERNS.md](SCAN_CENTRIC_UX_PATTERNS.md), [ONBOARDING_AND_ACTIVATION.md](ONBOARDING_AND_ACTIVATION.md)

---

## Why This Matters

The app is scan-centric but the Scan tab sits at position 2 with no persistent FAB pattern. Settings is hidden behind a header icon on Home only. The Social screen uses an in-screen FAB toggle for Community/Family sub-views — fragile on small screens.

As the app grows, the 5-tab structure may not accommodate new contexts (local guidelines, disposal locations, partner programs) without tab proliferation.

---

## Research Summary

### How Scan-Centric Apps Navigate

| App | Tabs | Scan CTA | Settings |
|-----|------|----------|----------|
| **Yuka** | 4 (Home, Scan, Search, Profile) | Center tab (distinct icon) | Profile page gear icon |
| **PictureThis** | 4 (Home, Identify, Community, Profile) | Center tab (camera icon, elevated) | Profile page |
| **Google Lens** | 3 (Search, Lens, Translate) | Center tab | Avatar→Settings |
| **FoodKeeper** | 3 (Search, Browse, Settings) | Home screen CTA | Settings tab |
| **Too Good To Go** | 4 (Discover, Favorites, Orders, Profile) | Surprise bags CTAs on tabs | Profile → gear |

**Key pattern**: Scan-centric apps use **3-4 tabs** with the scan action as a **prominent center element**, not a floating overlay.

### Scan CTA: FAB vs Dedicated Tab

**FAB approach**:
- Pros: Always accessible, persistent across all screens, Material Design native
- Cons: Overlaps content, feels like an overlay, can interfere with gesture navigation on iOS

**Dedicated center tab** (recommended):
- Pros: Treats scan as a core app mode, consistent hit target, native navigation pattern
- Cons: Requires switching away from current screen (minor friction)

**Recommendation**: Dedicated center tab with visually distinct styling (elevated icon, camera iconography, differentiated color). This is the industry standard for scan-first apps.

### Settings Placement

| Pattern | Discoverability | Standard Alignment | Used By |
|---------|----------------|-------------------|---------|
| Gear icon in header | Medium — per-tab | Non-standard | Current app |
| Profile page gear icon | High — consistent | Industry standard | Yuka, PictureThis |
| Settings tab | High — always visible | Acceptable for complex apps | FoodKeeper |

**Recommendation**: Settings should live inside a Profile/Account tab, accessed via a gear icon in the top-right of that page. Remove the gear icon from the Home header to avoid confusion.

### Number of Tabs

| Tab Count | Best For | Risk |
|-----------|----------|------|
| 3 tabs | Single-purpose utility apps | Too few for feature set |
| 4 tabs | Most utility apps (sweet spot) | Good balance |
| 5 tabs | Apps with distinct user personas | Crowding, fat-finger errors |

**Current state**: 5 tabs (Home, Scan, History, Social, Achievements) + Settings header icon.

**Recommendation**: Reduce to **4 tabs**: Home (dashboard + quick actions), Scan (center CTA), History (personal feed), Profile (account, settings, achievements). Move community/social to Home or a sub-view of Profile.

### Social FAB Toggle

Current pattern: in-screen FAB toggles between Community and Family sub-views. This is fragile on small screens and invisible on the Community sub-view at bottom-right.

**Alternatives**:
- Segmented control / top tab bar within the screen
- Separate navigation elements (swipeable tabs)
- Merge community into Home screen feed section

**Recommendation**: Top tab bar inside a unified "Social" section accessible from Home or Profile. This follows standard mobile UX patterns and avoids the visibility issues.

---

## Proposed IA Options

### Option A: 4-Tab (Recommended)
```
[Home] [Scan] [History] [Profile]
  │       │        │         │
  │       │        │     [Settings, Achievements,
  │       │        │      Premium, Social, Family,
  │       │        │      Impact Dashboard]
  │       │        │
  │  [Center CTA — elevated icon, camera]
```

**Pros**: Clean, industry-standard, reduces cognitive load. Settings discoverable via Profile. Social/Community becomes a Home card or Profile section.

**Cons**: Achievements and Social lose their dedicated tabs. Power users may need more taps to reach them.

### Option B: 5-Tab (Current Refined)
```
[Home] [Scan] [History] [Social] [Profile]
                             │         │
                        [Community,    [Settings, Achievements,
                         Family]        Premium, Impact]
```

**Pros**: Maintains direct access to all major surfaces. Familiar to existing users.

**Cons**: 5 tabs is above the sweet spot. Social sub-views need better treatment than FAB toggle.

### Option C: 3-Tab (Minimal)
```
[Scan] [Feed] [Profile]
   │       │       │
   │ [History,     [Settings, Achievements,
   │  Community,    Premium, Impact, Family]
   │  Activities]
```

**Pros**: Absolute minimum cognitive load. Scan-first focus.

**Cons**: Too few — buries too much content.

---

## Open Questions

1. Should the camera open on first launch / after onboarding for returning users? (Google Lens pattern)
2. Should there be a persistent FAB overlay on History and Home for quick re-scan?
3. How does the navigation change for premium users? (Premium tab? Premium section in Profile?)
4. Should Settings be accessible from the lock screen / widget for quick access?

---

## Next Steps

1. Decide on tab count (recommend 4)
2. Design the center scan tab visual treatment (elevated icon, camera icon, color differentiation)
3. Move Settings gear icon from Home header to Profile page
4. Replace Social FAB toggle with top tab bar or segmented control
5. A/B test 4-tab vs 5-tab on retention and task completion
