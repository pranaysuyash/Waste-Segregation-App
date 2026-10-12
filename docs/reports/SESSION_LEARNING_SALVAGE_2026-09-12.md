# Session Learning Salvage - 2026-09-12

## Scope and Method

This report applies the `session-learning-salvage` workflow to the local
OpenCode history for:

`/Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app`

The source database was inspected read-only at
`~/.local/share/opencode/opencode.db`. Session, message, and part records were
used to separate completed responses from prompts and intermediate tool work.
Agent reports were treated as evidence only and were checked against the
current repository before being recorded here.

No OpenCode sessions, messages, parts, project source, profiles, caches, or
user data were deleted or rewritten during this pass.

## Full Inventory

| Measure | Observed value |
|---|---:|
| Total sessions | 274 |
| Root build sessions | 62 |
| Child explore sessions | 169 |
| Child general sessions | 43 |
| Session/message/part payload | approximately 320.8 MB |
| First recorded activity | 2026-05-15 |
| Last recorded activity | 2026-06-28 |
| Assistant messages ending in `finish=stop` | 262 |
| Sessions without a clean assistant stop | 12 |
| Sessions with a trailing `step-finish` part | 155 |
| Sessions with a trailing running/pending/error tool state | 2 |

These are triage signals, not deletion recommendations. Payload size measures
logical record content and does not predict the physical space recovered from
SQLite deletion.

## Open or Uncertain Queue

The following sessions were not promoted to learnings because completion could
not be established from the current database state. They should be preserved
until their work is explicitly resolved, re-run, or classified as obsolete by
the operator.

| Session | Agent | Last observed state | Reason to preserve |
|---|---|---|---|
| `ses_1ac1f68c5ffe1xqM4IGY9md29a` | explore | unknown / `step-finish` | Verification request has no clean assistant completion marker. |
| `ses_1ac207dd3ffeNteVuFYIHzm6uk` | explore | unknown / `step-finish` | TODO/FIXME inventory has no clean assistant completion marker. |
| `ses_1beef011fffeuU9e5I47ezrYW4` | build | no assistant stop | Audit session ends at a user prompt. |
| `ses_1b102c65dffe60s6UGShMURLnE` | general | trailing `step-start` | City-rules research appears to have started without a completed response. |
| `ses_1b44d52d9ffeZ71kcE5XoOBmmy` | explore | no assistant stop | Data-model exploration contains the request but no completed findings. |
| `ses_1b44dd6e2ffeftb64eCToIT22x` | explore | trailing tool `running` | Active/incomplete tool state must be preserved. |
| `ses_1b44faa94ffevibW7JwSE3KDLH` | explore | trailing tool `pending` | Pending tool state must be preserved. |
| `ses_1b44e7135ffefj63gvCnJZgBxc` | explore | no clean stop | Structure exploration has no confirmed completed response. |
| `ses_1b44f5172ffe5rkqGA2wGBrL9Q` | explore | no clean stop | Screen implementation exploration has no confirmed completed response. |
| `ses_1b44f7c14ffeYbCMDNS2N9fpDN` | explore | no clean stop | Model/theme exploration has no confirmed completed response. |
| `ses_1bc427b19ffeHmj1HyjY41vwuH` | explore | trailing `patch` | The last recorded part is a patch, not a completed response. |
| `ses_1bc565081ffe5uzatZuu5GZPDn` | general | trailing `reasoning` | Compilation-fix work ends in reasoning without a clean response. |

The two previously reviewed child sessions are not in this queue because they
did complete cleanly and their durable findings are already recorded. Their
parents, however, contain separate follow-up work; this report does not close
or delete either parent.

## Verified Learning Map

The following completed root sessions had the highest cross-cutting signal in
the first pass. Their “complete” language was not copied as fact; the current
source was checked and the remaining gates were preserved.

### 1. Provider boundaries are improved, not globally complete

**Source session:** `ses_1be7d6948ffejxPgip6l9gWDA0` - `AI cache image service hardening complete`

