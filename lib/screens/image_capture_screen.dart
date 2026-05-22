import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/detected_waste_region.dart';
import 'package:waste_segregation_app/models/multi_item_classification_result.dart';
import 'package:waste_segregation_app/services/segmentation_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/capture_image_options.dart';
import '../utils/constants.dart';
import '../utils/design_system.dart';
import '../widgets/analysis_progress_view.dart';
import '../widgets/premium_segmentation_toggle.dart';
import '../widgets/analysis_speed_selector.dart';
import '../widgets/modern_ui/modern_cards.dart';
import '../models/token_wallet.dart';
import '../models/classification_state.dart';
import '../providers/ai_job_providers.dart';
import '../providers/app_providers.dart';
import '../providers/classification_pipeline_providers.dart';
import '../providers/classification_state_provider.dart';
import '../providers/token_providers.dart';
import '../services/image_quality_gate.dart';
import '../services/layer0_router.dart';
import '../services/local_classifier_service.dart';
import '../services/offline_queue_service.dart';
import '../services/remote_config_service.dart';
import 'result_screen_wrapper.dart';
import 'job_queue_screen.dart';
import 'zero_balance_sheet.dart';
import '../utils/waste_app_logger.dart';
import '../utils/ai_error_messages.dart';
import '../services/premium_service.dart';
import '../widgets/manual_region_selector.dart';
import 'combined_result_screen.dart';

class ImageCaptureScreen extends ConsumerStatefulWidget {
  const ImageCaptureScreen({
    super.key,
    this.imageFile,
    this.xFile,
    this.webImage,
    this.autoAnalyze = false,
  });

  factory ImageCaptureScreen.fromXFile(
    XFile xFile, {
    bool autoAnalyze = false,
  }) =>
      ImageCaptureScreen(
        xFile: xFile,
        imageFile: kIsWeb ? null : File(xFile.path),
        autoAnalyze: autoAnalyze,
      );
  final File? imageFile;
  final XFile? xFile;
  final Uint8List? webImage;
  final bool autoAnalyze;

  @override
  ConsumerState<ImageCaptureScreen> createState() => _ImageCaptureScreenState();
}

