# API Design Audit

Date: 2026-08-01  
Repository: `/Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app`  
Audit basis: `api-design` skill, repository `motto_v4.md`, live source inspection, and focused Functions checks.

## Executive decision

The current backend has useful security and operational foundations, but it does not yet have one coherent, published application API contract.

The system currently exposes three different API surfaces:

1. Firebase callable commands, such as `classifyImage`, `spendUserTokens`, `createCheckoutSession`, and `getR2UploadUrl`.
2. Firebase HTTP functions, such as `generateDisposal`, `healthCheck`, `getBatchStats`, `aggregateCommunityStatsHttp`, diagnostics, and the Dodo webhook.
3. Direct Firestore and Storage SDK access from the Flutter client, governed by `firestore.rules` and `storage.rules`.

That separation is technically valid. The design problem is that the surfaces are not documented or governed as distinct contracts. The existing API specification describes a generic `UnifiedApiClient` and a mostly HTTP-shaped envelope, while the live product path uses callable functions and direct Firebase data contracts for most user operations. The long-term direction should be one named Firebase application API contract with explicit transport-specific rules, shared schemas, stable error semantics, and an authoritative inventory.

This is an audit and documentation deliverable. No production implementation was changed.

## Evidence and limits

### Tier 1, static inspection

Inspected the current source and contract surfaces:

- `functions/src/index.ts`
- `functions/src/classify_image.ts`
- `functions/src/disposal.ts`
- `functions/src/helpers.ts`
- `functions/src/create_checkout_session.ts`
- `functions/src/create_token_purchase.ts`
- `functions/src/dodopayments_webhook.ts`
- `functions/src/r2_storage.ts`
- `functions/src/community_stats_aggregator.ts`
- `functions/src/ops_hardening.ts`
- `firestore.rules`
- `storage.rules`
- `lib/services/providers/backend_proxy_provider.dart`
- `lib/services/disposal_instructions_service.dart`
- `lib/services/firestore_schema_registry.dart`
- `docs/reference/api_documentation/api_specification.md`

### Tier 2, focused checks

Commands run from `functions/`:

```text
npm run build                         PASS
npm run test:http-response-contracts PASS, 2 tests
npm run test:http-guards             PASS, 6 tests
```

These checks do not prove complete end-to-end behavior. Payment provider behavior, webhook retries, callable contracts, Firestore rules, Storage rules, and deployed configuration remain unverified in this audit.

## Current API inventory

### Callable command surface

The current callable exports are command-shaped, which is appropriate for operations with domain side effects. They use Firebase `HttpsError`, not the HTTP envelope in `functions/src/helpers.ts`.

| Function | Domain role | Primary risk to contract quality |
|---|---|---|
| `classifyImage` | AI classification, token reservation, cache, cost event | High value and high risk. Requires stable request idempotency, schema validation, and explicit lifecycle states. |
| `reanalyzeWithCorrection` | Reclassification after user correction | Must preserve ownership, correction provenance, and repeat-request semantics. |
| `spendUserTokens` | Money-adjacent token mutation | Requires idempotency, atomic ledger semantics, and a stable error map. |
| `createBatchAiJob` | Creates an asynchronous AI job | Should return a resource lifecycle contract, not only an implementation-specific job identifier. |
| `createCheckoutSession` | Starts premium checkout | Requires idempotency and redirect allowlisting. |
| `createTokenPurchaseSession` | Starts token purchase checkout | Requires idempotency and redirect allowlisting. |
| `getR2UploadUrl` | Issues a signed upload URL | Requires strict object policy, rate limiting, App Check, and content constraints. |
| `clearAllData` | Destructive administrative mutation | Existing runtime kill switch and admin claim are good controls, but the operation needs an explicit destructive-operation contract and audit record. |
| `createReferralCode`, `redeemReferralCode`, `getReferralStats` | Referral lifecycle | Needs a documented command schema and duplicate redemption behavior. |
| Training data callables | Consent, review, labels, manifests | High privacy and governance risk. Need a versioned contract and explicit actor scope. |
| `migrateLegacyUserData` | Data migration | Needs resumability, migration status, and retry semantics documented as part of the API. |

