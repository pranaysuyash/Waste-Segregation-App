import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends ChangeNotifier {
  // static const String _removeAdsFeatureId = 'remove_ads'; // Unused field removed
  
  bool _hasPremium = false;
  
  // TODO: ADMOB CONFIGURATION REQUIRED
  // ================================
  // 1. Create AdMob account at https://admob.google.com
  // 2. Create new app in AdMob console
  // 3. Generate real ad unit IDs for production
  // 4. Update android/app/src/main/AndroidManifest.xml with AdMob App ID
  // 5. Update ios/Runner/Info.plist with AdMob App ID
  // 6. Replace test IDs below with production IDs before release
  
  // Ad unit IDs - CURRENTLY USING TEST IDs
  static const Map<String, String> _bannerAdUnitIds = {
    // TODO: Replace with your actual banner ad unit IDs from AdMob console
    'android': 'ca-app-pub-3940256099942544/6300978111', // TEST ID - REPLACE
    'ios': 'ca-app-pub-3940256099942544/2934735716',     // TEST ID - REPLACE
  };
  
  static const Map<String, String> _interstitialAdUnitIds = {
    // TODO: Replace with your actual interstitial ad unit IDs from AdMob console
    'android': 'ca-app-pub-3940256099942544/1033173712', // TEST ID - REPLACE
    'ios': 'ca-app-pub-3940256099942544/4411468910',     // TEST ID - REPLACE
  };
  
  // TODO: Add reward ad unit IDs when implementing reward ads
  // static const Map<String, String> _rewardAdUnitIds = {
  //   'android': 'ca-app-pub-3940256099942544/5224354917', // TEST ID
  //   'ios': 'ca-app-pub-3940256099942544/1712485313',     // TEST ID
  // };
  
  // Ad state tracking
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoading = false;
  DateTime? _lastInterstitialAdTime;
  int _classificationsSinceLastAd = 0;
  
  // Ad context management - FIXED: Prevent notifyListeners during build
  bool _isInClassificationFlow = false;
  bool _isInEducationalContent = false;
  bool _isInSettings = false;
  
  bool _isInitialized = false;
  bool _isInitializing = false;
  int _classificationCount = 0;
  
  BannerAd? _bannerAd;
  Widget? _cachedBannerWidget;
  String? _currentBannerAdKey;
  
  // Getters
  bool get isInitialized => _isInitialized;
  
  bool get shouldShowAds => !kIsWeb && 
         !_hasPremium &&
         !_isInClassificationFlow && 
         !_isInEducationalContent && 
         !_isInSettings;
  
  bool get canShowInterstitialAd {
    if (_lastInterstitialAdTime == null) return true;
    return DateTime.now().difference(_lastInterstitialAdTime!).inMinutes >= 5;
  }
  
  // Set premium status
  void setPremiumStatus(bool hasPremium) {
    if (_hasPremium != hasPremium) {
      _hasPremium = hasPremium;
      // Use post-frame callback to avoid calling notifyListeners during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          notifyListeners();
        }
      });
    }
  }
  
  // Check if the service is still mounted (not disposed)
  bool get mounted => !_disposed;
  bool _disposed = false;
  
  // Initialize the ad service
  Future<void> initialize() async {
    if (kIsWeb) {
      _isInitialized = true;
      return; // Skip ad initialization on web
    }
    
    if (_isInitialized || _isInitializing || _disposed) return;
    
    _isInitializing = true;
    
    try {
      // TODO: Verify AdMob App ID is correctly configured in platform files
      // Android: android/app/src/main/AndroidManifest.xml
      // iOS: ios/Runner/Info.plist
      
      // Initialize MobileAds
      await MobileAds.instance.initialize();
      _isInitialized = true;
      
      // TODO: Add consent management for GDPR compliance
      // Consider implementing User Messaging Platform (UMP) SDK
      
      // Preload interstitial ad
      _loadInterstitialAd();
      
      // Preload banner ad
      _loadBannerAd();
      
      // Use post-frame callback to avoid calling notifyListeners during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('Error initializing ads: $e');
      // TODO: Implement proper error tracking/analytics
    } finally {
      _isInitializing = false;
    }
  }
  
  // Preload banner ad with performance optimization
  void _loadBannerAd() {
    if (kIsWeb || _bannerAd != null || _disposed) return;
    
    // Use microtask to avoid blocking the main thread
    scheduleMicrotask(() async {
      try {
        final adUnitId = Platform.isAndroid 
            ? _bannerAdUnitIds['android']! 
            : _bannerAdUnitIds['ios']!;
        
        // Use adaptive banner for better performance and responsive design
        final newBannerAd = BannerAd(
          adUnitId: adUnitId,
          size: AdSize.banner, // Changed from AdSize.smartBanner
          request: const AdRequest(
            keywords: ['waste', 'recycling', 'environment', 'sustainability'],
            contentUrl: 'https://wastewise.app',
          ),
          listener: BannerAdListener(
            onAdLoaded: (ad) {
              debugPrint('Banner ad loaded successfully');
              if (!_disposed) {
                // Schedule UI update after current frame to prevent jank
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_disposed) {
                    _bannerAd = ad as BannerAd;
                    // Clear cached widget to force recreation
                    _cachedBannerWidget = null;
                    _currentBannerAdKey = null;
                    
                    if (mounted) {
                      notifyListeners();
                    }
                  }
                });
              }
            },
            onAdFailedToLoad: (ad, error) {
              debugPrint('Banner ad failed to load: $error');
              ad.dispose();
              
              // Schedule cleanup after current frame
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!_disposed) {
                  _bannerAd = null;
                  _cachedBannerWidget = null;
                  _currentBannerAdKey = null;
                  
                  // Exponential backoff for retries
                  _retryBannerAdLoad();
                }
              });
            },
            onAdImpression: (ad) {
              debugPrint('Banner ad impression');
              // Track ad impression analytics here
            },
            onAdClicked: (ad) {
              debugPrint('Banner ad clicked');
              // Track ad click analytics here
            },
          ),
        );
        
        // Load ad asynchronously to prevent main thread blocking
        await newBannerAd.load();
      } catch (e) {
        debugPrint('Error creating banner ad: $e');
        // Schedule retry after error
        if (!_disposed) {
          _retryBannerAdLoad();
        }
      }
    });
  }
  
  int _bannerRetryCount = 0;
  static const int _maxBannerRetries = 3;
  
  void _retryBannerAdLoad() {
    if (_bannerRetryCount >= _maxBannerRetries || _disposed) {
      _bannerRetryCount = 0;
      return;
    }
    
    _bannerRetryCount++;
    final delay = Duration(seconds: _bannerRetryCount * 30); // 30s, 60s, 90s
    
    Future.delayed(delay, () {
      if (!_disposed) {
        _loadBannerAd();
      }
    });
  }
  
  // Load interstitial ad with performance optimization
  void _loadInterstitialAd() {
    if (kIsWeb || _isInterstitialAdLoading || _interstitialAd != null || _disposed) return;
    
    _isInterstitialAdLoading = true;
    
    // Use microtask to avoid blocking the main thread
    scheduleMicrotask(() async {
      try {
        final adUnitId = Platform.isAndroid 
            ? _interstitialAdUnitIds['android']! 
            : _interstitialAdUnitIds['ios']!;
        
        await InterstitialAd.load(
          adUnitId: adUnitId,
          request: const AdRequest(
            keywords: ['waste', 'recycling', 'environment', 'sustainability'],
            contentUrl: 'https://wastewise.app',
          ),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              // Schedule UI update after current frame to prevent jank
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!_disposed) {
                  _interstitialAd = ad;
                  _isInterstitialAdLoading = false;
                  _interstitialRetryCount = 0; // Reset retry count on success
                  
                  // Set callback for ad close
                  ad.fullScreenContentCallback = FullScreenContentCallback(
                    onAdDismissedFullScreenContent: (ad) {
                      ad.dispose();
                      _interstitialAd = null;
                      if (!_disposed) {
                        // Preload next ad asynchronously
                        Future.delayed(const Duration(seconds: 5), _loadInterstitialAd);
                      }
                    },
                    onAdFailedToShowFullScreenContent: (ad, error) {
                      debugPrint('Failed to show interstitial ad: $error');
                      ad.dispose();
                      _interstitialAd = null;
                      if (!_disposed) {
                        _retryInterstitialAdLoad();
                      }
                    },
                    onAdImpression: (ad) {
                      debugPrint('Interstitial ad impression');
                      // Track ad impression analytics here
                    },
                    onAdClicked: (ad) {
                      debugPrint('Interstitial ad clicked');
                      // Track ad click analytics here
                    },
                  );
                  
                  if (mounted) {
                    notifyListeners();
                  }
                }
              });
            },
            onAdFailedToLoad: (error) {
              debugPrint('Failed to load interstitial ad: $error');
              // Schedule retry after current frame
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _isInterstitialAdLoading = false;
                if (!_disposed) {
                  _retryInterstitialAdLoad();
                }
              });
            },
          ),
        );
      } catch (e) {
        debugPrint('Error loading interstitial ad: $e');
        _isInterstitialAdLoading = false;
        if (!_disposed) {
          _retryInterstitialAdLoad();
        }
      }
    });
  }
  
  int _interstitialRetryCount = 0;
  static const int _maxInterstitialRetries = 3;
  
  void _retryInterstitialAdLoad() {
    if (_interstitialRetryCount >= _maxInterstitialRetries || _disposed) {
      _interstitialRetryCount = 0;
      return;
    }
    
    _interstitialRetryCount++;
    final delay = Duration(minutes: _interstitialRetryCount); // 1min, 2min, 3min
    
    Future.delayed(delay, () {
      if (!_disposed) {
        _loadInterstitialAd();
      }
    });
  }
  
  // Get banner ad widget - Optimized for performance and lifecycle management
  Widget getBannerAd() {
    if (kIsWeb || !shouldShowAds || _disposed) {
      return const SizedBox.shrink();
    }
    
    if (_bannerAd == null) {
      // If banner ad is not loaded yet, try to load it asynchronously
      if (!_isInitializing) {
        // Schedule ad loading after the current build cycle to prevent jank
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_disposed) {
            _loadBannerAd();
          }
        });
      }
      return _buildPlaceholderAd();
    }
    
    // Use a stable key based on ad instance to prevent unnecessary rebuilds
    final adKey = '${_bannerAd.hashCode}';
    
    // Only create a new widget if we don't have a cached one or the ad changed
    if (_cachedBannerWidget == null || _currentBannerAdKey != adKey) {
      _cachedBannerWidget = RepaintBoundary(
        child: Container(
          alignment: Alignment.center,
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: AdWidget(ad: _bannerAd!),
          ),
        ),
      );
      _currentBannerAdKey = adKey;
    }
    
    return _cachedBannerWidget!;
  }
  
  // Build a performant placeholder for the ad
  Widget _buildPlaceholderAd() {
    return RepaintBoundary(
      child: Container(
        alignment: Alignment.center,
        width: 320, // Standard banner width
        height: 50,  // Standard banner height
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: AnimatedOpacity(
          opacity: 0.6,
          duration: const Duration(milliseconds: 1000),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade500),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Loading ad...', 
                style: TextStyle(
                  fontSize: 11, 
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Show interstitial ad
  Future<bool> showInterstitialAd() async {
    if (kIsWeb || !shouldShowAds || !canShowInterstitialAd || _interstitialAd == null || _disposed) {
      return false;
    }
    
    try {
      await _interstitialAd!.show();
      _lastInterstitialAdTime = DateTime.now();
      _classificationsSinceLastAd = 0;
      return true;
    } catch (e) {
      debugPrint('Error showing interstitial ad: $e');
      return false;
    }
  }
  
  // TODO: Implement reward ad functionality
  // Future<bool> showRewardAd() async {
  //   // Implementation for reward ads
  //   return false;
  // }
  
  // Track classification completion
  void trackClassificationCompleted() {
    if (_disposed) return;
    
    _classificationsSinceLastAd++;
    
    // If approaching threshold, preload the ad
    if (_classificationsSinceLastAd >= 3 && _interstitialAd == null && !_isInterstitialAdLoading) {
      _loadInterstitialAd();
    }
  }
  
  // Check if interstitial should be shown
  bool shouldShowInterstitial() {
    return !_disposed && _classificationsSinceLastAd >= 5 && shouldShowAds;
  }
  
  // FIXED: Set context methods with post-frame callbacks to prevent build errors
  void setInClassificationFlow(bool value) {
    if (_disposed) return;
    
    if (_isInClassificationFlow != value) {
      _isInClassificationFlow = value;
      // Use post-frame callback to avoid calling notifyListeners during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          notifyListeners();
        }
      });
    }
  }
  
  void setInEducationalContent(bool value) {
    if (_disposed) return;
    
    if (_isInEducationalContent != value) {
      _isInEducationalContent = value;
      // Use post-frame callback to avoid calling notifyListeners during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          notifyListeners();
        }
      });
    }
  }
  
  void setInSettings(bool value) {
    if (_disposed) return;
    
    if (_isInSettings != value) {
      _isInSettings = value;
      // Use post-frame callback to avoid calling notifyListeners during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          notifyListeners();
        }
      });
    }
  }

  void incrementClassificationCount() {
    if (_disposed) return;
    
    _classificationCount++;
    if (_classificationCount >= 5 && canShowInterstitialAd) {
      // Schedule showing ad after the current build cycle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) {
          showInterstitialAd();
        }
      });
      _classificationCount = 0;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _interstitialAd?.dispose();
    _bannerAd?.dispose();
    _cachedBannerWidget = null;
    _currentBannerAdKey = null;
    super.dispose();
  }
  
  // Additional method to track classification for ad frequency
  void trackClassification() {
    if (!_disposed) {
      incrementClassificationCount();
    }
  }
  
  // Method to refresh banner ad (creates a new ad instance)
  void refreshBannerAd() {
    if (_disposed || kIsWeb) return;
    
    // Dispose current ad and clear cache
    _bannerAd?.dispose();
    _bannerAd = null;
    _cachedBannerWidget = null;
    _currentBannerAdKey = null;
    
    // Load a new banner ad
    _loadBannerAd();
  }
}

