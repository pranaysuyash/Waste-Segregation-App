# Public-Good Open Data Layer — Exploration Doc

**Track**: P3 — Deep Frontier
**Status**: 🟢 Exploration
**Last Updated**: 2026-05-24
**Parent**: [EXPLORATION_TOPICS.md #84](../EXPLORATION_TOPICS.md#84-public-good-open-data-layer-)
**Sibling topics**: Verified Impact Ledger (#82), Civic Issue Reporting (L2), Civic Authority Sharing (L5), Municipal APIs (#25), Industry Competitive Landscape (A25)

---

## Decision This Unblocks

Whether to publish anonymized, aggregated waste-disposal data as a public good — and what data is safe to publish, who benefits, and what risks must be addressed.

---

## Overview

A waste classification app generates a uniquely valuable dataset: **real-world disposal behavior at item-level granularity, tagged by geography, time, and material.** This data, properly anonymized and aggregated, has public benefit:

- **Researchers**: Study consumption patterns, recycling behavior, contamination trends.
- **Municipalities**: See real collection needs, not survey-based estimates.
- **Citizens**: Understand their neighbourhood's disposal trends for advocacy.
- **Brands / manufacturers**: See how their packaging actually gets disposed (via F8, not open data).

**The thesis**: Publishing non-sensitive, aggregated data as a public good builds trust, attracts academic/NGO partnerships, and strengthens the product's positioning as a mission-driven utility, not just a for-profit app.

---

## What Data Can Be Published

### SAFE to publish (low privacy risk)

| Dataset | Aggregate Level | Update Cadence | License |
|---------|----------------|----------------|---------|
| Per-city top-10 waste categories | City-level, monthly | Monthly | CC BY 4.0 |
| Contamination rate by category | City-level, monthly | Monthly | CC BY 4.0 |
| Day-of-week disposal volume patterns | City-level, quarterly | Quarterly | CC BY 4.0 |
| Disposal method distribution (recycle/compost/landfill) | City-level, quarterly | Quarterly | CC BY 4.0 |
| Average items classified per user per week | City-level, quarterly | Quarterly | CC BY 4.0 |
| Hazardous waste category frequency | City-level, quarterly | Quarterly | CC BY 4.0 |
| User correction patterns (where the app was wrong) | City-level, quarterly | Quarterly | ODbL |

### NEVER publish (even aggregated)

| Data | Risk |
|------|------|
| Individual user history | ❌ Identifiable |
| Individual user location | ❌ Identifiable even at "neighbourhood" level if household is unique category |
| Raw photos | ❌ PII, faces, homes |
| Individual correction data | ❌ Reveals user knowledge gaps |
| Facility-level data from user uploads | ❌ May expose private recycling info |
| Store/purchase-level data | ❌ Procurement habit inference |

### GRAY area — publish with care

| Dataset | Mitigation |
|---------|------------|
| Neighbourhood-level contamination heatmaps | Minimum 20 users per hexbin; never drop below 20. Coarse grid (1km²+). |
| Temporal trends per ward | Only if ward has 50+ active users. Suppress any ward where a single user dominates (> 40% of classifications). |
| Correction rate per category | Divisible only by category, never by user segment that could re-identify. |
| Brand-level packaging frequency | Only if 100+ classifications of that brand across 20+ unique users. |

---

## Data Format

### V1 (Minimum Viable — CSV on GitHub)

```
Repository: github.com/reloop-project/open-data

releases/
├── v1-2026-Q1/
│   ├── README.md          — methodology, license, change log
│   ├── bangalore_2026_q1.csv
│   ├── mumbai_2026_q1.csv
│   ├── delhi_2026_q1.csv
│   ├── schema.md          — column definitions, units, sources
│   └── aggregation_script.py  — how we produced these numbers
└── CHANGELOG.md
```

**CSV schema**:

```csv
city,quarter,category,total_classifications,recycle_pct,compost_pct,landfill_pct,contamination_pct,avg_confidence,unique_users
Bangalore,2026-Q1,plastic_bottle,12742,0.73,0.02,0.25,0.08,0.92,3841
Bangalore,2026-Q1,newspaper,8934,0.88,0.00,0.12,0.03,0.95,2910
...
```

### V2 (API)

- Read-only REST API.
- Rate-limited (100 req/min per IP).
- Requires API key for tracking (free for non-commercial).
- Returns JSON matching the CSV schema.

---

## Aggregation Privacy Script

Before any data enters the public dataset:

```python
def privacy_gate(df, collection):
    """Ensure no row has fewer than MIN_USERS unique users."""
    MIN_USERS = 20
    df = df[df['unique_users'] >= MIN_USERS]
    
    # Check for user dominance (one user > 40% of contributions)
    user_dominance = df.groupby('segment')['user_id_majority'].max()
    dominant_segments = user_dominance[user_dominance > 0.4].index
    df = df[~df['segment'].isin(dominant_segments)]
    
    # Check 5+ users contributed to each data point
    return df
```

**Automated in CI**: The aggregation script runs in GitHub Actions. A human reviews the output before publishing.

---

## Licensing

| License | Appropriate For |
|---------|----------------|
| CC BY 4.0 | Aggregate stats, methodology docs, trend data |
| ODbL (Open Database License) | Derived datasets, correction patterns data |
| PDDL (Public Domain Dedication) | Not recommended — waives all attribution rights |

**Recommendation**: CC BY 4.0 for all V1 datasets. Require attribution + share-alike for any derived commercial use.

---

## Risks and Mitigations

| Risk | Likelihood | Severity | Mitigation |
|------|-----------|----------|------------|
| Neighbourhood stigma from contamination data | Medium | High | Publish at city-level only in V1. Ward-level only with 50+ active user minimum. |
| Competitive intelligence for other apps | High | Low | Competitors could use our data to guide their product. Acceptable — this is public-good data. |
| Re-identification attempt | Low | Critical | Privacy gates, minimum user thresholds, no raw data. Annual re-identification risk audit. |
| Municipal backlash if data shows mismanagement | Low | Medium | Frame data as "citizen-reported patterns" not city performance metrics. Disclaim methodology limits. |
| License misinterpretation (commercial use of our data) | Medium | Low | CC BY 4.0 allows commercial use. Acceptable — public data should be usable by all. |
| Data quality too poor to be useful | Medium | Medium | Publish methodology openly. Include uncertainty bounds. Let users judge quality. |

---

## Beneficiaries

| Audience | What They Get | Value |
|----------|-------------|-------|
| Academic researchers | Anonymized waste behavior trends | Research validation |
| Municipal waste departments | Real-world disposal patterns by category | Better collection planning |
| Environmental NGOs | Data for advocacy campaigns | Evidence-based policy push |
| Citizens | "What does my city throw away?" | Awareness + accountability |
| Other civic tech teams | Baseline for their own community data | Reuse + reference |
| Media | Data for environmental reporting | Accurate stories |
| **Competitors** | Public-data-constrained benchmarking | Acceptable cost |

---

## Kill Criteria

1. **No external requests** for open data within 12 months of publishing V1.
2. **Privacy incident** from a re-identification attempt (force immediate kill and review).
3. **Data quality is so poor** (contamination rates differ from known municipal data by > 40%) that publishing does reputational harm.
4. **Legal review** concludes publishing even aggregated data carries unacceptable risk under Indian data protection rules (DPDP Act).

---

## Concrete Next Steps

1. ✅ Do not publish open data yet. Wait for sufficient MAU to make aggregated data statistically meaningful.
2. **Trigger**: Publish V1 open data when:
   - Any single city has > 10K unique users AND > 100K classifications.
   - OR a researcher/NGO formally requests data.
   - OR a municipal partner asks for aggregated trends.
3. Write the aggregation script and privacy gate before the trigger (can be done as a build-tool feature).
4. Set up `reloop-project/open-data` GitHub repository (empty with README).
5. Annual re-identification risk audit once data is published.

---

## Similar Efforts

| Project | Data | License | Status |
|---------|------|---------|--------|
| OpenStreetMap | Crowdsourced geographic data | ODbL | ✅ Thriving |
| Aclima | Hyperlocal air quality sensor data | CC BY 4.0 | ✅ Active |
| AirNow (EPA) | Real-time air quality | Public domain | ✅ Active |
| NYC Open Data | Municipal waste tonnage by borough | Public domain | ✅ Active |
| ShareWaste | Composting site locations | Custom (open) | ✅ Active |
| OLCA / openLCA | Lifecycle assessment databases | Various ODbL | ✅ Active |

---

## Research Sources

- CC BY 4.0 (Creative Commons) — standard open data license for attribution-based sharing.
- Open Data Commons ODbL — database-specific open license.
- DPDP Act 2023 (India) — personal data protection requirements for publishing anonymized data.
- NYC Open Data — reference implementation of municipal waste data as public good.
- Aclima — private environmental sensor company publishing open data at scale.
- OpenStreetMap Foundation — governance model for community-maintained open data.
- Privacy by Design (Cavoukian) — 7 foundational principles for privacy-safe data publishing.
