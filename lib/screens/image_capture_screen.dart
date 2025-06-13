import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/waste_classification.dart';
import '../services/ai_service.dart';
import '../utils/constants.dart';

import '../widgets/capture_button.dart';
import '../widgets/enhanced_analysis_loader.dart';
import 'result_screen.dart';

class ImageCaptureScreen extends StatefulWidget {

  const ImageCaptureScreen({
    super.key,
    this.imageFile,
    this.xFile,
    this.webImage,
    this.autoAnalyze = false,
  });

  // Factory constructor for creating from XFile (useful for web and mobile)
  factory ImageCaptureScreen.fromXFile(XFile xFile, {bool autoAnalyze = false}) =>
      ImageCaptureScreen(
        xFile: xFile,
        imageFile: kIsWeb ? null : File(xFile.path), // Convert XFile to File for mobile
        autoAnalyze: autoAnalyze,
      );
  final File? imageFile;
  final XFile? xFile;
  final Uint8List? webImage;
  final bool autoAnalyze;

  @override
  State<ImageCaptureScreen> createState() => _ImageCaptureScreenState();
}

class _ImageCaptureScreenState extends State<ImageCaptureScreen> with RestorationMixin {
  bool _isAnalyzing = false;
  bool _isCancelled = false;

  // Local state for holding image data
  File? _imageFile;
  XFile? _xFile;
  Uint8List? _webImageBytes;

  bool _useSegmentation = false;
  List<Map<String, dynamic>> _segments = [];
  final Set<int> _selectedSegments = {};

  // Restoration properties
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
    
    // Initialize restoration properties after registration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_imageFile != null) {
        _imagePath.value = _imageFile!.path;
      } else if (_xFile != null) {
        _imagePath.value = _xFile!.path;
      }
      _useSegmentationRestorable.value = _useSegmentation;
      
      // Auto-analyze if enabled and image is available
      if (widget.autoAnalyze && (_imageFile != null || _xFile != null || _webImageBytes != null)) {
        debugPrint('🚀 Auto-analyze enabled - starting analysis immediately');
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
        // Set restoration property safely after state update
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
      // User cancelled, pop the screen if there's no image
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
    final aiService = Provider.of<AiService>(context, listen: false);
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
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _isCancelled = false; // Reset cancellation state
    });

    try {
      final aiService = Provider.of<AiService>(context, listen: false);
      late WasteClassification classification;

      if (kIsWeb) {
        // For web, we need to handle the image differently
        if (_xFile != null) {
          // First check if we already have the web image bytes loaded
          var imageBytes = _webImageBytes;

          // If not, read them now
          if (imageBytes == null) {
            try {
              imageBytes = await _xFile!.readAsBytes();

              // Check if cancelled during image reading
              if (_isCancelled) {
                debugPrint('Analysis cancelled during image reading');
                return;
              }

              // Cache the bytes
              if (mounted) {
                setState(() {
                  _webImageBytes = imageBytes;
                });
              }
            } catch (bytesError) {
              debugPrint('Error reading web image bytes: $bytesError');
              throw Exception('Failed to read image data: $bytesError');
            }
          }

          // Ensure we have bytes before proceeding
          if (imageBytes.isEmpty) {
            throw Exception('Image data is empty or could not be read');
          }

          // Check if cancelled before starting analysis
          if (_isCancelled) {
            debugPrint('Analysis cancelled before starting web analysis');
            return;
          }

          // Log the image size for debugging
          debugPrint(
              'Analyzing web image: ${_xFile!.name}, size: ${imageBytes.length} bytes');

          if (_useSegmentation && _selectedSegments.isNotEmpty) {
            // Already using our custom Rect type from segmentImage()
            classification = await aiService.analyzeImageSegmentsWeb(
              imageBytes,
              _xFile!.name,
              _selectedSegments.map((i) => _segments[i]).toList(),
            );
          } else {
            classification = await aiService.analyzeWebImage(
              imageBytes,
              _xFile!.name,
            );
          }

          // Log success for debugging
          debugPrint('Web image analysis complete: ${classification.itemName}');
        } else if (_webImageBytes != null) {
          // Check if cancelled before starting analysis
          if (_isCancelled) {
            debugPrint('Analysis cancelled before starting web bytes analysis');
            return;
          }

          // We were provided with the image bytes directly
          debugPrint(
              'Analyzing web image from bytes, size: ${_webImageBytes!.length} bytes');

          if (_useSegmentation && _selectedSegments.isNotEmpty) {
            // Using our custom Rect class from segmentImage()
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

          // Log success for debugging
          debugPrint(
              'Web image bytes analysis complete: ${classification.itemName}');
        } else {
          throw Exception('No image provided for analysis');
        }
      } else {
        // For mobile platforms
        if (_imageFile != null) {
          // Check if cancelled before starting analysis
          if (_isCancelled) {
            debugPrint('Analysis cancelled before starting mobile analysis');
            setState(() {
              _isAnalyzing = false;
            });
            return;
          }

          debugPrint('Analyzing mobile image file: ${_imageFile!.path}');

          // Check if file exists and is readable
          if (await _imageFile!.exists()) {
            if (_useSegmentation && _selectedSegments.isNotEmpty) {
              // Using our custom Rect class from segmentImage()
              classification = await aiService.analyzeImageSegments(
                _imageFile!,
                _selectedSegments.map((i) => _segments[i]).toList(),
              );
            } else {
              classification = await aiService.analyzeImage(_imageFile!);
            }
            debugPrint(
                'Mobile image analysis complete: ${classification.itemName}');
          } else {
            throw Exception('Image file does not exist or could not be read');
          }
        } else {
          throw Exception('No image provided for analysis');
        }
      }

      // Check if cancelled after analysis completes but before navigation
      if (_isCancelled) {
        debugPrint('Analysis cancelled after completion, not navigating to results');
        setState(() {
          _isAnalyzing = false;
        });
        return;
      }

      if (mounted && !_isCancelled) {
        debugPrint('Navigation to results screen with classification');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              classification: classification,
            ),
          ),
        ).then((_) {
          // Reset _isAnalyzing after navigation is complete
          if (mounted) {
            setState(() {
              _isAnalyzing = false;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Analysis error: $e');
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
                final aiService = Provider.of<AiService>(context, listen: false);
                aiService.cancelAnalysis();
                
                setState(() {
                  _isCancelled = true;
                  _isAnalyzing = false;
                });
                debugPrint('Analysis cancelled by user');
                
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
                final aiService = Provider.of<AiService>(context, listen: false);
                aiService.cancelAnalysis();
                
                setState(() {
                  _isCancelled = true;
                  _isAnalyzing = false;
                });
                debugPrint('Analysis cancelled by user');
                
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                      border: Border.all(
                        color: Colors.blue.shade200,
                      ),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Advanced Segmentation',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: const Text(
                            'Identify multiple objects in a single image',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _useSegmentation,
                          onChanged: (bool value) async {
                            // For now, allow all users to use segmentation
                            // In future, add subscription check here
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
                                debugPrint('Segmentation error: $e');
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
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(AppTheme.paddingRegular),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Quick analyze button (prominent)
                      CaptureButton(
                        type: CaptureButtonType.analyze,
                        onPressed: _analyzeImage,
                      ),
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
