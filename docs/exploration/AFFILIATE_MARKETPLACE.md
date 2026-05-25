# Affiliate / Eco-Marketplace Exploration

**Status**: Seed — P2, not yet funded
**Last Updated**: 2026-05-26
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Item 74
**Related**: ADS_REVENUE_DIVERSIFICATION.md, SPONSOR_REWARDS_DONATION_MATCHING.md, TOKEN_ECONOMY_AND_PRICING_COHERENCE.md

---

## 1. Why This Matters

After repeated scans of hard-to-recycle packaging, the app has a natural prompt: "you keep scanning this — here's a lower-waste alternative." Done right, this is helpful. Done wrong, it's greenwashing or feels like an ad.

The affiliate wedge is a monetisation surface that *doesn't* degrade the core experience — but only if trust is preserved. Every design decision below is gated on trust neutrality.

---

## 2. How Existing Apps Handle This

| App | Model | Trust Mechanism |
|-----|-------|-----------------|
| **Yuka** | Freemium, no affiliate revenue | Zero revenue from recommendations — editorial independence is the selling point |
| **Buycott** | Free, no affiliate | Recommendations driven by third-party certification data, not revenue |
| **Good On You** | Free + paid brand profiles | Brands pay for verified presence; "Better Alternative" recommendations are editorial |
| **Ethical Consumer** | Subscription-funded | No affiliate links; editorial independence as core value |
| **Package Free Shop** | Full marketplace (owned inventory) | Curated products, own stock — clear merchant relationship |

**Key insight**: Yuka's refusal of affiliate revenue is a deliberate trust moat. The app should consider whether affiliate revenue is worth the trust erosion, or whether freemium + sponsor funding (see SPONSOR_REWARDS_DONATION_MATCHING.md) is a better path for a mission-driven product.

---

## 3. Trust Safeguards (Non-Negotiable)

If affiliate revenue is pursued, these guardrails MUST be in place:

### 3.1 Separation of Church and State
- Recommendation rankings are driven by **objective third-party data** (certifications, ingredient databases, supplier transparency) *before* affiliate filters are applied.
- Higher-commission partners never get priority placement.
- Audit trail: every recommendation decision is logged with the criteria that produced it.

### 3.2 Disclosure
- FTC-mandated "Commissionable Link" disclosure must be **above the fold**, not in a menu or footer.
- Mark all affiliate links as `rel="sponsored"` or `rel="nofollow"`.
- Disclosure language: "We recommend products based on sustainability metrics. Some links are commissionable — our scoring is independent."

### 3.3 The Altruism Rule
- If the most sustainable product in a category does NOT have an affiliate program, **recommend it anyway**. This is the credibility bridge that proves neutrality.
- Log every unsupported recommendation — they are trust deposits, not lost revenue.

### 3.4 Transparency Reports
- Publish periodic reports on how recommendations are generated.
- If a user can see *why* a product was recommended (material score, packaging score, end-of-life score), they're less likely to assume it was a paid placement.

---

## 4. Design Patterns for Alternative Suggestions

### 4.1 Contextual Trigger
- Shown after repeated scans of the same problematic packaging type (e.g., "you've scanned 3 plastic-wrapped items — would you like to see alternatives?")
- NOT shown on first scan. NOT shown when the user is holding the item at the bin.

### 4.2 Utility-First Language
| Salesy | Helpful |
|--------|---------|
| "Buy this now" | "Compare alternatives" |
| "Best deal" | "Lower-waste option" |
| "Shop now" | "Available in: glass, cardboard, bulk" |

### 4.3 Visual Hierarchy
- Alternative suggestions are a **secondary section** beneath the primary classification result and disposal instructions.
- Never in the top, most prominent screen position.
- Show the *why* first: "This alternative uses 60% less plastic packaging."

---

## 5. Affiliate Commission Structure

### 5.1 Typical Margins
- Physical products: **5–20%** commission typical.
- Higher margins (15%+) available through direct partnerships with sustainable-first DTC brands.
- Major networks: Impact, ShareASale, Rakuten — contain eco-merchant categories.

### 5.2 Strategic Approach
- **Primary**: Direct partnerships with sustainability-first brands for higher margins (15%+).
- **Secondary**: Affiliate networks for fill coverage.
- **Never**: Programmatic ads masquerading as recommendations (e.g., Amazon native shopping ads).

---

## 6. Minimum Viable Product

The wedge should be a **curation-first referral layer**, not a full marketplace:

1. **Scanner -> alternative suggestion**: After a scan, show "1 lower-waste alternative found" with a link.
2. **Outbound referral**: Clickthrough sends user to the brand's own site or a reputable retailer.
3. **Disclosure on every link**: "Commissionable link — chosen for sustainability score."
4. **No inventory, no payments, no logistics.**

**Why this wedge**: Minimal operational overhead (no inventory risk, no customer support for orders), establishes the app as an objective arbiter, and generates data on which categories users actually follow through on.

**Future expansion path**: If referral revenue validates user demand, explore:
- Direct brand partnerships with discount codes for app users.
- Curated seasonal collections (zero-waste starter kits, back-to-school sustainable supplies).
- Full marketplace only if a pilot partner (school/RWA) needs it for a specific program.

---

## 7. Kill Criteria

- User feedback indicates recommendations feel salesy or untrustworthy.
- Affiliate revenue projections don't justify the trust erosion risk.
- Recommended products can't be objectively ranked due to insufficient sustainability data.
- FTC or consumer protection scrutiny becomes a legal risk for a mission-driven app.

---

## 8. Key Questions Still Open

- **Yuka path vs affiliate path**: Is the trust moat worth more than the projected affiliate revenue? Should the app commit to zero affiliate revenue as a product principle?
- **Category prioritisation**: Which categories have the strongest "better alternative" story — packaging, household cleaners, personal care, food storage?
- **Cross-cultural product availability**: Alternatives valid in Bangalore may not be available in Delhi or San Francisco — how to handle region-specific recommendations?
- **Integration with the existing scanning flow**: Should the alternative suggestion be on the result screen, a follow-up notification, or a separate "discover" tab?
