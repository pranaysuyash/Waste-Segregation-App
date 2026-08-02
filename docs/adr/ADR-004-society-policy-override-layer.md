# ADR-004: Society Policy Override Layer

* Status: accepted
* Deciders: Development Team
* Date: 2026-05-22

Technical Story: Apartment societies (RWAs) need to override city-level waste policy rules for their specific buildings. How should we model and enforce society-specific policy deltas without breaking city-level compliance?

## Context and Problem Statement

*Depends on: ADR-005 (Multi-Layer Classification Pipeline) — society overrides are applied after classification, during policy evaluation.*

India's waste segregation rules vary by city (BBMP, BMC, MCD, etc.), but individual apartment complexes often have their own rules that differ from municipal policy. For example:

- BBMP requires wet waste separation at source, but a society might require pre-chopping of food waste
- BMC mandates specific bin colors, but a society might use different bins for internal collection
- A society might ban certain items that are technically allowed by city policy

The challenge: society overrides must be additive (they add/change rules, never remove city-level rules), they must be scoped to a specific city plugin, and conflicts between city and society rules must be detected and surfaced.

## Decision Drivers

* **Additivity**: Society overrides add or change rules — they never remove city-level safety rules
* **Scoping**: Each society override is anchored to a specific city plugin via `basePluginId`
* **Conflict detection**: Mismatches between society and city rules must be recorded and surfaced
* **Confidence gating**: Low-confidence classifications should not trigger society-level enforcement
* **Auditability**: Every override application must be traceable for governance

## Considered Options

* **Option 1**: Flat override map (society rules completely replace city rules)
* **Option 2**: Layered override model (society rules are additive deltas on city rules)
* **Option 3**: Separate policy engine per society (independent rule evaluation)

## Decision Outcome

Chosen option: **Option 2 — Layered override model with additive deltas.**

SocietyPolicyOverride objects are stored in Firestore under `society_policies/{societyId}` and contain:
- Society metadata (ID, name, base plugin ID)
- List of RuleOverride objects (category key, override type, new value)

The LocalPolicyEngine resolves the city plugin first, then applies society deltas on top. Conflicts are detected when both city and society define rules for the same category.

### Positive Consequences

* **Additive by design**: Society cannot weaken city-level safety rules
* **Conflict visibility**: Conflicts are surfaced in PolicyProvenanceCard for transparency
* **Confidence-aware**: Low-confidence classifications skip society enforcement
* **Audit trail**: Every override application is recorded on LocalPolicyDecision

### Negative Consequences

* **Complexity**: Society resolution adds a second evaluation pass to policy engine
* **Firestore dependency**: Society overrides require network for initial fetch (cached locally)
* **Conflict resolution ambiguity**: When city and society conflict, the UI shows both — no automatic resolution

## Implementation Structure

### Core Classes

```
SocietyPolicyOverride {
  societyId: String
  societyName: String
  basePluginId: String  // Must match resolved city plugin
  overrides: List<RuleOverride>
}

RuleOverride {
  categoryKey: String  // e.g., "hazardous", "wet_food"
  overrideType: RuleOverrideType
  newValue: String
  description: String?
}

enum RuleOverrideType {
  binColor,
  collectionFrequency,
  disposalMethod,
  collectionLocation,
  bannedItem,
  customInstruction,
}
```

### Resolution Flow

1. LocalPolicyEngine resolves city plugin from region string
2. If user has a society profile, fetch SocietyPolicyOverride from Firestore (cached)
3. Validate `basePluginId` matches resolved city plugin
4. If mismatch → record SocietyConflict, skip override
5. If match → apply RuleOverride objects as additive deltas
6. Record society metadata on LocalPolicyDecision for audit

### Conflict Detection

Conflicts are detected when:
1. Society's `basePluginId` doesn't match resolved city plugin
2. Both city and society define rules for the same `categoryKey`

Conflicts are surfaced in `LocalPolicyDecision.societyConflicts` and displayed in `PolicyProvenanceCard`.

## Links

* Implementation: `lib/services/society_policy_service.dart`
* Model: `lib/models/society_policy_override.dart`
* Tests: `test/services/local_policy_engine_test.dart` (society override tests)
* UI: `lib/widgets/result_screen/policy_provenance_card.dart`
* Refined by: [CONTEXT.md](../../CONTEXT.md) Society Policy Override section
