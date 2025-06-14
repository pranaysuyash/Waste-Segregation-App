# Short-Term Implementation Tasks
*Created: December 2024*

This document outlines concrete implementation tasks for the next 1-6 months based on the user flows prioritization framework and technical debt cleanup requirements.

## 🎯 Tier 1: Quick Wins (Next 1-2 Sprints)

### 1. Batch Scan Mode (RICE Score: 192)
**Priority: HIGH | Effort: 3 weeks | Impact: High user engagement**

#### Technical Tasks:
- [ ] **Backend API Enhancement**
  - [ ] Create bulk classification endpoint `/api/classify/batch`
  - [ ] Implement batch processing with queue management
  - [ ] Add rate limiting for bulk requests
  - [ ] Update API documentation

- [ ] **Mobile App Implementation**
  - [ ] Add long-press gesture detection on Scan FAB
  - [ ] Create multi-capture camera interface
  - [ ] Implement image gallery with 10-item limit
  - [ ] Add batch progress indicator
  - [ ] Create results grid view component
  - [ ] Implement individual result detail modal

- [ ] **State Management**
  - [ ] Create `BatchScanProvider` with Riverpod
  - [ ] Implement batch scan state machine
  - [ ] Add error handling for partial failures
  - [ ] Implement retry mechanism for failed items

- [ ] **UI/UX Components**
  - [ ] Design batch capture overlay
  - [ ] Create results grid with thumbnails
  - [ ] Add batch action buttons (save all, retry failed)
  - [ ] Implement loading states and animations

#### Acceptance Criteria:
- [ ] Users can capture up to 10 items in one session
- [ ] Batch processing completes within 30 seconds
- [ ] Individual results can be viewed and corrected
- [ ] Failed items can be retried individually
- [ ] Batch results are saved to history with grouping

### 2. Smart Notification Bundles (RICE Score: 252)
**Priority: HIGH | Effort: 2 weeks | Impact: Reduced churn**

#### Technical Tasks:
- [ ] **Notification System Redesign**
  - [ ] Implement notification bundling logic
  - [ ] Create digest scheduling system
  - [ ] Add notification preference storage
  - [ ] Implement smart timing algorithms

- [ ] **User Preferences**
  - [ ] Create notification settings screen
  - [ ] Add digest vs real-time toggle
  - [ ] Implement notification preview functionality
  - [ ] Add do-not-disturb time settings

- [ ] **Backend Services**
  - [ ] Update push notification service
  - [ ] Implement notification batching
  - [ ] Add user preference sync
  - [ ] Create notification analytics

#### Acceptance Criteria:
- [ ] Users can choose between digest and real-time notifications
- [ ] Digest notifications are sent at optimal times
- [ ] Notification opt-out rate decreases by 40%
- [ ] Users can preview notification styles

### 3. History Filter & Search (RICE Score: 189)
**Priority: HIGH | Effort: 2 weeks | Impact: Better UX**

#### Technical Tasks:
- [ ] **Search Implementation**
  - [ ] Add search functionality to history provider
  - [ ] Implement text-based search across classifications
  - [ ] Add date range filtering
  - [ ] Create category-based filters

- [ ] **UI Components**
  - [ ] Create search bar component
  - [ ] Design filter drawer/modal
  - [ ] Add search result highlighting
  - [ ] Implement filter chips

- [ ] **Performance Optimization**
  - [ ] Implement search result pagination
  - [ ] Add search result caching
  - [ ] Optimize database queries
  - [ ] Add search analytics

#### Acceptance Criteria:
- [ ] Users can search history by item name or category
- [ ] Date range filtering works correctly
- [ ] Search results load within 2 seconds
- [ ] Filter combinations work as expected

### 4. Offline Scan Queue (RICE Score: 84)
**Priority: MEDIUM | Effort: 4 weeks | Impact: Reliability**

#### Technical Tasks:
- [ ] **Offline Storage**
  - [ ] Implement local queue with Hive/SQLite
  - [ ] Add image compression for offline storage
  - [ ] Create sync mechanism for when online
  - [ ] Implement conflict resolution

- [ ] **Queue Management**
  - [ ] Create offline scan provider
  - [ ] Add queue status indicators
  - [ ] Implement retry logic with exponential backoff
  - [ ] Add manual sync trigger

- [ ] **UI Indicators**
  - [ ] Add offline mode banner
  - [ ] Create queued item badges
  - [ ] Show sync progress
  - [ ] Add network status indicator

#### Acceptance Criteria:
- [ ] Scans work completely offline
- [ ] Queued items sync automatically when online
- [ ] Users can see queue status and progress
- [ ] No data loss during offline periods

