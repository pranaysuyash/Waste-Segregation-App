# Home Screen (Canonical)

## Entrypoint

`MainNavigationWrapper` renders `HomeScreen` (`lib/screens/home_screen.dart`) as tab index `0`.

`UltraModernHomeScreen` is deprecated compatibility code and is not the runtime source of truth.

## Home sections

1. Hero header (greeting, settings, stats chips for points/tokens/streak/days active)
2. Mission control panel (primary Scan + Learn actions)
3. Daily progress card (today progress vs daily goal)
4. Action chips (Take Photo, Upload Image, Instant Camera, Instant Upload)
5. Near-milestone nudge (conditional)
6. Community impact card
7. Active challenge card (conditional)
8. Daily tip card
9. Recent classifications (latest 3, sorted newest-first)
10. Empty state and error/retry states

## Provider dependencies

- `classificationsProvider`
- `profileProvider`
- `userProfileProvider`
- `pointsManagerProvider`
- `tokenWalletProvider`
- `educationalContentServiceProvider`
- `todayGoalProvider`
- `gamificationServiceProvider`

## Navigation destinations from Home

- Settings (`Routes.settings`)
- `ImageCaptureScreen`
- `InstantAnalysisScreen`
- `EducationalContentScreen`
- `ContentDetailScreen`
- `HistoryScreen`
- `AchievementsScreen`
- `WasteDashboardScreen`

## Testing matrix

- Data/loading/error provider states
- Empty vs populated classification history
- Action chips for normal and instant capture modes
- Daily tip behavior with/without `contentId`
- Active challenge presence/absence and safe progress rendering
- Small width and larger text scale layouts
