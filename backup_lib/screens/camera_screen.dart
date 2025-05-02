import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import '../widgets/enhanced_camera.dart';
import 'image_capture_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isProcessing = false;
  String? _errorMessage;

  void _onImageCaptured(XFile image) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      if (kIsWeb) {
        // For web, convert XFile to bytes
        final Uint8List bytes = await image.readAsBytes();
        _navigateToImageCapture(image: image, webImageBytes: bytes);
      } else {
        // For mobile, convert to File
        final File imageFile = File(image.path);
        if (await imageFile.exists()) {
          _navigateToImageCapture(imageFile: imageFile);
        } else {
          throw Exception('Image file does not exist: ${image.path}');
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error processing image: $e';
      });
      debugPrint('Error processing captured image: $e');
    }
  }

  void _navigateToImageCapture(
      {File? imageFile, XFile? image, Uint8List? webImageBytes}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCaptureScreen(
          imageFile: imageFile,
          xFile: image,
          webImage: webImageBytes,
        ),
      ),
    ).then((_) {
      setState(() {
        _isProcessing = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Main camera content
          Container(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instructions
                const Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: AppTheme.paddingRegular),
                  child: Text(
                    'Position the waste item clearly in the center of the frame for the best classification results.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeRegular,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.paddingRegular),

                // Camera view
                Expanded(
                  child: Center(
                    child: EnhancedCamera(
                      onImageCaptured: _onImageCaptured,
                      onError: (error) {
                        setState(() {
                          _errorMessage = error;
                        });
                      },
                      previewDecoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusRegular),
                        border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.5),
                            width: 2),
                      ),
                    ),
                  ),
                ),

                // Error message if any
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.paddingRegular),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: AppTheme.fontSizeRegular,
                      ),
                    ),
                  ),

                const SizedBox(height: AppTheme.paddingRegular),

                // Close button
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.paddingRegular),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: AppTheme.paddingRegular),
                    Text(
                      'Processing image...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppTheme.fontSizeMedium,
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
