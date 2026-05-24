# Exploration Frontier — ReLoop

**Purpose**: High-ambition / "boil the ocean" frontier bets that don't fit a quarter's roadmap but should never fall off the map.
**Status**: Living
**Last Updated**: 2026-05-19
**Parent**: [EXPLORATION_TOPICS.md](EXPLORATION_TOPICS.md)
**Sibling**: [EXPLORATION_ROADMAP_WHILE_BUILDING.md](EXPLORATION_ROADMAP_WHILE_BUILDING.md)

---

## How this list works

- Each entry is a frontier bet — credible, but not currently funded with engineering time.
- For each: **what it is**, **why it could matter**, **what would have to be true** for it to become real, **kill criteria** (what would let us drop it).
- Promote a bet into [EXPLORATION_TOPICS.md](EXPLORATION_TOPICS.md) only when the "what would have to be true" pre-conditions look reachable.
- Demote a bet to [exploration/backlog.md](exploration/backlog.md) (or kill it) when the kill criteria fire.

---

## F1. Fully On-Device Multi-Model Stack

**What it is**: The common case of waste classification runs entirely on-device. Cloud is a fallback for genuinely ambiguous inputs, not the default path.

**Why it could matter**:

- Privacy by default — no photo leaves the device unless the user opts in.
- Marginal cost per classification → near zero.
- Works in places where the cloud doesn't (rural India, schools with bad Wi-Fi).

**What would have to be true**:

- A Flutter-deployable VLM (Gemma 3n, MiniCPM-V, SmolVLM class) hits acceptable quality on a held-out waste-classification golden set.
- Battery and thermal budget on representative mid-tier Android devices is acceptable.
- Model bundle / lazy-download strategy keeps APK size reasonable.

**Kill criteria**:

- After two serious model evaluations, top-1 quality is still > 10–15 points behind cloud Gemini/GPT-4-class on the golden set, and the gap isn't closing with smaller deltas.
- Inference latency on mid-tier devices is consistently > 3 seconds for the common case.

