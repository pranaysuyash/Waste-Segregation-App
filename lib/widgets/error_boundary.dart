import 'package:flutter/material.dart';
import '../utils/waste_app_logger.dart';
import '../utils/error_handler.dart';

/// Error boundary widget to catch and handle widget tree errors
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.onError,
    this.showErrorDetails = false,
    this.context,
  });

  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? fallback;
  final void Function(Object error, StackTrace? stackTrace)? onError;
  final bool showErrorDetails;
  final String? context;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallback?.call(_error!, _stackTrace) ??
          _buildDefaultErrorWidget(context);
    }

    return ErrorCatchingWidget(
      onError: _handleError,
      child: widget.child,
    );
  }

  void _handleError(Object error, StackTrace? stackTrace) {
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
    });

    // Log the error
    WasteAppLogger.severe(
        'Error boundary caught error${widget.context != null ? ' in ${widget.context}' : ''}',
        error: error,
        stackTrace: stackTrace);

    // Call custom error handler if provided
    widget.onError?.call(error, stackTrace);
  }

  Widget _buildDefaultErrorWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We encountered an unexpected error. Please try again.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (widget.showErrorDetails && _error != null) ...[
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
                _stackTrace = null;
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

/// Widget that catches errors in its child widget tree
class ErrorCatchingWidget extends StatefulWidget {
  const ErrorCatchingWidget({
    super.key,
    required this.child,
    required this.onError,
  });

  final Widget child;
  final void Function(Object error, StackTrace? stackTrace) onError;

  @override
  State<ErrorCatchingWidget> createState() => _ErrorCatchingWidgetState();
}

class _ErrorCatchingWidgetState extends State<ErrorCatchingWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _catchErrors();
  }

  void _catchErrors() {
    FlutterError.onError = (FlutterErrorDetails details) {
      widget.onError(details.exception, details.stack);
    };
  }
}

/// Specialized error boundary for async operations
class AsyncErrorBoundary extends StatefulWidget {
  const AsyncErrorBoundary({
    super.key,
    required this.future,
    required this.builder,
    this.errorBuilder,
    this.loadingBuilder,
    this.context,
  });

  final Future<dynamic> future;
  final Widget Function(BuildContext context, dynamic data) builder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final String? context;

  @override
  State<AsyncErrorBoundary> createState() => _AsyncErrorBoundaryState();
}

class _AsyncErrorBoundaryState extends State<AsyncErrorBoundary> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Log the error
          WasteAppLogger.severe(
              'Async error boundary caught error${widget.context != null ? ' in ${widget.context}' : ''}',
              error: snapshot.error,
              stackTrace: snapshot.stackTrace);

          return widget.errorBuilder?.call(context, snapshot.error!) ??
              _buildDefaultAsyncErrorWidget(context, snapshot.error!);
        }

        return widget.builder(context, snapshot.data);
      },
    );
  }

  Widget _buildDefaultAsyncErrorWidget(BuildContext context, Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load data',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Trigger rebuild to retry the future
              });
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Error boundary specifically for network operations
class NetworkErrorBoundary extends StatelessWidget {
  const NetworkErrorBoundary({
    super.key,
    required this.child,
    this.onNetworkError,
  });

  final Widget child;
  final VoidCallback? onNetworkError;

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      context: 'Network Operation',
      onError: (error, stackTrace) {
        // Check if it's a network-related error
        if (_isNetworkError(error)) {
          onNetworkError?.call();
          ErrorHandler.showWarningMessage(
            context,
            'Network connection issue. Please check your internet connection.',
          );
        }
      },
      fallback: (error, stackTrace) {
        if (_isNetworkError(error)) {
          return _buildNetworkErrorWidget(context);
        }
        return _buildGenericErrorWidget(context, error);
      },
      child: child,
    );
  }

  bool _isNetworkError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('socket') ||
        errorString.contains('http');
  }

  Widget _buildNetworkErrorWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Connection Problem',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your internet connection and try again.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onNetworkError,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericErrorWidget(BuildContext context, Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We encountered an unexpected error. Please try again.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
