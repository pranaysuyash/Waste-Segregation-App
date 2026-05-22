# GPS vs Manual Region Selection — UX Design Concept

**Decision this unblocks**: Whether the "set your city" flow needs to be built before or after the first multi-city plugin ships.

**Status**: Design Concept (2026-05-22)
**Related**: REGION_RULES_AND_CITY_EXPANSION_MAP.md §14

---

## Problem

The policy engine needs a `region` string. Today that comes from the `WasteClassification.region` field, which is populated by... whatever the caller provides. There is no user-facing "set your city" screen, and no GPS-based region detection.

## Options

### Option A: GPS-based automatic detection (preferred)

- On first launch, request coarse location permission.
- Reverse-geocode coordinates to city name.
- Match city name against `LocalGuidelinesManager._regionAliases`.
- Store selected region in SharedPreferences / Hive.
- Re-check periodically (monthly) or when user travels >50km from stored location.

**Pros**: Zero friction, always correct for users who grant location.
**Cons**: Requires location permission upfront; poor experience for permission-denied users.

### Option B: Manual city selection

- On first launch, show a "Where are you?" screen with a searchable dropdown of supported cities.
- Store in SharedPreferences.
- User can change in Settings.

**Pros**: No permission needed, works everywhere, user is in control.
**Cons**: Extra step in onboarding, user must know which jurisdiction they're in.

### Option C: Hybrid (recommended)

- On first launch, try GPS. If permission granted and reverse-geocode succeeds → auto-select, no UI shown.
- If permission denied or reverse-geocode fails → show manual city picker.
- User can always override in Settings.
- In Settings, show current detected location vs stored preference, with "Use current location" button.

## Edge cases

| Case | Behaviour |
|------|-----------|
| User works in City A, lives in City B — scans in both | Per-scan region = GPS at scan time. Home region = profile setting. Result card shows "Scanned in Mumbai. Home region: Pune." |
| Near ward/jurisdiction boundary | Use GPS coordinate, match to ward if available. If ambiguous, show both and ask. |
| Roaming / travel | GPS overrides home setting during scan. "You're in Delhi. Delhi rules applied. [Use home rules?]" |
| Airplane mode / no GPS | Fall back to stored home region. Show subtle badge: "Using saved region (offline)". |
| Multiple cities not yet supported | Engine gracefully falls through: plugin found → use it. Plugin not found → generic advice, no violations. |

## Proposed settings screen copy

```
Region & Local Rules
─────────────────────
Current location:  Mumbai, IN  [Detected from GPS]
Home region:       Pune, IN    [Tap to change]

When scanning away from home:
[x] Apply local rules automatically
[ ] Always use home region rules

Supported cities: Bangalore, Chennai, Delhi, Hyderabad, Kolkata, Mumbai, Pune
```

## Implementation notes

- GPS reverse-geocoding can use the existing `geoflutterfire_plus` dependency or a lightweight geocoding package.
- The region string passed to `LocalPolicyEngine.applyPolicy()` should be the **resolved city name** (e.g. "Mumbai, IN"), not a raw GPS coordinate.
- Region selection should be a Riverpod provider so the policy engine and UI reactively update when the user changes region.
- For the initial ship, manual selection (Option B) is sufficient and requires no new permissions. GPS integration (Option C) can follow in a subsequent release.
