# Next Phase Tasks - Token Economy Implementation

**Phase**: 1 - Cost & Scalability (Token Economy Infrastructure)  
**Timeline**: 2-3 weeks  
**Goal**: Cut OpenAI costs by 40-50% while adding freemium upsell path

## Immediate Tasks (Before Phase 1)

### 🔧 CI Pipeline Cleanup
**Priority**: High  
**Estimated Time**: 1-2 hours

1. **Address Secrets Detection** 
   - Review flagged files for any exposed API keys or credentials
   - Update `.gitignore` if needed
   - Clean any historical exposure

2. **Fix Security Checks**
   - Review security scan results
   - Address any vulnerability findings
   - Update dependencies if required

3. **Resolve markdown-lint Issues**
   - Fix remaining markdown formatting issues in documentation
   - Follow project's markdown style guide
   - Ensure all new documentation passes linting

## Phase 1 Implementation Tasks

### 1.1 Token Wallet Infrastructure 
**Priority**: High  
**Estimated Time**: 2-3 days  
**Dependencies**: CI cleanup complete

#### Tasks:
- [ ] **Design Firestore Schema**
  ```
  /users/{uid}/wallet
  {
    "balance": 50,
    "dailyEarned": 2,
    "lastLoginBonus": "2025-06-25T00:00:00Z",
    "conversionCap": 5,
    "conversionsToday": 0,
    "lastConversion": null,
    "createdAt": "timestamp",
    "updatedAt": "timestamp"
  }
  ```

- [ ] **Create Firebase Security Rules**
  ```javascript
  // Wallet rules: read = owner, write = server or owner via Cloud Functions
  match /users/{userId}/wallet/{document} {
    allow read: if request.auth != null && request.auth.uid == userId;
    allow write: if request.auth != null && 
                   (request.auth.uid == userId || 
                    request.auth.token.serverRole == 'admin');
  }
  ```

- [ ] **Implement TokenService** (`lib/services/token_service.dart`)
  - `getBalance(String userId)` 
  - `spendTokens(String userId, int amount, String reason)`
  - `earnTokens(String userId, int amount, String reason)`
  - `getWalletHistory(String userId)`

- [ ] **Add Token Models** (`lib/models/token_wallet.dart`)
  - `TokenWallet` model with Hive serialization
  - `TokenTransaction` model for history tracking

### 1.2 Job Queue System
**Priority**: High  
**Estimated Time**: 1 week  
**Dependencies**: Token wallet infrastructure

#### Tasks:
- [ ] **Design AI Jobs Schema**
  ```
  /ai_jobs/{jobId}
  {
    "id": "job_abc123",
    "userId": "user_xyz",
    "imagePath": "gs://bucket/path/image.jpg",
    "status": "queued", // queued, processing, completed, failed
    "mode": "batch", // batch, instant
    "priority": 1, // 1=normal, 5=premium
    "createdAt": "timestamp",
    "processingStartedAt": null,
    "completedAt": null,
    "estimatedCompletion": "timestamp",
    "result": null,
    "error": null
  }
  ```

- [ ] **Enhance Cloud Functions** (`functions/src/index.ts`)
  - `createBatchJob(imageData, userId)` - Submit job to queue
  - `batchWorker()` - Scheduled function every 5 minutes
  - `checkBatchStatus()` - Monitor OpenAI Batch API progress
  - `processBatchResults()` - Handle completed batches

- [ ] **Integrate OpenAI Batch API**
  - Upload images to batch processing
  - Submit batch requests with custom metadata
  - Poll for completion status
  - Download and parse results

- [ ] **Add Job Tracking** (`lib/services/batch_job_service.dart`)
  - `createJob(imageFile, userId, priority)`
  - `getJobStatus(jobId)`  
  - `getUserJobs(userId)`
  - `upgradeJobToPriority(jobId, tokenCost)`

### 1.3 Speed Toggle UI
**Priority**: Medium  
**Estimated Time**: 2-3 days  
**Dependencies**: Token wallet, job queue

#### Tasks:
- [ ] **Create Speed Toggle Widget** (`lib/widgets/analysis_speed_toggle.dart`)
  ```dart
  class AnalysisSpeedToggle extends StatelessWidget {
    final bool isInstantMode;
    final int tokenBalance;
    final Function(bool) onChanged;
    
    // Cupertino sliding segmented control
    // Show token costs: Batch (1 ⚡) vs Instant (5 ⚡)
    // Disable instant if insufficient tokens
  }
  ```

- [ ] **Update Home Screen** (`lib/screens/ultra_modern_home_screen.dart`)
  - Add speed toggle above camera controls
  - Show current token balance
  - Handle mode selection logic

- [ ] **Modify Analysis Flow** (`lib/services/ai_service.dart`)
  - Add `AnalysisMode` enum (instant, batch)
  - Route to appropriate processing based on mode
  - Handle token deduction for instant mode

