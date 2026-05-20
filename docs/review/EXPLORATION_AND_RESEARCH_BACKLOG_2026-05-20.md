# Exploration & Research Backlog — Locality & Civic Waste Intelligence

**Date**: 2026-05-20
**Status**: New exploration track — Seed / not P0
**Track lane**: Research & exploration only. **Do not** merge into launch hardening or token-economy P0 work.
**Author intent**: Captured from user addendum 2026-05-20 ("Locality, Collection Intelligence, Civic Reporting, and Community Verification Track") and reconciled with the existing exploration map.

---

## 0. Purpose & Lane Discipline

This document seeds a new long-horizon exploration theme:

> **Local Waste Intelligence and Civic Reporting Network** — locality-aware collection schedules, map-based civic reporting, Waze-style verification, community trust/points, and authority/B2B/B2G dashboards.

It is **not** an immediate launch deliverable. It must stay in the exploration/research lane until:

- the core "scan → classify → disposal guidance" loop is launched and revenue is validated,
- a privacy/moderation foundation exists that can survive civic-reporting risk,
- the token economy (`TOKEN_ECONOMY_TODO.md`) is settled so we never let civic points convert into paid AI tokens by accident.

Anything in this doc that gets pulled forward into launch P0 must go through a deliberate scope decision, not drift.

---

## 1. Existing Map — What This Track Reconciles With

This is an **addendum**, not a replacement. The existing exploration map already covers neighbouring surfaces; this track extends them rather than forking new parallel artefacts.

