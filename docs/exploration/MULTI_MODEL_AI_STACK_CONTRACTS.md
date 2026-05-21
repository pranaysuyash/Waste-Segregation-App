# Multi-Model AI Stack — Model Contracts

**Last Updated**: 2026-05-21  
**Owner**: Exploration / Architecture stack lane  
**Status**: SEED

## Scope

This document captures model contracts for the stack in [MULTI_MODEL_AI_STACK.md](./MULTI_MODEL_AI_STACK.md).

For each lane we track:

- input surface
- output contract
- confidence / uncertainty output
- required telemetry fields
- safety / privacy guardrails
- upstream/downstream dependency

## Shared contract primitives

- `model_version`: string
- `model_route`: one of `cache`, `local`, `small_cloud`, `large_cloud`, `parallel_race`, `manual_review`
- `model_latency_ms`: number
- `model_cost_usd`: number (estimated)
- `raw_confidence`: number [0.00, 1.00]
- `calibrated_confidence`: number [0.00, 1.00]
- `needs_review`: boolean
- `review_reason`: string | null
- `region_code`: string (e.g. `IN-KA-BLR`)
- `policy_pack_id`: string
- `prompt_or_model_config_id`: string
- `provenance`: object with keys `caller`, `ts_utc`, `request_id`

## Contracts

### Quality Gate Model (A1)

**Input**: image bytes, capture metadata (resolution, focus estimate), capture mode.

**Output**:

- `quality_score`: number [0,1]
- `quality_blockers`: list of enum values (`blur`, `too_dark`, `too_bright`, `glare`, `too_close`, `too_far`, `out_of_frame`, `obstructed`)
- `action`: enum `accept`, `retake`, `cloud_retry`, `manual_review`

**Guardrails**: No image leaves client without a quality decision; bad images should not incur cloud classification if avoidable.

### PII Risk Classifier (A4)

**Input**: image bytes, user consent state.

**Output**:

- `pii_score`: number [0,1]
- `pii_flags`: list enum (`faces`, `address`, `phone`, `license_plate`, `prescription`, `children`, `people`, `indoors`)
- `training_eligible`: boolean
- `action`: enum `allow_classify_only`, `redact_required`, `reject_for_training`, `manual_review`

**Guardrails**: Never set `training_eligible=true` unless user consent explicitly allows reuse and no blocking flags.

### Object Detection / Segmentation (A2)

**Input**: pre-checked image bytes, quality_pass boolean, optional cropping hints.

**Output**:

- `items`: array of objects with `box`, `mask`, `class_name`, `class_confidence`, `suggested_category`
- `object_count`: number
- `multi_object`: boolean

**Guardrails**: object classes must be mapped to app taxonomy before classifier hand-off.

### Waste Classifier (A3)

**Input**: image bytes or cropped object crop(s), optional OCR/metadata hints.

**Output**:

- `item_label`
- `category` (`wet_waste`, `dry_waste`, `hazardous`, `e_waste`, `medical`, `non_waste`, `reject`)
- `subcategory`
- `material`
- `calibrated_confidence`
- `needs_review`
- `needs_manual_rules_check`: boolean

**Guardrails**: must keep a category that is intentionally non-certain; never force deterministic output below confidence floor.

### Duplicate / Near-Duplicate Detector (A5)

**Input**: candidate image, optional user hash history.

**Output**:

- `duplicate_exact`: boolean
- `duplicate_crop`: boolean
- `similar_item_cluster_id`: string | null
- `duplicate_score`: number [0,1]

**Guardrails**: if `duplicate_score` above threshold, do not create additional training candidate without audit reason.

### Confidence Calibration / Ambiguity Model (A6)

**Input**: raw model outputs from classifier and detector.

**Output**:

- `calibrated_confidence` (per-class + overall)
- `uncertainty_buckets`: `high`, `medium`, `low`
- `needs_review`: boolean
- `review_reason`

**Guardrails**: route high uncertainty to escalation and user correction flow.

### Route / Escalation Model (A7)

**Input**: `quality_score`, `pii_score`, `duplicate_score`, uncertainty bucket, user tier, network state, cost budget, policy risk.

**Output**:

- `route`
- `max_cost_usd`
- `timeout_ms`
- `fallback_route`
- `requires_high_accuracy`: boolean

**Guardrails**: route must be replayable from logged telemetry.

### OCR + Label Extraction (A8)

**Input**: full image or crop.

**Output**:

- `ocr_text`: plain text
- `detected_codes`: list (e.g., `PET`, `HDPE`, `PVC`, `compostable`)
- `expiry_or_medication_flags`: list

**Guardrails**: parsed text is advisory; disposal policy still comes from policy engine.

### Barcode Classifier/Lookup (A9)

**Input**: crop or full-image barcode signal.

**Output**:

- `barcode`
- `product_match_confidence`
- `source`
- `suggested_material`
- `suggested_disposal_route`

**Guardrails**: must require positive barcode validation confidence before trust.

### Active Learning Question Selector (A10)

**Input**: uncertain classifications, user correction history, class rarity metadata.

**Output**:

- `should_ask`: boolean
- `question_id`
- `question_text`
- `expected_answer_schema`
- `expected_value`

**Guardrails**: one clarifying question per uncertain image unless explicit refusal.

### Training Data Quality Scorer (A11)

**Input**: labeled candidate, quality score, corrections, duplicate score, privacy status, rarity metadata.

**Output**:

- `training_value`
- `eligible_for`: list from `eval`, `training`, `hard_cases`, `abuse_queue`
- `reason_code`

**Guardrails**: no auto-accept for low-quality or privacy-eligible false items.

### Golden Eval Case Format (A12)

**Input**:

- curated image path/ID,
- expected label,
- must-not constraints,
- region context,
- safety tag set.

**Output**:

- deterministic evaluator result for benchmark run,
- error class attribution (`underfit`, `policy_mismatch`, `privacy_block`, `calibration_gap`).

**Guardrails**: eval runs must be versioned and produce drift alerts.

### Personalised Education Model (A13)

**Input**: user interaction history, category errors, streak state, completion context.

**Output**:

- `tip_variant`
- `difficulty_level`
- `delivery_style`
- `show_delay_seconds`

**Guardrails**: avoid sensitive assumptions about user identity, keep personalization local where possible.

### Abuse / Reward Fraud Signals (A14)

**Input**: user activity sequence, upload cadence, duplicate scores, low-quality rates.

**Output**:

- `risk_score`
- `signals`
- `action`: `allow`, `throttle`, `hold_rewards`, `manual_review`

**Guardrails**: suspicious events should preserve user rights with transparent remediation path.

## Cross-cutting outputs in `result_pipeline`

Every model contract output should be attached to the classification payload in a single canonical event envelope so routing, audit, and replay use one path.

- `vision_lane_version`
- `applied_models[]`
- `policy_pack_id`
- `disposal_rule_id`
- `correction_state`

## Open questions

- What minimum confidence floor is acceptable for each material category?
- What model latency floor is acceptable for each user tier?
- Which `must_not` constraints should block automatic classification finalisation?

