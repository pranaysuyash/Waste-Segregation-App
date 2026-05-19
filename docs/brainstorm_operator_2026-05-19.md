# OPERATOR MEMO: Token Economy Brainstorm
**Role:** Operator
**Date:** 2026-05-19
**Subject:** What the User Actually Does When Tokens Become Real (Or Stay Fake)

---

## Preface: I Do Not Care About Philosophy

This memo is about hands, thumbs, screens, and seconds. Not about whether tokens are "attention allocation" or "a tax on compliance." Both of those memos are useful. This one is about what happens when a real person, standing in their kitchen at 7:42 PM, holding a yogurt cup they need to sort before the garbage truck comes tomorrow, opens this app and tries to figure out what bin it goes in.

The Strategist wants to A/B test. The Executioner wants to delete. I want to know: what does the user tap, what do they read, what do they ignore, and where do they quit?

---

## 1. 10,000ft -- The Day-One Arc (What We Are Actually Building)

### The Current Day-One, Untouched

1. User downloads app. Sign up (email, Google, or anonymous).
2. Home screen loads. Token balance: 50 (model says 50; TokenService says 10 -- already a discrepancy).
3. User taps camera. Snaps yogurt cup. Review screen shows image.
4. Bottom of screen: "Analyze (Instant)" with "5 tokens" underneath.
5. User taps it. AI runs. Results in ~3 seconds. Token balance still says 50 (or 10).
6. User reads result. "Recyclable. Rinse and place in blue bin."
7. Done. Entire interaction: 15 seconds. Tokens were theater. User does not know this.

### The Day-One If We Flip Enforcement Tomorrow

1. Same download. Same sign up. Same 50 (or 10) tokens.
2. Same camera. Same yogurt cup. Same review screen.
3. Same button: "Analyze (Instant) -- 5 tokens."
4. User taps it. AI runs. Results in ~3 seconds. Token balance drops to 45 (or 5).
5. User barely notices the drop. They got what they wanted. They close the app.
6. Tomorrow morning. Coffee cup. Camera. Review screen. Tap. Token balance 40.
7. Day three. Takeout container. Token balance 35.
8. Day six. They sort their recycling. Token balance 15.
9. Day eight. Banana peel. Tap. "Insufficient tokens. Need 5, have 0."
10. The app just became a paywall at the moment of civic obligation.

**The 10,000ft insight:** The current unenforced state trains users that the app is free. Not "freemium." Free. The token display is wallpaper. If we enforce without changing anything else, the enforcement itself becomes a surprise penalty, not a paced economy. We are not "adding a feature." We are "removing a feature that users thought they had."

---

## 2. 1,000ft -- The Workflows That Actually Matter

### Workflow A: The First Time They See "0 Tokens"

This is the single most important moment in the entire economy. It determines whether the user churns, converts, or learns. Currently, this workflow does not exist. There is no 0-balance screen. The app would presumably crash or show a raw exception.

**What the user actually does at 0 tokens:**
- They are holding garbage. They need an answer in the next 60 seconds or the garbage truck leaves.
- They do not want to "watch a tutorial to earn 5 tokens." They want to know if the yogurt cup is recyclable.
- They do not want to "convert 500 eco-points." They do not know what eco-points are. They have never opened the points screen.
- They do not want to "upgrade to Premium." They are standing in their kitchen.

**What the app must offer at 0 tokens:**
1. **Batch mode as a bailout.** "Wait 2-6 hours, pay 1 token, get your answer." But this is useless for the garbage-truck scenario. The user needs the answer NOW.
2. **A token-free path.** "Share this app with a friend, get 10 tokens." But they are holding garbage. Their thumbs are dirty.
3. **A daily free scan.** "Your daily free instant scan resets in 14 hours." This is the only one that solves the immediate problem.
4. **A downgrade to text-only.** "Type a description instead of uploading an image. 0 tokens." But the user already took the photo.

**The concrete workflow we need:**

```
User taps "Analyze (Instant)" at 0 tokens
  -> Bottom sheet slides up (not a full-screen block)
  -> "You're out of instant scans for today."
  -> Option 1: "Switch to Batch (1 token, result in ~2 hours)" [Primary, if they have 1 token]
  -> Option 2: "Use your daily free instant scan" [Secondary, if not used today]
  -> Option 3: "Watch a 15-sec tip, earn 3 tokens" [Tertiary]
  -> Option 4: "Describe the item in text, 0 tokens" [Always available]
  -> No "Buy Tokens" button at first. The first time they hit 0, we teach. The second time, we offer purchase.
```

### Workflow B: The Speed Selector (The Actual UI)

The `analysis_speed_selector.dart` widget is where the token economy lives. Let me describe what the user sees:

- Top of widget: "Token Balance: 50" with a small coin icon.
- Two cards:
  - "Batch Analysis" -- "1 token" -- green checkmark if affordable.
  - "Instant Analysis" -- "5 tokens" -- greyed out with lock icon if not affordable.
