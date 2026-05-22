# Backend Platform and Money Strategy Review

Date: 2026-05-22
Repo: /Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app
Primary objective: fastest path to launch and revenue without locking the app into bad architecture.

## 1. Executive summary

Decision:
- Keep Firebase as core backend for launch.
- Harden current Firebase + Functions stack immediately (security, spend enforcement, storage policy, entitlement authority).
- Add Cloudflare now only for public web/content/acquisition edge.
- Keep Cloud Run as targeted follow-up for heavy AI/image/batch workloads after telemetry.
- Run InsForge as a short spike, not migration.
- Do not migrate to Supabase/VPS/Cloudflare-only now.

Why:
- Revenue speed and operational certainty are currently more valuable than platform novelty.
- The app already depends on Firebase Auth, Firestore, Storage, App Check, Functions, Analytics, Crashlytics, and Remote Config.
- Launch blockers are hardening gaps, not missing platform capability.

Confidence:
- High confidence in launch-path recommendation (repo-grounded).
- Medium confidence in exact cross-platform cost deltas at scale because live pricing re-fetch was blocked in this session; official links included for verification at execution time.

## 2. Repo/backend context

Instruction order applied:
1) /Users/pranay/AGENTS.md
2) /Users/pranay/Projects/AGENTS.md
3) repo AGENTS.md
4) motto_v2.md
5) firebase_task.md

Current backend reality:
- Firebase-first mobile backend.
- Server-authoritative classify token reservation/refund controls already added in Functions.
- Release fail-closed backend AI routing already implemented in Flutter AI service.
- Remaining launch-critical work is policy hardening and operational consistency.

## 3. Current backend capability map

Legend:
- MVP needed: Yes/No
- Defer: Yes/No

