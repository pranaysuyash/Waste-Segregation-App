import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/waste_classification.dart';
import '../services/ai_service.dart';
import '../utils/constants.dart';
import '../widgets/enhanced_analysis_loader.dart';
import '../widgets/premium_segmentation_toggle.dart';
import '../widgets/analysis_speed_selector.dart';
import '../models/token_wallet.dart';
import '../providers/ai_job_providers.dart';
import '../providers/app_providers.dart';
import 'result_screen.dart';
import '../utils/waste_app_logger.dart';

class ImageCaptureScreen extends ConsumerStatefulWidget {
  const ImageCaptureScreen({
    super.key,
    this.imageFile,
    this.xFile,
    this.webImage,
    this.autoAnalyze = false,
  });

  factory ImageCaptureScreen.fromXFile(XFile xFile, {bool autoAnalyze = false}) =>
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

class _ImageCaptureScreenState extends ConsumerState<ImageCaptureScreen> with RestorationMixin {
  bool _isAnalyzing = false;
  bool _isCancelled = false;

  File? _imageFile;
  XFile? _xFile;
  Uint8List? _webImageBytes;

  bool _useSegmentation = false;
  List<Map<String, dynamic>> _segments = [];
  final Set<int> _selectedSegments = {};
  AnalysisSpeed _selectedSpeed = AnalysisSpeed.instant;

  final RestorableStringN _imagePath = RestorableStringN(null);
  final RestorableBool _useSegmentationRestorable = RestorableBool(false);

