# Federated & Privacy-Preserving Learning — Exploration Doc

**Track**: P3 — Deep Frontier
**Status**: 🟢 Exploration
**Last Updated**: 2026-05-24
**Parent**: [EXPLORATION_TOPICS.md #79](../EXPLORATION_TOPICS.md#79-federated-or-privacy-preserving-learning-)
**Sibling topics**: On-Device Inference (#6), Continuous Learning Loop (F3), Local-First Privacy Architecture (G2), Consent Architecture (A19)

---

## Decision This Unblocks

Whether to invest in a federated learning (FL) pipeline that improves on-device classification models from user corrections without centralizing raw images — and whether this is feasible for a small team or remains a Google-scale technique.

---

## Overview

Federated learning promises a compelling vision: user corrections improve the model without the user's photo leaving the device. But the operational reality for a small team (~1-3 ML engineers) differs dramatically from the research-lab ideal.

**The core tension**: FL is an *infrastructure* problem, not an *algorithm* problem. The algorithm is well-studied. The infrastructure (orchestrating N clients, managing heterogeneous devices, handling stragglers, verifying gradient integrity, maintaining evaluation) is a full-time platform team.

---

## Assessment: Federated Learning at Small Scale

### What FL Actually Requires

| Requirement | Reality |
|-------------|---------|
| On-device model trainable | 3B+ VLM models don't fit on-device training budget. Even 500M-parameter models need GPU for training. |
| Reliable client participation | Users close the app, lose connectivity, have dying batteries. FL clients drop out. |
| Secure aggregation | Without secure aggregation, the server sees raw gradient updates, which can leak training data. |
| Heterogeneous hardware | Mid-range Android (4GB RAM) cannot train what high-end iOS can. |
| Evaluation | Global model evaluation requires held-out data from clients, which contradicts the privacy premise. |
| Rounds to convergence | 100-1000+ rounds for realistic tasks. Each round = days at small MAU. |

### Verdict at Current Scale

**FL is not practical** for this team size and MAU today. The infrastructure overhead would dominate ML work for at least 2 quarters before producing a single accuracy improvement.

---

## Viable Privacy-Preserving Alternatives (Scale-Appropriate)

### Alternative 1: Local-Only Learning + Central Eval (Recommended)

**How it works**:

1. User corrects the app's classification.
2. Correction is stored ephemerally on-device.
3. A **local adapter** (lightweight fine-tuning of a subset of model weights) runs on-device when the device is charging + Wi-Fi.
4. The locally-improved model replaces the previous on-device model.
5. **No data leaves the device.**

**Central improvement path**:

- Periodically (weekly), the team hand-labels corrections from **consented, reviewed users** whose corrections would not leak private information.
- These labelled corrections enter the golden eval set (#5).
- The central model is fine-tuned on this curated dataset.
- The updated model is distributed to devices via CDN (model download service).

**Why this works at small scale**:

- Zero privacy risk — no raw user data ever transmitted.
- Straightforward eval — compare curated set before/after.
- Infrastructure = existing model download pipeline + one weekly batch job.
- Improvement compounds over time as the eval set grows.

**Limitation**: Hard-example coverage grows only as fast as the curated set, which is bounded by human review bandwidth.

### Alternative 2: Correction Feedback → Prompt Engineering

**How it works**:

1. Aggregated, anonymized correction patterns are analyzed weekly.
2. "Users are correcting Material X from Paper to Plastic 30% of the time."
3. Prompt adjustments are made to the cloud model's system prompt.
4. The cloud model improves for all users.

**Why this works**:

- Requires zero on-device training infrastructure.
- Leverages the existing prompt-versioning discipline (#1a).
- Fixes the underlying model behavior, not just a user's device.

**Trade-off**: Only works for cloud-invoked models, not on-device-only cases.

### Alternative 3: One-Shot Distillation

**How it works**:

1. On-device model processes corrections locally.
2. Instead of gradient upload, the on-device model generates **soft labels** (probability distributions) for a small set of curated unlabelled examples.
3. These soft labels (not images) are uploaded with user consent.
4. Central teacher model learns from the aggregated soft labels.

**Why this is better than FL**:

- Single communication round per update cycle — no round coordination.
- Soft labels leak much less about the source data than gradients.
- Feasible on-device (forward pass only, no backwards pass).

**Limitation**: Still requires consent + anonymization pipeline for soft-label uploads.

---

## Recommended Path

### Phase 1 (Now — Ready): Local-Only + Central Eval

| Component | Timeline | Effort |
|-----------|----------|--------|
| On-device correction ephemeral storage | Week 1 | 2-3 days |
| Weekly correction pattern analysis | Week 2 | 1 day/week recurring |
| Prompt improvement cycle from patterns | Week 3 | 1 day/week recurring |
| Golden set enrichment from consented corrections | Week 4 | 2 days/week recurring |

**Cost**: ~0.5 engineer/week recurring. **Privacy**: zero data leaves device without explicit consent.

### Phase 2 (6-12 months): One-Shot Distillation Pilot

- Add soft-label generation to the on-device model.
- Consent flow for "share anonymized improvement signal (not your photos)."
- Aggregate one round per month, run eval.

### Phase 3 (18+ months): Federated Learning if conditions are met

**Promotion gate**: Do not invest in FL until all of:
- On-device model is > 500K MAU reach.
- At least 1 dedicated ML infra engineer.
- One-shot distillation Phase 2 showed measurable improvement.
- Privacy review of gradient leakage risk is signed off.

**Kill criteria**: If Phase 2 shows < 2% accuracy improvement after 6 months, skip Phase 3 entirely.

---

## Research Sources

- Google Federated Learning (McMahan et al., 2017) — original paper, core algorithm.
- TensorFlow Federated — practical FL framework, requires TF on device.
- Apple's Differential Privacy implementation — operational reference for privacy-preserving learning at consumer scale.
- Zhu et al. (2019) "Deep Leakage from Gradients" — FL does not automatically protect privacy.
- Papernot et al. (2018) "Semi-supervised Knowledge Distillation" — one-shot distillation alternative.

---

## Concrete Next Steps

1. ✅ Do not start FL implementation.
2. Set up weekly correction pattern analysis (terminal command: export from Firestore corrections collection, pipe through aggregation script).
3. Document the prompt-improvement cycle in `docs/guides/prompt_improvement_cadence.md`.
4. Add consent telemetry to track what % of users opt into training data use.
5. Reassess FL after on-device model Phase C is live and > 50K corrections accumulated.
