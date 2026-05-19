# Cartographer: Token Economy Spatial Map — Waste Segregation App

**Date:** 2026-05-19
**Role:** Cartographer
**Mandate:** Navigation, views, grouping, at-a-glance information design, the spatial mental model.

---

## 10,000ft: The Territory Is Wrong

The current token economy has three territories that do not connect:

| Territory | Entry Point | Surface | Depth | Exit |
|-----------|------------|---------|-------|------|
| **Instant Analysis** | Camera button | "5 tokens" label | 0 tokens actually deducted | Result screen |
| **Batch Analysis** | Queue button | "1 token" label | 1 token deducted | Notification (2-6h later) |
| **Premium** | Paywall | "$4.99/mo" label | Unknown connection to tokens | Settings |

A user standing at the Camera button sees a price tag (5 tokens) that does not match the receipt (0 charged). A user standing at the Queue button sees a price tag (1 token) that does match the receipt (1 charged). A user at the Premium paywall sees no connection to either.

This is not a map. This is three unconnected islands with bridges drawn on them that lead to the ocean.

**The spatial problem:** Users navigate by landmarks. Right now, the landmarks contradict each other. The "5 tokens" sign says "expensive." The actual experience says "free." The brain resolves this contradiction by ignoring the sign.

---

## 1,000ft: The View Hierarchy

### Current State (Broken)

```
App
├── Home Screen
│   └── No token visibility (balance hidden until analysis)
├── Image Capture
│   ├── "Analyze (Instant)" → 5 tokens label → 0 tokens deducted
│   └── "Analyze (Batch)" → 1 token label → 1 token deducted
├── Results Screen
│   └── No token reflection (did I spend? how many left?)
├── Token History
│   └── Shows transactions (batch only — instant produces none)
├── Premium Screen
│   └── No token connection (separate universe)
└── Settings
    └── No token controls
```

### What a User Sees at Each View

| View | Sees | Understands | Actually Happens |
|------|------|-------------|-----------------|
| Home | Nothing about tokens | "This app is free" | Instant is free, batch costs |
| Capture | "5 tokens" on instant button | "This costs something" | Nothing is deducted |
| Capture | "1 token" on batch button | "This is cheaper" | 1 token is deducted |
| Results | No token feedback | "Transaction complete" | No confirmation of spend/earn |
| History | Batch entries only | "I spent 3 tokens" | Instant analysis produces no records |
| Premium | Monthly fee | "This replaces tokens?" | No connection established |

**Navigation dead ends:**
1. Instant analysis produces no transaction record. No history entry. No balance change. The user has no way to verify the displayed cost.
2. Premium has no path to tokens. No "Premium users get X tokens/month." No bridge.
3. Zero balance has no next step. No "earn more" path. No "switch to batch" nudge. Just a wall.

---

## Ground Level: The Information Architecture

### The 3 Maps a User Needs

**Map 1: Balance at a Glance**
- Where: Persistent header or home screen badge
- What: Current token count + earned/spent today
- Why: Without a balance indicator, the economy is invisible

**Map 2: Decision Crossroads**
- Where: At the analysis choice point (instant vs batch)
- What: "You have X tokens. Instant costs 5. Batch costs 1. Which speed?"
- Why: The current UI shows cost but not affordance. Users need to see both sides.

**Map 3: Earning Pathways**
- Where: Zero-balance screen or settings
- What: Daily login bonus, correction rewards, batch completion bonuses
- Why: Without earning paths, a balance going down is a countdown timer to churn

### The Spatial Metaphor That Works

Think of the token economy as a **water tank with two faucets and three drains**:

```
        [Daily Login +5]
        [Correction Bonus +1]     ← Faucets (earn)
            │
    ┌───────┴───────┐
    │               │
    │  TOKEN TANK   │
    │  Balance: 47  │
    │               │
    └───┬───────┬───┘
        │       │
    [Instant] [Batch]    ← Drains (spend)
     -5        -1
        │       │
    [Result]  [Queue]    ← Destination
     Now     2-6h later
```

Currently, the Instant drain is disconnected from the tank. Water flows freely. The tank never empties for instant users. Batch users see the tank drain correctly.

**What this means for navigation:** Every screen that touches tokens needs a visual connection back to the tank. The tank level should be visible from:
1. Home screen (header badge)
2. Analysis choice (instant vs batch selector)
3. Results screen (balance delta: "-5" or "-1")
4. Zero-balance screen (earning paths)
5. Settings (token history + premium bridge)

---

## Groupings That Should Exist But Don't

| Group | Should Contain | Currently Contains |
|-------|---------------|-------------------|
| Balance Header | Token count + trend arrow | Nothing |
| Analysis Choice | Cost + affordance + alternative | Cost only |
| Transaction History | Instant + batch entries | Batch entries only |
| Earning Center | Daily bonus + correction rewards | Welcome bonus only |
| Premium Bridge | Token multiplier + free analysis days | Nothing |
| Zero-Balance Sheet | Earn/wait/convert options | Nothing (app likely crashes or blocks silently) |

---

## The Thing Most People Miss About This

**An economy that is not navigable is not an economy. It is a sticker.**

The token system has no map. There is no "you are here" indicator. There is no "how to get more tokens" path. There is no "what happened to my tokens" history for the path users use most (instant). The app has built a toll booth with no signage, no alternate route, and no way to see if your toll pass works.

The fix is not enforcement. The fix is **legibility first, enforcement second**. Make the economy visible, navigable, and understandable before you make it real. A user should be able to answer three questions from any screen:
1. How many tokens do I have?
2. What can I do with them right now?
3. How do I get more?

Until those three questions have clear visual answers, enforcement will feel like a trap, not a feature.

---

*End of Cartographer output. Return to brainstorm facilitator.*