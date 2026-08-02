# Domain Model Relationships — ReLoop Waste Segregation App

> **Date**: August 1, 2026
> **Purpose**: Visualize how core domain entities connect across the classification, policy, society, and pricing layers

---

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CLASSIFICATION LAYER                               │
│                                                                              │
│  ┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐   │
│  │  Layer0Router    │      │ Classification   │      │  BackendProxy    │   │
│  │  (barcode,       │─────▶│ Pipeline         │─────▶│  Provider        │   │
│  │   color hist.)   │      │ (routing logic)  │      │  (cloud API)     │   │
│  └──────────────────┘      └────────┬─────────┘      └────────┬─────────┘   │
│                                     │                          │              │
│                                     ▼                          ▼              │
│                          ┌─────────────────────────────────────────────┐     │
│                          │         WasteClassification                 │     │
│                          │  (central domain object)                    │     │
│                          │                                             │     │
│                          │  • itemName, category, subCategory          │     │
│                          │  • confidence, calibratedConfidence         │     │
│                          │  • classificationLayer (runtime)            │     │
│                          │  • analysisSource (cloud_primary, etc.)     │     │
│                          │  • modelRoute, modelSelectionStrategy       │     │
│                          │  • source (barcode:xxx, color_histogram)    │     │
│                          │  • disposalInstructions                     │     │
│                          │  • localRegulations (per-city rules)        │     │
│                          │  • localPolicyDecision ─────────────────────┼──┐  │
│                          │  • societyOverride (applied) ───────────────┼──┼──┼──┐
│                          │  • isOfflineHint                           │  │  │  │
│                          └─────────────────────────────────────────┬───┘  │  │  │
│                                                                   │      │  │  │
└───────────────────────────────────────────────────────────────────│──────│──│──┘
                                                                    │      │  │
                                                                    │      │  │
