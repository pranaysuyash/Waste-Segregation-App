     1|import 'dart:async';
     2|import 'dart:io';
     3|import 'package:flutter/foundation.dart';
     4|import 'package:flutter/material.dart';
     5|import 'package:google_mobile_ads/google_mobile_ads.dart';
     6|import 'package:waste_segregation_app/utils/waste_app_logger.dart';
     7|
     8|class AdService extends ChangeNotifier {
     9|  // static const String _removeAdsFeatureId = 'remove_ads'; // Unused field removed
    10|
    11|  bool _hasPremium = false;
    12|
    13|  // Test IDs are always used in debug/profile builds.
    14|  static const String _testAndroidBannerId =
    15|      'ca-app-pub-3940256099942544/6300978111';
    16|  static const String _testIosBannerId =
    17|      'ca-app-pub-3940256099942544/2934735716';
    18|  static const String _testAndroidInterstitialId =
    19|      'ca-app-pub-3940256099942544/1033173712';
    20|  static const String _testIosInterstitialId =
    21|      'ca-app-pub-3940256099942544/4411468910';
    22|
    23|  // Release IDs must be provided via --dart-define.
    24|  static const String _releaseAndroidBannerId =
    25|      String.fromEnvironment('ADMOB_ANDROID_BANNER_AD_UNIT_ID');
    26|  static const String _releaseIosBannerId =
    27|      String.fromEnvironment('ADMOB_IOS_BANNER_AD_UNIT_ID');
    28|  static const String _releaseAndroidInterstitialId =
    29|      String.fromEnvironment('ADMOB_ANDROID_INTERSTITIAL_AD_UNIT_ID');
    30|  static const String _releaseIosInterstitialId =
    31|      String.fromEnvironment('ADMOB_IOS_INTERSTITIAL_AD_UNIT_ID');
    32|
    33|  // TODO: Add reward ad unit IDs when implementing reward ads
    34|  // static const Map<String, String> _rewardAdUnitIds = {
    35|  //   'android': 'ca-app-pub-3940256099942544/5224354917', // TEST ID
    36|  //   'ios': 'ca-app-pub-3940256099942544/1712485313',     // TEST ID
    37|  // };
    38|
    39|  // Ad state tracking
    40|  InterstitialAd? _interstitialAd;
    41|  bool _isInterstitialAdLoading = false;
    42|  DateTime? _lastInterstitialAdTime;
    43|  int _classificationsSinceLastAd = 0;
    44|
    45|  // Ad context management - FIXED: Prevent notifyListeners during build
    46|  bool _isInClassificationFlow = false;
    47|  bool _isInEducationalContent = false;
    48|  bool _isInSettings = false;
    49|
    50|  bool _isInitialized = false;
    51|  bool _isInitializing = false;
    52|  bool _canRequestAds = false;
    53|  BannerAd? _bannerAd;
    54|  Widget? _cachedBannerWidget;
    55|  String? _currentBannerAdKey;
    56|  bool _didWarnReleaseBannerFallback = false;
    57|  bool _didWarnReleaseInterstitialFallback = false;
    58|
    59|  // Getters
    60|  bool get isInitialized => _isInitialized;
    61|
    62|  @visibleForTesting
    63|  void debugSetCanRequestAds(bool value) {
    64|    _canRequestAds = value;
    65|  }
    66|
    67|  bool get shouldShowAds =>
    68|      !kIsWeb &&
    69|      _canRequestAds &&
    70|      !_hasPremium &&
    71|      !_isInClassificationFlow &&
    72|      !_isInEducationalContent &&
    73|      !_isInSettings;
    74|
    75|  bool get canShowInterstitialAd {
    76|    if (_lastInterstitialAdTime == null) return true;
    77|    return DateTime.now().difference(_lastInterstitialAdTime!).inMinutes >= 5;
    78|  }
    79|
    80|  // Set premium status
    81|  void setPremiumStatus(bool hasPremium) {
    82|    if (_hasPremium != hasPremium) {
    83|      _hasPremium = hasPremium;
    84|      if (_hasPremium) {
    85|        _classificationsSinceLastAd = 0;
    86|        _bannerAd?.dispose();
    87|        _bannerAd = null;
    88|        _interstitialAd?.dispose();
    89|        _interstitialAd = null;
    90|        _cachedBannerWidget = null;
    91|        _currentBannerAdKey = null;
    92|      } else if (_isInitialized && _canRequestAds && !_disposed && !kIsWeb) {
    93|        _loadBannerAd();
    94|      }
    95|      // Use post-frame callback to avoid calling notifyListeners during build
    96|      WidgetsBinding.instance.addPostFrameCallback((_) {
    97|        if (mounted) {
    98|          notifyListeners();
    99|        }
   100|      });
   101|    }
   102|  }
   103|
   104|  // Check if the service is still mounted (not disposed)
   105|  bool get mounted => !_disposed;
   106|  bool _disposed = false;
   107|
   108|  // Initialize the ad service
   109|  Future<void> initialize() async {
   110|    if (kIsWeb) {
   111|      _isInitialized = true;
   112|      return; // Skip ad initialization on web
   113|    }
   114|
   115|    if (_isInitialized || _isInitializing || _disposed) return;
   116|
   117|    _isInitializing = true;
   118|
   119|    try {
   120|      await MobileAds.instance.initialize();
   121|
   122|      await _refreshConsentAndAdRequestEligibility();
   123|      _isInitialized = true;
   124|
   125|      if (_canRequestAds) {
   126|        _loadInterstitialAd();
   127|        _loadBannerAd();
   128|      } else {
   129|        WasteAppLogger.warning(
   130|          'Ad loading skipped: consent/App eligibility not granted.',
   131|          context: {'service': 'ad_service'},
   132|        );
   133|      }
   134|
   135|      // Use post-frame callback to avoid calling notifyListeners during build
   136|      WidgetsBinding.instance.addPostFrameCallback((_) {
   137|        if (mounted) {
   138|          notifyListeners();
   139|        }
   140|      });
   141|    } catch (e) {
   142|      WasteAppLogger.severe('Error initializing ads: $e');
   143|      // TODO: Implement proper error tracking/analytics
   144|    } finally {
   145|      _isInitializing = false;
   146|    }
   147|  }
   148|
   149|  Future<void> _refreshConsentAndAdRequestEligibility() async {
   150|    if (kIsWeb) {
   151|      _canRequestAds = false;
   152|      return;
   153|    }
   154|
   155|    final completer = Completer<void>();
   156|    final params = ConsentRequestParameters();
   157|
   158|    ConsentInformation.instance.requestConsentInfoUpdate(
   159|      params,
   160|      () async {
   161|        try {
   162|          final status = await ConsentInformation.instance.getConsentStatus();
   163|          if (status == ConsentStatus.obtained ||
   164|              status == ConsentStatus.notRequired) {
   165|            _canRequestAds = true;
   166|            completer.complete();
   167|            return;
   168|          }
   169|
   170|          final isFormAvailable =
   171|              await ConsentInformation.instance.isConsentFormAvailable();
   172|          if (!isFormAvailable) {
   173|            _canRequestAds = false;
   174|            completer.complete();
   175|            return;
   176|          }
   177|
   178|          ConsentForm.loadConsentForm(
   179|            (ConsentForm consentForm) {
   180|              consentForm.show((FormError? formError) async {
   181|                if (formError != null) {
   182|                  WasteAppLogger.warning(
   183|                    'Consent form dismissed with error.',
   184|                    context: {
   185|                      'service': 'ad_service',
   186|                      'error': formError.message,
   187|                      'code': formError.errorCode,
   188|                    },
   189|                  );
   190|                }
   191|
   192|                try {
   193|                  final latestStatus =
   194|                      await ConsentInformation.instance.getConsentStatus();
   195|                  _canRequestAds = latestStatus == ConsentStatus.obtained ||
   196|                      latestStatus == ConsentStatus.notRequired;
   197|                } catch (_) {
   198|                  _canRequestAds = false;
   199|                }
   200|
   201|                await consentForm.dispose();
   202|                completer.complete();
   203|              });
   204|            },
   205|            (FormError error) {
   206|              WasteAppLogger.warning(
   207|                'Consent form failed to load.',
   208|                context: {
   209|                  'service': 'ad_service',
   210|                  'error': error.message,
   211|                  'code': error.errorCode,
   212|                },
   213|              );
   214|              _canRequestAds = false;
   215|              completer.complete();
   216|            },
   217|          );
   218|        } catch (e) {
   219|          WasteAppLogger.warning(
   220|            'Consent evaluation failed after info update.',
   221|            context: {'service': 'ad_service', 'error': e.toString()},
   222|          );
   223|          _canRequestAds = false;
   224|          completer.complete();
   225|        }
   226|      },
   227|      (FormError error) {
   228|        WasteAppLogger.warning(
   229|          'Consent info update failed.',
   230|          context: {
   231|            'service': 'ad_service',
   232|            'error': error.message,
   233|            'code': error.errorCode,
   234|          },
   235|        );
   236|        _canRequestAds = false;
   237|        completer.complete();
   238|      },
   239|    );
   240|
   241|    await completer.future.timeout(
   242|      const Duration(seconds: 15),
   243|      onTimeout: () {
   244|        _canRequestAds = false;
   245|      },
   246|    );
   247|  }
   248|
   249|  String _resolveBannerAdUnitId() {
   250|    if (Platform.isAndroid) {
   251|      return _resolveAdUnitId(
   252|        releaseValue: _releaseAndroidBannerId,
   253|        testValue: _testAndroidBannerId,
   254|        isInterstitial: false,
   255|      );
   256|    }
   257|    return _resolveAdUnitId(
   258|      releaseValue: _releaseIosBannerId,
   259|      testValue: _testIosBannerId,
   260|      isInterstitial: false,
   261|    );
   262|  }
   263|
   264|  String _resolveInterstitialAdUnitId() {
   265|    if (Platform.isAndroid) {
   266|      return _resolveAdUnitId(
   267|        releaseValue: _releaseAndroidInterstitialId,
   268|        testValue: _testAndroidInterstitialId,
   269|        isInterstitial: true,
   270|      );
   271|    }
   272|    return _resolveAdUnitId(
   273|      releaseValue: _releaseIosInterstitialId,
   274|      testValue: _testIosInterstitialId,
   275|      isInterstitial: true,
   276|    );
   277|  }
   278|
   279|  String _resolveAdUnitId({
   280|    required String releaseValue,
   281|    required String testValue,
   282|    required bool isInterstitial,
   283|  }) {
   284|    if (!kReleaseMode) {
   285|      return testValue;
   286|    }
   287|
   288|    if (releaseValue.trim().isNotEmpty) {
   289|      return releaseValue.trim();
   290|    }
   291|
   292|    if (isInterstitial) {
   293|      if (!_didWarnReleaseInterstitialFallback) {
   294|        _didWarnReleaseInterstitialFallback = true;
   295|        WasteAppLogger.warning(
   296|          'Release interstitial ad unit ID not configured; using test ID fallback.',
   297|          context: {'service': 'ad_service'},
   298|        );
   299|      }
   300|    } else {
   301|      if (!_didWarnReleaseBannerFallback) {
   302|        _didWarnReleaseBannerFallback = true;
   303|        WasteAppLogger.warning(
   304|          'Release banner ad unit ID not configured; using test ID fallback.',
   305|          context: {'service': 'ad_service'},
   306|        );
   307|      }
   308|    }
   309|
   310|    return testValue;
   311|  }
   312|
   313|  // Preload banner ad with performance optimization
   314|  void _loadBannerAd() {
   315|    if (kIsWeb || _bannerAd != null || _disposed) return;
   316|
   317|    // Use microtask to avoid blocking the main thread
   318|    scheduleMicrotask(() async {
   319|      try {
   320|        final adUnitId = _resolveBannerAdUnitId();
   321|
   322|        // Use adaptive banner for better performance and responsive design
   323|        final newBannerAd = BannerAd(
   324|          adUnitId: adUnitId,
   325|          size: AdSize.banner, // Changed from AdSize.smartBanner
   326|          request: const AdRequest(
   327|            keywords: ['waste', 'recycling', 'environment', 'sustainability'],
   328|            contentUrl: 'https://reloop.app',
   329|          ),
   330|          listener: BannerAdListener(
   331|            onAdLoaded: (ad) {
   332|              WasteAppLogger.info('Banner ad loaded successfully');
   333|              if (!_disposed) {
   334|                // Schedule UI update after current frame to prevent jank
   335|                WidgetsBinding.instance.addPostFrameCallback((_) {
   336|                  if (!_disposed) {
   337|                    _bannerAd = ad as BannerAd;
   338|                    // Clear cached widget to force recreation
   339|                    _cachedBannerWidget = null;
   340|                    _currentBannerAdKey = null;
   341|
   342|                    if (mounted) {
   343|                      notifyListeners();
   344|                    }
   345|                  }
   346|                });
   347|              }
   348|            },
   349|            onAdFailedToLoad: (ad, error) {
   350|              WasteAppLogger.severe('Banner ad failed to load: $error');
   351|              ad.dispose();
   352|
   353|              // Schedule cleanup after current frame
   354|              WidgetsBinding.instance.addPostFrameCallback((_) {
   355|                if (!_disposed) {
   356|                  _bannerAd = null;
   357|                  _cachedBannerWidget = null;
   358|                  _currentBannerAdKey = null;
   359|
   360|                  // Exponential backoff for retries
   361|                  _retryBannerAdLoad();
   362|                }
   363|              });
   364|            },
   365|            onAdImpression: (ad) {
   366|              WasteAppLogger.info('Banner ad impression');
   367|              // Track ad impression analytics here
   368|            },
   369|            onAdClicked: (ad) {
   370|              WasteAppLogger.info('Banner ad clicked');
   371|              // Track ad click analytics here
   372|            },
   373|          ),
   374|        );
   375|
   376|        // Load ad asynchronously to prevent main thread blocking
   377|        await newBannerAd.load();
   378|      } catch (e) {
   379|        WasteAppLogger.severe('Error creating banner ad: $e');
   380|        // Schedule retry after error
   381|        if (!_disposed) {
   382|          _retryBannerAdLoad();
   383|        }
   384|      }
   385|    });
   386|  }
   387|
   388|  int _bannerRetryCount = 0;
   389|  static const int _maxBannerRetries = 3;
   390|
   391|  void _retryBannerAdLoad() {
   392|    if (_bannerRetryCount >= _maxBannerRetries || _disposed) {
   393|      _bannerRetryCount = 0;
   394|      return;
   395|    }
   396|
   397|    _bannerRetryCount++;
   398|    final delay = Duration(seconds: _bannerRetryCount * 30); // 30s, 60s, 90s
   399|
   400|    Future.delayed(delay, () {
   401|      if (!_disposed) {
   402|        _loadBannerAd();
   403|      }
   404|    });
   405|  }
   406|
   407|  // Load interstitial ad with performance optimization
   408|  void _loadInterstitialAd() {
   409|    if (kIsWeb ||
   410|        _isInterstitialAdLoading ||
   411|        _interstitialAd != null ||
   412|        _disposed) {
   413|      return;
   414|    }
   415|
   416|    _isInterstitialAdLoading = true;
   417|
   418|    // Use microtask to avoid blocking the main thread
   419|    scheduleMicrotask(() async {
   420|      try {
   421|        final adUnitId = _resolveInterstitialAdUnitId();
   422|
   423|        await InterstitialAd.load(
   424|          adUnitId: adUnitId,
   425|          request: const AdRequest(
   426|            keywords: ['waste', 'recycling', 'environment', 'sustainability'],
   427|            contentUrl: 'https://reloop.app',
   428|          ),
   429|          adLoadCallback: InterstitialAdLoadCallback(
   430|            onAdLoaded: (ad) {
   431|              // Schedule UI update after current frame to prevent jank
   432|              WidgetsBinding.instance.addPostFrameCallback((_) {
   433|                if (!_disposed) {
   434|                  _interstitialAd = ad;
   435|                  _isInterstitialAdLoading = false;
   436|                  _interstitialRetryCount = 0; // Reset retry count on success
   437|
   438|                  // Set callback for ad close
   439|                  ad.fullScreenContentCallback = FullScreenContentCallback(
   440|                    onAdDismissedFullScreenContent: (ad) {
   441|                      ad.dispose();
   442|                      _interstitialAd = null;
   443|                      if (!_disposed) {
   444|                        // Preload next ad asynchronously
   445|                        Future.delayed(
   446|                            const Duration(seconds: 5), _loadInterstitialAd);
   447|                      }
   448|                    },
   449|                    onAdFailedToShowFullScreenContent: (ad, error) {
   450|                      WasteAppLogger.severe(
   451|                          'Failed to show interstitial ad: $error');
   452|                      ad.dispose();
   453|                      _interstitialAd = null;
   454|                      if (!_disposed) {
   455|                        _retryInterstitialAdLoad();
   456|                      }
   457|                    },
   458|                    onAdImpression: (ad) {
   459|                      WasteAppLogger.info('Interstitial ad impression');
   460|                      // Track ad impression analytics here
   461|                    },
   462|                    onAdClicked: (ad) {
   463|                      WasteAppLogger.info('Interstitial ad clicked');
   464|                      // Track ad click analytics here
   465|                    },
   466|                  );
   467|
   468|                  if (mounted) {
   469|                    notifyListeners();
   470|                  }
   471|                }
   472|              });
   473|            },
   474|            onAdFailedToLoad: (error) {
   475|              WasteAppLogger.severe('Failed to load interstitial ad: $error');
   476|              // Schedule retry after current frame
   477|              WidgetsBinding.instance.addPostFrameCallback((_) {
   478|                _isInterstitialAdLoading = false;
   479|                if (!_disposed) {
   480|                  _retryInterstitialAdLoad();
   481|                }
   482|              });
   483|            },
   484|          ),
   485|        );
   486|      } catch (e) {
   487|        WasteAppLogger.severe('Error loading interstitial ad: $e');
   488|        _isInterstitialAdLoading = false;
   489|        if (!_disposed) {
   490|          _retryInterstitialAdLoad();
   491|        }
   492|      }
   493|    });
   494|  }
   495|
   496|  int _interstitialRetryCount = 0;
   497|  static const int _maxInterstitialRetries = 3;
   498|
   499|  void _retryInterstitialAdLoad() {
   500|    if (_interstitialRetryCount >= _maxInterstitialRetries || _disposed) {
   501|      _interstitialRetryCount = 0;
   502|      return;
   503|    }
   504|
   505|    _interstitialRetryCount++;
   506|    final delay =
   507|        Duration(minutes: _interstitialRetryCount); // 1min, 2min, 3min
   508|
   509|    Future.delayed(delay, () {
   510|      if (!_disposed) {
   511|        _loadInterstitialAd();
   512|      }
   513|    });
   514|  }
   515|
   516|  // Get banner ad widget - Optimized for performance and lifecycle management
   517|  Widget getBannerAd() {
   518|    if (kIsWeb || !shouldShowAds || _disposed) {
   519|      return const SizedBox.shrink();
   520|    }
   521|
   522|    if (_bannerAd == null) {
   523|      // If banner ad is not loaded yet, try to load it asynchronously
   524|      if (!_isInitializing) {
   525|        // Schedule ad loading after the current build cycle to prevent jank
   526|        WidgetsBinding.instance.addPostFrameCallback((_) {
   527|          if (!_disposed) {
   528|            _loadBannerAd();
   529|          }
   530|        });
   531|      }
   532|      return _buildPlaceholderAd();
   533|    }
   534|
   535|    // Use a stable key based on ad instance to prevent unnecessary rebuilds
   536|    final adKey = '${_bannerAd.hashCode}';
   537|
   538|    // Only create a new widget if we don't have a cached one or the ad changed
   539|    if (_cachedBannerWidget == null || _currentBannerAdKey != adKey) {
   540|      _cachedBannerWidget = RepaintBoundary(
   541|        child: Container(
   542|          alignment: Alignment.center,
   543|          width: _bannerAd!.size.width.toDouble(),
   544|          height: _bannerAd!.size.height.toDouble(),
   545|          decoration: BoxDecoration(
   546|            color: Colors.transparent,
   547|            borderRadius: BorderRadius.circular(4),
   548|          ),
   549|          child: ClipRRect(
   550|            borderRadius: BorderRadius.circular(4),
   551|            child: AdWidget(ad: _bannerAd!),
   552|          ),
   553|        ),
   554|      );
   555|      _currentBannerAdKey = adKey;
   556|    }
   557|
   558|    return _cachedBannerWidget!;
   559|  }
   560|
   561|  // Build a performant placeholder for the ad
   562|  Widget _buildPlaceholderAd() {
   563|    return RepaintBoundary(
   564|      child: Container(
   565|        alignment: Alignment.center,
   566|        width: 320, // Standard banner width
   567|        height: 50, // Standard banner height
   568|        decoration: BoxDecoration(
   569|          color: Colors.grey.shade100,
   570|          border: Border.all(color: Colors.grey.shade300, width: 0.5),
   571|          borderRadius: BorderRadius.circular(4),
   572|        ),
   573|        child: AnimatedOpacity(
   574|          opacity: 0.6,
   575|          duration: const Duration(milliseconds: 1000),
   576|          child: Row(
   577|            mainAxisAlignment: MainAxisAlignment.center,
   578|            children: [
   579|              SizedBox(
   580|                width: 12,
   581|                height: 12,
   582|                child: CircularProgressIndicator(
   583|                  strokeWidth: 1.5,
   584|                  valueColor:
   585|                      AlwaysStoppedAnimation<Color>(Colors.grey.shade500),
   586|                ),
   587|              ),
   588|              const SizedBox(width: 8),
   589|              Text(
   590|                'Loading ad...',
   591|                style: TextStyle(
   592|                  fontSize: 11,
   593|                  color: Colors.grey.shade600,
   594|                  fontWeight: FontWeight.w400,
   595|                ),
   596|              ),
   597|            ],
   598|          ),
   599|        ),
   600|      ),
   601|    );
   602|  }
   603|
   604|  // Show interstitial ad
   605|  Future<bool> showInterstitialAd() async {
   606|    if (kIsWeb ||
   607|        !shouldShowAds ||
   608|        !canShowInterstitialAd ||
   609|        _interstitialAd == null ||
   610|        _disposed) {
   611|      return false;
   612|    }
   613|
   614|    try {
   615|      await _interstitialAd!.show();
   616|      _lastInterstitialAdTime = DateTime.now();
   617|      _classificationsSinceLastAd = 0;
   618|      return true;
   619|    } catch (e) {
   620|      WasteAppLogger.severe('Error showing interstitial ad: $e');
   621|      return false;
   622|    }
   623|  }
   624|
   625|  // TODO: Implement reward ad functionality
   626|  // Future<bool> showRewardAd() async {
   627|  //   // Implementation for reward ads
   628|  //   return false;
   629|  // }
   630|
   631|  // Track classification completion
   632|  void trackClassificationCompleted() {
   633|    if (_disposed) return;
   634|
   635|    _classificationsSinceLastAd++;
   636|
   637|    // If approaching threshold, preload the ad
   638|    if (_classificationsSinceLastAd >= 3 &&
   639|        _interstitialAd == null &&
   640|        !_isInterstitialAdLoading) {
   641|      _loadInterstitialAd();
   642|    }
   643|  }
   644|
   645|  // Check if interstitial should be shown
   646|  bool shouldShowInterstitial() {
   647|    return !_disposed && _classificationsSinceLastAd >= 5 && shouldShowAds;
   648|  }
   649|
   650|  // FIXED: Set context methods with post-frame callbacks to prevent build errors
   651|  void setInClassificationFlow(bool value) {
   652|    if (_disposed) return;
   653|
   654|    if (_isInClassificationFlow != value) {
   655|      _isInClassificationFlow = value;
   656|      // Use post-frame callback to avoid calling notifyListeners during build
   657|      WidgetsBinding.instance.addPostFrameCallback((_) {
   658|        if (mounted) {
   659|          notifyListeners();
   660|        }
   661|      });
   662|    }
   663|  }
   664|
   665|  void setInEducationalContent(bool value) {
   666|    if (_disposed) return;
   667|
   668|    if (_isInEducationalContent != value) {
   669|      _isInEducationalContent = value;
   670|      // Use post-frame callback to avoid calling notifyListeners during build
   671|      WidgetsBinding.instance.addPostFrameCallback((_) {
   672|        if (mounted) {
   673|          notifyListeners();
   674|        }
   675|      });
   676|    }
   677|  }
   678|
   679|  void setInSettings(bool value) {
   680|    if (_disposed) return;
   681|
   682|    if (_isInSettings != value) {
   683|      _isInSettings = value;
   684|      // Use post-frame callback to avoid calling notifyListeners during build
   685|      WidgetsBinding.instance.addPostFrameCallback((_) {
   686|        if (mounted) {
   687|          notifyListeners();
   688|        }
   689|      });
   690|    }
   691|  }
   692|
   693|  @override
   694|  void dispose() {
   695|    if (_disposed) return;
   696|    _disposed = true;
   697|    _interstitialAd?.dispose();
   698|    _bannerAd?.dispose();
   699|    _cachedBannerWidget = null;
   700|    _currentBannerAdKey = null;
   701|    super.dispose();
   702|  }
   703|
   704|  // Method to refresh banner ad (creates a new ad instance)
   705|  void refreshBannerAd() {
   706|    if (_disposed || kIsWeb) return;
   707|
   708|    // Dispose current ad and clear cache
   709|    _bannerAd?.dispose();
   710|    _bannerAd = null;
   711|    _cachedBannerWidget = null;
   712|    _currentBannerAdKey = null;
   713|
   714|    // Load a new banner ad
   715|    _loadBannerAd();
   716|  }
   717|}
   718|
   719|/*
   720|TODO: ADMOB SETUP CHECKLIST
   721|===========================
   722|
   723|1. CREATE ADMOB ACCOUNT:
   724|   - Go to https://admob.google.com
   725|   - Sign up with Google account
   726|   - Create new app project
   727|
   728|2. GENERATE AD UNIT IDs:
   729|   - Create Banner ad units for Android/iOS
   730|   - Create Interstitial ad units for Android/iOS
   731|   - Replace test IDs in _bannerAdUnitIds and _interstitialAdUnitIds
   732|
   733|3. UPDATE ANDROID CONFIGURATION:
   734|   - Add to android/app/src/main/AndroidManifest.xml:
   735|     <meta-data
   736|         android:name="com.google.android.gms.ads.APPLICATION_ID"
   737|         android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
   738|
   739|4. UPDATE IOS CONFIGURATION:
   740|   - Add to ios/Runner/Info.plist:
   741|     <key>GADApplicationIdentifier</key>
   742|     <string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
   743|
   744|5. IMPLEMENT GDPR COMPLIANCE:
   745|   - Add User Messaging Platform (UMP) SDK
   746|   - Handle consent for EU users
   747|
   748|6. TESTING:
   749|   - Use test ads during development
   750|   - Test on real devices before release
   751|   - Verify ad placement doesn't interfere with UX
   752|
   753|7. ANALYTICS INTEGRATION:
   754|   - Track ad performance metrics
   755|   - Monitor user engagement impact
   756|   - A/B test ad frequencies
   757|
   758|8. PREMIUM FEATURES:
   759|   - Implement ad removal as premium feature
   760|   - Test premium upgrade flow
   761|*/
   762|