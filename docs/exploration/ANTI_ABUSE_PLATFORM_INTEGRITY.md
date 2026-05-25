# Anti-Abuse & Platform Integrity

**Decision it unblocks**: Whether the platform has systematic abuse protections before abuse becomes a cost or trust crisis.

**Key questions**:
- Scan farming: what stops a user from taking 1000 photos of the same object to farm tokens/points? (Server-side dedup, rate limits, per-category caps, correction ratio gates?)
- Token farming: what prevents automated token generation? (Server-authoritative token accounting, App Check, HMAC receipt verification?)
- Referral abuse: what stops a user from creating 50 fake accounts to farm referral rewards? (Device fingerprinting, phone/email verification, IP rate limits, invite-tree analysis?)
- Duplicate account detection: can a banned user create a new account and continue? (Phone number, hardware ID, Apple/Google SSO cross-reference?)
- Content abuse in community features: spam, hate speech, misinformation about disposal — automated (moderation ML) or manual flow?
- Community reputation manipulation: can users vote-farm or report-abuse to harm competitors?
- Civic report abuse: false reports of missed pickup, illegal dumping — what verification threshold applies?
- Premium abuse: can a user share a premium account across many devices? (Concurrent session limits, device cap?)
- Compliance abuse: can a user trigger the consent/delete flow repeatedly to disrupt operations?
- Detection vs enforcement balance: how much abuse do we tolerate before investing in detection infrastructure?
- Ethics of blocking: what's the appeals process for falsely flagged legitimate users?

**Kill criteria**:
- No measurable abuse pattern observed at current MAU (< 1000 DAU). Pre-mature investment in anti-abuse infrastructure before abuse is real.
- But: server-authoritative token accounting (#27a) and App Check are non-negotiable regardless of MAU — they prevent the most costly abuse (AI budget drain).
- Rate limits for AI calls (#10 G4 backend proxy) are first line of defense and already planned.

**Status**: Seed — 2026-05-25

**Links**:
- [EXPLORATION_TOPICS.md#102](../EXPLORATION_TOPICS.md#102)

**Related**: Token Economy & Pricing Coherence, AI Cost Telemetry & Guardrails, Backend Classification Proxy, Account Identity Lifecycle, Moderation & Safety, Deep Links & Viral Loops
