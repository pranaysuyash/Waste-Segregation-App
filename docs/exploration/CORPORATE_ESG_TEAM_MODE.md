# Corporate ESG / Team Sustainability Mode

**Status**: Draft — no code surface for corporate/team mode exists yet.
**Priority**: P2 (longer-term B2B revenue path)
**Related**: [B2B_ENTERPRISE_WEDGE.md](B2B_ENTERPRISE_WEDGE.md), [CIVIC_B2B_B2G_VALIDATION.md](CIVIC_B2B_B2G_VALIDATION.md), Workplace/Office Mode (entry in school/classroom cluster)
**Last Updated**: 2026-05-25

---

## Why This Is a Topic

Corporate sustainability teams have growing mandates and budgets:

1. **ESG reporting requirements** — publicly listed companies in India (SEBI BRSR), EU (CSRD), and US (SEC climate rules) must report environmental metrics. Employee waste behaviour data feeds these reports.
2. **Employee engagement** — sustainability programs improve retention (especially Gen Z/millennial) and provide positive PR.
3. **CSR budget alignment** — Indian companies have mandatory CSR spend (2% of net profit). Waste/sustainability programs qualify.
4. **Office waste audits** — baseline measurement is the first step; companies need tools.

However, corporate sales cycles are long, procurement is complex, and per-seat pricing may not work for low-engagement tools.

---

## Corporate Mode: Core Concept

An office version of the app where:

- Company signs up as an organization.
- HR/CSR admin creates campaigns and challenges.
- Employees opt in (mandatory participation is toxic — must be voluntary).
- Data is anonymized and aggregated at the team/department level.
- Impact reports are auto-generated for CSR/ESG compliance.

---

## Feature Surface

### Phase 1: Employee Engagement

| Feature | Description |
|---------|-------------|
| **Anonymous opt-in** | Employee joins via company code, no personal data shared with employer |
| **Team challenges** | Department vs department — "Which team diverts the most this quarter?" |
| **Personal impact tracking** | Employee sees their own diversion, C02 estimate, waste reduced |
| **Aggregated leaderboard** | Team-level only — no individual ranking visible to company admin |
| **Badge system** | Milestone badges: "50 items classified", "Zero-waste week", "Hazardous-aware" |

### Phase 2: CSR & ESG Reporting

| Feature | Description |
|---------|-------------|
| **Monthly impact report** | Auto-generated PDF: total items classified, diversion estimate, participation rate by team |
| **Material breakdown** | What materials are employees encountering most? What's going to landfill vs recycling? |
| **Contamination rate** | % of items incorrectly sorted — a proxy for education effectiveness |
| **CSR story cards** | Shareable infographic for annual CSR report |
| **Benchmarks** | How does this company compare to industry peers (anonymized)? |

### Phase 3: Strategic Integration

| Feature | Description |
|---------|-------------|
| **Office waste audit baseline** | One-time scan of office waste output by category |
| **Procurement insights** | Aggregated packaging data → inform office procurement decisions (reduce single-use, switch to recyclable) |
| **Green team coordination** | Volunteer coordination for office cleanups, e-waste drives, compost initiatives |
| **API/data export** | Export to ESG reporting platforms (GRI, SASB, BRSR format) |

---

## Privacy & Trust Model

Corporate mode has a unique privacy challenge: employees must trust that their individual data is not visible to their employer.

### Absolute Rules

1. **Company never sees individual employee data.** Only team-aggregated (min 5 members) or company-aggregated.
2. **Company cannot see correction history, quiz performance, or individual scores.**
3. **Employee joins anonymously** — no email-to-profile matching. Company sees only "Employee #A7B3" or their team name.
4. **No location tracking of employee disposal.**

### Enforcement

- Data aggregation is server-enforced, not client-enforced. Firestore security rules prevent access to individual employee documents by company-admin roles.
- Company admin's Firestore query returns only aggregated stats (via backend function, not direct client read).
- Employee can leave the corporate program at any time — their data is immediately excluded from future reports (historical aggregate remains, which is acceptable by design).

---

## Pricing Model Hypothesis

| Tier | Price | What's Included |
|------|-------|-----------------|
| **Free** | ₹0 | Up to 50 employees, basic challenges, aggregated dashboard |
| **Team** | ₹X/month | Up to 200 employees, monthly CSR report, team leaderboards |
| **Enterprise** | Custom | Unlimited, full ESG/BRSR reporting, API access, dedicated support |

### More Likely Alternative: Tier 0 is free for all, upsell is paid CSR reports and data exports.

Companies will pay for compliance-ready reports. They won't pay for employee engagement tools that feel optional.

---

## B2B Sales Cycle Reality

From [CIVIC_B2B_B2G_VALIDATION.md](CIVIC_B2B_B2G_VALIDATION.md) — corporate ESG is **not** the shortest sales cycle:

| Buyer | Cycle | Probability of Close |
|-------|-------|---------------------|
| RWA/society | 1–2 weeks | High |
| School | 1–2 months | Medium |
| Corporate ESG | 3–6 months | Low (unless warm intro) |
| Municipality | 6–12+ months | Very low (unless tender) |

**Recommendation**: Do not lead with corporate ESG. Lead with RWA and school pilots. Corporate ESG is a Phase 2 extension once the product has proven impact data.

---

## Eco-Data Product (Frontier)

The most valuable long-term corporate product is not the employee engagement tool — it's the **anonymized, aggregated waste-pattern data** that the employee base generates:

- What packaging types confuse consumers most?
- Which materials are most often mis-sorted in office settings?
- What time of year does e-waste generation peak?

This data is valuable to:
- **Brands** for packaging redesign
- **Recyclers** for material flow prediction
- **Municipalities** for policy planning

However, this requires explicit consent, robust anonymization, and a clear data-usage contract. Not P0–P2. Frontier bet.

---

## Open Questions

1. **Ad-supported free tier for companies?** Unlikely to work — companies paying for ESG tools expect ad-free.
2. **On-premise vs cloud data?** Some corporates may require on-premise or "India-only" data storage for compliance.
3. **Integrations** — which ESG/reporting platforms should the app target first (GRI, SASB, BRSR)?
4. **Employee churn** — what happens to data when an employee leaves the company? Proposal: data stays in aggregate, individual profile is archived.

---

## Related Work

- [B2B_ENTERPRISE_WEDGE.md](B2B_ENTERPRISE_WEDGE.md) — B2B sales model, buyer prioritization
- [CIVIC_B2B_B2G_VALIDATION.md](CIVIC_B2B_B2G_VALIDATION.md) — buyer matrix and pilot validation
- [PERSONAL_IMPACT_DASHBOARD_UX.md](PERSONAL_IMPACT_DASHBOARD_UX.md) — impact visualization shared by both consumer and corporate users
- [CARBON_IMPACT_ACCOUNTING.md](CARBON_IMPACT_ACCOUNTING.md) — methodology for impact numbers
