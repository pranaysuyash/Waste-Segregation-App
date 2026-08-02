> **Review baseline:** `pranaysuyash/Waste-Segregation-App`, branch `main`, commit `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Remote commit date:** 2026-05-25
>
> **Review date:** 2026-08-02
>
> **Hard limitation:** This review does not include local, uncommitted, or unpushed work. Run `02_TASK_LOCAL_CHANGE_RECONCILIATION.md` before implementing any other task. Existing local work is authoritative where it is newer and intentional.

# Decision Log and Kill List

## Purpose

Prevent the project from returning to feature accumulation before the core is trusted and sold.

## Decisions to make and record

Use this format:

```markdown
## ADR/Decision ID

Date:
Owner:
Status: proposed | accepted | superseded
Decision:
Options considered:
Evidence:
Trade-offs:
Consequences:
Review trigger:
```

## Required decisions

### DEC-01: primary product

Recommended: BWG segregation-assurance and evidence product, with consumer scanner as a component.

### DEC-02: initial buyer

Recommended test order: authorised processor, apartment complex, facility-management company.

### DEC-03: initial jurisdiction

Recommended: Bengaluru only until SWM 2026 policy and workflow are verified.

### DEC-04: canonical AI path

One backend classification gateway. Direct client provider calls restricted to explicit developer/test mode.

### DEC-05: canonical entitlement

Server ledger/projection. Local state is cache only.

### DEC-06: billing rails

Decide per platform and region. Do not expose unsupported external checkout.

### DEC-07: state management

Choose a migration direction and forbid new code in the losing pattern.

### DEC-08: object storage

Assign object classes to one storage system each. No generic dual-write.

### DEC-09: brand

Complete collision/trademark screen before brand investment.

### DEC-10: consumer monetisation

Keep off the critical path until repeated willingness-to-pay is demonstrated.

## Kill/freeze list

The following are frozen unless a decision record documents new buyer evidence:

- blockchain;
- broad marketplace;
- new social/community mechanics;
- more gamification currencies;
- new AI providers;
- on-device production inference;
- smart-bin hardware;
- new municipality rule packs;
- public API;
- advanced carbon accounting;
- broad EPR platform;
- processor logistics;
- new premium tiers;
- generic referral growth;
- complex family features;
- multiple payment providers for the same platform.

## Feature admission rule

A new feature enters the active roadmap only if it has:

1. named buyer/user;
2. repeated job;
3. evidence of current pain;
4. metric it should move;
5. smallest test;
6. dependency and operational cost;
7. security/privacy review;
8. explicit feature to remove or deprioritise if capacity is fixed.

## Claim admission rule

Do not publish or display a claim unless evidence exists.

Examples:

- “offline” requires real inference without network;
- “compliant” requires verified rules and reviewed workflow;
- “secure” requires threat model and tests;
- “AI accuracy” requires a disclosed evaluated dataset;
- “carbon saved” requires a documented methodology;
- “production-ready” requires release evidence;
- “premium active” requires server-authoritative entitlement.

## Review trigger

Revisit the kill list only after:

- P0 gates pass;
- one paid design partner uses the product;
- four weeks of site usage exists;
- the buyer identifies the next bottleneck;
- unit economics are measured.
