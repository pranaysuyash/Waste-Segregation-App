> **Review baseline:** `pranaysuyash/Waste-Segregation-App`, branch `main`, commit `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Remote commit date:** 2026-05-25
>
> **Review date:** 2026-08-02
>
> **Hard limitation:** This review does not include local, uncommitted, or unpushed work. Run `02_TASK_LOCAL_CHANGE_RECONCILIATION.md` before implementing any other task. Existing local work is authoritative where it is newer and intentional.

# Waste Segregation App: Agent Execution Bundle

This bundle converts the remote-code review into agent-executable work.

## Bottom line

The repository is not missing another large feature set. It is missing convergence.

The codebase already contains substantial product breadth: image classification, local policy rules, gamification, community, family features, analytics, Firebase, subscriptions, token wallets, referrals, DodoPayments, R2 storage, and an evaluation harness. That breadth is now the liability. Several critical systems have multiple competing implementations, several paid features are not truly implemented, and some trust boundaries are enforced by client-controlled state.

**Current saleability judgment:** not ready to charge users or sell to organisations without first completing the P0 trust and release tasks.

**Best commercial direction:** use the consumer scanner as one component of a Bengaluru-focused Bulk Waste Generator compliance and behaviour-assurance product. The sellable unit is not “AI tells you which bin.” It is “prove and improve correct four-stream segregation, train residents or staff, retain evidence, and produce compliance-ready records.”

## Recommended execution order

1. `02_TASK_LOCAL_CHANGE_RECONCILIATION.md`
2. P0 tasks in parallel, with strict file ownership:
   - `03_TASK_SECURITY_AUTHZ_FIRESTORE.md`
   - `04_TASK_PAYMENTS_ENTITLEMENTS_STORE_COMPLIANCE.md`
   - `10_TASK_QA_CI_RELEASE.md`
   - `11_TASK_PRIVACY_DATA_GOVERNANCE.md`
3. `06_TASK_ARCHITECTURE_CANONICALIZATION.md`
4. `05_TASK_AI_POLICY_TAXONOMY_EVAL.md`
5. Product and commercial work:
   - `07_TASK_PRODUCT_WEDGE_AND_UX.md`
   - `08_TASK_BWG_COMPLIANCE_PRODUCT.md`
   - `09_TASK_ANALYTICS_EXPERIMENTATION.md`
   - `13_TASK_GTM_SALES_MARKET_VALIDATION.md`
6. Repository convergence:
   - `12_TASK_DOCS_REPO_HYGIENE_AGENT_ONBOARDING.md`
7. Use `14_PARALLEL_AGENT_ORCHESTRATION.md` to assign ownership and merge order.
8. Use `15_DECISION_LOG_AND_KILL_LIST.md` to prevent scope re-expansion.

## Files in this bundle

| File | Purpose |
|---|---|
| `00_REMOTE_BASELINE_REVIEW.md` | Full review across code, security, AI, product, market, sales and operations |
| `01_MASTER_EXECUTION_PLAN.md` | Prioritised backlog, gates and sequencing |
| `02_TASK_LOCAL_CHANGE_RECONCILIATION.md` | Protect and reconcile unpushed changes |
| `03_TASK_SECURITY_AUTHZ_FIRESTORE.md` | Repair trust boundaries and Firestore access control |
| `04_TASK_PAYMENTS_ENTITLEMENTS_STORE_COMPLIANCE.md` | Build server-authoritative, store-compliant monetisation |
| `05_TASK_AI_POLICY_TAXONOMY_EVAL.md` | Align classification with SWM Rules 2026 and real evidence |
| `06_TASK_ARCHITECTURE_CANONICALIZATION.md` | Remove competing implementations and simplify the core |
| `07_TASK_PRODUCT_WEDGE_AND_UX.md` | Rebuild the product around the job users pay to solve |
| `08_TASK_BWG_COMPLIANCE_PRODUCT.md` | Define and build the B2B compliance MVP |
| `09_TASK_ANALYTICS_EXPERIMENTATION.md` | Instrument activation, quality, retention and revenue |
| `10_TASK_QA_CI_RELEASE.md` | Create a reproducible release gate |
| `11_TASK_PRIVACY_DATA_GOVERNANCE.md` | DPDP-aligned consent, retention, deletion and training data |
| `12_TASK_DOCS_REPO_HYGIENE_AGENT_ONBOARDING.md` | Establish one source of truth and repair agent onboarding |
| `13_TASK_GTM_SALES_MARKET_VALIDATION.md` | Validate buyer, price, positioning and channel |
| `14_PARALLEL_AGENT_ORCHESTRATION.md` | File ownership, dependencies and merge protocol |
| `15_DECISION_LOG_AND_KILL_LIST.md` | Decisions, freezes and explicit non-goals |

## Agent operating rules

- Read `motto_v2.md` before changing code.
- Do not assume the remote repository is newer than the local workspace.
- Never overwrite or discard unpushed work.
- One task, one branch, one accountable owner.
- Do not mark a task complete from code inspection alone. Run its verification commands.
- Do not add a new service while an overlapping service exists unless the task explicitly authorises a migration adapter.
- Do not claim “production-ready,” “compliant,” “offline,” “premium,” or “verified” without evidence defined in the relevant acceptance criteria.
- Security, billing, privacy and release failures are blockers, not backlog polish.
