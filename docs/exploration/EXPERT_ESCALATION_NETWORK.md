# Expert Escalation Network

**Status**: Seed — P2, not yet funded
**Last Updated**: 2026-05-26
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Item 62
**Related**: WHY_THIS_ANSWER_EXPLANATION.md, USER_DISPUTE_AND_APPEAL.md, TRANSPARENCY_LOG_MODEL_CARDS.md, PEER_MENTORING_EXPERT_QA.md

---

## 1. Why This Matters

No AI classification system is perfect. When the app is wrong — or when the user disagrees — there must be a credible human fallback. An expert escalation network:

- **Builds trust**: Users know a real person can review their case.
- **Improves accuracy**: Expert-reviewed corrections become high-quality training data.
- **De-risks safety-critical categories**: Hazardous, medical, and e-waste classifications benefit from human review before advice is given.
- **Supports B2B/B2G credibility**: Schools, municipalities, and corporate partners need to know there's a human backstop.

---

## 2. Escalation Models from Other Platforms

| Platform | Model | Trigger | Quality Mechanism |
|----------|-------|---------|-------------------|
| **Stack Overflow** | Community flagging + reputation | User report, auto-flag | High-rep users + elected moderators |
| **Reddit** | Community moderation | Moderator review queue | Subreddit-specific mods + admin backup |
| **Medical AI (e.g., IDx)** | Confidence threshold → clinician | AI confidence < threshold | Licensed clinician review before decision |
| **Wikipedia** | Community peer review | Edits flagged by algorithm or users | Recent changes patrol + experienced editors |
| **Uber/Eats** | Customer support escalation | User reports issue + evidence | Tiered support (bot → agent → supervisor) |

**Key design insight**: Escalation model should mirror risk profile:
- **Low risk** (plastic vs paper): Community-flagging model (Stack Overflow-like).
- **Medium risk** (e-waste category): Confidence threshold triggers expert queue.
- **High risk** (hazardous, medical, sharps): Always escalate to expert before advice is finalised.

---

## 3. Expert Verification & Qualification

### 3.1 Expert Tiers

| Tier | Qualification | Example | Compensation |
|------|---------------|---------|--------------|
| **Tier 1 — Community Expert** | Training + 50+ verified corrections | Master composter, long-term user | Badge, recognition, token rewards |
| **Tier 2 — Domain Expert** | Professional certification or relevant degree (environmental science, waste management) | SWANA-certified professional, municipal waste officer | Paid per review ($1-5), premium access |
| **Tier 3 — Subject Matter Expert** | Advanced degree + industry experience + vetting | PhD in materials science, licensed environmental engineer | Paid per review ($10-20), consulting rates for complex cases |

### 3.2 Vetting Process
- **Application**: Expert submits credentials (certificates, degrees, work history).
- **Reference check**: 1-2 professional references.
- **Test cases**: Expert review 10-20 golden cases with known answers — must match consensus on >80%.
- **Probation period**: First 50 reviews audited by existing expert before full trust promotion.

---

## 4. Escalation Flow Design

### 4.1 Triggers

| Trigger | Threshold | Action |
|---------|-----------|--------|
| AI confidence low | < 0.60 (safety), < 0.40 (non-safety) | Queue for expert review before showing result |
| User disputes result | User taps "This is wrong" | Queue for expert review with user's correction | 
| Contradictory providers | Gemini says "plastic", OpenAI says "paper" | Queue for expert arbitration |
| Safety-critical category | Any hazardous/medical/sharps classification | Always escalate to Tier 2+ before finalisation |
| Repeat dispute pattern | ≥ 3 disputes on same category by different users | Prioritise for system improvement review |

### 4.2 Lifecycle
```
Escalation Created → Assigned → In Review → Resolved
                                               ↓
                                        Acceptance: Accepted / Rejected / Needs More Info
                                               ↓
                                        Correction appended to classification result
                                               ↓
                                        (Optional) Training data eligibility
```

### 4.3 Escalation Interface (Operator View)
- **Queue view**: Sort by urgency (safety-critical first), category, date.
- **Review view**: Shows original image, AI result (with confidence), user correction (if any), and a "Truth" selector.
- **Audit trail**: Approve/reject/flag as training data candidate.
- **Response to user**: After resolution, user receives notification with expert's reasoning.

