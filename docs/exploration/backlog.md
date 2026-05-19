# Exploration Backlog — Waste Segregation App

**Last Updated**: 2026-05-19

A living, append-only document of areas to explore, ideas to investigate, and potential improvements. **Add items freely** — this is a capture space, not a commitment queue. Items get promoted into [../EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) or a dedicated `docs/exploration/*.md` doc when they're mature enough to act on.

Format per item:

- `[ ]` open / `[x]` promoted / `[~]` killed (with one-line rationale)
- Short title, then optional context
- Cross-link to existing planning / research docs when known

Sources already mined for this initial list:

- [../planning/ideas_to_explore.md](../planning/ideas_to_explore.md)
- [../planning/STRATEGIC_ROADMAP_COMPREHENSIVE.md](../planning/STRATEGIC_ROADMAP_COMPREHENSIVE.md)
- [../planning/CONSOLIDATED_FUNCTIONAL_IMPROVEMENTS_ROADMAP.md](../planning/CONSOLIDATED_FUNCTIONAL_IMPROVEMENTS_ROADMAP.md)
- [../planning/REMAINING_ROADMAP_ITEMS.md](../planning/REMAINING_ROADMAP_ITEMS.md)
- [../TODO/](../TODO/)
- [../TOKEN_ECONOMY_TODO.md](../../TOKEN_ECONOMY_TODO.md)

---

## AI & Vision

- [ ] Calibrated confidence + "ambiguous" UX state (vs forcing a single answer)
- [ ] Per-provider response normaliser so model swaps don't ripple into UI
- [ ] Prompt versioning + per-prompt eval scores (no prompt change without an eval pass)
- [ ] Hard-example mining from user corrections — weekly cycle
- [ ] Multi-frame / burst-capture mode for cluttered or hard scenes
- [ ] Audio cues (crunching plastic, paper rustle) as supplementary signal
- [ ] Brand / SKU recognition with explicit privacy & accuracy boundaries
- [ ] Distinguish "model unsure" from "image bad" (blur, framing, glare)
- [ ] Active-clarification: when uncertain, ask the user a structured question rather than guessing

## On-Device & Edge

- [ ] Evaluate Gemma 3n, MiniCPM-V, SmolVLM, MobileSAM, Apple Vision for the common case
- [ ] Bundle-vs-lazy-download strategy for model weights (APK size guardrail)
- [ ] iOS vs Android parity matrix for on-device inference
- [ ] Battery / thermal / memory budget benchmark on representative mid-tier devices
- [ ] On-device pre-filter (is this even a waste item?) before cloud classify
- [ ] Cascade escalation policy — features that drive escalation, audit trail per escalation
- [ ] Graceful degradation tiers on low-end devices (skip on-device entirely, force cloud, throttle)

## Data, Cost & Reliability

- [ ] Per-user daily / monthly soft + hard caps on AI spend
- [ ] Provider downgrade ladder when budget exhausted (small model → on-device → queue)
- [ ] Anonymous-user abuse mitigations (rate limits, device fingerprinting tradeoffs)
- [ ] Firestore read/write hotspot audit and per-MAU cost projection
- [ ] Index audit — find load-bearing vs dead composite indexes
- [ ] Classification history schema migration framework (versioned migrations)
- [ ] User export of classification history (JSON / CSV, with photo links)
- [ ] Photo storage lifecycle: hot → cold → delete with explicit windows
- [ ] Offline queue: idempotency keys, conflict resolution policy per record type
- [ ] "Pending sync" UI surface with retry / cancel
- [ ] Telemetry for stuck or repeatedly-failing queue items

## User Experience & Engagement

- [ ] Time-to-first-successful-scan instrumentation + funnel dashboard
- [ ] Skip-onboarding-and-recover path for impatient users
- [ ] Re-onboarding when a returning user has been away N weeks
- [ ] Notification policy — what reliably drives return without becoming nagging
- [ ] Educational content sequencing based on user competence (scaffolded learning)
- [ ] Persona-specific surfaces — household, parent, kid, teacher, RWA admin, sustainability officer
- [ ] Accessibility audit — VoiceOver / TalkBack coverage of the classify flow
- [ ] Voice-first capture path for accessibility
- [ ] Language priority order beyond English / Hindi
- [ ] Low-literacy iconography pass on disposal advice

## Gamification & Behaviour

- [ ] Reward correct disposal, not just scan volume — needs verification primitive
- [ ] Anti-cheating: detect repeat-scan farming
- [ ] Cooperative family / group challenges vs purely competitive
- [ ] Streak design that survives travel / sick days without punishing
- [ ] Habit loop measurement — cue → routine → reward, with retention cliffs
- [ ] Week-3 retention cliff investigation (where does novelty wear off?)
- [ ] Long-term motivation beyond points (impact narrative, identity, belonging)

## Community & Social