| Existing topic | Where | What it already covers | What this track adds |
|---|---|---|---|
| **A20. Disposal Facilities Directory** | [EXPLORATION_TOPICS.md#A20](../EXPLORATION_TOPICS.md) | Facility data sourcing, verification, offline cache | Civic *status* layer over facility records: "still open?", "still accepting?", user-verified timings |
| **A21. User Contribution / UGC Pipeline** | [EXPLORATION_TOPICS.md#A21](../EXPLORATION_TOPICS.md) | Contribution review pipeline, reputation, incentive design | New contribution *classes*: collection schedules, civic issue reports, "still there?" votes |
| **#20. Community Feed Trust Layer** | [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) | Social trust tiers, moderation | Civic-grade trust tiers ("verified local", "ward champion") + trust-weighted confidence |
| **#23. Moderation & Safety** | [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) | Image/comment moderation | Civic-report-specific risks: defamation, harassment of collectors, false-report harm |
| **#24. Smart-Bin Integration / QR Bin Layer** | [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) | QR-bin as cheapest "smart bin" | Public bin inventory + bin-fullness reports as a civic data layer |
| **#25. Municipal APIs (BBMP, etc.)** | [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) | Municipal partner outreach | The *product side* municipalities would consume — dashboards, exports, SLA tracking |
| **#26. Informal Collector Network** | [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) | Kabadiwala onboarding | Public-vs-personal contact data, route reliability, collector accountability |
| **#27a. Token Economy & Pricing Coherence** | [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) + `TOKEN_ECONOMY_TODO.md` | Paid AI-token mechanics | **Hard separation** — civic points are reputation, not currency |
| **#32. Privacy / Photo PII** | [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) | Face/PII redaction | Adds coarse-location publication, collector phone-number policy, exact-location authority gating |
| **#29. B2B / Enterprise Wedge** | [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) | School / corporate / hospitality / municipal wedge ranking | Apartment, NGO, CSR, contractor, ward-analytics buyer hypotheses |
| **Planning: `planning/local_recycling_directory.md`** | [planning/local_recycling_directory.md](../planning/local_recycling_directory.md) | Local directory data model + offline access | Civic *status* / *route* / *schedule* layer beneath the directory |
| **Code surface present today** | `lib/screens/disposal_facilities_screen.dart`, `facility_detail_screen.dart`, `community_screen.dart`, `lib/models/disposal_location.dart`, `lib/models/user_contribution.dart`, `lib/services/local_guidelines_plugin.dart` | Directory, community, contributions already exist | Civic-issue / schedule / verification surfaces are net-new |
| **Map stack present today** | `pubspec.yaml`: `flutter_map ^7.0.2`, `flutter_map_tile_caching ^9.1.4`, `flutter_map_marker_cluster ^1.4.0`, `flutter_map_heatmap ^0.0.8`, `geoflutterfire_plus ^0.0.32` | OSM tiles, clustering, heatmap, Firestore geohash queries — already pulled in | Track inherits this stack; no new geospatial vendor decision needed for MVP |

**Reading rule**: if anything below contradicts an existing topic or planning doc, the source artefact wins; update the source instead of forking a parallel truth here.

---

## 2. Refined Idea Map

```diagram
╭───────────────────────────────────────────────────────────────────────────────╮
│           LOCALITY & CIVIC WASTE INTELLIGENCE — REFINED IDEA MAP              │
├───────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  L1. LOCALITY DATA                       L2. CIVIC REPORTING                  │
│  ├── Schedules (dry/wet/haz/e-waste)     ├── Map-tap → photo → issue type     │
│  ├── Routes / wards / zones              ├── Issue lifecycle (state machine)  │
│  ├── Pickup timings + windows            ├── Geo-tag + coarse public location │
│  ├── Holiday / strike / weather notice   ├── Duplicate clustering             │
│  ├── Apartment-specific schedules        ├── Authority handoff (later)        │
│  └── Bulk + e-waste pickup calendar      └── Spam / false-report defence      │
│                                                                               │
│  L3. WAZE-STYLE VERIFICATION             L4. TRUST & POINTS (reputation only) │
│  ├── "Is this still here?" prompts       ├── Tiers: new → local → mapper →   │
│  ├── Lightweight responses (5–6)         │           ward champion → mod     │
│  ├── Proximity-triggered re-check        ├── Points per useful action         │
│  ├── Confidence decay over time          ├── Penalty for spam / duplicate     │
│  └── Trust-weighted aggregation          └── HARD SEPARATION from AI tokens   │
│                                                                               │
│  L5. AUTHORITY / B2B SHARING             L6. GEOSPATIAL + PRIVACY             │
│  ├── WhatsApp report card                ├── flutter_map + clustering + heat  │
│  ├── Email / PDF / public link           ├── geoflutterfire_plus already in   │
│  ├── CSV / API export                    ├── Coarse public / exact authority  │
│  ├── Municipality dashboard (later)      ├── EXIF strip + face/plate blur     │
│  └── SLA tracking (reported → resolved)  └── Offline tile cache (planned)     │
│                                                                               │
│  L7. ADJACENT EXPANSIONS (research candidates, not commitments)               │
│  ├── Public bin intelligence (inventory, fullness, damage)                    │
│  ├── Collection route reliability score                                       │
│  ├── Apartment / school / NGO modes                                           │
│  ├── Local marketplace (kabadiwala, compost, e-waste pickup partners)         │
│  ├── WhatsApp-first civic flow (share, local-language complaint text)         │
│  ├── Local-language reports (Kannada/Hindi/English + voice + icons)           │
│  └── Open civic API / anonymised public feed                                  │
│                                                                               │
╰───────────────────────────────────────────────────────────────────────────────╯
```

### Sequencing — what must come before what

```diagram
╭───────────────────────────╮
│ #32 Privacy / Photo PII   │  ← upstream of any public-facing civic surface
│ #23 Moderation & Safety   │
╰───────────────┬───────────╯
                │
                ▼
╭───────────────────────────╮     ╭───────────────────────────╮
│ A20 Disposal Facilities   │────▶│ L1 Locality Collection    │
│     Directory             │     │     Schedule Data         │
╰───────────────┬───────────╯     ╰───────────────┬───────────╯
                │                                 │
                ▼                                 ▼
╭───────────────────────────╮     ╭───────────────────────────╮
│ A21 UGC Pipeline          │────▶│ L2 Map-Based Civic        │
│     (extend with civic    │     │     Issue Reporting       │
│      contribution classes)│     │     (pilot scope only)    │
╰───────────────┬───────────╯     ╰───────────────┬───────────╯
                │                                 │
                ▼                                 ▼
╭───────────────────────────╮     ╭───────────────────────────╮
│ L4 Trust & Points         │◀───▶│ L3 "Still there?"         │
│ (reputation, NOT $$)      │     │     Verification Loop     │
╰───────────────┬───────────╯     ╰───────────────────────────╯
                │
                ▼
╭───────────────────────────╮     ╭───────────────────────────╮
│ L5 Authority / B2B        │────▶│ #29 B2B Wedge / #25       │
│     Sharing & Export      │     │     Municipal APIs        │
╰───────────────────────────╯     ╰───────────────────────────╯
```

**Iron rules from this diagram**:

1. **No civic public surface ships before #32 + #23** have a working privacy/moderation answer. Civic reporting can defame, harass, or endanger real people.
2. **No civic points convert to paid AI tokens.** Period. Civic reputation is a separate ledger.
3. **L1 Schedule data** can ship as a *display* surface (read-only) before any of L2–L5 exist — the lowest-risk wedge for this entire track.
4. **L2 Civic reporting** must launch as *pilot only* (one apartment, one school, or one ward) before any public map.

---

## 3. Feature Clusters

### L1 — Locality Collection Data

- Area / locality collection schedule (display).
- Per-waste-type pickup days (dry / wet / hazardous / e-waste).
- Collection window (e.g. 07:00–09:30).
- Ward / zone / BBMP area identifier.
- Route coverage description.
- Collector / contractor name (public-source only).
- Collector contact (**public official sources only** — never personal numbers user-submitted).
- Apartment-specific overrides.
- Bulk waste pickup request flow.
- E-waste pickup event calendar.
- Disruption notices (holiday / strike / weather).
- "Is collection happening today?" status query.

### L2 — Map-Based Civic Issue Reporting

- Issue types (canonical set): garbage pile, missed pickup, overflowing bin, illegal dumping, drain blocked by waste, e-waste dumped, construction debris, dead animal / biohazard, public bin damaged, collection vehicle did not arrive.
- Capture flow: map tap → photo → issue type → optional notes → submit.
- Geo-tagged, coarse public coordinates by default.
- Lifecycle state machine: `reported → needs_verification → confirmed → submitted_to_authority → acknowledged → in_progress → resolved | rejected_spam | duplicate`.
- Authority submission (later phase) via shareable artefact.
- Other-user confirmation / update.
- Reward via L4 reputation points only.

### L3 — Waze-Style "Still There?" Verification

- Proximity-triggered prompt to nearby users.
- Lightweight responses: `still_there | cleared | not_sure | wrong_location | duplicate | unsafe_urgent`.
- Trust-weighted aggregation into issue confidence.
- Time-decay on issue confidence so abandoned pins fade.
- Anti-farming: per-user per-issue cap, per-day cap, proximity guard.

### L4 — Trust & Points System (Reputation Only)

- Tiers: `new_contributor → verified_local → trusted_mapper → ward_champion → moderator`.
- Earn points for: valid new report, valid confirmation, valid resolution, schedule correction, official-source addition, facility status update, recycling-partner addition.
- Lose / earn-nothing for: spam, duplicate (after grace), false report, unsafe personal info, abusive content.
- **Hard separation**: civic points are a `reputation_score`, never minted into the `tokens` table used by AI. Same person can have high civic reputation and zero AI tokens.

### L5 — Authority / NGO / Apartment Sharing

- WhatsApp share-to-officer message (with local-language template variants).
- Email template.
- PDF report.
- Public link (read-only, coarse location).
- CSV export at ward level.
- Auto-grouping of duplicate reports before share.
- SLA tracking (reported_at → acknowledged_at → resolved_at).
- Weekly "top unresolved hotspots" digest.
- Municipality / NGO / apartment / contractor dashboard (later).

### L6 — Geospatial & Privacy Layer

- Inherits existing stack — `flutter_map`, `flutter_map_marker_cluster`, `flutter_map_heatmap`, `geoflutterfire_plus`, OSM tiles, `flutter_map_tile_caching` for offline.
- Two coordinate fidelities per record: `coords_public` (coarse, ≥ 50–100m bucket) and `coords_exact` (authority/moderator only, ACL-gated).
- EXIF strip on civic photos by default.
- On-device face / license-plate blur before upload (ties to #32).
- Geohash clusters for hotspot detection and heatmap layer.
- Offline tile pack for primary city to support degraded connectivity.

### L7 — Adjacent Expansions (Research Candidates Only)

- Crowdsourced "truck came at 8:20am" → route reliability score, missed-pickup heatmap.
- Public bin inventory + fullness + damage reports.
- Apartment / school modes (waste champion, leaderboards, contamination reports, vendor pickup tracking, classroom waste audit, weekly clean-campus challenge).
- Local marketplace: kabadiwala / recycler directory, compost buyer/seller, e-waste pickup partners (extends #26).
- WhatsApp-first civic flow with local-language complaint generation.
- Local-language layer (Kannada / Hindi / English) + voice notes + low-literacy icons.
- Open anonymised civic API / NGO export.

---

## 4. Data Model Sketch (Draft Only)

> All names are provisional. The eventual Firestore / SQL schema must be reviewed alongside `lib/models/user_contribution.dart`, `lib/models/disposal_location.dart`, and the data-retention policy (#14).

### L1 — Collection schedules

```
collection_route
  id, city, zone, ward, locality_label, geometry (polygon or geohash set),
  contractor_name_public?, source_type, source_url, verification_status,
  last_verified_at, contributor_id?, confidence_score, created_at, updated_at

collection_schedule
  id, route_id, waste_type (dry|wet|haz|e_waste|bulk),
  day_of_week, window_start, window_end,
  effective_from, effective_to?, holiday_calendar_id?,
  source_type, source_url, verification_status, confidence_score

collection_disruption
  id, route_id, kind (holiday|strike|weather|other),
  starts_at, ends_at, message_local_lang, source_type, verification_status
```

### L2 / L3 — Civic issues + verification

```
civic_issue
  id, kind (enum), title, description?,
  coords_public (geohash + coarse lat/lng), coords_exact (ACL: authority/mod),
  ward_id?, route_id?,
  status (reported|needs_verification|confirmed|submitted|acknowledged|
          in_progress|resolved|rejected_spam|duplicate),
  reported_by, reported_at,
  duplicate_cluster_id?, confidence_score,
  resolution_at?, sla_breach?, public (bool)

civic_issue_photo
  id, issue_id, storage_path, exif_stripped (bool),
  face_blur_applied (bool), plate_blur_applied (bool),
  uploaded_by, uploaded_at

civic_issue_update
  id, issue_id, author_id, kind (comment|status_change|photo_add),
  payload, created_at

civic_issue_vote (the "still there?" signal)
  id, issue_id, voter_id, response (still_there|cleared|not_sure|
                                    wrong_location|duplicate|unsafe_urgent),
  proximity_m, created_at

duplicate_cluster
  id, anchor_issue_id, member_issue_ids[], merged_at, merged_by

verification_prompt
  id, issue_id, target_user_id, sent_at, responded_at?, response?
```

### L4 — Reputation (separate ledger)

```
civic_reputation
  user_id, tier (new|verified_local|trusted_mapper|ward_champion|moderator),
  reputation_score (int, monotonic-ish),
  ward_scope[], earned_at_latest, decayed_at_latest

civic_reputation_event
  id, user_id, kind (report_valid|confirm_valid|resolution_valid|
                    schedule_correction|official_source_add|spam_penalty|
                    duplicate_penalty|false_report_penalty),
  delta, source_ref (issue_id / schedule_id / ...), created_at
```

> **Hard constraint**: `civic_reputation_event.delta` MUST NOT flow into the AI-token ledger. Separate tables, separate services, no shared mint path. Code review must enforce this.

### L5 — Authority submission

```
authority_submission
  id, issue_id, channel (whatsapp|email|pdf|api), target_authority,
  payload_snapshot, sent_at, sent_by, ack_at?, resolution_link?
```

---

## 5. Privacy & Safety Risks (Must-Resolve Before Public Surface)

This list is the gating checklist. Each item must be either *answered* or *killed* before that surface can ship.

1. **Photo PII**: faces, license plates, addresses, children. → On-device blur + EXIF strip + opt-in policy. Ties to #32.
2. **Exact location leakage**: do not publish exact coordinates. Public surface always uses coarse geohash bucket. Exact reserved for authority/moderator with audit log.
3. **Collector worker contact info**: never publish personal phone numbers. Only public official sources (ward office, contractor company line). User-submitted personal numbers rejected by intake.
4. **Defamation / harassment**: civic reports naming specific people / businesses must be moderated before public display. Anonymous reports must still be attributable internally for abuse handling.
5. **False reports**: false reports of "missed pickup" can harm contractors; require verification before authority handoff. Reputation penalty for confirmed false reports.
6. **Unsafe area exposure**: dense civic-issue clusters can map unsafe neighbourhoods. Need policy for what is publicly visible vs authority-only.
7. **Children's data**: any school / classroom mode triggers COPPA-class age-gating (#33, A14).
8. **Cross-border**: civic data may include faces / addresses → triggers DPDP (India) at minimum.
9. **Moderation load**: civic photos + comments + votes can become unmoderatable. Pilot-scope launch only; estimate moderation hours/MAU before opening to public.
10. **Takedown / abuse flow**: every public artefact needs a one-tap report-abuse path and a takedown SLA.

---

## 6. Monetization Possibilities (Validation Required, Not Commitment)

| Buyer | Pain | MVP offer | Data needed | Operational burden | Legal/privacy risk | Shortest validation |
|---|---|---|---|---|---|---|
| Apartment association | Visibility into waste compliance; vendor accountability | Apartment compliance dashboard + monthly report | Apartment opt-in, in-complex schedule + issues | Low–medium (per-complex onboarding) | Low (consenting community) | 1 pilot apartment, ₹X/month, 8-week proof |
| School | Classroom waste audit + behaviour change | School mode + classroom leaderboard + teacher dashboard | Roster opt-in, student PII-safe identifiers | Medium (teacher training) | High (kids) | 1 school pilot, sponsored or paid |
| NGO / volunteer org | Plan cleanup campaigns; show impact | NGO cleanup map + before/after export | Civic issue feed (anonymised), photos | Low (read-only consumer of platform) | Medium (photos) | 1 NGO pilot, free → paid after value proven |
| CSR sponsor | ESG storytelling + measurable impact | Sponsored cleanup campaign analytics | Anonymised issue feed + campaign tagging | Low | Low | 1 brand pilot, fee covers ops |
| Municipality | Triage civic complaints; SLA tracking | Ward issue triage dashboard + SLA report | Verified civic feed + duplicate clustering | High (procurement cycles) | Medium (official data) | Free pilot with one ward; convert to MoU |
| Waste contractor | Route feedback; missed-pickup defence | Route reliability dashboard | Crowdsourced "truck came at..." signal | Medium | Medium (worker privacy) | 1 contractor pilot |
| Recycling partner | Lead gen for pickup customers | Verified directory + bulk pickup leads | Facility data + user pickup requests | Low | Low | Per-lead fee |
| Citizens | Quick civic complaint generation | WhatsApp-formatted complaint export | Issue card | Low | Low | Free feature; ties to retention not revenue |

**Decision rule**: do not commit to any B2B/B2G product until at least one paid (even token-fee) pilot validates willingness to pay. Free pilots do not count as validation.

---

## 7. MVP / Later / Moonshot Classification

### Launch-adjacent (can be considered now, only if zero impact on P0 ship)

- Display collection timing **if data is already available from a public source** (read-only).
- Disposal facility map + status surface (already exists; extend with "last verified" badge).
- Save a civic issue locally; share as WhatsApp card. **No public map, no authority handoff yet.**
- Reputation points (civic ledger, separate from AI tokens) for verified facility-status corrections.
- Cloudflare SEO pages for "<area> e-waste disposal" / "<area> bulk pickup" — pure SEO surface, no UGC moderation cost.

### Next (after launch, after privacy/moderation foundation)

- Map-based civic reports (pilot scope: one apartment / one school / one ward).
- "Still there?" verification loop, proximity-triggered.
- Locality-wide collection schedule (user-contributed + official sources).
- Public bin / disposal centre verification.
- Apartment collection reminders.

### Later (only after a working pilot proves the moderation + trust loop)

- Municipality / NGO / apartment dashboards.
- Route reliability intelligence.
- Public-facing hotspot heatmaps.
- Trust-weighted civic confidence network.
- B2B / B2G analytics products.
- Partner marketplace (recyclers, compost, kabadiwala).

### Moonshot (long-horizon moat)

- City-wide waste intelligence network.
- Predictive missed-pickup alerts.
- Municipal SLA tracking as a verified third-party.
- Open civic waste data layer / public API.

---

## 8. Kill Criteria (When to Stop)

Stop or de-scope this track if **any** of the following becomes true:

1. **K-1**: Privacy / photo PII (#32) does not have a credible on-device blur + EXIF-strip answer within the launch window. Civic UGC cannot ship before that.
2. **K-2**: Moderation cost projected per 1k MAU exceeds the projected revenue from any single B2B/B2G wedge.
3. **K-3**: Collection schedule data is not legally publishable for the launch city (BBMP / municipal terms forbid republication).
4. **K-4**: No paid pilot can be closed for *any* B2B/B2G product within 6 months of opening conversations.
5. **K-5**: Civic points leak into AI-token economy (in code or in user mental model) and start farming-driven AI cost spikes.
6. **K-6**: A single false-report event causes provable harm to a worker / contractor and the platform has no defensible workflow.
7. **K-7**: Core "scan → classify → dispose" loop retention is still under target — fixing the core is more leveraged than building this track.

If a kill criterion fires, archive this track in `docs/exploration/ARCHIVE.md` with the rationale; do not silently let it consume cycles.

---

## 9. Agent-Ready Tasks

Each task below is exploration-grade (research + spec, not code merge). All tasks must:

- Follow [motto_v2.md](../../motto_v2.md).
- Run **read-only** git only (`git status`, `git diff --stat`, `git log` — no mutating commands).
- **Preserve parallel work**: do not touch files outside the task's listed deliverables. Do not modify launch-P0 surfaces.
- Inspect existing exploration docs before adding anything: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md), [exploration/backlog.md](../exploration/backlog.md), [planning/local_recycling_directory.md](../planning/local_recycling_directory.md), `docs/planning/business/`, this doc.
- Cross-link to existing topics (A20, A21, #20, #23, #24, #25, #26, #27a, #29, #32) instead of duplicating.

---

### Civic-A — Locality Collection Data Research

**Deliverable**: `docs/exploration/LOCALITY_COLLECTION_DATA.md`

**Scope**:

- Survey what public collection data exists for Bangalore/BBMP and 2 comparison cities (one Indian metro, one international peer).
- Define the `collection_route` / `collection_schedule` / `collection_disruption` schemas (start from §4 of this doc).
- Identify legal/privacy limits on republishing collector / contractor contact info; codify a `source_type` policy (`official_public` / `contractor_disclosed` / `user_submitted_unverified`).
- Recommend an MVP data-acquisition path: scrape vs partner vs user contribution vs hybrid.

**Acceptance criteria**:

- One-page schema sketch.
- One-page legal/privacy policy for collector contact info.
- Three city case studies with verdicts (publishable / partner-only / blocked).
- One MVP recommendation with confidence statement (§0.2 of motto_v2).

**Out of scope**:

- Building the data pipeline.
- Touching `lib/` code.
- Negotiating real partnerships.

**Validation**:

- Cross-check against `planning/local_recycling_directory.md`.
- Confirm no contradiction with #25 (Municipal APIs / BBMP).

---

### Civic-B — Map-Based Waste Issue Reporting Product Spec

**Deliverable**: `docs/exploration/CIVIC_ISSUE_REPORTING_SPEC.md`

**Scope**:

- UX flow: map tap → photo → issue type → notes → submit.
- Canonical issue-type enum (start from §3 L2).
- Photo capture rules (count, EXIF strip, on-device blur hooks).
- Lifecycle state machine (start from §4 `civic_issue.status`).
- Pilot vs public scoping (what's gated to apartment/school/ward pilots, what's never public without moderation).
- Reward design (civic reputation only — link to Civic-C).
- Duplicate detection sketch (proximity + kind + time-window).

**Acceptance criteria**:

- Flow diagram + state machine diagram (text/diagram block).
- Pilot-scope MVP defined; public-scope explicitly out of MVP.
- Moderation cost estimate per 1k reports.

**Out of scope**:

- Implementation.
- Authority dashboards (that's Civic-D).
- Trust algorithm details (that's Civic-C).

**Validation**:

- Reconcile with `lib/models/user_contribution.dart` and A21 (do not fork the UGC pipeline; extend it).

---

### Civic-C — Community Verification & Trust System

**Deliverable**: `docs/exploration/CIVIC_TRUST_AND_VERIFICATION.md`

**Scope**:

- "Still there?" prompt design (when, who, how often, proximity threshold).
- Trust tier definitions and promotion/demotion rules.
- Confidence algorithm (trust-weighted aggregation, time decay).
- Anti-spam / anti-farming controls (rate caps, proximity caps, behavioural signals).
- Duplicate clustering algorithm sketch.
- **Hard separation contract** between civic reputation points and AI tokens (#27a) — including a code-level enforcement plan.

**Acceptance criteria**:

- Confidence formula with worked example.
- Anti-farming control list with attack scenarios it defeats.
- Written separation contract reviewed against `TOKEN_ECONOMY_TODO.md`.

**Out of scope**:

- Backend implementation.
- Moderation tooling.

**Validation**:

- Cross-check separation contract with the active token-economy work; raise an alert if any planned token earn-path overlaps with civic actions.

---

### Civic-D — Authority / NGO / Apartment Sharing Workflow

**Deliverable**: `docs/exploration/CIVIC_AUTHORITY_SHARING.md`

**Scope**:

- Report card design (WhatsApp / email / PDF / public link).
- Local-language complaint text generation (Kannada / Hindi / English at minimum).
- CSV export schema for ward-level rollups.
- Future authority dashboard sketch (read-only at first).
- SLA tracking model (reported → acknowledged → resolved).
- Apartment association report variant.

**Acceptance criteria**:

- Sample report card mock (text or diagram).
- Local-language template variants.
- Dashboard wireframe (text/diagram).
- Data-export schema reviewed against §4.

**Out of scope**:

- Actual outreach to municipalities.
- Building the dashboard.

**Validation**:

- Reconcile with #25 (Municipal APIs / BBMP) and #29 (B2B wedge ranking).

---

### Civic-E — Privacy & Safety Review

**Deliverable**: `docs/exploration/CIVIC_PRIVACY_SAFETY_REVIEW.md`

**Scope**:

- Evaluate every risk listed in §5 of this doc against current code (`#32`, `lib/services/user_consent_service.dart`, `lib/services/analytics_consent_manager.dart`).
- Required pre-launch safeguards: on-device face/plate blur, EXIF strip, coarse-location publication, authority-only exact location, takedown SLA, abuse-report flow, no public personal phone numbers.
- DPDP (India) checklist; GDPR / COPPA flags for any cross-border / kid surfaces.
- Moderation-cost projection per 1k reports.

**Acceptance criteria**:

- Per-risk verdict: blocked / mitigated / accepted-with-rationale.
- Concrete pre-launch safeguards list with owners (left blank if owner not yet assigned).
- Moderation cost estimate with sensitivity analysis.

**Out of scope**:

- Implementation.
- Legal review (flag where legal review is required, do not perform it).

**Validation**:

- Cross-check with `docs/security/`, #32, #33, A14, A19.

---

### Civic-F — B2B / B2G Monetization Validation

**Deliverable**: `docs/exploration/CIVIC_B2B_B2G_VALIDATION.md`

**Scope**:

- For each buyer in §6 (apartment, school, NGO, CSR sponsor, municipality, contractor, recycling partner): pain, MVP offer, data needed, operational burden, legal/privacy risk, shortest validation path.
- Rank the wedges by *paid-pilot probability within 6 months*, not by addressable market.
- Define a single "first paid pilot" hypothesis with success/kill criteria.
- Reconcile against #29 (existing B2B wedge ranking) — do not propose a new ranking that contradicts it without explicit justification.

**Acceptance criteria**:

- Buyer matrix completed.
- One named first-pilot hypothesis with kill criteria.
- Reconciliation note against #29.

**Out of scope**:

- Outreach.
- Pricing decisions.

**Validation**:

- Cross-check against `docs/planning/business/monetization/` and #28.

---

## 10. Update Plan for the Existing Map

To keep this track *reconciled* and not *forked*:

1. **`docs/EXPLORATION_TOPICS.md`** — add a new section "F — New Category: LOCALITY & CIVIC WASTE INTELLIGENCE" with entries `L1–L6` that **cross-link to this doc as the canonical track** and to existing topics (A20, A21, #20, #23, #24, #25, #26, #27a, #29, #32). Do **not** copy this doc into the master index; the master index is the cursor, this doc is the substance.
2. **`docs/exploration/backlog.md`** — append capture lines under a new "Locality & Civic Waste Intelligence" heading and a promotion-log row pointing here.
3. **`docs/exploration/ARCHIVE.md`** — touched only if a kill criterion (§8) fires.
4. **No other planning docs are overwritten.** If a contradiction surfaces with `planning/local_recycling_directory.md`, `planning/business/monetization/`, or `EXPLORATION_FRONTIER.md`, raise it explicitly in the relevant agent task above and let the source artefact win.

---

## 11. Confidence Statement (per motto_v2 §0.2)

- **Verified**: existing map stack (`flutter_map`, `flutter_map_marker_cluster`, `flutter_map_heatmap`, `geoflutterfire_plus`, `flutter_map_tile_caching`) is present in `pubspec.yaml`. Existing screens (`disposal_facilities_screen.dart`, `facility_detail_screen.dart`, `community_screen.dart`) and models (`disposal_location.dart`, `user_contribution.dart`, `local_guidelines_plugin.dart`) are present. Existing topics A20, A21, #20, #23, #24, #25, #26, #27a, #29, #32 are real entries in `docs/EXPLORATION_TOPICS.md`.
- **Inferred**: that the user-addendum direction extends those surfaces coherently rather than duplicates them; that pilot-scope launch is feasible without building a moderation org first; that paid B2B/B2G pilots are reachable within 6 months — none of these are validated yet.
- **Unknown / requires the agent tasks above to resolve**: legal publishability of BBMP collection schedules; moderation cost per 1k reports; willingness to pay of every buyer in §6; whether civic-token separation can be enforced cleanly in the current token-economy implementation; whether existing `geoflutterfire_plus` scales to civic-issue density at city level.
- **Fragile areas**:
  - The separation between civic reputation and AI tokens is a *policy* until it is enforced in code; it can leak in either direction silently.
  - Civic-reporting moderation can collapse the team's bandwidth if launched public-scope without pilot gating.
  - "Display collection schedule" looks like the safest near-term wedge but is only safe if the data is legally publishable.

---

## 12. References

- [docs/EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — master index, esp. entries A20, A21, #20, #23, #24, #25, #26, #27a, #29, #32.
- [docs/exploration/backlog.md](../exploration/backlog.md) — raw capture; this track is appended there with a promotion-log row.
- [docs/EXPLORATION_FRONTIER.md](../EXPLORATION_FRONTIER.md) — high-ambition map; this track may eventually graduate here.
- [docs/planning/local_recycling_directory.md](../planning/local_recycling_directory.md) — directory feature spec; civic status layer sits on top of this.
- [docs/planning/business/monetization/](../planning/business/monetization/) — monetization context for §6.
- [docs/reference/APP_KNOWLEDGE_BASE.md](../reference/APP_KNOWLEDGE_BASE.md) — app-level facts; cross-check before any data-model decision.
- [TOKEN_ECONOMY_TODO.md](../../TOKEN_ECONOMY_TODO.md) — active token-economy work; civic-token separation contract must hold against this.
- [motto_v2.md](../../motto_v2.md) — operating discipline; every agent task above defers to it.
- [firebase_task.md](../../firebase_task.md) — Phase/P0 checklist; this track does **not** modify P0.
