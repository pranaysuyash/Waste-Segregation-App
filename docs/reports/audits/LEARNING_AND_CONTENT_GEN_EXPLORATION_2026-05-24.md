# Learning and Content Generation Exploration

Date: 2026-05-24

## What exists today

The in-app learning surface is real and self-contained. `EducationalContentService` seeds a fixed library of articles, videos, infographics, quizzes, tutorials, and tips; it also owns bookmarks, deterministic daily tips, and recommendation rules for classification follow-up content.

The main browsing surface is `EducationalContentScreen`, which provides tabbed browsing, search, category filtering, level filtering, and a bookmarked-only toggle. `ContentDetailScreen` opens an individual item and records view/session analytics through `EducationalContentAnalyticsService`.

There is also a separate hidden-content/unlock system in `lib/models/ai_discovery_content.dart` for progression-style rewards. That looks like a gamification layer, not the primary educational catalog.

## What is actually generated

The only live AI content-generation path I found is disposal guidance, not educational articles or lessons. `functions/src/disposal.ts` loads `prompts/disposal.txt`, sends it to OpenAI, validates the structured JSON response, caches the result in Firestore, and falls back to a safe generic response when generation fails.

## What is planned, not shipped

The docs describe a much larger AI-assisted educational CMS: article drafting, quiz question generation, repurposing tools, review workflows, versioning, scheduling, and content analytics. That intent is laid out in `docs/implementation/admin_panel_design.md`, and the repo’s exploration map explicitly calls out “AI-Generated Educational Content” as a distinct topic that still needs a dedicated deep dive.

## Practical read

Right now the learning part is mostly curated, local, and deterministic. The content-gen story is split:

1. Live for disposal instructions.
2. Planned for educational content.
3. Not yet wired into a real authoring or moderation pipeline for lessons or quizzes.

So the app already teaches, but it does not yet have a production educational-content generation system with provenance, moderation, or publishing workflow.