**Related**: [On-Device Inference](EXPLORATION_TOPICS.md#6-on-device-inference-), [Multi-Model AI Routing](EXPLORATION_TOPICS.md#1-multi-model-ai-routing--seed).

---

## F2. Region-Aware Disposal Reasoning over a Live Rules Corpus

**What it is**: Disposal advice is a separate reasoning step grounded in a versioned, citable rules corpus per jurisdiction. The model retrieves and reasons; it doesn't invent.

**Why it could matter**:

- Currently the single biggest failure mode is "right material, wrong disposal advice" because rules vary.
- Builds an asset (the corpus) that compounds and that competitors don't have.
- Opens the door to municipal partnerships — we maintain *their* rulebook in the app.

**What would have to be true**:

- A clean ruleset schema exists (material × jurisdiction × method × exceptions × source).
- We can seed at least two cities (Bangalore + one more) credibly.
- Update cadence is sustainable — manual curation + community submissions + verified-source ingestion.

**Kill criteria**:

- We can't get even one credibly-maintained ruleset live within one quarter.
- Users routinely override the corpus-derived advice because local reality differs in ways we can't model.

**Related**: [Disposal Reasoning Stage](EXPLORATION_TOPICS.md#3-disposal-reasoning-stage-), [Region-Aware Rulesets](EXPLORATION_TOPICS.md#4-region-aware-rulesets-).

---

## F3. Continuous Learning Loop from User Corrections

**What it is**: Every user correction is a labelled training datapoint. A weekly cycle re-evaluates the golden set, identifies hard examples, and proposes prompt / routing / model updates.

**Why it could matter**:

- The biggest unfair advantage of a deployed app is the data it produces. Today that data largely goes unused.
- Compounding accuracy improvement without raw model retraining.

**What would have to be true**:

- Eval harness and golden set exist and are trusted (F-tier dependency on `EVAL_HARNESS_AND_GOLDEN_SETS`).
- Correction signals are clean — distinguishable from "user changed their mind" or trolling.
- Privacy / consent for using user data this way is explicit and reversible.

**Kill criteria**:

- Correction signal is too noisy / sparse to be useful after a representative sample.
- Privacy review concludes we can't ethically use this data without a heavy consent burden that kills the loop.

**Related**: [Eval Harness & Golden Sets](EXPLORATION_TOPICS.md#5-eval-harness--golden-sets-), [Classification History Schema](EXPLORATION_TOPICS.md#12-classification-history-schema-).

---

## F4. Neighbourhood Reuse Marketplace

**What it is**: A second product surface — items go to "give away / swap / sell" *before* becoming waste. Scoped to a building / society / neighbourhood for trust and logistics.

**Why it could matter**:

- The highest-leverage waste intervention is preventing the item from entering the waste stream.
- Strong narrative tie-in with the app's mission; data flywheel between classification and reuse listing (camera open, item recognised, "want to give this away?" prompt).

**What would have to be true**:

- We can run a marketplace experience with credible safety and moderation at small scale.
- A defined wedge — society / RWA / building rather than competing with OLX city-wide on day one.
- Logistics (pickup, drop, payment if any) handled by users / existing channels — not by us.

**Kill criteria**:

- Pilot with two societies generates < N listings / week, or moderation overhead is unmanageable.
- Conflict with core app retention — users go to the marketplace and never come back to the classify flow.

**Related**: [Local Reuse Marketplace](EXPLORATION_TOPICS.md#22-local-reuse-marketplace-).

---

## F5. Smart-Bin / QR-Bin Aggregation Layer

**What it is**: Even before real IoT smart bins, a layer where physical bins (apartment, school, public) carry a QR code; scanning logs the disposal and unlocks bin-specific guidance and rewards.

**Why it could matter**:

- 80% of the perceived smart-bin value (verified disposal, location-aware) at 1% of the hardware cost.
- Becomes the bridge to real smart bins later, without committing to hardware partners now.
- Lets RWAs / schools "smart-enable" their bins immediately.

**What would have to be true**:

- QR generation, bin registration, and scan flow are operable by a non-technical RWA / school admin.
- Disposal verification can be made trustworthy enough to gate rewards (anti-cheating).
- Privacy review for logging "user X disposed at bin Y at time T".

**Kill criteria**:

- After two pilots, admins won't maintain the QR layer; or users won't bother scanning.

**Related**: [Smart-Bin Integration](EXPLORATION_TOPICS.md#24-smart-bin-integration--frontier), [Municipal APIs](EXPLORATION_TOPICS.md#25-municipal-apis-bbmp-etc-).

---

## F6. Carbon / Impact Accounting with Defensible Methodology

**What it is**: Headline "X kg CO₂ saved" / "Y kg plastic diverted" numbers backed by a published methodology, regional emission factors, and acknowledged uncertainty.

**Why it could matter**:

- The motivation engine for the user *and* the credibility currency for partners (corporates, schools, municipalities).
- Without methodology, claims become reputational risk.

**What would have to be true**:

- A clear framework choice (EPA / IPCC / regional) and someone competent enough to defend it.
- UI that can show both a headline number and the uncertainty without killing motivation.

**Kill criteria**:

- After a serious attempt, all credible methodologies require data we don't and won't have.

**Related**: [Carbon / Impact Accounting](EXPLORATION_TOPICS.md#30-carbon--impact-accounting-).

---

## F7. Tokenised Impact / Web3 Layer

**What it is**: NFT proof-of-disposal, tokenised carbon credits, on-chain verified action — discussed in `STRATEGIC_ROADMAP_COMPREHENSIVE.md`.

**Why it could matter**:

- Tamper-proof community drop-off records.
- Optional incentive ladder beyond gamification points.

> The [gamification redesign spec](planning/gamification-redesign-spec.md) serves as the foundation layer below any future tokenised or external incentive ladder. Its points economy (§2), achievement tiers (§3), and challenge system (§6) define the base engagement loop that a web3/impact layer would extend. Any tokenised layer should integrate via the one-way integration contract (§12.1) to avoid compromising the core points economy.

**Honest assessment**:

- High narrative risk vs current practical value. Most "web3 for waste" projects have struggled with real user pull-through.
- Risk of distracting from the core classification + disposal loop.

**What would have to be true** before promoting:

- The corresponding non-web3 system (verified disposal logs, F5) already works at scale.
- A concrete partner (municipality, brand, ESG fund) needs the on-chain proof; users don't drive this.

**Kill criteria**:

- If F5 fails (no reliable disposal verification), F7 can't exist credibly.

**Status today**: PARKED — revisit only after F5 is real.

**Related**: `STRATEGIC_ROADMAP_COMPREHENSIVE.md` blockchain section.

---

## F8. Brand / Manufacturer Closed-Loop Data

**What it is**: Anonymised, aggregated data showing how products from brand X are being disposed of, where, and how often correctly. Sold or shared with brand sustainability teams to inform packaging redesign.

**Why it could matter**:

- A B2B revenue surface that doesn't compromise the user experience.
- Brands have real budgets for sustainability data.

**What would have to be true**:

- Image recognition reliably identifies brand/SKU at acceptable resolution.
- Privacy and consent posture supports aggregated commercial data sharing.
- Sales motion to brands — totally different muscle than the consumer app.

**Kill criteria**:

- Brand-identification accuracy isn't there even with a year of effort.
- Privacy/consent posture makes the offering legally too complex.

**Related**: [B2B / Enterprise Wedge](EXPLORATION_TOPICS.md#29-b2b--enterprise-wedge-), [Privacy / Photo PII](EXPLORATION_TOPICS.md#32-privacy--photo-pii-).

---

## F9. Voice-First & Multi-Modal Capture

**What it is**: Classify by voice description (when camera isn't viable), audio cues (crinkle of plastic vs paper), short video, or share-from-other-app intents.

**Why it could matter**:

- Accessibility — visually-impaired users.
- Hands-free scenarios — kitchen, garage.
- Reduces dependency on photo quality, which is the dominant failure mode today.

**What would have to be true**:

- Cloud / on-device speech and audio pipelines stable and cheap enough.
- Clear UX for when voice is the primary mode vs the fallback.

**Kill criteria**:

- After a prototype, real users prefer the camera path in > 90% of cases even when given a choice.

**Related**: [Accessibility & I18n](EXPLORATION_TOPICS.md#18-accessibility--internationalisation-).

---

## F10. Education-First White-Label for Schools

**What it is**: A school-specific surface — classroom dashboards, teacher controls, lesson-aligned content, kid-safe community.

**Why it could matter**:

- Strong distribution channel — one teacher → 30 kids → 30 families.
- Mission-aligned and easier to evangelise than a B2C consumer pitch.

**What would have to be true**:

- A pilot with one or two schools that proves teachers will actually use it.
- Kid-safe surfaces (moderation, parental controls) at acceptable maturity.

**Kill criteria**:

- Two pilots show teachers don't sustain usage beyond a one-week novelty period.

**Related**: [Persona Journeys](EXPLORATION_TOPICS.md#15-persona-journeys-), [B2B / Enterprise Wedge](EXPLORATION_TOPICS.md#29-b2b--enterprise-wedge-).

---

## Promotion / Demotion Log

| Date | Bet | Action | Rationale |
|------|-----|--------|-----------|
| 2026-05-19 | All bets above | Seeded | Initial frontier list captured. |
| 2026-05-21 | Waste UI Component System | Promoted to EXPLORATION_TOPICS.md (19a) | Canonical waste-domain helpers + 8 components built; enables F2/F4/F5 display consistency. See `docs/review/WASTE_UI_COMPONENT_SYSTEM_2026-05-21.md`. |

(Append entries here as bets promote into EXPLORATION_TOPICS.md, get killed, or change status.)
