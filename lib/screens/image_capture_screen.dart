import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/waste_classification.dart';
import '../services/ai_service.dart';
import '../utils/constants.dart';
import '../widgets/capture_button.dart';
import 'result_screen.dart';

class ImageCaptureScreen extends StatefulWidget {
  final File? imageFile;
  final XFile? xFile;
  final Uint8List? webImage;

  const ImageCaptureScreen({
    Key? key,
    this.imageFile,
    this.xFile,
    this.webImage,
  }) : assert(imageFile != null || xFile != null || webImage != null),
       super(key: key);

  // Factory constructor for creating from XFile (useful for web)
  factory ImageCaptureScreen.fromXFile(XFile xFile) => ImageCaptureScreen(xFile: xFile);

  @override
  State<ImageCaptureScreen> createState() => _ImageCaptureScreenState();
}

class _ImageCaptureScreenState extends State<ImageCaptureScreen> {
  bool _isAnalyzing = false;
  Uint8List? _webImageBytes;

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
          if (imageBytes == null || imageBytes.isEmpty) {
            throw Exception('Image data is empty or could not be read');
          }
          
          // Log the image size for debugging
          debugPrint('Analyzing web image: ${widget.xFile!.name}, size: ${imageBytes.length} bytes');
          
          // Analyze the image
          classification = await aiService.analyzeWebImage(
            imageBytes,
            widget.xFile!.name,
          );
          
          // Log success for debugging
          debugPrint('Web image analysis complete: ${classification.itemName}');
        } else if (widget.webImage != null) {
          // We were provided with the image bytes directly
          debugPrint('Analyzing web image from bytes, size: ${widget.webImage!.length} bytes');
          
          // Analyze the image
          classification = await aiService.analyzeWebImage(
            widget.webImage!,
            'uploaded_image.jpg',
          );
          
          // Log success for debugging
          debugPrint('Web image bytes analysis complete: ${classification.itemName}');
        } else {
          throw Exception('No image provided for analysis');
        }
      } else {
        // For mobile platforms
        if (widget.imageFile != null) {
          debugPrint('Analyzing mobile image file: ${widget.imageFile!.path}');
          
          // Check if file exists and is readable
          if (await widget.imageFile!.exists()) {
            classification = await aiService.analyzeImage(widget.imageFile!);
            debugPrint('Mobile image analysis complete: ${classification.itemName}');
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
              child: _buildImagePreview(),
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
        );
      } else if (widget.webImage != null) {
        return Image.memory(
          widget.webImage!,
          fit: BoxFit.contain,
        );
      } else {
        return const CircularProgressIndicator();
      }
    } else {
      return Image.file(
        widget.imageFile!,
        fit: BoxFit.contain,
      );
    }
  }
}