┌───────────────────────────────────────────────────────────────────│──────│──│──┐
│                           POLICY ENGINE LAYER                     │      │  │  │
│                                                                   │      │  │  │
│  ┌──────────────────┐      ┌──────────────────┐      ┌─────────┐│      │  │  │
│  │  Region String   │─────▶│  LocalPolicy     │      │  Local  ││      │  │  │
│  │  ("Bangalore")   │      │  Engine          │◀─────│  Policy ││      │  │  │
│  └──────────────────┘      │                  │      │  Rule   ││      │  │  │
│                            │  • resolvePlugin()│      │  Pack   ││      │  │  │
│                            │  • applyRules()   │      │  (city) ││      │  │  │
│                            │  • checkConfidence│      └─────────┘│      │  │  │
│                            │  • applySociety() │                 │      │  │  │
│                            └────────┬─────────┘                 │      │  │  │
│                                     │                            │      │  │  │
│                                     ▼                            │      │  │  │
│                          ┌──────────────────────────────────────┐│      │  │  │
│                          │       LocalPolicyDecision            ││      │  │  │
│                          │                                      ││      │  │  │
│                          │  • wasPolicyApplied                  ││      │  │  │
│                          │  • pluginUsed (CityPlugin ref)       ││◀─────┘  │  │
│                          │  • complianceStatus                  ││         │  │
│                          │  • violations, warnings              ││         │  │
│                          │  • confidenceState                   ││         │  │
│                          │  • policyPackId                      ││         │  │
│                          │  • societyMetadata ──────────────────┼┼─────────┼──┘
│                          │  • societyConflicts ─────────────────┼┼─────────┘
│                          │  • provenance                        ││
│                          └──────────────────────────────────────┘│
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┘
│
│  SOCIETY OVERRIDE LAYER
│
│  ┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
│  │  CityPlugin      │◀─────│ SocietyPolicy    │      │  RuleOverride    │
│  │  (bbmp_bangalore)│      │ Override         │─────▶│  (per category)  │
│  │                  │      │                  │      │                  │
│  │  • pluginId      │      │  • societyId     │      │  • categoryKey   │
│  │  • rulePacks     │      │  • societyName   │      │  • overrideType  │
│  │  • authority     │      │  • basePluginId ─┼──────│  • newValue      │
│  │  • sourceTitle   │      │  • overrides[] ──┼──┐   │  • description   │
│  │  • localName     │      │                  │  │   └──────────────────┘
│  │  • trustTier     │      └──────────────────┘  │
│  │  • lastVerified  │                            │
│  │  • nextReviewDue │                            │
│  └──────────────────┘                            │
│                                                  │
│  ┌──────────────────────────────────────────────┐│
│  │  RuleOverrideType                            ││
│  │                                              ││
│  │  • binColor          (different bin)         ││
│  │  • collectionFrequency (different schedule) ││
│  │  • disposalMethod    (different process)     ││
│  │  • collectionLocation (different drop-off)   ││
│  │  • bannedItem        (prohibited by society) ││
│  │  • customInstruction (society-specific)      ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  ┌──────────────────────────────────────────────┐│
│  │  SocietyConflict                             ││
│  │                                              ││
│  │  Detected when:                              ││
│  │  1. basePluginId ≠ resolved city plugin      ││
│  │  2. Both city + society define same category ││
│  │                                              ││
│  │  Surfaced in: LocalPolicyDecision            ││
│  │  Displayed in: PolicyProvenanceCard          ││
│  └──────────────────────────────────────────────┘│
│                                                  │
└──────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                         PRICING & TOKEN ECONOMY LAYER                       │
│                                                                              │
│  ┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐   │
│  │  RemoteConfig    │─────▶│ DynamicPricing   │      │  AiService       │   │
│  │  Service         │      │ Service          │◀─────│  (classifyImage) │   │
│  │                  │      │                  │      │                  │   │
│  │  • ai_model_     │      │  • model pricing │      │  • calls cloud   │   │
│  │    pricing       │      │  • batch discount│      │    API per       │   │
│  │  • spending_     │      │  • daily/weekly/ │      │    classification│   │
│  │    budgets       │      │    monthly       │      │  • tracks costs  │   │
│  │  • token_limits  │      │    spending      │      │    via guardrails│   │
│  │  • cost_guard_   │      │  • budget        │      └────────┬─────────┘   │
│  │    rails_enabled │      │    utilization   │               │              │
│  └──────────────────┘      │  • shouldEnforce │               │              │
│                            │    BatchMode()   │               │              │
│                            └────────┬─────────┘               │              │
│                                     │                          │              │
│                                     ▼                          │              │
│                          ┌──────────────────────────────────────┘              │
│                          │                                                     │
│                          │  ┌──────────────────┐                              │
│                          │  │ CostGuardrail    │                              │
│                          │  │ Service          │                              │
│                          │  │                  │                              │
│                          │  • batch mode      │                              │
│                          │    enforcement     │                              │
│                          │  • budget alerts   │                              │
│                          │  • cost analytics  │                              │
│                          │  • threshold 80%   │                              │
│                          │  • stream updates  │                              │
│                          │  └────────┬─────────┘                              │
│                          │           │                                        │
│                          │           ▼                                        │
│                          │  ┌──────────────────┐      ┌──────────────────┐   │
│                          │  │ AnalysisSpeed    │      │  TokenService    │   │
│                          │  │ (enum)           │◀─────│                  │   │
│                          │  │                  │      │  • earnTokens()  │   │
│                          │  │ • batch (1 token)│      │  • spendTokens() │   │
│                          │  │ • instant        │      │  • canAfford()   │   │
│                          │  │   (5 tokens)     │      │  • enforcement   │   │
│                          │  └──────────────────┘      │    kill switch   │   │
│                          │                             │  • server-side   │   │
│                          │                             │    validation    │   │
│                          │                             └────────┬─────────┘   │
│                          │                                      │             │
│                          │                                      ▼             │
│                          │                             ┌──────────────────┐   │
│                          │                             │  TokenWallet     │   │
│                          │                             │  (embedded in    │   │
│                          │                             │   UserProfile)   │   │
│                          │                             │                  │   │
│                          │                             │  • balance       │   │
│                          │                             │  • totalEarned   │   │
│                          │                             │  • totalSpent    │   │
│                          │                             │  • lastUpdated   │   │
│                          │                             │  • dailyConver-  │   │
│                          │                             │    sionsUsed     │   │
│                          │                             │  • canAfford()   │   │
│                          │                             └────────┬─────────┘   │
│                          │                                      │             │
│                          │                                      ▼             │
│                          │                             ┌──────────────────┐   │
│                          │                             │  TokenTransaction│   │
│                          │                             │  (history)       │   │
│                          │                             │                  │   │
│                          │                             │  • id, delta     │   │
│                          │                             │  • type (earn/   │   │
│                          │                             │    spend/convert/│   │
│                          │                             │    bonus/refund) │   │
│                          │                             │  • timestamp     │   │
│                          │                             │  • description   │   │
│                          │                             │  • reference     │   │
│                          │                             │    (classif. ID) │   │
│                          │                             └──────────────────┘   │
│                          │                                                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Relationship Summary