---

## 5. Expert Incentive Models

### 5.1 Paid Per Review (Recommended for Safety-Critical)
- **Rate**: $1–5 per review (Tier 2), $10–20 (Tier 3).
- **Who**: Professionals who need compensation for time.
- **Source**: Fund from premium subscription revenue, not from user fees.
- **Estimate**: At 500k classifications/mo and 1% escalation rate → 5,000 reviews/mo → at 5 min/review → 1.5 FTE.

### 5.2 Volunteer with Recognition (Scalable for Non-Safety)
- **Mechanic**: Badges, recognition on leaderboard, community influence.
- **Best for**: Tier 1 community experts who value reputation.
- **Risk**: Must not create incentive to review *more* (farming) — cap daily reviews for unpaid experts.

### 5.3 Pro-Bono Professional
- **Mechanic**: Professionals (environmental scientists, waste consultants) offer pro-bono time.
- **Best for**: NGOs, academic partners, and mission-aligned professionals.
- **Incentive**: Mission alignment, professional visibility, potential tax benefit.

---

## 6. Quality Metrics

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Expert-AI agreement rate | 85%+ | Compare expert resolution against original AI result |
| Expert consensus (complex cases) | 90%+ | 2-3 experts review same case; measure inter-rater reliability |
| Turnaround time | < 24h (normal), < 1h (safety-critical) | Time from escalation → resolution |
| User satisfaction after review | 4.0/5.0+ | Survey after expert resolution |
| Expert accuracy drift | < 5% per quarter | Regular audit of reviewed cases against known golden set |

---

## 7. Moderation Cost Estimation

### 7.1 Formula
```
Estimated Expert Cost = (Monthly Classifications × Escalation Rate × Avg Cost per Review) + Fixed Overhead
```

### 7.2 At Different Scales

| MAU | Monthly Classifications | Escalation Rate (1%) | Reviews/Month | Cost/Month (Tier 2 avg $3) |
|-----|------------------------|----------------------|---------------|----------------------------|
| 1K | 10K | 100 | 100 | $300 |
| 10K | 100K | 1,000 | 1,000 | $3,000 |
| 50K | 500K | 5,000 | 5,000 | $15,000 |
| 100K | 1M | 10,000 | 10,000 | $30,000 |

**Note**: Escalation rate drops over time as AI improves. Target: 0.5% escalation rate within 6 months of expert feedback loop.

---

## 8. Minimum Viable Expert Network

### Phase 1: Manual Routing (1-2 months to MVP)
1. **Recruit 3-5 experts** (mix of Tier 2 and Tier 3) — vet manually.
2. **Routing**: Simple Airtable/Trello queue visible to the team.
3. **Communication**: Email notifications for new cases and resolutions.
4. **Scope**: Safety-critical categories only (hazardous, medical, sharps, e-waste).

### Phase 2: Semi-Automated (3-4 months)
1. In-app escalation queue with assignment rules.
2. Expert dashboard (mobile + web).
3. Expand to medium-risk categories + user disputes.

### Phase 3: Full Expert Network
1. Self-service expert application and vetting pipeline.
2. Automated routing based on expertise category and availability.
3. Payment automation (no manual invoicing).
4. Quality dashboards for all expert tiers.
5. Only pursue when Phase 2 volume exceeds manual handling capacity.

---

## 9. Integration with the AI Learning Flywheel

Expert-reviewed corrections are the highest-quality training data the app can produce:

- Every expert resolution becomes a training data **candidate** (flagged for review before entering the dataset).
- Expert-resolved disputes feed back into the golden eval set.
- Regularly audit: "Would the new model version have handled this escalated case correctly?"
- Expert agreement rate becomes a model quality signal: if experts increasingly agree with the model, the escalation threshold might be too conservative.

---

## 10. Kill Criteria

- Cannot recruit 3+ qualified experts within 3 months.
- Expert turnaround time exceeds 48h for > 10% of cases — user trust impact is worse than showing an uncertain AI result.
- Expert cost exceeds budget allocation at current scale.
- Expert-AI agreement rate is < 70% and does not improve over 6 months, suggesting the model is fundamentally wrong on a category the experts validate.
