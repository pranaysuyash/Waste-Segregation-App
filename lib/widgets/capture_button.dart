import 'package:flutter/material.dart';
import '../utils/constants.dart';
// Use platform-agnostic camera

enum CaptureButtonType {
  camera,
  gallery,
  analyze,
  retry,
}

class CaptureButton extends StatefulWidget {
  final CaptureButtonType type;
  final VoidCallback onPressed;
  final bool isLoading;

  const CaptureButton({
    super.key,
    required this.type,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<CaptureButton> {
  void _handlePress() {
    // Simple handler that just calls the provided callback
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    // Button configuration based on type
    late final IconData icon;
    late final String label;
    late final Color color;

    switch (widget.type) {
      case CaptureButtonType.camera:
        icon = Icons.camera_alt_rounded;
        label = AppStrings.captureImage;
        color = AppTheme.primaryColor;
        break;
      case CaptureButtonType.gallery:
        icon = Icons.photo_library_rounded;
        label = AppStrings.uploadImage;
        color = AppTheme.secondaryColor;
        break;
      case CaptureButtonType.analyze:
        icon = Icons.analytics_rounded;
        label = AppStrings.analyzeImage;
        color = AppTheme.secondaryColor;
        break;
      case CaptureButtonType.retry:
        icon = Icons.refresh_rounded;
        label = AppStrings.retakePhoto;
        color = Colors.red;
        break;
    }

    // Generate semantic label for accessibility
    String semanticLabel;
    switch (widget.type) {
      case CaptureButtonType.camera:
        semanticLabel = widget.isLoading 
            ? 'Taking photo, please wait' 
            : 'Take photo with camera';
        break;
      case CaptureButtonType.gallery:
        semanticLabel = widget.isLoading 
            ? 'Opening gallery, please wait' 
            : 'Select image from gallery';
        break;
      case CaptureButtonType.analyze:
        semanticLabel = widget.isLoading 
            ? 'Analyzing image, please wait' 
            : 'Analyze image for waste classification';
        break;
      case CaptureButtonType.retry:
        semanticLabel = widget.isLoading 
            ? 'Retaking photo, please wait' 
            : 'Retake photo';
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: Semantics(
        label: semanticLabel,
        button: true,
        enabled: !widget.isLoading,
        child: ElevatedButton.icon(
          onPressed: widget.isLoading ? null : _handlePress,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.paddingRegular,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
            ),
          ),
          icon: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.0,
                  ),
                )
              : Semantics(
                  excludeSemantics: true, // Exclude icon from semantics since button has label
                  child: Icon(icon),
                ),
          label: Text(
            widget.isLoading && widget.type == CaptureButtonType.analyze
                ? AppStrings.analyzing
                : label,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
