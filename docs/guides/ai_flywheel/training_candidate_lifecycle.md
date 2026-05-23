# Training Candidate Lifecycle

1. Classification completes
2. Consent gate checks (`enabled`, policy version)
3. Candidate metadata + prediction captured
4. User correction attached separately
5. Reviewer provides verified truth
6. Privacy/redaction state gate
7. Dataset eligibility decision
8. Export with exclusion controls

Key rule:
- No consent => no candidate
- No verified truth => cannot become golden/training_eligible
- privacy failed/needs redaction/revoked/deleted/unreviewed => excluded
- Stale policy version => excluded unless explicit export override
- `reviewerVerified.reviewedAt` required for export inclusion
- Lifecycle output state is explicit: `trainingEligible`, `golden`, `excluded`
