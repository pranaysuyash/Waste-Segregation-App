# DOCUMENTATION_TRUTH_MAP_2026-05-21
Date: 2026-05-21
Scope: repository documentation reliability audit for AI classification stack, feedback loop, ResultScreen docs, token-economy docs
Method: code-first verification against live files + targeted test execution

Truth labels used
- real: directly verified in current code/runtime evidence
- needs_verification: partially verified or historically true but not recently validated end-to-end
- speculative: design intent, roadmap, or now contradicted by code

---

## 1) Read-first order (for any new execution agent)
1. `AGENTS.md` (repo-level constraints)
2. `motto_v2.md` (execution discipline)
3. `firebase_task.md` (phase checklist and required behavior)
4. `docs/review/P0_EXECUTION_PROGRESS_2026-05-21.md` (latest execution packet)
5. `docs/review/AI_EVAL_HARNESS_IMPLEMENTATION_PACKET_2026-05-21.md` (eval/correction-loop implementation state)
6. `docs/review/DOCUMENTATION_TRUTH_MAP_2026-05-21.md` (this map)
7. `docs/architecture/CURRENT_AI_ARCHITECTURE.md` (use with caution; partially stale, see below)

---

## 2) Source-of-truth index (current)

### A) Governance / execution (authoritative)
- `AGENTS.md` -> real
- `motto_v2.md` -> real
- `firebase_task.md` -> real

### B) AI runtime architecture (code is source-of-truth)
Primary runtime files:
- `functions/src/classify_image.ts`
- `functions/src/index.ts`
- `lib/services/ai_service.dart`
- `lib/services/providers/backend_proxy_provider.dart`
- `lib/models/waste_classification.dart`
- `lib/models/classification_feedback.dart`
- `lib/services/result_pipeline.dart`
- `lib/services/firestore_schema_registry.dart`

Status: real (compile status re-validated; see section 4-D)

### C) Eval + correction-loop infra (new)
- `eval/classification/schema/golden_case.schema.json`
- `eval/classification/golden/golden_cases_v1.jsonl`
- `eval/classification/fixtures/provider_outputs_v1.jsonl`
- `scripts/eval/run_classification_eval.py`
- `scripts/eval/export_feedback_candidates.py`
- `eval/classification/reports/eval_report_offline_v1.json`

Status: real (implemented and executed)

---

## 3) Reliability map for major docs

| Doc | Verdict | Why |
|---|---|---|
| `docs/review/BACKEND_GATEWAY_IMPLEMENTATION_NOTES_2026-05-21.md` | real | Matches code: `classifyImage` exists and is exported at `functions/src/index.ts:1016`; backend proxy provider exists and AiService routing checks enabled flag. |
| `docs/review/AI_EVAL_HARNESS_IMPLEMENTATION_PACKET_2026-05-21.md` | real | Created in this run; all referenced artifacts exist. |
| `docs/architecture/CURRENT_AI_ARCHITECTURE.md` | speculative (partially stale) | Claims "no classifyImage function" and "classification fully client-side" are no longer true after backend proxy integration. |
| `docs/review/AI_PIPELINE_TRUTH_MAP_2026-05-21.md` | speculative (partially stale) | Previously accurate snapshot, now outdated on backend classification path presence and routing state. |
| `docs/implementation/ai/api_key_management_and_security.md` | speculative | Contains aspirational sections and outdated provider/routing assumptions; not aligned with current code. |
| `docs/implementation/ai/model_routing.md` | needs_verification | High-level concept remains useful, but operational claims require revalidation against active routing code. |
| `docs/design/result_screen_v2_documentation.md` | needs_verification | Architectural statements mostly align; historical pass-state claims should be treated as time-bound and revalidated against current tree (see section 4-D). |
| `docs/reports/RESULT_SCREEN_V2_OVERHAUL_REPORT.md` | needs_verification | Same as above; historical report, not current pass-state guarantee. |
| `TOKEN_ECONOMY_TODO.md` | needs_verification | Task tracker still useful, but several completion markers and assumptions are outdated relative to current code/test reality. |
| `docs/reports/audits/RANDOM_DOCUMENT_AUDIT_TOKEN_ECONOMY_2026-05-19.md` | speculative (time-bound snapshot) | Good forensic snapshot for that date; several findings now superseded by later implementation/tests. |
| `docs/DOCUMENTATION_INDEX.md` | speculative (stale index) | Contains many outdated paths and role guidance no longer matching current structure. |
| `docs/README.md` | speculative (stale index) | Contains obsolete navigation links and outdated environment/config claims. |
| `docs/reference/APP_KNOWLEDGE_BASE.md` | needs_verification | Valuable broad context, but marked last verified earlier and includes legacy assertions requiring refresh. |

