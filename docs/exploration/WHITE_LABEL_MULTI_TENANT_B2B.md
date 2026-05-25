# White-Label / Multi-Tenant B2B Infrastructure

**Decision it unblocks**: Whether to offer branded/whitelabel versions of the app to schools, apartment societies, municipalities, and corporate ESG teams — and what infrastructure that requires.

**Key questions**:
- What is the minimum viable B2B offer: brand-customised scan + result screen, or full tenant-isolated backend?
- Tenant data isolation model: Firestore collection prefix / per-tenant DB / separate project for enterprise?
- Theming/customisation surface: logo, colors, bin guidance icons, local rule set, welcome screen, feature flags per tenant?
- Tenant onboarding automation: self-service signup, tenant admin account creation, bulk user import?
- Tenant admin dashboard: user management (roles, invites, removal), analytics export (CSV/PDF), usage reports?
- Pricing model: per-seat / per-tenant / flat monthly / usage-based?
- First tenant profile: school (classroom mode), apartment/RWA, or corporate ESG team?
- Support model: does white-label include white-label support or is it still the parent brand?
- iOS/Android app variants: how do branded apps get distributed (App Store multiple entries, enterprise MDM, or PWA)?

**Kill criteria**:
- No paid B2B pilot within 6 months of first tenant-ready build.
- Tenant onboarding requires > 1 week of engineering time per tenant.
- App Store guidelines prevent white-label variants (reviewer confusion).

**Status**: Seed — 2026-05-25

**Links**:
- [EXPLORATION_TOPICS.md#99](../EXPLORATION_TOPICS.md#99)

**Related**: B2B / Enterprise Wedge, Family/School/Org Modes, Monetization & Pricing Tiers, Distribution & Partnerships
