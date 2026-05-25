# Customer Support & User Help Infrastructure

**Decision it unblocks**: Whether to build in-app help/support as a first-class product surface or outsource to email/Zendesk/Intercom.

**Key questions**:
- What help do users need that isn't answered by the current UI? (disposal questions, safety concerns, account issues, feature discovery, bug reports)
- In-app FAQ / knowledge base vs chatbot (LLM-grounded on docs) vs email ticketing vs all three?
- How does a user report a wrong disposal instruction or safety concern urgently?
- What's the support SLA for safety-critical questions (hazardous waste, medical sharps)?
- How does user feedback on classification quality reach the engineering team without manual triage?
- What self-service paths reduce ticket volume: account settings, data export, consent revocation, deletion?
- Seasonal or event-driven support load (cleanup drives, collection schedule changes, new city rollouts)?

**Kill criteria**:
- User research shows < 5% of users need human-answered support (unlikely for a real-world product).
- Ticket volume stays < 10/month with only async email support.

**Status**: Seed — 2026-05-25

**Links**:
- [EXPLORATION_TOPICS.md#98](../EXPLORATION_TOPICS.md#98)

**Related**: Onboarding & Activation, Notification Strategy, Moderation & Safety, Account/Identity Lifecycle
