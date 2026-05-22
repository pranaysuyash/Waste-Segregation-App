# AI Eval Golden Case Schema

Each line in `golden_cases.jsonl` is one eval case with required fields:
- `id`, `imageRef`, `region`, `language`
- `expected.category` (required)
- `mustNot` (list)
- `safetyCritical`, `localRuleCritical`

Optional:
- `expected` details (`itemName`, `subcategory`, `materialType`, `localRule`)
- `acceptableAlternatives`
- `inputHints`
- `notes`
