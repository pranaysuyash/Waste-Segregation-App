# AI Flywheel Runtime Verification

Date: 2026-05-23
Command run:

```bash
./tools/verify_ai_flywheel_foundation.sh
```

## Pass/Fail summary
- Flywheel tests: pass
- Offline eval: pass
- Recorded provider evals: pass
- Merge records: pass
- Router report: pass
- Dataset export: pass
- Review workflow export/apply/report: pass
- Seed coverage report: pass
- Evidence summary: pass
- Acceptance report: pass (`12/12`)

## Generated artifacts
- `build/reports/ai_eval/latest.json`
- `build/reports/ai_eval/offline_latest.json`
- `build/reports/ai_eval/recorded_backend_latest.json`
- `build/reports/ai_eval/recorded_openai_latest.json`
- `build/reports/ai_eval/recorded_gemini_latest.json`
- `build/reports/ai_eval/recorded_local_latest.json`
- `build/reports/ai_eval/merged_records.jsonl`
- `build/reports/ai_eval/router_compare_backend.json`
- `build/reports/ai_eval/router_strategy_recommendations.md`
- `build/reports/ai_eval/seed_coverage_report.json`
- `build/reports/ai_dataset/latest/manifest.jsonl`
- `build/reports/ai_dataset/latest/labels.jsonl`
- `build/reports/ai_dataset/latest/datasheet.md`
- `build/reports/ai_dataset/latest/excluded.jsonl`
- `build/reports/ai_dataset/latest/version.json`
- `build/reports/ai_review/review_template.jsonl`
- `build/reports/ai_review/updated_candidates.jsonl`
- `build/reports/ai_flywheel/acceptance_report.json`
- `build/reports/ai_flywheel/FINAL_EVIDENCE_SUMMARY.md`

## Failures fixed
- Verifier ordering updated so acceptance runs after coverage and evidence artifacts.
- Verifier fail-closed assertions enforce artifact completeness and `allPassed=true`.

## Remaining gaps
- Live provider eval remains opt-in and intentionally disabled by default.
- Local segmentation model is still placeholder (eval support is present).

## Acceptance report meaningfulness
- `acceptance_report.json` validates runtime artifact presence, semantic coverage, and stricter criteria (100+ cases).
- It is meaningful for go/no-go at scaffold layer; model quality still needs human review.

## Seed-case semantic breadth
- Coverage validator now checks household/safety/e-waste/ambiguous/multi-item/region-rule families.
- Cases expanded beyond count-only to structured risk families.