### HTTP surface

HTTP functions use the shared envelope in `functions/src/helpers.ts` only when the handler explicitly calls the helpers.

| Function | Expected exposure | Audit result |
|---|---|---|
| `generateDisposal` | Authenticated client operation | Best-aligned HTTP endpoint. It has method checking, optional App Check enforcement, bearer verification, request validation, rate limiting, cache behavior, and shared envelopes. |
| `healthCheck` | Public operational probe | Reasonable public shape, but method semantics and cache policy should be explicit. |
| `testOpenAI` | Admin diagnostic | Has a feature flag and admin token check. Keep outside the public application API inventory. |
| `getClassifyReservationDashboard` | Admin diagnostic | Has feature flag and admin verification. Keep outside the public application API inventory. |
| `getBatchStats` | Operational read | Current handler checks `GET` but does not show an authentication or admin guard before reading aggregate job counts. This is a likely information disclosure and should be closed before exposure. |
| `aggregateCommunityStatsHttp` | Internal write trigger | The source comments say authentication is optional and rely on deployment policy. This is not a sufficient application-layer contract for a state-mutating HTTP endpoint. |
| `dodopaymentsWebhook` | Provider callback | Signature verification and duplicate handling exist, but duplicate detection is check-then-set rather than an atomic claim. See finding F-04. |

### Direct Firestore and Storage surface

The Flutter client directly reads and writes many collections. This is an API surface even though it is not an HTTP route. The rules are therefore part of the public contract between app versions, and collection names, field names, ownership rules, and mutation semantics must be versioned and tested like endpoints.

The current source of truth is split between `lib/services/firestore_schema_registry.dart`, model serializers, service constants, `firestore.rules`, `storage.rules`, and documentation. The registry is a useful direction, but the audit found no single generated contract artifact that connects schema, authorization, client operation, and migration status.

## Findings

### F-01, P0: No authoritative API catalog or transport boundary

The existing `docs/reference/api_documentation/api_specification.md` leads with `UnifiedApiClient`, OpenAI, Gemini, and Firebase HTTP abstractions. The live user-facing backend contract is primarily callable Firebase functions and direct Firestore access. The document also says all HTTP endpoints should use the shared envelope, while callable functions correctly use Firebase `HttpsError` and are not represented by that envelope.

Impact:

- Client and backend engineers cannot identify the canonical contract for an operation.
- New work can accidentally create another route or another response shape.
- Versioning, deprecation, ownership, and security review are applied inconsistently.

First-principles resolution:

- Create one authoritative API catalog organized by domain operation and transport.
- For every operation record the callable name or HTTP function, region, auth mode, App Check mode, request schema, success schema, error map, idempotency rule, rate limit, data mutations, audit event, and client owner.
- Keep the existing API specification as supporting client-library documentation, not as the application API source of truth.
- Generate or validate schemas from the same typed definitions where practical. Do not create parallel route files or parallel contract registries.

### F-02, P0: Schema validation is inconsistent and mostly manual

Many callable handlers rely on TypeScript interfaces plus ad hoc checks. For example, `createBatchAiJob` converts `data.imageUrl` with `String(...)`, and the payment/session handlers accept `product_id`, `pack_id`, and `return_url` without a shared runtime schema. TypeScript types do not validate untrusted runtime payloads.

Impact:

- Invalid, oversized, or unexpected fields can reach side-effecting code.
- Error codes and field-level details vary by function.
- Contract drift is detected late, often only through runtime failures.

First-principles resolution:

- Define runtime schemas at every external boundary, including callable data, HTTP JSON, webhook payloads, and Firestore writes where the server owns the mutation.
- Reject malformed JSON and semantically invalid input with stable field-level error codes.
- Use one shared validation and error mapping layer. Do not hand-roll a second validation stack per function.
- Add contract tests for valid, invalid, boundary, unknown-field, and malicious inputs.

### F-03, P0: Payment session commands lack explicit idempotency and redirect policy