  @override
  String? get restorationId => 'image_capture_screen';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_imagePath, 'image_path');
    registerForRestoration(_useSegmentationRestorable, 'use_segmentation');
    _useSegmentation = _useSegmentationRestorable.value;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_imageFile != null) {
        _imagePath.value = _imageFile!.path;
      } else if (_xFile != null) {
        _imagePath.value = _xFile!.path;
      }
      _useSegmentationRestorable.value = _useSegmentation;
      if (widget.autoAnalyze && (_imageFile != null || _xFile != null || _webImageBytes != null)) {
        WasteAppLogger.info('Auto-analyzing image on init.', null, null, {'service': 'screen', 'file': 'image_capture_screen'});
        _analyzeImage();
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

  Future<void> _captureImage() async {
    final imagePicker = ImagePicker();
    final image = await imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
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
      if (mounted && _imageFile == null && _xFile == null && _webImageBytes == null) {
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

  Future<void> _runSegmentation() async {
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

  Future<void> _analyzeImage() async {
    if (_isAnalyzing || _isCancelled) return;
    setState(() {
      _isAnalyzing = true;
      _isCancelled = false;
    });
    try {
      final aiService = ref.read(aiServiceProvider);
      late WasteClassification classification;
      if (kIsWeb) {
        if (_xFile != null) {
          var imageBytes = _webImageBytes;
          if (imageBytes == null) {
            try {
              imageBytes = await _xFile!.readAsBytes();
              if (_isCancelled) {
                WasteAppLogger.info('Analysis cancelled during image reading.', null, null, {'service': 'screen', 'file': 'image_capture_screen'});
                return;
              }
              if (mounted) {
                setState(() {
                  _webImageBytes = imageBytes;
                });
              }
            } catch (bytesError, s) {
              WasteAppLogger.severe('Failed to read image data for web analysis', bytesError, s, {'service': 'screen', 'file': 'image_capture_screen'});
              throw Exception('Failed to read image data: $bytesError');
            }
          }
          if (imageBytes.isEmpty) {
            throw Exception('Image data is empty or could not be read');
          }
          if (_isCancelled) {
            WasteAppLogger.info('Analysis cancelled before starting.', null, null, {'service': 'screen', 'file': 'image_capture_screen'});
            return;
          }
          WasteAppLogger.info('Analyzing web image: ${_xFile!.name}, size: ${imageBytes.length} bytes', null, null, {'service': 'screen', 'file': 'image_capture_screen'});
          if (_useSegmentation && _selectedSegments.isNotEmpty) {
            if (_selectedSpeed == AnalysisSpeed.instant) {
              classification = await aiService.analyzeImageSegmentsWeb(
                imageBytes,
                _xFile!.name,
                _selectedSegments.map((i) => _segments[i]).toList(),
              );
            } else {
              await _createBatchJobWeb(imageBytes, _xFile!.name, segments: _selectedSegments.map((i) => _segments[i]).toList(), useSegmentation: true);
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
          WasteAppLogger.info('Web image analysis complete: ${classification.itemName}', null, null, {'service': 'screen', 'file': 'image_capture_screen'});
        } else if (_webImageBytes != null) {
          if (_isCancelled) {
            WasteAppLogger.info('Analysis cancelled before starting.', null, null, {'service': 'screen', 'file': 'image_capture_screen'});
            return;
          }
          WasteAppLogger.info('Analyzing web image from bytes, size: ${_webImageBytes!.length} bytes', null, null, {'service': 'screen', 'file': 'image_capture_screen'});
          if (_useSegmentation && _selectedSegments.isNotEmpty) {
            classification = await aiService.analyzeImageSegmentsWeb(
              _webImageBytes!,
              'uploaded_image.jpg',
              _selectedSegments.map((i) => _segments[i]).toList(),
            );
          } else {
            classification = await aiService.analyzeWebImage(
              _webImageBytes!,
              'uploaded_image.jpg',
            );
          }
          WasteAppLogger.info('Web image bytes analysis complete: ${classification.itemName}', null, null, {'service': 'screen', 'file': 'image_capture_screen'});
        } else {
          throw Exception('No image provided for analysis');
        }
      } else {
        if (_imageFile != null) {
          if (_isCancelled) {
            WasteAppLogger.info('Analysis cancelled before starting.', null, null, {'service': 'screen', 'file': 'image_capture_screen'});
            setState(() {
              _isAnalyzing = false;
            });
            return;
          }
          WasteAppLogger.info('Analyzing mobile image: ${_imageFile!.path}', null, null, {'service': 'screen', 'file': 'image_capture_screen'});
          if (await _imageFile!.exists()) {
            if (_useSegmentation && _selectedSegments.isNotEmpty) {
              if (_selectedSpeed == AnalysisSpeed.instant) {
                classification = await aiService.analyzeImageSegments(
                  _imageFile!,
                  _selectedSegments.map((i) => _segments[i]).toList(),
                );
              } else {
                await _createBatchJob(
                  imageFile: _imageFile!,
                  imageName: _imageFile!.path.split('/').last,
                  segments: _selectedSegments.map((i) => _segments[i]).toList(),
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
            WasteAppLogger.info('Mobile image analysis complete: ${classification.itemName}', null, null, {'service': 'screen', 'file': 'image_capture_screen'});
          } else {
            throw Exception('Image file does not exist or could not be read');
          }
        } else {
          throw Exception('No image provided for analysis');
        }
      }
      if (_isCancelled) {
        WasteAppLogger.info('Analysis cancelled after completion, not navigating.', null, null, {'service': 'screen', 'file': 'image_capture_screen'});
        setState(() {
          _isAnalyzing = false;
        });
        return;
      }
      if (mounted && !_isCancelled) {
        WasteAppLogger.info('Analysis complete, navigating to ResultScreen.', null, null, {'service': 'screen', 'file': 'image_capture_screen'});
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              classification: classification,
            ),
          ),
        ).then((_) {
          if (mounted) {
            setState(() {
              _isAnalyzing = false;
            });
          }
        });
      }
    } catch (e, s) {
      WasteAppLogger.severe('Analysis failed', e, s, {'service': 'screen', 'file': 'image_capture_screen'});
      if (mounted && !_isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() {
          _isAnalyzing = false;
        });
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
        throw Exception('User not authenticated');
      }
      final batchJobNotifier = ref.read(batchJobCreationProvider.notifier);
      final jobId = await batchJobNotifier.createJob(
        userId: userProfile.id,
        imageFile: imageFile,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Batch job created! Job ID: $jobId'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View Jobs',
              onPressed: () {
                // TODO: Navigate to job queue screen
              },
            ),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      WasteAppLogger.severe('Failed to create batch job', e, null, {
        'service': 'screen',
        'file': 'image_capture_screen',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create batch job: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _createBatchJobWeb(Uint8List imageBytes, String imageName, {List<Map<String, dynamic>>? segments, bool useSegmentation = false}) async {
    // TODO: Implement web batch job creation using Riverpod
    // For now, show a placeholder
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batch job (web) queued! You will be notified when analysis is complete.'),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no image is available yet and we are not analyzing, show a loader or placeholder
    if (_imageFile == null && _xFile == null && _webImageBytes == null && !_isAnalyzing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Capture Image'),
        ),
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
          ? EnhancedAnalysisLoader(
              imageName: _imageFile?.path.split('/').last ?? 
                         _xFile?.name ?? 
                         'captured_image.jpg',
              onCancel: () {
                // Cancel the AI service analysis
                final aiService = ref.read(aiServiceProvider);
                aiService.cancelAnalysis();
                
                setState(() {
                  _isCancelled = true;
                  _isAnalyzing = false;
                });
                WasteAppLogger.info('Analysis cancelled by user.', null, null, {'service': 'screen', 'file': 'image_capture_screen'});
                
                // Show cancellation feedback
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Analysis cancelled.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
                // Navigate back to home screen
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            )
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
      ),
      body: _isAnalyzing
          ? EnhancedAnalysisLoader(
              imageName: _imageFile?.path.split('/').last ?? 
                         _xFile?.name ?? 
                         'captured_image.jpg',
              onCancel: () {
                // Cancel the AI service analysis
                final aiService = ref.read(aiServiceProvider);
                aiService.cancelAnalysis();
                
                setState(() {
                  _isCancelled = true;
                  _isAnalyzing = false;
                });
                WasteAppLogger.info('Analysis cancelled by user.', null, null, {'service': 'screen', 'file': 'image_capture_screen'});
                
                // Show cancellation feedback
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Analysis cancelled.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
                // Navigate back if cancelled
                Navigator.pop(context); // Go back to the previous screen (e.g., camera)
              },
            )
          : Column(
              children: [
                // Image preview
                Expanded(
                  child: Center(
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
                                      children:
                                          List.generate(_segments.length, (index) {
                                        // Using segment bounds from Map
                                        final segment = _segments[index];
                                        final bounds = segment['bounds'] as Map<String, dynamic>;
                                        final left = (bounds['x'] as num).toDouble() * imageWidth / 100;
                                        final top = (bounds['y'] as num).toDouble() * imageHeight / 100;
                                        final width = (bounds['width'] as num).toDouble() * imageWidth / 100;
                                        final height = (bounds['height'] as num).toDouble() * imageHeight / 100;
                                        final selected =
                                            _selectedSegments.contains(index);

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
                                                    ? Colors.blue.withValues(alpha: 0.3)
                                                    : Colors.transparent,
                                                border: Border.all(
                                                  color: selected
                                                      ? Colors.blue
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
                ),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(AppTheme.paddingRegular),
                  color: Colors.black.withValues(alpha: 0.05),
                  child: const Row(
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

                // Segmentation toggle with premium feature indication
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.paddingRegular),
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
                          WasteAppLogger.severe('Segmentation failed', e, null, {'service': 'screen', 'file': 'image_capture_screen'});
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content:
                                    Text('Segmentation failed: ${e.toString()}'),
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
                if (_useSegmentation && _segments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_segments.length} objects detected. Tap to select for analysis.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                        
                // Speed selector
                const SizedBox(height: 16),
                AnalysisSpeedSelector(
                  selectedSpeed: _selectedSpeed,
                  onSpeedChanged: (AnalysisSpeed speed) {
                    setState(() {
                      _selectedSpeed = speed;
                    });
                  },
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(AppTheme.paddingRegular),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                                // Show tip about auto-analyze
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('💡 Tip: Use camera button with long press for instant analysis!'),
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

  Widget _buildAnalyzeButton() {
    final speedText = _selectedSpeed == AnalysisSpeed.instant ? 'Instant' : 'Batch';
    final tokenCost = _selectedSpeed.cost;
    
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
            : Icon(_selectedSpeed == AnalysisSpeed.instant ? Icons.flash_on : Icons.schedule),
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

  Widget _buildImagePreview() {
    Widget imageWidget;
    
    if (kIsWeb) {
      if (_webImageBytes != null) {
        imageWidget = Image.memory(
          _webImageBytes!,
          fit: BoxFit.contain,
        );
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    } else {
      // For mobile, use imageFile if available, otherwise convert xFile to File
      final file = _imageFile ?? File(_xFile!.path);
      imageWidget = Image.file(
        file,
        fit: BoxFit.contain,
      );
    }
    
    // Wrap with InteractiveViewer for zoom functionality
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: InteractiveViewer(
        minScale: 0.5, // Minimum zoom out
        maxScale: 4.0, // Maximum zoom in
        child: Stack(
          fit: StackFit.expand, // FIXED: Use StackFit.expand instead of infinite container
          children: [
          // FIXED: Center the image within available space
          Center(child: imageWidget),
          // Zoom instruction overlay (shows briefly)
          Positioned(
            top: 16,
            left: 16,
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
                  Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 16,
                  ),
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
    ));
  }

  @override
  void dispose() {
    _imagePath.dispose();
    _useSegmentationRestorable.dispose();
    super.dispose();
  }
}
