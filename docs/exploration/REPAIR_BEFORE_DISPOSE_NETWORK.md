# Repair-Before-Dispose Network

**Status**: Exploration | P2 | Circular Economy & Pre-Waste Intervention
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Entry 48
**Last Updated**: 2026-05-25

---

## Why This Matters

"Can I recycle this?" is the user's second question. The first should be: **"Do I need to dispose of this at all?"** A repair-before-dispose network intercepts waste at the highest-leverage moment — before an item even enters the waste stream.

Repair is not just environmental; it's economic. The EU's Right-to-Repair legislation, France's repairability index, and growing consumer awareness make this a timely product surface.

---

## Network Models

### 1. Repair Café / Event Directory

- **Model**: Community-led, volunteer-based, non-commercial repair events
- **Format**: Local directory with event calendar, categories accepted (electronics, textiles, furniture, appliances)
- **Trust signal**: Volunteer reputation, event history, city affiliation
- **Comparable models**: [Repair Café International](https://repaircafe.org), Fixit Clinics

### 2. Local Technician Directory

- **Model**: For-fee independent repair professionals
- **Format**: Searchable directory with specialization categories, ratings, service area
- **Trust signal**: Verified reviews, certification badges, warranty offered
- **Comparable models**: iFixit's "Find a Pro", local handyman platforms

### 3. Manufacturer / Authorised Service Bridge

- **Model**: Link to official warranty repair channels
- **Format**: Deep links to manufacturer service portals
- **Use case**: Items still under warranty — user shouldn't pay for repair
- **Data needed**: Warranty status, purchase date, serial number

---

## Right to Repair — Regulatory Landscape

| Jurisdiction | Key Regulation | Implication for App |
|-------------|---------------|---------------------|
| EU | Repair Score (France) | Surfacing repairability scores at scan time |
| EU | ESPR / DPP | Spare parts availability, disassembly documentation |
| EU | Right-to-Repair Directive (2024) | Manufacturer obligation to provide parts/tools |
| India | E-Waste Rules | EPR obligations, collection targets |
| US (state) | Digital Fair Repair Act | Independent repair access |

**App opportunity**: Become the consumer-facing bridge to R2R data — surface repair scores, find parts, connect to repair networks.

---

## Repair vs Replace Triage

The 50% rule is industry standard:

| Factor | Favours Repair | Favours Replace |
|--------|---------------|-----------------|
| Cost | < 50% of replacement | > 50% of replacement |
| Age | Early-to-mid lifecycle | Near end of expected life |
| Sentimental value | High (heirloom, furniture) | Low (commodity) |
| Efficiency/tech | Minor fix needed | Major obsolescence |
| Warranty | Still under warranty | Expired |
| Spare parts | Available | Discontinued |

**In-app triage flow**:
1. What's the item (category, approximate age)?
2. What's wrong? (battery, screen, mechanical, cosmetic)
3. Is it under warranty? → Route to manufacturer
4. Estimate repair cost vs replacement → Suggestion with nearby resources

---

## Trust & Verification

| Signal | How It Works |
|--------|-------------|
| Verified reviews | User reviews with photo evidence of completed repair |
| Volunteer reputation | Hours contributed, event history, certifications |
| iFixit integration | Open-source guides as trusted reference |
| Community verification | "Is the repair cafe still active?" Waze-style freshness |
| Quality guarantee | Technician-offered warranty on repair work |

---

## Integration Points

| Surface | What to Show |
|---------|-------------|
| Scan result — electronics | "This item could be repaired. Find repair options near you." |
| Scan result — textiles | "Button missing? Zipper stuck? Local tailoring/repair options." |
| Disposal guidance | "Before recycling, consider: can this be repaired?" |
| Home screen widget | "Nearby repair events this weekend" |
| Community tab | User-submitted repair success stories |

---

## Open Questions

1. **Sourcing**: Should the directory be crowdsourced (user-submitted + verified) vs partner-supplied vs scraped?
2. **Coverage**: In a new market (Indian city), are repair café networks dense enough to be useful?
3. **Economic viability**: Does the repair option motivate behaviour change, or is replacement cheaper in practice?
4. **Liability**: If we recommend a technician and they do poor work, does the app bear any responsibility?
5. **Anti-spam**: How to prevent fake repair listings from SEO spam businesses?

---

## Phasing

| Phase | Scope | Data Source | Launch |
|-------|-------|-------------|--------|
| 0 | Repair vs replace triage flow with general advice | Static rules, no directory | Quick win — no data dependency |
| 1 | iFixit repair guide links per category | iFixit API | Integrate existing directory |
| 2 | Crowd-sourced repair café/technician directory | UGC + moderator review | Requires moderation foundation |
| 3 | Warranty check integration (receipt scan → warranty lookup) | Receipt data | Privacy-dependent |
| 4 | Book repair appointment in-app | Direct partner booking | Requires partner commitment |
