# Remaining Roadmap Items - Final 3%

**Status**: 97% Complete - Final Polish Items  
**Priority**: Medium (Production-ready without these)  
**Estimated Time**: 1-2 weeks  
**Date**: June 19, 2025

## 🎯 Overview

The Waste Segregation App has achieved 97% completion of the comprehensive roadmap. The remaining 3% consists of polish items that enhance user experience but don't block production deployment.

---

## 📋 TODO Items

### 1. Home Header Batch Jobs Card
**Priority**: High  
**Estimated Time**: 4-6 hours  
**File**: `lib/screens/ultra_modern_home_screen.dart`

**Current State**: Home header shows points/tokens chips but no batch job tracking  
**Expected**: "Your batch jobs · 2 processing · done in ~38 min" card

**Implementation Tasks**:
- [ ] Create `BatchJobsHeaderCard` widget
- [ ] Add stream provider for user's active batch jobs
- [ ] Calculate estimated completion time based on queue position
- [ ] Add navigation to JobQueueScreen on tap
- [ ] Show confetti animation when jobs complete

**Code Location**:
```dart
// Add to _buildStatChips() in ultra_modern_home_screen.dart
Widget _buildBatchJobsCard(BuildContext context) {
  return StreamBuilder<List<AiJob>>(
    stream: ref.watch(userAiJobsProvider(userId)).value,
    builder: (context, snapshot) {
      final activeJobs = snapshot.data?.where((job) => job.isProcessing).toList() ?? [];
      if (activeJobs.isEmpty) return SizedBox.shrink();
      
      return _buildStatChip(
        '${activeJobs.length} processing',
        'Batch Jobs',
        Icons.schedule,
        onTap: () => Navigator.pushNamed(context, '/job-queue'),
      );
    },
  );
}
```

---

### 2. "Need it sooner?" Upgrade Button
**Priority**: High  
**Estimated Time**: 6-8 hours  
**File**: `lib/screens/job_queue_screen.dart`

**Current State**: Job cards show status but no upgrade functionality  
**Expected**: Upgrade button for queued batch jobs to convert to instant processing

**Implementation Tasks**:
- [ ] Add upgrade button to queued job cards
- [ ] Implement `upgradeBatchToInstant()` function
- [ ] Check token balance before upgrade (needs 4 additional tokens)
- [ ] Update job priority and mode in Firestore
- [ ] Show confirmation dialog with cost breakdown
- [ ] Handle insufficient tokens gracefully

**Code Location**:
```dart
// Add to _buildJobCard() in job_queue_screen.dart
if (job.status == AiJobStatus.queued && job.speed == AnalysisSpeed.batch) {
  const SizedBox(height: 12),
  Row(
    children: [
      Icon(Icons.flash_on, size: 16, color: Colors.orange),
      const SizedBox(width: 8),
      Expanded(
        child: Text('Need it sooner?', 
          style: GoogleFonts.inter(fontSize: 12, color: Colors.orange.shade700)),
      ),
      TextButton(
        onPressed: () => _showUpgradeDialog(context, job),
        child: Text('Upgrade (4 ⚡)', 
          style: TextStyle(color: Colors.orange.shade700)),
      ),
    ],
  ),
}
```

---

### 3. Dynamic Pricing Implementation
**Priority**: Medium  
**Estimated Time**: 4-6 hours  
**File**: `lib/widgets/analysis_speed_selector.dart`

**Current State**: RemoteConfigService exists but pricing is hardcoded  
**Expected**: Token prices driven by Firebase Remote Config

**Implementation Tasks**:
- [ ] Create `DynamicPricingService` class
- [ ] Add Remote Config keys: `batch_token_price`, `instant_token_price`
- [ ] Update AnalysisSpeedSelector to fetch dynamic prices
- [ ] Add fallback to hardcoded prices if Remote Config fails
- [ ] Cache prices locally to avoid repeated fetches

**Code Location**:
```dart
// New file: lib/services/dynamic_pricing_service.dart
class DynamicPricingService {
  static Future<Map<String, int>> getCurrentPrices() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.fetchAndActivate();
    
    return {
      'batch': remoteConfig.getInt('batch_token_price') ?? 1,
      'instant': remoteConfig.getInt('instant_token_price') ?? 5,
      'conversion_rate': remoteConfig.getInt('points_to_token_rate') ?? 100,
    };
  }
}
```

---

### 4. Points to Tokens Conversion
**Priority**: Medium  
**Estimated Time**: 8-10 hours  
**Files**: Multiple (TokenService, UI components)

**Current State**: Mentioned in docs but not implemented  
**Expected**: Optional one-way conversion (100 points → 1 token, max 5/day)

