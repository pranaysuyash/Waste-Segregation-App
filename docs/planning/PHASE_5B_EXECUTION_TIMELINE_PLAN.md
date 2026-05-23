# Phase 5B: Execution Timeline + Confirmation Ledger — Revised Design

## Context

Phase 5A gave us booking tasks. Phase 5B adds durable execution evidence: confirmation records, a true event ledger, and a privacy-safe timeline view.

This revision addresses 10 specific gaps from the first review: durable event ledger, response privacy tiers, evidence ref schema, verified→voided, shared encryption helper, endpoint paths, ownership validation, and additional tests.

---

## 1. Durable Execution Event Ledger

### `execution_events` table

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | `String(36)` PK | No | `uuid4()` | |
| `agency_id` | `String(36)` FK agencies.id CASCADE | No | | |
| `trip_id` | `String(36)` | No | | |
| `subject_type` | `String(30)` | No | | booking_task / booking_confirmation / booking_document / document_extraction |
| `subject_id` | `String(36)` | No | | FK to the subject row |
| `event_type` | `String(40)` | No | | task_created, task_completed, confirmation_recorded, etc. |
| `event_category` | `String(20)` | No | | task / confirmation / document / extraction |
| `status_from` | `String(20)` | Yes | NULL | Previous status (null for creation) |
| `status_to` | `String(20)` | No | | New status |
| `actor_type` | `String(20)` | No | `system` | `agent` or `system` |
| `actor_id` | `String(36)` | Yes | NULL | User ID when actor_type=agent; NULL for system |
| `source` | `String(30)` | No | `agent_action` | `agent_action` / `system_generation` / `reconciliation` |
| `metadata` | `JSON` | Yes | NULL | Allowed keys only (see below) |
| `created_at` | `DateTime(tz)` | No | `now()` | |

Indexes: `ix_ee_trip_id`, `ix_ee_agency_id`, `ix_ee_subject`, `ix_ee_category`, `ix_ee_trip_created`

**Allowed metadata keys**: `task_type`, `confirmation_type`, `document_type`, `provider`, `model`, `blocker_code`, `evidence_ref_count`

**Forbidden in metadata**: supplier_name, confirmation_number, notes, traveler name, DOB, passport number, document filename, storage_key, signed URL, extracted field values, any PII

**Event types**:
- task (emitted in Phase 5B): task_created, task_blocked, task_ready, task_started, task_waiting, task_completed, task_cancelled
- confirmation (emitted in Phase 5B): confirmation_created, confirmation_updated, confirmation_recorded, confirmation_verified, confirmation_voided
- document (schema-ready, not emitted in Phase 5B): document_uploaded, document_accepted, document_rejected
- extraction (schema-ready, not emitted in Phase 5B): extraction_started, extraction_applied, extraction_rejected

**Who writes events**: The confirmation_service and the booking_task_service both call `emit_execution_event()` after each state transition. Document/extraction event emission is deferred to Phase 5C or later — the schema supports it but no code emits those events yet.

---

## 2. Confirmation Data Model

### `booking_confirmations` table

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| `id` | `String(36)` PK | No | `uuid4()` | |
| `agency_id` | `String(36)` FK agencies.id CASCADE | No | | |
| `trip_id` | `String(36)` | No | | |
| `task_id` | `String(36)` FK booking_tasks.id SET NULL | Yes | NULL | Nullable — standalone allowed |
| `confirmation_type` | `String(20)` | No | | flight/hotel/insurance/payment/other |
| `confirmation_status` | `String(20)` | No | `draft` | State machine |
| `supplier_name_encrypted` | `JSON` | Yes | NULL | `encrypt_blob({"value": "..."})` |
| `confirmation_number_encrypted` | `JSON` | Yes | NULL | `encrypt_blob({"value": "..."})` |
| `has_supplier` | `Boolean` | No | False | Queryable indicator |
| `has_confirmation_number` | `Boolean` | No | False | Queryable indicator |
| `evidence_refs` | `JSON` | Yes | NULL | Typed IDs only (see §5) |
| `notes_encrypted` | `JSON` | Yes | NULL | `encrypt_blob({"value": "..."})`, max 2000 chars plaintext |
| `notes_present` | `Boolean` | No | False | For list/timeline indicator without decrypting |
| `external_ref_encrypted` | `JSON` | Yes | NULL | For external supplier refs |
| `external_ref_present` | `Boolean` | No | False | |
| `recorded_by` | `String(36)` | Yes | NULL | |
| `recorded_at` | `DateTime(tz)` | Yes | NULL | |
| `verified_by` | `String(36)` | Yes | NULL | |
| `verified_at` | `DateTime(tz)` | Yes | NULL | |
| `voided_by` | `String(36)` | Yes | NULL | |
| `voided_at` | `DateTime(tz)` | Yes | NULL | |
| `created_by` | `String(36)` | No | | |
| `created_at` | `DateTime(tz)` | No | `now()` | |
| `updated_at` | `DateTime(tz)` | No | `now()` | Auto-updated |