---

## 4) Concrete contradictions found

### A) Backend classification existence
Contradiction:
- Some docs claim `classifyImage` callable does not exist.
Verified code:
- `functions/src/classify_image.ts` exists.
- `functions/src/index.ts:1016` exports `classifyImage`.
- `lib/services/providers/backend_proxy_provider.dart` calls callable `classifyImage`.
- `lib/services/ai_service.dart:810` and `:1009` route through backend when enabled.

Conclusion: docs claiming "no backend classifyImage" are stale.

### B) Routing mode claims
Contradiction:
- Docs claiming classification is strictly client-direct only.
Verified code:
- Backend route is available behind `USE_BACKEND_AI_IN_RELEASE` and used before direct provider path.

Conclusion: architecture is now hybrid-capable, not strictly client-only.

### C) Token economy historical findings vs current state
Contradiction:
- 2026-05-19 audit claims zero TokenService tests.
Verified code:
- `test/services/token_service_test.dart` exists now.

Conclusion: that specific finding is superseded.

### D) ResultScreen test pass claims vs current state
Historical note:
- An earlier run had a constructor parse failure in `lib/services/result_pipeline.dart`.

Current verification run:
- Command run: `flutter test test/screens/result_screen_test.dart test/screens/result_screen_widget_test.dart test/golden/result_screen_v2_golden_test.dart`
- Result: all targeted ResultScreen tests passed.

Conclusion: test-status statements are time-bound; they must always be backed by fresh command evidence for the current tree.

---

## 5) Stale-doc supersession map

Superseded documents (for operational decisions):
1. `docs/architecture/CURRENT_AI_ARCHITECTURE.md` (parts) -> superseded by code files listed in section 2-B and backend gateway notes.
2. `docs/review/AI_PIPELINE_TRUTH_MAP_2026-05-21.md` (parts) -> superseded by post-backend-routing code state.
3. `docs/DOCUMENTATION_INDEX.md` and `docs/README.md` (navigation claims) -> superseded by direct repo tree inspection.
4. `docs/reports/audits/RANDOM_DOCUMENT_AUDIT_TOKEN_ECONOMY_2026-05-19.md` (specific findings) -> superseded where code/test changes landed after 2026-05-19.

Rule: keep old docs as historical records, but mark them explicitly as historical snapshots.

---

## 6) Recommended doc hygiene actions
1. Add "snapshot timestamp + scope boundary" banner to architecture/review docs that are date-sensitive.
2. Split canonical runtime truth into one file with strict ownership:
   - `docs/architecture/CURRENT_RUNTIME_TRUTH.md`
3. Add machine-checkable status footer in key docs:
   - "Last code-verified commit/date"
   - "Verification command"
4. Add a lightweight doc consistency CI check for:
   - existence of referenced paths
   - forbidden stale phrases (e.g., "classifyImage does not exist")

---

## 7) Operational note
This truth map is a runtime reliability overlay, not a replacement for historical design docs. If conflict appears between docs, trust:
1) code,
2) latest execution packets,
3) this truth map,
in that order.