`functions/src/create_checkout_session.ts` and `functions/src/create_token_purchase.ts` create external checkout sessions from callable requests. Both accept caller-controlled `return_url`. Neither exposes a request idempotency key or records a durable create-attempt key before calling the provider.

Impact:

- Client retries can create multiple checkout sessions.
- A caller may supply an unintended redirect destination if the payment provider accepts it.
- Support and reconciliation cannot reliably connect repeated requests to one intent.

First-principles resolution:

- Require a client-generated idempotency key scoped to the authenticated user and operation.
- Persist an intent record atomically before the provider call, then persist provider outcome and replay the same result for the same key.
- Replace arbitrary return URLs with server-owned named destinations or a strict allowlist of exact origins and paths.
- Define timeout, provider failure, replay, and partially-created-session behavior.
- Add payment-focused integration tests. This is a high-risk path and unit tests alone are insufficient.

### F-04, P0: Webhook idempotency is not atomic

`functions/src/dodopayments_webhook.ts:319-331` reads `webhook_events/{webhookId}`, returns duplicate if present, then writes the event marker. Two concurrent deliveries can both observe absence and both apply the event before either marker is written.

Impact:

- Premium access or token credits can be applied twice.
- The existing comment claims idempotency stronger than the implementation proves.

First-principles resolution:

- Atomically claim the event using a Firestore transaction or create-only write that fails on an existing document.
- Store processing state, event type, provider timestamp, attempt count, applied mutation references, and final outcome.
- Make downstream entitlement and token mutations idempotent by provider event or transaction reference.
- Return a provider-appropriate success response for already-completed events and a retryable failure for incomplete processing.
- Test concurrent duplicate delivery, provider retry after timeout, malformed event, and partial mutation failure.

### F-05, P1: Internal HTTP mutators rely on deployment policy instead of an application guard

`functions/src/community_stats_aggregator.ts:226-238` exposes `aggregateCommunityStatsHttp` as a POST mutator while its source explicitly leaves authentication optional and relies on a Cloud Function access policy. This is weaker than the admin verification used by diagnostics.

Impact:

- A deployment configuration mistake can turn an expensive write operation into a public trigger.
- The API contract is not self-contained or auditable from the function code.

Resolution:

- Make the intended caller explicit: authenticated admin, service account/IAM, or remove the HTTP trigger and keep the scheduled function as the only canonical trigger.
- Add method, identity, App Check or IAM, rate, replay, and operator-audit checks at the chosen boundary.
- Prefer one canonical trigger. Do not retain an HTTP backdoor if the scheduled function is sufficient.

### F-06, P1: `getBatchStats` lacks a documented authorization contract

`functions/src/index.ts:1191-1232` checks only the HTTP method before reading aggregate job counts. It uses the shared envelope but does not show an auth, App Check, or admin check.

Impact:

- Operational workload and failure counts may be disclosed publicly.
- The endpoint can become an unbounded read cost if exposed without rate limiting.

Resolution:

- Decide whether this is an admin diagnostic or a user-scoped resource.
- If admin-only, use the same feature flag and admin token verification as the other diagnostics.
- If user-facing, return only the caller's authorized job summary and enforce ownership.
- Add rate limiting and tests for unauthenticated, non-admin, admin, and cross-user access.

### F-07, P1: Signed upload URL contract is under-constrained

`functions/src/r2_storage.ts:41-87` authenticates the caller but does not visibly enforce App Check, rate limiting, file size, allowed content types, folder values, or a server-owned purpose. `folder` is inserted into the object key after only filename sanitization. The response also returns a `public_url`, which may imply public object availability even when the upload is intended to be private.

Impact:

- Authenticated users can consume signing capacity and storage with unintended content.
- Object namespace and retention policy become caller-influenced.
- A public URL can weaken privacy expectations for user images.

Resolution:

- Replace arbitrary `folder` with an enum of server-owned upload purposes.
- Enforce MIME allowlist, byte limit, extension/content consistency, expiration, and per-user quotas.
- Require App Check where the client is a trusted app surface and rate limit the command.
- Return a private object reference, not a public URL, unless public access is an explicit product decision.
- Add completion/finalization or cleanup semantics so abandoned signed uploads are observable and recoverable.

