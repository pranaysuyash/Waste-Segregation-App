# User Dispute & Appeal Workflow

**Status**: Exploration — pre-design
**Priority**: P2 (🟡)
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Topic #60
**Related docs**: `WHY_THIS_ANSWER_EXPLANATION.md`, `USER_CONTRIBUTION_UGC_PIPELINE.md`, `TRAINING_DATA_ANNOTATION_TOOL.md`, `CONTINUOUS_LEARNING_LOOP.md`

---

## Why This Matters

When the app classifies waste incorrectly, the user's experience defines whether they correct the result (valuable signal) or lose trust and churn (costly outcome). A well-designed dispute workflow:

1. **Captures high-quality training data** — corrected labels are the most valuable signal for model improvement.
2. **Reduces churn** — users who correct errors stay engaged longer than users who see errors and say nothing.
3. **Builds trust** — transparent appeals demonstrate that the app is fallible and accountable.
4. **Powers continuous learning** — every dispute is a potential training case for the next model iteration.

---

## Key Questions

- How do we distinguish a legitimate correction from a malicious or mistaken one?
- What dispute categories map to meaningful model improvements vs noise?
- When should a dispute auto-resolve (user is correct) vs require human review?
- How do we close the loop with the user after resolution?
- How does the dispute pipeline connect to training data ingestion without privacy violations?

---

## Research Findings

### 1. Correction Capture Types

Not all corrections are equal. Three tiers:

| Tier | Example | Auto-Trust? | Training Value | Review Needed |
|---|---|---|---|---|
| **Category switch** | "This is Paper, not Plastic" | Maybe (≥ 2 users agree) | High | Manual spot-check |
| **Material refinement** | "This is PET #1, not HDPE #2" | No — requires expertise | Very high | Expert review |
| **Disposal override** | "This IS accepted in my city" | No — may be wrong about local rules | High (for rules) | Policy check |
| **Hazard dispute** | "This is NOT hazardous" | Never — safety first | Critical | Mandatory review |
| **Spam/abuse** | Random label, garbage input | Never | None | Flag user |

### 2. Dispute Lifecycle

```
Submitted → Auto-screened → Queued → Reviewed → Resolved
                                    ↓
                              Escalated (if disputed again)
```

**Lifecycle states**:
1. **Submitted** — User taps "Correct" on classification result.
2. **Auto-screened** — Automated checks: is this a known correction (duplicate)? Is the user trust score above threshold? Does the correction match known patterns?
3. **Queued** — For review. Prioritized by: safety impact > correction frequency > user trust score.
4. **Under review** — Reviewer examines correction + original classifier output + image + context.
5. **Resolved** — Decision made: accept (training case), reject (notify user), or partial (accept category but not refinement).
6. **Escalated** — User disputes the review result → goes to senior reviewer or expert panel.

### 3. Auto-Resolution Rules

Some disputes can resolve without human review:

| Condition | Resolution |
|---|---|
| ≥ 2 users independently correct the *same* classification | Auto-accept. High training confidence. |
| User has high AI-training trust score (> threshold) | Auto-accept for non-safety categories. |
| Correction matches a golden set case | Auto-accept. Golden set confirms. |
| Correction is for a safety-critical category | Never auto-accept. Always review. |
| Correction contradicts a city policy rule | Route to policy reviewer, not AI reviewer. |

### 4. Dispute Farming Prevention

**Attack vectors**:
- Coordinated false corrections to bias model toward wrong answers.
- Random corrections to earn gamification rewards tied to "contributions."
- Targeting specific categories to degrade model performance.

**Mitigations**:
- **Trust-weight corrections** by user's correction history accuracy rate.
- **Rate-limit corrections** per user/day (e.g., max 20 corrections/day).
- **Cross-user correlation** — detect if multiple corrections cluster on same image/user/category.
- **No gamification reward for corrections** — or if rewarded, at a very low rate that makes farming unprofitable.
- **Hazardous dispute lock** — only users with verified expertise can dispute hazardous classifications.

### 5. Closing the Loop

When a dispute is resolved, the user needs to know:

| Outcome | Notification | What Else |
|---|---|---|
| **Accepted** | "Thanks! You were right — this is Paper. We've updated our model." | Offer to show corrected result. Show the new disposal instruction. |
| **Rejected** | "We reviewed your correction and determined the original classification was correct. Here's why..." | Show explanation. Offer to escalate. |
| **Partially accepted** | "We accepted part of your correction — the material was right, but the subcategory is different." | Show details. Offer alternative. |
| **Escalated** | "This needs a second look — a specialist will review within 48 hours." | No change until resolution. |

### 6. Connection to Training Pipeline

The dispute-resolution pipeline is the primary data source for model improvement:

```
User correction
     ↓
Dispute record created (image + classification + correction + trust context)
     ↓
Auto-screened (safety, duplicates, farming detection)
     ↓
Reviewed (accepted/rejected)
     ↓
Accepted → Training candidate dataset
     ├── Requalify for consent (is training allowed?)
     ├── Redact PII (faces, addresses, license plates)
     ├── Add to golden set (if reviewer says "high-quality case")
     └── Push to training pipeline (next model iteration)
     ↓
Rejected → Anomaly analysis (pattern detection for model weaknesses)
```

---

## Design Patterns

### Pattern 1: Quick Correction Flow
```
┌───────────────────────────────┐
│   ? Plastic (PET) #1         │
│                               │
│ [That's wrong] ──────────→   │
│                               │
│   What is it?                 │
│   [Paper] [Glass] [Metal]     │
│   [Organic] [Other ▸]         │
│                               │
│ [Submit] [Cancel]             │
└───────────────────────────────┘
```

### Pattern 2: Detailed Correction Form
```
┌───────────────────────────────┐
│ Correct Classification        │
│                               │
│ Correct category:             │
│ [Paper ▸ Craft paper]         │
│                               │
│ What was wrong? (optional)    │
│ [It's not plastic, it's paper]│
│                               │
│ App was:                      │
│ ☐ Wrong category              │
│ ☐ Wrong material              │
│ ☐ Wrong disposal instruction  │
│ ☐ Confident but incorrect     │
│ ☐ Not confident enough        │
│                               │
│ [Submit Correction]            │
└───────────────────────────────┘
```

### Pattern 3: Appeal Status Screen
```
┌───────────────────────────────┐
│ Appeal Status                  │
│                               │
│ Classification: Plastic #1    │
│ Corrected to: Paper           │
│ Submitted: 2 hours ago        │
│                               │
│ Status: Under Review 🟡       │
│ Estimated: ~24 hours          │
│                               │
│ When resolved:                │
│ ✓ Notification                │
│ ✓ Result updated              │
│ ✓ Model improvement           │
└───────────────────────────────┘
```

---

## Implementation Recommendations

### Phase 1 (Quick correction)
- Tap "That's wrong" → pick from list of common categories.
- No review queue — store correction, use for future model training.
- Show acknowledgment: "Thanks, we'll learn from this."

### Phase 2 (Structured disputes)
- Category selection + correction type tags.
- Review queue for safety-critical disputes.
- Acceptance/rejection notifications.

### Phase 3 (Full appeal pipeline)
- Auto-resolution for trusted users + accepted patterns.
- Escalation workflow for disputed reviews.
- Cross-user consensus detection.
- Training pipeline integration with consent checks.

---

## Open Questions

1. Should corrections be visible to other users (community fact-checking) or private?
2. How do we handle the case where the user corrects to the *wrong* answer — how do we detect and prevent?
3. What is the minimum review queue size before auto-resolution is safe?
4. Should we offer a reward for corrections (tokens, points) — does that incentivize farming?
5. How do we handle disputes about disposal instructions (policy) vs disputes about material classification (model)?

---

## Next Steps

1. Design the quick correction flow and add to result screen.
2. Define dispute category taxonomy and correction type tags.
3. Create the dispute record schema in Firestore.
4. Implement auto-resolution rules for high-trust users.
5. Design review queue UI for the operator/admin dashboard.
6. Wire correction acceptance into training data pipeline.
