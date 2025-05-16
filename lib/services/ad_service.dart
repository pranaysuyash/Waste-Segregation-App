import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends ChangeNotifier {
  static const String _removeAdsFeatureId = 'remove_ads';
  
  bool _hasPremium = false;
  
  // Ad unit IDs
  static const Map<String, String> _bannerAdUnitIds = {
    'android': 'ca-app-pub-3940256099942544/6300978111', // Test ID for Android
    'ios': 'ca-app-pub-3940256099942544/2934735716', // Test ID for iOS
  };
  
  static const Map<String, String> _interstitialAdUnitIds = {
    'android': 'ca-app-pub-3940256099942544/1033173712', // Test ID for Android
    'ios': 'ca-app-pub-3940256099942544/4411468910', // Test ID for iOS
  };
  
  // Ad state tracking
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoading = false;
  DateTime? _lastInterstitialShown;
  int _classificationsSinceLastAd = 0;
  
  // Ad context management
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
      notifyListeners();
    }
  }
  
  // Initialize the ad service
  Future<void> initialize() async {
    if (kIsWeb) {
      _isInitialized = true;
      return; // Skip ad initialization on web
    }
    
    if (_isInitialized || _isInitializing) return;
    
    _isInitializing = true;
    
    try {
      // Initialize MobileAds
      await MobileAds.instance.initialize();
      _isInitialized = true;
      
      // Preload interstitial ad
      _loadInterstitialAd();
      
      // Preload banner ad
      _loadBannerAd();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing ads: $e');
    } finally {
      _isInitializing = false;
    }
  }
  
  // Preload banner ad
  void _loadBannerAd() {
    if (kIsWeb || _bannerAd != null) return;
    
    try {
      final adUnitId = Platform.isAndroid 
          ? _bannerAdUnitIds['android']! 
          : _bannerAdUnitIds['ios']!;
      
      _bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            debugPrint('Banner ad loaded successfully');
            _adWidget = AdWidget(ad: _bannerAd!);
            notifyListeners();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed to load: $error');
            ad.dispose();
            _bannerAd = null;
            _adWidget = null;
            
            // Retry after delay
            Future.delayed(const Duration(minutes: 1), _loadBannerAd);
          },
        ),
      );
      
      // Start loading the ad
      _bannerAd!.load();
    } catch (e) {
      debugPrint('Error creating banner ad: $e');
    }
  }
  
  // Load interstitial ad
  void _loadInterstitialAd() {
    if (kIsWeb || _isInterstitialAdLoading || _interstitialAd != null) return;
    
    _isInterstitialAdLoading = true;
    
    try {
      final adUnitId = Platform.isAndroid 
          ? _interstitialAdUnitIds['android']! 
          : _interstitialAdUnitIds['ios']!;
      
      InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialAdLoading = false;
            
            // Set callback for ad close
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _interstitialAd = null;
                _loadInterstitialAd(); // Reload for next time
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                _interstitialAd = null;
                _loadInterstitialAd(); // Reload for next time
              },
            );
            
            notifyListeners();
          },
          onAdFailedToLoad: (error) {
            _isInterstitialAdLoading = false;
            // Retry after delay with exponential backoff
            Future.delayed(const Duration(minutes: 1), _loadInterstitialAd);
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading interstitial ad: $e');
      _isInterstitialAdLoading = false;
    }
  }
  
  // Get banner ad widget
  Widget getBannerAd() {
    if (kIsWeb || !shouldShowAds) {
      return const SizedBox.shrink(); // No ads on web or for premium users
    }
    
    // If not initialized, try to initialize
    if (!_isInitialized && !_isInitializing) {
      initialize();
      return _buildPlaceholderAd();
    }
    
    // If we don't have a loaded ad widget yet, show placeholder
    if (_adWidget == null) {
      // Try loading an ad if not already loading
      if (_bannerAd == null && !_isInitializing) {
        _loadBannerAd();
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
      color: Colors.black12, // Light gray background for the ad space
      child: const Text(
        'Ad loading...', 
        style: TextStyle(fontSize: 12, color: Colors.grey)
      ),
    );
  }
  
  // Show interstitial ad
  Future<bool> showInterstitialAd() async {
    if (kIsWeb || !shouldShowAds || !canShowInterstitialAd || _interstitialAd == null) {
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
  
  // Track classification completion
  void trackClassificationCompleted() {
    _classificationsSinceLastAd++;
    
    // If approaching threshold, preload the ad
    if (_classificationsSinceLastAd >= 3 && _interstitialAd == null && !_isInterstitialAdLoading) {
      _loadInterstitialAd();
    }
  }
  
  // Check if interstitial should be shown
  bool shouldShowInterstitial() {
    return _classificationsSinceLastAd >= 5 && shouldShowAds;
  }
  
  // Set context for ad management
  void setInClassificationFlow(bool value) {
    _isInClassificationFlow = value;
    notifyListeners();
  }
  
  void setInEducationalContent(bool value) {
    _isInEducationalContent = value;
    notifyListeners();
  }
  
  void setInSettings(bool value) {
    _isInSettings = value;
    notifyListeners();
  }

  void incrementClassificationCount() {
    _classificationCount++;
    if (_classificationCount >= 5 && canShowInterstitialAd) {
      showInterstitialAd();
      _classificationCount = 0;
    }
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }
}