### Classification & Policy Relationships

| Relationship | Type | Description |
|--------------|------|-------------|
| **WasteClassification → LocalPolicyDecision** | 1:1 | Every classification carries its policy decision |
| **WasteClassification → SocietyPolicyOverride** | 1:0..1 | Classification may have society override applied |
| **LocalPolicyDecision → CityPlugin** | N:1 | Decision references the resolved city plugin |
| **LocalPolicyDecision → LocalPolicyRulePack** | N:1 | Decision references the applied rule pack |
| **SocietyPolicyOverride → CityPlugin** | N:1 | Society override is anchored to a city plugin via basePluginId |
| **SocietyPolicyOverride → RuleOverride** | 1:N | Society override contains multiple rule overrides |
| **CityPlugin → LocalPolicyRulePack** | 1:N | City plugin has multiple rule packs |

### Pricing & Token Economy Relationships

| Relationship | Type | Description |
|--------------|------|-------------|
| **AiService → DynamicPricingService** | 1:1 | AiService calculates cost per classification API call |
| **AiService → CostGuardrailService** | 1:1 | AiService checks if instant/batch is allowed per budget |
| **AiService → TokenService** | 1:1 | AiService triggers token spending after classification |
| **CostGuardrailService → DynamicPricingService** | 1:1 | Guardrails depend on pricing data for cost calculations |
| **CostGuardrailService → AnalysisSpeed** | 1:1 | Guardrails determine recommended analysis speed |
| **TokenService → TokenWallet** | 1:1 | TokenService reads/writes wallet balance |
| **TokenService → TokenTransaction** | 1:N | TokenService creates transaction records per operation |
| **UserProfile → TokenWallet** | 1:0..1 | Wallet is embedded in user profile (Hive typeId 20) |
| **DynamicPricingService → RemoteConfigService** | 1:1 | Pricing loaded from Firebase Remote Config |
| **WasteClassification → TokenWallet** | 1:0..1 | Indirect: classification triggers token spend via TokenService |

---

## Data Flow

### Classification → Policy Flow

```
1. Image captured
2. Layer0Router: barcode/color_histogram → Layer0Result
3. ClassificationPipeline: routes to appropriate layer
4. EnhancedAiApiService: calls cloud API
5. WasteClassification created with classificationLayer, analysisSource, source
6. LocalPolicyEngine.resolve(region) → CityPlugin
7. LocalPolicyEngine.evaluate(classification, plugin) → LocalPolicyDecision
8. If society profile exists → SocietyPolicyService.fetch() → SocietyPolicyOverride
9. Society overrides applied as additive deltas
10. Conflicts detected and recorded
11. WasteClassification.localPolicyDecision = decision
12. Result screen displays via PolicyProvenanceCard
```

### Classification → Pricing Flow