### 1.4 Remote Config Pricing Service
**Priority**: Medium  
**Estimated Time**: 1 day  
**Dependencies**: Basic token system

#### Tasks:
- [ ] **Setup Firebase Remote Config**
  ```json
  {
    "instant_token_cost": 5,
    "batch_token_cost": 1,
    "daily_login_bonus": 2,
    "points_to_token_rate": 100,
    "max_daily_conversions": 5,
    "batch_processing_enabled": true
  }
  ```

- [ ] **Create Pricing Service** (`lib/services/pricing_service.dart`)
  - `getInstantTokenCost()`
  - `getBatchTokenCost()`  
  - `getConversionRate()`
  - `isDynamicPricingEnabled()`

- [ ] **Update UI to Use Dynamic Pricing**
  - Speed toggle shows current costs
  - Conversion screen uses remote config rates
  - Admin can adjust pricing without app updates

### 1.5 Cost Guardrails
**Priority**: Medium  
**Estimated Time**: 1 day  
**Dependencies**: Pricing service

#### Tasks:
- [ ] **Daily Cost Monitoring** (Cloud Function)
  ```typescript
  export const dailyCostGuardrail = functions.pubsub
    .schedule('0 */6 * * *') // Every 6 hours
    .onRun(async () => {
      const todaySpend = await calculateDailySpend();
      const budget = await getRemoteConfig('daily_budget');
      
      if (todaySpend > budget * 0.8) {
        await enableForceBatchMode();
        await notifyAdmins(todaySpend, budget);
      }
    });
  ```

- [ ] **Force Batch Mode Implementation**
  - Override speed toggle when budget exceeded
  - Show user notification about cost management
  - Allow override for premium users only

### 1.6 Priority Upgrade Flow
**Priority**: Low  
**Estimated Time**: 2 days  
**Dependencies**: Job queue, token wallet

#### Tasks:
- [ ] **Upgrade Job Function** (Cloud Function)
  - Allow spending extra tokens to bump queued job to instant
  - Cost: 4 additional tokens (total 5 for instant processing)
  - Update job priority and processing queue

- [ ] **Upgrade UI** (`lib/screens/batch_jobs_screen.dart`)
  - Show "Upgrade to Instant" button for queued jobs
  - Display token cost and confirmation dialog
  - Real-time job status updates

## Testing & Quality Assurance

### Unit Tests Required
- [ ] **TokenService Tests** - All wallet operations
- [ ] **BatchJobService Tests** - Job lifecycle management  
- [ ] **PricingService Tests** - Remote config integration
- [ ] **SpeedToggle Widget Tests** - UI interactions and token validation

### Integration Tests Required  
- [ ] **End-to-End Batch Flow** - Image → Queue → Processing → Results
- [ ] **Token Economy Flow** - Earn → Spend → Balance tracking
- [ ] **Cost Guardrail Simulation** - Budget limits and force batch mode

### Performance Tests Required
- [ ] **Concurrent Job Creation** - Multiple users submitting simultaneously
- [ ] **Batch Processing Scale** - Large numbers of queued jobs
- [ ] **Token Transaction Load** - High-frequency wallet operations

## Success Metrics & Monitoring

### Implementation Metrics
- [ ] **Token Wallet**: 100% of operations are transactional and consistent
- [ ] **Job Queue**: <5 minute average processing start time
- [ ] **Speed Toggle**: >80% user adoption of batch mode
- [ ] **Cost Guardrails**: 0% budget overruns

### Business Metrics  
- [ ] **Cost Reduction**: 40-50% decrease in AI processing costs
- [ ] **User Engagement**: Increased classifications due to lower barriers
- [ ] **Revenue Opportunity**: Token purchasing and premium features

## Risk Mitigation

### Technical Risks
1. **OpenAI Batch API Limits** → Implement fallback to individual calls
2. **Firebase Quota Exceeded** → Add monitoring and auto-scaling
3. **Token Economy Exploits** → Implement rate limiting and validation

### Business Risks  
1. **User Confusion** → Comprehensive onboarding and clear UX
2. **Cost Explosion** → Daily guardrails and spending caps
3. **Feature Adoption** → Gradual rollout with opt-out mechanisms

## Phase 1 Completion Checklist

- [ ] All token economy infrastructure implemented
- [ ] Batch processing fully functional with OpenAI integration
- [ ] Speed toggle UI deployed and user-tested
- [ ] Remote config pricing system operational
- [ ] Cost guardrails active and monitored
- [ ] Comprehensive test suite passing
- [ ] Documentation updated for new features
- [ ] Performance benchmarks established
- [ ] Ready for Phase 2: Enhanced AI Analysis v2.0

---

**Next Session Focus**: Begin with CI cleanup, then start Token Wallet Infrastructure implementation following this task list.