**Observed now:** `AiService` injects and constructs
`OpenAiProviderClient` and `GeminiProviderClient`. The provider clients own
the normal OpenAI/Gemini transport path.

**Important correction:** Current source still contains direct provider HTTP
methods in `lib/services/enhanced_ai_api_service.dart`, including
`chat/completions` and `generateContent` paths. The session itself acknowledged
that this was a separate out-of-scope service, so “provider-specific transport
is gone” is true only for the scoped `AiService` path, not for the repository as
a whole.

**Durable lesson:** Architecture claims need a scope qualifier. A clean facade
refactor does not prove that every parallel service or correction path has been
migrated.

**Open gate:** Decide whether `EnhancedAiApiService` and correction transport
belong in the same canonical migration, then verify with a repository-wide
transport search and focused tests.

### 2. A local Functions split is not deployment closure

**Source session:** `ses_1bc4a13fbffeEh0bTlFAHRaRr2` - `Community Impact Card MVP`

**Observed now:** The current tree contains `functions/src/helpers.ts`,
`functions/src/disposal.ts`, and a reduced `functions/src/index.ts`:

| File | Current lines |
|---|---:|
| `functions/src/index.ts` | 1,234 |
| `functions/src/helpers.ts` | 283 |
| `functions/src/disposal.ts` | 291 |

`generateDisposal` is exported from `disposal.ts`, and the main index exports
the current payment, storage, referral, family, migration, and verification
routes. The session's historical line counts have drifted.

**Historical/open:** The session explicitly marked staging Firebase setup as
not started and listed required environment variables. No deployment or
staging proof follows from the existence of the split files.

**Durable lesson:** Local compilation and file extraction prove repository
structure only. Deployment readiness requires environment, staging, callable,
auth/App Check, rollback, and hosted-runtime evidence.

### 3. Segmentation has a canonical box model, but real model weights remain a gate

**Source session:** `ses_1b5b21c7cffeY6Fh2eik3R0aGS` - `Multi-item waste segmentation UX`

**Observed now:** `NormalizedBoundingBox` is the shared model used by the
manual selector and segmentation services. `OnDeviceSegmentationBackend`,
`YoloSegmentationBackend`, and MobileSAM backends exist as separate paths.
The code still contains a TODO for TFLite inference, and no `.tflite`, `.onnx`,
`.pt`, or `.bin` model files were found under `assets/` during this pass.

**Historical/open:** The session reported 36 passing tests and described
future YOLO weights, MiniCPM real-API validation, and MobileSAM conversion as
remaining work. Those are not closed by the current model abstraction.

**Durable lesson:** A stable data contract and heuristic fallback are useful
milestones, but they do not establish real model quality, device performance,
or production segmentation readiness.

### 4. Local ML is an interface and pipeline, not yet real inference

**Source session:** `ses_1b4510faeffe6KFYIJYvEl3bIr` - `Local ML Classifier Plan`

**Observed now:** `LocalClassifier` and `ClassificationPipeline` exist, and
the offline degradation tiers are represented in source and documentation.
`TfliteLocalClassifier` is referenced as a future implementation rather than
as a concrete class, `tflite_flutter` is not an active production dependency,
and no model binary is present in the app assets.

**Historical/open:** The session correctly listed real TFLite/VLM inference,
iOS parity, and battery/thermal benchmarks as blocked or deferred.

**Durable lesson:** Keep interface, orchestration, model weights, and device
benchmarks as separate evidence tiers. “Offline pipeline exists” must not be
reported as “offline model inference works.”

### 5. City policy coverage needs governance status, not only plugin count

**Source session:** `ses_1b44f5e01ffexWw4YYOugVdUIx` - `Indian city disposal rules research`

**Observed now:** City plugin registration exists in
`lib/services/local_guidelines_plugin.dart`; the current source has 18
`registerPlugin` calls. `SocietyPolicyService` and the `societyPolicies`
schema reference exist, and `.github/workflows/policy-source-check.yml` is
present. The current rule-pack source contains 11 `governanceStage: 'draft'`
markers.

