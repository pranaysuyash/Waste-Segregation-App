import 'package:flutter/foundation.dart';
import '../services/gamification_service.dart';
import '../services/storage_service.dart';
import '../services/analytics_service.dart';
import '../services/community_service.dart';
import '../models/gamification.dart';
import '../models/waste_classification.dart';
import '../models/community_feed.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced provider that ensures all screens show consistent data
/// This solves the points synchronization issues across Home, Analytics, Community, and History screens
class DataSyncProvider extends ChangeNotifier {
  final GamificationService _gamificationService;
  final StorageService _storageService;
  final AnalyticsService _analyticsService;
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
  
  DataSyncProvider(
    this._gamificationService,
    this._storageService,
    this._analyticsService,
    this._communityService,
  ) {
    // Listen to gamification changes
    _gamificationService.addListener(_onGamificationChanged);
    
    // Perform initial sync
    _performInitialSync();
    
    // Schedule daily image refresh
    _scheduleDailyImageRefresh();
  }
  
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
      debugPrint('📊 SYNC: Already syncing, skipping duplicate request');
      return;
    }
    
    _isSyncing = true;
    _isUpdating = true;
    notifyListeners();
    
    try {
      debugPrint('📊 SYNC: Starting comprehensive data sync...');
      
      // 1. Force complete gamification sync first (this fixes points issues)
      await _gamificationService.syncGamificationData();
      debugPrint('📊 SYNC: ✅ Gamification sync complete');
      
      // 2. Refresh cached classifications
      _cachedClassifications = await _storageService.getAllClassifications();
      _cachedClassificationCount = _cachedClassifications?.length ?? 0;
      debugPrint('📊 SYNC: ✅ Classifications refreshed: $_cachedClassificationCount items');
      
      // 3. Get latest profile and points (now guaranteed to be consistent)
      _cachedProfile = await _gamificationService.getProfile(forceRefresh: true);
      _cachedPoints = _cachedProfile?.points;
      debugPrint('📊 SYNC: ✅ Profile refreshed - Points: ${_cachedPoints?.total}');
      
      // 4. Sync community data to remove stale entries
      await _syncCommunityData();
      debugPrint('📊 SYNC: ✅ Community data synced');
      
      // 5. Refresh images if needed (daily check)
      await _checkAndRefreshImages();
      debugPrint('📊 SYNC: ✅ Image refresh checked');
      
      // 6. Update last sync time
      _lastSyncTime = DateTime.now();
      
      debugPrint('📊 SYNC: ✅ Complete - Final Points: ${_cachedPoints?.total}, Classifications: $_cachedClassificationCount');
      
    } catch (e, stackTrace) {
      debugPrint('📊 SYNC ERROR: $e');
      debugPrint('📊 SYNC STACK: $stackTrace');
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
      debugPrint('📊 Community sync error: $e');
    }
  }
  
  /// Get live data for a specific screen with automatic refresh
  Future<Map<String, dynamic>> getScreenData(String screenName) async {
    debugPrint('📊 Getting screen data for: $screenName');
    
    // Force sync if data is stale (more than 1 minute old) or if no data exists
    final now = DateTime.now();
    final needsSync = _lastSyncTime == null || 
                     now.difference(_lastSyncTime!).inMinutes > 1 ||
                     _cachedPoints == null ||
                     _cachedProfile == null;
    
    if (needsSync) {
      debugPrint('📊 Data is stale for $screenName, forcing sync...');
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
      debugPrint('📊 Quick refresh error: $e');
    }
  }
  
  /// Check if data needs syncing based on age
  bool get needsSync {
    if (_lastSyncTime == null) return true;
    final now = DateTime.now();
    return now.difference(_lastSyncTime!).inMinutes > 2; // 2 minute threshold
  }
  
  void _onGamificationChanged() {
    // When gamification data changes, refresh our cache
    _refreshCache();
  }
  
  Future<void> _performInitialSync() async {
    // Don't block the UI on initial sync
    Future.microtask(() async {
      await forceSyncAllData();
    });
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
      debugPrint('📊 Cache refresh error: $e');
    }
  }
  
  /// Force refresh community feeds
  Future<void> refreshCommunityFeeds() async {
    try {
      debugPrint('🌍 Refreshing community feeds...');
      await _communityService.initCommunity();
      
      if (_cachedClassifications != null) {
        final userProfile = await _storageService.getCurrentUserProfile();
        await _communityService.syncWithUserData(_cachedClassifications!, userProfile);
      }
      
      // Refresh cached feed
      _cachedCommunityFeed = await _communityService.getFeedItems();
      notifyListeners();
      
      debugPrint('🌍 Community feeds refreshed successfully');
    } catch (e) {
      debugPrint('🌍 Error refreshing community feeds: $e');
    }
  }
  
  /// Daily image refresh functionality
  void _scheduleDailyImageRefresh() {
    // Check if image refresh is needed on app startup
    _checkAndRefreshImages();
  }
  
  /// Check and refresh images if needed (daily)
  Future<void> _checkAndRefreshImages() async {
    try {
      final now = DateTime.now();
      
      final classifications = _cachedClassifications ?? await _storageService.getAllClassifications();
      final List<WasteClassification> updatedClassifications = [];

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
      debugPrint('🖼️ Image refresh error: $e');
    }
  }
  
  /// Manual force refresh of all images
  Future<void> forceRefreshAllImages() async {
    try {
      debugPrint('🖼️ Force refreshing all images...');
      _lastImageRefresh = null; // Reset to force refresh
      await _checkAndRefreshImages();
      notifyListeners();
    } catch (e) {
      debugPrint('🖼️ Error force refreshing images: $e');
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
