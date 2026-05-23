# Firestore Cost & Indexing

**Date**: 2026-05-23
**Status**: Exploration — cost analysis and schema optimization
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) entry 13
**Decision this unblocks**: Scale to 100K+ MAU without Firestore cost surprises
**Kill criteria**: If Firestore costs are < $10/month at target MAU, optimization is premature

---

## 1. Current Schema

19+ collections defined in `firestore_schema_registry.dart`. Key high-traffic collections:

| Collection | Write Pattern | Read Pattern | Estimated Docs/MAU/Month |
|------------|--------------|--------------|--------------------------|
| `users/{userId}` | Profile updates | Every app open | 30 |
| `users/{userId}/classifications` | Every classification | History browsing | 60–200 |
| `leaderboard_allTime` | Point updates | Every home screen | 1 per user |
| `community_feed` | Sharing events | Feed scroll | 5–20 |
| `disposal_instructions` | Cache writes | Every classification | 60–200 |
| `rate_limits/{userId}` | Every API call | Every API call | 60–200 |
| `training_candidates` | Classification events | Admin review | 60–200 (if consented) |
| `analytics_events` | Every tracked event | Dashboard only | 100–500 |
| `ai_jobs` | Batch processing | Job status polls | 10–60 |

### Firestore pricing (free tier + paid)

| Operation | Free Tier | Paid (per 100K) |
|-----------|-----------|-----------------|
| Document reads | 50K/day | $0.036 |
| Document writes | 20K/day | $0.108 |
| Document deletes | 20K/day | $0.012 |
| Storage | 1 GB | $0.108/GB |
| Network egress | 10 GB/month | $0.12/GB |

---

## 2. Per-MAU Cost Estimate

### Conservative (60 classifications/month)

| Operation | Count/MAU/Month | Cost/MAU |
|-----------|-----------------|----------|
| Reads | ~600 | $0.000216 |
| Writes | ~300 | $0.000324 |
| Deletes | ~50 | $0.000006 |
| Storage | ~0.5 MB | $0.000054 |
| **Total** | | **$0.000600** |

### At scale

| MAU | Monthly Cost |
|-----|-------------|
| 1K | $0.60 |
| 10K | $6.00 |
| 100K | $60.00 |
| 1M | $600.00 |

This is very affordable. The real cost risk is **spikes** (viral moment, bot attack) and **inefficient queries** that multiply reads.

---

## 3. Optimization Opportunities

### Batch writes

Already implemented via `FirestoreBatchManager`. Reduces write costs by ~40%.

### Read caching

- `disposal_instructions` is already cached in Firestore with material ID as key
- Cache hit rate: ~60% for common items
- Recommendation: Increase cache duration, add client-side LRU cache

### Index optimization

- Current indexes: defined per-collection in `firestore_schema_registry.dart`
- Risk: compound queries without indexes cause full collection scans
- Recommendation: Audit all `where()` + `orderBy()` combinations, add composite indexes

### Archival strategy

- Classifications older than 12 months: move to cold storage or aggregate
- Analytics events older than 14 months: delete
- Community feed: TTL of 90 days

---

## 4. Recommendations

1. **Add Firestore spend alerts** — Firebase console budget alerts at $10, $50, $100 thresholds
2. **Audit compound queries** — ensure all query patterns have corresponding indexes
3. **Implement client-side caching** — LRU cache for disposal instructions and user profile
4. **Monitor per-collection growth** — `analytics_events` and `rate_limits` are highest risk
5. **Archive old classifications** — reduce active collection size for faster queries

---

## 5. Related

- [Data Retention & PII Strategy](DATA_RETENTION_AND_PII_STRATEGY.md) — retention policies
- [AI Cost Telemetry](AI_COST_TELEMETRY_AND_GUARDRAILS.md) — AI-specific costs
- `lib/services/firestore_schema_registry.dart` — schema definitions
- `lib/services/cloud_storage_service.dart` — Firestore operations