**Correction:** The historical report's “17 cities” and “44/44 tests pass”
are not adopted as current facts by this index. The plugin count includes the
current registration surface, while governance stage and source freshness are
separate questions.

**Durable lesson:** Policy breadth is not policy authority. Every city pack
needs a named source, freshness signal, governance stage, safety override
behavior, and appropriate verification before it is presented as authoritative.

### 6. Deprecated cache code should not be mistaken for disposable cache data

**Source session:** `ses_1a0dd2e69ffeLdWljF1nQ4V8ac` - `Find image compression in EnhancedCacheService`

**Observed now:** `EnhancedCacheService` is explicitly deprecated and opens
`enhanced_cache_classifications` and `enhanced_cache_images`. The current
runtime wiring uses `ClassificationCacheService` in `cache_service.dart`.

**Durable lesson:** A deprecated source file may contain persistent application
data contracts. It is not safe to delete the file or clear its Hive boxes as
ordinary temporary cache without migration and old-build ownership checks.

The full verified addendum is preserved in
`docs/implementation/technical/classification_caching_technical_spec.md`.

## Existing Learning Addenda

The second selected child report, `Find Firebase Storage upload patterns`, is
preserved in
`docs/reports/FIREBASE_BATCH_PATH_MIGRATION_2026-05-26.md`. Its current-source
correction is important: contribution uploads now belong to
`CommunityContributionService`, and the current contribution path does not
show the same EXIF-stripping call used by batch uploads.

## Review Priorities

1. Preserve and classify the 12 open/uncertain sessions before any deletion
   discussion.
2. Reconcile the parallel provider transport path before claiming repository-
   wide provider canonicalization.
3. Treat staging, real model weights, hosted runtime, policy authority, and
   device benchmarks as independent closure gates.
4. Continue with a bounded second review of completed roots whose final reports
   contain concrete security, data lifecycle, or canonicalization findings.

## Evidence and Limits

- **Tier 1:** Current-source and SQLite static inspection.
- **Not established:** current hosted deployment, live Firebase state, device
  model performance, production test results, or public user behavior.
- The first pass reviewed the full session inventory and a bounded set of
  highest-signal completed reports; it did not reproduce every historical test
  claim or copy every transcript.
- No session deletion is recommended from this report solely on title, age,
  payload size, or an agent's “complete” wording.

## Second-Pass Candidate Queue - 2026-09-12

This is a deletion-review list, not a deletion authorization. No session was
deleted in this pass. The mechanical filter required all of the following:

- child session with a clean latest assistant `finish=stop`
- latest part is `step-finish`
- no recorded child sessions or descendants
- no recorded session file-change summary
- parent session has a clean latest assistant `finish=stop`

The filter returned 73 sessions with approximately 21.63 MiB of logical
session/message/part payload. Logical payload is not the same as physical
SQLite recovery. The current OpenCode database is much larger than this queue,
so this list is not expected to solve the database space problem by itself.

### Protected Patch-Bearing Sessions

These five sessions also matched the mechanical filter, but contain patch
parts. They remain protected until their changes are reconciled against the
live dirty worktree and any resulting learning is recorded.

| Session | Parent | Logical bytes | Parts | Patch parts | Title |
|---|---|---:|---:|---:|---|
| `ses_0f5dd55caffeE6fM7gx253pEQr` | `ses_0f734b6a6ffe8j7fOqFyBLlyJj` | 233,931 | 100 | 8 | Fix riverpod.Consumer references |
| `ses_0f607597fffeVCM3zLrdmaes5G` | `ses_0f734b6a6ffe8j7fOqFyBLlyJj` | 932,496 | 353 | 42 | Migrate test files to Riverpod |
| `ses_0f6145a4affebIwz9WvXstBCBM` | `ses_0f734b6a6ffe8j7fOqFyBLlyJj` | 2,032,672 | 467 | 76 | Migrate screens batch 1 to Riverpod |
| `ses_0f6187255ffe2mNn6eODg1BMXr` | `ses_0f734b6a6ffe8j7fOqFyBLlyJj` | 772,900 | 228 | 23 | Migrate settings widgets to Riverpod |
| `ses_1ac38f8caffeX70H1y65TI05O3` | `ses_1ac39fd17ffeOmXGvpLq3zwf5c` | 377,393 | 89 | 2 | Check gamification/token config and tests |

