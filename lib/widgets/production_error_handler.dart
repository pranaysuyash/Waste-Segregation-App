import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'gen_z_microinteractions.dart';
import '../utils/performance_optimizer.dart';

/// Production-ready error handler that prevents users from seeing internal errors
class ProductionErrorHandler extends StatelessWidget {

  const ProductionErrorHandler({
    Key? key,
    required this.child,
    this.fallbackTitle,
    this.fallbackMessage,
    this.onRetry,
    this.showRetryButton = true,
  }) : super(key: key);
  final Widget child;
  final String? fallbackTitle;
  final String? fallbackMessage;
  final VoidCallback? onRetry;
  final bool showRetryButton;

  @override
  Widget build(BuildContext context) {
    // In production, show user-friendly error instead of red screen
    if (kReleaseMode) {
      return _buildProductionErrorWidget(context);
    }
    
    // In debug mode, show detailed error for developers
    return _buildProductionErrorWidget(context);
  }

  Widget _buildProductionErrorWidget(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'re sorry, but something unexpected happened. Please try again.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugErrorWidget(BuildContext context, FlutterErrorDetails details) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.red.shade50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bug_report,
            size: 48,
            color: Colors.red.shade600,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Debug Error',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Text(
              details.exception.toString(),
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Colors.red.shade700,
              ),
            ),
          ),
          
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Network error handler for API failures
class NetworkErrorHandler extends StatelessWidget {

  const NetworkErrorHandler({
    Key? key,
    this.onRetry,
    this.customMessage,
  }) : super(key: key);
  final VoidCallback? onRetry;
  final String? customMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GenZMicrointeractions.buildPulseAnimation(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off,
                size: 40,
                color: Colors.blue.shade600,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Connection Issue',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            customMessage ?? 'Check your internet connection and try again.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          if (onRetry != null)
            PerformanceOptimizer.buildSnappyButton(
              onPressed: onRetry!,
              backgroundColor: Colors.blue.shade600,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Retry',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Empty state handler for when content is loading or unavailable
class EmptyStateHandler extends StatelessWidget {

  const EmptyStateHandler({
    Key? key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionText,
  }) : super(key: key);
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GenZMicrointeractions.buildSuccessAnimation(
            isVisible: true,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 50,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (onAction != null && actionText != null) ...[
            const SizedBox(height: 32),
            PerformanceOptimizer.buildSnappyButton(
              onPressed: onAction!,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                actionText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading state with shimmer effect
class LoadingStateHandler extends StatelessWidget {

  const LoadingStateHandler({
    Key? key,
    this.message,
    this.showShimmer = true,
  }) : super(key: key);
  final String? message;
  final bool showShimmer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showShimmer)
            GenZMicrointeractions.buildShimmerLoader(
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(40),
            )
          else
            const CircularProgressIndicator(),
          
          const SizedBox(height: 24),
          
          if (message != null)
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
} 