Indexes: `ix_bc_trip_id`, `ix_bc_agency_id`, `ix_bc_task_id`, `ix_bc_status`, `ix_bc_type`, `ix_bc_trip_status`

### State machine (revised — verified is voidable)

```
draft → recorded → verified
draft → voided
recorded → voided
verified → voided
```

```python
CONFIRMATION_VALID_TRANSITIONS = {
    "draft": {"recorded", "voided"},
    "recorded": {"verified", "voided"},
    "verified": {"voided"},
    "voided": set(),
}
```

Voided confirmations are NOT deleted. They remain in history with the execution event recording the void.

---

## 3. Response Privacy Tiers

### ConfirmationSummaryResponse (list endpoint)

Returns **no decrypted private fields**:
- id, trip_id, task_id, confirmation_type, confirmation_status
- has_supplier, has_confirmation_number, external_ref_present, notes_present
- evidence_ref_count (derived from evidence_refs.length)
- recorded_at, verified_at, voided_at (timestamps only, no actor names)
- created_by, created_at

### ConfirmationDetailResponse (single-record GET/PATCH)

Returns decrypted private fields for **authenticated agent editing**:
- Everything in SummaryResponse, plus:
- supplier_name (decrypted), confirmation_number (decrypted), notes (decrypted)
- evidence_refs (typed IDs), external_ref (decrypted)
- recorded_by, verified_by, voided_by (user IDs)

### ExecutionTimelineEvent (timeline endpoint)

Returns **zero private data**:
- timestamp, event_category, event_type, subject_type, status_from, status_to, actor_type, actor_id, source
- metadata (allowed keys only)

---

## 4. Encryption Helper — Shared Location

### New file: `spine_api/services/private_fields.py`

Moves `encrypt_blob` / `decrypt_blob` out of `extraction_service.py` into a neutral module.

```python
def encrypt_blob(data: dict) -> dict | None:
    """Encrypt a JSON dict as a single Fernet token."""
    # Exact same logic, moved from extraction_service.py

def decrypt_blob(data: dict) -> dict | None:
    """Decrypt a blob-encrypted JSON dict."""

def encrypt_field(value: str | None) -> dict | None:
    """Encrypt a single string field as a blob."""
    if not value: return None
    return encrypt_blob({"value": value.strip()})

def decrypt_field(blob: dict | None) -> str | None:
    """Decrypt a single string field from a blob."""
    if not blob: return None
    decrypted = decrypt_blob(blob)
    return decrypted.get("value") if decrypted else None
```

Then update `extraction_service.py` to import from `private_fields.py` instead of defining its own.

---

## 5. Evidence Refs — Strict Schema

**Allowed ref types** (typed IDs only):

```json
[
  {"type": "booking_document", "id": "doc-uuid"},
  {"type": "document_extraction", "id": "ext-uuid"},
  {"type": "extraction_attempt", "id": "attempt-uuid"},
  {"type": "booking_task", "id": "task-uuid"}
]
```

**No arbitrary strings, no filenames, no URLs, no free text.**

External supplier references use dedicated encrypted columns: `external_ref_encrypted` + `external_ref_present`.

**Ownership validation** (service layer):
- Each evidence ref's target must satisfy: `target.trip_id == trip_id AND target.agency_id == agency_id`
- Same for task_id: `task.trip_id == trip_id AND task.agency_id == agency_id`
- Reject with ValueError if cross-trip or cross-agency

---

## 6. API Endpoints — Under `/api/trips`

All confirmation endpoints scoped under trips (not booking-tasks):