```
1. User selects AnalysisSpeed (instant or batch)
2. TokenService.canAffordAnalysis(speed) checks:
   a. If enforcement disabled → always true (Phase 0)
   b. If enforcement enabled → checks TokenWallet.balance
3. CostGuardrailService.getRecommendedAnalysisSpeed() checks:
   a. If batch mode enforced (budget 80%+ used) → forces batch
   b. Otherwise → allows user's choice
4. DynamicPricingService.calculateCost() computes:
   a. Model-specific input/output token costs
   b. Batch discount (50% off if batch mode)
5. After classification:
   a. TokenService.spendAnalysisTokens() deducts from TokenWallet
   b. DynamicPricingService.recordSpending() updates budget tracking
   c. CostGuardrailService checks thresholds → may enforce batch mode
6. TokenTransaction recorded with reference to classification ID
```

### Society Override Resolution Flow

```
1. User's society profile loaded from Firestore
2. SocietyPolicyOverride fetched (cached locally)
3. Validate basePluginId == resolved CityPlugin.pluginId
4. If mismatch → SocietyConflict recorded, override skipped
5. If match → RuleOverride objects applied:
   - For each RuleOverride in overrides[]:
     - Find matching categoryKey in city rules
     - Apply overrideType + newValue as delta
     - Record in LocalPolicyDecision.societyMetadata
6. SocietyConflict if both city + society define same category
7. All decisions surfaced in PolicyProvenanceCard UI
```

---

## Key Code Anchors

### Classification & Policy Entities

| Entity | File | Class/Enum |
|--------|------|------------|
| WasteClassification | `lib/models/waste_classification.dart` | `WasteClassification` |
| LocalPolicyDecision | `lib/services/local_policy_engine.dart` | `LocalPolicyDecision` |
| SocietyPolicyOverride | `lib/models/society_policy_override.dart` | `SocietyPolicyOverride` |
| CityPlugin | `lib/services/city_policy_data.dart` | `CityPlugin` |
| RuleOverride | `lib/models/society_policy_override.dart` | `RuleOverride` |
| RuleOverrideType | `lib/models/society_policy_override.dart` | `RuleOverrideType` |
| LocalPolicyRulePack | `lib/services/local_policy_rule_packs.dart` | `LocalPolicyRulePack` |
| ComplianceStatus | `lib/services/local_policy_engine.dart` | `ComplianceStatus` |
| PolicyProvenanceCard | `lib/widgets/result_screen/policy_provenance_card.dart` | `PolicyProvenanceCard` |

### Pricing & Token Economy Entities

| Entity | File | Class/Enum |
|--------|------|------------|
| TokenWallet | `lib/models/token_wallet.dart` | `TokenWallet` (Hive typeId 20) |
| TokenTransaction | `lib/models/token_wallet.dart` | `TokenTransaction` (Hive typeId 21) |
| TokenTransactionType | `lib/models/token_wallet.dart` | `TokenTransactionType` (enum) |
| AnalysisSpeed | `lib/models/token_wallet.dart` | `AnalysisSpeed` (enum: batch, instant) |
| TokenService | `lib/services/token_service.dart` | `TokenService` |
| DynamicPricingService | `lib/services/dynamic_pricing_service.dart` | `DynamicPricingService` |
| CostGuardrailService | `lib/services/cost_guardrail_service.dart` | `CostGuardrailService` |
| CostAlert | `lib/services/cost_guardrail_service.dart` | `CostAlert` |
| UserProfile (tokenWallet field) | `lib/models/user_profile.dart` | `UserProfile.tokenWallet` |

### Providers (Dependency Injection)

| Provider | File | Type |
|----------|------|------|
| tokenWalletProvider | `lib/providers/token_providers.dart` | `FutureProvider<TokenWallet?>` |
| dynamicPricingServiceProvider | `lib/providers/cost_management_providers.dart` | `Provider<DynamicPricingService>` |
| costGuardrailServiceProvider | `lib/providers/cost_management_providers.dart` | `Provider<CostGuardrailService>` |

