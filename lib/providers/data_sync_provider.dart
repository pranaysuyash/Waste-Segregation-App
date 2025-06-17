import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/gamification_service.dart';
import '../services/storage_service.dart';
import '../services/community_service.dart';
import '../models/gamification.dart';
import '../models/waste_classification.dart';
import '../models/community_feed.dart';
import '../utils/waste_app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced provider that ensures all screens show consistent data
/// This solves the points synchronization issues across Home, Analytics, Community, and History screens
class DataSyncProvider extends ChangeNotifier {
  
  DataSyncProvider(
    this._gamificationService,
    this._storageService,
    this._communityService,
  ) {
    // Listen to gamification changes
    _gamificationService.addListener(_onGamificationChanged);
    
    // Perform initial sync
    _performInitialSync();
    
    // Schedule daily image refresh
    _scheduleDailyImageRefresh();
  }
  final GamificationService _gamificationService;
  final StorageService _storageService;
  final CommunityService _communityService;
  
  // Cached data that all screens can access
  UserPoints? _cachedPoints;
  int? _cachedClassificationCount;
  List<WasteClassification>? _cachedClassifications;
  GamificationProfile? _cachedProfile;
  List<CommunityFeedItem>? _cachedCommunityFeed;
  DateTime? _lastSyncTime;
  DateTime? _lastImageRefresh;
  bool _isSyncing = false;
  
  // Synchronization lock to prevent concurrent updates
  bool _isUpdating = false;
  
  @override
  void dispose() {
    _gamificationService.removeListener(_onGamificationChanged);
    super.dispose();
  }
  
  // Public getters for consistent data access
  UserPoints? get currentPoints => _cachedPoints;
  int? get classificationsCount => _cachedClassificationCount;
  List<WasteClassification>? get classifications => _cachedClassifications;
  GamificationProfile? get gamificationProfile => _cachedProfile;
  List<CommunityFeedItem>? get communityFeed => _cachedCommunityFeed;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  DateTime? get lastImageRefresh => _lastImageRefresh;
  
  /// MAIN SYNC METHOD - This resolves all points inconsistency issues
  Future<void> forceSyncAllData() async {
    if (_isSyncing || _isUpdating) {
      WasteAppLogger.debug('Data sync already in progress, skipping duplicate request', {
        'is_syncing': _isSyncing,
        'is_updating': _isUpdating
      });
      return;
    }
    
    _isSyncing = true;
    _isUpdating = true;
    notifyListeners();
    
    try {
      WasteAppLogger.info('Starting comprehensive data sync', null, null, {
        'sync_type': 'full_data_sync',
        'cached_classifications_count': _cachedClassificationCount,
        'cached_points': _cachedPoints?.total
      });
      
      // 1. Force complete gamification sync first (this fixes points issues)
      await _gamificationService.syncGamificationData();
      WasteAppLogger.info('Gamification sync complete', null, null, {'sync_step': 1});
      
      // 2. Refresh cached classifications
      _cachedClassifications = await _storageService.getAllClassifications();
      _cachedClassificationCount = _cachedClassifications?.length ?? 0;
      WasteAppLogger.info('Classifications refreshed', null, null, {
        'sync_step': 2,
        'classifications_count': _cachedClassificationCount
      });
      
      // 3. Get latest profile and points (now guaranteed to be consistent)
      _cachedProfile = await _gamificationService.getProfile(forceRefresh: true);
      _cachedPoints = _cachedProfile?.points;
      WasteAppLogger.info('Profile refreshed', null, null, {
        'sync_step': 3,
        'total_points': _cachedPoints?.total
      });
      
      // 4. Sync community data to remove stale entries
      await _syncCommunityData();
      WasteAppLogger.info('Community data synced', null, null, {'sync_step': 4});
      
      // 5. Refresh images if needed (daily check)
      await _checkAndRefreshImages();
      WasteAppLogger.info('Image refresh checked', null, null, {'sync_step': 5});
      
      // 6. Update last sync time
      _lastSyncTime = DateTime.now();
      
      WasteAppLogger.info('Data sync complete', null, null, {
        'final_points': _cachedPoints?.total,
        'final_classifications_count': _cachedClassificationCount,
        'sync_duration_ms': DateTime.now().difference(_lastSyncTime!).inMilliseconds
      });
      
    } catch (e, stackTrace) {
      WasteAppLogger.severe('Data sync failed', e, stackTrace, {
        'sync_type': 'full_data_sync',
        'cached_classifications_count': _cachedClassificationCount,
        'cached_points': _cachedPoints?.total
      });
      // Don't rethrow - we want the app to continue working even if sync fails
    } finally {
      _isSyncing = false;
      _isUpdating = false;
      notifyListeners();
    }
  }
  
  /// Sync community data and ensure it's fresh
  Future<void> _syncCommunityData() async {
    try {
      await _communityService.initCommunity();
      
      // Sync with real user data
      if (_cachedClassifications != null) {
        final userProfile = await _storageService.getCurrentUserProfile();
        await _communityService.syncWithUserData(_cachedClassifications!, userProfile);
      }
      
      // Refresh community feed cache
      _cachedCommunityFeed = await _communityService.getFeedItems();
      
    } catch (e) {
      WasteAppLogger.warning('Community sync error', e, null, {
        'classifications_count': _cachedClassifications?.length,
        'community_feed_count': _cachedCommunityFeed?.length
      });
    }
  }
  
