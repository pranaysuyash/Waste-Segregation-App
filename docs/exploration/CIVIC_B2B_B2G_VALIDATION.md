# Civic B2B/B2G Validation — Pilot Buyer Hypothesis

**Status**: Seed — research only, no implementation
**Priority**: 🟢 (P2 — civic intelligence track)
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Section F: Locality & Civic Waste Intelligence (L5)
**Related**: [CIVIC_AUTHORITY_SHARING.md](CIVIC_AUTHORITY_SHARING.md), [B2B_ENTERPRISE_WEDGE.md](B2B_ENTERPRISE_WEDGE.md), [POST_MVP_ROADMAP_POINTS_CHALLENGES_COMMUNITY.md](POST_MVP_ROADMAP_POINTS_CHALLENGES_COMMUNITY.md)

---

## Overview

The civic data layer needs a **paying buyer** to justify the engineering investment. This doc maps potential buyers, their urgency, their sales cycle, and the minimum viable product surface for each.

**Goal**: Identify the buyer who can close a paid pilot within 6 months, and define the minimum surface needed for that pilot.

---

## Buyer Matrix

| Buyer | Urgency | Budget | Sales Cycle | Competition | Fit |
|-------|---------|--------|-------------|-------------|-----|
| **Apartment Association (RWA)** | HIGH — direct pain (fines, odour, segregation rules) | ₹10K-50K/month | 1-2 months | None specific for waste data | ★★★★★ |
| **School** | MED — curriculum need, CSR grants | ₹5K-20K/month | 2-4 months | Some eco-club tools | ★★★★☆ |
| **CSR Sponsor** | HIGH — compliance need (audited impact data) | ₹50K-500K/month | 3-6 months | Many impact measurement vendors | ★★★☆☆ |
| **Municipality (Ward Office)** | LOW — bureaucracy, no legal mandate to buy | ₹100K-1M/year | 6-12 months | Existing SCM systems | ★★☆☆☆ |
| **Recycling Partner** | MED — needs volume, not software | Revenue share | 3-6 months | Their own operations tools | ★★☆☆☆ |
| **Corporate ESG** | MED — reporting need, but slow procurement | ₹50K-200K/month | 3-6 months | ESG reporting platforms | ★★★☆☆ |
| **Hotel/Hospitality** | LOW — not a pain point | Low priority | — | — | ★☆☆☆☆ |

---

## Primary Hypothesis: Apartment Association (RWA)

**Why RWA is the fastest buyer:**

1. **Direct operational pain**: RWAs are responsible for segregation compliance under SWM Rules 2016. Municipalities can fine societies for improper segregation.
2. **Existing budget**: RWAs have a common maintenance fund. Spending ₹10K-50K/month on waste management software is within discretionary authority.
3. **Concentrated user base**: One RWA deal = 50-500 apartment units = instant user acquisition.
4. **Short decision chain**: Committee secretary can approve pilot budget without tender process.

**The pitch**: "Track your society's waste segregation, generate compliance reports, avoid municipal fines, and improve your Swachh Survekshan score."

**MVP surface for RWA pilot**:
- Society-level waste tracking (aggregate scans from resident users)
- Segregation quality score (manual + auto from classification data)
- Monthly report card PDF (English + local language)
- Collection regularity tracking
- Issue reporting (missed pickup, bin overflow)
- Admin dashboard (web or in-app) with 4 key metrics

**Pilot pricing**: ₹5,000/month for first 3 months (introductory), then ₹15,000/month.

---

## Secondary Hypothesis: School

**Why schools are worth pursuing:**

1. **Education mission alignment**: Waste classification is directly relevant to environmental science curriculum.
2. **CSR funding**: Many schools have CSR/community engagement budgets for eco-initiatives.
3. **Parent engagement**: School-led waste tracking drives parent installs.
4. **Low churn**: Academic year contracts, not month-to-month.