| Capability | Current implementation | Key files | Service | Business importance | Revenue importance | User risk if broken | Migration difficulty | MVP needed | Defer |
|---|---|---|---|---|---|---|---|---|---|
| Authentication | Firebase Auth with guest-aware flows | lib/main.dart, firestore.rules | Firebase Auth | High | High | High | High | Yes | No |
| User profile | Firestore user documents | firestore.rules, lib/services/firebase_family_service.dart | Firestore | High | Medium | Medium | High | Yes | No |
| Guest mode | App supports non-auth paths | lib/main.dart, services | App + Firebase optional | High | Medium | Medium | Medium | Yes | No |
| Classification history | Persisted in Firestore/local | services/storage and result pipeline | Firestore + Hive | High | High | High | High | Yes | No |
| Classification feedback/corrections | Feedback export/report pipelines present | eval/classification/*, functions/training hooks | Firestore + Functions | Medium | Medium | Medium | Medium | No | Yes |
| AI classification | Callable backend classify path | functions/src/classify_image.ts, lib/services/ai_service.dart | Functions 2nd gen | High | High | High | High | Yes | No |
| Disposal instruction generation | AI + fallback guidance paths | lib/services/ai_service.dart, prompts/disposal.txt (if present) | Functions + client fallback | High | High | Medium | Medium | Yes | No |
| API key hiding | Backend proxy available; direct client paths still exist behind release safeguards | lib/services/providers/backend_proxy_provider.dart, lib/services/ai_service.dart | Functions | High | High | High | Medium | Yes | No |
| Model gateway (OpenAI/Gemini) | Multi-provider with server routing; residual direct clients in repo | lib/services/providers/*, functions/src/classify_image.ts | Functions + provider APIs | High | High | High | Medium | Yes | No |
| Cost guardrails | Token spend enforcement and wallet checks present | functions/src/classify_image.ts, lib/services/cost_guardrail_service.dart | Functions + app services | High | High | High | Medium | Yes | No |
| Daily quota/free limits | Config and token policy paths exist | token_service, remote config, functions | Functions + Firestore | High | High | Medium | Medium | Yes | No |
| Token wallet | Wallet + transaction logic in app and backend spend callable | lib/services/token_service.dart, functions/src/index.ts | Firestore + Functions | High | High | High | Medium | Yes | No |
| Payments/premium | Purchase + entitlement sync flow exists | lib/services/purchase_service.dart, premium_service.dart | Store + Firestore + claims | High | High | High | High | Yes | No |
| Ads | Ad service integrated | lib/services/ad_service.dart | Ad SDK + Remote Config | Medium | High | Medium | Medium | Yes | No |
| Remote config/feature flags | Remote Config service and dependencies present | lib/services/remote_config_service.dart, pubspec.yaml | Firebase Remote Config | High | High | Medium | Medium | Yes | No |
| Crash/error reporting | Crashlytics integration | lib/main.dart, deps | Firebase Crashlytics | High | Medium | Medium | Medium | Yes | No |
| Analytics | Analytics service present | lib/services/analytics_service.dart | Firebase Analytics | High | High | Medium | Medium | Yes | No |
| Push notifications | Firebase messaging path | deps/services | FCM | Medium | Medium | Medium | High | No | Yes |
| Image upload/storage | Cloud storage services in app; rules gap exists | cloud_storage_service.dart, storage_service.dart | Firebase Storage | High | High | High | High | Yes | No |
| Local Hive storage | Local persistence present | enhanced_storage_service.dart, Hive files | Local | High | Medium | Low | Low | Yes | No |
| Offline mode | Local/cache fallback behaviors | storage + result pipeline | Local + app logic | Medium | Medium | Low | Medium | Yes | No |
| On-device ML/model download | Model download and object detection services | model_download_service.dart, object_detection_service.dart | On-device + cloud assets | Medium | Medium | Medium | Medium | No | Yes |
| Gamification | Points/rewards logic present | gamification_service.dart | Firestore + local | Medium | Medium | Low | Medium | No | Yes |
| Achievements | Achievement logic present | gamification-related services | Firestore | Low | Medium | Low | Medium | No | Yes |
| Leaderboards | Community/gamification scaffolds | community/family services | Firestore | Low | Medium | Low | Medium | No | Yes |
| Family features | Family/group services exist | firebase_family_service.dart | Firestore | Medium | Medium | Medium | High | No | Yes |
| Community feed | Community service present | community_service.dart | Firestore | Low | Medium | Low | High | No | Yes |
| Sharing/deep links | Dynamic link service present | dynamic_link_service.dart | Firebase Dynamic Links | Medium | Medium | Low | High | No | Yes |
| Data export/delete/privacy | Not fully evidenced end-to-end as a unified flow | docs + services | Mixed | High | Medium | High | High | Yes | No |
| Admin/diagnostic endpoints | Ops hardening dashboard endpoints exist | functions/src/ops_hardening.ts | Functions + Firestore | Medium | Medium | Low | Medium | No | Yes |
| Batch/scheduled jobs | Scheduler and batch processor exist | functions/src/index.ts, functions/batch_processor.js | Functions | Medium | Medium | Medium | Medium | No | Yes |
| CI/CD | Multiple workflows present | .github/workflows/*.yml | GitHub Actions | High | High | Medium | Medium | Yes | No |
| Play Store readiness | Not fully validated in this pass; build/release workflows exist | workflows + docs | CI + app config | High | High | High | Medium | Yes | No |
| Landing page/marketing site | No first-class production lane in repo | docs/workflows | N/A yet | High | High | Low | Medium | Yes | No |
| SEO/public content | Not operationalized in deployment stack yet | docs only | N/A yet | Medium | High | Low | Medium | No | Yes |
| Open-source contributor setup | Repo includes docs/workflows; drift exists | README/docs | GitHub | Medium | Medium | Low | Low | Yes | No |

## 4. Current risk inventory

P0 (blocks launch/money)
1) Missing storage.rules while storage is active.
2) Residual direct client AI provider code paths in repository (misconfiguration risk).
3) Entitlement authority split risk between claims and Firestore billing entitlement state.

P1 (serious production risk)
4) functions.config() legacy usage remains in batch processor.
5) Firestore rules/model drift potential across rapidly evolving features.
6) Incomplete deterministic environment split enforcement (dev/staging/prod consistency risk).

P2 (long-term architecture risk)
7) Monolithic function surfaces increase operational coupling.
8) Weak explicit migration contracts for future relational workloads.
9) Cloud Run selective offload path not yet codified as deployment contract.

P3 (cleanup)
10) Documentation supersession drift.
11) Test/lint exclusions and noise in some lanes.

## 5. Firebase assessment

Strengths now:
- Already integrated across core app surfaces.
- Fastest path to revenue with lowest migration tax.
- Good managed primitives for auth, document data, messaging, crash, analytics.

Weaknesses now:
- Cost unpredictability if reads/writes and storage access are not tightly controlled.
- Security correctness depends on rigorous rules and callable boundary discipline.
- Document model can become awkward for relational/report-heavy B2B analytics.

Decision:
- Keep Firebase as launch core and harden immediately.

## 6. Firebase Functions 2nd gen / Cloud Run assessment

Current state:
- Functions 2nd gen style callable/runtime already present.
- classify route has spend reservation/refund and auth enforcement.
- Legacy functions.config remains in batch lane.

Decision:
- Short term: keep on Functions and close config debt.
- Near term: move only clearly heavy workloads to Cloud Run after telemetry (latency/cost/error evidence).
- Avoid broad migration now.

## 7. Cloudflare assessment

Best immediate use:
- Landing page and public waste-guide content.
- Edge caching/CDN for public assets.
- Turnstile/WAF/rate-limiting for public endpoints and lead funnels.

What not to move now:
- Core authenticated mobile backend state (auth/user data/token wallet).

Decision:
- Additive Cloudflare usage now for acquisition/public edge only.

## 8. InsForge assessment

First-principles view:
- Attractive for agent-oriented workflows and relational data flexibility.
- Current app has zero runtime InsForge integration; migration would be significant.
- Unknown maturity and mobile SDK fit must be tested in a constrained spike.

Decision:
- Run 2-day spike only.
- Do not migrate production backend now.

## 9. Supabase/VPS sanity check

Supabase:
- Strong relational SQL and developer ergonomics.
- Migration cost from Firebase-first product is high right now.
- Not fastest to first revenue.

VPS/custom backend:
- Maximum control, maximum ops burden.
- High distraction risk before monetization proof.

Decision:
- Defer both as primary backend migration choices for now.

## 10. Cost model rough scenarios

Note: live pricing pull was blocked in this session; use official links in section 20 before final budget lock.

Scenario assumptions (directional only):
- 100 users: low request rate, mostly free tier, modest storage.
- 1,000 users: meaningful daily classify volume, mixed ad/premium.
- 10,000 users: high classify and media growth.

Directional cost behavior:
- Firebase-only: lowest migration overhead; can spike on read/write/storage if rules and access patterns are loose.
- Firebase + Cloudflare edge: lower public bandwidth and better acquisition-site economics.
- Firebase + selective Cloud Run: better control for heavy compute but adds deployment surface.
- Full migration options: high one-time engineering cost and delay cost (lost revenue weeks).

Money-first interpretation:
- Near-term largest cost risk is not vendor unit price; it is abuse, weak quota enforcement, and misrouted paid AI calls.

## 11. Monetization backend requirements

Free tier must-have before launch:
- Daily free classifications enforced server-side.
- Ad-supported scan gating via backend flags.
- Limited history and baseline disposal guidance.
- Safe fallback behavior when paid AI unavailable.

Paid tier must-have before launch:
- Premium entitlement source of truth on server.
- Ad-free premium gating.
- Increased scan allowance and stronger features.

Token wallet must-have before launch:
- Server-side spend before paid classify execution.
- Reservation -> consumed/refunded lifecycle.
- Duplicate-spend/idempotency guard.
- Clear relationship between quota and token balance.

Abuse controls must-have before launch:
- App Check enforced in production.
- Per-UID rate limiting.
- Request logging with non-sensitive telemetry.

Can defer until after launch:
- Complex B2B analytics/reporting packages.
- Advanced relational city/compliance dashboards.
- Full partner ecosystem workflows.

## 12. Deployment strategy

MVP deployment split:
- Mobile backend APIs: Firebase Functions.
- Core app state: Firestore + Firebase Auth + Storage.
- Public content/landing: Cloudflare Pages (or equivalent edge-hosted static route).

Environment discipline:
- Explicit dev/staging/prod env variables.
- Secrets in managed secret stores only.
- No client-side production API secrets.

CI/CD:
- Keep GitHub Actions as central pipeline.
- Gate deployments on test/analyze/rules checks.
- Add storage rules validation lane and entitlement/monetization regression lane.

Rollback:
- Preserve callable backward compatibility.
- Remote Config kill switches for risky lanes.

## 13. Firestore vs Postgres future data model

Firestore currently fits:
- Mobile-first transactional paths.
- Real-time app interactions with low schema friction.

Postgres would improve later:
- Complex joins for B2B reporting.
- Strong relational integrity for multi-tenant org/apartment/school dashboards.
- Analytical queries over classifications, tokens, compliance, and partner conversions.

Migration view:
- Do not migrate core transactional surfaces pre-revenue.
- If/when B2B/reporting grows, consider phased relational sidecar or scoped migration by bounded context.

## 14. Weighted decision matrix

Weights (from firebase_task.md):
- 30% time to launch/revenue
- 20% operational simplicity
- 15% cost predictability
- 15% long-term architecture
- 10% agent-friendliness
- 10% migration risk/reversibility

Scores (1-5):

| Option | Launch/revenue | Ops simplicity | Cost predictability | Long-term architecture | Agent-friendliness | Migration risk/reversibility | Weighted score |
|---|---:|---:|---:|---:|---:|---:|---:|
| Firebase hardening | 5 | 5 | 4 | 3 | 4 | 5 | 4.50 |
| Firebase + Functions 2nd gen hardening | 5 | 4 | 4 | 4 | 4 | 4 | 4.30 |
| Firebase + Cloud Run selective | 4 | 3 | 4 | 4 | 4 | 4 | 3.90 |
| Firebase + Cloudflare (additive) | 5 | 4 | 4 | 4 | 4 | 4 | 4.30 |
| InsForge migration now | 2 | 2 | 3 | 4 | 4 | 2 | 2.65 |
| InsForge spike only | 4 | 4 | 4 | 4 | 5 | 4 | 4.10 |
| Supabase migration now | 2 | 2 | 3 | 4 | 4 | 2 | 2.65 |
| Cloudflare-only backend | 1 | 2 | 3 | 3 | 3 | 2 | 2.00 |
| VPS/custom now | 1 | 1 | 3 | 4 | 2 | 1 | 1.75 |

## 15. Recommended path

Recommended default stack for current stage:
1) Firebase core + Functions hardening for launch.
2) Cloudflare additive for public web/acquisition.
3) Optional targeted Cloud Run move after launch telemetry.
4) InsForge constrained spike in parallel only.

## 16. What to do this week

1) Create and enforce storage.rules with tests/emulator validation.
2) Remove or hard-disable production direct AI provider paths in client code.
3) Finalize entitlement authority contract (server canonical field + claims sync as propagation only).
4) Remove remaining functions.config() dependency from batch path.
5) Add explicit monetization regression tests (insufficient wallet, idempotent retry, premium discount).
6) Add production App Check/rate-limit enforcement checklist to release gate.
7) Stand up minimal Cloudflare landing/content lane for acquisition.

## 17. What not to do this week

1) Do not execute full backend migration to InsForge/Supabase/VPS.
2) Do not split backend ownership across multiple databases without bounded context.
3) Do not move all AI to Cloud Run before measuring current lane behavior.
4) Do not add infra novelty that delays monetization proof.

## 18. 2-day InsForge spike plan

Day 1
- Build minimal auth + user profile + one classify metadata write/read flow.
- Validate Flutter/mobile SDK and session flow.
- Map Firebase equivalents and identify hard gaps.

Day 2
- Implement token wallet reservation prototype and one entitlement check path.
- Run load-smoke and developer-experience checks.
- Produce go/no-go with explicit blockers and migration tax estimate.

Pass criteria
- Mobile auth/session is stable.
- Server-side spend/entitlement controls are feasible without major workaround layers.
- Operational ergonomics are acceptable for small team velocity.

Fail criteria
- Weak mobile/auth ergonomics.
- Missing critical features that require custom replacement of too many Firebase primitives.
- Setup and maintenance overhead exceeds expected near-term benefit.

## 19. Agent task breakdown

Global rules for all agents:
- Follow motto_v2.
- Read-only git unless explicitly authorized.
- Preserve parallel work.
- No “pre-existing” bypass.
- Re-verify state before edits.

Agent A: Backend production hardening (Firebase/Functions)
- Scope: storage rules, App Check enforcement, functions.config cleanup.
- Inspect: functions/src/index.ts, functions/src/classify_image.ts, functions/batch_processor.js, firebase.json, firestore.rules.
- Likely touch: functions/src/*, storage.rules, docs/config/environment_variables.md, test harness.
- Out-of-scope: platform migration.
- Acceptance: secure callable boundaries, no legacy config path, rules validated.
- Validation: npm --prefix functions run build; emulator/rules tests.
- Risks: accidental behavior changes in batch lane.
- Deliverable: hardening PR + test evidence doc.

Agent B: InsForge spike design/prototype plan
- Scope: 2-day spike implementation and findings.
- Inspect: auth/profile/token flows and mobile integration.
- Touch: docs/review spike report and optional prototype folder only.
- Out-of-scope: production cutover.
- Acceptance: pass/fail matrix with quantified migration tax.
- Validation: prototype runbook + smoke tests.
- Risks: over-scoping spike.
- Deliverable: spike decision report.

Agent C: Cloudflare landing/content/CDN lane
- Scope: edge-hosted landing and public guide pages with basic analytics.
- Inspect: docs/marketing/deployment plans, public content surfaces.
- Touch: landing deployment configs, docs.
- Out-of-scope: core mobile auth/data backend.
- Acceptance: deployed landing with attribution and cache policy.
- Validation: route checks, lighthouse baseline.
- Risks: attribution disconnect to app conversion.
- Deliverable: deployment package + funnel instrumentation notes.

Agent D: Monetization backend model
- Scope: quota, token, ads, premium policy contract unification.
- Inspect: token_service, premium_service, purchase_service, classify_image.ts.
- Touch: server policy code + tests + docs.
- Out-of-scope: ad-network UI optimization.
- Acceptance: policy matrix enforced server-side, tests cover abuse paths.
- Validation: wallet/quota/premium emulator tests.
- Risks: entitlement drift race conditions.
- Deliverable: policy contract + test report.

Agent E: AI cost-control/model gateway
- Scope: enforce provider routing, fallback contract, cost telemetry.
- Inspect: ai_service, backend_proxy_provider, classify function, remote config.
- Touch: gateway/config/testing docs.
- Out-of-scope: model migration project.
- Acceptance: no production direct-key path, measurable per-request cost metrics.
- Validation: release-mode smoke tests + telemetry assertions.
- Risks: fallback behavior regressions.
- Deliverable: gateway hardening and observability report.

Agent F: Firestore vs Postgres future model
- Scope: bounded-context migration map for future B2B/reporting scale.
- Inspect: domain entities and current Firestore schemas.
- Touch: architecture docs only unless approved.
- Out-of-scope: actual migration execution.
- Acceptance: entity-by-entity migration feasibility and sequence.
- Validation: architecture review walkthrough.
- Risks: premature migration pressure.
- Deliverable: phased data-model roadmap.

Agent G: CI/deployment/release pipeline hardening
- Scope: enforce rules tests and monetization regression lanes in CI.
- Inspect: .github/workflows/*.yml, firebase deploy scripts.
- Touch: workflow files + docs.
- Out-of-scope: business logic changes.
- Acceptance: deterministic gates for launch-critical checks.
- Validation: workflow dry-runs / CI pass evidence.
- Risks: slower pipeline if over-bloated.
- Deliverable: CI hardening summary.

Agent H: Security/privacy/rules/App Check/rate-limit review
- Scope: threat review over auth boundaries, callable guards, data exposure.
- Inspect: firestore.rules, storage.rules, functions guards, analytics/privacy flows.
- Touch: rules/docs/tests as needed.
- Out-of-scope: full re-architecture.
- Acceptance: no critical open boundary issues for launch.
- Validation: security checklist + emulator tests.
- Risks: hidden drift between rules and app expectations.
- Deliverable: security audit memo with closure list.

## 20. Open questions / unknowns

Open questions:
1) Exact live pricing deltas across Firebase/Cloud Run/Cloudflare/Supabase/InsForge at current date.
2) Real p95 latency and cost profile for classify at production-like traffic.
3) Current completeness of privacy export/delete workflows.
4) Current gap between docs and actual release pipeline behavior.

Unknowns handling:
- Kept explicit; not hidden.
- Should be resolved by targeted measurement and pricing validation before final budget commitments.

Official documentation and pricing links:
- Firebase pricing: https://firebase.google.com/pricing
- Firebase Functions env/config: https://firebase.google.com/docs/functions/config-env
- Firebase Functions 2nd gen upgrade: https://firebase.google.com/docs/functions/2nd-gen-upgrade
- Cloud Run pricing: https://cloud.google.com/run/pricing
- Cloudflare plans: https://www.cloudflare.com/plans/
- Cloudflare Workers pricing: https://developers.cloudflare.com/workers/platform/pricing/
- Cloudflare R2 docs/pricing: https://developers.cloudflare.com/r2/
- Cloudflare Turnstile docs: https://developers.cloudflare.com/turnstile/
- Supabase pricing: https://supabase.com/pricing
- InsForge docs: https://docs.insforge.dev/
- InsForge pricing: https://insforge.dev/pricing

Inspected files (phase-0 and extended):
- motto_v2.md
- firebase_task.md
- /Users/pranay/AGENTS.md
- /Users/pranay/Projects/AGENTS.md
- AGENTS.md
- pubspec.yaml
- pubspec.lock
- package.json
- analysis_options.yaml
- firebase.json
- firestore.rules
- storage.rules (missing)
- CLAUDE.md (missing at repo root)
- .github/workflows/ci.yml
- README.md
- docs/README.md
- docs/config/environment_variables.md
- lib/main.dart
- lib/services/ai_service.dart
- lib/services/enhanced_ai_api_service.dart
- lib/services/unified_api_client.dart
- lib/services/api_client_factory.dart
- lib/services/cost_guardrail_service.dart
- lib/services/dynamic_pricing_service.dart
- lib/services/model_selection_service.dart
- lib/services/cloud_storage_service.dart
- lib/services/storage_service.dart
- lib/services/enhanced_storage_service.dart
- lib/services/result_pipeline.dart
- lib/services/gamification_service.dart
- lib/services/firebase_family_service.dart
- lib/services/community_service.dart
- lib/services/analytics_service.dart
- lib/services/ad_service.dart
- lib/services/premium_service.dart
- lib/services/token_service.dart
- lib/services/dynamic_link_service.dart
- lib/services/remote_config_service.dart
- lib/services/model_download_service.dart
- lib/services/object_detection_service.dart
- lib/services/tflite_preprocessing_helper.dart
- functions/package.json
- functions/src/index.ts
- functions/src/classify_image.ts
- functions/src/ops_hardening.ts
- functions/src/rate_limit_config.ts
- functions/src/training_data.ts
- functions/batch_processor.js
- functions tests (http guards and emulator suites)

Status of execution boundaries for this report:
- No platform migration executed.
- No broad backend replacement executed.
- This deliverable is decision + roadmap + task decomposition.