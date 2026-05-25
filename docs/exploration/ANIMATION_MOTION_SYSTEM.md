# Animation & Motion System

- **Decision it unblocks**: Whether to consolidate ad-hoc animations across the app into a coherent motion system with shared choreography, timing curves, and transition patterns.
- **Key questions**:
  - What animation patterns exist today (page transitions, success celebrations, shimmer loading, error recovery, educational animations, social animations)?
  - Should animations be centralized (one motion design system) or kept local to each widget?
  - Performance implications: how to ensure 60fps on low-end devices with rich animations?
  - Accessibility: reduced-motion support, animation scaling for vestibular disorders?
- **Kill criteria**: App uses only platform-default page transitions and no custom animations.
- **Status**: Seed — 2026-05-25
- **Links**: [`animation_system.dart`](../../lib/utils/animation_system.dart), [`animation_helpers.dart`](../../lib/utils/animation_helpers.dart), [`enhanced_animations.dart`](../../lib/utils/enhanced_animations.dart), [`animations/`](../../lib/widgets/animations/), [`page_transitions.dart`](../../lib/widgets/animations/page_transitions.dart), [`gen_z_microinteractions.dart`](../../lib/widgets/gen_z_microinteractions.dart)
- **Source discovery**: Gap analysis — 10+ animation/motion files exist with no unifying architecture topic.