### Preliminary No-Patch Review Queue

The following 68 exact session IDs passed the mechanical filter and contain no
patch parts. They are preliminary deletion-review candidates only. Their
final text still has to be checked for signal, open work, sensitive material,
and whether its learning has been captured in a canonical project document.

| Session | Logical bytes | Parts | Title |
|---|---:|---:|---|
| `ses_1be6965f7ffeIwFWD2Gl2qil4B` | 13,216 | 5 | Executioner role brainstorm |
| `ses_1d2f829ddffeMNPfOv3oiQ8qLi` | 17,627 | 17 | Read remaining navigation callers |
| `ses_1ac1cfd75ffeDdI0cSEwz6jMI3` | 23,595 | 31 | Verify CI/CD and test infrastructure exists |
| `ses_1a15a913bffe3bWyYgk1SZL9eq` | 31,592 | 13 | Find AiJob model and VisonModelConfig |
| `ses_1a0dd2e69ffeLdWljF1nQ4V8ac` | 49,127 | 10 | Find image compression in EnhancedCacheService |
| `ses_1ab29d2ecffePPOfXMtqJVQ6Th` | 74,389 | 45 | Check stale claims and patterns |
| `ses_1ac3c0033ffeOmFs96S1p16SXY` | 82,831 | 22 | Verify premium widget files |
| `ses_1ab29c5ceffeBSg4SMMImAGoxj` | 83,150 | 55 | Verify broken dependency chain |
| `ses_1a1301434ffeLHUc2QEOIl4RdD` | 83,994 | 12 | Read existing exploration docs for gaps |
| `ses_1ab29dbfaffenozzM18SjZxWyy` | 84,964 | 64 | Verify fixed items in codebase |
| `ses_1a1319286ffegd8tHdMI1YA9sN` | 86,038 | 24 | Audit token and points UI |
| `ses_1ac1d3072ffe1Zl5lIVB2896SX` | 89,129 | 33 | Verify t5 tests and env doc claims |
| `ses_1a131a84bffeBf6I6Lmr4dCrGx` | 94,102 | 33 | Audit profile screen actual implementation |
| `ses_1d327982effeC5FZRIViMC4dhL` | 100,045 | 32 | Audit v1 feedback widget provider deps |
| `ses_1ab299299ffekNkdnIdwRllPTY` | 105,646 | 62 | Check home screen and achievement integration |
| `ses_19f981d74ffeeRkgRKKWQ3pYPP` | 120,605 | 29 | Read key gamification exploration docs |
| `ses_1ab29fee4ffe98twmPwoM9SULa` | 121,634 | 42 | Verify issue_review code claims |
| `ses_1a15bbf10ffepbgX0qCgpg3cOO` | 123,978 | 44 | Find Firebase Storage upload patterns |
| `ses_1d32b2e38ffenGfQTinU5bSe2v` | 129,029 | 70 | Map all result screen paths |
| `ses_19fae3972ffeNvMLwvbZphm46p` | 130,760 | 44 | Find all gamification files |
| `ses_1c11eeadfffe7KJzQohy1jQFeo` | 148,547 | 46 | Verify scripts existence |
| `ses_1bb1cf420ffeAzu3cQ0ZaxjXYO` | 155,338 | 23 | Analyze AiService extractable modules |
| `ses_1a0e952a6ffeKR0xfR8fDbHrBl` | 157,914 | 87 | Find cache service usage |
| `ses_1d31831bbffeTL1n4o5VaoCQeM` | 163,218 | 74 | Deep dive into v1 tag system |
| `ses_1ab29835bffehK6vOkHDPJYUsP` | 167,342 | 28 | Check pubspec for animation deps |
| `ses_1a131a1c7ffexr8OK8E9jdCHF6` | 167,584 | 24 | Audit history screen actual implementation |
| `ses_1ac3bd311ffevrOYY4h31fzjsG` | 169,157 | 48 | Check legacy settings screen |
| `ses_19f9cc459ffeT65nMgBIUJlH1l` | 180,887 | 110 | Find all gamification TODOs and stubs |
| `ses_1ab281b9bffeFjBT3PjJxaq7VP` | 181,923 | 21 | Read key source files for verification |
| `ses_1c11ec8e7ffe4qUBxXYrA7qZAK` | 183,223 | 62 | Verify test coverage claims |
| `ses_1ab29ec37ffe9LLvC26CWPNipg` | 187,023 | 61 | Check test suite and build status |
| `ses_1ac3bea80ffe4gIvA0VohAmNep` | 187,553 | 36 | Verify test files and baseline |
| `ses_1ab296aacffe4I5jSeKHZJdupe` | 194,382 | 46 | Verify Firestore rules and test gates |
| `ses_1c11edad6ffeNXmS0wjN79Dvqp` | 202,258 | 79 | Verify navigation code patterns |
| `ses_1ab29b462ffe6sNwxsVmB3HJQg` | 205,660 | 49 | Check test suite status |
| `ses_1ac3c413fffeXG3ei1ZsWQtIfk` | 212,832 | 51 | Verify theme/colors/typography |
| `ses_19faaaab8ffe9bfnBSUntDyTzg` | 213,249 | 104 | Trace GamificationResult flow |
| `ses_1ab2a29d7ffebSkxge6i4q87pY` | 219,443 | 47 | Check Firestore rules community |
| `ses_1d3279834ffeEir81vJzXhQjYA` | 242,713 | 41 | Full v1 vs v2 feature inventory |
| `ses_1ac1d05b2ffee1IHnq6xXvRlrD` | 263,001 | 50 | Run test baseline and dynamic checks |
| `ses_1ac1d1739ffeg646v4wqnePxK7` | 271,893 | 67 | Verify analytics and feedback widget claims fully |
| `ses_1ac1e2eccffeCarEGj2iI2ky5k` | 282,701 | 92 | Security and secrets audit |
| `ses_19fb47346ffeZdcE2Epox01Yof` | 286,909 | 112 | Find classification pipeline deep dives |
| `ses_19fa7607fffeEJRxS3Osk3ZB79` | 300,966 | 60 | Map cooperative family mechanics |
| `ses_1ac3be2b2ffeDGTHTweJSJqb6E` | 301,709 | 91 | Check performance/accessibility/animations |
| `ses_1ac1cc234ffeZyv28R0TIRDHkX` | 309,844 | 37 | Explore functions/ Cloud backend |
| `ses_1ac391274ffe0kWTOxvJhKT5k1` | 311,002 | 95 | Trace token/wallet source code |
| `ses_1c11eb93fffe8Xec19foLpTkZI` | 325,712 | 86 | Check monitoring and deployment |
| `ses_19f9f6718ffec21Bvy84NRl84R` | 353,239 | 34 | Read all gamification exploration docs |
| `ses_1a15d42aeffeWu4YhH5UVo2d2X` | 357,533 | 48 | Find OpenAI API usage patterns |
| `ses_1a11ab9f5ffeSGf3wnUDSvGKNx` | 363,163 | 88 | Trace offline queue and retry |
| `ses_1ab2a566affe94CeMOjY7Eswct` | 370,049 | 66 | Trace community service deps |
| `ses_1ac1e48e8ffeaVWv4cPqCHpnnL` | 373,396 | 104 | Audit Firebase setup codebase |
| `ses_1ac1e373dffeFD2vhw018t6XWP` | 381,653 | 86 | Audit Flutter test infrastructure |
| `ses_1a16332a4ffeTOOOe8VX2R5J67` | 391,957 | 219 | Find subcategory/materialType issues |
| `ses_1a11adc08ffed4b5E4ovbU3zEb` | 394,381 | 71 | Map ClassificationState model |
| `ses_1ac1e3867ffewV2nxAPQAPV20O` | 401,655 | 113 | Inventory all repo documents |
| `ses_0f6c9dd35ffeZ2GUEZjR5FaxJu` | 421,466 | 83 | Audit Provider vs Riverpod usage |
| `ses_1ac1e1fadffedaJK9ZzABy478c` | 451,360 | 90 | Audit services and env vars |
| `ses_1a11aad5effeFjXnBxhNPx5qnH` | 459,612 | 113 | Map feedback loop and rendering |
| `ses_1ac3c050effeEGZUfXM3E3gva7` | 483,566 | 79 | Verify gamification and social features |
| `ses_1a12d950bffeeKmOc7VcWsgKSw` | 508,538 | 67 | Find random audit findings docs |
| `ses_1a11ac8abffe7ghx0eARMA2mho` | 534,571 | 81 | Trace routing pipeline services |
| `ses_1ac3c2418ffeByzdRkn7rIRU6A` | 573,483 | 68 | Verify screens and UI components |
| `ses_1a130208effen1pla1PFiUMhul` | 647,634 | 106 | Find what user-facing screens are missing |
| `ses_1a15c2623ffedrVkafbVwdS94Q` | 652,946 | 95 | Explore app structure and data models |
| `ses_1a13039dcffet7Z9Z5CB6YtEw5` | 866,693 | 167 | Find all model fields with no UI |
| `ses_0f7347fe9ffeeMl0YJsYCs0WcY` | 1,504,762 | 139 | Explore repo structure |

