# Next Features Pickup Note

Date: 2026-05-23
Scope: Post-flywheel-foundation priorities (deferred)

## Proposed next features
1. Lightweight admin review UI
- Queue view + candidate detail + reviewer ground-truth actions
- Not a full dashboard initially

2. Reviewer truth quality gates
- Require essential `groundTruth` fields for `golden` / `training_eligible`
- Add conflict checks against model/user label paths

3. Router decision loop
- Convert eval/router outputs into explicit runtime threshold config
- Apply deterministic routing policy from those thresholds

4. Dataset governance hardening
- Maintain immutable lineage: model version <-> dataset version <-> eval version <-> rules version
- Release metadata integrity checks

5. Live-eval safety lane
- Small controlled live-eval sample path
- Env gating, spend caps, and rollback defaults to recorded/offline

## Note
Deferred intentionally to keep current effort focused on making flywheel foundation genuinely green.
