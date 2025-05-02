import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import 'platform_camera.dart';

enum CameraViewMode {
  preview, // Show camera preview
  button, // Show camera button
  fallback, // Fallback view when camera isn't available
}

/// A widget that provides an enhanced camera experience with fallbacks
/// for different platforms and environments.
class EnhancedCamera extends StatefulWidget {
  /// Callback when an image is captured
  final Function(XFile) onImageCaptured;

  /// Callback when an error occurs
  final Function(String)? onError;

  /// Initial mode to start with
  final CameraViewMode initialMode;

  /// Whether to show the gallery button
  final bool showGalleryButton;

  /// Size of the camera preview
  final Size? previewSize;

  /// Decoration for the camera preview container
  final BoxDecoration? previewDecoration;

  const EnhancedCamera({
    super.key,
    required this.onImageCaptured,
    this.onError,
    this.initialMode = CameraViewMode.preview,
    this.showGalleryButton = true,
    this.previewSize,
    this.previewDecoration,
  });

  @override
  State<EnhancedCamera> createState() => _EnhancedCameraState();
}

class _EnhancedCameraState extends State<EnhancedCamera>
    with WidgetsBindingObserver {
  CameraViewMode _currentMode = CameraViewMode.preview;
  bool _isInitializing = true;
  bool _isTakingPicture = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentMode = widget.initialMode;
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes to properly manage camera resources
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // App is in background or inactive, clean up camera
      PlatformCamera.cleanup();
    } else if (state == AppLifecycleState.resumed) {
      // App is resumed, reinitialize camera
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PlatformCamera.cleanup();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      // Try initializing the camera
      final bool cameraSetupSuccess = await PlatformCamera.setup();

      // Set the appropriate mode based on the result
      if (cameraSetupSuccess && _currentMode == CameraViewMode.preview) {
        setState(() {
          _currentMode = CameraViewMode.preview;
          _isInitializing = false;
        });
      } else {
        // Fallback to button mode
        setState(() {
          _currentMode = CameraViewMode.button;
          _isInitializing = false;
        });

        // Log why we're falling back
        if (!cameraSetupSuccess) {
          debugPrint('Camera setup failed, falling back to button mode');
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      setState(() {
        _errorMessage = 'Camera initialization failed: $e';
        _currentMode = CameraViewMode.fallback;
        _isInitializing = false;
      });

      if (widget.onError != null) {
        widget.onError!('Camera initialization failed: $e');
      }
    }
  }

  Future<void> _takePicture() async {
    if (_isTakingPicture) return;

    setState(() {
      _isTakingPicture = true;
      _errorMessage = null;
    });

    try {
      final XFile? image = await PlatformCamera.takePicture();

      setState(() {
        _isTakingPicture = false;
      });

      if (image != null) {
        widget.onImageCaptured(image);
      } else {
        setState(() {
          _errorMessage = 'Failed to capture image';
        });

        if (widget.onError != null) {
          widget.onError!('Failed to capture image');
        }
      }
    } catch (e) {
      setState(() {
        _isTakingPicture = false;
        _errorMessage = 'Error taking picture: $e';
      });

      if (widget.onError != null) {
        widget.onError!('Error taking picture: $e');
      }

      debugPrint('Error taking picture: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await PlatformCamera.pickImage();

      if (image != null) {
        widget.onImageCaptured(image);
      }
    } catch (e) {
      if (widget.onError != null) {
        widget.onError!('Error picking image: $e');
      }
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    switch (_currentMode) {
      case CameraViewMode.preview:
        return _buildCameraPreview();
      case CameraViewMode.button:
        return _buildCameraButton();
      case CameraViewMode.fallback:
        return _buildFallbackView();
    }
  }

  Widget _buildCameraPreview() {
    // Pass null to get a placeholder preview
    final Widget cameraPreview = PlatformCamera.getCameraPreview(null);

    return Container(
      width: widget.previewSize?.width,
      height: widget.previewSize?.height,
      decoration: widget.previewDecoration ??
          BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
            border: Border.all(color: Colors.grey.shade300),
          ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          cameraPreview,

          // Capture button overlay
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Capture button
                _buildCaptureButton(),

                // Gallery button
                if (widget.showGalleryButton) ...[
                  const SizedBox(width: 16),
                  _buildGalleryButton(),
                ],
              ],
            ),
          ),

          // Loading overlay when taking picture
          if (_isTakingPicture)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: _isTakingPicture ? null : _takePicture,
          icon: const Icon(Icons.camera_alt),
          label: _isTakingPicture
              ? const Text('Capturing...')
              : const Text('Take Picture'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
        if (widget.showGalleryButton) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_library),
            label: const Text('Select from Gallery'),
          ),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFallbackView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.camera_alt_outlined,
          size: 64,
          color: Colors.grey,
        ),
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? 'Camera not available',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        if (widget.showGalleryButton)
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_library),
            label: const Text('Select from Gallery'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _isTakingPicture ? null : _takePicture,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.8),
          border: Border.all(color: AppTheme.primaryColor, width: 2),
        ),
        child: Center(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isTakingPicture ? Colors.grey : AppTheme.primaryColor,
            ),
            child: _isTakingPicture
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  )
                : const Icon(Icons.camera_alt, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.8),
        ),
        child: const Icon(
          Icons.photo_library,
          color: AppTheme.secondaryColor,
          size: 24,
        ),
      ),
    );
  }
}
