# AI Model Strategy Discussion

_Date: 2026-05-19_

## Purpose

This note captures the discussion about model strategy for the waste segregation app, with an emphasis on what the app actually needs rather than a generic model comparison.

The key shift in the discussion was to stop treating the problem as a single "best model" choice and instead split it into distinct AI jobs:

1. detection / segmentation
2. classification
3. disposal guidance / policy reasoning

That split matters because the app can benefit from different models and different fallbacks for each job.

## What the Repo Currently Shows

The current repo state still centers on cloud AI plus a placeholder on-device path:

- `lib/utils/constants.dart` defaults to OpenAI-first routing with `gpt-4.1-nano`, `gpt-4o-mini`, `gpt-4.1-mini`, and Gemini fallback via `gemini-2.0-flash`.
- `lib/services/on_device_vision_service.dart` exists, but the implementation is still placeholder-only and does not perform real local inference.
- `docs/reference/APP_KNOWLEDGE_BASE.md` states that no real on-device model binaries are present and that cloud inference is the functional path.
- `docs/launch/LAUNCH_BLOCKERS.md` confirms the unused `tflite_flutter` dependency was removed because local inference was not actually implemented.

## What the App Needs

The app is not just doing one-off chat or generic image captioning. It needs a pipeline that can handle:

- cluttered waste photos
- single-item and multi-item images
- category mapping
- mixed-material ambiguity
- disposal guidance after classification
- offline or privacy-sensitive flows where possible

That means the architecture should support multiple model roles rather than a single monolithic model.

## Recommended Functional Split

### 1. Detection / Segmentation

Use this to find one or more waste items in a messy scene.

This is especially useful when:

- the image contains multiple items
- the item boundaries matter
- the scene is cluttered or partially occluded

### 2. Classification

Use this to decide what the object is and map it into the app's waste categories.

This is the core scan workflow for common items.

### 3. Disposal Guidance / Policy Reasoning

Use this to explain what the user should do with the item in their region.

This layer benefits from a stronger cloud model because it may need:

- region-aware guidance
- edge-case reasoning
- explanation quality
- structured output

## Multi-Model Setup Discussed

The discussion moved toward a multi-model routing stack rather than a single fallback chain.

### Suggested Local / On-Device Candidates

These came up as serious recent options for local or on-device multimodal work:

- Gemma 3 / Gemma 3n
- MiniCPM-V 4.0
- SmolVLM / SmolVLM 256M / 500M

The important distinction is that these are not all interchangeable.

- Some are better for mobile-first multimodal reasoning.
- Some are better for very small-footprint fallback.
- Some are better as a hosted local model rather than true phone-local inference.

### Suggested Cloud Fallback Candidates

For higher-accuracy fallback and policy reasoning:

- Gemini 2.5 Flash / Flash-Lite / Pro
- GPT-5 mini / GPT-5
- o3 or other stronger reasoning-tier model only for hard cases

## Routing Logic Discussed

The app should not behave like:

> image in -> one model -> answer out

Instead, the better shape is:

> image in -> detect/segment -> classify crops -> reconcile categories -> cloud fallback if uncertain -> disposal guidance

This gives the app a place to use different models for different tasks.

## Recommended Fallback Ladder

One practical stack discussed was:

1. on-device detection / segmentation
2. on-device classification
3. tiny on-device fallback model
4. cloud multimodal fallback for ambiguity
5. stronger cloud escalation for hard cases

## Main Takeaway

The app should be designed as a **multi-model system by category**, not just by fallback.

A more complete model map would look like:

- `detector_model`
- `segmenter_model`
- `classifier_model`
- `policy_model`
- `fallback_model`

Each role can be local or cloud-backed depending on latency, cost, privacy, and accuracy requirements.

## Current Status / Actionable Conclusion

The repo is currently not yet at that architecture. The on-device path remains placeholder-only, and the cloud path is still the functional production route.

The best next step is to treat the model layer as a planned multi-stage pipeline rather than a single model toggle.

## Source Boundaries

This note combines:

- repo-verified implementation details from the current checkout
- current vendor documentation and model announcements
- interpretation of how those models map to the waste-segmentation use case

The following should be re-verified before implementation because they may drift over time:

- exact model names
- exact pricing
- exact mobile/on-device deployment constraints
- whether a given model is practical in Flutter / mobile inference stacks

