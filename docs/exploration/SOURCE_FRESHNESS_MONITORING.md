# Source Freshness Monitoring — Design Concept

**Decision this unblocks**: Whether to build automated municipal-policy diff monitoring or rely on manual re-check cycles.

**Status**: Design Concept (2026-05-22)
**Related**: REGION_RULES_AND_CITY_EXPANSION_MAP.md §14, GLOBAL_MUNICIPAL_POLICY_ENGINE.md

---

## Problem

Every city plugin carries a `nextReviewDue` date. When that date passes, rules are demoted to `draft` automatically. But who updates them? Without a monitoring system, every city goes stale.

## Approaches (ranked by feasibility)

### Approach A: Manual re-check with calendar (simplest, recommended for ≤15 cities)

- Each `pilot`/`production` city has a recurring calendar reminder at its `nextReviewDue` date.
- Assignee re-visits source URL, checks whether rules have changed.
- If unchanged: bump `nextReviewDue` by 12 months, update `lastVerified`.
- If changed: research new rules, create PR with updated plugin.
- **Cost**: ~2 hours per city per year.
- **Risk**: Human forgetfulness; no automation fallback.

### Approach B: Source URL change detection (medium effort)

- Run a weekly GitHub Action / Cron Job that HTTP-heads each city's source URL.
- Compare ETag, Last-Modified, or content hash.
- If changed: file an issue in the repo with the city name and source URL.
- **Cost**: ~1 day to set up. Ongoing: serverless function cost (<$1/month).
- **Risk**: False positives (site layout change ≠ rule change). Hard to detect PDF-only rule publications.

### Approach C: RSS / social monitoring (low effort, noisy)

- Follow city corporation Twitter accounts, RSS feeds for SWM departments.
- Use keyword filters ("waste", "segregation", "composting", "penalty").
- **Cost**: ~30 min setup per city. Ongoing: moderate noise.
- **Risk**: Missing gazette-only announcements.

## Recommended strategy

**2026 Q3–Q4 (≤7 cities)**: Approach A + a script that logs stale warnings from `PolicySource.nextReviewDue` into a weekly Slack/email report.

**2027 (15+ cities)**: Approach B as a GitHub Action. City-ops team reviews flagged issues monthly.

## Implementation sketch

```yaml
# .github/workflows/policy-source-check.yml (future)
on:
  schedule:
    - cron: '0 9 * * 1'  # Monday 9 AM UTC

jobs:
  check-sources:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check policy source freshness
        run: |
          # Script reads docs/playbooks/CITY_RULES_RESEARCH.md
          # Extracts source URLs, HEAD requests each
          # Files issue if ETag/LM changed
          dart run tools/check_policy_sources.dart
```

## Data model

```dart
// Already in PolicySource
class PolicySource {
  final String url;
  final DateTime lastVerified;
  final DateTime nextReviewDue;
  final String? lastEtag;
  final String? lastContentHash;  // SHA-256 of fetched content
}
```

The `lastEtag` / `lastContentHash` fields enable Approach B. They should be persisted alongside the city plugin data (in a separate JSON map or Firestore collection), not hardcoded in the plugin class.