class _ImageCaptureScreenState extends ConsumerState<ImageCaptureScreen>
    with RestorationMixin, TickerProviderStateMixin {
  static const bool _isDebugGridSegmentationEnabled = bool.fromEnvironment(
    'ENABLE_DEBUG_GRID_SEGMENTATION',
  );
  WasteClassification? _pendingClassification;
  String? _analysisErrorMessage;
  int? _queuedPositionHint;

  File? _imageFile;
  XFile? _xFile;
  Uint8List? _webImageBytes;

  bool _useSegmentation = false;
  List<Map<String, dynamic>> _segments = [];
  final Set<int> _selectedSegments = {};
  AnalysisSpeed _selectedSpeed = AnalysisSpeed.instant;
  bool _guardrailForcesBatch = false;

  bool _isSelectingRegions = false;
  List<SelectedRegion> _selectedRegions = [];
  List<DetectedWasteRegion>? _suggestedRegions;
  bool _hasShownSuggestion = false;

  final RestorableStringN _imagePath = RestorableStringN(null);
  final RestorableBool _useSegmentationRestorable = RestorableBool(false);

  late final AnimationController _scanPulseController;
  late final Animation<double> _scanPulseScale;
  late final Animation<double> _scanPulseOpacity;

  // Track 1 & 2: Quality Gate and Offline Queue Integration
  bool _isOnline = true;
  int _pendingQueueItems = 0;
  late StreamSubscription<int> _queueCountSubscription;

  // Layer 0 result preserved for offline hint fallback.
  Layer0Result? _lastLayer0Result;

  @override
  String? get restorationId => 'image_capture_screen';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_imagePath, 'image_path');
    registerForRestoration(_useSegmentationRestorable, 'use_segmentation');
    _useSegmentation =
        _isDebugGridSegmentationEnabled && _useSegmentationRestorable.value;
    if (_imageFile == null && _imagePath.value != null && !kIsWeb) {
      final file = File(_imagePath.value!);
      if (file.existsSync()) {
        _imageFile = file;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _imagePath.value = null;
          }
        });
      }
    }
    if (_xFile == null && _imagePath.value != null && kIsWeb) {
      _xFile = XFile(_imagePath.value!);
      _loadWebImage();
    }
  }

  @override
  void initState() {
    super.initState();
    _imageFile = widget.imageFile;
    _xFile = widget.xFile;
    _webImageBytes = widget.webImage;
    _scanPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _scanPulseScale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _scanPulseController, curve: Curves.easeOut),
    );
    _scanPulseOpacity = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(parent: _scanPulseController, curve: Curves.easeOut),
    );

    // Track 1 & 2: Initialize connectivity listener
    _initializeConnectivityListener();

    // Track 2: Initialize offline queue listener
    _initializeQueueListener();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_imageFile != null) {
        _imagePath.value = _imageFile!.path;
      } else if (_xFile != null) {
        _imagePath.value = _xFile!.path;
      }
      _useSegmentationRestorable.value = _useSegmentation;
      if (widget.autoAnalyze &&
          (_imageFile != null || _xFile != null || _webImageBytes != null)) {
        WasteAppLogger.info(
          'Auto-analyzing image on init.',
          context: {'service': 'screen', 'file': 'image_capture_screen'},
        );
        _analyzeImage();
      } else if (!widget.autoAnalyze &&
          (_imageFile != null || _webImageBytes != null)) {
        _autoDetectMultiItemRegions();
      }
    });
    if (_imageFile == null && _xFile == null && _webImageBytes == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _captureImage();
      });
    } else if (kIsWeb && _xFile != null) {
      _loadWebImage();
    }
  }

  Future<void> _refreshGuardrailMode({bool showUserNotice = false}) async {
    try {
      final aiService = ref.read(aiServiceProvider);
      await aiService.initialize();
      final shouldForceBatch = aiService.isBatchModeEnforced() ||
          aiService.getRecommendedAnalysisSpeed() == AnalysisSpeed.batch;

      if (!mounted) return;
      if (_guardrailForcesBatch != shouldForceBatch) {
        setState(() {
          _guardrailForcesBatch = shouldForceBatch;
        });
      }

      if (shouldForceBatch && _selectedSpeed == AnalysisSpeed.instant) {
        setState(() {
          _selectedSpeed = AnalysisSpeed.batch;
        });
        if (showUserNotice && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Instant mode is temporarily disabled by cost guardrails. Switched to Batch.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (_) {
      // Non-blocking: do not prevent analysis flow if policy refresh fails.
    }
  }

  void _initializeConnectivityListener() {
    final connectivity = Connectivity();
    connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final isOnline = !results.contains(ConnectivityResult.none);
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
      WasteAppLogger.info(
        'Connectivity changed',
        context: {
          'service': 'screen',
          'file': 'image_capture_screen',
          'isOnline': isOnline,
        },
      );
    });
  }

  void _initializeQueueListener() {
    final queueService = OfflineQueueService();
    _queueCountSubscription = queueService.queueCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _pendingQueueItems = count;
        });
      }
    });
  }

  Future<void> _captureImage() async {
    final imagePicker = ImagePicker();
    final image = await CaptureImageOptions.pick(
      imagePicker,
      source: ImageSource.camera,
    );
    if (image != null) {
      if (mounted) {
        setState(() {
          _xFile = image;
          if (!kIsWeb) {
            _imageFile = File(image.path);
          }
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _imagePath.value = image.path;
          }
        });
        if (kIsWeb) {
          await _loadWebImage();
        }
      }
    } else {
      if (mounted &&
          _imageFile == null &&
          _xFile == null &&
          _webImageBytes == null) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _loadWebImage() async {
    if (_xFile != null) {
      final bytes = await _xFile!.readAsBytes();
      if (mounted) {
        setState(() {
          _webImageBytes = bytes;
        });
      }
    }
  }

  ClassificationStateMachine get _stateMachine =>
      ref.read(classificationStateMachineProvider);

  ClassificationStateMachineNotifier get _stateMachineNotifier =>
      ref.read(classificationStateMachineProvider.notifier);

  ClassificationState get _classificationState => _stateMachine.current;
  bool get _isAnalyzing => _stateMachine.isActive;
  bool get _isCancelled =>
      _stateMachine.current == ClassificationState.cancelled;

  void _setClassificationState(ClassificationState state) {
    if (!mounted) return;
    _stateMachineNotifier.transitionTo(state);
    setState(() {});
  }


  String _currentImageName() {
    return _imageFile?.path.split('/').last ??
        _xFile?.name ??
        'captured_image.jpg';
  }

  String? _localRuleChipLabel() {
    final region = _pendingClassification?.region;
    if (_classificationState == ClassificationState.policyApplied) {
      if (region == null || region.isEmpty) {
        return 'Applying region rules for disposal guidance.';
      }
      return 'Applying disposal rules for ${region.trim()}.';
    }
    if (_classificationState == ClassificationState.awaitingUserConfirmation) {
      return 'Result requires manual review before finalization.';
    }
    return null;
  }

  String _analysisConfidenceText() {
    final confidence = _pendingClassification?.confidence;
    if (confidence == null) {
      return 'Confidence and local scoring are still finalizing.';
    }
    final rounded = (confidence * 100).round();
    return 'Confidence: $rounded%';
  }

  bool _isFallbackClassification(WasteClassification classification) {
    if (classification.category.toLowerCase() == 'requires manual review') {
      return true;
    }
    if (classification.clarificationNeeded == true) {
      return true;
    }
    if ((classification.confidence ?? 1.0) < 0.55) {
      return true;
    }
    return false;
  }

  Future<void> _showResultOrFallback(WasteClassification classification) async {
    if (!mounted || _isCancelled) return;

    _pendingClassification = classification;
    _setClassificationState(ClassificationState.policyApplied);

    // Let users perceive the local rule pass before outcome is surfaced.
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!mounted || _isCancelled) return;

    if (_isFallbackClassification(classification)) {
      _setClassificationState(
        ClassificationState.awaitingUserConfirmation,
      );
      return;
    }

    _setClassificationState(ClassificationState.classificationSucceeded);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted || _isCancelled) return;

    await _navigateToResult(classification);
  }

  Future<void> _navigateToResult(WasteClassification classification) async {
    if (!mounted || _isCancelled) return;

    final resultRoute = ResultScreenWrapper(
      classification: classification,
    );

    try {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => resultRoute),
      );
    } finally {
      if (mounted) {
        _stateMachineNotifier.reset();
        setState(() {
          _analysisErrorMessage = null;
          _pendingClassification = null;
        });
      }
    }
  }

  Widget _buildAnalysisProgressView() {
    final cs = _classificationState;
    return AnalysisProgressView(
      state: cs,
      imageName: _currentImageName(),
      offlineQueueCount: _pendingQueueItems,
      queuePosition: _queuedPositionHint,
      localRuleChipText: _localRuleChipLabel(),
      statusMessage: _analysisErrorMessage,
      confidenceText: _analysisConfidenceText(),
      resultCategoryColor: WasteAppDesignSystem.getCategoryColor(
          _pendingClassification?.category ?? ''),
      onRetry: cs == ClassificationState.failedRetryable
          ? _retryAnalysis
          : null,
      onCancel: cs == ClassificationState.failedRetryable ||
              cs == ClassificationState.qualityChecking ||
              cs == ClassificationState.cacheChecking ||
              cs == ClassificationState.cloudClassifying ||
              cs == ClassificationState.localClassifying ||
              cs == ClassificationState.policyApplied
          ? _cancelAnalysis
          : null,
      onContinue: cs == ClassificationState.awaitingUserConfirmation ||
              cs == ClassificationState.classificationSucceeded
          ? () {
              final classification = _pendingClassification;
              if (classification != null) {
                _navigateToResult(classification);
              }
            }
          : null,
    );
  }

  Future<void> _retryAnalysis() async {
    final hasImageSource = kIsWeb
        ? (_webImageBytes != null || _xFile != null)
        : (_imageFile != null || _xFile != null);
    if (!hasImageSource &&
        (_imageFile == null && _xFile == null && _webImageBytes == null)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image available to retry.')),
        );
      }
      return;
    }
    _setClassificationState(ClassificationState.qualityChecking);
    if (mounted) {
      setState(() {
        _analysisErrorMessage = null;
      });
    }
    await _analyzeImage();
  }

  void _cancelAnalysis() {
    // Cancel the AI service analysis.
    final aiService = ref.read(aiServiceProvider);
    aiService.cancelAnalysis();

    _setClassificationState(ClassificationState.cancelled);

    setState(() {
      _analysisErrorMessage = null;
      _pendingClassification = null;
    });

    WasteAppLogger.info(
      'Analysis cancelled by user.',
      context: {
        'service': 'screen',
        'file': 'image_capture_screen',
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analysis cancelled.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _autoDetectMultiItemRegions() async {
    if (_suggestedRegions != null || _hasShownSuggestion) return;
    try {
      final segService = SegmentationService();
      await segService.initialize();
      Uint8List? bytes;
      if (_webImageBytes != null) {
        bytes = _webImageBytes;
      } else if (_imageFile != null) {
        bytes = await _imageFile!.readAsBytes();
      }
      if (bytes == null || !mounted) return;

      final regions = await segService.detectRegions(bytes);
      if (regions.length > 1 && mounted) {
        setState(() {
          _suggestedRegions = regions;
          _hasShownSuggestion = true;
        });
        WasteAppLogger.info(
          'Auto-detected ${regions.length} regions from segmentation service '
          '(model: ${segService.modelName})',
          context: {'service': 'screen', 'file': 'image_capture_screen'},
        );
      }
    } catch (e) {
      WasteAppLogger.warning(
        'Auto-detection failed (non-blocking)',
        error: e,
        context: {'service': 'screen', 'file': 'image_capture_screen'},
      );
    }
  }

  void _enterRegionSelectionMode({List<DetectedWasteRegion>? preDetected}) {
    if (!mounted || _isAnalyzing || _isSelectingRegions || widget.autoAnalyze) {
      return;
    }
    if (_imageFile == null && _xFile == null && _webImageBytes == null) {
      return;
    }
    setState(() {
      _isSelectingRegions = true;
      _hasShownSuggestion = false;
      if (preDetected != null && preDetected.isNotEmpty) {
        _selectedRegions = preDetected.map((r) {
          return SelectedRegion(
            id: int.tryParse(r.id.replaceAll(RegExp(r'\D'), '')) ?? 1,
            left: r.boundingBox.left,
            top: r.boundingBox.top,
            width: r.boundingBox.width,
            height: r.boundingBox.height,
          );
        }).toList();
      } else {
        _selectedRegions = [_defaultRegionSeed()];
      }
    });
  }

  SelectedRegion _defaultRegionSeed() {
    return SelectedRegion(
      id: 1,
      left: 0.04,
      top: 0.04,
      width: 0.92,
      height: 0.92,
    );
  }

  Future<void> _runSegmentation() async {
    if (!_isDebugGridSegmentationEnabled) {
      throw Exception(
        'Debug grid segmentation is disabled. Enable ENABLE_DEBUG_GRID_SEGMENTATION for demo mode.',
      );
    }
    final aiService = ref.read(aiServiceProvider);
    List<Map<String, dynamic>> segments;
    if (kIsWeb) {
      final imageBytes = _webImageBytes;
      if (imageBytes == null || imageBytes.isEmpty) {
        throw Exception('No image data available for segmentation');
      }
      segments = await aiService.segmentImage(imageBytes);
    } else {
      if (_imageFile == null) {
        throw Exception('No image file available for segmentation');
      }
      segments = await aiService.segmentImage(_imageFile!);
    }
    setState(() {
      _segments = segments;
      _selectedSegments.clear();
    });
  }

  // Track 1: Quality check dialog and offline queue integration
  Future<bool> _showQualityCheckDialog(QualityCheckResult result) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Image Quality Warning'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.userMessage),
                if (result.metrics != null && result.metrics!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Quality Metrics:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...result.metrics!.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatMetricLabel(e.key)),
                          Text(
                            e.value,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Retake'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Use Anyway'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _formatMetricLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  Future<void> _queueAnalysisOffline(Uint8List imageBytes) async {
    _setClassificationState(ClassificationState.queuedOffline);
    setState(() {
      _analysisErrorMessage = null;
    });
    final queueService = OfflineQueueService();
    final userProfile = ref.read(userProfileProvider).value;
    const region = 'auto'; // Default region for offline queue
    final imageName = _imageFile?.path.split('/').last ??
        _xFile?.name ??
        'captured_${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      setState(() {
        _queuedPositionHint = queueService.pendingCount + 1;
      });
      await queueService.queue(
        imageBytes: imageBytes,
        region: region,
        userId: userProfile?.id,
        imageName: imageName,
      );
      WasteAppLogger.info(
        'Image queued for offline processing',
        context: {
          'service': 'screen',
          'file': 'image_capture_screen',
          'imageName': imageName,
          'region': region,
        },
      );
      _setClassificationState(ClassificationState.classificationSucceeded);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Image queued for analysis. Will process when online.',
            ),
          ),
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _setClassificationState(ClassificationState.failedRetryable);
      setState(() {
        _analysisErrorMessage = 'Failed to queue image offline. Try again.';
      });
      WasteAppLogger.severe(
        'Failed to queue image offline',
        error: e,
        context: {'service': 'screen', 'file': 'image_capture_screen'},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to queue image: ${e.toString()}')),
        );
      }
    }

    setState(() {
      _queuedPositionHint = null;
    });
  }

  /// Try local classification (Layer 0 deterministic + Layer 1 on-device ML).
  ///
  /// Returns true when a local layer produced an accepted classification
  /// and the result screen was shown. Stores the Layer 0 result in
  /// [_lastLayer0Result] for offline hint fallback.
  Future<bool> _tryLocalClassification(Uint8List imageBytes) async {
    _setClassificationState(ClassificationState.localClassifying);
    _lastLayer0Result = null;

    final pipeline = ref.read(classificationPipelineProvider);
    final result = await pipeline.tryLocalWithHint(
      imageBytes: imageBytes,
      region: 'Bangalore, IN',
    );

    _lastLayer0Result = result.layer0Result;

    if (result.accepted != null && mounted && !_isCancelled) {
      await _showResultOrFallback(result.accepted!);
      return true;
    }

    return false;
  }

  /// Show a degraded result when offline and Layer 0 produced a hint.
  Future<bool> _tryShowOfflineHint(
    Layer0Result layer0Result,
    Uint8List imageBytes,
  ) async {
    if (layer0Result.decision != Layer0Decision.hint) return false;

    final pipeline = ref.read(classificationPipelineProvider);
    final hintWc = pipeline.buildLocalClassification(
      localResult: layer0Result.classificationResult ??
          LocalClassificationResult(
            category: layer0Result.barcodeResult?.category ?? 'Unknown',
            confidence: layer0Result.barcodeResult?.confidence ?? 0.0,
            modelVersion: 'layer0_hint',
          ),
      region: 'Bangalore, IN',
    );

    final hintClassification = hintWc.copyWith(
      isOfflineHint: true,
      classificationLayer: 'layer0_hint_pending_cloud',
      explanation:
          'Preliminary classification (offline). '
          'Will re-verify when connected.',
    );

    if (!_isOnline && !kIsWeb) {
      unawaited(_queueAnalysisOffline(imageBytes));
    }

    if (mounted && !_isCancelled) {
      await _showResultOrFallback(hintClassification);
      return true;
    }
    return false;
  }

  Future<void> _analyzeImage() async {
    if (_isAnalyzing || _isCancelled) return;

    _setClassificationState(ClassificationState.qualityChecking);
    setState(() {
      _analysisErrorMessage = null;
    });

    await _refreshGuardrailMode(showUserNotice: true);

    // Phase 0: Token economy kill switch and telemetry
    final tokenService = ref.read(tokenServiceProvider);
    await tokenService.initialize();

    // Log the user's intent (regardless of enforcement state)
    tokenService.logAnalysisIntent(
      analysisSpeed: _selectedSpeed.name,
      tokenCost: _selectedSpeed.cost,
      currentBalance: tokenService.currentWallet?.balance ?? 0,
    );

    // Check affordability (always allows when enforcement is off, blocks when on)
    final premiumService = context.read<PremiumService>();
    final isPremiumUser = premiumService.hasActivePremiumPlan();
    final effectiveCost = tokenService.getAnalysisCost(
      _selectedSpeed,
      isPremiumUser: isPremiumUser,
    );
    if (!tokenService.canAffordAnalysisWithPricing(
      _selectedSpeed,
      isPremiumUser: isPremiumUser,
    )) {
      if (mounted) {
        _stateMachineNotifier.reset();
        setState(() {});
        ZeroBalanceOptionsSheet.show(
          context,
          requiredTokens: effectiveCost,
          onBatchSelected: () {
            setState(() => _selectedSpeed = AnalysisSpeed.batch);
            _analyzeImage();
          },
        );
      }
      return;
    }

    // Track 1 & 2: Quality gate check and offline queue handling
    Uint8List? imageBytes;
    try {
      if (kIsWeb) {
        if (_xFile != null) {
          imageBytes = _webImageBytes;
          imageBytes ??= await _xFile!.readAsBytes();
        } else if (_webImageBytes != null) {
          imageBytes = _webImageBytes;
        }
      } else if (_imageFile != null) {
        imageBytes = await _imageFile!.readAsBytes();
      }

      if (imageBytes != null && imageBytes.isNotEmpty) {
        // Track 1: Check image quality
        final qualityResult = await ImageQualityGate.check(imageBytes);
        if (!qualityResult.isValid) {
          WasteAppLogger.info(
            'Image quality check failed',
            context: {
              'service': 'screen',
              'file': 'image_capture_screen',
              'failureType': qualityResult.failureType.toString(),
            },
          );
          if (mounted) {
            final useAnyway = await _showQualityCheckDialog(qualityResult);
            if (!useAnyway) {
              WasteAppLogger.info(
                'User chose to retake image',
                context: {'service': 'screen', 'file': 'image_capture_screen'},
              );
              if (mounted) {
                _stateMachineNotifier.reset();
                setState(() {});
              }
              return;
            }
          }
        }
      }
    } catch (e) {
      WasteAppLogger.warning(
        'Quality gate error (non-blocking)',
        error: e,
        context: {'service': 'screen', 'file': 'image_capture_screen'},
      );
      // Fail-open: continue with analysis even if quality check fails
    }

    // Layers 0 & 1: Deterministic + on-device ML — zero-cost local classification.
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final accepted = await _tryLocalClassification(imageBytes);
      if (accepted) return;
    }

    // Track 2: Check if we're offline — try hint before queuing.
    if (!_isOnline && !kIsWeb) {
      if (imageBytes != null && imageBytes.isNotEmpty) {
        // If Layer 0 produced a hint, show a degraded result (gated by remote config).
        final tier2Enabled = await RemoteConfigService()
            .getBool('offline_degradation_tier2_enabled', defaultValue: true);
        if (tier2Enabled &&
            _lastLayer0Result != null &&
            _lastLayer0Result!.decision == Layer0Decision.hint &&
            mounted) {
          final hintShown = await _tryShowOfflineHint(
              _lastLayer0Result!, imageBytes);
          if (hintShown) return;
        }
        if (mounted) {
          await _queueAnalysisOffline(imageBytes);
        } else {
          _stateMachineNotifier.reset();
        }
        return;
      }
    }

    // Quota preflight re-check immediately before network analysis.
    // Covers long quality-check dialogs / async delays between initial intent
    // logging and the actual provider call.
    await tokenService.initialize();
    if (!tokenService.canAffordAnalysisWithPricing(
      _selectedSpeed,
      isPremiumUser: isPremiumUser,
    )) {
      if (mounted) {
        ZeroBalanceOptionsSheet.show(
          context,
          requiredTokens: effectiveCost,
          onBatchSelected: () {
            setState(() => _selectedSpeed = AnalysisSpeed.batch);
            _analyzeImage();
          },
        );
      }
      return;
    }

    _setClassificationState(ClassificationState.cloudClassifying);
    try {
      // _stateMachine is already cloudClassifying — analysis in flight
      final aiService = ref.read(aiServiceProvider);
      late WasteClassification classification;
      if (kIsWeb) {
        if (_xFile != null) {
          var imageBytes = _webImageBytes;
          if (imageBytes == null) {
            try {
              imageBytes = await _xFile!.readAsBytes();
              if (_isCancelled) {
                WasteAppLogger.info(
                  'Analysis cancelled during image reading.',
                  context: {
                    'service': 'screen',
                    'file': 'image_capture_screen',
                  },
                );
                return;
              }
              if (mounted) {
                setState(() {
                  _webImageBytes = imageBytes;
                });
              }
            } catch (bytesError, s) {
              WasteAppLogger.severe(
                'Failed to read image data for web analysis',
                error: bytesError,
                stackTrace: s,
                context: {'service': 'screen', 'file': 'image_capture_screen'},
              );
              throw Exception('Failed to read image data: $bytesError');
            }
          }
          if (imageBytes.isEmpty) {
            throw Exception('Image data is empty or could not be read');
          }
          if (_isCancelled) {
            WasteAppLogger.info(
              'Analysis cancelled before starting.',
              context: {'service': 'screen', 'file': 'image_capture_screen'},
            );
            return;
          }
          WasteAppLogger.info(
            'Analyzing web image: ${_xFile!.name}, error: size: ${imageBytes.length} bytes',
          );
          if (_useSegmentation && _selectedSegments.isNotEmpty) {
            final selectedBounds =
                _selectedSegments.map((i) => _segments[i]).toList();
            if (_selectedSpeed == AnalysisSpeed.instant) {
              final results = await aiService.analyzeImageRegions(
                imageBytes,
                _xFile!.name,
                selectedBounds,
              );
              classification = results.isNotEmpty
                  ? results.first
                  : WasteClassification.fallback(_xFile!.name);
            } else {
              await _createBatchJobWeb(
                imageBytes,
                _xFile!.name,
                segments: selectedBounds,
                useSegmentation: true,
              );
              return;
            }
          } else {
            if (_selectedSpeed == AnalysisSpeed.instant) {
              classification = await aiService.analyzeWebImage(
                imageBytes,
                _xFile!.name,
              );
            } else {
              await _createBatchJobWeb(imageBytes, _xFile!.name);
              return;
            }
          }
          WasteAppLogger.info(
            'Web image analysis complete: ${classification.itemName}',
            context: {'service': 'screen', 'file': 'image_capture_screen'},
          );
        } else if (_webImageBytes != null) {
          if (_isCancelled) {
            WasteAppLogger.info(
              'Analysis cancelled before starting.',
              context: {'service': 'screen', 'file': 'image_capture_screen'},
            );
            return;
          }
          WasteAppLogger.info(
            'Analyzing web image from bytes, error: size: ${_webImageBytes!.length} bytes',
          );
          if (_useSegmentation && _selectedSegments.isNotEmpty) {
            final selectedBounds =
                _selectedSegments.map((i) => _segments[i]).toList();
            final results = await aiService.analyzeImageRegions(
              _webImageBytes!,
              'uploaded_image.jpg',
              selectedBounds,
            );
            classification = results.isNotEmpty
                ? results.first
                : WasteClassification.fallback('uploaded_image.jpg');
          } else {
            classification = await aiService.analyzeWebImage(
              _webImageBytes!,
              'uploaded_image.jpg',
            );
          }
          WasteAppLogger.info(
            'Web image bytes analysis complete: ${classification.itemName}',
            context: {'service': 'screen', 'file': 'image_capture_screen'},
          );
        } else {
          throw Exception('No image provided for analysis');
        }
      } else {
        if (_imageFile != null) {
          if (_isCancelled) {
            WasteAppLogger.info(
              'Analysis cancelled before starting.',
              context: {'service': 'screen', 'file': 'image_capture_screen'},
            );
            return;
          }
          WasteAppLogger.info(
            'Analyzing mobile image: ${_imageFile!.path}',
            context: {'service': 'screen', 'file': 'image_capture_screen'},
          );
          if (await _imageFile!.exists()) {
            if (_useSegmentation && _selectedSegments.isNotEmpty) {
              final selectedBounds =
                  _selectedSegments.map((i) => _segments[i]).toList();
              if (_selectedSpeed == AnalysisSpeed.instant) {
                final bytes = await _imageFile!.readAsBytes();
                final imageName = _imageFile!.path.split('/').last;
                final results = await aiService.analyzeImageRegions(
                  bytes,
                  imageName,
                  selectedBounds,
                );
                classification = results.isNotEmpty
                    ? results.first
                    : WasteClassification.fallback(imageName);
              } else {
                await _createBatchJob(
                  imageFile: _imageFile!,
                  imageName: _imageFile!.path.split('/').last,
                  segments: selectedBounds,
                  useSegmentation: true,
                );
                return;
              }
            } else {
              if (_selectedSpeed == AnalysisSpeed.instant) {
                classification = await aiService.analyzeImage(_imageFile!);
              } else {
                await _createBatchJob(
                  imageFile: _imageFile!,
                  imageName: _imageFile!.path.split('/').last,
                );
                return;
              }
            }
            WasteAppLogger.info(
              'Mobile image analysis complete: ${classification.itemName}',
              context: {'service': 'screen', 'file': 'image_capture_screen'},
            );
          } else {
            throw Exception('Image file does not exist or could not be read');
          }
        } else {
          throw Exception('No image provided for analysis');
        }
      }
      if (_isCancelled) {
        WasteAppLogger.info(
          'Analysis cancelled after completion, error: not navigating.',
        );
        return;
      }

      if (_selectedSpeed == AnalysisSpeed.instant) {
        await tokenService.spendAnalysisTokens(
          _selectedSpeed,
          isPremiumUser: isPremiumUser,
          description: 'Instant AI analysis',
          reference: classification.id,
          metadata: {
            'screen': 'image_capture',
            'segmentation_used':
                _useSegmentation && _selectedSegments.isNotEmpty,
          },
        );
        tokenService.logAnalysisCompletion(
          analysisSpeed: _selectedSpeed.name,
          tokensDeducted: effectiveCost,
          balanceAfter: tokenService.currentWallet?.balance ?? 0,
        );
      }

      if (mounted && !_isCancelled) {
        WasteAppLogger.info(
          'Analysis complete, error: navigating to ResultScreen.',
        );
        await _showResultOrFallback(classification);
      }
    } catch (e, s) {
      WasteAppLogger.severe(
        'Analysis failed',
        error: e,
        stackTrace: s,
        context: {'service': 'screen', 'file': 'image_capture_screen'},
      );
      if (mounted && !_isCancelled) {
        final userMessage = AiErrorMessages.toUserMessage(e);
        _setClassificationState(ClassificationState.failedRetryable);
        setState(() {
          _analysisErrorMessage = userMessage;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _createBatchJob({
    required File imageFile,
    required String imageName,
    List<Map<String, dynamic>>? segments,
    bool useSegmentation = false,
  }) async {
    try {
      final userProfile = ref.read(userProfileProvider).value;
      if (userProfile == null) {
        throw const AuthException('User not authenticated');
      }
      if (!_isOnline) {
        throw const OfflineException('No network connection available');
      }
      final batchJobNotifier = ref.read(batchJobCreationProvider.notifier);
      final jobId = await batchJobNotifier.createJob(
        userId: userProfile.id,
        imageFile: imageFile,
      );
      if (mounted) {
        String message;
        try {
          final stats = await ref.read(queueStatsProvider.future);
          final position = stats.queuedJobs + stats.processingJobs + 1;
          final waitSeconds = stats.estimatedWaitTime.inSeconds;
          if (waitSeconds > 60) {
            message =
                'Job queued at position #$position (~${waitSeconds ~/ 60}m wait)';
          } else {
            message =
                'Job queued at position #$position (~${waitSeconds}s wait)';
          }
        } catch (_) {
          message = 'Batch job created! Job ID: ${jobId.substring(0, 8)}…';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: 'View Jobs',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const JobQueueScreen()),
                );
              },
            ),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthException catch (e) {
      WasteAppLogger.severe(
        'Auth failed creating batch job',
        error: e,
        context: {'service': 'screen', 'file': 'image_capture_screen'},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in before creating a batch job.'),
            duration: Duration(seconds: 5),
          ),
        );
        _stateMachineNotifier.reset();
        setState(() {});
      }
    } on OfflineException catch (e) {
      WasteAppLogger.severe(
        'Offline creating batch job',
        error: e,
        context: {'service': 'screen', 'file': 'image_capture_screen'},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No internet connection. Batch jobs require an active network.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
        _stateMachineNotifier.reset();
        setState(() {});
      }
    } on Exception catch (e) {
      final msg = e.toString();
      String userMessage;
      if (msg.contains('token') ||
          msg.contains('budget') ||
          msg.contains('Insufficient')) {
        userMessage =
            'Not enough tokens for batch analysis. Top up your wallet and try again.';
      } else if (msg.contains('upload') || msg.contains('storage')) {
        userMessage =
            'Image upload failed. Please try again with a smaller image.';
      } else {
        userMessage = 'Failed to create batch job. Please try again later.';
      }
      WasteAppLogger.severe(
        'Failed to create batch job',
        error: e,
        context: {'service': 'screen', 'file': 'image_capture_screen'},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            duration: const Duration(seconds: 5),
          ),
        );
        _stateMachineNotifier.reset();
        setState(() {});
      }
    }
  }

  Future<void> _createBatchJobWeb(
    Uint8List imageBytes,
    String imageName, {
    List<Map<String, dynamic>>? segments,
    bool useSegmentation = false,
  }) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Batch processing on web not yet available. Use the mobile app for batch analysis.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the state machine so the UI rebuilds on every transition.
    ref.watch(classificationStateMachineProvider);

    // If no image is available yet and we are not analyzing, show a loader or placeholder
    if (_imageFile == null &&
        _xFile == null &&
        _webImageBytes == null &&
        !_isAnalyzing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Capture Image')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Waiting for camera...'),
            ],
          ),
        ),
      );
    }

    // If auto-analyze is enabled, show only the loader (no review screen)
    if (widget.autoAnalyze) {
      return Scaffold(
        body: _isAnalyzing
            ? _buildAnalysisProgressView()
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Preparing image for analysis...'),
                  ],
                ),
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.autoAnalyze ? 'Analyzing Image' : 'Review Image'),
        actions: [
          // Track 1 & 2: Show connectivity and queue status
          if (!_isOnline)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Tooltip(
                  message: 'No internet connection - images will be queued',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off, size: 20),
                      SizedBox(width: 4),
                      Text('Offline', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            )
          else if (_pendingQueueItems > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Tooltip(
                  message:
                      '$_pendingQueueItems image(s) waiting to be processed',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        'Pending: $_pendingQueueItems',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isAnalyzing
          ? _buildAnalysisProgressView()
          : _isSelectingRegions
              ? _buildRegionSelectionBody()
              : _buildNormalReviewBody(),
    );
  }

  Widget _buildAnalyzeButton() {
    final speedText =
        _selectedSpeed == AnalysisSpeed.instant ? 'Instant' : 'Batch';
    final tokenCost = _selectedSpeed.cost;

    // Phase 0: Log token cost display event for telemetry
    final tokenService = ref.read(tokenServiceProvider);
    tokenService.logTokenDisplayed(
      analysisSpeed: _selectedSpeed.name,
      tokenCost: tokenCost,
      currentBalance: tokenService.currentWallet?.balance ?? 0,
    );

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isAnalyzing ? null : _analyzeImage,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.paddingRegular,
          ),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
          ),
        ),
        icon: _isAnalyzing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.0,
                ),
              )
            : Icon(
                _selectedSpeed == AnalysisSpeed.instant
                    ? Icons.flash_on
                    : Icons.schedule,
              ),
        label: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isAnalyzing ? 'Analyzing...' : 'Analyze ($speedText)',
              style: const TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!_isAnalyzing)
              Text(
                '$tokenCost ⚡ tokens',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalReviewBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Image preview
          Center(
            child: _useSegmentation
                ? Stack(
                    children: [
                      _buildImagePreview(),
                      if (_segments.isNotEmpty)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final imageWidth = constraints.maxWidth;
                            final imageHeight = constraints.maxHeight;

                            return Stack(
                              children: List.generate(_segments.length, (
                                index,
                              ) {
                                // Using segment bounds from Map
                                final segment = _segments[index];
                                final bounds =
                                    segment['bounds'] as Map<String, dynamic>;
                                final left = (bounds['x'] as num).toDouble() *
                                    imageWidth /
                                    100;
                                final top = (bounds['y'] as num).toDouble() *
                                    imageHeight /
                                    100;
                                final width =
                                    (bounds['width'] as num).toDouble() *
                                        imageWidth /
                                        100;
                                final height =
                                    (bounds['height'] as num).toDouble() *
                                        imageHeight /
                                        100;
                                final selected = _selectedSegments.contains(
                                  index,
                                );

                                return Positioned(
                                  left: left,
                                  top: top,
                                  width: width,
                                  height: height,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (selected) {
                                          _selectedSegments.remove(index);
                                        } else {
                                          _selectedSegments.add(index);
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppTheme.secondaryColor
                                                .withValues(alpha: 0.3)
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: selected
                                              ? AppTheme.secondaryColor
                                              : Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                    ],
                  )
                : _buildImagePreview(),
          ),

          // Multi-item suggestion banner
          if (_suggestedRegions != null && _suggestedRegions!.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingRegular,
                vertical: AppTheme.paddingSmall,
              ),
              child: Material(
                color: Colors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _enterRegionSelectionMode(
                    preDetected: _suggestedRegions,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.paddingRegular),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.teal.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.crop_square,
                            color: Colors.teal,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'I see ${_suggestedRegions!.length} possible items',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap each one to confirm',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.teal,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Instructions
          const ModernCard(
            margin: EdgeInsets.symmetric(horizontal: AppTheme.paddingRegular),
            padding: EdgeInsets.all(AppTheme.paddingRegular),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Position the item clearly in the image for best results.',
                    style: TextStyle(fontSize: AppTheme.fontSizeRegular),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          _buildScanInsights(),

          // Segmentation toggle with premium feature indication
          if (_isDebugGridSegmentationEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingRegular,
              ),
              child: PremiumSegmentationToggle(
                value: _useSegmentation,
                onChanged: (bool value) async {
                  setState(() {
                    _useSegmentation = value;
                  });
                  // Set restoration property safely after state update
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _useSegmentationRestorable.value = value;
                    }
                  });
                  if (value && _segments.isEmpty) {
                    // Capture ScaffoldMessenger before async operation
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    try {
                      await _runSegmentation();
                    } catch (e) {
                      WasteAppLogger.severe(
                        'Segmentation failed',
                        error: e,
                        context: {
                          'service': 'screen',
                          'file': 'image_capture_screen',
                        },
                      );
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Segmentation failed: ${e.toString()}',
                            ),
                            duration: const Duration(seconds: 5),
                          ),
                        );
                        setState(() {
                          _useSegmentation = false;
                        });
                      }
                    }
                  } else if (!value) {
                    setState(() {
                      _segments.clear();
                      _selectedSegments.clear();
                    });
                  }
                },
              ),
            ),

          // Segmentation results info
          if (_isDebugGridSegmentationEnabled &&
              _useSegmentation &&
              _segments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppTheme.secondaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_segments.length} debug grid regions generated. Tap to select for analysis.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_isDebugGridSegmentationEnabled &&
              _useSegmentation &&
              _segments.isNotEmpty)
            _buildDetectedObjectsCard(),

          // Speed selector
          const SizedBox(height: 16),
          AnalysisSpeedSelector(
            selectedSpeed: _selectedSpeed,
            forceBatchMode: _guardrailForcesBatch,
            onSpeedChanged: (AnalysisSpeed speed) {
              if (_guardrailForcesBatch && speed == AnalysisSpeed.instant) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Instant mode is disabled by cost guardrails right now.',
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
                return;
              }
              setState(() {
                _selectedSpeed = speed;
              });
              if (speed == AnalysisSpeed.batch) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _enterRegionSelectionMode();
                  }
                });
              }
            },
          ),
          const SizedBox(height: 12),
          _buildAnalysisSummaryCard(),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Select multiple items button
                _buildSelectMultipleItemsButton(),
                const SizedBox(height: AppTheme.paddingSmall),

                // Quick analyze button (prominent)
                _buildAnalyzeButton(),
                const SizedBox(height: AppTheme.paddingSmall),

                // Quick action row
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Back'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.paddingSmall),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '💡 Tip: Use camera button with long press for instant analysis!',
                              ),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                        icon: const Icon(Icons.flash_on, size: 18),
                        label: const Text('Quick Tip'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectMultipleItemsButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _enterRegionSelectionMode,
        icon: const Icon(Icons.crop_square, size: 20),
        label: const Text('Select multiple items'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.paddingRegular,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
          ),
        ),
      ),
    );
  }

  Widget _buildRegionSelectionBody() {
    return Column(
      children: [
        // Manual region selector with image
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: ManualRegionSelector(
              imageFile: _imageFile,
              webImageBytes: _webImageBytes,
              initialRegions: _selectedRegions,
              maxRegions: 3,
              onRegionsChanged: (regions) {
                setState(() {
                  _selectedRegions = regions;
                });
              },
            ),
          ),
        ),

        // Confirm / Cancel bar
        Padding(
          padding: const EdgeInsets.all(AppTheme.paddingRegular),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isSelectingRegions = false;
                        _selectedRegions = [];
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _selectedRegions.isEmpty
                        ? null
                        : _analyzeSelectedRegions,
                    icon: Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: _selectedRegions.isEmpty ? null : Colors.white,
                    ),
                    label: Text(
                      _selectedRegions.isEmpty
                          ? 'Analyze item'
                          : 'Analyze ${_selectedRegions.length} item${_selectedRegions.length == 1 ? '' : 's'}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedRegions.isEmpty
                          ? null
                          : AppTheme.primaryColor,
                      foregroundColor:
                          _selectedRegions.isEmpty ? null : Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusRegular,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _analyzeSelectedRegions() async {
    if (_selectedRegions.isEmpty) return;

    _setClassificationState(ClassificationState.cloudClassifying);

    try {
      final aiService = ref.read(aiServiceProvider);
      final regions = List<SelectedRegion>.from(_selectedRegions);

      Uint8List imageBytes;
      String imageName;

      if (_webImageBytes != null) {
        imageBytes = _webImageBytes!;
        imageName = 'captured_image.jpg';
      } else if (_imageFile != null) {
        imageBytes = await _imageFile!.readAsBytes();
        imageName = _imageFile!.path.split('/').last;
      } else if (_xFile != null) {
        imageBytes = await _xFile!.readAsBytes();
        imageName = _xFile!.name;
      } else {
        throw Exception('No image available');
      }

      final results = await aiService.analyzeImageRegions(
        imageBytes,
        imageName,
        regions.map((r) => r.toBoundsMap()).toList(),
      );

      if (!mounted) return;

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No items could be classified.'),
            duration: Duration(seconds: 3),
          ),
        );
        _stateMachineNotifier.reset();
        setState(() {
          _isSelectingRegions = false;
          _selectedRegions = [];
        });
        return;
      }

      _stateMachineNotifier.reset();

      final pairedCount = regions.length < results.length
          ? regions.length
          : results.length;
      final detectedRegions = List<DetectedWasteRegion>.generate(
        pairedCount,
        (index) {
          final selectedRegion = regions[index];
          final classification = results[index];
          return DetectedWasteRegion(
            boundingBox: NormalizedBoundingBox(
              left: selectedRegion.left,
              top: selectedRegion.top,
              width: selectedRegion.width,
              height: selectedRegion.height,
            ),
            classification: classification,
            confidence: classification.confidence,
            userConfirmed: true,
            label: classification.displayItemLabel,
          );
        },
      );
      final multiItemResult = MultiItemClassificationResult(
        sourceImagePath: imageName,
        regions: detectedRegions,
        aggregateWarnings: detectedRegions.length > 1
            ? const ['Review each item before disposal.']
            : const [],
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CombinedResultScreen(
            classifications: results,
            multiItemResult: multiItemResult,
            imageName: imageName,
          ),
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            _isSelectingRegions = false;
            _selectedRegions = [];
          });
        }
      });
    } catch (e) {
      WasteAppLogger.severe(
        'Failed to analyze regions',
        error: e,
        context: {'service': 'screen', 'file': 'image_capture_screen'},
      );
      if (mounted) {
        final userMessage = AiErrorMessages.toUserMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            duration: const Duration(seconds: 5),
          ),
        );
        _stateMachineNotifier.reset();
        setState(() {});
      }
    }
  }

  Widget _buildAnalysisSummaryCard() {
    final selectedCount = _selectedSegments.length;
    final totalCount = _segments.length;
    final segmentationStatus = _useSegmentation
        ? (totalCount == 0
            ? 'Detecting...'
            : '$selectedCount of $totalCount selected')
        : 'Off';
    final tokenCost = _selectedSpeed.cost;

    return ModernCard(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.paddingRegular),
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.speed, color: AppTheme.secondaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mode',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                _selectedSpeed.displayName,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.auto_fix_high, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Model',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                _modelLabel(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.bolt, color: AppTheme.rewardGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Status',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                _analysisStatusLabel(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.flash_on, color: AppTheme.rewardGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Token cost',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                '$tokenCost ⚡',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, color: AppTheme.secondaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Estimated time',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                _estimateDurationLabel(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.layers, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Segmentation',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                segmentationStatus,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedObjectsCard() {
    return ModernCard(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.paddingRegular),
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category, color: AppTheme.secondaryColor),
              const SizedBox(width: 8),
              Text(
                'Detected Objects',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_segments.length, (index) {
              final segment = _segments[index];
              final label =
                  segment['label']?.toString() ?? 'Object ${index + 1}';
              final confidence = segment['confidence'] is num
                  ? (segment['confidence'] as num).toDouble()
                  : null;
              final isSelected = _selectedSegments.contains(index);
              final color =
                  isSelected ? AppTheme.secondaryColor : AppTheme.primaryColor;
              final suffix =
                  confidence == null ? '' : ' ${(confidence * 100).round()}%';

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isSelected ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.6)),
                ),
                child: Text(
                  '$label$suffix',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _scanHintText() {
    if (_useSegmentation && _segments.isNotEmpty) {
      return 'Tap objects to focus the scan';
    }
    if (_useSegmentation && _segments.isEmpty) {
      return 'Detecting multiple items...';
    }
    return _selectedSpeed == AnalysisSpeed.instant
        ? 'Instant scan ready'
        : 'Batch scan queued';
  }

  String _modelLabel() {
    return _selectedSpeed == AnalysisSpeed.instant
        ? 'Instant Vision'
        : 'Batch Vision';
  }

  String _analysisStatusLabel() {
    if (_isAnalyzing) {
      return 'Analyzing';
    }
    if (_selectedSpeed == AnalysisSpeed.batch) {
      return 'Queued';
    }
    return 'Ready';
  }

  String _estimateDurationLabel() {
    return _selectedSpeed == AnalysisSpeed.instant
        ? 'Under 1 min'
        : '2-6 hours';
  }

  Widget _buildImagePreview() {
    Widget imageWidget;

    if (kIsWeb) {
      if (_webImageBytes != null) {
        imageWidget = Image.memory(_webImageBytes!, fit: BoxFit.contain);
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    } else if (_imageFile != null || _xFile != null) {
      final file = _imageFile ?? File(_xFile!.path);
      imageWidget = Image.file(file, fit: BoxFit.contain);
    } else if (_webImageBytes != null) {
      imageWidget = Image.memory(_webImageBytes!, fit: BoxFit.contain);
    } else {
      return const Center(child: CircularProgressIndicator());
    }

    // Wrap with InteractiveViewer for zoom functionality
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: InteractiveViewer(
        minScale: 0.5, // Minimum zoom out
        maxScale: 4.0, // Maximum zoom in
        child: Stack(
          fit: StackFit
              .expand, // FIXED: Use StackFit.expand instead of infinite container
          children: [
            // FIXED: Center the image within available space
            Center(child: imageWidget),
            _buildVisionOverlay(),
            // Zoom instruction overlay (shows briefly)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Pinch to zoom • Drag to pan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisionOverlay() {
    final confidence = _getConfidenceEstimate();
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.6),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.center_focus_strong,
                      color: AppTheme.secondaryColor,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'AI Vision Mode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _confidenceColor(confidence).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _confidenceColor(confidence)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.insights,
                      color: _confidenceColor(confidence),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_confidenceLabel(confidence)} ${(confidence * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _scanPulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scanPulseScale.value,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppTheme.secondaryColor.withValues(
                            alpha: _scanPulseOpacity.value,
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.7),
                    width: 2,
                  ),
                  color: Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _scanHintText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getConfidenceEstimate() {
    var base = switch (_selectedSpeed) {
      AnalysisSpeed.batch => 0.72,
      AnalysisSpeed.instant => 0.84,
    };
    final segmentConfidence = _getSegmentConfidence();
    if (segmentConfidence != null) {
      base = (base * 0.6) + (segmentConfidence * 0.4);
    } else if (_useSegmentation && _segments.isNotEmpty) {
      base += 0.06;
    }
    return base.clamp(0.5, 0.95).toDouble();
  }

  double? _getSegmentConfidence() {
    final sourceSegments = _selectedSegments.isNotEmpty
        ? _selectedSegments.map((index) => _segments[index]).toList()
        : _segments;
    if (sourceSegments.isEmpty) {
      return null;
    }
    final confidenceValues = sourceSegments
        .map((segment) => segment['confidence'])
        .whereType<num>()
        .map((value) => value.toDouble())
        .toList();
    if (confidenceValues.isEmpty) {
      return null;
    }
    final total = confidenceValues.reduce((a, b) => a + b);
    return total / confidenceValues.length;
  }

  String _confidenceLabel(double confidence) {
    if (confidence >= 0.85) {
      return 'High';
    }
    if (confidence >= 0.72) {
      return 'Good';
    }
    return 'Est.';
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.85) {
      return AppTheme.wetWasteColor;
    }
    if (confidence >= 0.72) {
      return AppTheme.rewardGold;
    }
    return AppTheme.hazardousWasteColor;
  }

  Widget _buildScanInsights() {
    final hints = <String>[];
    if (_useSegmentation) {
      if (_segments.isNotEmpty) {
        hints.add('Tap detected items to focus the analysis.');
      } else {
        hints.add('Segmentation is on. Detecting multiple items...');
      }
    } else {
      hints.add('Enable multi-item scan if the photo has mixed waste.');
    }
    if (_selectedSpeed == AnalysisSpeed.batch) {
      hints.add('Batch mode is cheaper but slower.');
    } else {
      hints.add('Instant mode prioritizes speed.');
    }
    hints.add('Model in use: ${_modelLabel()}.');
    hints.add('Local disposal rules appear after analysis.');

    return ModernCard(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.paddingRegular),
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates, color: AppTheme.rewardGold),
              const SizedBox(width: 8),
              Text(
                'Scan Insights',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...hints.map(
            (hint) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: AppTheme.secondaryColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      hint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _imagePath.dispose();
    _useSegmentationRestorable.dispose();
    _scanPulseController.dispose();
    // Track 2: Cleanup offline queue listener
    _queueCountSubscription.cancel();
    super.dispose();
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class OfflineException implements Exception {
  const OfflineException(this.message);
  final String message;

  @override
  String toString() => message;
}
