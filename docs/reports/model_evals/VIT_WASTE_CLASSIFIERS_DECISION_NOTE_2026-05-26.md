# ViT Waste Classifiers Decision Note (2026-05-26)

## Scope
Evaluate whether either Hugging Face model should be promoted into this repo's near-term routing roadmap:
- `ddompe/vit-waste-classification`
- `Tatyr2210/waste-classification-vit_21Mayo`

This note follows the current repo eval/routing artifacts and `motto_v2.md` execution discipline.

## Ground Truth Used
- Eval harness taxonomy + policy: `eval/classification/README.md`, `eval/classification/schema/golden_case.schema.json`, `eval/classification/golden/golden_cases_v1.jsonl`
- Current routing baseline: `eval/classification/reports/eval_report_offline_v1.json`, `eval/classification/reports/ci_eval_report.json`
- Current runtime routing constraints: `lib/utils/production_safety_config.dart`, `lib/services/providers/ai_provider_router.dart`, `lib/services/classification_pipeline.dart`, `lib/providers/classification_pipeline_providers.dart`
- On-device readiness constraints: `lib/services/on_device_vision_service.dart`, `lib/services/providers/local_vlm_provider.dart`, `docs/design/model_distribution_strategy.md`
- Cloud output contract surface: `functions/src/index.ts`
- Hugging Face model metadata/model cards:
  - https://huggingface.co/ddompe/vit-waste-classification
  - https://huggingface.co/Tatyr2210/waste-classification-vit_21Mayo
  - https://huggingface.co/api/models/ddompe/vit-waste-classification?blobs=true
  - https://huggingface.co/api/models/Tatyr2210/waste-classification-vit_21Mayo?blobs=true

## 1) Current Repository Acceptance Bar (What A Promotion Must Satisfy)

### Taxonomy bar (non-negotiable)
Eval schema enforces 5 canonical top-level categories:
- Wet Waste
- Dry Waste
- Hazardous Waste
- Medical Waste
- Non-Waste

Golden v1 distribution (36 cases):
- Wet: 8
- Dry: 7
- Hazardous: 8
- Medical: 7
- Non-Waste: 6

### Safety/routing bar
Current eval report already marks routing as `review_required` when even the top route has unresolved safety failures. Any new model promotion must not increase safety-critical misroutes.

### Deployment bar
- Release route is backend-first/fail-closed (`ProductionSafetyConfig.useBackendAiInRelease` + provider router behavior).
- On-device Layer-1 is not production-wired yet: `localClassifierProvider` currently returns `FakeLocalClassifier(isModelLoaded: false)`.
- Current on-device service/provider code is still placeholder/unimplemented for real inference.

## 2) Candidate Model Snapshot (as of 2026-05-26)

### `ddompe/vit-waste-classification`
- Base family: ViT (`google/vit-base-patch16-224-in21k` fine-tune per card)
- Labels: 9-way garbage taxonomy
  - Cardboard, Food Organics, Glass, Metal, Miscellaneous Trash, Paper, Plastic, Textile Trash, Vegetation
- Artifact size: `model.safetensors` ~343,243,020 bytes (~327 MiB)
- HF API signals:
  - downloads: 30
  - lastModified: 2026-05-23T05:15:14Z
  - license: apache-2.0

### `Tatyr2210/waste-classification-vit_21Mayo`
- Base model: `google/vit-base-patch16-224-in21k`
- Labels: same 9-way taxonomy as above
- Reported validation metric in card: accuracy 0.9302 (dataset=`imagefolder`, not externally verified)
- Artifact size: `model.safetensors` ~343,245,508 bytes (~327 MiB)
- HF API signals:
  - downloads: 62
  - lastModified: 2026-05-22T03:54:48Z
  - license: apache-2.0

## 3) Taxonomy Mapping Fit Against Repo Canonical Classes

Both ViTs predict the same 9 classes. Approximate mapping to repo canonical categories:
- Food Organics, Vegetation -> Wet Waste
- Cardboard, Glass, Metal, Paper, Plastic, Textile Trash -> Dry Waste
- Miscellaneous Trash -> ambiguous (often Dry, sometimes policy-specific)

Critical gap:
- No explicit Hazardous Waste head
- No explicit Medical Waste head
- No explicit Non-Waste head

Impact:
- At least 21/36 golden cases belong to categories that the model cannot express directly (Hazardous + Medical + Non-Waste).
- Any forced mapping would require heuristic post-routing that introduces exactly the sort of safety drift the current harness is designed to prevent.

## 4) Deployment Compatibility Against Current Architecture

### On-device promotion readiness
Not ready.
- These checkpoints are PyTorch/safetensors ViTs, while current on-device path expects TFLite artifacts and still has placeholder inference.
- Even if converted, ~327 MiB single-model size is far above current bundle strategy assumptions (bundle ~20MB class model, lazy-download large model with explicit UX and reliability controls).
- Promoting now would violate current practical mobile distribution and runtime constraints.

### Cloud-routing promotion readiness
Conditionally possible only as **experimental challenger**, not primary route.
- Cloud path currently expects richer structured output and policy-aware handling in backend pipeline.
- ViT class logits can be used as an extra signal, but not as standalone final classifier because of missing hazardous/medical/non-waste expressivity.
- Any use must stay behind guardrailed routing and must not bypass canonical backend path.

## 5) Comparative Verdict: ddompe vs Tatyr2210

Observed difference today is minor for roadmap quality:
- Both share effectively identical label space and base architecture.
- Tatyr has slightly better hub activity metadata (more downloads) and a reported val accuracy card entry.
- Neither model solves our core taxonomy+safety gap.

Therefore:
- There is no credible basis to promote one to production route while rejecting the other.
- If we test one first, choose `Tatyr2210/waste-classification-vit_21Mayo` purely as an experimental challenger candidate due to better documented eval metadata, not because it meets production bar.

## 6) Promotion Decision

### Decision (current): **Do not promote either model into production on-device or production cloud routing.**

#### On-device roadmap status
- **No promotion** for either model.
- Blockers: format/runtime mismatch, model size, and incomplete local inference implementation.

#### Cloud routing roadmap status
- **No production promotion** for either model.
- Allowed next step: limited A/B challenger path behind backend guardrails, only after adapter + eval integration, with explicit safety gates.

## 7) Concrete Path If We Want to Evaluate Seriously (without architecture drift)

1. Add a new eval adapter in `scripts/eval/run_classification_eval.py` for HF ViT inference (offline recorded first, live optional).
2. Define deterministic 9-class -> 5-class mapping policy file under `eval/classification/` and treat it as an explicit transform with tests.
3. Re-run harness on full golden set and track:
   - strict pass rate,
   - safety failures,
   - must-not violations,
   - per-category failures (especially Hazardous/Medical/Non-Waste).
4. Promotion gate:
   - must not regress safety failures vs current `router_v1` baseline,
   - must not increase hazardous/medical false negatives,
   - must preserve backend-first fail-closed route behavior.

## 8) Recommendation Summary

- `ddompe/vit-waste-classification`: **Hold** (research-only).
- `Tatyr2210/waste-classification-vit_21Mayo`: **Hold** (candidate for controlled challenger evaluation only).
- Production roadmap action now: continue with current backend-first canonical route; if ViT exploration proceeds, do it as a measured eval-track addition, not a routing replacement.

