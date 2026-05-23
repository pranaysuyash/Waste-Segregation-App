# AI Eval Golden Case Schema (expanded)

Each JSONL line in `golden_cases.jsonl`:

Required:
- `id`, `imageRef`, `region`, `language`
- `expected.category`
- `mustNot[]`
- `safetyCritical`, `localRuleCritical`

Optional (single-item):
- `expected.itemName`, `expected.subcategory`, `expected.materialType`
- `acceptableAlternatives[]`

Optional (global/local rule):
- `localRuleId`, `globalSafetyRule`, `authority`
- `expectedPolicy.requiresDropoff`
- `expectedPolicy.mustNotBin[]`

Optional (multi-item placeholder):
- `inputHints.multiItem=true`
- `expectedItems[]` with per-item `{ itemName, category }`
- `expectedAggregateWarnings[]`

Prediction record format (`recorded_*.jsonl`) supports:
- `caseId`, `route`, `provider`, `model`
- `prediction.{category,subcategory,materialType,confidence}`
- `latencyMs`, `estimatedCostUsd`, `cacheHit`, `fallbackUsed`, `providerFailure`
- `predictedItems[]`, `aggregateWarnings[]`