- [ ] Trust tiers — anonymous / email-verified / identity-verified, and what each can do
- [ ] Image moderation pipeline (NSFW, faces, license plates, addresses)
- [ ] Comment / reaction abuse handling
- [ ] Misinformation handling when a community "correct" answer is wrong
- [ ] Role model for families / classrooms / societies (parent / kid / admin / member / observer)
- [ ] Privacy boundaries within a group (what does an admin see vs a parent vs a kid?)
- [ ] Cross-group movement (kid graduates from family group to school group)
- [ ] Local reuse marketplace pilot — society or building scoped
- [ ] Integration with existing local channels (society apps, WhatsApp groups)

## IoT, Smart City & Partners

- [ ] QR-bin layer as the cheapest possible "smart bin" — pilot with one RWA / school
- [ ] Smart-bin hardware partner landscape scan
- [ ] BBMP / municipal partner outreach — what data, what SLA, what credibility win
- [ ] Apartment-chute / weighing-scale integrations as future surfaces
- [ ] Informal collector (kabadiwala) onboarding model — literacy, devices, payments
- [ ] Verified-disposal primitive (what counts? user attestation? bin scan? collector confirmation?)
- [ ] Drop-off point directory with user ratings + verified status

## Business & Growth

- [ ] Premium tier value justification (cloud quality? family seats? offline pack? education?)
- [ ] Anchor pricing across regions (India vs US PPP)
- [ ] Family / group plans vs per-seat pricing
- [ ] Free-tier limits that drive conversion without breaking the core promise
- [ ] B2B wedge ranking — school vs corporate ESG vs hospitality vs municipal
- [ ] Minimum admin surface for each B2B wedge (dashboard, exports, SSO)
- [ ] White-label vs first-party rules of the road
- [ ] Carbon / impact accounting framework choice (EPA / IPCC / regional)
- [ ] Uncertainty UI for impact numbers without killing motivation
- [ ] Brand / manufacturer closed-loop data — privacy posture + sales motion
- [ ] Distribution channels: schools, RWAs, brand partners, sustainability NGOs

## Compliance & Trust

- [ ] On-device face / PII redaction before any upload
- [ ] Explicit consent UI for any photo reuse beyond classification
- [ ] Cross-border data flow constraints (India ↔ US ↔ EU)
- [ ] DPDP Act (India) checklist
- [ ] GDPR checklist for any EU exposure
- [ ] COPPA / age-gating for kid users
- [ ] Provenance metadata per classification (model, prompt version, ruleset version, timestamp)
- [ ] "Why did the app say that?" explainability surface for advanced users / partners
- [ ] Audit trail spec: one place to answer "what did the app do for this user, when, and why?"

## Pipeline & Capture Surfaces

- [ ] Share-from-other-app intent (share an image from gallery / WhatsApp to classify)
- [ ] Batch capture mode — classify many items in one session (kitchen clean-out)
- [ ] Continuous video classification for conveyor / chute scenarios (frontier)
- [ ] Auto-detect "this is a waste-item scan, not a random photo" so user doesn't have to choose
- [ ] Re-classification flow — open an old scan, re-run with a newer model

## Engineering Health

- [ ] Code TODO sweep — see `code_todos_grep_results.txt`, `todo_grep_results.txt`, `todos_consolidated_raw_2025-06-14.txt`
- [ ] Service-level Riverpod migration audit — anything still on legacy state
- [ ] Test coverage map vs critical-path matrix
- [ ] Crash / ANR baseline + budget
- [ ] Build-time + release-pipeline health audit
- [ ] Documentation lint — broken cross-doc links, stale dates, drift vs `APP_KNOWLEDGE_BASE.md`

---

## Promotion Log

When an item moves from this backlog into a real exploration doc or into `EXPLORATION_TOPICS.md`, log it here:

| Date | Item | Promoted to | Notes |
|------|------|-------------|-------|
| 2026-05-19 | Multi-Model AI Routing | `EXPLORATION_TOPICS.md#1` | Topic seeded in master index. Full doc still to write. |
| 2026-05-19 | Eval Harness & Golden Sets | `EXPLORATION_TOPICS.md#5` | Topic seeded. Full doc still to write. |
| 2026-05-19 | Region-Aware Rulesets | `EXPLORATION_TOPICS.md#4` | Topic seeded. Full doc still to write. |
| 2026-05-19 | AI Cost Telemetry & Guardrails | `EXPLORATION_TOPICS.md#10` | Topic seeded. Full doc still to write. |
| 2026-05-19 | Onboarding & Activation | `EXPLORATION_TOPICS.md#19` | Topic seeded. Full doc still to write. |
| 2026-05-19 | Privacy / Photo PII | `EXPLORATION_TOPICS.md#32` | Topic seeded. Full doc still to write. |

(Append new rows here; never delete — the trail is the value.)
