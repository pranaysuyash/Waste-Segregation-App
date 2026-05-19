# Social & Gamification Features — Roadmap & Product Notes

* Status: aspirational (pre-architecture)
* Source stash: `stash@{7}` (leaderboard, team challenges, achievement sharing, social features)
* Last updated: 2025-06-20 (from stash diff date)

---

## Overview

Stash 7 contained several social/gamification features that were never merged into `main`. This document captures the product concepts, architectural notes, and integration points — without merging any code.

These features are **not ready for implementation** until:
1. The core gamification service is stable and fully tested
2. The app has sufficient user base to justify social features
3. A product decision is made about which social features to prioritize

---

## Feature Concepts (from stash 7)

### 1. Leaderboard Screen

**What it is:** A full-screen leaderboard showing top users by points or achievements.

**Files:** New `lib/screens/leaderboard_screen.dart`
**Imports needed:** `GamificationProfile`, `GamificationService`, `AchievementType`, `Challenge`, `share_plus`
**Integration point:** AppBar action button in `achievements_screen.dart` (~8 lines)
**Existing foundation:** The `GamificationService` already tracks points and has profile data. Firestore already stores user profiles with points. The leaderboard query would read from the `users` collection ordered by `totalPoints`.

**Product questions:**
- Should this be global or friend/family-only?
- Should it be opt-in (privacy)?
- Weekly reset or all-time?
- Gamification hooks: does viewing leaderboard award points?

### 2. Achievement Sharing

**What it is:** Share buttons on achievement cards to post to social media or messaging apps.

**Files modified in stash:** `lib/screens/achievements_screen.dart`
**Library used:** `share_plus` (already in pubspec)
**Integration:** Share button in AppBar or on individual achievement cards

**Product questions:**
- What message format? (Text + image? Just text? Link to app?)
- Does sharing unlock an achievement itself ("Social Butterfly")?

### 3. Team / Community Challenges

**What it is:** Gamification challenges with team scoring — "Team Recycling Challenge" and "Community Cleanup."

**Files modified in stash:** `lib/services/gamification_service.dart`
**Approach from stash:** Added thread templates and team/leaderboard challenge types to the service

**Product questions:**
- How are teams formed? Auto-assigned? Friends invited?
- What's the scoring model for teams?
- Challenges need a lifecycle (start, end, reward distribution)

### 4. Educational Content: `isBookmarked` + `copyWith`

**Status:** ✅ **PORTED to main** (see stash 7B)
**What it is:** A boolean `isBookmarked` field on `EducationalContent` and a `copyWith()` method for immutable updates.
**Current main:** `EducationalContent` now has both `isBookmarked` and `copyWith()` — enables bookmarking UI without data mutation.

---

## Architecture Notes

### Leaderboard Data Flow

```
GamificationService.getLeaderboard()
  → Firestore query: users collection ordered by totalPoints desc
  → Returns List<GamificationProfile>
  → LeaderboardScreen renders

Caching: Leaders change rarely, cache for 5 minutes
Staleness: Acceptable — leaderboard doesn't need real-time
```

### Sharing Flow

```
User taps share on achievement
  → Construct share text: "I just earned {achievement} on Waste Segregation!"
  → share_plus.share(text)
  → Optionally track via analytics
```

### Team Challenge Flow

```
Admin creates challenge template
  → Users join (individually or as team)
  → Scoring based on classifications submitted during challenge period
  → Auto-award points/achievements on completion
```

---

## Dependencies

| Feature | Dependencies Needed | Already in pubspec? |
|---------|-------------------|-------------------|
| Leaderboard | None beyond existing | ✅ |
| Achievement sharing | `share_plus` | ✅ |
| Team challenges | None beyond existing | ✅ |

No new packages needed — all dependencies already in `pubspec.yaml`.

---

## Implementation Priority

| Priority | Feature | Effort | Dependencies |
|----------|---------|--------|-------------|
| P0 | `isBookmarked` + `copyWith` | ✅ **Done** | None |
| P1 | Leaderboard screen | 2-3 days | GamificationService, Firestore index |
| P2 | Achievement sharing | 1 day | leaderboard (for import) |
| P3 | Team challenges | 3-5 days | leaderboard + sharing |

---

## Links

* Source stash: `stash@{7}` (camera+gamification+edu features — never merged)
* Related: `docs/adr/ADR-003-data-sync-strategy.md`
* Related: `lib/services/gamification_service.dart`
* Related: `lib/screens/achievements_screen.dart`
