# Firebase Backend Diagnostics & Health Monitoring

- **Decision it unblocks**: Whether to build a formal health-check and diagnostics system for Firebase Functions, Firestore latency, and cloud service availability.
- **Key questions**:
  - What does the existing `FirebaseBackendDiagnosticsService` already measure?
  - Should diagnostics be exposed to users (e.g., "AI service is slow right now") or only operators?
  - How to detect and communicate partial outages (classify_image down but training_data works)?
  - Integration with crash/performance observability (topic 41) — overlap vs. complement?
- **Kill criteria**: Single-function backend with no need for per-endpoint health.
- **Status**: Seed — 2026-05-25
- **Links**: [`firebase_backend_diagnostics_service.dart`](../../lib/services/firebase_backend_diagnostics_service.dart), [`functions/src/ops_hardening.ts`](../../functions/src/ops_hardening.ts)
- **Source discovery**: Gap analysis — `firebase_backend_diagnostics_service.dart` exists but has no exploration topic; ops_hardening.ts covers some aspects on the server side.