The no-patch queue still contains high-signal sessions. In particular,
`ses_1ac1e2eccffeCarEGj2iI2ky5k`, `ses_1ab296aacffe4I5jSeKHZJdupe`,
`ses_1a11ab9f5ffeSGf3wnUDSvGKNx`, and `ses_0f6c9dd35ffeZ2GUEZjR5FaxJu`
remain learning-review items even though they pass the mechanical deletion
filter. They must not be deleted merely because they have no patch parts.

## Second-Pass Verified Learning Addenda

### 7. Security findings require redaction and current-source correction

**Source session:** `ses_1ac1e2eccffeCarEGj2iI2ky5k` - `Security and secrets audit`

**Historical evidence:** The session reported non-empty OpenAI and Gemini
credentials in the project `.env` and reported a Gemini request using a URL
query parameter. Raw credential values are intentionally not reproduced here.

**Observed now:** The current `.env` still has non-empty `OPENAI_API_KEY` and
`GEMINI_API_KEY` entries and is gitignored. The current
`lib/services/enhanced_ai_api_service.dart` path sends the Gemini key in the
`x-goog-api-key` header, not as a query parameter. The provider client also
uses the header form.

**Durable lesson:** Security salvage must redact values, re-check the current
source, and distinguish a historical transport leak from the current transport
implementation. Gitignore status does not establish secret safety for local
backups, sync tools, logs, or compiled artifacts.