| Method | Path | Purpose | Response |
|---|---|---|---|
| GET | `/api/trips/{trip_id}/confirmations` | List (summary) | ConfirmationSummaryResponse[] |
| GET | `/api/trips/{trip_id}/confirmations/{id}` | Detail | ConfirmationDetailResponse |
| POST | `/api/trips/{trip_id}/confirmations` | Create | ConfirmationDetailResponse |
| PATCH | `/api/trips/{trip_id}/confirmations/{id}` | Update | ConfirmationDetailResponse |
| POST | `/api/trips/{trip_id}/confirmations/{id}/record` | draft→recorded | ConfirmationSummaryResponse |
| POST | `/api/trips/{trip_id}/confirmations/{id}/verify` | recorded→verified | ConfirmationSummaryResponse |
| POST | `/api/trips/{trip_id}/confirmations/{id}/void` | any→voided | ConfirmationSummaryResponse |
| GET | `/api/trips/{trip_id}/execution-timeline` | Timeline | ExecutionTimelineEvent[] |

New router file: `spine_api/routers/confirmations.py` with `prefix="/api/trips"`

---

## 7. Service Layer

### `spine_api/services/confirmation_service.py`

- `list_confirmations(db, trip_id, agency_id)` — summary response (no decryption)
- `get_confirmation(db, confirmation_id, agency_id)` — detail response (decrypts)
- `create_confirmation(db, trip_id, agency_id, created_by, data)` — encrypts, validates ownership, emits event
- `update_confirmation(db, confirmation_id, agency_id, data)` — draft: fully editable. recorded: editable but emits `confirmation_updated` event. verified/voided: not editable.
- `record_confirmation(...)` — draft→recorded, emits event
- `verify_confirmation(...)` — recorded→verified, emits event
- `void_confirmation(...)` — any non-voided→voided, emits event

### `spine_api/services/execution_event_service.py`

- `emit_event(db, agency_id, trip_id, subject_type, subject_id, event_type, category, status_from, status_to, actor_type, actor_id, source, metadata)` — inserts execution_event row. `actor_type` is "agent" or "system". `source` is "agent_action", "system_generation", or "reconciliation".
- `get_timeline(db, trip_id, agency_id)` — reads from execution_events table, returns sorted list + summary

No more aggregation from current-row state. Timeline is sourced entirely from `execution_events`.

**Forbidden metadata keys enforcement**: `emit_event` validates that metadata dict contains only keys from the allowed set. Raises ValueError if any forbidden key (supplier_name, confirmation_number, notes, etc.) is present.

---

## 8. Frontend

### New: `ConfirmationPanel.tsx`
- Create/edit form for confirmations
- List view shows summary only (has_supplier, has_confirmation_number badges)
- Detail view decrypts for editing (masked input with reveal toggle)
- Status actions: Record, Verify, Void

### New: `ExecutionTimelinePanel.tsx`
- Reads from GET execution-timeline
- Category filter chips (All, Tasks, Confirmations, Documents)
- No PII — only type, status, actor, timestamp

### Modify: `BookingExecutionPanel.tsx`
- Show confirmation badge on CONFIRMATION_REQUIRED_TASK_TYPES tasks
- "Add Confirmation" button opens ConfirmationPanel
- Fetch confirmation summary from list endpoint

### Types in `api-client.ts`
- `ConfirmationSummary`, `ConfirmationDetail` (separate types)
- `CreateConfirmationRequest`, `UpdateConfirmationRequest`
- `ExecutionTimelineEvent`
- API functions matching 8 endpoints

---

## 9. Audit / Event Privacy

| Source | Logged in execution_event | Excluded |
|---|---|---|
| Task transition | task_type, status_from, status_to, actor | blocker_refs values |
| Confirmation transition | confirmation_type, status_from, status_to, actor | supplier_name, confirmation_number, notes |
| Document event | document_type, status_to, actor | filename_hash, storage_key |
| Extraction event | provider, status_to, actor | extracted_fields |

---

## 10. Files to Create/Modify

