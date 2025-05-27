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
  final File? imageFile;
  final XFile? xFile;
  final Uint8List? webImage;

  const ImageCaptureScreen({
    super.key,
    this.imageFile,
    this.xFile,
    this.webImage,
  }) : assert(imageFile != null || xFile != null || webImage != null);

  // Factory constructor for creating from XFile (useful for web)
  factory ImageCaptureScreen.fromXFile(XFile xFile) =>
      ImageCaptureScreen(xFile: xFile);

  @override
  State<ImageCaptureScreen> createState() => _ImageCaptureScreenState();
}

class _ImageCaptureScreenState extends State<ImageCaptureScreen> {
  bool _isAnalyzing = false;
  bool _isCancelled = false;
  Uint8List? _webImageBytes;

  bool _useSegmentation = false;
  List<Map<String, dynamic>> _segments = [];
  final Set<int> _selectedSegments = {};

  @override
  void initState() {
    super.initState();
    if (kIsWeb && widget.xFile != null) {
      _loadWebImage();
    }
  }

  Future<void> _loadWebImage() async {
    if (widget.xFile != null) {
      final bytes = await widget.xFile!.readAsBytes();
      setState(() {
        _webImageBytes = bytes;
      });
    }
  }

  Future<void> _runSegmentation() async {
    final aiService = Provider.of<AiService>(context, listen: false);
    List<Map<String, dynamic>> segments;
    if (kIsWeb) {
      Uint8List? imageBytes = _webImageBytes ?? widget.webImage;
      if (imageBytes == null || imageBytes.isEmpty) {
        throw Exception('No image data available for segmentation');
      }
      segments = await aiService.segmentImage(imageBytes);
    } else {
      if (widget.imageFile == null) {
        throw Exception('No image file available for segmentation');
      }
      segments = await aiService.segmentImage(widget.imageFile!);
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
        if (widget.xFile != null) {
          // First check if we already have the web image bytes loaded
          Uint8List? imageBytes = _webImageBytes;

          // If not, read them now
          if (imageBytes == null) {
            try {
              imageBytes = await widget.xFile!.readAsBytes();

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
              'Analyzing web image: ${widget.xFile!.name}, size: ${imageBytes.length} bytes');

          if (_useSegmentation && _selectedSegments.isNotEmpty) {
            // Already using our custom Rect type from segmentImage()
            classification = await aiService.analyzeImageSegmentsWeb(
              imageBytes,
              widget.xFile!.name,
              _selectedSegments.map((i) => _segments[i]).toList(),
            );
          } else {
            classification = await aiService.analyzeWebImage(
              imageBytes,
              widget.xFile!.name,
            );
          }

          // Log success for debugging
          debugPrint('Web image analysis complete: ${classification.itemName}');
        } else if (widget.webImage != null) {
          // Check if cancelled before starting analysis
          if (_isCancelled) {
            debugPrint('Analysis cancelled before starting web bytes analysis');
            return;
          }

          // We were provided with the image bytes directly
          debugPrint(
              'Analyzing web image from bytes, size: ${widget.webImage!.length} bytes');

          if (_useSegmentation && _selectedSegments.isNotEmpty) {
            // Using our custom Rect class from segmentImage()
            classification = await aiService.analyzeImageSegmentsWeb(
              widget.webImage!,
              'uploaded_image.jpg',
              _selectedSegments.map((i) => _segments[i]).toList(),
            );
          } else {
            classification = await aiService.analyzeWebImage(
              widget.webImage!,
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
        if (widget.imageFile != null) {
          // Check if cancelled before starting analysis
          if (_isCancelled) {
            debugPrint('Analysis cancelled before starting mobile analysis');
            return;
          }

          debugPrint('Analyzing mobile image file: ${widget.imageFile!.path}');

          // Check if file exists and is readable
          if (await widget.imageFile!.exists()) {
            if (_useSegmentation && _selectedSegments.isNotEmpty) {
              // Using our custom Rect class from segmentImage()
              classification = await aiService.analyzeImageSegments(
                widget.imageFile!,
                _selectedSegments.map((i) => _segments[i]).toList(),
              );
            } else {
              classification = await aiService.analyzeImage(widget.imageFile!);
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
        return;
      }

      if (mounted && !_isCancelled) {
        debugPrint('Navigation to results screen with classification');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              classification: classification,
              showActions: true,
            ),
          ),
        );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Image'),
      ),
      body: _isAnalyzing
          ? EnhancedAnalysisLoader(
              imageName: widget.imageFile?.path.split('/').last ?? 
                         widget.xFile?.name ?? 
                         'captured_image.jpg',
              onCancel: () {
                setState(() {
                  _isCancelled = true;
                  _isAnalyzing = false;
                });
                debugPrint('Analysis cancelled by user');
                
                // Show cancellation feedback
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Analysis cancelled'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              estimatedDuration: const Duration(seconds: 17), // 14-20s average
              showEducationalTips: true,
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
                                                    ? Colors.blue.withOpacity(0.3)
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
                  color: Colors.black.withOpacity(0.05),
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
                        width: 1,
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
                                    fontSize: 10,
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
                            if (value && _segments.isEmpty) {
                              try {
                                await _runSegmentation();
                              } catch (e) {
                                debugPrint('Segmentation error: $e');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                                      fontSize: 12,
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
                      CaptureButton(
                        type: CaptureButtonType.analyze,
                        onPressed: _analyzeImage,
                        isLoading: false, // Always false since we show custom loader
                      ),
                      const SizedBox(height: AppTheme.paddingRegular),
                      CaptureButton(
                        type: CaptureButtonType.retry,
                        onPressed: () => Navigator.pop(context),
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
      } else if (widget.webImage != null) {
        imageWidget = Image.memory(
          widget.webImage!,
          fit: BoxFit.contain,
        );
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    } else {
      imageWidget = Image.file(
        widget.imageFile!,
        fit: BoxFit.contain,
      );
    }
    
    // Wrap with InteractiveViewer for zoom functionality
    return InteractiveViewer(
      panEnabled: true, // Allow panning
      scaleEnabled: true, // Allow zooming
      minScale: 0.5, // Minimum zoom out
      maxScale: 4.0, // Maximum zoom in
      constrained: true, // FIXED: Use constrained layout to prevent infinite constraints
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
                color: Colors.black.withOpacity(0.7),
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
    );
  }
}