**The pitch**: "Make environmental science hands-on. Students learn waste segregation, track their school's waste, and compete in class challenges."

**MVP surface for school pilot**:
- Classroom/group accounts (teacher admin, student participants)
- Quiz integration (knowledge verification tied to curriculum)
- Class-level waste tracking leaderboard
- Printable certificates for participation
- No ads, no public community (child-safe)

**Pilot pricing**: ₹3,000/month per school (up to 500 students).

---

## Tier: CSR / Grant Funded

**Why CSR is the highest revenue potential:**

1. **Compliance need**: Companies need audited, verified impact data for CSR reporting under Companies Act 2013.
2. **Budget availability**: CSR budgets are already allocated and need to be spent.
3. **Multi-year contracts**: CSR partnerships can run 1-3 years.

**The pitch**: "Fund waste management education in 100 schools. We deliver verified impact reports showing kg waste diverted, students educated, and behavior change metrics — all audit-ready."

**Surface needed**:
- Program dashboard (aggregate across schools/societies)
- Impact verification reports (audit trail for CSR compliance)
- White-label / co-branded report cards
- API or regular CSV export for internal ESG systems

**Pricing**: ₹200K-1M/year per program depending on scale.

---

## Buyer Segmentation by Location

| Location | Primary Buyer | Accessibility | Notes |
|----------|--------------|---------------|-------|
| Bangalore (BBMP area) | RWA | EASY — many tech-savvy RWAs already using apps | Primary pilot market |
| Bangalore (BMC wards) | RWA | EASY | — |
| Mumbai (BMC) | RWA | MEDIUM — large societies, harder decision chain | Expansion market |
| Delhi (MCD) | School | MEDIUM — many schools interested in eco-programs | Education wedge |
| Tier 2 cities | School / CSR | HARD — less digital adoption | Future |

---

## Pricing Model Options

| Model | RWA | School | CSR | Municipality |
|-------|-----|--------|-----|-------------|
| Per-building/month | ✅ ₹10-50K | — | — | — |
| Per-school/month | — | ✅ ₹3-15K | — | — |
| Per-program/year | — | — | ✅ ₹200K-1M | — |
| Per-ward/month | — | — | — | ✅ ₹50-200K |

---

## Risk & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| RWA budget inadequate | Medium | Medium | Price floor of ₹10K/month; upsell analytics |
| School procurement slow | High | Low | Start with free pilot → paid upgrade |
| CSR requires audited methodology we don't have | Medium | Medium | Build impact methodology doc before CSR outreach |
| Municipality buys from existing vendor | Low | High | Differentiate on resident engagement data they don't have |
| RWA churns after 3 months | Medium | Medium | Contract lock-in + demonstrated compliance value |

---

## Immediate Next Steps

1. **Validate RWA pricing**: Talk to 3-5 Bangalore RWAs to confirm ₹10K-15K/month is acceptable.
2. **Choose pilot partner**: Identify one RWA with tech-savvy committee and existing waste management interest.
3. **Build MVP pilot surface**: Society-level tracking + monthly report card (4 weeks engineering).
4. **Close first deal**: Offer 3-month introductory pricing, convert to paid at month 4.
5. **Document case study**: Use pilot results to sell to next 5 RWAs.

---

## Kill Criteria

This track is de-prioritised if:

- No RWA/School pilot buyer found within 3 months of active sales effort.
- First 3 pilot buyers all churn before paid conversion.
- Engineering cost to build admin surface exceeds 8 weeks of dedicated work.
- Core app (scan + classify + disposal) retention is below threshold — fix core first.

---

## Open Questions

- Should B2B data sharing be a separate app/site or an in-app admin mode?
- Do we need SOC2 or similar certification for CSR/enterprise buyers?
- What is the minimum team needed to support B2B sales (1 founder-led sale + 1 part-time support)?
- Should we build our own admin dashboard or embed Google Data Studio / Metabase for the paid tier?
