import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';

/// A simplified camera widget for Flutter web
/// This widget displays a dialog with a button to capture a photo
/// using the device's camera on web platforms
class SimpleWebCamera extends StatefulWidget {
  const SimpleWebCamera({
    super.key,
    required this.onCapture,
    this.title = 'Camera Access',
    this.buttonText = 'Take Photo',
  });
  final Function(XFile?) onCapture;
  final String title;
  final String buttonText;

  @override
  State<SimpleWebCamera> createState() => _SimpleWebCameraState();
}

class _SimpleWebCameraState extends State<SimpleWebCamera> {
  final ImagePicker _picker = ImagePicker();
  bool _isCapturing = false;

  Future<void> _captureImage() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // Use standard image_picker with camera source
      // On web, this will prompt the browser's file picker,
      // but most browsers will allow direct camera access
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 720,
        imageQuality: 90,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onCapture(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accessing camera: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Please allow camera access when prompted by your browser.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isCapturing ? null : _captureImage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: _isCapturing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(widget.buttonText),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: AppTheme.dialogCancelButtonStyle(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Shows a dialog with a camera access button
Future<void> showCameraDialog(
  BuildContext context, {
  required Function(XFile?) onCapture,
  String title = 'Camera Access',
  String buttonText = 'Take Photo',
}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return SimpleWebCamera(
        onCapture: onCapture,
        title: title,
        buttonText: buttonText,
      );
    },
  );
}
