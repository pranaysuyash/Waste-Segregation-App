# Memory Management on Mobile

- **Decision it unblocks**: Strategy for preventing OOM crashes on low-RAM devices during image classification, model inference, and large list rendering.
- **Key questions**:
  - What does the existing `MemoryManagementService` monitor and trigger?
  - Should we preemptively degrage model quality (smaller input, lighter model) based on free RAM?
  - How to handle iOS memory warnings vs. Android `onTrimMemory` differently?
  - Image caching budget: how many bitmaps to keep in memory before evicting to disk?
- **Kill criteria**: Target devices all have >= 8GB RAM; OOM crashes are < 0.1% of sessions.
- **Status**: Seed — 2026-05-25
- **Links**: [`memory_management_service.dart`](../../lib/services/memory_management_service.dart), [`performance_monitor.dart`](../../lib/utils/performance_monitor.dart), [`image_utils.dart`](../../lib/utils/image_utils.dart)
- **Source discovery**: Gap analysis — `memory_management_service.dart` exists but has no exploration topic; RAM/OOM mentioned only in passing in other topics.
