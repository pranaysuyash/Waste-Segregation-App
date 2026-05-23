# AI Learning Flywheel Expansion

This document upgrades the flywheel from scaffold to product-ready foundation.

## Implemented now
- 100+ eval case structure with multi-item and rule-policy fields
- Expanded scoring dimensions: safety/must-not/local-rule/multi-item/confidence behaviors
- Provider-recorded eval support across backend/openai/gemini/local-stub
- Router comparison report + strategy recommendation output
- Hardened dataset export with explicit exclusions and excluded.jsonl
- Review workflow validation for verified labels and privacy constraints
- Runtime verification + evidence summary documentation

## Still scaffold / future
- Real segmentation model integration (currently eval placeholders)
- Runtime router threshold enforcement in app behavior (recommendation-first)
- Full admin dashboard UX (workflow currently CLI/JSONL + backend callables)