**Open gate:** Key rotation/revocation, local secret handling, and release
artifact inspection remain separate operator/security actions. None was
performed in this documentation pass.

### 8. Firestore rules and Cloud Function enforcement are separate boundaries

**Source session:** `ses_1ab296aacffe4I5jSeKHZJdupe` - `Verify Firestore rules and test gates`

**Observed now:** `firestore.rules` has no explicit matches for
`token_spend_ledger`, `ops_metrics`, App Check, or rate limiting. Current
`functions/src/helpers.ts` and `functions/src/index.ts` contain the App Check
and rate-limit helpers and call sites. Admin SDK writes do not depend on
client Firestore rules, while hosted enforcement still depends on deployed
configuration and runtime verification.

**Durable lesson:** Absence of a client Firestore rule is not enough to prove
or disprove server-side protection. Review the client rules, Admin SDK write
path, function enforcement, environment gates, and hosted behavior as separate
evidence surfaces.

### 9. Offline capability is multiple paths, not one feature claim

**Source session:** `ses_1a11ab9f5ffeSGf3wnUDSvGKNx` - `Trace offline queue and retry`

**Observed now:** The repository contains separate
`OfflineClassificationService`, `OfflineQueueService`,
`ResilientNetworkService`, and `ClassificationPipeline` paths. The offline
classification service calls `tryLocalOnly` and `tryLocalWithHint`; the queue
service owns deferred work when local processing cannot complete.

