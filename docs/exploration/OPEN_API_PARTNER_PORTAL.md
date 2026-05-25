# Open API & Partner Portal

**Status**: Seed — P2, not yet funded
**Last Updated**: 2026-05-26
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Item 78
**Related**: CIVIC_AUTHORITY_SHARING.md, CIVIC_B2B_B2G_VALIDATION.md, DISPOSAL_FACILITIES_DIRECTORY.md, CIVIC_ISSUE_REPORTING.md

---

## 1. Why This Matters

An open API turns the app's data (disposal rules, facility directory, schedule information, anonymised impact) into a platform that other services can build on. For a mission-driven product, an API can:

- **Accelerate civic impact**: Municipalities, NGOs, and researchers can consume the app's data directly.
- **Enable partner ecosystems**: Recyclers, schools, brands, and other apps can integrate disposal advice into their own experiences.
- **Generate revenue**: API access tiers (free for civic/NGO, paid for commercial).
- **Create moat**: The more partners depend on the app's data, the harder it is to replace.

---

## 2. Partner Types & Data Needs

| Partner Type | Data They Want | Value to Them | Value to Us |
|-------------|----------------|---------------|-------------|
| **Municipalities** | Disposal rules, facility directory, collection schedules, issue reports | Better citizen information, operational intelligence | Civic credibility, channel distribution |
| **Recyclers** | Facility data freshness, user disposal patterns (anonymised), incoming volume estimates | Operations planning, capacity management | Data partnerships, referral revenue |
| **Schools/NGOs** | Classroom challenge data, impact summaries, educational content | Curriculum integration, impact reporting | Distribution (one teacher → 30 families) |
| **Brands/Manufacturers** | Anonymised disposal confusion trends, packaging misclassification rates | Packaging redesign, ESG reporting | Revenue, brand partnership |
| **Researchers** | Anonymised data exports | Academic research | Credibility, citations, free data quality analysis |
| **Other apps** | Disposal advice API, facility lookup endpoint | Add waste guidance to their app | Distribution, referral traffic |

---

## 3. API Surface Areas (By Priority)

### Tier 1: Read APIs (MVP)

| Endpoint | Description | Auth |
|----------|-------------|------|
| `GET /v1/cities` | List supported cities with ruleset versions | API Key |
| `GET /v1/cities/{id}/rules` | Disposal rules for a jurisdiction | API Key |
| `GET /v1/facilities` | Disposal facilities with location, hours, accepted materials | API Key (public) |
| `GET /v1/materials` | Supported material categories with labels | API Key |
| `GET /v1/collection-schedules` | Collection schedules by zone/pincode (where available) | API Key |

### Tier 2: Write APIs (Partner)
| Endpoint | Description | Auth |
|----------|-------------|------|
| `POST /v1/facilities` | Submit facility update/correction | API Key (verified) |
| `POST /v1/rules` | Submit rules update (municipal partner) | OAuth (admin) |
| `POST /v1/reports` | Submit civic issue report programmatically | API Key (verified) |

### Tier 3: Analytics APIs (Premium)
| Endpoint | Description | Auth |
|----------|-------------|------|
| `GET /v1/analytics/disposal-trends` | Aggregated disposal pattern data | OAuth (commercial) |
| `GET /v1/analytics/misclassification` | Category-level misclassification rates | OAuth (commercial) |
| `GET /v1/analytics/participation` | User engagement metrics (anonymised) | OAuth (commercial) |

---

## 4. API Governance

### 4.1 Versioning
- URI-based versioning (`/v1/`, `/v2/`) for major breaking changes.
- Header-based versioning for minor non-breaking additions.
- Deprecation: "Sunset" header in responses, 6-month deprecation notice before removal.

### 4.2 Authentication
- **Tier 1 (Public)**: API Key (simple, self-service via portal).
- **Tier 2 (Partner)**: OAuth 2.0 with scoped permissions.
- **Tier 3 (Premium)**: OAuth 2.0 + signed requests + usage tracking.

### 4.3 Rate Limiting
- Free tier: 1,000 requests/day, 10 req/min.
- Standard: 10,000 requests/day, 60 req/min.
- Enterprise: Negotiated.

### 4.4 Documentation
- OpenAPI 3.0 spec auto-generated from code.
- Hosted on a dedicated docs subdomain (e.g., `developers.reloop.app`).
- Interactive playground for each endpoint.

---

## 5. Privacy & Safety

### 5.1 Data Anonymisation
- All API data is aggregated or anonymised before reaching the API layer.
- No individual user data (scan history, identity, location traces) available via public API.
- Partner-specific APIs require explicit user consent scope.

### 5.2 Consent Gating
- If a user's data flows through the API (e.g., school parent opting into classroom dashboard), consent is collected at the time of association, not via blanket TOS.
- Revocation: When a user withdraws consent, API data for that user stops flowing within a defined SLA (24h).

### 5.3 Differential Privacy
- For sensitive metrics (neighbourhood-level contamination rates), add calibrated noise to prevent re-identification.
- Small-count suppression: any cell with <5 contributing users is suppressed.

---

## 6. Minimum Viable Portal

### Phase 1: Documented API + Manual Access
1. **Publish OpenAPI spec** on GitHub or a simple docs page.
2. **Manual API key issuance**: Interested partners request via email or form.
3. **Support**: Dedicated `partners@reloop.app` email.
4. **Scope**: Read-only endpoints (cities, rules, facilities, materials) — the most useful data with the lowest risk.

### Phase 2: Self-Service Portal
1. Developer registration + automatic API key generation.
2. Usage dashboard (requests, rate limit status, error logs).
3. Documentation with interactive playground.
4. When Phase 1 generates verifiable partner interest and the manual bottleneck becomes clear.

### Phase 3: Partner Marketplace
1. Commercial tier with billing and SLAs.
2. Write-api access for verified partners.
3. Analytics and reporting APIs for commercial customers.
4. Only when there are 3+ paying commercial API customers.

---

## 7. Pricing Model

| Tier | Price | Includes |
|------|-------|----------|
| **Civic/NGO/Academic** | Free | Read APIs, 1K req/day, non-commercial |
| **Standard** | $50–200/mo | Read APIs, 10K req/day, commercial use |
| **Enterprise** | Custom | Read + write APIs, analytics, SLA, dedicated support |

**Pricing principles**:
- Never charge civic partners (municipalities, schools, NGOs) for core data access.
- Commercial API revenue should fund civic API infra, not extract from it.

---

## 8. Kill Criteria

- No verifiable partner interest in API access after publishing the specification.
- API maintenance cost exceeds value delivered (security reviews, docs updates, support burden).
- Privacy/compliance review finds acceptable data-sharing architecture requires more investment than the partnership pipeline justifies.
- Municipal/NGO partners prefer direct data exports (CSV, PDF) over API integration — in which case the API can wait while the data-sharing feature ships as exports.
