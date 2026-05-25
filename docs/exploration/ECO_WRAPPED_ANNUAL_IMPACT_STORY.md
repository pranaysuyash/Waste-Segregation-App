# Eco Wrapped / Annual Impact Story

**Status**: Draft — no code surface for annual recaps exists yet.
**Priority**: P2 (high retention value, low implementation cost)
**Related**: [PERSONAL_IMPACT_DASHBOARD_UX.md](PERSONAL_IMPACT_DASHBOARD_UX.md), [DEEP_LINKS_SHARING_VIRAL_LOOPS.md](DEEP_LINKS_SHARING_VIRAL_LOOPS.md), CARBON_IMPACT_ACCOUNTING.md
**Last Updated**: 2026-05-25

---

## Why This Is a Topic

Spotify Wrapped generated 60M+ social shares in 2023. The pattern works because:

1. **Personalized narrative** — the user is the hero of their own data story.
2. **Surprise and delight** — users discover patterns in their behaviour they didn't consciously recognize.
3. **Identity expression** — sharing "I'm in the top 5% of waste diversions" signals values to social network.
4. **Retention hook** — anticipation for "Wrapped season" drives re-engagement.

For a sustainability app, "Eco Wrapped" is even more mission-aligned: it shows the user their real-world impact, which is abstract in daily use but meaningful in aggregate.

---

## Story Card Deck

Each "Eco Wrapped" is a sequence of vertical (9:16) cards, designed for sharing to Instagram, WhatsApp, and X/Twitter. Estimated 8–12 cards per user.

### Card 1: Cover
- "Your 2026 Eco Wrapped"
- User's eco handle or name
- Year's dominant bin colour/theme
- "Powered by ReLoop"

### Card 2: Your Year in Waste
- Total items classified
- "That's like sorting X days worth of waste"
- Comparison: "More than X users in your city"

### Card 3: Material Mix (Donut chart)
- Top 3 materials classified
- Surprise stat: "You classified X types of plastic — do you buy bottled water?"
- Material with biggest improvement from last year

### Card 4: Streak Highlights
- Longest streak: "X days without missing a classification"
- Streak month with most consistency
- "You maintained your streak through [holiday season, festival, vacation]"

### Card 5: Impact Snapshot
- Kg diverted from landfill estimate
- CO₂ equivalent saved
- Concrete comparison: "Equal to planting X trees" / "X kg of coal not burned"

### Card 6: Local Hero
- City where you classified the most
- Items aligned with your city's rules
- "You knew recycling rules for X different cities"

### Card 7: Most Improved Category
- Category with biggest accuracy improvement
- "In January you correctly sorted X% of plastic. By December: Y%."
- Learning journey stat: quizzes completed, corrections made

### Card 8: Hazardous Awareness
- Hazardous items identified: X
- "You prevented X kg of hazardous waste from entering the wrong stream"
- Safety stat: "Zero hazardous items mis-sorted!" (if true)

### Card 9: Community Impact (if applicable)
- "Your community sorted X items together"
- Challenges completed
- "You helped X neighbors with their waste questions"

### Card 10: Fun Facts
Weirdest item classified, most common misclassification, most active hour/month, "You classify plastic most often on Tuesday evenings"

### Card 11: Year Ahead
- Target for next year: "Can you beat your streak? Can you improve accuracy on paper?"
- "You're in the top X% of eco-citizens this year"
- "Keep going — every classification counts"

### Card 12: Share
- "Share your Eco Wrapped"
- Share buttons: Instagram, WhatsApp, X/Twitter, Save to gallery
- "Challenge a friend to beat your score"

---

## Data Refresh Cadence

| Cadence | Surface | Purpose |
|---------|---------|---------|
| **Monthly** | In-app notification + static card | Micro-milestone, re-engagement |
| **Quarterly** | In-app story (3–4 cards) | Deeper reflection, catch-up |
| **Annual** | Full 12-card deck (Eco Wrapped) | Mega-event, social sharing, viral growth |