### F-08, P1: Callable and HTTP error contracts are intentionally different but undocumented as such

HTTP helpers return `success`, `data` or `error`, `request_id`, `version`, and `timestamp`. Callable handlers throw `HttpsError`, with Firebase error codes such as `unauthenticated`, `invalid-argument`, `failed-precondition`, and `resource-exhausted`. Both are reasonable transport-native choices, but the current documentation presents the HTTP envelope as the general API pattern and does not give clients a canonical cross-transport error map.

Resolution:

- Document transport-native wire formats explicitly.
- Define a shared domain error taxonomy and map it to HTTP status plus callable `HttpsError` code.
- Preserve a correlation identifier in both transports where possible.
- Do not force callable responses into an HTTP envelope if that reduces Firebase client ergonomics. Consistency should be semantic, not cosmetic.

### F-09, P1: Versioning is metadata-only for HTTP and absent for callable/data contracts

`functions/src/helpers.ts` emits `x-api-version` and a body `version`, defaulting to `v1`. This is useful metadata, but it does not select a versioned route or schema. Callable names and Firestore collections are not versioned in the same contract.

Resolution:

- Define what `v1` means: schema version, behavior version, or deployment generation.
- Version breaking callable and Firestore contracts deliberately, preferably through additive fields and compatibility windows before a new callable name or collection is needed.
- Add a deprecation and sunset record for every breaking change.
- Treat Firestore rules and model serializers as versioned compatibility code, not only database configuration.

### F-10, P1: Observability is strong in parts, but not contract-wide

The shared HTTP helper emits request IDs and rate-limit metadata. Token spending and classification also emit operational metrics. However, the API catalog does not define a common operation ID, actor, idempotency key, outcome, retry count, provider, or state transition for every command. HTTP handlers also sometimes include raw caught error messages in response details, for example the community aggregation handler.

Impact:

- Operators cannot consistently explain a failed or duplicated operation.
- Internal details can leak through error responses.

Resolution:

- Define a structured operation event contract for every externally triggered mutation.
- Redact provider, database, and stack details from customer responses. Keep them in protected logs with request correlation.
- Record success, validation failure, authorization failure, retry, fallback, duplicate, partial completion, and operator action required.

### F-11, P1: Direct Firestore writes create a broad client API with uneven authority boundaries

`firestore.rules` protects many owner and membership boundaries, but several user-facing collections are directly writable by clients, including parts of classifications, leaderboard entries, community content, families, feedback, and contributions. This can be valid for offline-first collaboration, but the API contract must state which fields are client-authored, which are server-derived, and how replay or tampering is handled.

Resolution:

- For each collection, define an explicit command/data contract table: readable fields, client-writable fields, server-derived fields, ownership predicate, allowed state transitions, and audit requirement.
- Move money, points, entitlement, ranking, moderation, and other authoritative mutations behind callable/server transactions where client writes cannot be safely constrained.
- Add emulator tests for every state transition and malicious field injection.

### F-12, P2: Naming is command-oriented for callable functions but not represented as domain resources

Names such as `createBatchAiJob`, `createCheckoutSession`, and `getR2UploadUrl` are understandable commands. The API is not required to become REST, but asynchronous resources should have documented lifecycle nouns and states. For example, a batch job should define `queued`, `processing`, `completed`, and `failed` as a stable state machine, including retry and cancellation semantics.

Resolution:

- Keep verbs for true commands.
- Document the resource created by each command, its owner, lifecycle, terminal states, and read path.
- Prefer a single canonical read model for job status instead of multiple ad hoc stats and status reads.

## Recommended target contract

The long-term API model should be:

```text
Flutter client
  -> Callable command contract       side effects and domain commands
  -> HTTP endpoint contract          public HTTP operations and webhooks
  -> Firestore/Storage data contract authorized reads and narrowly-scoped writes

All three
  -> shared domain schemas
  -> shared error taxonomy
  -> shared identity and ownership rules
  -> idempotency and retry policy
  -> request correlation and audit events
  -> one API catalog
```

