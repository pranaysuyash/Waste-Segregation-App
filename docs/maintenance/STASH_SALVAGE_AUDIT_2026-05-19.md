# Stash Salvage Audit — 2026-05-19

## Scope

All 8 local stashes were reviewed for code, documentation, and architectural ideas worth preserving on `main`. No stash was applied or popped during this audit. All inspection was read-only.

---

## Code Ported (2 changes, 1 file)

| Change | File | Source |
|--------|------|--------|
| `EducationalContent.isBookmarked` field (default `false`) | `lib/models/educational_content.dart` | `stash@{7}` |
| `EducationalContent.copyWith()` method | `lib/models/educational_content.dart` | `stash@{7}` |

Both changes are purely additive and were verified with `dart analyze`.

---

## Documentation Created (6 new files)

| File | Content | Source |
|------|---------|--------|
| `lib/models/educational_content.dart` | `isBookmarked` field + `copyWith()` method | `stash@{7}` |
| `docs/adr/ADR-003-data-sync-strategy.md` | Deferred centralized data sync strategy with phased plan and exact stash 3 method names as reference | `stash@{3}` |
| `docs/planning/roadmap/SOCIAL_GAMIFICATION.md` | Social/gamification feature concepts: leaderboard, sharing, team challenges, with architecture notes and product questions | `stash@{7}` |
| `docs/roadmap/ENHANCEMENT_BACKLOG.md` | Full enhancement backlog from stash 1 QUICK_WINS_TODO, including educational UX ideas, VIS-22 premium visuals, T-05 semantic labels | `stash@{1}`, `stash@{7}` |
| `docs/technical/features/camera_architecture.md` | Current camera implementation summary + aspirational direct camera API notes with decision points | `stash@{7}` |
| `docs/maintenance/STASH_SALVAGE_AUDIT_2026-05-19.md` | This file — full audit record | all stashes |

---

## Intentionally Not Merged (with reasoning)

| Item | Stash | Reason |
|------|-------|--------|
| `DataSyncProvider` class | 3 | Architecturally incompatible with current `_AppBootstrapper`; would create circular dependencies |
| Leaderboard implementation | 7 | New screen — needs product/design decision; idea preserved in roadmap |
| Achievement sharing implementation | 7 | Depends on leaderboard screen; premature without social foundation |
| Team/community challenge templates | 7 | Dead code without leaderboard; idea preserved in roadmap |
| Direct camera API (CameraController, availableCameras) | 7 | Would add ~100 lines of native camera code; deferred per roadmap |
| Camera initialization in `main.dart` | 7 | Depends on direct camera API above |
| Educational content screen rewrite | 7 | Full screen rewrite with advanced filtering/search/UX — would overwrite current screen; UX patterns preserved in backlog |
| "Refresh All Images" settings button | 3 | Required importing non-existent `DataSyncProvider` — not a local UI hook |
| Web-safe WasteAppLogger patch | 0 | Current main is already web-safe (no `dart:io`, uses `kDebugMode`/`debugPrint`); stash was from older logger iteration |
| Stash 2, 4, 5, 6 changes | 2,4,5,6 | Lockfile noise, superseeded formatting, initial commit, or changes already in main |

---

## Stash Cleanup Recommendation

| Stash | Safety | Action |
|-------|--------|--------|
| `stash@{2}` | Superseded lockfile/analysis noise | **Delete immediately** |
| `stash@{4}` | Cosmetic tweaks, superseded | **Delete immediately** |
| `stash@{5}` | Initial commit, stale | **Delete immediately** |
| `stash@{6}` | Changes already merged into main | **Delete immediately** |
| `stash@{0}` | Logger idea documented as obsolete | **Delete after skimming docs** |
| `stash@{1}` | QUICK_WINS_TODO fully captured in backlog | **Delete after skimming docs** |
| `stash@{3}` | Sync method names captured in ADR-003 | **Delete after skimming docs** |
| `stash@{7}` | Code ported + UX ideas captured in backlog | **Delete after skimming docs** |

---

## Key Principles Followed

1. **Preserve long-term thinking**: Ideas worth keeping were documented as ADRs, roadmaps, or backlog entries — not merged as old code.
2. **Don't pollute main with old architecture**: The `DataSyncProvider` and full screen rewrites were consciously rejected.
3. **Catch gaps before deletion**: The final safety check revealed undocumented stash 7 UX features, which were then captured in the backlog.
4. **No git mutations during salvage**: All inspection was read-only. No stash applied, popped, or deleted by agent.

---

## Links

- Source stashes: `stash@{0}` through `stash@{7}`
- ADR-001: `docs/adr/ADR-001-clean-architecture.md`
- ADR-002: `docs/adr/ADR-002-state-management-riverpod.md`
- ADR-003: `docs/adr/ADR-003-data-sync-strategy.md`
- Social Gamification Roadmap: `docs/planning/roadmap/SOCIAL_GAMIFICATION.md`
- Enhancement Backlog: `docs/roadmap/ENHANCEMENT_BACKLOG.md`
- Camera Architecture: `docs/technical/features/camera_architecture.md`
