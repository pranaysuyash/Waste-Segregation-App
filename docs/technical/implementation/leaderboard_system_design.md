# Technical Design: Extensible Multi-Type Leaderboards

## 1. Firestore Structure

### 1.1. Collections
- **Option 1: Single Collection with Type Fields**
  - Collection: `leaderboards`
  - Each document represents a leaderboard entry for a user, with fields for period, metric, category, group, etc.
- **Option 2: Composite Collections**
  - Collections named as `leaderboard_{period}_{metric}` (e.g., `leaderboard_weekly_points`)
  - Each collection contains documents for users for that leaderboard type.

**Recommendation:** Start with Option 1 for flexibility and easier querying, migrate to Option 2 if performance/scalability requires.

### 1.2. Document Schema
See the "Example Document Structure" in `docs/technical/data_storage/firestore_schema.md`.

### 1.3. Indexing
- Composite indexes on (`leaderboardType`, `period`, `category`, `groupId`, `region`)
- Indexes for top-N queries (e.g., order by `points` desc, filter by `period` and `leaderboardType`)

---

## 2. Backend Logic

### 2.1. Entry Updates
- When a user's relevant metric changes (points, analyses, etc.), update all relevant leaderboard documents for that user.
- For period-based leaderboards, update the document for the current period (e.g., week, month).
- For category/group leaderboards, update the relevant document(s) as well.

### 2.2. Periodic Resets & Archival
- Use Cloud Functions (or scheduled jobs) to:
  - Archive and reset daily, weekly, and monthly leaderboards.
  - Move old period data to an archive collection or mark as inactive.
  - Optionally, calculate and store final ranks for each period.

### 2.3. Aggregation
- For metrics like streaks or achievements, aggregate data from user profiles or activity logs.
- For category leaderboards, sum points/analyses per category.

---

## 3. Service Layer (Flutter/Dart)

### 3.1. LeaderboardService
- Methods to fetch:
  - Top N users for a given leaderboard type/period/metric/category/group.
  - Current user's entry and rank for any leaderboard type.
  - Historical leaderboard data (for archived periods).
- Methods to update:
  - User's leaderboard entries when metrics change.

### 3.2. Provider Layer
- Riverpod providers for:
  - Current leaderboard type/period/metric (state)
  - Top N entries for selected leaderboard
  - Current user's entry and rank for selected leaderboard
  - UI state for loading, error, and refresh

---

## 4. UI/UX Design

### 4.1. Navigation
- Tabs or dropdowns to switch between:
  - Periods (All-Time, Monthly, Weekly, Daily)
  - Metrics (Points, Analyses, Streaks, Achievements)
  - Categories (Plastic, Food Waste, etc.)
  - Groups (Family, Region, Friends)

### 4.2. Display
- Show user's current rank and stats even if not in top N.
- Highlight top performers with badges or special styling.
- Show period countdowns for time-based leaderboards.
- Provide tooltips/info for each leaderboard type.

### 4.3. Gamification
- Display earned badges/rewards for top ranks in each leaderboard.
- Show progress toward next rank or badge.

---

## 5. Gamification & Rewards
- Define badge/reward logic for each leaderboard type and period.
- Store badge/reward history in user profile.
- Notify users when they achieve a new rank or badge.

---

## 6. Privacy & Security
- Allow users to opt out or anonymize their display.
- Only show non-sensitive info (displayName, photoUrl, rank, points).
- Implement anti-cheat logic (e.g., server-side validation, anomaly detection).

---

## 7. Migration & Backward Compatibility
- Migrate existing all-time leaderboard data to new schema.
- Ensure old clients can still read all-time leaderboard if needed.
- Provide migration scripts or Cloud Functions for data transformation.

---

## 8. Testing & Monitoring
- Unit and integration tests for service and provider logic.
- UI tests for leaderboard navigation and display.
- Monitor Firestore read/write costs and optimize queries as needed.

---

## 9. Documentation
- Update developer docs for new service/provider APIs.
- Update user docs for new leaderboard types and navigation.
- Document Firestore schema and index requirements.
- Reference: `docs/planning/roadmap/FUTURE_FEATURES_AND_ENHANCEMENTS.md`, `docs/technical/data_storage/firestore_schema.md`

---

**This technical design is the blueprint for future implementation of a robust, extensible leaderboard system.** 