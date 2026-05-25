# Pickup Booking & Logistics Integration

**Status**: Seed — P2, not yet funded
**Last Updated**: 2026-05-26
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Item 77
**Related**: SCRAP_RATES_RECYCLABLE_VALUE.md, DISPOSAL_FACILITIES_DIRECTORY.md, CIVIC_AUTHORITY_SHARING.md, CIVIC_B2B_B2G_VALIDATION.md

---

## 1. Why This Matters

Classification answers "what is this and where does it go?". But many items can't go in the household bin — e-waste, bulk waste, hazardous materials, scrap metal. The natural next step is "book a pickup."

Pickup booking is also a monetisation surface (commission on paid pickups, premium feature for unlimited bookings) and a B2B wedge (RWA/school/corporate accounts with scheduled bulk pickups).

---

## 2. Existing Patterns

| Platform | Model | Logistics | Trust Mechanism |
|----------|-------|-----------|-----------------|
| **RecycleSmart** | Aggregator (marketplace) | Partner recyclers | Photo proof, driver rating |
| **The Kabadiwala** | Aggregator + own fleet | Hybrid (own + partner) | Digital scale, UPI payment, membership |
| **Too Good To Go** | Marketplace | Partner businesses | Digital receipt + swipe confirmation |
| **Olio** | Peer-to-peer | User self-arranges | In-app chat, ratings |
| **Municipal apps** | Government service | City fleet | Ticket-based, no SLA |

---

## 3. Pickup Booking UX Flow

### 3.1 Core Flow
1. **Item identification**: User selects type from visual menu (icons for e-waste, bulk furniture, metal scrap, hazardous, compost).
2. **Photo upload**: Required for verification and value estimation. "Take a photo of the items where they'll be picked up."
3. **Address + time window**: Pre-filled from profile or GPS. Time slot selection (next available vs specific window).
4. **Value estimate**: Estimated scrap value (for recyclable materials) or pickup fee (for non-recyclable bulk).
5. **Confirmation + tracking**: "Pickup confirmed [Driver name] arriving between 2-4 PM tomorrow."
6. **Completion**: Driver confirms pickup (photo proof + digital signature). User rates the experience.

### 3.2 Status Lifecycle
```
Created → Assigned → En Route → Picked Up → Verified → Completed
                                                                      ↓
                                                               (if paid) Paid
```

---

## 4. Logistics Models

### 4.1 Aggregator/Marketplace (Recommended for MVP)
- **How it works**: The app connects users to partner recyclers/haulers. The app handles the front end; partners handle collection.
- **Pros**: Asset-light, fast to launch, scalable.
- **Cons**: Quality control depends on partner vetting, less margin control.

### 4.2 Municipal Hybrid
- **How it works**: The app routes requests into municipal ticketing/scheduling systems.
- **Pros**: No logistics cost, aligned with government services.
- **Cons**: No SLA (municipal timelines are unpredictable), not available in most cities.

### 4.3 Peer-to-Peer
- **How it works**: Users list items for pickup by anyone (neighbour, kabadiwala, recycler).
- **Pros**: Zero logistics cost, community engagement.
- **Cons**: Safety risk, quality variance, no SLA.

**Recommendation for MVP**: Aggregator model with 1-2 verified partner recyclers per city.

---

## 5. Trust & SLA Design

### 5.1 Proof of Pickup
- **Driver confirmation**: Photo of collected items loaded on vehicle + digital signature.
- **Geo-fencing**: Automatic timestamp when driver arrives at/passes pickup address.
- **User confirmation**: User swipes to confirm pickup completed.

### 5.2 Missed Pickup Handling
- **Automated rebooking**: One-tap reschedule if driver no-shows.
- **Proof of attempt**: Driver must pin location/photo to prove they visited.
- **Trust scoring**: Flag users who mark items as "ready" but aren't; flag drivers with frequent no-shows.

### 5.3 Payment & Deposits
- **Free pickups**: For subsidised/partner-supported recycling (e-waste, scrap metal with value).
- **Paid pickups**: For bulk waste, hazardous, or non-recyclable items.
- **Pre-authorisation**: Card pre-authorised at booking; final charge confirmed after pickup verification.
- **Deposit for large items**: Refunded if item matches description.

---

## 6. Integration with Scrap Value Engine

When a pickup is booked, the scrap value estimate (see SCRAP_RATES_RECYCLABLE_VALUE.md) affects the flow:

| Scenario | User Sees |
|----------|-----------|
| High scrap value (>₹200) | "Your items are worth ~₹250. The recycler will pay you on pickup." |
| Low scrap value (₹10–200) | "Estimated value ₹30. Free pickup available." |
| Negative value (disposal fee) | "Disposal fee ₹150. This covers safe processing." |
| Mixed load | "Sorting available on site — estimated value range ₹50–200." |

---

## 7. Minimum Viable Pickup Feature

### Phase 1: Manual Dispatch (1-2 months to MVP)
1. **User side**: Simple photo upload + address + category selection.
2. **Operator side**: Lightweight dashboard (Airtable/Retool) receives requests.
3. **Dispatch**: Manual communication with 1-2 partner haulers via WhatsApp.
4. **Confirmation**: Manual notification to user when pickup is assigned.

### Phase 2: Semi-Automated (3-4 months)
1. Automated partner notification when request matches their service area.
2. In-app tracking updates (status changes).
3. Rating system for partners.

### Phase 3: Full Automation (6+ months)
1. Automated dispatch to nearest available partner.
2. Real-time driver tracking on map.
3. In-app payment + deposit handling.
4. Only pursue when Phase 2 volume clearly exceeds manual handling capacity.

---

## 8. Kill Criteria

- Cannot find 2+ reliable partner haulers in the launch city within 3 months.
- Partner quality (no-show rate, damage complaints) exceeds acceptable threshold.
- Users show no interest in pickup feature (high volume of classifications but zero pickup requests).
- Pickup feature does not measurably increase retention or revenue within 6 months.