- If instant is unaffordable: "You need 5 tokens for instant analysis. Earn more tokens through daily login bonuses, classifications, or convert eco-points." And a "TODO: Navigate to token wallet/earning screen" comment in the code.

**The micro-decision the user faces:**

The user is not choosing between "batch" and "instant" because they understand the token economy. They are choosing between "instant" (which feels like the normal thing) and "batch" (which feels like a worse thing). The token cost is a secondary signal. The primary signal is speed.

If we enforce tokens, the micro-decision becomes: "Do I spend 5 tokens now, or do I wait?" But the user has no mental model of how hard tokens are to earn. They got 50 (or 10) for free. They do not know the earn rate. They do not know if 5 tokens is expensive or cheap.

**What the UI must add to make this a real decision:**
- Below the speed selector, show: "You earn 2 tokens per day by opening the app. Instant analysis uses 2.5 days of login tokens."
- Or: "You have 50 tokens. At current usage, you will run out in 10 scans."
- Or: "Switch to batch to save 80% -- that's 4 extra scans this week."

Without this context, the token cost is just a number. Numbers without context are ignored.

### Workflow C: The Disconnect Between Premium and Tokens

Currently, `premium_service.dart` and `token_service.dart` do not know each other exist. From the user's perspective, this means:

- They can be a Premium subscriber and still run out of tokens.
- They can have 10,000 eco-points and not know they can convert them to tokens.
- They can pay $4.99/month for Premium and still hit a "5 tokens" wall on instant analysis.

**What the user actually thinks:** "I paid for this app. Why am I being charged again?"

**The concrete fix:**
- Premium should grant a daily free instant scan. Not "unlimited." One per day. This makes Premium feel like "insurance against the 0-token moment" rather than "a skip button for the entire economy."
- Premium should display a "token multiplier" in the speed selector: "Premium bonus: instant costs 3 tokens (save 40%)."
- The Premium features screen should mention token benefits. Currently it does not.

### Workflow D: The Batch Analysis Reality

Batch analysis deducts 1 token correctly (AiJobService calls spendTokens). But let's trace the user journey:

1. User selects batch mode. Taps analyze.
2. Token drops by 1.
3. App says: "Queued for batch analysis. Check back in 2-6 hours."
4. User closes app.
5. 4 hours later. User remembers. Opens app. Navigates to some jobs screen.
6. Result is there. Or it is not. Or it failed. Or the OpenAI batch API returned an error.
7. If it failed, the token is refunded (code exists for this). But the user already waited 4 hours. They do not want a token back. They want the answer.

**The micro-decision in batch mode:** The user is trading 1 token + 4 hours of memory burden for an answer. Most users will forget to check back. The batch mode is a "set it and forget it" that they will forget. The app needs a push notification when the batch completes. Currently, no notification code exists in the batch flow.

**Concrete addition:**
- When batch is submitted, ask: "Notify me when ready?" If yes, schedule a local notification.
- If the user opens the app before the batch completes, show a persistent banner: "1 batch job pending. Estimated ready in 2 hours."
- If batch fails, do not just refund the token. Offer an instant analysis at batch price (1 token) as apology.

### Workflow E: The No-Server-Validation Reality

Everything is client-side. Token balance is in local storage. The user can:
- Clear app data -> back to 50 (or 10) tokens.
- Use a rooted device -> edit the SharedPreferences directly.
- Airplane mode -> batch job submits but token is already deducted locally; no server reconciliation.

**What the user actually does:** Nothing malicious. 99.9% of users will never think about this. But the 0.1% who do will farm tokens, crash the economy for themselves, and then post about it on Reddit.

**The operator's take:** Server-side validation is not a "nice to have." It is a "the economy is fake without it." But server-side validation is also a Firebase bill. And a latency hit. And a cold-start problem. The concrete decision is: do we ship client-side enforcement first (with a kill switch), or do we block on server-side?

My take: ship client-side with a kill switch. Accept that the first 6 months will have token farming. Use that time to observe behavior. Then add server-side validation as Phase 2. The economy needs to be *tested* before it is *secured*.

---

## 3. Ground Level -- The Next Clicks (What I Would Actually Build This Week)

### Click 1: Fix the Welcome Bonus Discrepancy

`token_wallet.dart` says 50. `token_service.dart` says 10. The user gets 10. The UI shows 50. Fix this first. It is a one-line change that prevents every new user from thinking the economy is broken on day one.

File: `lib/services/token_service.dart`, line 32. Change `welcomeBonus = 10` to `welcomeBonus = 50` to match the model and the UI expectation. Or change the model. But make them match.

### Click 2: Build the Zero-Balance Bottom Sheet

Current state: hitting 0 tokens on instant analysis likely throws an uncaught exception or shows a generic error dialog.