---

## Pricing Configuration Constants

| Constant | Value | Location |
|----------|-------|----------|
| Welcome bonus | 50 tokens | `TokenService.welcomeBonus`, `TokenWallet.newUser()` |
| Daily login bonus | 2 tokens | `TokenService.dailyLoginBonus` |
| Batch cost | 1 token | `AnalysisSpeed.batch.cost` |
| Instant cost | 5 tokens | `AnalysisSpeed.instant.cost` |
| Premium instant discount | 50% | `TokenService.premiumInstantDiscountPercent` |
| Points-to-token rate | 100 pts = 1 token | `TokenService.pointsToTokenRate` |
| Max daily conversions | 5 | `TokenService.maxDailyConversions` |
| Enforcement kill switch | OFF (default) | `TokenService.enableTokenEnforcement = false` |
| Batch discount rate | 50% | `DynamicPricingService._defaultPricing['batch_discount_rate']` |
| Budget threshold | 80% | `CostGuardrailService._budgetThresholdPercentage` |
| Daily budget | $5.00 | `DynamicPricingService._defaultBudgets['daily_budget']` |
| Weekly budget | $30.00 | `DynamicPricingService._defaultBudgets['weekly_budget']` |
| Monthly budget | $100.00 | `DynamicPricingService._defaultBudgets['monthly_budget']` |

---

## Confidence Gating Matrix

| Confidence Range | Policy Enforcement | Society Override | UI Display |
|------------------|-------------------|------------------|------------|
| ≥ 0.70 | Full enforcement (violations) | Applied if valid | Green: "Policy Applied" |
| 0.50 – 0.70 | Demoted to warnings | Applied if valid | Yellow: "Policy Gated" |
| < 0.50 | Skipped entirely | Skipped | Gray: "Policy Not Applied" |

---

## Token Economy State Machine

```
┌─────────────────────────────────────────────────────────────────┐
│                    Token Economy State Machine                    │
│                                                                  │
│  ┌──────────────┐     canAfford()      ┌──────────────────┐     │
│  │  Idle        │──────────────────────▶│  Analysis Ready  │     │
│  │  (balance N) │                       │  (balance ≥ cost)│     │
│  └──────┬───────┘                       └────────┬─────────┘     │
│         │                                        │               │
│         │ !canAfford()                          │ spendTokens()  │
│         ▼                                        ▼               │
│  ┌──────────────┐     Phase 0 skip      ┌──────────────────┐     │
│  │  Insufficient│──────────────────────▶│  Analysis Runs   │     │
│  │  Tokens      │  (enforcement off)    │  (tokens NOT     │     │
│  │              │                       │   deducted)      │     │
│  └──────────────┘                       └────────┬─────────┘     │
│                                                  │               │
│                                                  │ Record cost   │
│                                                  ▼               │
│                                         ┌──────────────────┐     │
│                                         │  Wallet Updated  │     │
│                                         │  (balance N-cost)│     │
│                                         └──────────────────┘     │
│                                                                  │
│  Earn Paths:                                                     │
│  • Daily login → +2 tokens                                       │
│  • Challenge complete → +30 tokens                               │
│  • Badge earned → +25 tokens                                     │
│  • Points conversion → 100 pts = 1 token (max 5/day)            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Cross-References

- **CONTEXT.md** — Canonical domain terminology
- **ADR-004** — Society Policy Override architecture
- **ADR-005** — Classification Pipeline architecture
- **docs/architecture/CURRENT_AI_ARCHITECTURE.md** — Full pipeline documentation
- **docs/exploration/REGION_RULES_AND_CITY_EXPANSION_MAP.md** — City plugin expansion plan
- **docs/exploration/TOKEN_ECONOMY_AND_PRICING_COHERENCE.md** — Token economy coherence analysis
- **docs/exploration/COMPETITOR_PRICING_STRATEGIES_2026-08-01.md** — Competitor pricing research
