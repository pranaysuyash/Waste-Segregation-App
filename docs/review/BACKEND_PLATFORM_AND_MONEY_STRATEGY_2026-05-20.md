# Backend Platform and Money Strategy Review (2026-05-20)

Repo: /Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app
Scope source: firebase_task.md
Status: complete (full firebase_task.md strategy/report scope covered)

## Active Task
Full strategy/report scope from firebase_task.md is complete. Next step is implementation execution only, if requested.

## Phase 0 - Mandatory Review Result

Reference checklist in firebase_task.md lines 78-143.

### Missing required files
1) docs/config/environment_variables.md
2) AGENTS.md (repo root)
3) CLAUDE.md (repo root)

Notes:
- AGENTS.md exists at /Users/pranay/Projects/AGENTS.md (outside this repo).
- CLAUDE.md exists at docs/reference/CLAUDE.md and docs/reference/developer_documentation/CLAUDE.md.
- storage.rules optional: not present.

Detailed file audit: docs/review/PHASE0_FILE_AUDIT_2026-05-20.md

## Phase 1 - Current Backend/Platform Capability Map

Legend:
- Importance scale: High / Medium / Low
- Migration difficulty: Low / Medium / High / Very High

| Capability | Current implementation | Files involved (evidence) | Service(s) | Business importance | Revenue importance | User-facing risk if broken | Migration difficulty | MVP must-have | Can defer |
|---|---|---|---|---|---|---|---|---|---|
| Authentication | Firebase Auth based login + profile flow | lib/screens/auth_screen.dart, lib/main.dart, pubspec.yaml (firebase_auth) | Firebase Auth | High | High | Users cannot retain account data/pay | High | Yes | No |
| User profile | UserProfile persisted locally + cloud sync paths | lib/services/storage_service.dart, lib/services/cloud_storage_service.dart, lib/models/user_profile.dart | Hive, Firestore | High | Medium | Account state inconsistency | Medium | Yes | No |
| Guest mode | Explicit guest_user fallback + guest-safe messaging | lib/services/storage_service.dart, lib/widgets/settings/account_section.dart | Local Hive | High | Medium | Trial-to-signup funnel degrades | Low | Yes | No |
| Classification history | Local history primary, cloud sync optional | lib/services/storage_service.dart, lib/screens/history_screen.dart, lib/services/cloud_storage_service.dart | Hive, Firestore | High | High | Core value disappears | Medium | Yes | No |
| Feedback/corrections | Stable dedup key, local+cloud feedback record, points integration | lib/services/result_pipeline.dart, lib/models/classification_feedback.dart, firestore.rules | Firestore, Hive | High | High | Model quality loop breaks | Medium | Yes | No |
| AI classification | Multiple AI service layers with provider abstraction and retries | lib/services/ai_service.dart, lib/services/enhanced_ai_api_service.dart, lib/services/unified_api_client.dart | OpenAI, Gemini, Functions | High | High | App gives wrong/failed results | High | Yes | No |
| Disposal instruction generation | Backend endpoint generation + cache/fallback patterns | functions/src/index.ts, lib/services/disposal_instructions_service.dart, prompts/disposal.txt | Cloud Functions, OpenAI | High | High | Trust drops quickly | High | Yes | No |
| API key hiding | Server-side callable + bearer guard for HTTP endpoints; mixed client-side provider paths still present | functions/src/index.ts, lib/services/api_client_factory.dart, lib/services/providers/openai_provider_client.dart | Functions, Secret env | Very High | Very High | Key leakage / abuse costs | High | Yes | No |
| Model gateway | UnifiedApiClient + provider clients + version routing | lib/services/unified_api_client.dart, lib/services/api_client_factory.dart | OpenAI, Gemini | High | High | Uncontrolled provider drift/cost | Medium | Yes | No |
| Cost guardrails | Dedicated guardrail + dynamic pricing + token spend callable | lib/services/cost_guardrail_service.dart, lib/services/dynamic_pricing_service.dart, functions/src/index.ts (spendUserTokens) | Firestore, Functions | Very High | Very High | Margin collapse | High | Yes | No |
| Daily quota/free limits | Token wallet and quota checks in app/backend paths | lib/services/token_service.dart, functions/src/index.ts | Firestore, Functions | High | Very High | Free users can drain paid infra | High | Yes | No |
| Token wallet | Server-side deduction callable + app token service | functions/src/index.ts, functions/test/http_guards.emulator.test.js, lib/services/token_service.dart | Functions, Firestore | High | Very High | Monetization logic breaks | High | Yes | No |
| Payments/premium | Premium service exists; real purchase rail appears partial/stub | lib/services/premium_service.dart, lib/screens/premium_features_screen.dart, docs/reports/audits/RANDOM_DOCUMENT_AUDIT_TOKEN_ECONOMY_2026-05-19.md | App-level premium logic | Very High | Very High | No direct revenue capture | High | Yes | No |
| Ads | Ad service + Google Mobile Ads package/tests | lib/services/ad_service.dart, pubspec.yaml (google_mobile_ads), test/services/ad_service_test.dart | Google Mobile Ads | Medium | High | Reduced fallback revenue | Low | No | Yes |
| Remote Config/flags | Remote config service and dependency present | lib/services/remote_config_service.dart, pubspec.yaml (firebase_remote_config) | Firebase Remote Config | High | High | Cannot throttle features/costs | Medium | Yes | No |
| Crash/error reporting | Crashlytics hooks in startup and test crash actions | lib/main.dart, lib/screens/settings_screen.dart, pubspec.yaml (firebase_crashlytics) | Firebase Crashlytics | High | Medium | Silent production failures | Low | Yes | No |
| Analytics | Custom analytics service writing analytics_events in Firestore with consent | lib/services/analytics_service.dart, firestore_schema_registry.dart | Firestore analytics_events | High | High | No funnel or retention signal | Medium | Yes | No |
| Push notifications | firebase_messaging dependency present; runtime handling not clearly wired in inspected core services | pubspec.yaml (firebase_messaging) | Firebase Messaging | Medium | Medium | Re-engagement loss | Medium | No | Yes |
| Image upload/storage | Cloud storage service handles cloud persistence/sync | lib/services/cloud_storage_service.dart, pubspec.yaml (firebase_storage) | Firebase Storage | High | Medium | Media-backed history breaks | Medium | Yes | No |
| Local data layer | Hive-based primary local storage, adapters, migration support | lib/services/storage_service.dart, lib/services/hive_manager.dart | Hive | High | Medium | App unusable offline / state loss | Medium | Yes | No |
| Offline mode | Local-first persistence + queue patterns | lib/services/storage_service.dart, lib/services/offline_queue_service.dart | Hive + queued sync | High | Medium | Poor reliability perception | Medium | Yes | No |
| On-device ML/model download | Model selection, download, preprocessing, object detection placeholder implementation | lib/services/model_selection_service.dart, lib/services/model_download_service.dart, lib/services/tflite_preprocessing_helper.dart, lib/services/object_detection_service.dart | On-device ML stack (partial) | Medium | Medium | Latency/cost fallback unavailable | High | No | Yes |
| Gamification | Full service with points engine and profile sync | lib/services/gamification_service.dart, lib/services/points_engine.dart | Hive + Firestore | Medium | Medium | Retention drop | Medium | No | Yes |
| Achievements | Achievement progression and claim flow in gamification profile | lib/services/gamification_service.dart, lib/models/gamification.dart | Hive + Firestore | Medium | Medium | Engagement drop | Medium | No | Yes |
| Leaderboards | Community/feed/stats aggregation patterns exist (family/community stats) | lib/services/community_service.dart, lib/services/firebase_family_service.dart | Firestore | Medium | Medium | Social proof weak | Medium | No | Yes |
| Family features | Family creation/invites/members/stats in dedicated service | lib/services/firebase_family_service.dart, lib/models/enhanced_family.dart | Firestore | Medium | Low-Med | Niche cohort impacted | High | No | Yes |
| Community feed | Feed records + stats maintained in Firestore | lib/services/community_service.dart, firestore.rules (community_feed) | Firestore | Medium | Medium | Viral loop weak | Medium | No | Yes |
| Sharing/deep links | app_links based deep links replacing deprecated firebase_dynamic_links | lib/services/dynamic_link_service.dart, pubspec.yaml | App Links | Medium | Medium | Organic sharing weak | Low | No | Yes |
| Data export/delete/privacy | clearAllData callable exists with enable flag + recursive delete; account-delete UX docs exist | functions/src/index.ts (clearAllData), docs/planning/feature_deep_dive_analysis.md | Functions + Firestore/Storage | High | High | Compliance/trust risk | High | Yes | No |
| Admin/diagnostics endpoints | healthCheck, testOpenAI, guarded clearAllData | functions/src/index.ts, functions/test/http_guards.test.js | Functions | Medium | High (ops reliability) | Slow incident response | Low | Yes | No |
| Batch/scheduled jobs | processBatchJobs scheduler + batch stats endpoints | functions/src/index.ts, functions/batch_processor.js | Functions scheduler + OpenAI batches | Medium | High (COGS optimization) | Backlog/cost inefficiency | Medium | No | Yes |
| CI/CD | GitHub Actions CI file present; includes test/lint workflow | .github/workflows/ci.yml, README.md | GitHub Actions + Firebase deploy scripts | High | High | Broken releases | Medium | Yes | No |
| Play Store readiness | Release notes and scripts exist; monetization/security completeness still open | docs/archive/play_store_release_notes_0.1.5_97.txt, scripts/README.md | Android release pipeline | High | Very High | Cannot convert growth to money | Medium | Yes | No |
| Landing page/marketing site | Not yet clear as separate production system in repo; considered in strategy docs | firebase_task.md, docs/planning business docs | (candidate: Cloudflare/Firebase hosting) | High | Very High | Acquisition blocked | Medium | Yes | No |
| SEO/public content | Mentioned in planning, no strong evidence of production SEO pipeline in current app repo | firebase_task.md, docs/planning docs | TBD (likely Cloudflare + static CMS) | Medium | High | Weak top-of-funnel | Medium | No | Yes |
| Open-source contributor setup | README and docs exist; contributor-specific env doc missing | README.md, docs/README.md, missing docs/config/environment_variables.md | GitHub + docs | Medium | Medium | Slower external contributions | Low | No | Yes |

