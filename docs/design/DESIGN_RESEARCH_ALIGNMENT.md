# Design & Research Alignment Report

> Captures the current research assets, the implementation surface, and a recommended order of work so we can document alignment before adjusting palette layers.

## 1. Context
- **Research foundation**: `docs/technical/comprehensive_recycling_codes_research.md` documents the completed multi‑AI waste/recycling research (2,100+ lines) along with the expanded `WasteInfo.recyclingCodes` tables and global compliance matrices (`:732`).
- **Design vision**: `docs/design/waste_app_ui_revamp.md` lays out the “Living Earth” palette plus animated onboarding, mission control home, AR-style scan screen, storytelling result flow, and educational experience (`:32-150`).
- **Current implementation snapshot**:
  - Color tokens live in `lib/utils/constants.dart:127-150` (Living Earth colors, `WasteInfo` guidance, recycled/color code maps) while `WasteAppDesignSystem` still uses legacy greens/blues at `lib/utils/design_system.dart:7-66`.
  - Result/dashboard screens (`lib/screens/result_screen.dart:460-750` and `lib/screens/waste_dashboard_screen.dart:168-220`) remain functional/text-heavy and do not yet include the animated narratives or advanced category iconography described in the docs.
  - Recycling-code UI (`lib/widgets/recycling_code_info.dart:1-100`) only surfaces the seven basic codes despite the much wider research tables referenced above.

## 2. Research vs Implementation Gaps
1. **Design tokens and palettes**  
   - Living Earth palette defined twice (`constants.dart` vs `design_system.dart`) and inconsistently applied; widgets still reference the older palette classes.
2. **Experience narrative**  
   - Research calls for mission-control dashboard, AR scan, and impact reveal journeys, but the screens still present data lists without the described animations or micro-storytelling elements.
3. **Educational/knowledge surfacing**  
   - The comprehensive recycling research (including municipal variation tables and hazard handling guidance) is not wired into `WasteInfo`, `RecyclingCodeInfoCard`, or the result/home screens—users only see static descriptions.

## 3. Suggested Documentation Priorities (before color consolidation)
1. **Capture alignment story**: This document plus any additional notes should serve as the single reference point for product, design, and engineering stakeholders to understand why the implementation differs and what we intend to deliver next.
2. **List actionable gaps**:
   - Palette consolidation: keep `lib/utils/constants.dart:127-150` as the source of truth, remove (or replace) the legacy `WasteAppDesignSystem`.
   - Experience enhancements: document which screens need the animated onboarding, mission control layout, AR scan feedback, and result storytelling so future implementation work can be scoped clearly.
   - Knowledge integration: map the research tables to UI locations (e.g., recycling code card, educational carousel, hazards overlay) so the research doesn’t remain “archived” but becomes actionable.

## 4. Next Steps (Post-documentation)
1. **Color system consolidation**: After stakeholders have reviewed this alignment, replace the legacy `WasteAppDesignSystem` color tokens with the Living Earth palette (per `constants.dart:127-150`) and ensure all widgets use the unified tokens.
2. **Experience & knowledge backlog**: Build tickets for enhanced launcher/scan/result animations and the expanded recycling/education experience using this document’s gap list as the acceptance criteria.
3. **Reference tracking**: Whenever new design or research documents surface, append them here so we maintain one living source of truth prior to implementation changes.

*Document created by Codex on request – ready for collaborator review before any UI refactors.*