## 🚀 Tier 2: Strategic Investments (Next 3-6 Months)

### 5. Daily Eco-Quests (RICE Score: 101)
**Priority: HIGH | Effort: 5 weeks | Impact: Engagement**

#### Technical Tasks:
- [ ] **Quest System Backend**
  - [ ] Design quest data model
  - [ ] Create quest generation algorithms
  - [ ] Implement progress tracking
  - [ ] Add reward distribution system

- [ ] **Mobile Implementation**
  - [ ] Create quest display components
  - [ ] Implement progress tracking UI
  - [ ] Add quest completion animations
  - [ ] Create reward claim interface

- [ ] **Gamification Integration**
  - [ ] Connect with existing badge system
  - [ ] Implement streak tracking
  - [ ] Add social sharing features
  - [ ] Create leaderboard integration

#### Acceptance Criteria:
- [ ] Daily quests are generated based on user behavior
- [ ] Progress is tracked in real-time
- [ ] Completion triggers reward animations
- [ ] Quests drive 30% increase in daily scans

### 6. Voice Classification (RICE Score: 48)
**Priority: MEDIUM | Effort: 6 weeks | Impact: Accessibility**

#### Technical Tasks:
- [ ] **Voice Processing**
  - [ ] Integrate speech-to-text service
  - [ ] Add multilingual support (EN/HI/KAN)
  - [ ] Implement voice command parsing
  - [ ] Add text-to-speech for responses

- [ ] **UI/UX Design**
  - [ ] Create voice overlay interface
  - [ ] Add waveform visualization
  - [ ] Implement language picker
  - [ ] Design accessibility features

- [ ] **Classification Integration**
  - [ ] Connect voice input to AI classifier
  - [ ] Add confidence scoring for voice inputs
  - [ ] Implement fallback to camera scan
  - [ ] Add voice training data collection

#### Acceptance Criteria:
- [ ] Voice recognition works in 3 languages
- [ ] Classification accuracy matches camera scans
- [ ] Hands-free operation is fully functional
- [ ] Accessibility compliance is achieved

## 🛠 Technical Debt Cleanup Tasks

### 1. Riverpod State Management Issues

#### A. Missing Await Statements (15 issues)
- [ ] **Audit Phase**
  - [ ] Run grep search: `grep -R "ref.read(.*Async).*;" -n lib/`
  - [ ] Document all un-awaited async calls
  - [ ] Categorize by risk level (high/medium/low)

- [ ] **Fix Implementation**
  - [ ] Add await statements to async provider calls
  - [ ] Convert void methods to Future<void> where needed
  - [ ] Add proper error handling with try-catch blocks
  - [ ] Update method signatures and callers

- [ ] **Linting Setup**
  - [ ] Enable `await_only_futures` lint rule
  - [ ] Enable `cascade_invocations` lint rule
  - [ ] Add custom lint rules for provider usage
  - [ ] Update CI to fail on new violations

#### B. BuildContext Lifecycle Safety (10 issues)
- [ ] **Audit Phase**
  - [ ] Identify all async methods using BuildContext
  - [ ] Find Navigator/Dialog calls after async gaps
  - [ ] Document context usage patterns

- [ ] **Fix Implementation**
  - [ ] Add mounted checks before context usage
  - [ ] Move UI logic to providers where possible
  - [ ] Use AsyncValue.when() for navigation triggers
  - [ ] Implement proper error boundaries

- [ ] **Best Practices**
  - [ ] Create context safety guidelines
  - [ ] Add code review checklist items
  - [ ] Create reusable context-safe utilities
  - [ ] Document patterns in team wiki

### 2. Deep Widget Tree Refactoring

#### Extract Reusable Components (3 large screens)
- [ ] **Home Screen Refactoring**
  - [ ] Extract `HomeHeader` component
  - [ ] Create `ImpactMeter` widget
  - [ ] Build `ActionButtons` component
  - [ ] Design `ChallengesCarousel` widget

- [ ] **History Screen Refactoring**
  - [ ] Extract `HistoryListItem` component
  - [ ] Create `FilterDrawer` widget
  - [ ] Build `SearchBar` component
  - [ ] Design `ImpactSummary` widget

- [ ] **Profile Screen Refactoring**
  - [ ] Extract `ProfileHeader` component
  - [ ] Create `AchievementGrid` widget
  - [ ] Build `SettingsSection` component
  - [ ] Design `StatsCard` widget

#### Component Testing
- [ ] **Unit Tests**
  - [ ] Write widget tests for each extracted component
  - [ ] Add golden tests for visual regression
  - [ ] Create interaction tests for buttons/gestures
  - [ ] Add accessibility tests

