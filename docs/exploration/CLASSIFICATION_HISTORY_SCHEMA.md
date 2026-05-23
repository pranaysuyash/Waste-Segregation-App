# Classification History Schema

**Date**: 2026-05-23
**Status**: Exploration — schema design for scale
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) entry 12
**Decision this unblocks**: Growth-proof schema before migrations become expensive
**Kill criteria**: If classification history is never used beyond display, a simple flat schema suffices

---

## 1. Current Schema

Classification documents stored in `users/{userId}/classifications/{classificationId}`.

### Core fields (from `waste_classification.dart`)

```
itemName: String
category: String
subcategory: String?
confidence: Double?
isRecyclable: Bool
disposalInstructions: String
 recyclingBin, compostBin, specialHandling, tips, warnings
imageUrl: String
timestamp: DateTime
userId: String
region: String?
```

### AI pipeline metadata

```
classificationLayer: String?  // 'layer0', 'layer1', 'layer2', 'layer3'
provider: String?             // 'openai', 'gemini', 'local', 'cache'
model: String?                // 'gpt-4.1-nano', etc.
isOfflineHint: Bool           // G6 offline degradation flag
```

### User interaction metadata

```
userCorrection: String?       // User's corrected category
correctionTimestamp: DateTime?
feedbackNotes: String?
```

### Local policy metadata

```
localPolicyApplied: Bool
policyRuleId: String?
policyConfidence: Double?
```

---

## 2. Schema Gaps

### No versioning

Schema has no version field. If fields are added/renamed/removed, old documents silently break.

**Fix**: Add `schemaVersion: int` field. Migration logic handles old versions.

### No deduplication

Same image classified twice creates two separate documents. No content hash to detect duplicates.

**Fix**: Add `imageContentHash: String` field. Before creating, check for existing classification with same hash.

### No aggregation support

To show "how many plastic items have I classified this month?", every document must be read client-side.

**Fix**: Maintain server-side aggregation counters (per category per month). Update atomically with `FieldValue.increment`.

### No export format

No structured export format for user data portability (GDPR) or dataset creation.

**Fix**: Export service produces JSONL with all fields + schema version.

---

## 3. Recommended Schema

```dart
{
  // Identity
  'id': String,
  'userId': String,
  'schemaVersion': 2,

  // Classification
  'itemName': String,
  'category': String,           // Wet Waste, Dry Waste, Hazardous, Medical, Non-Waste
  'subcategory': String?,
  'confidence': double?,
  'isRecyclable': bool,
  'imageContentHash': String?,  // SHA-256 of image bytes

  // Disposal
  'disposalInstructions': {
    'primaryMethod': String,
    'recyclingBin': String?,
    'compostBin': String?,
    'specialHandling': String?,
    'tips': List<String>,
    'warnings': List<String>,
  },

  // AI pipeline
  'classificationLayer': String?,  // layer0, layer1, layer2, layer3
  'provider': String?,             // openai, gemini, local, cache
  'model': String?,
  'isOfflineHint': bool,
  'processingTimeMs': int?,

  // User interaction
  'userCorrection': String?,
  'correctionTimestamp': DateTime?,
  'feedbackNotes': String?,

  // Local policy
  'localPolicyApplied': bool,
  'policyRuleId': String?,
  'policyConfidence': double?,
  'region': String?,
  'city': String?,

  // Timestamps
  'createdAt': DateTime,
  'updatedAt': DateTime?,
  'archivedAt': DateTime?,
}
```

---

## 4. Query Patterns and Indexes

| Query | Fields | Index Required |
|-------|--------|---------------|
| History by date | `userId` + `createdAt DESC` | Composite |
| History by category | `userId` + `category` | Composite |
| Monthly aggregation | `userId` + `createdAt` range | Composite |
| Duplicate check | `userId` + `imageContentHash` | Composite |
| Offline hints | `userId` + `isOfflineHint == true` | Composite |
| Unclassified items | `userId` + `category == null` | Composite |

---

## 5. Related

- [Firestore Cost & Indexing](FIRESTORE_COST_AND_INDEXING.md) — cost implications
- [Offline Queue & Sync](OFFLINE_QUEUE_AND_SYNC.md) — offline history handling
- `lib/models/waste_classification.dart` — current model
- `lib/services/firestore_schema_registry.dart` — schema definitions