Build `lib/widgets/zero_balance_bottom_sheet.dart`:
- Title: "You're out of instant scans"
- Body: "Instant analysis uses 5 tokens. You have 0. Here are your options:"
- Button 1 (primary, if batch affordable): "Switch to Batch (1 token, ~2 hours)"
- Button 2 (secondary, if daily free scan unused): "Use Daily Free Scan"
- Button 3 (tertiary): "Describe item in text (0 tokens)"
- Button 4 (last resort): "Earn 3 tokens (30 seconds)"
- NO "Buy" button on first encounter. Teach first. Sell second.

Wire this into `image_capture_screen.dart` at the point where `_analyzeImage()` would call the token service. Catch `Exception('Insufficient tokens...')` and show the sheet.

### Click 3: Add Token Context to the Speed Selector

In `analysis_speed_selector.dart`, below the two speed cards, add a one-line context banner:

```
"At 5 tokens per scan, your current balance lasts for X more instant analyses."
```

Where X = wallet.balance ~/ AnalysisSpeed.instant.cost.

This turns the token number into a meaningful countdown. Users understand countdowns. They do not understand abstract currency.

### Click 4: Implement the Kill Switch

Add a boolean flag `ENABLE_TOKEN_ENFORCEMENT` to `lib/services/token_service.dart` or `lib/utils/production_safety_config.dart`. Default: false.

When false: instant analysis bypasses spendTokens. Batch analysis still deducts (current behavior). When true: both enforce.

This is not Remote Config (too much setup for this week). It is a compile-time flag. Flip it in a future release after telemetry is added.

### Click 5: Connect Premium to Token Cost

In `lib/services/cost_guardrail_service.dart` or a new `effective_token_cost_provider.dart`, read both `premiumServiceProvider` and `tokenWalletProvider`. Compute:

```
if (isPremium && hasDailyFreeScan) -> instantCost = 0
else if (isPremium) -> instantCost = 3 (discounted)
else -> instantCost = 5
```

Display this discounted cost in the speed selector. This is the first bridge between the two monetization systems. It takes one provider and one UI line change.

### Click 6: Add Batch Completion Notification

In `lib/services/batching_service.dart` or `lib/services/ai_job_service.dart`, when a batch job is created, schedule a local notification for "estimated completion time + 15 minutes buffer."

Use the `flutter_local_notifications` package (already in most Flutter projects). If the job completes early, cancel the scheduled notification and fire an immediate one: "Your waste analysis is ready!"

Without this, batch mode is a graveyard of forgotten jobs.

---

## 4. The Micro-Decision Matrix

Here is what the user decides at every token touchpoint:

| Moment | Micro-Decision | Current UX | Needed UX |
|--------|---------------|------------|-----------|
| First open | "Do I care about this token number?" | 50 displayed, no explanation | Brief tooltip: "50 free scans to start" |
| Before first scan | "Instant or batch?" | Two cards, token costs shown | Add "savings" context line; highlight default |
| Tap analyze | "Do I trust this will work?" | Loading spinner | Show token deduction animation (coin fly) |
| Result screen | "Did I spend tokens?" | No feedback | "5 tokens used. 45 remaining." snackbar |
| 5th scan | "Am I running low?" | Balance still shows 50 (fake) or dropping (real) | Warning at 10 tokens: "~2 scans left today" |
| 10th scan | "What happens at 0?" | Unknown | Pre-emptive banner at 5 tokens |
| 11th scan at 0 | "How do I keep using this?" | Likely crash or raw error | Zero-balance bottom sheet with 4 options |
| Day 2 | "Do I come back?" | No token reason to return | Daily login bonus popup: "+2 tokens for returning" |
| Day 7 | "Is this app worth paying for?" | No Premium-token bridge | Premium pitch: "Never run out of daily scans" |

---

## 5. The Thing Most People Miss About This

**Most people think the token economy is about scarcity. It is not. It is about predictability.**

Users do not hate paying. They hate *surprise* paying. The current unenforced state is actually worse than enforcement because it trains users that the app is unpredictable. The token number is displayed but meaningless. The cost is shown but never felt. This creates a learned helplessness: "I do not know what this app costs, so I assume it is free until proven otherwise."

The thing most people miss: **The worst token economy is not a strict one or a generous one. It is an inconsistent one.** An app that sometimes charges and sometimes does not -- or displays a cost that never materializes -- trains users to ignore all economic signals. When you finally enforce, it feels like a bait-and-switch, not like a fair system starting.

If we enforce tokens, we must enforce them consistently from the first tap. If we do not enforce them, we must remove the display entirely. The middle ground -- "show but do not charge" -- is the most user-hostile option. It is a lie that users learn to distrust.

The real operational question is not "Should tokens deduct?" It is "Does the user understand the rules of the game before they start playing?" Right now, the rules are invisible, the scoreboard is broken, and the referee is asleep. Fix the rules first. Then turn on the deductions.

---

*End of memo. Next: Synthesize with Strategist and Executioner outputs for consensus roadmap.*