## Phase 1 Key Architectural Reality (Short)
1) This codebase is Firebase-first operationally, not just historically.
2) Revenue-critical controls (tokens, quotas, cost guardrails, premium logic) exist, but payment rail completeness looks weaker than quota rail completeness.
3) There is real backend guard logic (auth guards, diagnostics guards), but API-key surface is still mixed due to client-side provider paths.
4) On-device ML path exists structurally but contains placeholder behavior in object detection, so cloud/endpoint quality remains primary for launch trust.

## Phase 2 - Risk Inventory (P0-P3 with root cause)

Severity definition:
- P0: blocks launch or immediate money risk
- P1: serious production/safety risk
- P2: medium-term architecture/operational risk
- P3: cleanup/quality debt

| Severity | Risk | Root cause | Evidence | Impact |
|---|---|---|---|---|
| P0 | Revenue rail incomplete vs usage rail | Token/quota system exists, but purchase conversion path appears partially stubbed | lib/services/token_service.dart, functions/src/index.ts (spendUserTokens), lib/services/premium_service.dart, docs/reports/audits/RANDOM_DOCUMENT_AUDIT_TOKEN_ECONOMY_2026-05-19.md | Users hit limits but cannot reliably pay to continue |
| P0 | Mixed API-key exposure surface | Some app-side provider/client patterns still construct Authorization headers client-side | lib/services/api_client_factory.dart, lib/services/providers/openai_provider_client.dart, README env examples | Key leakage/abuse and uncontrolled spend |
| P0 | AI fallback may mask backend failure states | Broad fallback behavior can return cached/default instruction flow and hide true upstream outage | functions/src/index.ts (cached response + fallback patterns), disposal flow service | Silent quality degradation while metrics look "healthy" |
| P0 | Missing explicit environment variable runbook | Required env doc absent | missing docs/config/environment_variables.md | Fragile deploys, misconfigured secrets, incident-prone ops |
| P1 | Cloud Function generation/style drift risk | Legacy and newer function patterns coexist; historical files indicate evolution not full convergence | functions/src/index.ts, functions/batch_processor.js | Upgrade friction and inconsistent runtime behavior |
| P1 | Secret strategy may be inconsistent across paths | Guarded endpoints exist, but client/provider and server env references coexist | functions/src/index.ts, lib/services/providers/openai_provider_client.dart | Security gaps or accidental plaintext key usage |
| P1 | Firestore rule/model drift pressure | Large ruleset with many model validations; app model evolution is active | firestore.rules, lib/models/*, lib/services/* | Runtime permission failures or over-permissive access |
| P1 | Firestore read-cost pressure in social/family stats | Some stats involve broad reads/recalculation paths | lib/services/community_service.dart, lib/services/firebase_family_service.dart | Cost growth with engagement |
| P1 | Storage/image cost growth without strict lifecycle policy | Image-heavy use case and cloud sync; retention/deletion policy not clearly centralized in inspected docs | lib/services/cloud_storage_service.dart, firebase.json | Margin pressure at scale |
| P1 | Function cold start/timeout in AI paths | AI calls and batch orchestration on callable/HTTP endpoints | functions/src/index.ts | Latency spikes and failed requests during load |
| P1 | Scheduled/batch operational fragility | Batch scheduler exists but dual implementations/history suggest operational complexity | functions/src/index.ts, functions/batch_processor.js | Incomplete batch processing, delayed outputs |
| P1 | Environment split (dev/staging/prod) not strongly codified | Missing central env doc + multiple context docs | docs/.AGENT_INSTRUCTIONS.md, missing docs/config/environment_variables.md | Cross-environment mistakes and higher release risk |
| P1 | Limited App Check hardening evidence in inspected core runtime | No strong App Check wiring found in inspected app/services | lib search (no clear FirebaseAppCheck wiring) | Higher abuse/bot surface |
| P1 | Push re-engagement uncertainty | Dependency present, but clear runtime messaging flow not found in inspected core files | pubspec.yaml (firebase_messaging), lib search results | Weak retention/reactivation loop |
| P2 | Dependency drift / historical package churn | Repo references prior replacements and compatibility pinning | pubspec.yaml comments, docs/reports/*, README historical notes | Ongoing maintenance tax |
| P2 | Tests/analyzer boundaries may miss integration regressions | Existing tests cover key guards, but breadth of service graph is large | functions/test/http_guards*.js, .github/workflows/ci.yml | Regressions escape until production |
| P2 | Deterministic deployment process not fully documented in one place | CI exists, but env/deploy controls are fragmented | .github/workflows/ci.yml, missing env doc | Slower incident rollback and onboarding |
| P2 | On-device ML readiness gap | Object detection path contains placeholder implementation | lib/services/object_detection_service.dart | Product promises may exceed shipped behavior |
| P2 | Multi-provider complexity in AI stack | Several abstraction layers plus fallback, token logic, and batch logic | ai_service.dart, enhanced_ai_api_service.dart, unified_api_client.dart, token_service.dart | Harder debugging and correctness guarantees |
| P3 | Logging signal-to-noise imbalance in some services | High-volume logs and repeated "operation completed" patterns | lib/services/gamification_service.dart | Harder ops diagnosis |
| P3 | Legacy doc clutter and decision drift | Multiple status/audit docs with overlapping claims | docs/reports/status/*, docs/reports/audits/* | Decision latency and confusion |

## Phase 2 immediate priorities (ordered)
1) Close revenue rail gap: implement/verify payment-to-token/premium flow end-to-end.
2) Remove client-side secret surfaces; force all paid AI through server-controlled gateway.
3) Add single source env/secrets doc and production checklist (missing file).
4) Harden anti-abuse (App Check/rate limiting) before scaling acquisition.
5) Make fallback behavior explicit in metrics (separate hard-fail, soft-fail, cached-fallback counters).

## Phase 3 - External Platform Research and Comparison (official docs/pricing)

Research date: 2026-05-20
Method: live fetch from official pricing/docs pages via terminal HTTP requests.

### Sources
- Firebase pricing: https://firebase.google.com/pricing
- Cloud Run pricing: https://cloud.google.com/run/pricing
- Cloudflare plans/pricing: https://www.cloudflare.com/plans/
- Supabase pricing: https://supabase.com/pricing
- InsForge pricing: https://insforge.dev/pricing
- InsForge product/site context: https://insforge.dev

### Verified facts captured from official pages

Firebase
- Two primary plans are explicit: Spark (no-cost tier) and Blaze (pay-as-you-go).
- Page explicitly highlights Spark free usage and Blaze expansion with pay-as-you-go behavior.
- Firebase page currently highlights eligibility messaging around cloud credits for some users.

Cloud Run
- Pure usage-based billing model with free tier allowances visible on pricing page.
- Free-tier language on page includes monthly request and compute allowances (vCPU-seconds / GiB-seconds), plus networking notes.
- Clear statement that final bill is post free-tier application.

Cloudflare
- Plan ladder clearly shown: Free, Pro, Business, and enterprise/contract style options.
- Website plans and Zero Trust style plans are separately represented.
- Workers/platform usage pricing appears usage-metered with included quotas.

Supabase
- Plan ladder shown: Free, Pro, Team, Enterprise.
- Free and paid tiers are explicit with included quotas and add-on style overages.

InsForge
- Public pricing page exists and is not purely "contact sales only".
- Plan ladder visible: Free, Pro, Enterprise (with usage quotas and overage references).
- Product positioning explicitly AI-native with integrated auth/database/storage/functions/model-gateway language.

### First-principles comparison for THIS app

| Option | What it is best at | Where it is weak for this app right now | Revenue-speed fit | Architecture fit | Migration cost from current state |
|---|---|---|---|---|---|
| Firebase (current core) | Fastest continuity for existing auth/firestore/storage/functions/remote config/crash flows | Can become expensive with poor read/write patterns; needs strict guardrails | Very high short-term | High (already integrated) | Lowest |
| Cloud Run (add-on) | Heavy AI/image/batch workloads, explicit server control, cleaner key isolation | Adds platform split and ops complexity if used for everything too early | High when scoped to heavy workloads only | High for backend compute lane | Medium |
| Cloudflare (add-on) | Landing pages, public content, CDN/edge caching, acquisition surface | Not a drop-in replacement for existing Firebase app backend domain model | High for top-of-funnel speed | High as edge/acquisition layer | Low-Medium (if scoped) |
| Supabase (full/partial replacement) | Postgres-centric product/data modeling and SQL analytics | Significant migration from live Firebase model and rules; slower path to immediate cash | Medium-Low short-term | Medium-High long-term | High |
| InsForge (full/partial replacement) | AI-native integrated backend experience and Postgres orientation | Newer ecosystem risk + migration cost from current Firebase-heavy app | Medium short-term, potentially high mid-term | Medium-High (if stable and proven) | High |

## Phase 4 - Recommendation (time-to-revenue first, sane architecture second)

### Decision
Adopt a staged hybrid strategy, not a full replatform now.

1) Keep Firebase as system-of-record for launch-critical features in next revenue window.
2) Add Cloud Run only for compute-heavy AI endpoints where function limits/cold-start/cost require it.
3) Use Cloudflare for landing pages/public content/CDN and acquisition experiments.
4) Defer Supabase/InsForge migration until revenue signal is established and tracked.

Why this is not patchwork:
- It follows bounded responsibility by layer, not random tool mixing.
- It preserves working launch paths while isolating the highest-risk/cost workloads.
- It creates optionality for future Postgres migration without burning current momentum.

### Target architecture (near-term)
- App client: Flutter + local Hive + current product UX.
- Core backend system-of-record: Firebase Auth + Firestore + Storage.
- AI secure gateway: server-side endpoints only (Firebase Functions initially, Cloud Run for heavy lanes).
- Revenue controls: token wallet + quota + premium purchase flow + remote-config kill switches.
- Acquisition surface: Cloudflare-hosted landing/content + analytics plumbing into product funnel.

## Phase 5 - Monetization path and deployment strategy

### Monetization path (ordered)
1) Ship working purchase rail (token packs or premium subscription) that actually unlocks usage.
2) Keep free tier tight but useful (daily quota) to drive conversion intent.
3) Use ads as secondary monetization only for non-paying segment.
4) Add simple, transparent usage ledger in-app (tokens used, remaining, top-up CTA).
5) Add remote-config control for pricing, quotas, model routing, fallback strictness.

### Deployment strategy
Phase A (immediate)
- Keep Firebase deploy path intact.
- Harden secrets and eliminate direct client provider key paths.
- Add env runbook and release checklist.

Phase B (2nd)
- Move only high-cost AI endpoints to Cloud Run if observed latency/cost justifies.
- Preserve same app API contract to avoid client churn.

Phase C (3rd)
- Launch Cloudflare landing pages + SEO content loop.
- Link campaign tracking to in-app activation and paid conversion.

## Phase 6 - Future data model direction

Near-term (no migration)
- Keep Firestore for product velocity and current features.
- Tighten schema/rules discipline and indexed query patterns.

Mid-term (migration-ready)
- Introduce event mirror/export (classification, token spend, conversion events) to a relational analytics store.
- Define canonical domain entities independent of Firebase document shapes.

Long-term (only if warranted)
- Consider Postgres-first core (Supabase/InsForge/self-managed) only when:
  - monthly revenue and retention justify migration effort,
  - query complexity surpasses Firestore ergonomics,
  - team can absorb migration risk without growth stall.

## Weighted decision matrix

Weights (100 total):
- Revenue speed (30)
- Migration effort/risk (20)
- Security/control for AI costs (20)
- Product velocity (15)
- Long-term flexibility (15)

Scoring scale: 1-5 (5 best).

| Option | Revenue speed 30 | Migration risk 20 | AI security/control 20 | Velocity 15 | Long-term flexibility 15 | Weighted total |
|---|---:|---:|---:|---:|---:|---:|
| Firebase-only harden | 5 | 5 | 3 | 5 | 3 | 4.35 |
| Firebase + Cloud Run (targeted) + Cloudflare landing | 5 | 4 | 5 | 4 | 4 | 4.55 |
| Full Supabase migration now | 2 | 1 | 4 | 2 | 5 | 2.70 |
| Full InsForge migration now | 2 | 1 | 4 | 3 | 4 | 2.75 |
| Cloudflare-heavy backend replacement now | 2 | 2 | 3 | 2 | 4 | 2.55 |

Default recommendation from matrix:
- Firebase core + targeted Cloud Run for heavy AI + Cloudflare for acquisition surfaces.

## Phase 7 - Multi-agent execution breakdown

### Agent A: Revenue rail closure
Scope
- Validate and implement end-to-end purchase -> token/premium unlock flow.
Acceptance
- Successful purchase updates entitlement and token balance deterministically.
Validation
- Test cases for purchase success/failure/cancel/refund edge paths.
Risks
- Store policy and restore-purchase behavior.
Guardrails
- No token grants from client-only trust path.

### Agent B: Secret and gateway hardening
Scope
- Remove/disable client-side direct provider key usage; route through server gateway.
Acceptance
- No production path constructs raw provider Authorization key in client.
Validation
- Static grep + integration test against gateway.
Risks
- Breaking fallback paths.
Guardrails
- Keep rollback switch via remote config.

### Agent C: Cost and abuse controls
Scope
- Enforce quota/rate/App Check controls and fallback telemetry separation.
Acceptance
- Distinct metrics for hard-fail vs soft-fail vs cached-fallback.
Validation
- Emulator/integration tests for quota boundary conditions.
Risks
- False positives blocking real users.
Guardrails
- Emergency bypass flag and gradual rollout.

### Agent D: Environment and release discipline
Scope
- Create docs/config/environment_variables.md and deployment runbook.
Acceptance
- One canonical env matrix (dev/stage/prod), required secrets, rotation notes.
Validation
- Dry-run checklist completion before release.
Risks
- Drift between docs and CI.
Guardrails
- CI checks for missing required env vars.

### Agent E: Acquisition surface
Scope
- Launch landing/content site lane (Cloudflare or equivalent) tied to app conversion analytics.
Acceptance
- Published pages + campaign attribution into app funnel reporting.
Validation
- UTM -> activation -> conversion trace exists.
Risks
- Vanity traffic without conversion.
Guardrails
- Weekly channel ROI review.

## Phase 8 - Acceptance criteria check

Checklist from firebase_task.md status:
- Phase 0 file inspection and missing-file note: Done.
- Backend/platform capability map with MVP/revenue relevance: Done.
- P0-P3 risk inventory with root cause: Done.
- External official docs/pricing research and option comparison: Done.
- Recommendation + monetization + deployment + future data model + weighted matrix: Done.
- Multi-agent breakdown with scope/acceptance/validation/risks/guardrails: Done.

Open items requiring implementation work (not analysis work)
- Build/verify real payment rail end-to-end.
- Remove residual client-side provider key pathways.
- Add missing docs/config/environment_variables.md.
- Validate App Check/rate limiting coverage in production paths.


---

## Completion Addendum - Full firebase_task.md Coverage (t9-t12 and compliance gaps closed)

Status update:
- Previous draft covered t2-t8 well but did not fully satisfy all explicit deliverable structure in firebase_task.md.
- This addendum closes remaining scope and marks unknowns explicitly.

## 1) Executive summary

Money-first answer:
- Do not migrate core backend off Firebase before first revenue signal.
- Harden Firebase now (security, quota/token enforcement, secrets, App Check, env hygiene).
- Add Cloudflare now only for landing/content/CDN/protection (acquisition + public traffic economics).
- Keep Cloud Run as targeted lane for heavy AI/image/batch once telemetry proves Functions pain.
- Run an InsForge spike in parallel (2 days), no production cutover.

Why:
- Fastest path to launch and first paid conversions is to improve existing working system, not replatform.
- Biggest near-term money risk is incomplete purchase rail + client-side key exposure + weak abuse controls.

## 2) Repo/backend context

Current stack is Firebase-native with Flutter local-first client:
- Firebase Auth, Firestore, Storage, Functions, Remote Config, Crashlytics, Messaging, Analytics patterns.
- Hive local persistence + offline queue patterns.
- AI stack uses multi-provider abstraction with both server and client/provider pathways.
- Token/quota logic exists server-side, but purchase-to-entitlement path is not yet production-complete.

No migration performed in this task.
No mutating git commands run in this task.

## 3) Current backend capability map

Already completed in Phase 1 above.

## 4) Current risk inventory

Already completed in Phase 2 above.
Additional validated findings from code scan:
- `functions.config()` is still used in multiple paths:
  - functions/batch_processor.js:92,160
  - functions/src/index.ts:19,317,328,443,644,713
- Client-side Authorization header construction still exists in AI paths:
  - lib/services/api_client_factory.dart:23
  - lib/services/ai_service.dart:1256,1660
  - lib/services/ai_job_service.dart:219,252
  - lib/services/providers/openai_provider_client.dart:80
- App Check wiring evidence in app code was not found in current scan.

## 5) Firebase assessment

Strengths for immediate launch:
- Deep integration already present in codebase and release flow.
- Existing auth + document model already serves product core and social/community features.
- Fastest route to paid experiments because churn is in hardening, not re-architecture.

Weaknesses/risk:
- Cost unpredictability if read amplification and storage retention are unmanaged.
- Rule/model drift risk as entities evolve.
- Mixed secrets model and legacy config usage increase operational risk.

Verdict:
- Keep as launch core, harden aggressively.

## 6) Firebase Functions 2nd gen / Cloud Run assessment

Validated platform guidance:
- Firebase docs explicitly state 2nd gen drops support for `functions.config` and recommends parameterized configuration.
  Source: https://firebase.google.com/docs/functions/2nd-gen-upgrade
  Source: https://firebase.google.com/docs/functions/config-env

Assessment:
- 2nd gen migration should be planned now because current code still uses `functions.config`.
- For heavy AI/image/batch workloads, Cloud Run can be a cleaner compute lane with explicit scaling/resource controls.
- Keep API contract stable for Flutter while swapping backend implementation under same route surface.

## 7) Cloudflare assessment (deep)

Direct answers required by task:
- Should Cloudflare host the landing page? Yes.
- Should Cloudflare host public waste guide pages? Yes.
- Should Workers be used for public APIs? Yes, for non-sensitive/public cacheable APIs only.
- Should R2 be used for public images/static assets? Yes, for public static/non-sensitive media and CDN economics.
- Should Cloudflare be used as CDN/cache in front of Firebase/Cloud Run? Yes, selectively for public/cache-safe paths.
- Should Turnstile/rate limits/WAF be used? Yes, especially on public endpoints and forms.
- Should Cloudflare be avoided for core mobile app auth/data now? Yes, avoid replacing Firebase core now.
- Would Cloudflare help acquisition/SEO/content marketing? Yes, materially.
- Could Cloudflare reduce bandwidth/storage costs? Yes for public static and cache-hit heavy traffic.
- Minimal setup now: Cloudflare Pages + Cache + WAF/Turnstile + optional R2 for public assets.

Recommended Cloudflare use cases now:
- Landing pages (Pages)
- Public SEO content and guides
- CDN/caching for public assets
- WAF + basic bot protection + Turnstile on lead forms

Recommended later:
- Public edge APIs for cached/non-sensitive datasets
- Edge personalization for content
- More advanced rate limiting

Should not own yet:
- Core mobile auth state
- Primary transactional user/profile/token ledger backend
- Critical paid AI deduction path

Sources:
- https://www.cloudflare.com/plans/
- https://developers.cloudflare.com/workers/platform/pricing/
- https://developers.cloudflare.com/turnstile/
- https://developers.cloudflare.com/r2/
- https://developers.cloudflare.com/cache/

## 8) InsForge assessment (deep)

### 8.1 Direct replacement questions

What replaces Firebase Auth?
- InsForge Authentication (JWT + OAuth/session model) appears available.
  Source: https://docs.insforge.dev/core-concepts/authentication/architecture

What replaces Firestore?
- InsForge PostgreSQL + PostgREST-style API layer.
  Source: https://docs.insforge.dev/core-concepts/database/architecture

What replaces Firebase Storage?
- InsForge storage + S3-compatible gateway model.
  Source: https://docs.insforge.dev/core-concepts/storage/architecture

What replaces Cloud Functions?
- InsForge edge/serverless functions model.
  Source: https://docs.insforge.dev/core-concepts/functions/architecture

What replaces Remote Config?
- No explicit 1:1 Remote Config equivalent verified in inspected pages. Unknown.

What replaces FCM/push notifications?
- No explicit FCM-equivalent push layer verified. Unknown.

What replaces Crashlytics?
- No explicit 1:1 crash reporting equivalent verified. Unknown.

What replaces Analytics?
- Product analytics equivalent not clearly verified as 1:1 replacement. Unknown.

Flutter/mobile SDK story?
- Public docs show SDK/examples and REST references; full Flutter-native maturity level is not yet verified in this review. Unknown-risk until spike.

Auth/session from Flutter?
- Likely JWT/OAuth flows over REST/SDK; exact production-grade Flutter ergonomics need spike validation.

Image upload + secure access?
- Storage architecture + S3-compatible gateway suggests feasible signed/private/public access patterns.

AI gateway metering?
- AI architecture includes model gateway concepts and OpenRouter integration references; billing-grade meter guarantees need spike verification.
  Source: https://docs.insforge.dev/core-concepts/ai/architecture

Quotas/token/payments?
- Feasible with Postgres ledger + policy + server functions; still custom app logic required.
- Payments shown as private preview context in docs nav signals maturity caution.

How Postgres helps family/community/leaderboards and city rules?
- Strong relational joins, constraints, aggregation, materialized views can simplify complex ranking/reporting.

Open-source/self-host benefit?
- Better portability and reduced hard vendor lock if maturity sufficient.

Multi-agent backend safety?
- SQL schema migrations, explicit contracts, and strong transaction semantics can reduce hidden document-shape drift.

Maturity/vendor unknowns requiring spike:
- Push/crash/analytics parity for mobile
- Flutter-specific integration depth and stability
- Operational tooling maturity and incident ergonomics
- Production migration path and rollback for existing Firebase data

### 8.2 InsForge replacement map

| Current Firebase thing | InsForge equivalent | Gap/unknown | Migration complexity | Launch impact |
|---|---|---|---|---|
| Firebase Auth | InsForge Auth (JWT/OAuth) | Session ergonomics in Flutter needs validation | High | High |
| Firestore | Postgres + API layer | Document-model migration + rules parity rewrite | Very High | Very High |
| Firebase Storage | InsForge Storage/S3 gateway | Existing bucket/path/access migration | High | High |
| Cloud Functions | InsForge Functions | Existing callable semantics parity | High | High |
| Remote Config | No clear 1:1 verified | Need custom config table/edge config | Medium | Medium |
| FCM | No clear 1:1 verified | Need separate push provider integration | High | High |
| Crashlytics | No clear 1:1 verified | Need Sentry/other crash stack integration | Medium | Medium |
| Firebase Analytics | No clear 1:1 verified | Need analytics stack integration | Medium | Medium |
| App Check | No clear 1:1 verified | Need alternative anti-abuse architecture | Medium | High |

InsForge sources:
- https://insforge.dev/
- https://insforge.dev/pricing
- https://docs.insforge.dev/core-concepts/authentication/architecture
- https://docs.insforge.dev/core-concepts/database/architecture
- https://docs.insforge.dev/core-concepts/storage/architecture
- https://docs.insforge.dev/core-concepts/functions/architecture
- https://docs.insforge.dev/core-concepts/ai/architecture

## 9) Supabase / VPS sanity check

Supabase:
- Strong Postgres ecosystem and mature docs/community.
- Still a high migration project from current Firebase-first app.
- Good long-term candidate after revenue validation.
  Source: https://supabase.com/pricing

VPS/custom backend:
- Maximum control but highest operational burden for small team under money pressure.
- Bad choice for immediate launch speed unless team already has hardened platform templates.

## 10) Cost model rough scenarios (unknowns explicit)

Important:
- Exact costs depend on usage profile (requests, storage, egress, AI tokens, image size, cache ratio, region).
- Numbers below are directional bands for decision-making, not invoice promises.

Assumptions:
- AI cost is dominant variable and treated separately from platform baseline.
- Baseline excludes ad network rev-share effects.

### 10.1 Platform baseline (excluding AI token spend)

| Option | 0 users | 100 users | 1,000 users | 10,000 users | Surprise bill risk |
|---|---:|---:|---:|---:|---|
| Firebase hardening | Very low | Low | Medium | Medium-High | Medium (read/storage patterns matter) |
| Firebase + Functions 2nd gen | Very low | Low | Medium | Medium-High | Medium |
| Firebase + Cloud Run | Low | Low-Med | Medium | Medium-High | Medium |
| Firebase + Cloudflare | Low | Low | Medium | Medium | Low-Med |
| InsForge migration | Low | Low-Med | Medium | Medium-High | Unknown-Med |
| InsForge spike only | Very low | Very low | Very low | Very low | Low |
| Supabase migration | Low | Low-Med | Medium | Medium-High | Medium |
| Cloudflare-only | Low | Low | Medium | Medium | Medium-High (backend replacement complexity) |
| VPS/custom | Fixed low-med | Fixed + ops | Medium | Medium-High | High (ops mistakes) |

### 10.2 AI-heavy cost risk across options
- Highest risk is not vendor choice alone, it is missing server-side enforcement and model routing discipline.
- Required controls regardless of platform:
  - server-side token deduction
  - per-user/per-day quota
  - model tiering by plan
  - fallback budget caps
  - prompt/response caching where safe
  - usage anomaly alerts

Pricing references:
- Firebase: https://firebase.google.com/pricing
- Cloud Run: https://cloud.google.com/run/pricing
- Cloudflare: https://www.cloudflare.com/plans/ and https://developers.cloudflare.com/workers/platform/pricing/
- Supabase: https://supabase.com/pricing
- InsForge: https://insforge.dev/pricing

## 11) Monetization backend requirements (money-first)

### 11.1 Free tier

| Item | Backend requirement | Platform dependency | Must-have pre-launch | Cheapest path now | Abuse/cost risk |
|---|---|---|---|---|---|
| Daily free classifications | Per-user daily counter + reset window | Firebase Auth + Firestore + Functions | Yes | Keep existing token/quota rails | Multi-account abuse |
| Ad-supported scans | Ad eligibility + frequency flags | Remote Config + ad service | Yes | Existing google_mobile_ads + RC | UX degradation if over-shown |
| Limited history | Server policy + client cap | Firestore/Hive | Yes | Existing storage service caps | Circumvention via account churn |
| Basic disposal instructions | Lower-cost model route | Functions + AI gateway | Yes | Existing endpoint with strict cap | Low quality fallback trust risk |
| Local/offline fallback | Deterministic local rule fallback | Hive + local rules | Yes | Existing local stack | Mismatch vs cloud quality |

### 11.2 Paid tier

| Item | Backend requirement | Platform dependency | Must-have pre-launch | Cheapest path now | Abuse/cost risk |
|---|---|---|---|---|---|
| More scans | Higher quota tier | Firestore + Functions | Yes | RC-controlled plans | Shared-account abuse |
| No ads | entitlement gate | Premium service + RC + ad service | Yes | existing premium flags + server verification | local-only entitlement spoofing if not server-validated |
| Advanced local guidance | richer data/rules | local data + backend sync | No | staged rollout | stale rules |
| History export | export endpoint + signed access | Functions + Storage | No | defer v1.1 | data leak if auth weak |
| Family/apartment mode | org/group model + permissions | Firestore rules | No (unless GTM depends) | existing family service | permission drift |
| Reports | aggregation jobs | Functions/Cloud Run | No | defer post-revenue | query cost spikes |
| Priority AI model | plan-based model routing | gateway + RC | Yes (simple version) | model map by entitlement | cost blowout without hard caps |

### 11.3 Token wallet requirements
- Starting tokens: grant on signup server-side only.
- Spend per scan: server transaction only (`spendUserTokens` style, idempotent).
- Earn from corrections/contributions: dedup key + anti-fraud thresholds.
- Prevent duplicate earning: deterministic operation_id + unique constraint pattern.
- Daily quota + token relation: consume free quota first, then tokens.

### 11.4 Ads controls
- Safe placements: non-critical transitions, post-result modules, not before first useful output.
- Backend flags: remote-config frequency caps, segment-specific overrides.
- Premium ad-free: server-validated entitlement must suppress all ad requests.

### 11.5 B2B future backend
- Organizations (apartment/school), seats, role-based access, shared challenges, compliance reporting.
- Best introduced after B2C monetization proof.

## 12) Deployment strategy

### 12.1 Hosting/API split recommendation
- Landing page + public content: Cloudflare Pages.
- Public static assets: Cloudflare (and optionally R2 for public media).
- Mobile core APIs/auth/data: Firebase (Functions + Firestore + Auth) now.
- Heavy AI/image/batch (when needed): Cloud Run behind stable API contract.

### 12.2 Platform comparison for deployment

| Platform | Best use now | Avoid now |
|---|---|---|
| Firebase Hosting | App-adjacent docs/internal console pages | Main marketing site if Cloudflare SEO/CDN strategy preferred |
| Cloudflare Pages | Landing + SEO/public guides | Core mobile transactional backend replacement |
| Vercel | Optional if team already standardized there | Introducing another platform without need |
| GitHub Pages | Simple static docs only | Dynamic/public API workloads |
| Cloud Run | Heavy compute APIs | Full backend move before evidence |
| Firebase Functions | Current core callable/http endpoints | Unbounded heavy jobs without profiling |
| InsForge deployment | Spike/prototype only | Full production migration now |

### 12.3 CI/CD + rollback + monitoring
- Keep GitHub Actions CI as quality gate.
- Add environment matrix documentation (currently missing required file).
- Add explicit rollback runbook for Functions and app release.
- Crash + analytics remain in Firebase stack until replacement proven.

## 13) Firestore vs Postgres future data model (entity-level)

Legend:
- FS = Firestore
- PG = Postgres

| Entity | FS representation | PG representation | Easier in FS | Easier in PG | Migration risk |
|---|---|---|---|---|---|
| users/profiles | docs keyed by uid | users/profile tables | rapid iteration | constraints/joins | High |
| classifications | subcollections/docs | classifications table + FK | denormalized writes | analytics, joins | High |
| classification images | storage path refs | object metadata table + signed URLs | direct firebase integration | strict metadata/querying | High |
| feedback/corrections | docs + dedup key | feedback table + unique index | simple write path | anti-dup guarantees | Med-High |
| token wallet | doc fields + tx array | wallet + ledger tables | fast to ship | accounting-grade integrity | High |
| quota usage | per-user counters | usage table + rollups | low setup | robust reporting | Med-High |
| premium subscription | entitlement flags | subscription table + billing refs | simple flags | billing lifecycle correctness | Med |
| ad impression state | doc counters | ad_events table | simple counters | cohort analysis | Med |
| city rules/disposal guides | docs by city/material | normalized taxonomy tables | flexible schema | high-quality query/reporting | Med |
| materials taxonomy | nested docs | taxonomy tables | fast edits | consistency and joins | Med |
| brands/products/barcodes | docs + indexes | product/barcode tables | quick bootstrap | robust lookup relations | Med |
| families/groups | nested membership docs | org/member tables | simple bootstrap | permission/reporting clarity | Med-High |
| community posts | feed docs | posts/comments tables | quick feed writes | moderation/reporting | Med |
| challenges/achievements | docs/counters | challenge/achievement tables | velocity | scoring integrity | Med |
| leaderboard entries | denormalized docs | materialized rankings | cheap simple display | strong ranking queries | Med |
| partner locations | geo fields/docs | partner_location table + geo index | quick add | geospatial analytics | Med |
| B2B org/schools | docs + custom rules | org/tenant schema | fast prototype | tenancy clarity and billing | High |

Conclusion:
- FS wins short-term velocity.
- PG wins long-term analytical/relational integrity.
- Migration should be staged, not pre-revenue.

## 14) Weighted decision matrix (exact required weights/options)

Required weights:
- 30% time to launch / revenue
- 20% operational simplicity
- 15% cost predictability
- 15% long-term architecture
- 10% agent-friendliness
- 10% migration risk / reversibility

Scoring: 1-5.

| Option | Launch/Revenue 30 | Ops Simplicity 20 | Cost Predictability 15 | Long-term Arch 15 | Agent-friendly 10 | Migration/Reversible 10 | Weighted Score (/5) |
|---|---:|---:|---:|---:|---:|---:|---:|
| Firebase hardening | 5 | 4 | 3 | 3 | 4 | 5 | 4.10 |
| Firebase + Functions 2nd gen | 5 | 4 | 3 | 4 | 4 | 4 | 4.15 |
| Firebase + Cloud Run | 4 | 3 | 3 | 4 | 4 | 4 | 3.65 |
| Firebase + Cloudflare | 5 | 4 | 4 | 4 | 4 | 4 | 4.30 |
| InsForge migration | 2 | 2 | 3 | 4 | 4 | 2 | 2.70 |
| InsForge spike only | 4 | 4 | 4 | 4 | 5 | 5 | 4.15 |
| Supabase migration | 2 | 3 | 3 | 4 | 4 | 2 | 2.85 |
| Cloudflare-only | 2 | 3 | 4 | 3 | 3 | 2 | 2.75 |
| VPS/custom | 1 | 1 | 2 | 5 | 2 | 2 | 1.95 |

Rationale summary and what changes scores:
- Firebase hardening scores drop if abuse controls remain weak.
- Firebase+Cloudflare scores drop if team lacks content/SEO execution capacity.
- InsForge migration score rises only after spike proves Flutter parity + push/crash/analytics strategy.
- Cloud Run score rises if measured Functions latency/cost pain is already severe.

## 15) Recommended path

Final recommendation:
- Primary path: Firebase core hardening + Cloudflare additive + optional targeted Cloud Run lane.
- Parallel path: InsForge spike only (no migration commitment).

## 16) What to do this week (explicit)

1) Lock all paid AI access behind server endpoints only.
2) Close purchase-to-entitlement-to-token flow end-to-end.
3) Add App Check + basic abuse controls.
4) Replace `functions.config` usage with parameterized/env approach for 2nd-gen readiness.
5) Create docs/config/environment_variables.md and production/staging matrix.
6) Stand up Cloudflare landing + one public SEO guide + analytics attribution.
7) Instrument fallback telemetry split: hard-fail vs soft-fail vs cached-response.

## 17) What NOT to do this week (explicit)

- Do not start full Firebase->InsForge migration.
- Do not rewrite entire data model to Postgres now.
- Do not split backend into many new services without measured bottleneck evidence.
- Do not spend time on infra novelty before purchase flow and abuse controls are production-safe.

## 18) 2-day InsForge spike plan (explicit)

Day 1:
- Build minimal vertical slice:
  - auth session in Flutter test harness
  - one protected API
  - one storage upload/download path
  - one AI gateway call with usage log row

Day 2:
- Validate operational concerns:
  - migration tooling sanity
  - local dev loop
  - rollback/recovery notes
  - rough cost and latency observations

Exit criteria:
- Go/no-go memo with evidence for Flutter ergonomics, feature parity gaps, and migration risk.

## 19) Agent task breakdown (A-H, exact fields)

Global instruction for every agent task (must be repeated):
- Follow motto_v2.md.
- Use no git commands except read-only inspection.
- Preserve parallel work.
- Do not use “pre-existing” as an excuse.
- Verify current state before changing anything.

### Agent A - Backend production hardening on Firebase/Functions
- Scope: secrets/config modernization, server-only AI enforcement, auth checks, fallback telemetry split.
- Files to inspect: functions/src/index.ts, functions/batch_processor.js, lib/services/ai_service.dart, lib/services/api_client_factory.dart, lib/services/providers/openai_provider_client.dart.
- Files likely to touch: same + tests under functions/test.
- Out-of-scope: UI redesign, feature expansion.
- Acceptance criteria: no client production path sends provider secret; tests pass for guarded endpoints.
- Validation commands: npm --prefix functions test ; targeted flutter test for AI service adapters.
- Risks: accidentally breaking legacy fallback calls.
- Deliverable: hardening patch + test evidence + migration notes.

### Agent B - InsForge spike design and prototype plan
- Scope: no migration, only vertical spike spec + implementation checklist.
- Files to inspect: docs/review file, current auth/storage/AI service contracts.
- Files likely to touch: docs/review/INSFORGE_SPIKE_PLAN.md (or addendum section).
- Out-of-scope: production cutover.
- Acceptance criteria: explicit parity matrix + go/no-go gates.
- Validation commands: none mandatory beyond doc completeness checks.
- Risks: over-promising parity without evidence.
- Deliverable: 2-day executable spike document.

### Agent C - Cloudflare landing/content/CDN plan
- Scope: landing architecture, caching, WAF/Turnstile, attribution path.
- Files to inspect: docs/planning business docs, current analytics service, deployment docs.
- Files likely to touch: docs/review/CLOUDFLARE_DEPLOY_PLAN.md.
- Out-of-scope: backend auth/data migration.
- Acceptance criteria: publish-ready MVP setup checklist.
- Validation commands: deployment dry-run checklist.
- Risks: SEO vanity without conversion instrumentation.
- Deliverable: stepwise deployment plan.

### Agent D - Monetization backend model (quota/token/ads/premium)
- Scope: enforceable server-side rules and state transitions.
- Files to inspect: lib/services/token_service.dart, premium_service.dart, ad_service.dart, functions/src/index.ts.
- Files likely to touch: token/premium function endpoints + tests + docs.
- Out-of-scope: payment UI polish.
- Acceptance criteria: deterministic entitlement and spend ledger behavior.
- Validation commands: emulator tests for quota/token boundary cases.
- Risks: race conditions, double-spend, entitlement desync.
- Deliverable: state machine + tests + rollout plan.

### Agent E - AI cost-control and model gateway design
- Scope: model tiering, quota coupling, fallback budget policy, anomaly alerts.
- Files to inspect: ai_service.dart, unified_api_client.dart, cost_guardrail_service.dart, dynamic_pricing_service.dart, functions/src/index.ts.
- Files likely to touch: routing logic, metrics logging, remote config keys.
- Out-of-scope: unrelated gamification/community.
- Acceptance criteria: per-plan routing with hard budget caps and observability.
- Validation commands: targeted tests + synthetic load script.
- Risks: quality degradation due to too-aggressive cost cuts.
- Deliverable: cost-control policy + implementation notes.

### Agent F - Data model and Firestore/Postgres future comparison
- Scope: canonical entity model and migration phasing.
- Files to inspect: firestore.rules, models/, relevant services.
- Files likely to touch: docs/review/DATA_MODEL_FUTURE_PLAN.md.
- Out-of-scope: live migration execution.
- Acceptance criteria: entity-by-entity mapping + phased migration gates.
- Validation commands: schema consistency checks and query pattern inventory.
- Risks: underestimating migration cutover complexity.
- Deliverable: migration strategy document.

### Agent G - CI/deployment/release pipeline hardening
- Scope: deterministic release checklist, env matrix, rollback.
- Files to inspect: .github/workflows/ci.yml, firebase.json, scripts/README.md, docs/testing/*.
- Files likely to touch: docs/config/environment_variables.md, deployment docs, CI workflow.
- Out-of-scope: feature-level app logic.
- Acceptance criteria: documented and repeatable staging/prod pipeline.
- Validation commands: CI dry-run and checklist execution.
- Risks: secret leakage via misconfigured CI.
- Deliverable: hardened CI/CD playbook.

### Agent H - Security/privacy/rules/App Check/rate-limit review
- Scope: app-check enforcement strategy, rules audit, abuse controls.
- Files to inspect: firestore.rules, functions/src/index.ts, auth-dependent services.
- Files likely to touch: security docs + rules/tests + middleware.
- Out-of-scope: unrelated UX components.
- Acceptance criteria: documented threat list and mitigations implemented or scheduled with P-levels.
- Validation commands: rules tests + endpoint auth tests + abuse simulation checks.
- Risks: false positives harming legitimate users.
- Deliverable: security hardening report + prioritized patch list.

## 20) Open questions / unknowns

1) Exact production payment rail currently used (Play Billing/RevenueCat/custom) is not verified from inspected files.
2) InsForge 1:1 parity for push notifications and crash analytics is unverified.
3) Cloudflare Pages pricing details are partially represented via Workers/Plans docs; detailed pages-specific limits should be validated before traffic scale.
4) True 10k-user cost curves require real telemetry (request counts, image sizes, cache hit rate, AI token mix).

## Validation and compliance checklist (final)

- Mention every inspected file:
  - Phase 0 full list recorded in: docs/review/PHASE0_FILE_AUDIT_2026-05-20.md
  - Additional scans cited in this addendum with file paths and line references.
- Official docs/pricing citations included for Firebase, Cloudflare, Cloud Run, InsForge, Supabase.
- Unknowns explicitly listed.
- No migration performed.
- No mutating git commands performed.

Final status:
- firebase_task.md goal coverage is now complete at strategy/report level.
- Remaining work is implementation execution (by explicit next-task approval).