/*
TODO: ADMOB SETUP CHECKLIST
===========================

1. CREATE ADMOB ACCOUNT:
   - Go to https://admob.google.com
   - Sign up with Google account
   - Create new app project

2. GENERATE AD UNIT IDs:
   - Create Banner ad units for Android/iOS
   - Create Interstitial ad units for Android/iOS
   - Replace test IDs in _bannerAdUnitIds and _interstitialAdUnitIds

3. UPDATE ANDROID CONFIGURATION:
   - Add to android/app/src/main/AndroidManifest.xml:
     <meta-data
         android:name="com.google.android.gms.ads.APPLICATION_ID"
         android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>

4. UPDATE IOS CONFIGURATION:
   - Add to ios/Runner/Info.plist:
     <key>GADApplicationIdentifier</key>
     <string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>

5. IMPLEMENT GDPR COMPLIANCE:
   - Add User Messaging Platform (UMP) SDK
   - Handle consent for EU users

6. TESTING:
   - Use test ads during development
   - Test on real devices before release
   - Verify ad placement doesn't interfere with UX

7. ANALYTICS INTEGRATION:
   - Track ad performance metrics
   - Monitor user engagement impact
   - A/B test ad frequencies

8. PREMIUM FEATURES:
   - Implement ad removal as premium feature
   - Test premium upgrade flow
*/
