import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/waste_app_logger.dart';

/// Service for providing immediate visual and haptic feedback to users
class VisualFeedbackService {
  VisualFeedbackService._();
  static VisualFeedbackService? _instance;
  static VisualFeedbackService get instance =>
      _instance ??= VisualFeedbackService._();

  bool _hapticsEnabled = true;
  bool _animationsEnabled = true;

  /// Initialize the visual feedback service
  void initialize({
    bool hapticsEnabled = true,
    bool animationsEnabled = true,
  }) {
    _hapticsEnabled = hapticsEnabled;
    _animationsEnabled = animationsEnabled;

    WasteAppLogger.info('Visual Feedback Service initialized', context: {
      'haptics_enabled': _hapticsEnabled,
      'animations_enabled': _animationsEnabled,
      'service': 'VisualFeedbackService',
    });
  }

  /// Provide light haptic feedback for button taps
  Future<void> lightImpact() async {
    if (!_hapticsEnabled) return;

    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      WasteAppLogger.warning('Failed to provide light haptic feedback',
          context: {
            'error': e.toString(),
            'service': 'VisualFeedbackService',
          });
    }
  }

  /// Provide medium haptic feedback for important actions
  Future<void> mediumImpact() async {
    if (!_hapticsEnabled) return;

    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      WasteAppLogger.warning('Failed to provide medium haptic feedback',
          context: {
            'error': e.toString(),
            'service': 'VisualFeedbackService',
          });
    }
  }

  /// Provide heavy haptic feedback for critical actions
  Future<void> heavyImpact() async {
    if (!_hapticsEnabled) return;

    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      WasteAppLogger.warning('Failed to provide heavy haptic feedback',
          context: {
            'error': e.toString(),
            'service': 'VisualFeedbackService',
          });
    }
  }

  /// Provide selection haptic feedback for picker/selector interactions
  Future<void> selectionClick() async {
    if (!_hapticsEnabled) return;

    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      WasteAppLogger.warning('Failed to provide selection haptic feedback',
          context: {
            'error': e.toString(),
            'service': 'VisualFeedbackService',
          });
    }
  }

  /// Provide vibration pattern for success feedback
  Future<void> successFeedback() async {
    if (!_hapticsEnabled) return;

    try {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.lightImpact();
    } catch (e) {
      WasteAppLogger.warning('Failed to provide success haptic feedback',
          context: {
            'error': e.toString(),
            'service': 'VisualFeedbackService',
          });
    }
  }

  /// Provide vibration pattern for error feedback
  Future<void> errorFeedback() async {
    if (!_hapticsEnabled) return;

    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
    } catch (e) {
      WasteAppLogger.warning('Failed to provide error haptic feedback',
          context: {
            'error': e.toString(),
            'service': 'VisualFeedbackService',
          });
    }
  }

  /// Show a loading overlay with customizable content
  void showLoadingOverlay(
    BuildContext context, {
    String? message,
    bool barrierDismissible = false,
    Color? barrierColor,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      builder: (context) => LoadingOverlay(message: message),
    );
  }

  /// Hide the loading overlay
  void hideLoadingOverlay(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Show a success snackbar with haptic feedback
  void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    successFeedback();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show an error snackbar with haptic feedback
  void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    errorFeedback();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show an info snackbar
  void showInfoSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Create a bounce animation for button press feedback
  Animation<double> createBounceAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  /// Create a fade animation for state transitions
  Animation<double> createFadeAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  /// Create a slide animation for page transitions
  Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  /// Create a scale animation for popup/modal appearances
  Animation<double> createScaleAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ),
    );
  }

  /// Enable or disable haptic feedback
  void setHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
    WasteAppLogger.info('Haptics ${enabled ? 'enabled' : 'disabled'}',
        context: {
          'service': 'VisualFeedbackService',
        });
  }

  /// Enable or disable animations
  void setAnimationsEnabled(bool enabled) {
    _animationsEnabled = enabled;
    WasteAppLogger.info('Animations ${enabled ? 'enabled' : 'disabled'}',
        context: {
          'service': 'VisualFeedbackService',
        });
  }

  /// Get current haptics setting
  bool get hapticsEnabled => _hapticsEnabled;

  /// Get current animations setting
  bool get animationsEnabled => _animationsEnabled;
}

/// Loading overlay widget with customizable content
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Button with built-in visual and haptic feedback
class FeedbackButton extends StatefulWidget {
  const FeedbackButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.hapticFeedback = HapticFeedbackType.light,
    this.animationDuration = const Duration(milliseconds: 150),
    this.style,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final HapticFeedbackType hapticFeedback;
  final Duration animationDuration;
  final ButtonStyle? style;

  @override
  State<FeedbackButton> createState() => _FeedbackButtonState();
}

class _FeedbackButtonState extends State<FeedbackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = VisualFeedbackService.instance
        .createBounceAnimation(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (widget.onPressed == null) return;

    // Provide haptic feedback
    switch (widget.hapticFeedback) {
      case HapticFeedbackType.light:
        await VisualFeedbackService.instance.lightImpact();
        break;
      case HapticFeedbackType.medium:
        await VisualFeedbackService.instance.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        await VisualFeedbackService.instance.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        await VisualFeedbackService.instance.selectionClick();
        break;
    }

    // Animate button press
    await _animationController.forward();
    await _animationController.reverse();

    // Call the actual onPressed callback
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ElevatedButton(
            onPressed: widget.onPressed != null ? _handlePress : null,
            style: widget.style,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Enum for different types of haptic feedback
enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
}

/// Loading state widget for async operations
class LoadingStateWidget extends StatelessWidget {
  const LoadingStateWidget({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingWidget,
    this.loadingMessage,
  });

  final bool isLoading;
  final Widget child;
  final Widget? loadingWidget;
  final String? loadingMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ??
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              if (loadingMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  loadingMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          );
    }

    return child;
  }
}

/// Animated state transition widget
class AnimatedStateTransition extends StatefulWidget {
  const AnimatedStateTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  State<AnimatedStateTransition> createState() =>
      _AnimatedStateTransitionState();
}

class _AnimatedStateTransitionState extends State<AnimatedStateTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedStateTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child.runtimeType != widget.child.runtimeType) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.child,
    );
  }
}

/// Extension to easily add visual feedback to any widget
extension VisualFeedbackExtension on Widget {
  /// Wrap this widget with loading state functionality
  Widget withLoadingState({
    required bool isLoading,
    Widget? loadingWidget,
    String? loadingMessage,
  }) {
    return LoadingStateWidget(
      isLoading: isLoading,
      loadingWidget: loadingWidget,
      loadingMessage: loadingMessage,
      child: this,
    );
  }

  /// Wrap this widget with animated state transitions
  Widget withAnimatedTransition({
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return AnimatedStateTransition(
      duration: duration,
      curve: curve,
      child: this,
    );
  }
}