**Implementation Tasks**:
- [ ] Add conversion tracking to TokenWallet model
- [ ] Implement daily conversion limit logic
- [ ] Create conversion UI in TokenWallet screen
- [ ] Add Cloud Function for atomic conversion
- [ ] Add conversion history tracking
- [ ] Create conversion confirmation dialog

**Code Location**:
```dart
// Add to lib/services/token_service.dart
Future<bool> convertPointsToTokens(int pointsToConvert) async {
  const int CONVERSION_RATE = 100; // 100 points = 1 token
  const int DAILY_LIMIT = 5;       // max 5 tokens per day
  
  final tokensFromPoints = pointsToConvert ~/ CONVERSION_RATE;
  final todayConverted = await getTodayConversions();
  
  if (todayConverted + tokensFromPoints > DAILY_LIMIT) {
    throw ConversionLimitException();
  }
  
  // Atomic transaction implementation
}
```

---

### 5. Observability Dashboard
**Priority**: Low  
**Estimated Time**: 12-16 hours  
**Files**: New admin dashboard components

**Current State**: getBatchStats endpoint exists but no dashboard  
**Expected**: Admin monitoring interface for batch processing

**Implementation Tasks**:
- [ ] Create admin dashboard screen
- [ ] Add batch processing metrics visualization
- [ ] Implement cost monitoring charts
- [ ] Add queue health indicators
- [ ] Create alerting for unusual patterns
- [ ] Add BigQuery integration for historical data

**Code Location**:
```dart
// New file: lib/screens/admin/batch_monitoring_screen.dart
class BatchMonitoringScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Batch Processing Monitor')),
      body: Column(
        children: [
          _buildStatsCards(),
          _buildQueueHealthChart(),
          _buildCostMonitoringChart(),
          _buildRecentJobsList(),
        ],
      ),
    );
  }
}
```

---

### 6. Daily Budget Cost Caps
**Priority**: Low  
**Estimated Time**: 6-8 hours  
**File**: `functions/src/cost-monitor.ts`

**Current State**: ApiCostManager foundation exists but not fully implemented  
**Expected**: Automated cost protection with budget alerts

**Implementation Tasks**:
- [ ] Implement daily spend calculation
- [ ] Add budget threshold monitoring (80% warning)
- [ ] Create auto-switch to batch-only mode
- [ ] Add admin alerting for budget overruns
- [ ] Implement cost projection algorithms
- [ ] Add Remote Config for budget settings

**Code Location**:
```typescript
// functions/src/cost-monitor.ts
export const dailyCostMonitor = onSchedule("every 24 hours", async () => {
  const today = new Date().toISOString().split('T')[0];
  const dailySpend = await calculateDailySpend(today);
  const budget = await getConfigValue('daily_budget_usd');
  
  if (dailySpend > budget * 0.8) { // 80% threshold
    await setGlobalConfig('force_batch_mode', true);
    await sendAlert(`Daily spend ${dailySpend} approaching budget ${budget}`);
  }
});
```

---

## 🚀 Implementation Strategy

### Phase 1: Core UX Improvements (Week 1)
1. Home Header Batch Jobs Card
2. "Need it sooner?" Upgrade Button
3. Dynamic Pricing Implementation

### Phase 2: Advanced Features (Week 2)
4. Points to Tokens Conversion
5. Observability Dashboard
6. Daily Budget Cost Caps

---

## 🎯 Success Criteria

### User Experience
- [ ] Users can see batch job status from home screen
- [ ] Users can upgrade batch jobs to instant processing
- [ ] Token prices can be adjusted without app updates
- [ ] Users can convert points to tokens when needed

### Operations
- [ ] Admin can monitor batch processing health
- [ ] Cost overruns are prevented automatically
- [ ] Historical data is available for analysis
- [ ] Alerts notify of system issues

---

## 📊 Impact Assessment

### Without These Items
- **Production Ready**: ✅ Yes
- **User Experience**: ⭐⭐⭐⭐ (Good)
- **Operational Visibility**: ⭐⭐⭐ (Basic)

### With These Items
- **Production Ready**: ✅ Yes
- **User Experience**: ⭐⭐⭐⭐⭐ (Excellent)
- **Operational Visibility**: ⭐⭐⭐⭐⭐ (Enterprise-grade)

---

## 🔗 Related Documentation

- [Comprehensive Roadmap Status Report](../status/COMPREHENSIVE_ROADMAP_STATUS_REPORT_JUNE_19_2025.md)
- [Batch Processing System Deployment](../fixes/BATCH_PROCESSING_SYSTEM_DEPLOYMENT_COMPLETE.md)
- [Token Micro-Economy Foundation](../features/TOKEN_MICRO_ECONOMY_FOUNDATION.md)

---

**Next Steps**: 
1. Prioritize items based on user feedback
2. Implement in phases as outlined above
3. Monitor production metrics to validate improvements
4. Iterate based on real user behavior 