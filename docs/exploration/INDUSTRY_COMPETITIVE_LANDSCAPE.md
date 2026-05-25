# Industry Competitive Landscape

**Status**: Exploration doc — annual refresh recommended
**Last Updated**: 2026-05-25
**Category**: Industry Signal
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md#a25-mrf-side-competitors--b2b-reference-customers--industry-signal-)
**Related**: B2B / Enterprise Wedge (#29), Distribution & Partnerships (#31), Cross-Platform Parity (A10), Token Economy (#27a)

---

## Why This Is a Topic

The waste classification app market has two distinct ecosystems:

1. **Consumer-facing apps** (Recycle Coach, Scrapp, iRecycle, RecycleNation) — what the app directly competes with
2. **MRF-side industrial systems** (AMP Robotics, Greyparrot, Recycleye, TOMRA) — define the *upper bound* of what CV-for-waste can achieve and are potential B2B partners

Understanding both landscapes determines the app's differentiation strategy, partnership opportunities, and accuracy targets.

---

## Key Questions

1. **Consumer competitor analysis** — what features are table-stakes vs differentiators?
2. **MRF competitor analysis** — what can industrial systems do that consumer apps can't, and vice versa?
3. **Partnership landscape** — who partners with whom, and what does the app bring to a partnership?
4. **Gap analysis** — what needs do consumers have that no current app fully addresses?
5. **Accuracy benchmarks** — what claims do competitors make, and how credible are they?

---

## Research Summary

### Consumer App Landscape

| App | Business Model | Key Features | Accuracy Claim | Partnership Model |
|-----|---------------|--------------|---------------|-------------------|
| **Recycle Coach** | B2G (municipal licensing) | Collection schedules, "what goes where" search, localized guides, notifications | Not publicly stated — relies on curated database | Municipal contracts (city-level) |
| **Scrapp** | B2C (freemium) | Barcode scanning → product lookup, material identification, disposal guidance | Not publicly benchmarked | Brand/retailer partnerships |
| **iRecycle** | B2C (free, ad-supported) | 350+ material directory, location-based drop-off, collection events | Not AI-based — manual database | Municipal + recycling partner listings |
| **RecycleNation** | B2C (free) | Location search, material guides, local rules | Not AI-based — database lookup | Municipal + brand partnerships |
| **WasteSorted** | B2B (corporate/education) | Bin signage, staff training, waste audits | Not vision-based — educational | Schools, offices, events |
| **Too Good To Go** | B2C/B2B (marketplace) | Surplus food rescue, not classification | Not applicable | Food retailers, restaurants |
| **Olio** | B2C (community) | Food sharing, not classification | Not applicable | Community + brand partnerships |

**Key observation**: No consumer app has yet built a truly reliable, AI-powered image classification layer for waste. Most rely on curated databases, manual search, or barcode lookup. This is the app's primary differentiation opportunity.

### MRF-Side Industrial Systems

| Company | Funding | Technology | Focus | Partnership Potential |
|---------|---------|------------|-------|---------------------|
| **AMP Robotics** | ~$105M+ raised | Computer vision + robotic sorting at MRF scale | High-speed sorting, material purity | Consumer side data partner (anonymized trends) |
| **Greyparrot** | ~$80M+ raised | AI camera systems for MRF conveyor analysis | Waste analytics, purity monitoring, contamination detection | Data partnership (consumer confusion → MRF insight) |
| **Recycleye** | ~$20M+ raised | Vision-based robotic sorting | Low-cost MRF automation | Limited — early stage |
| **TOMRA** | Public company ($3B+ market cap) | Sensor-based sorting (NIR, XRF, camera) | Reverse vending, MRF sorting, food processing | Hardware partnership (QR-enabled reverse vending) |

**Accuracy claims**: MRF systems cite 95%+ accuracy for specific material streams. However, these are controlled conveyor-belt conditions with optimized lighting — not directly comparable to consumer phone camera photos of dirty/obscured items.

### Partnership Landscape

The most successful consumer apps monetize through **B2G licensing** (municipal contracts), not B2C revenue:

- **Recycle Coach** — signed contracts with ~2,500+ municipalities across North America. Provides localized collection schedules, disposal guides, push alerts.
- **Scrapp** — partnerships with brands (P&G, Nestlé) for packaging recyclability data.
- **iRecycle** — listings from recycling partners, funded by industry associations.

**What the app brings to a partnership**: Real-world classification data (anonymized consumer accuracy, confusion patterns, regional rule gaps) that neither consumer apps nor MRF systems currently capture at scale.

### Gap Analysis

| Gap | Current App Coverage | Unmet Need |
|-----|---------------------|------------|
| Real-time AI image classification | ✅ App does this | No consumer competitor does this reliably |
| Multi-city regional rules | ✅ 7 cities live | Most apps have 1-2 cities or none |
| User correction loop | ✅ Correction service + training data pipeline | No competitor captures corrections as training signal |
| On-device inference | ⚠️ Phase A+B built, Phase C pending | No competitor targets offline classification |
| QR/barcode + product DB lookup | ❌ Disabled in prod (dependency conflict) | Scrapp does this — differentiator gap |
| DPP / QR scan integration | ❌ Not started | No competitor does this yet |
| Community/social features | ✅ Community feed + family groups | Limited in competitor space |
| Family/household mechanics | ✅ Family groups, cooperative challenges | Unique in sustainability app space |
| Gamification with adaptive engine | ⚠️ V1 done, V2 planned | Most competitors have no gamification |
| Impact accounting with methodology | ⚠️ Dashboard exists, methodology pending | Most competitors show simplified numbers |
| B2B/B2G sales motion | ❌ Not started | Recycle Coach dominates here; largest gap to close |

---

## Design Recommendations

### Differentiation Strategy

1. **Lead with AI classification accuracy** — the app's ability to classify via AI image recognition is the primary differentiator. Publish a benchmark against the golden set once it reaches critical mass.
2. **Build the data flywheel** — user corrections, regional rule application, and multi-provider routing create a compounding data moat that database-only competitors cannot replicate.
3. **Monetize through B2G/B2B, not ads** — following Recycle Coach's model. The consumer app is the data engine; the revenue comes from selling aggregated, anonymized intelligence to municipalities, brands, and MRF partners.
4. **Compete on locality, not geography** — most consumer apps cover North America only. The app's India-first (BBMP) + 6 pilot cities + global ambition is a genuine geographic differentiator.
5. **Prepare for DPP integration** — no competitor in the consumer space is preparing for DPP consumption. First-mover advantage exists.

### Partnership Development Path

1. **Phase 1 (2026)** — Approach BBMP / Bangalore municipality for informal data partnership. Offer anonymized classification accuracy/confusion data in exchange for official collection route data.
2. **Phase 2 (2027)** — Approach Greyparrot or AMP Robotics for MRF data partnership. Consumer-side correction data complements MRF-side contamination data.
3. **Phase 3 (2028)** — If DPP integration is live, approach consumer electronics brands for B2B data service: "our users correctly dispose your products at X rate — here's the breakdown by model."

### Accuracy Benchmark Target

| Metric | Current Target | Competitor Benchmark | Goal |
|--------|---------------|---------------------|------|
| Top-1 accuracy (all items) | TBD (no baseline published) | Recycle Coach: N/A (no vision), Scrapp: N/A (barcode-only) | Publish baseline by Q3 2026 |
| Top-3 accuracy (all items) | TBD | — | Target >95% |
| Disposal advice correctness | TBD | — | Target >90% (with regional rule application) |
| Safety-critical accuracy | TBD | — | Target >99% (with escalation path) |

### Kill Criteria

- If a competitor (Google Lens, Apple Visual Lookup) adds waste classification as a general feature and achieves >95% consumer accuracy, the app's differentiation pivots from "accuracy" to "domain knowledge" (regional rules, impact, gamification, community)
- If Recycle Coach adds real-time AI classification with multi-city rules within 12 months, the app loses its primary differentiation gap

---

## Open Questions

- Should the app open-source parts of its taxonomy or rules corpus to build community authority (Wikipedia model for waste data)?
- Is there a stronger growth angle through B2B (schools, apartments, corporate ESG) than B2C, given the competitive landscape?
- Would publishing an annual "State of Waste Classification" report with anonymized accuracy data build the app's credibility and attract research partnerships?
