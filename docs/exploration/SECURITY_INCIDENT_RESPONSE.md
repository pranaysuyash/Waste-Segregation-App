# Security Incident Response & Vulnerability Management

**Decision it unblocks**: Whether the project has a documented, testable security incident response plan — or relies on ad-hoc reaction when something breaks.

**Key questions**:
- Incident classification: what qualifies as P0 (data breach, API key leak, active abuse), P1 (suspected token farming, policy violation), P2 (dependency vuln, misconfiguration)?
- Data breach response: who is notified, how, within what SLA? User notification trigger and template?
- API key / secret rotation: automated rotation cadence, manual emergency rotation procedure, how to detect a leak?
- Vulnerability disclosure: security contact email/mechanism, expected response time, disclosure timeline?
- Dependency vulnerability monitoring: Dependabot / Renovate / Snyk / pub.dev advisory — what monitors what?
- Bug bounty / researcher-friendly policy: is the project open to external security research, or invite-only?
- Penetration testing schedule: annual / quarterly / triggered by major feature release?
- Forensics and audit trail: what logs survive an incident (auth events, API calls, admin actions)?
- Post-mortem culture: template for incident review, action items, public vs internal documentation?
- Ransomware / supply-chain attack: how would we detect a compromised dependency or CI pipeline?

**Kill criteria**:
- MAU under 10K with no paid users — incident risk is low enough that formal response plan is premature.
- But: API key in source-controlled code or public CI logs is never acceptable, regardless of MAU.

**Status**: Seed — 2026-05-25

**Links**:
- [EXPLORATION_TOPICS.md#100](../EXPLORATION_TOPICS.md#100)

**Related**: Privacy / Photo PII, Data Retention & PII Strategy, Dependency Supply Chain Security, CI/CD Pipeline Hardening, Audit / Telemetry
