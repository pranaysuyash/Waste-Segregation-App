# EU Digital Product Passport (DPP) / ESPR Integration

**Status**: Exploration doc
**Last Updated**: 2026-05-25
**Category**: Industry Signal
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md#a23-eu-digital-product-passport--espr--industry-signal-)
**Related**: Region-Aware Rulesets (#4), Disposal Reasoning Stage (#3), Recycling Code Taxonomy (A22), Deterministic Classifier (G1), Smart-Bin Integration (#24)

---

## Why This Is a Topic

The EU Ecodesign for Sustainable Products Regulation (ESPR) mandates Digital Product Passports (DPPs) for specific product categories starting 2026, with battery passports mandatory by February 2027. DPPs carry authoritative material composition, disposal, and circularity data per product unit.

**Implication for this app**: DPPs are an **authoritative data source** for disposal advice. Once products carry them, the app's region-aware rulesets become a **resolver**, not a primary data source. Products with DPPs bypass image classification entirely for labelled, in-scope items.

This is an industry signal to *track and prepare for*, not a build target for the current quarter.

---

## Key Questions

1. **Timeline** — when will DPPs cover meaningful consumer product categories for waste classification?
2. **Consumption path** — how does a mobile app consume a DPP data carrier (QR/NFC scan)?
3. **Battery passport implications** — does the Feb 2027 deadline offer an immediate opportunity?
4. **Resolver architecture** — what infrastructure does the app need to query DPP data?
5. **Replacing AI vision** — for which product categories can DPPs replace or augment image-based classification?
6. **Pilot opportunity** — can the app be an early consumer-facing DPP consumer?

---

## Research Summary

### ESPR Timeline

| Date | Milestone | Scope |
|------|-----------|-------|
| July 2024 | ESPR in force | Framework regulation |
| Feb 2027 | Battery passport mandatory | All industrial + EV + LMT batteries |
| 2026–2027 | Delegated acts for iron/steel, textiles, furniture, electronics | Product-specific rules |
| 2028–2030 | Consumer electronics and broader categories | Full DPP rollout |

**Key insight**: Battery passports are the nearest deadline (Feb 2027) and map directly to the app's safety-critical waste categories. This is the highest-leverage DPP opportunity.

### How an App Consumes a DPP

1. User scans QR code or taps NFC tag on the product
2. QR resolves to a URI via **GS1 Digital Link URI** standard
3. URI routes to a resolver that fetches structured JSON-LD data from the manufacturer's DPP server or a central registry
4. App parses the DPP payload for:
   - Material composition (chemical breakdown, recyclable materials)
   - End-of-life instructions (disassembly, separate disposal, return programs)
   - Battery chemistry (if applicable)
   - Hazardous substance declarations

The app doesn't need to store DPP data — it retrieves it on demand via the resolver.

### Battery Passport (Feb 2027)

Mandated fields relevant to the app:
- Battery chemistry (Li-ion, NiMH, lead-acid, etc.)
- Carbon footprint
- Recycled content percentage
- End-of-life instructions for consumers
- Unique battery identifier
- QR code on the battery itself

**Implication**: By mid-2027, most replacement batteries sold in the EU will carry QR codes with authoritative disposal instructions. The app should be ready to scan and parse these.

### DPP as Image Classification Bypass

For products with DPPs, the classification flow becomes:
```
QR/NFC scan → DPP resolver → Material composition → Regional rule lookup → Disposal advice
```

This is fully deterministic — no AI needed. For in-scope products, this is **faster, cheaper, and more accurate** than any vision model.

Categories where DPP will replace vision:
- Batteries (by Feb 2027)
- Consumer electronics (by 2028–2030)
- Textiles (by 2028)
- Furniture (by 2028)
- High-end appliances (by 2028)
- Anything with a GS1 QR code

### Resolver Architecture

```
[User scans QR on product]
        │
        ▼
[GS1 Digital Link URI] → [App reads URI from scan]
        │
        ▼
[DPP Resolver Service] (Firebase Function or external service)
        │
        ├── Manufacturer's DPP server (primary)
        │       └── JSON-LD payload → material/end-of-life data
        │
        └── Central EU registry (fallback when manufacturer server unreachable)
                └── Cached copy of DPP data
```

The resolver service handles:
- URI normalization and routing
- Manufacturer server reachability (with fallback)
- Data format parsing (JSON-LD → app model)
- Caching (24h TTL for non-perishable product data)

### Pilot Opportunity

The app could be an early consumer consumer of DPP data before the mandate reaches critical mass:

1. **Battery passport preview**: Partner with a battery manufacturer or recycling scheme to be an early consumer of battery DPP data
2. **GS1 Digital Link experiment**: Build QR scanning for products that already carry GS1 Digital Links (some premium electronics and appliances already do)
3. **DPP resolver sandbox**: Build the resolver architecture now against test/sandbox DPP servers (EU CIRPASS project offers test environments)

**Timing**: Pre-2027 is the window to experiment before the mandate reaches critical mass.

---

## Design Recommendations

### Preparation (2026)

1. Build GS1 Digital Link QR code scanner into the existing barcode scan path
2. Create `DppResolverService` that:
   - Resolves QR/NFC URIs to structured data
   - Parses JSON-LD DPP payloads
   - Returns `DppProductData` with material composition and disposal instructions
3. Integrate resolver result as a deterministic classification source in `ClassificationPipeline` (Layer 0 — beats AI by being authoritative)
4. Cache DPP lookups per GTIN (24h TTL for non-perishable, 1h for food/consumables)
5. Test against EU CIRPASS sandbox and any manufacturer pilot DPP servers

### Long-term (2027+)

6. Wire battery passport scan directly into safety-critical handling (hazardous routing)
7. When DPP covers a threshold of consumer products (estimated >30% by 2029), evaluate whether the vision pipeline should treat DPP-scannable products as a priority path
8. Consider DPP provider partnership: become a reference consumer app for manufacturers' DPP implementations

### Kill Criteria

- If GS1 Digital Link adoption among consumer products is still <5% by 2028, the investment in resolver infrastructure doesn't pay back yet
- If the resolver architecture adds >2s to scan latency (user scans QR, expects near-instant result), the caching strategy needs fundamental change

---

## Open Questions

- Should the app attempt to parse DPP data from any QR code on a product, or only from explicitly identified DPP carriers?
- What's the legal status of cached DPP data — can the app store and serve DPP data when the manufacturer server is down?
- If a DPP says "recyclable" but local municipality does not accept the material, which instruction wins?
