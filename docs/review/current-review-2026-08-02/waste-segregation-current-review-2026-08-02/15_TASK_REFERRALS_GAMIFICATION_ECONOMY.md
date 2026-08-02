> **Repository:** `pranaysuyash/Waste-Segregation-App`
>
> **Reviewed branch:** `main`
>
> **Reviewed commit:** `e48a66bd6c9116e939a3eddfa5cc48c5d2171e6a`
>
> **Commit timestamp:** 2026-08-02T03:40:33Z
>
> **Review timestamp:** 2026-08-02
>
> **Previous review baseline:** `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Evidence limit:** Static remote-code inspection plus current official/public-source research. The latest GitHub commit exposes no combined status checks or associated workflow runs, so build, test, deployment and runtime claims remain unverified until the release-proof task is executed.

# Task: Referrals, Gamification and Economic Integrity

## Priority

P2, except any current token/reward exploit discovered in Task 04 becomes P0.

## Objective

Separate harmless engagement feedback from server-authoritative economic/ranking value and repair exactly-once referral rewards.

## Referral defects

- uniqueness check outside transaction;
- no reward to referrer;
- stats query wrong collection;
- code collision not handled;
- latest redeemer overwrites code document field;
- no App Check/rate limiting;
- no abuse/device/account-age rules.

## Referral model

```text
referral_codes/{code}
referral_redemptions/{redeemerUid}
reward_ledger/{sourceEventId}
```

Transaction:

1. validate code;
2. reject self;
3. create unique redeemer record;
4. credit new user;
5. credit referrer;
6. write immutable rewards;
7. increment aggregate projection.

One idempotency/source key.

## Gamification boundary

Client-local visual events may include:

- animation;
- local progress preview;
- non-economic acknowledgement.

Server authority required for:

- points used in leaderboard;
- token conversion;
- premium trial;
- referral reward;
- challenge prize;
- public reputation.

Client submits action evidence; server validates and projects totals.

## Anti-abuse

- App Check;
- account age;
- verified email/phone if proportionate;
- device/account velocity;
- duplicate image/content;
- repeated correction farming;
- referral graph anomalies;
- reward caps;
- reversal;
- audit.

## Token economy decision

Before expanding:

- is token friction necessary for user value?
- does it obscure AI cost control?
- can free quota plus paid account be simpler?
- does it create app-store virtual-currency obligations?

Keep cost-control accounting internal even if user-facing tokens are removed.

## Acceptance criteria

- referral credits both parties exactly once;
- stats match ledger;
- race/concurrency tests pass;
- client cannot create ranking/economic value;
- reversals are possible;
- abuse controls and privacy trade-offs documented;
- token economy has an explicit keep/cut decision.

## Anything else?

Referral growth is premature until activation and retention are measured. Repair integrity, then keep it feature-flagged.