- [ ] **Integration Tests**
  - [ ] Test component composition
  - [ ] Verify data flow between components
  - [ ] Test error states and edge cases
  - [ ] Add performance benchmarks

### 3. Unused Code Cleanup (60 issues)

#### Static Analysis Setup
- [ ] **Tooling Configuration**
  - [ ] Enable strict dart analyze settings
  - [ ] Configure dart_code_metrics
  - [ ] Set up unused code detection
  - [ ] Add CI enforcement

#### Cleanup Process
- [ ] **Phase 1: Low-Risk Cleanup (20 issues)**
  - [ ] Remove unused imports
  - [ ] Delete unused variables
  - [ ] Clean up unused parameters
  - [ ] Remove dead code branches

- [ ] **Phase 2: Medium-Risk Cleanup (25 issues)**
  - [ ] Remove unused methods
  - [ ] Delete unused classes
  - [ ] Clean up unused assets
  - [ ] Remove deprecated code

- [ ] **Phase 3: High-Risk Review (15 issues)**
  - [ ] Review potentially unused complex code
  - [ ] Move questionable code to deprecated folder
  - [ ] Document removal decisions
  - [ ] Plan gradual removal timeline

## 📊 Sprint Planning

### Sprint 1 (2 weeks): Foundation
- [ ] Smart Notification Bundles implementation
- [ ] History Filter & Search basic functionality
- [x] Phase 1 unused code cleanup (started - removed _activeChallenges field)
- [x] Missing await statements fixes (started - fixed data_sync_provider.dart)

### Sprint 2 (2 weeks): Core Features
- [ ] Batch Scan Mode implementation
- [ ] BuildContext lifecycle safety fixes
- [ ] Home Screen component extraction
- [ ] Phase 2 unused code cleanup

### Sprint 3 (2 weeks): Polish & Testing
- [ ] Offline Scan Queue implementation
- [ ] Remaining component extractions
- [ ] Comprehensive testing suite
- [ ] Phase 3 unused code review

### Sprint 4-6 (6 weeks): Strategic Features
- [ ] Daily Eco-Quests implementation
- [ ] Voice Classification development
- [ ] Advanced testing and optimization
- [ ] Documentation and team training

## 🎯 Success Metrics

### Technical Debt Reduction
- [ ] Zero missing await statement violations
- [ ] Zero BuildContext lifecycle issues
- [ ] 50% reduction in widget tree depth
- [ ] 60% reduction in unused code warnings

### Feature Implementation
- [ ] 25% increase in daily active users (Batch Scan)
- [ ] 40% reduction in notification opt-outs (Smart Bundles)
- [ ] 30% improvement in history usage (Filter & Search)
- [ ] 15% increase in offline usage (Offline Queue)

### Code Quality
- [ ] 90%+ test coverage for new components
- [ ] All lint rules passing in CI
- [ ] Documentation updated for all changes
- [ ] Team training completed on new patterns

## 📋 Definition of Done

For each task:
- [ ] Implementation completed and tested
- [ ] Code review passed
- [ ] Unit tests written and passing
- [ ] Integration tests updated
- [ ] Documentation updated
- [ ] Accessibility verified
- [ ] Performance benchmarked
- [ ] Deployed to staging environment
- [ ] QA testing completed
- [ ] Product owner approval received

---

## 📈 Progress Tracking

### Technical Debt Fixes Completed
- ✅ **Data Sync Provider**: Fixed missing await statement in `_scheduleDailyImageRefresh()` method
- ✅ **Result Screen**: Added mounted checks for BuildContext safety in `_saveResult()` and `_shareResult()` methods  
- ✅ **Modern Home Screen**: Removed unused `_activeChallenges` field and cleaned up related code
- ✅ **Analysis Options**: Enhanced linting rules with `await_only_futures` and `cascade_invocations`

### Issues Identified by Analyzer
- **Total Issues**: 360 (as of last run)
- **Missing Await Statements**: 15+ identified across multiple files
- **BuildContext Safety**: 10+ issues with context usage after async gaps
- **Unused Code**: 60+ unused elements, fields, and methods
- **Cascade Invocations**: 50+ opportunities for code style improvements

### Next Priority Fixes
1. **lib/screens/settings_screen.dart**: Multiple missing await statements (lines 1051, 1069, 1090, etc.)
2. **lib/widgets/navigation_wrapper.dart**: Missing await statements (lines 304, 319)
3. **lib/services/ai_service.dart**: Remove unused `_imageToBase64` method
4. **lib/screens/new_modern_home_screen.dart**: Remove multiple unused helper methods

*This document should be updated weekly with progress and any scope changes.* 