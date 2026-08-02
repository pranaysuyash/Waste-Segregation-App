> **Repository:** `pranaysuyash/Waste-Segregation-App`
>
> **Reviewed branch:** `main`
>
> **Reviewed commit:** `e48a66bd6c9116e939a3eddfa5cc48c5d2171e6a`
>
> **Commit timestamp:** 2026-08-02T03:40:33Z
>
> **Review timestamp:** 2026-08-02
>
> **Previous review baseline:** `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Evidence limit:** Static remote-code inspection plus current official/public-source research. The latest GitHub commit exposes no combined status checks or associated workflow runs, so build, test, deployment and runtime claims remain unverified until the release-proof task is executed.

# Task: Storage, R2 and Data Lifecycle

## Priority

P0 for R2 public use; P1 for storage convergence.

## Objective

Assign each object class to a controlled store and replace unconstrained signed uploads with private, verified upload intents.

## Object-class decision

Define stores for:

- transient classification image;
- local history image;
- offline queue image;
- site audit evidence;
- community-shared image;
- training candidate;
- export;
- backup.

Do not use Firebase Storage and R2 as generic interchangeable destinations.

## R2 upload protocol

### Request intent

Client sends:

- logical purpose;
- expected MIME;
- expected size;
- checksum;
- organisation/site context if applicable.

Server derives:

- owner/tenant;
- object prefix;
- retention class;
- max size;
- allowed MIME;
- quota;
- expiry.

### Upload

Signed request constrains:

- key;
- content type;
- size/checksum where supported;
- short TTL.

### Finalisation

Client calls finalise. Server checks object metadata/head:

- exists;
- size;
- MIME;
- checksum;
- owner;
- malware/PII scan state if required.

Only then create application record.

### Read

Private by default.

Use signed read URLs or authenticated delivery; do not construct a bucket hostname and call it public.

### Delete/lifecycle

- automatic expiry by retention class;
- user/account/site deletion;
- audit record;
- orphan sweep;
- legal/contract hold if applicable.

## Required controls

- Firebase Auth;
- App Check;
- per-UID/tenant/IP rate limit;
- upload count/bytes quota;
- MIME allowlist;
- filename/key sanitisation;
- no client folder;
- no SVG/HTML/executable unless explicitly handled;
- encryption;
- access log;
- environment-separated buckets.

## Cache image box

The classification cache stores compressed images.

Decide whether image bytes are necessary for cache behaviour. If not, remove them. If yes:

- cap total bytes, not only entry count;
- set TTL;
- encrypt;
- delete with cache entry;
- exclude from training;
- purge on logout/account deletion where required.

## Acceptance criteria

- every object has owner, tenant, purpose and retention;
- client cannot choose arbitrary path;
- upload bytes/type/quota are bounded;
- objects are private until authorised delivery;
- finalisation rejects mismatches;
- deletion is idempotent and auditable;
- no orphan public URLs;
- storage choice and cost model are documented.

## Anything else?

R2 cost savings are not a reason to migrate data before ownership and lifecycle are correct. Security and deletion precede optimisation.
