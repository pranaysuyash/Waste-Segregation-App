# Classroom Mode & Teacher Dashboard

**Status**: Draft — no code surface for classroom/school mode exists yet.
**Priority**: P2 (pilot-ready after individual core maturity)
**Related**: [FAMILY_COOPERATIVE_MECHANICS.md](FAMILY_COOPERATIVE_MECHANICS.md), Kid-Safe Mode (separate doc), [B2B_ENTERPRISE_WEDGE.md](B2B_ENTERPRISE_WEDGE.md)
**Last Updated**: 2026-05-25

---

## Why This Is a Topic

Schools are a high-leverage distribution channel for a waste/sustainability app:

1. **One teacher → 30 students → 30 families** — the classroom acts as a force multiplier for adoption.
2. **Mission alignment** — waste education is part of school curriculum (environmental science, EVS, SDGs).
3. **Structured usage pattern** — regular class periods, defined assignments, measurable outcomes.
4. **B2B revenue path** — schools have budgets for curriculum-supporting tools.

However, classroom use introduces a completely new set of requirements: teacher controls, student privacy, age-appropriate content, grading, and curriculum alignment.

---

## Core Assumptions

1. **School signs up as an organization, not individual teachers.** Org admin manages teacher licenses.
2. **Teachers create classes, students join via code/link.** No student account creation needed (COPPA compliance).
3. **Students use kid-safe mode** (see separate doc) — no ads, no public community, no social sharing.
4. **Data is isolated to class/school** — no cross-school feeds, no public leaderboards.
5. **Teachers control content scope** — which waste categories, which cities/rules, which quiz topics.

---

## Teacher Dashboard

### MVP Features (Phase 1)

| Feature | Description |
|---------|-------------|
| **Class roster** | View enrolled students, see last active date, remove students |
| **Assignment hub** | Assign specific tasks (classify 5 items of e-waste, complete quiz on plastic codes) with due dates |
| **Progress heatmap** | See which students have completed assignments, which are struggling |
| **Class-level stats** | Total items classified, diversion estimate, top materials, accuracy rate |
| **Printable reports** | Class summary PDF for parent-teacher meetings, student progress cards |
| **Leaderboard (class-only)** | Optional — show top performers by week within the class |

### Phase 2 Features

- **Content library** — browse curated waste/ sustainability lessons by grade level, assign to class
- **Quiz builder** — create custom quizzes from the label taxonomy + local rules
- **Certificate generator** — auto-create completion certificates for milestones
- **Parent dashboard** — show parents what their child is learning and how they can reinforce at home

### Anti-Features (Intentionally Excluded)

- Individual student comparison by teacher (avoid shaming)
- Public or cross-school rankings
- Commercial content or brand promotions
- Access to individual student correction history (aggregated only)

---

## Student Experience in Classroom Mode

On the student device:
- Simplified UI: large icons, minimal text, voice guidance option.
- No camera issues — students scan pre-prepared items or use the camera with teacher supervision.
- No ads, no community, no social sharing.
- Quiz mode: answer questions about waste sorting, earn points.
- Impact display: "Your class diverted X kg this week!" (team framing).

### What Changes vs Standard Mode

| Surface | Standard Mode | Classroom Mode |
|---------|---------------|----------------|
| Camera scan | Any item, any time | Teacher-controlled scope |
| Classification result | Full detail (material, category, disposal) | Simplified (bin colour + action) |
| Community feed | Visible | Hidden |
| Ads | Possible (non-premium) | Never |
| Social sharing | Available | Hidden |
| Points | Individual | Class-level + individual |
| Streak | Daily | School-week adjusted (Mon-Fri) |
| Quiz | As optional | Integrated into assignment |

---

## Content by Grade Band

| Age Band | Focus | Mechanics |
|----------|-------|-----------|
| **5–7** (Grades 1–2) | Bin colours, basic sorting (wet/dry/reject), clean habits | Icon-based, no text, voice guidance, large targets |
| **8–10** (Grades 3–5) | Material types (plastic, paper, metal, glass), why recycling matters, what contamination is | Scan + classify, simple quizzes, streak for consistency |
| **11–13** (Grades 6–8) | Resin codes, local rules, e-waste, hazardous waste, composting | Full classification, rule application, impact calculation, research tasks |
| **14+** (Grades 9–12) | Circular economy, lifecycle analysis, policy critique, waste audits | Advanced assignments, data export, sustainability reporting |

---

## COPPA / FERPA / GDPR-K Compliance

### COPPA (US, under 13)

- **No student accounts**: students join class via code; no email, no password, no PII collection.
- **School as agent**: the school consents on behalf of parents for educational tool use (per FERPA).
- **Data minimization**: store only progress data (items classified, quiz scores, streaks). No location, no device ID, no behavioural tracking.
- **No third-party sharing**: no analytics SDKs that share data, no ad SDKs, no social media integration.

### GDPR-K (EU, under 16)

- Age of digital consent varies by member state (13–16). Default to 16 unless school confirms otherwise.
- Privacy notice must be in language understandable by the child.
- Right to erasure: student data must be deletable on request.

### Indian Context (DPDP Act 2023)

- Data fiduciary obligations apply. Parental consent required for children under 18.
- Same pattern as COPPA: school-mediated consent, data minimization, no third-party sharing.

---

## Pilot Design

### Phase 0: Validate demand

- Talk to 3–5 environmental science teachers. What do they need?
- What's the single biggest pain point in their current waste education approach?

### Phase 1: Single-school MVP (6 weeks)

- One class, one teacher, 30 students.
- Features: class roster via code, assignment hub, basic progress tracking, kid-safe classification interface.
- Success criteria: teacher sustains usage for 4+ weeks, students classify 5+ items/assignment.

### Phase 2: Multi-school (3 months)

- 3–5 schools, 10+ classes each.
- Features: printable reports, content library, quiz builder, parent dashboard.
- Success criteria: 80%+ teacher retention from Phase 1, 3+ schools paying for annual license.

### Pricing Model Hypothesis

| Tier | Price | What's Included |
|------|-------|-----------------|
| **Free** | ₹0 | 1 class, 30 students, basic classification + quiz |
| **School** | ₹X/year | Unlimited classes, full dashboard, reports, certificates, content library |
| **District/Chain** | Custom | Multi-school admin, curriculum alignment, custom content, API access |

---

## Open Questions

1. **Should classroom mode be a separate app or a mode within the existing app?** Proposal: mode within the existing app, toggled by school-admin setting. Simpler distribution.
2. **Who creates classroom content?** Curated in-house initially. Teacher-contributed (with review) in Phase 2. AI-generated (with moderation) in Phase 3.
3. **Offline use in schools with poor connectivity?** Critical requirement for Indian market. Classification + quiz must work offline. Sync when connected.
4. **Battery/device constraints?** School devices may be low-end Android tablets. On-device classification must work on 3GB RAM devices.

---

## Related Work

- [B2B_ENTERPRISE_WEDGE.md](B2B_ENTERPRISE_WEDGE.md) — B2B sales model for schools and enterprises
- Kid-Safe Mode (separate doc) — safety, content filtering, and parent controls
- [HOUSEHOLD_ROLES_AND_PERMISSIONS.md](HOUSEHOLD_ROLES_AND_PERMISSIONS.md) — related role/permission model for families
- [KNOWLEDGE_VERIFICATION_QUIZ.md](KNOWLEDGE_VERIFICATION_QUIZ.md) — quiz engine that powers classroom assessments
- [LOW_LITERACY_MULTILINGUAL_UX.md](LOW_LITERACY_MULTILINGUAL_UX.md) — icon-first design for younger students
