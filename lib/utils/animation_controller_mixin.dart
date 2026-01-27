import 'package:flutter/material.dart';
import 'waste_app_logger.dart';

/// OPTIMIZATION: Mixin for managing AnimationController lifecycle
///
/// Provides automatic disposal of animation controllers to prevent memory leaks.
/// Use this mixin in StatefulWidget State classes that use animations.
///
/// Benefits:
/// - Automatic cleanup of all animation controllers
/// - Prevents memory leaks from undisposed controllers
/// - Centralized controller management
/// - Consistent disposal patterns across the app
///
/// Usage:
/// ```dart
/// class _MyWidgetState extends State<MyWidget>
///     with SingleTickerProviderStateMixin, AnimationControllerMixin {
///
///   late final AnimationController _fadeController;
///
///   @override
///   void initState() {
///     super.initState();
///     _fadeController = createController(
///       duration: Duration(milliseconds: 300),
///     );
///   }
///
///   // dispose() is automatically called by the mixin
/// }
/// ```
mixin AnimationControllerMixin<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  final List<AnimationController> _controllers = [];

  /// Create an AnimationController that will be automatically disposed
  ///
  /// [duration] - The length of time this animation should last
  /// [reverseDuration] - The length of time for the reverse animation (optional)
  /// [debugLabel] - A label to use when reporting errors (optional)
  /// [lowerBound] - The lowest value the animation can have (default: 0.0)
  /// [upperBound] - The highest value the animation can have (default: 1.0)
  /// [animationBehavior] - How the animation behaves when the app is in the background
  AnimationController createController({
    required Duration duration,
    Duration? reverseDuration,
    String? debugLabel,
    double lowerBound = 0.0,
    double upperBound = 1.0,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
  }) {
    final controller = AnimationController(
      duration: duration,
      reverseDuration: reverseDuration,
      debugLabel: debugLabel,
      lowerBound: lowerBound,
      upperBound: upperBound,
      vsync: this,
      animationBehavior: animationBehavior,
    );

    _controllers.add(controller);
    return controller;
  }

  /// Get the number of managed controllers
  int get controllerCount => _controllers.length;

  /// Check if any controllers are currently animating
  bool get isAnyAnimating => _controllers.any((c) => c.isAnimating);

  /// Dispose all controllers at once
  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }
}

/// OPTIMIZATION: Mixin for managing multiple types of disposable resources
///
/// Extends AnimationControllerMixin to also handle other disposable resources
/// like StreamSubscriptions, Timers, etc.
///
/// Usage:
/// ```dart
/// class _MyWidgetState extends State<MyWidget>
///     with SingleTickerProviderStateMixin, ResourceManagementMixin {
///
///   late final AnimationController _controller;
///   late final StreamSubscription _subscription;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = createController(duration: Duration(seconds: 1));
///     _subscription = stream.listen((data) { });
///     registerDisposable(_subscription);
///   }
/// }
/// ```
mixin ResourceManagementMixin<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T>
    implements AnimationControllerMixin<T> {
  @override
  final List<AnimationController> _controllers = [];
  final List<void Function()> _disposables = [];

  @override
  AnimationController createController({
    required Duration duration,
    Duration? reverseDuration,
    String? debugLabel,
    double lowerBound = 0.0,
    double upperBound = 1.0,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
  }) {
    final controller = AnimationController(
      duration: duration,
      reverseDuration: reverseDuration,
      debugLabel: debugLabel,
      lowerBound: lowerBound,
      upperBound: upperBound,
      vsync: this,
      animationBehavior: animationBehavior,
    );

    _controllers.add(controller);
    return controller;
  }

  /// Register a disposable resource (StreamSubscription, Timer, etc.)
  ///
  /// The dispose function will be called automatically when the widget is disposed.
  ///
  /// Example:
  /// ```dart
  /// final subscription = stream.listen((data) { });
  /// registerDisposable(() => subscription.cancel());
  ///
  /// final timer = Timer.periodic(Duration(seconds: 1), (_) { });
  /// registerDisposable(() => timer.cancel());
  /// ```
  void registerDisposable(dynamic resource) {
    if (resource is void Function()) {
      _disposables.add(resource);
    } else if (resource.runtimeType.toString().contains('StreamSubscription')) {
      _disposables.add(() => (resource as dynamic).cancel());
    } else if (resource.runtimeType.toString().contains('Timer')) {
      _disposables.add(() => (resource as dynamic).cancel());
    } else {
      throw ArgumentError('Unsupported resource type: ${resource.runtimeType}. '
          'Pass a disposal function instead: registerDisposable(() => resource.dispose())');
    }
  }

  @override
  int get controllerCount => _controllers.length;

  @override
  bool get isAnyAnimating => _controllers.any((c) => c.isAnimating);

  /// Get the number of registered disposables
  int get disposableCount => _disposables.length;

  @override
  void dispose() {
    // Dispose all animation controllers
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();

    // Call all registered disposal functions
    for (final disposeFn in _disposables) {
      try {
        disposeFn();
      } catch (e) {
        // Log but don't throw to ensure all resources are cleaned up
        WasteAppLogger.warning('Error disposing resource: $e');
      }
    }
    _disposables.clear();

    super.dispose();
  }
}