The target is not to add a second REST layer. Adding REST routes beside callable functions would create the duplicate API problem prohibited by the repository rules. The target is to make the existing canonical surfaces coherent and explicit.

## Decision record

Decision: treat the Firebase callable, HTTP, Firestore, and Storage surfaces as one application API with transport-specific wire contracts.

Context: the app is Firebase-native and most operations do not use the generic `UnifiedApiClient` path described in the existing specification.

Options considered:

1. Convert all operations to REST. Rejected because it adds a second transport and migration surface without improving the Firebase-native client path.
2. Keep each surface undocumented and rely on source discovery. Rejected because it creates drift, inconsistent security review, and repeated contract rediscovery.
3. Document and govern the existing surfaces through one operation catalog, shared domain taxonomy, runtime schemas, and transport adapters. Chosen because it preserves the current platform while creating a durable contract boundary.

Tradeoffs: this requires broader contract documentation and schema work than a route-by-route cleanup. It avoids a costly parallel API and provides a path for future external integrations without weakening the native app contract.

Revisit when: a supported external client, partner integration, or independently deployed frontend requires a stable public HTTP API. At that point, expose only operations already represented in the catalog and preserve one domain implementation beneath the new adapter.

## Ordered closure plan

The closure should be executed as gated commits in this dependency order:

1. API catalog and operation ownership. Inventory every callable, HTTP function, Firestore collection, and Storage path. Mark public, authenticated, admin, internal, webhook, scheduled, and deprecated surfaces.
2. Shared runtime schemas and domain error taxonomy. Add contract tests before changing behavior.
3. High-risk mutation hardening. Close payment idempotency, webhook atomicity, token/points authority, and destructive operation auditability.
4. HTTP and Storage boundary hardening. Close `getBatchStats`, internal aggregation auth, signed-upload policy, and error-detail leakage.
5. Firestore and Storage contract tests. Use emulator tests for ownership, field allowlists, state transitions, legacy documents, and malicious writes.
6. Client contract migration and documentation sync. Update the Flutter adapters and API catalog from the verified live contract. Do not add duplicate routes.

## Acceptance contract for this audit

- User-facing behavior changed: none. This artifact records the current contract and closure path.
- Business/team value: a single inventory and priority order for reducing duplicate API work, payment risk, and integration ambiguity.
- Internal/operational value: explicit separation of callable, HTTP, Firestore, and Storage evidence, with test boundaries and unresolved risks named.
- Files added: `docs/review/API_DESIGN_AUDIT_2026-08-01.md`.
- Checks run: Functions build, HTTP response contract tests, and HTTP guard tests. All passed as listed above.
- Directly verified: current source structure, shared HTTP envelope behavior, selected HTTP auth guards, and TypeScript compilation.
- Inferred or unverified: deployed IAM and App Check configuration, full callable integration, payment-provider behavior, concurrent webhook delivery, Firestore emulator coverage for every collection, and Storage object privacy.
- Known gaps: F-01 through F-12 remain findings. The highest-risk closure items are F-03 and F-04, followed by F-02, F-05, F-06, and F-07.
- Hardening path: execute the ordered closure plan with Tier 3 integration tests for high-risk mutations before production claims.
- Documentation updated: this audit artifact only. The existing API specification still needs a follow-up reconciliation against this catalog decision.
- Git state: pre-existing local changes and untracked artifacts were preserved untouched. No staging, commit, reset, checkout, or other git mutation was performed.
- User decision needed: approve the target contract and priority order before implementation commits change high-risk payment, webhook, Storage, or Firestore behavior.

## Anything else?

Yes. The audit also surfaces a naming and product-boundary issue: AI classification, tokens, payments, training data, community analytics, and user uploads are not equal-risk APIs. They should not inherit one generic retry, caching, or rate-limit policy. The operation catalog must classify each by data sensitivity, side-effect level, user visibility, and recovery requirement. That classification is necessary to prevent a generic client abstraction from silently applying the wrong semantics to money, privacy, or model-backed operations.