### Create
- `spine_api/services/private_fields.py` — shared encrypt/decrypt helpers
- `spine_api/services/confirmation_service.py`
- `spine_api/services/execution_event_service.py`
- `spine_api/routers/confirmations.py`
- `alembic/versions/add_booking_confirmations.py`
- `frontend/src/components/workspace/panels/ConfirmationPanel.tsx`
- `frontend/src/components/workspace/panels/ExecutionTimelinePanel.tsx`
- `tests/test_confirmation_service.py`
- `tests/test_execution_event_service.py`
- `frontend/.../ConfirmationPanel.test.tsx`
- `frontend/.../ExecutionTimelinePanel.test.tsx`

### Modify
- `spine_api/models/tenant.py` — add BookingConfirmation + ExecutionEvent models + constants
- `spine_api/services/extraction_service.py` — import encrypt_blob/decrypt_blob from private_fields
- `spine_api/services/booking_task_service.py` — add emit_event calls after task transitions
- `spine_api/server.py` — register confirmations router
- `frontend/src/lib/api-client.ts` — add types + API functions
- `frontend/src/components/workspace/panels/BookingExecutionPanel.tsx` — integrate confirmation triggers

---

## 11. Implementation Order

1. `private_fields.py` — shared encryption helpers (refactored from extraction_service)
2. `tenant.py` — BookingConfirmation + ExecutionEvent models + constants
3. Migration: `add_booking_confirmations.py` (both tables)
4. `execution_event_service.py` — event emission + timeline query
5. `confirmation_service.py` — CRUD + encryption + state machine + event emission
6. `booking_task_service.py` — add emit_event calls after transitions
7. `confirmations.py` router — 8 endpoints
8. `server.py` — register router
9. Backend tests (~32 tests)
10. Frontend types + API functions in `api-client.ts`
11. `ConfirmationPanel.tsx` + `ExecutionTimelinePanel.tsx`
12. `BookingExecutionPanel.tsx` integration
13. Frontend tests (~20 tests)

---

## 12. Test Plan (~52 tests)

**Backend: ~32 tests**

`test_confirmation_service.py` (~20):
- State machine: 8 (all valid transitions + all invalid + verified→voided)
- Encryption helpers: 3 (round-trip, None, empty)
- Create validation: 3 (valid, invalid type, cross-trip task_id rejected)
- Update restrictions: 3 (verified blocked, voided blocked, recorded update emits event)
- Ownership: 2 (cross-agency task_id rejected, cross-trip evidence_ref rejected)
- Notes guardrails: 1 (notes over max length rejected)

`test_execution_event_service.py` (~16):
- Event emission: 3 (creates row, correct metadata, forbidden metadata rejected)
- Actor modeling: 2 (system event has actor_type=system + actor_id=null; agent event has actor_type=agent + actor_id=user_id)
- Source field: 1 (reconciliation vs agent_action distinguished)
- Timeline query: 4 (sorted chronologically, category filter, empty trip, multi-category)
- Privacy: 4 (no supplier_name, no confirmation_number, no notes, no filenames in events)
- Voiding history: 2 (voided confirmation stays in timeline, void event recorded)

**Frontend: ~20 tests**

`ConfirmationPanel.test.tsx` (~13):
- Summary list shows has_* badges (has_supplier, has_confirmation_number, notes_present), no decrypted values
- Detail view shows decrypted values
- Create form validates fields
- Notes max length enforced
- Status actions call correct endpoints
- Evidence ref validation
- Privacy masking toggle

`ExecutionTimelinePanel.test.tsx` (~8):
- Renders events by category
- Category filter works
- No PII in rendered output (no supplier_name, confirmation_number, notes)
- Empty state message
- Summary stats
- Cross-category chronological order
- Actor rendering (system shows "System", agent shows user info)
- Event type labels

---

## 13. Non-goals

- No supplier API integration
- No payment gateway
- No email/WhatsApp automation
- No customer-facing confirmation portal
- No automatic confirmation creation on task completion
- No document/extraction event emission in Phase 5B — the event schema is future-ready but only task and confirmation events are emitted now. Document/extraction event backfill is Phase 5C+.

---

## 14. Verification

1. `alembic upgrade head` — both tables created
2. `pytest tests/test_confirmation_service.py tests/test_execution_event_service.py -v` — all pass
3. `vitest run` — all frontend tests pass
4. `tsc --noEmit` — zero source TS errors
5. `scripts/snapshot_server_routes.py --write` — route count updated
6. Manual: generate tasks, complete confirm_flights, add confirmation, verify timeline shows task_created → task_completed → confirmation_created → confirmation_recorded
