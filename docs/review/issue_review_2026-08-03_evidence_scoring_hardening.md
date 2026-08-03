# Issue Review: Evidence-backed Environmental Scoring Hardening

Date: 2026-08-03

## Feedback item addressed
The feedback emphasized that environmental fields should not be shown as facts without source, uncertainty, and methodology. This work hardened scoring and impact signaling to require verified environmental evidence.

## What was changed
- `lib/models/waste_classification.dart`
  - `calculatePoints()` now uses `environmentalImpactEvidence` values (with confidence gates) for environmental score bonuses.
  - `getEnvironmentalImpactScore()` now uses evidence-backed environmental metrics only.
  - Added `hasVerifiedEnvironmentalImpactScoreInput` to surface whether impact scoring evidence exists.
  - High CO₂ impact tags now require verifiable metric evidence.
- `lib/widgets/interactive_classification_tags.dart`
  - Environmental impact tag is hidden when no verifiable environmental metrics exist.
- `lib/screens/result_screen.dart`
  - Impact reveal now shows an explicit unverified state if environmental score inputs are not evidence-verified.

## Evidence contracts in use
- Metric reads now look for keys such as
  - `co2_avoidance`, `co2Impact`
  - `water_pollution`, `waterPollutionLevel`
  - `soil_contamination_risk`, `soilContaminationRisk`
  - `human_toxicity`, `humanToxicityLevel`
  - `wildlife_impact`, `wildlifeImpactSeverity`
- The confidence gate keeps the same minimum as nearby UI helpers (`0.55`) to maintain consistency.

## Tests added/updated
- `test/models/waste_classification_test.dart`
  - Added assertion that raw legacy metrics alone do not unlock verified environmental score input.
- `test/enhanced_ai_analysis_v2_test.dart`
  - Updated point/impact scenarios to provide `environmentalImpactEvidence` instead of relying on raw fields.

## Open follow-ups
- Decide whether to create a typed conversion layer for legacy raw environmental fields so legacy records can be retired safely without data loss.
- Decide whether a user-visible metric source badge should be added near CO₂ and impact score surfaces for stronger trust messaging.
