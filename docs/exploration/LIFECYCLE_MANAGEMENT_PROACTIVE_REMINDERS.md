# Personal Waste Lifecycle Management & Proactive Reminders

**Status**: Exploration | P2 | Circular Economy & Pre-Waste Intervention
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Entry 47
**Last Updated**: 2026-05-25

---

## Why This Matters

The app currently reacts to waste *after* the user decides to scan it. The next horizon is predicting waste before it happens — intercepting items at their end-of-life and guiding the user to the right disposal decision before the item sits in a corner for months or goes to landfill incorrectly.

Proactive lifecycle management transforms the app from a "scan-to-answer" tool into a "waste prevention companion" with recurring engagement touchpoints between scans.

---

## Core Concept: The Item Lifecycle

```
Purchase → In-Use → End-of-Life Warning → Disposal Decision → Correct Disposal
   │          │            │                    │
   │          │       ╔════════════════╗        └─> Reuse / Donate / Sell
   │          │       ║  APP INTER-   ║            Recycle / Compost / Trash
   │          │       ║  VENTION      ║            Hazardous disposal
   │          │       ╚════════════════╝
   │          │
   └─> Log    └─> Track
       scan       consumption
       receipt    velocity
```

---

## Key Research Findings

### 1. Data Sources for End-of-Life Prediction

Apps predict item EOL by synthesizing multiple data streams:

| Source | Reliability | User Effort | Privacy Risk |
|--------|-------------|-------------|--------------|
| Barcode scan → product DB lookup | High | Medium (scan) | Low |
| Digital receipt OCR (Gmail connector) | Medium | Zero | Medium |
| Manual expiry date entry | High | High | Low |
| Heuristic consumption velocity | Medium | Low (passive) | Low |
| Order email parsing (Amazon, Blinkit) | Medium | Zero | High |

**Recommendation**: Start with barcode + manual expiry entry (lowest privacy risk). Add digital receipt parsing only with explicit opt-in and on-device processing.

### 2. Notification Design — Avoiding Nagging

The single biggest design challenge is notification fatigue. Effective patterns:

- **Just-in-time context**: Alert when an item hits 20% remaining shelf life, not at arbitrary intervals
- **Aggregate, don't drip**: Daily/weekly "Waste Outlook" summaries instead of per-item alerts
- **Passive visibility**: Color-coded "fridge/pantry health" dashboard users can check voluntarily
- **Actionable links**: Every notification must include direct action: "Mark used" / "Find recipe" / "Check disposal guide"
- **Quiet hours**: Respect time-of-day — never nudge after 9 PM or before 8 AM

### 3. Privacy Boundaries

| Acceptable | —​— Boundary —​— | Creepy |
|---|---|---|
| "You bought this milk 2 weeks ago" | ← → | "You buy milk every Tuesday at 10 AM from the same store" |
| "This item typically lasts 6 months" | ← → | "We know you stopped using this — are you OK?" |
| On-device, opt-in lifecycle tracking | ← → | Cloud sync of purchase data without clear value exchange |

**Rule**: All lifecycle data should default to on-device. Cloud sync is opt-in and value-transparent.

### 4. Competitive Research

- **NoWaste**: Manual inventory + expiry dates. Relies on user input to stay useful. Most direct comparable.
- **Too Good To Go**: Pre-consumer surplus marketplace. Does not track home inventory.
- **Olio**: Community redistribution. Items listed by users nearing EOL.
- **Fridge Pal**: Simple expiry tracking with push reminders and colour coding.

---

## Engagement Touchpoints

| Lifecycle Phase | Touchpoint | Frequency |
|----------------|------------|-----------|
| Purchase | "Scan to add to your inventory" | On scan result if item is durable/long-life |
| Regular use | Silent — passive inventory decay | None |
| Approaching EOL | "X items expiring this week" | Weekly digest |
| Past EOL | "Did you dispose of X?" | Once, gentle |
| Disposal | "This could be [reused/donated/recycled]" | At disposal action |

---

## Integration Points

| Component | Changes Required |
|-----------|-----------------|
| Scan result screen | "Track this item?" button for long-life items |
| Home screen | Lifecycle widget: "3 items expiring soon" |
| Notifications | Daily/weekly digest preference |
| Impact dashboard | "Waste prevented by proactive disposal" metric |
| History screen | Lifecycle timeline view per item |

---

## Open Questions

1. **On-device vs cloud**: Is a local-only lifecycle engine sufficient, or does cloud sync enable cross-device utility?
2. **Heuristic calibration**: How do we learn consumption velocity without user fatigue from logging?
3. **Notification cap**: What's the maximum weekly lifecycle notification count before users disable it?
4. **Retention value**: Does proactive lifecycle management measurably improve DAU/WAU against notification cost?
5. **Integration scope**: Should this be a standalone mode or woven into existing scan → result → action flow?

---

## Risk Register

| Risk | Severity | Mitigation |
|------|----------|------------|
| Notification fatigue → uninstall | High | Aggregate digests, user-controlled frequency, quiet hours |
| Privacy backlash from purchase tracking | High | On-device default, explicit opt-in for cloud, transparent value explanation |
| Low data quality from manual entry | Medium | Barcode as default, heuristic fallback, minimal friction design |
| Low engagement — users don't log purchases | Medium | Integrate with existing scan flow; don't create new habit |

---

## Phasing

| Phase | Scope | Data Source | Privacy Model |
|-------|-------|-------------|---------------|
| 0 | Barcode + manual expiry only | User-initiated scans | On-device only |
| 1 | + Heuristic consumption velocity | Passive from usage patterns | On-device |
| 2 | + Digital receipt parsing (opt-in) | Gmail connector, app-links | Opt-in, on-device OCR |
| 3 | + Cloud sync, cross-device lifecycle | Synced ledger | Explicit opt-in |