  /// Get live data for a specific screen with automatic refresh
  Future<Map<String, dynamic>> getScreenData(String screenName) async {
    WasteAppLogger.debug('Getting screen data', {
      'screen_name': screenName,
      'has_cached_points': _cachedPoints != null,
      'has_cached_profile': _cachedProfile != null,
      'last_sync_minutes_ago': _lastSyncTime != null ? DateTime.now().difference(_lastSyncTime!).inMinutes : null
    });
    
    // Force sync if data is stale (more than 1 minute old) or if no data exists
    final now = DateTime.now();
    final needsSync = _lastSyncTime == null || 
                     now.difference(_lastSyncTime!).inMinutes > 1 ||
                     _cachedPoints == null ||
                     _cachedProfile == null;
    
    if (needsSync) {
      WasteAppLogger.info('Data is stale, forcing sync', null, null, {
        'screen_name': screenName,
        'last_sync_minutes_ago': _lastSyncTime != null ? DateTime.now().difference(_lastSyncTime!).inMinutes : null,
        'has_cached_points': _cachedPoints != null,
        'has_cached_profile': _cachedProfile != null
      });
      await forceSyncAllData();
    }
    
    return {
      'points': _cachedPoints?.toJson(),
      'profile': _cachedProfile?.toJson(),
      'classificationsCount': _cachedClassificationCount,
      'classifications': _cachedClassifications?.map((c) => c.toJson()).toList(),
      'communityFeed': _cachedCommunityFeed?.map((f) => f.toJson()).toList(),
      'lastUpdated': _lastSyncTime?.toIso8601String(),
      'screenName': screenName,
    };
  }
  
  /// Lightweight refresh - just update points without full sync
  Future<void> quickRefresh() async {
    if (_isUpdating) return;
    
    try {
      _cachedProfile = await _gamificationService.getProfile();
      _cachedPoints = _cachedProfile?.points;
      notifyListeners();
    } catch (e) {
      WasteAppLogger.warning('Quick refresh error', e, null, {
        'action': 'quick_refresh_profile_points'
      });
    }
  }
  
  /// Check if data needs syncing based on age
  bool get needsSync {
    if (_lastSyncTime == null) return true;
    final now = DateTime.now();
    return now.difference(_lastSyncTime!).inMinutes > 2; // 2 minute threshold
  }
  
  void _onGamificationChanged() async {
    // When gamification data changes, refresh our cache
    await _refreshCache();
  }
  
  Future<void> _performInitialSync() async {
    // Don't block the UI on initial sync
    unawaited(Future.microtask(() async {
      await forceSyncAllData();
    }));
  }
  
  Future<void> _refreshCache() async {
    if (_isUpdating) return;
    
    try {
      _cachedProfile = await _gamificationService.getProfile();
      _cachedPoints = _cachedProfile?.points;
      
      // Also refresh classification count periodically
      if (_lastSyncTime == null || 
          DateTime.now().difference(_lastSyncTime!).inMinutes > 5) {
        final classifications = await _storageService.getAllClassifications();
        _cachedClassificationCount = classifications.length;
      }
      
      notifyListeners();
    } catch (e) {
      WasteAppLogger.severe('Cache refresh error', e, null, {
        'operation': 'cache_refresh',
        'action': 'continue_with_existing_cache'
      });
    }
  }
  
  /// Force refresh community feeds
  Future<void> refreshCommunityFeeds() async {
    try {
      WasteAppLogger.info('Refreshing community feeds', null, null, {
        'operation': 'community_feeds_refresh'
      });
      await _communityService.initCommunity();
      
      if (_cachedClassifications != null) {
        final userProfile = await _storageService.getCurrentUserProfile();
        await _communityService.syncWithUserData(_cachedClassifications!, userProfile);
      }
      
      // Refresh cached feed
      _cachedCommunityFeed = await _communityService.getFeedItems();
      notifyListeners();
      
      WasteAppLogger.info('🌍 Community feeds refreshed successfully');
    } catch (e) {
      WasteAppLogger.severe('🌍 Error refreshing community feeds: $e');
    }
  }
  
  /// Daily image refresh functionality
  void _scheduleDailyImageRefresh() {
    // Check if image refresh is needed on app startup
    // Use unawaited to avoid blocking initialization
    unawaited(_checkAndRefreshImages());
  }
  
  /// Check and refresh images if needed (daily)
  Future<void> _checkAndRefreshImages() async {
    try {
      final now = DateTime.now();
      
      final classifications = _cachedClassifications ?? await _storageService.getAllClassifications();
      final updatedClassifications = <WasteClassification>[];

      for (final classification in classifications) {
        if (classification.imageUrl != null) {
            // No-op, image URL is sufficient
        }
      }
      
      // Batch update classifications if any were changed
      if (updatedClassifications.isNotEmpty) {
        for (final updatedClassification in updatedClassifications) {
          await _storageService.saveClassification(updatedClassification);
        }
        
        // Refresh local cache
        _cachedClassifications = await _storageService.getAllClassifications();
      }
      
      // Update last refresh time in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastImageRefresh', now.toIso8601String());
      
      _lastImageRefresh = now;
      
    } catch (e) {
      WasteAppLogger.severe('🖼️ Image refresh error: $e');
    }
  }
  
  /// Manual force refresh of all images
  Future<void> forceRefreshAllImages() async {
    try {
      WasteAppLogger.info('🖼️ Force refreshing all images...');
      _lastImageRefresh = null; // Reset to force refresh
      await _checkAndRefreshImages();
      notifyListeners();
    } catch (e) {
      WasteAppLogger.severe('🖼️ Error force refreshing images: $e');
    }
  }
  
  /// Get status of image refresh
  Map<String, dynamic> getImageRefreshStatus() {
    return {
      'lastRefresh': _lastImageRefresh?.toIso8601String(),
      'needsRefresh': _lastImageRefresh == null || 
                     DateTime.now().difference(_lastImageRefresh!).inDays >= 1,
      'isRefreshing': _isSyncing,
    };
  }
}
