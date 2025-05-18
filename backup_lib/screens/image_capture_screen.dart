import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/waste_classification.dart';
import '../services/ai_service.dart';
import '../utils/constants.dart';
import '../utils/image_utils.dart' show Rect;
import '../widgets/capture_button.dart';
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
  Uint8List? _webImageBytes;

  bool _useSegmentation = false;
  List<Rect> _segments = [];
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
    List<Rect> segments;
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

          // Log the image size for debugging
          debugPrint(
              'Analyzing web image: ${widget.xFile!.name}, size: ${imageBytes.length} bytes');

          if (_useSegmentation && _selectedSegments.isNotEmpty) {
            // Already using our custom Rect type from segmentImage()
            classification = await aiService.analyzeImageSegmentsWeb(
              imageBytes,
              _selectedSegments.map((i) => _segments[i]).toList(),
              widget.xFile!.name,
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
          // We were provided with the image bytes directly
          debugPrint(
              'Analyzing web image from bytes, size: ${widget.webImage!.length} bytes');

          if (_useSegmentation && _selectedSegments.isNotEmpty) {
            // Using our custom Rect class from segmentImage()
            classification = await aiService.analyzeImageSegmentsWeb(
              widget.webImage!,
              _selectedSegments.map((i) => _segments[i]).toList(),
              'uploaded_image.jpg',
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

      if (mounted) {
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
      if (mounted) {
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
      body: Column(
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
                                  // Using our custom Rect class
                                  final rect = _segments[index];
                                  final left = rect.left * imageWidth;
                                  final top = rect.top * imageHeight;
                                  final width = rect.width * imageWidth;
                                  final height = rect.height * imageHeight;
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
          if (!_isAnalyzing)
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

          // Segmentation toggle
          if (!_isAnalyzing)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingRegular),
              child: SwitchListTile(
                title: const Text('Segment'),
                value: _useSegmentation,
                onChanged: (bool value) async {
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
                  isLoading: _isAnalyzing,
                ),
                const SizedBox(height: AppTheme.paddingRegular),
                if (!_isAnalyzing)
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
    if (kIsWeb) {
      if (_webImageBytes != null) {
        return Image.memory(
          _webImageBytes!,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        );
      } else if (widget.webImage != null) {
        return Image.memory(
          widget.webImage!,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        );
      } else {
        return const CircularProgressIndicator();
      }
    } else {
      return Image.file(
        widget.imageFile!,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      );
    }
  }
}