Quarterly is optional for Phase 1. Annual is the flagship.

---

## Generation Architecture

### Client-side generation (Phase 1)

- Data query: Firestore query for user's classification history for the year.
- Computation: aggregation functions (total items, per-category breakdown, streak calculation, city counts).
- Card rendering: template-based in-app (pre-designed card backgrounds, text overlay).
- Export: save to gallery as PNG, share sheet.

**Pros**: No server cost, works offline.
**Cons**: App update needed to change card designs, limited graphic complexity.

### Server-side generation (Phase 2)

- Cloud Function queries Firestore, computes stats, calls image generation API (Cloudinary, Vercel OG, or custom canvas) to produce cards.
- Cards are served as pre-generated images via a shareable link.
- Server handles the computationally intensive aggregation; client just displays.

**Pros**: Design can be updated server-side, richer graphics possible.
**Cons**: Higher implementation cost, requires network for initial generate.

### Recommendation

Phase 1: client-side generation (minimal cost, fast to ship). Phase 2: server-side generation for richer designs and share-by-link support.

---

## Privacy Considerations

### Sharing Boundaries

- Default: Eco Wrapped is **private** — viewable only by the user.
- User opts in to share: "Share your Eco Wrapped with friends?"
- Shared data is a pre-generated image — no live connection to account.
- User can share individual cards (not required to share the whole deck).

### What's Shared vs What's Private

| Data Point | Shared Card | Private (not shared) |
|------------|-------------|---------------------|
| Total items | ✓ (aggregated) | — |
| Top materials | ✓ | — |
| Streak length | ✓ | — |
| Impact estimate | ✓ | — |
| Correction rate | ✗ | ✓ (too sensitive) |
| Individual item photos | ✗ | ✓ |
| Location history | City only | Exact GPS |
| Comparison percentile | ✓ | — |

### Comparison Data

- Percentile rankings require aggregated peer data ("You sorted more than X% of users").
- Aggregated data must be pre-computed from all users (anonymized, server-side).
- No individual user's data is exposed through comparison — only the user's own percentile.

---

## Viral Loop Potential

Eco Wrapped is the app's highest-potential viral surface:

1. **Share card → recipient sees card → curious → installs app**.
2. **Share "Challenge a friend" → friend gets notification → engagement**.
3. **Compare with community → "My neighbor sorted twice what I did!" → re-engagement**.

To maximize this:
- Cards must be visually striking (rich colors, waste-themed design, clear data).
- Cards must include the app name/logo (branding).
- Share-to-Instagram-story should be a one-tap action.
- "Challenge a friend" deep link auto-fills the friend's handle if shared from within app.

---

## Open Questions

1. **Should Eco Wrapped work for new users?** (joined November — only 1 month of data). Proposal: yes — highlight first-scan moments instead of annual stats.
2. **Should there be a "lite" version for anonymous users?** Proposal: yes — basic stats without attribution.
3. **What's the right time of year for launch?** End of year (Dec 26–Jan 1) for maximum social sharing during holiday season. Extended to Jan 15 for stragglers.
4. **Monthly/quarterly recaps as push notification triggers?** Monthly recap notification: "You classified 47 items this January — 15% more than December!" Low-cost re-engagement.

---

## Related Work

- [PERSONAL_IMPACT_DASHBOARD_UX.md](PERSONAL_IMPACT_DASHBOARD_UX.md) — daily/weekly impact presentation (Eco Wrapped is the annual version)
- [DEEP_LINKS_SHARING_VIRAL_LOOPS.md](DEEP_LINKS_SHARING_VIRAL_LOOPS.md) — sharing infrastructure that Eco Wrapped relies on
- CARBON_IMPACT_ACCOUNTING.md — methodology behind impact numbers used in Eco Wrapped
- [NOTIFICATION_STRATEGY.md](NOTIFICATION_STRATEGY.md) — notification timing for monthly/quarterly recaps
