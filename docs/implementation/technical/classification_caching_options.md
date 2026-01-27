# Classification Caching Implementation Options

## Overview
This document outlines various approaches to implementing image classification caching in the Waste Segregation application. The goal is to reduce API calls, improve response times, and ensure consistent classification results for identical images.

## Problem Statement
Currently, the application sends every captured image to the AI classification API, even if identical images have been processed before. This leads to:
- Increased API costs
- Slower response times for users
- Potentially inconsistent results for the same waste item
- Unnecessary bandwidth usage
- Reduced offline capabilities

## Implementation Options

### Option 1: Local (Device-Only) Hive Cache
**Description:**
Store classification results in a local Hive database with image hashes as keys.

**Implementation:**
1. Generate SHA-256 hash of image data before API call
2. Check local Hive box for existing results with that hash
3. Return cached results if found; otherwise query API and cache results

**Pros:**
- Simple implementation
- No additional backend requirements
- Fast local lookup
- Works offline after initial classification
- Minimal changes to existing codebase
- Zero additional infrastructure costs

**Cons:**
- Cache limited to individual devices
- No sharing of classification data between users
- Cache lost if app is uninstalled

**Estimated Effort:** Low (1-2 days)

### Option 2: Firestore-Based Global Cache
**Description:**
Use Firebase Firestore to store classification results that can be shared across all app users.

**Implementation:**
1. Generate SHA-256 hash of image data
2. Query Firestore collection for matching hash
3. Return cached results if found; otherwise query API
4. Store new classification results in Firestore

**Pros:**
- Shared classification data across all users
- Consistent results across the platform
- Greater reduction in API calls as user base grows
- Cache persists across app reinstalls

**Cons:**
- Requires Firestore setup and management
- Network requests still required for cache checks
- Potential Firestore costs as database grows
- More complex implementation
- Requires internet connection for cache lookup

**Estimated Effort:** Medium (3-5 days)

### Option 3: Hybrid Approach (Local + Cloud)
**Description:**
Use both local Hive cache and Firestore, with local cache as first lookup and periodic sync with cloud.

**Implementation:**
1. Check local Hive cache first using image hash
2. If not found locally, check Firestore
3. If not in Firestore, call API and update both caches
4. Periodically sync new local cache entries to Firestore
5. Periodically fetch popular/common items from Firestore to local cache

**Pros:**
- Fast local lookups for repeat classifications
- Offline functionality for previously classified items
- Community benefit from shared classifications
- Optimal reduction in API calls
- Graceful degradation when offline

**Cons:**
- Highest implementation complexity
- Cache consistency challenges between local and cloud
- Requires sync management logic
- Combined maintenance of two caching systems

**Estimated Effort:** High (7-10 days)

### Option 4: SQLite with LRU Cache Policy
**Description:**
Use SQLite database with a Least Recently Used (LRU) cache eviction policy to manage the cache size.

**Implementation:**
1. Store classifications in SQLite database with image hash as key
2. Implement LRU tracking for cache entries
3. Limit cache size and evict least recently used items
4. Index database for fast lookups

**Pros:**
- More structured storage than Hive
- Better control over cache size
- Optimized for limited device storage
- No cloud dependencies or costs

**Cons:**
- More complex than simple Hive implementation
- Requires additional cache management logic
- Still limited to individual devices
- Potential performance overhead from SQL operations

**Estimated Effort:** Medium (2-4 days)

## Cost Analysis

| Implementation Option | Development Cost | Infrastructure Cost | Maintenance Cost |
|----------------------|------------------|---------------------|------------------|
| Local Hive Cache     | Low              | None                | Low              |
| Firestore Cache      | Medium           | Low-Medium          | Medium           |
| Hybrid Approach      | High             | Low-Medium          | High             |
| SQLite with LRU      | Medium           | None                | Medium           |

## Recommendation

**For immediate implementation:** Option 1 (Local Hive Cache)
- Provides significant benefits with minimal implementation effort
- Zero additional infrastructure costs
- Can be extended to Option 3 in the future if needed

**For long-term solution:** Option 3 (Hybrid Approach)
- Best user experience and API cost reduction
- Balances online/offline capabilities
- Community benefit from shared classifications

## Implementation Path
1. Start with Local Hive Cache (Option 1) as Phase 1
2. Monitor performance and cache hit rates
3. If warranted by usage patterns and growth, expand to Hybrid Approach (Option 3) as Phase 2

## Technical Considerations
- Image hash generation must be consistent across devices
- Cache invalidation strategy should be considered for all options
- Privacy implications of storing user classifications should be addressed
- Image preprocessing (resize, normalization) should occur before hashing
- Consider compressing or storing only essential parts of API responses