import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends ChangeNotifier {
  static const String _removeAdsFeatureId = 'remove_ads';
  
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
  DateTime? _lastInterstitialShown;
  int _classificationsSinceLastAd = 0;
  
  // Ad context management - FIXED: Prevent notifyListeners during build
  bool _isInClassificationFlow = false;
  bool _isInEducationalContent = false;
  bool _isInSettings = false;
  
  bool _isInitialized = false;
  bool _isInitializing = false;
  int _classificationCount = 0;
  DateTime? _lastInterstitialAdTime;
  
  BannerAd? _bannerAd;
  AdWidget? _adWidget;
  
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
  
  // Preload banner ad
  void _loadBannerAd() {
    if (kIsWeb || _bannerAd != null || _disposed) return;
    
    try {
      final adUnitId = Platform.isAndroid 
          ? _bannerAdUnitIds['android']! 
          : _bannerAdUnitIds['ios']!;
      
      // TODO: Consider implementing adaptive banner ads for better performance
      _bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: AdSize.banner, // TODO: Consider AdSize.smartBanner for responsive design
        request: const AdRequest(
          // TODO: Add targeting keywords if needed
          // keywords: ['waste', 'recycling', 'environment'],
        ),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            debugPrint('Banner ad loaded successfully');
            if (!_disposed) {
              _adWidget = AdWidget(ad: _bannerAd!);
              // Use post-frame callback to avoid calling notifyListeners during build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  notifyListeners();
                }
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed to load: $error');
            ad.dispose();
            _bannerAd = null;
            _adWidget = null;
            
            // TODO: Implement exponential backoff for retries
            // Retry after delay
            if (!_disposed) {
              Future.delayed(const Duration(minutes: 1), _loadBannerAd);
            }
          },
          // TODO: Add impression and click tracking
          onAdImpression: (ad) => debugPrint('Banner ad impression'),
          onAdClicked: (ad) => debugPrint('Banner ad clicked'),
        ),
      );
      
      // Start loading the ad
      _bannerAd!.load();
    } catch (e) {
      debugPrint('Error creating banner ad: $e');
      // TODO: Log to crash reporting service
    }
  }
  
  // Load interstitial ad
  void _loadInterstitialAd() {
    if (kIsWeb || _isInterstitialAdLoading || _interstitialAd != null || _disposed) return;
    
    _isInterstitialAdLoading = true;
    
    try {
      final adUnitId = Platform.isAndroid 
          ? _interstitialAdUnitIds['android']! 
          : _interstitialAdUnitIds['ios']!;
      
      InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(
          // TODO: Add targeting parameters
        ),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (!_disposed) {
              _interstitialAd = ad;
              _isInterstitialAdLoading = false;
              
              // Set callback for ad close
              ad.fullScreenContentCallback = FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  _interstitialAd = null;
                  if (!_disposed) {
                    _loadInterstitialAd(); // Reload for next time
                  }
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  debugPrint('Failed to show interstitial ad: $error');
                  ad.dispose();
                  _interstitialAd = null;
                  if (!_disposed) {
                    _loadInterstitialAd(); // Reload for next time
                  }
                },
                // TODO: Track ad events for analytics
                onAdImpression: (ad) => debugPrint('Interstitial ad impression'),
                onAdClicked: (ad) => debugPrint('Interstitial ad clicked'),
              );
              
              // Use post-frame callback to avoid calling notifyListeners during build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  notifyListeners();
                }
              });
            }
          },
          onAdFailedToLoad: (error) {
            debugPrint('Failed to load interstitial ad: $error');
            _isInterstitialAdLoading = false;
            // TODO: Implement exponential backoff strategy
            if (!_disposed) {
              Future.delayed(const Duration(minutes: 1), _loadInterstitialAd);
            }
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading interstitial ad: $e');
      _isInterstitialAdLoading = false;
      // TODO: Report to crash analytics
    }
  }
  
  // Get banner ad widget
  Widget getBannerAd() {
    if (kIsWeb || !shouldShowAds || _disposed) {
      return const SizedBox.shrink(); // No ads on web or for premium users
    }
    
    // If not initialized, try to initialize
    if (!_isInitialized && !_isInitializing) {
      // Schedule initialization after the current build cycle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) {
          initialize();
        }
      });
      return _buildPlaceholderAd();
    }
    
    // If we don't have a loaded ad widget yet, show placeholder
    if (_adWidget == null) {
      // Try loading an ad if not already loading
      if (_bannerAd == null && !_isInitializing) {
        // Schedule ad loading after the current build cycle
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_disposed) {
            _loadBannerAd();
          }
        });
      }
      return _buildPlaceholderAd();
    }
    
    // Return the ad widget wrapped in a container
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: _adWidget,
    );
  }
  
  // Build a placeholder for the ad
  Widget _buildPlaceholderAd() {
    return Container(
      alignment: Alignment.center,
      width: 320, // Standard banner width
      height: 50,  // Standard banner height
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Advertisement', 
        style: TextStyle(
          fontSize: 12, 
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
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
    super.dispose();
  }
  
  // Additional method to track classification for ad frequency
  void trackClassification() {
    if (!_disposed) {
      incrementClassificationCount();
    }
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
