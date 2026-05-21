# MULTI-MODEL AI STACK FOR WASTE APP

**Last Updated**: 2026-05-21
**Status**: SEED

## Decision it unblocks
This lane defines how waste classification should evolve from a single-provider inference path into a model stack tied to product workflow:

`capture → quality/privacy gate → detect/segment → classify → dispose-policy → user correction → dataset/eval → routing improvement`

The current decision is to postpone full-model fine-tuning until we have:

- consented and versioned data,
- a golden/eval dataset,
- and a routing + calibration pipeline that can measure regressions.

## Links
- Master index: [../EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md)
- Raw capture: [../exploration/backlog.md](../exploration/backlog.md)
- Baseline references: [../review/AI_EVAL_HARNESS_IMPLEMENTATION_PACKET_2026-05-21.md](../review/AI_EVAL_HARNESS_IMPLEMENTATION_PACKET_2026-05-21.md), [../AI_API_RACE_FAULT_TOLERANCE.md](../AI_API_RACE_FAULT_TOLERANCE.md)
- Issue review packet: [../review/multi_model_ai_stack_issue_review_2026-05-21.md](../review/multi_model_ai_stack_issue_review_2026-05-21.md)
- Execution docs:
  - [MULTI_MODEL_AI_STACK_CONTRACTS.md](./MULTI_MODEL_AI_STACK_CONTRACTS.md)
  - [MULTI_MODEL_AI_STACK_PHASE1_EXECUTION.md](./MULTI_MODEL_AI_STACK_PHASE1_EXECUTION.md)
  - [MULTI_MODEL_AI_STACK_DATA_AND_CONSENT_READINESS.md](./MULTI_MODEL_AI_STACK_DATA_AND_CONSENT_READINESS.md)

## Key questions

- Which stack component is the best first model to ship after foundation work?
- How do we decide local vs cloud per image without creating a quality cliff?
- What privacy thresholds are mandatory before image reuse for training/eval?
- How is "uncertainty" represented so routing is explainable and auditable?
- Which correction/eval signals should drive retraining priorities?
- What should be deterministic policy vs probabilistic ML in disposal advice?

## Kill criteria

- No measurable improvement in eval on the same benchmark after at least two rollout waves.
- Privacy gate failures cannot be reduced to deterministic controls + human review.
- Training/eval loop cannot be maintained with the required provenance and versioning.

## 1) Core model lanes

### 1. Waste image classifier
Input image → item/category/material prediction with confidence.

- Early: cloud VLM prompt/embedding classifier, then small classifier head.
- Later: on-device family + region-aware variants.

### 2. Multi-object detection / segmentation
Split cluttered scenes into individual objects and regions.

- Why now: unlocks multi-item guidance and avoids single-label hallucination.
- Early: detector + region crop classifier.

### 3. Image quality model
Bad-photo detection before inference (blur, glare, distance, cut-off, obstruction).

- Why now: reduces cloud spend and user friction by enabling fast re-capture loops.

### 4. PII / privacy risk detector
Faces, addresses, prescriptions, bills, plates, people, children, etc.

- Why now: required before training pool decisions and consented reuse.

### 5. Duplicate / near-duplicate detector
Exact duplicates, crop variants, same-object repeats, spam-like repeats.

- Why now: clean training corpus, reward fairness, cloud cache, anti-spam.

### 6. Confidence calibration
Model outputs include `needsReview` and human-readable reason.

- Why now: controls wrong-confidence loops and escalation policy.

### 7. Model router / escalation model
Given quality, risk, confidence, cost, latency, and user state, selects route:

- cache / local / small cloud / large cloud / race / human review.

### 8. Disposal rule prediction support
ML can rank rules and suggest likely disposal outcome; deterministic policy engine remains source of truth for safety-critical cases.

### 9. OCR / label reading
Read printed recycling and medical/compostable cues before classification finalisation.

### 10. Barcode / product recognition
Barcode → product metadata → material / disposal mapping.

### 11. Active learning / correction question selector
Prioritise uncertain examples and ask one high-value clarification question.

### 12. Training data quality scorer
Score before training/eval admission using quality, confidence, privacy, dedupe, rarity, approval signals.

### 13. Golden eval dataset
Immutable/evolving held-out cases per region and hard-edge class.

### 14. Personalized education model
Sequence tips and reinforcement based on user errors and progress.

### 15. Gamification / abuse model
Protect reward economy from repeat-image abuse, correction spam, low-quality farming.

### 16. Collection / scheduling prediction
Suggest storage and disposal timing with local civic schedule and locality context.

### 17. Material impact estimator
Material and decomposition guidance where it improves user understanding and decision quality.

### 18. Local / on-device inference
Progressive on-device stack:

- quality + duplicate + simple material classifier + privacy checks initially,
- then detector/ocr/router enrichment as model size/compute budget allows.

## 2) Recommended execution order

### Phase 1 — Data foundation
1. explicit training consent
2. training candidate schema
3. image storage + redaction path
4. user correction capture
5. golden eval dataset
6. dataset versioning

### Phase 2 — Eval + routing
1. image quality scoring
2. duplicate detection
3. confidence calibration
4. provider/router model
5. safety-critical evaluation suite

### Phase 3 — Small useful models
1. wet/dry/hazardous/e-waste classifier
2. material family classifier
3. edge-case local model set (e.g. Bengaluru-specific waste semantics)
4. PII rejector

### Phase 4 — Advanced vision
1. detection/segmentation
2. multi-item classification
3. OCR/barcode assisted classification
4. small local VLM / distilled classifier

### Phase 5 — Product intelligence
1. personalized education
2. active learning selector
3. training data quality model
4. abuse/fraud signals
5. habit/retention nudges

## 3) What to avoid in phase 1

- do not start with full VLM fine-tuning.
- do not ship on unlabeled or low-consent data.
- do not route everything to cloud as the permanent default.

## 4) Moat principle

Success is unlikely from model-only gains alone. The long-term defensibility stack is:

`consented real waste imagery + user corrections + Bangalore/local rules + eval harness + dataset versioning + local-first routing + privacy-safe training`.
