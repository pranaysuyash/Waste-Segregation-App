# Civic Authority Sharing — Data Formats, Report Cards & Multi-Language

**Status**: Seed — no implementation
**Priority**: 🟢 (P2 — civic intelligence track)
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Section F: Locality & Civic Waste Intelligence (L5)
**Related**: [CIVIC_B2B_B2G_VALIDATION.md](CIVIC_B2B_B2G_VALIDATION.md), [DISPOSAL_FACILITIES_DIRECTORY.md](DISPOSAL_FACILITIES_DIRECTORY.md), [CIVIC_ISSUE_REPORTING.md](CIVIC_ISSUE_REPORTING.md)

---

## Overview

The civic data layer earns its keep when some buyer pays for it — or some authority acts on it. This doc covers the **sharing surface**: how civic data gets formatted, localized, and delivered to different stakeholders (municipalities, RWA committees, NGOs, school administrators).

This is the UX side of the authority relationship. The business/sales side is in [CIVIC_B2B_B2G_VALIDATION.md](CIVIC_B2B_B2G_VALIDATION.md).

---

## Data Formats by Stakeholder

| Stakeholder | Primary Format | Secondary Format | Channel |
|-------------|---------------|-----------------|---------|
| Municipality / Ward office | PDF report | CSV download | Email, WhatsApp |
| RWA committee | One-page PDF/image | WhatsApp-forwardable summary | In-app share |
| School admin | Dashboard link | Printable certificate PDF | Email, in-app |
| NGO / CSR partner | CSV/Excel export | Dashboard embed | API or email |
| Residents (individual) | In-app stats card | Social share image | In-app share |

**Design principle**: meet each stakeholder in their native format. Don't force authorities to adopt a dashboard if they operate by PDF.

---

## Report Card Design

### Apartment/Society Waste Report Card

A single-page PDF optimized for WhatsApp sharing in resident groups:

**Metrics** (visual, color-coded):
- Segregation quality score (Green/Yellow/Red)
- Waste diverted from landfill (kg)
- Contamination rate (% wrong bin)
- Collection regularity (% of scheduled pickups completed)
- Community rank (compared to other societies in ward)

**Structure**:
1. Header: Society name, month/year, overall grade (A+ through F)
2. Metric cards: 4 key numbers with icons
3. Trend arrow: up/down/flat compared to previous month
4. Action items: "Top 3 things to improve this month"
5. QR code: link to in-app dashboard for detail

### Multi-Language Generation

**Tier 1** (MVP): English only with Kannada key terms in parentheticals
**Tier 2**: Full Kannada and Hindi report cards using LLM translation
**Tier 3**: Local language complaint/report generation + voice-to-text input in Kannada/Hindi

LLM approach: template-based report with localized fields, not freeform generation. Reduces hallucination risk.

---

## Complaint/Report Generation for Indian Market

**Feature**: "Generate complaint letter" from civic issue report.

- Auto-generates formal complaint in Kannada, Hindi, or English
- Includes: issue details, location, date, photo evidence (if available), expected action
- Output: downloadable PDF or WhatsApp-forwardable text
- Target audience: BBMP ward office, police (illegal dumping), pollution control board (hazardous)

**Template structure**:
```
To: [Authority Name]
Subject: Complaint regarding [issue type] at [location]
Date: [date]

Respected Sir/Madam,

This is to bring to your attention that [issue description] has been observed at [address] since [date]. [Evidence: photo(s) attached]. 

This is causing [impact: health hazard / environmental damage / inconvenience].

Request your immediate intervention to resolve this issue.

Sincerely,
[User name]
[Contact]
[Ward number]
```

---

## Implementation Path

1. **Phase 0**: English-only report card PDF generation. Single society/metrics view.
2. **Phase 1**: Add Kannada + Hindi translation via LLM. Complaint letter generation.
3. **Phase 2**: QR code → dashboard link. CSV/Excel export for admin users.
4. **Phase 3**: Automated monthly report card delivery (email/WhatsApp). White-label for partners.

---

## Open Questions

- Should report cards be generated app-side (Flutter PDF) or server-side (Firebase Functions + Puppeteer)?
- What is the legal status of an automatically generated complaint letter? Does it need user review before sending?
- How do we handle data export for municipalities that want real-time API access vs periodic CSV delivery?
- Should we offer a free tier with basic report cards and a paid tier with admin dashboard + custom branding?