**Durable lesson:** Report offline support per path and tier: deterministic
classification, on-device model availability, queued cloud work, retry, and
recovery are separate claims. A queue or fallback interface does not prove
that real on-device inference, retry completion, or device performance works.

## Portable Learning Promotion Ledger

These principles are suitable for reuse outside the waste-segregation project.
The project-specific paths, counts, IDs, and unresolved actions remain in this
report; only the generalized decision rules were promoted into
`session-learning-salvage`.

| Portable principle | Evidence source | Promotion disposition |
|---|---|---|
| Separate historical agent claims from current source/runtime evidence and label the difference explicitly. | Provider, security, policy, and test audits | Promoted to the skill's verification and evidence-labeling workflow. |
| Treat local structure, passing tests, and generated files as separate from hosted, device, provider, or production closure. | Functions split, local ML, segmentation, and deployment audits | Promoted as an independent-evidence-gates rule. |
| Check canonical ownership and data semantics before retiring deprecated code, caches, stores, or migration paths. | `EnhancedCacheService` and cache-routing audit | Promoted to the skill's canonical-destination and preservation boundaries. |
| Evaluate a feature claim per independent path, tier, fallback, retry, and recovery behavior instead of collapsing them into one capability label. | Offline classification and queue audit | Promoted to the portable-principles workflow. |
| Handle security findings with redaction; gitignored is not equivalent to safe, rotated, or absent from artifacts. | Security and secrets audit | Promoted to the skill's sensitive-value rule. |
| Treat client rules, server/Admin SDK enforcement, environment gates, and hosted behavior as separate security evidence surfaces. | Firestore and Cloud Function audit | Promoted to the portable-principles workflow. |
| Check live Git ownership and context-generation health before closing or deleting work associated with a session. | Dirty worktree and context-compiler observations | Promoted to the skill's open-work triage and re-verification rules. |
| Bound large history queries to the selected project/session IDs before aggregation or windowing. | 31 GB OpenCode database probe | Promoted to the skill's bounded-query rule. |

The following remain project-specific and were not promoted as universal rules:
city plugin counts, waste categories, provider names, Firebase collection
names, model-weight formats, Flutter file paths, and the exact session-selection
queue. They remain useful project evidence but would be misleading as generic
workflow instructions.

The shared cross-project copy is maintained at
`/Users/pranay/Projects/LEARNING_LEDGER.md`. The project report remains the
source for waste-segregation-specific evidence, session IDs, and unresolved
actions.

## Second-Pass Evidence and Non-Actions

- **Tier 1:** Read-only SQLite inspection, current-source searches, redacted
  environment-variable presence checks, and `git diff --check`.
- The context pack is present; the canonical compiler passed with
  `--print-step1 --skip-index`. The project-local shorthand
  `/Users/pranay/Projects/agent-start` is not executable, so the canonical
  `/Users/pranay/Projects/agent-start/bin/agent-start` path was used.
- The live project worktree is dirty with modified, deleted, and untracked
  files. It has no extra worktree or stash reported by the read-only Git check.
- No OpenCode sessions, messages, parts, database rows, profiles, caches,
  project source, or Git state were deleted or rewritten.
- No secret values were written to this report.
- The five patch-bearing sessions and all 12 previously identified
  open/uncertain sessions remain protected.
