# Verified Environmental Impact Ledger — Exploration Doc

**Track**: P3 — Deep Frontier
**Status**: 🟢 Exploration
**Last Updated**: 2026-05-24
**Parent**: [EXPLORATION_TOPICS.md #82](../EXPLORATION_TOPICS.md#82-verified-environmental-impact-ledger-)
**Sibling topics**: Carbon / Impact Accounting (#30 / F6), Personal Impact Dashboard (A9), Corporate ESG Mode (#67), Tokenised Web3 Layer (F7), Smart-Bin / QR-Bin (F5)

---

## Decision This Unblocks

Whether to build an auditable impact ledger — a system that generates verified claims about waste diverted, carbon saved, or materials recovered — and whether this should be a simple database-backed audit trail or a blockchain-based immutable record.

---

## Overview

"I diverted 50 kg of plastic from landfill" is a claim. A **verified impact ledger** makes it an auditable claim: anyone can verify that the classification happened, the material was correctly identified, and the disposal was properly executed.

The key insight: **impact claims without verification are marketing, not data.** Verified claims unlock:

- Corporate ESG reporting (paid B2B wedge).
- School curriculum integration (credible educational data).
- Brand/manufacturer feedback loops (F8).
- Carbon offset partnerships (if credible).
- User trust (the app's numbers are real).

---

## What Kinds of Verification Exist

| Verification Level | What It Proves | How | Audit Cost |
|-------------------|---------------|-----|------------|
| L0: Unverified | "User says they sorted an item" | Self-report | Zero |
| L1: Classified | "An AI identified this item" | Classification record + photo | Low (retrospective random audit) |
| L2: QR-Verified | "Item disposed at a known bin" | QR scan log + timestamp (F5) | Low |
| L3: Photo-Verified | "Photo shows item in correct bin" | Human reviewer checks photo | Medium |
| L4: Third-Party Audited | "Verified by auditor X annually" | External auditor samples logs | High ($/audit) |

**Recommendation**: Build for L1 → L2 as the core product path. L3 and L4 are buyer-specific upgrades, not default features.

---

## Database-Backed Ledger (Recommended)

### Schema

```dart
// One record per classification
class ImpactLedgerEntry {
  final String id;                    // ledger entry ID (UUID)
  final String userId;                // pseudonymised user ID
  final String classificationId;      // links to classification record
  final String category;              // e.g., "plastic_bottle"
  final double estimatedWeightKg;     // from avg weight table or AI estimate
  final String material;              // e.g., "PET"
  final String disposalMethod;        // e.g., "recycle", "compost", "landfill"
  final String disposalRuleVersion;   // which city rule applied
  final String modelVersion;          // which model/prompt classified this
  final DateTime classifiedAt;
  
  // Verification
  final VerificationLevel verified;   // L0-L4
  final String? verifiedBy;           // reviewer ID for L3/L4
  final String? binId;               // for L2 verification (QR scan)
  final DateTime? verifiedAt;
  
  // Audit
  final DateTime createdAt;
  final bool deleted;                 // soft delete for privacy withdrawal
  final String? retentionExpiry;      // when record is auto-anonymised
}
```

### Data Flow

```
Classification → ImpactLedgerEntry (L1) → Aggregation → Verified Claims
                      ↓
               QR Scan (L2) removes
               "unverified" flag
                      ↓
               Annual audit (L4) reviews
               sample of entries
```

### Important: This Is Not a Replacement for the Gamification Ledger

Impact verification runs **parallel to and separate from** the token economy (#27a) and civic reputation (L4). Rationale:

- Impact claims must survive privacy withdrawal (user deletes account → impact aggregated record stays, user ID removed).
- Gamification points are ephemeral and user-facing. Impact ledger is permanent and partner-facing.
- Token economy has anti-farming rules; impact ledger has verification rules. Different concerns.

---

## The Blockchain Question

### Arguments For

- Immutability: once written, an impact claim cannot be altered.
- Transparency: anyone can audit the chain.
- Partner trust: "on-chain" is a credibility signal for corporate buyers.

### Arguments Against

- **No practical advantage for this use case**: Immutability is provided by Firestore's built-in change tracking (the `createdAt` field + write-ahead log). "Altering" an impact record requires admin Firestore access — which is already controlled by security rules.
- **Gas costs**: Writing each classification to-chain costs $0.01-0.50 (Ethereum L2). At 10K classifications/day → $100-500/day in gas. This is prohibitive at scale.
- **Privacy**: On-chain records are permanent. Users cannot withdraw consent if their data is on a public blockchain.
- **Complexity**: Smart contract development, audit, and key management add a full product surface.

### Verdict: Do Not Use Blockchain

Blockchain adds cost, complexity, and privacy risk without adding meaningful verification value for this product's scale. A well-structured Firestore collection with `createdAt` timestamps, retention policies, and annual third-party audit is more verifiable than an un-audited on-chain record.

**Exception**: If a specific B2B partner requires on-chain records (e.g., a carbon offset registry), evaluate on a per-partner basis using a private permissioned chain or a verified data API, not a public blockchain.

---

## Impact Metric Methodology

### Waste Diverted (kg)

```
∑ (estimated_item_weight) for all classifications where
  disposalMethod ∈ {recycle, compost, reuse, donate}
```

- Weight estimation: average item weight table (see #81).
- Transparency: Show methodology note — "Weights are estimates based on EPA averages."

### CO₂ Equivalent Saved (kg)

```
% per item_type × estimated_weight × (emission_factor_landfill - emission_factor_recycling)
```

- Plastic bottle: landfill emits 0.003 kg CO₂e/g; recycling saves ~0.006 kg CO₂e/g.
- Source: EPA WARM model (Waste Reduction Model).
- Uncertainty: ±40% due to weight estimation + transport variables.

### Landfill Volume Avoided (L)

```
estimated_volume = estimated_weight / density_of_item_category
```

- Plastic: density ~0.03 g/cm³. Glass: density ~2.5 g/cm³.
- Volume-based metrics are easier to visualize ("this is the size of a bathtub") but harder to compute accurately.

### Honest Presentation

```dart
class ImpactClaim {
  final double bestEstimate;      // central value (kg, CO₂e, etc.)
  final double lowerBound;        // 90% confidence interval lower
  final double upperBound;        // 90% confidence interval upper
  final String methodologyNote;   // "Based on EPA WARM model v16"
  final String uncertaintyNote;   // "Actual impact varies by transport, facility, and item condition"
}
```

**Design rule**: Never show a single number without acknowledging uncertainty. A tooltip or footnote is sufficient:

> "This is an estimate. Actual impact depends on how the item was processed. [Methodology]"

---

## Audit Trail for Partners (B2B)

For corporate ESG reports or school impact certificates:

```
Quarterly verified report:
- Total classifications: 12,847
- Verified (L1+): 11,230 (87.4%)
- QR-verified (L2): 3,412 (26.6%)
- Random-sample audited (L3): 500 records sampled, 98.2% match rate
- Methodology: [link to published methodology doc]
- Auditor: [name/firm, for L4 reports]
```

**Minimum viable**: Monthly CSV export with header fields (category, weight, verified level, date range). Sent via email. No dashboard required for first partner.

---

## Kill Criteria

1. **No B2B/B2G buyer has requested verified impact data** after 6 months of having the product available.
2. **Users do not engage** with "Your impact summary" any more than they engage with raw classification counts.
3. **Methodology validation** shows ±80%+ uncertainty on weight estimates (too noisy to publish).
4. **Privacy review** concludes that impact ledger retention conflicts with right-to-deletion (soft-delete pattern mitigates this).

---

## Concrete Next Steps

1. ✅ Do not build blockchain integration.
2. ✅ Weight estimation table — exists in related doc (#81).
3. Add `ImpactLedgerEntry` model to Firestore (new collection: `impact_ledger`).
4. Write a lightweight methodology doc: `docs/methodology/impact_calculation.md` sharing calculation formulas and sources.
5. Add "Your Impact Summary" section to the personal dashboard (A9) with uncertainty acknowledgment.
6. When first B2B partner requests data, export as CSV from `impact_ledger` collection.

---

## Research Sources

- EPA WARM model v16 (Waste Reduction Model) — emission factors per material and disposal method.
- Verra (Verified Carbon Standard) — carbon offset verification methodology.
- Gold Standard for the Global Goals — sustainable development impact methodology.
- Puro.earth — CO₂ Removal Certificates standard (non-blockchain framework).
- Google Cloud Firestore audit logs — built-in immutable change stream for Firestore collections.
- Ethereum L2 gas costs (Arbitrum/Optimism) — ~$0.01-0.05 per tx; prohibitive at classification scale.
