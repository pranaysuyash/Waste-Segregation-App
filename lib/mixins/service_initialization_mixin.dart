import 'package:flutter/material.dart';
import '../utils/service_locator.dart';
import '../utils/error_handler.dart';
import '../utils/waste_app_logger.dart';
import '../models/user_profile.dart';
import '../models/gamification.dart';

/// Mixin to eliminate duplicate service initialization patterns across screens
mixin ServiceInitializationMixin<T extends StatefulWidget> on State<T> {
  ServiceBundle? _services;
  UserProfile? _userProfile;
  GamificationProfile? _gamificationProfile;
  bool _isInitialized = false;
  bool _isLoading = true;

  /// Get the service bundle (lazy initialization)
  ServiceBundle get services {
    _services ??= ServiceLocator.getServiceBundle(context);
    return _services!;
  }

  /// Get the current user profile
  UserProfile? get userProfile => _userProfile;

  /// Get the current gamification profile
  GamificationProfile? get gamificationProfile => _gamificationProfile;

  /// Check if services are initialized
  bool get isInitialized => _isInitialized;

  /// Check if data is loading
  bool get isLoading => _isLoading;

  /// Initialize common services and load user data
  @protected
  Future<void> initializeServices({
    bool loadUserProfile = true,
    bool loadGamificationProfile = true,
    String? screenName,
  }) async {
    if (_isInitialized) return;

    setState(() {
      _isLoading = true;
    });

    final result = await ErrorHandler.handleAsync(
      () async {
        // Load user profile if requested
        if (loadUserProfile) {
          _userProfile = await services.storage.getCurrentUserProfile();
        }

        // Load gamification profile if requested
        if (loadGamificationProfile) {
          _gamificationProfile = await services.gamification.getProfile();
        }

        _isInitialized = true;

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
      context: 'Initializing services for ${screenName ?? 'screen'}',
      service: 'service_initialization_mixin',
      file: 'service_initialization_mixin',
    );

    // If initialization failed, update state anyway to prevent infinite loading
    if (result == null && mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Refresh user data
  @protected
  Future<void> refreshUserData({
    bool refreshUserProfile = true,
    bool refreshGamificationProfile = true,
  }) async {
    final result = await ErrorHandler.handleAsync(
      () async {
        if (refreshUserProfile) {
          _userProfile = await services.storage.getCurrentUserProfile();
        }

        if (refreshGamificationProfile) {
          _gamificationProfile = await services.gamification.getProfile();
        }

        if (mounted) {
          setState(() {});
        }
      },
      context: 'Refreshing user data',
      service: 'service_initialization_mixin',
      file: 'service_initialization_mixin',
    );

    // Log if refresh failed
    if (result == null) {
      WasteAppLogger.warning('User data refresh failed',
          context: {'mounted': mounted});
    }
  }

  /// Common sign out logic
  @protected
  Future<void> performSignOut({
    String? redirectRoute,
  }) async {
    final success = await ErrorHandler.handleAsyncVoid(
      () async {
        await services.googleDrive.signOut();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(redirectRoute ?? '/auth');
        }
      },
      context: 'Sign out',
      service: 'service_initialization_mixin',
      file: 'service_initialization_mixin',
      showSnackBar: true,
      buildContext: context,
      userMessage: 'Failed to sign out. Please try again.',
    );

    if (success) {
      ErrorHandler.showSuccessMessage(context, 'Signed out successfully');
    }
  }

  /// Common method to save classification
  @protected
  Future<bool> saveClassification(dynamic classification,
      {bool force = false}) async {
    return ErrorHandler.handleAsyncVoid(
      () async {
        await services.storage.saveClassification(classification, force: force);
      },
      context: 'Saving classification',
      service: 'service_initialization_mixin',
      file: 'service_initialization_mixin',
      showSnackBar: true,
      buildContext: context,
      userMessage: 'Failed to save classification. Please try again.',
    );
  }

  /// Common method to award points
  @protected
  Future<bool> awardPoints(String action, {int? customPoints}) async {
    return ErrorHandler.handleAsyncVoid(
      () async {
        await services.gamification
            .addPoints(action, customPoints: customPoints);
        // Refresh gamification profile after awarding points
        _gamificationProfile = await services.gamification.getProfile();
        if (mounted) {
          setState(() {});
        }
      },
      context: 'Awarding points for $action',
      service: 'service_initialization_mixin',
      file: 'service_initialization_mixin',
    );
  }

  /// Common method to track analytics event
  @protected
  void trackAnalyticsEvent(String eventName,
      {Map<String, dynamic>? parameters}) {
    ErrorHandler.handleSync(
      () {
        // Use the user action helper to avoid needing to provide eventType everywhere.
        services.analytics
            .trackUserAction(eventName, parameters: parameters ?? {});
      },
      context: 'Tracking analytics event: $eventName',
      service: 'service_initialization_mixin',
      file: 'service_initialization_mixin',
    );
  }

  /// Common method to set ad context
  @protected
  void setAdContext({
    bool inClassificationFlow = false,
    bool inEducationalContent = false,
    bool inSettings = false,
  }) {
    ErrorHandler.handleSync(
      () {
        services.ad.setInClassificationFlow(inClassificationFlow);
        services.ad.setInEducationalContent(inEducationalContent);
        services.ad.setInSettings(inSettings);
      },
      context: 'Setting ad context',
      service: 'service_initialization_mixin',
      file: 'service_initialization_mixin',
    );
  }

  /// Common method to check Google sync status
  @protected
  Future<bool> isGoogleSyncEnabled() async {
    final result = await ErrorHandler.handleAsync(
      () async {
        final settings = await services.storage.getSettings();
        return settings['isGoogleSyncEnabled'] ?? false;
      },
      context: 'Checking Google sync status',
      service: 'service_initialization_mixin',
      file: 'service_initialization_mixin',
    );
    return result ?? false;
  }

  /// Common method to get user display name
  @protected
  String getUserDisplayName() {
    if (_userProfile != null) {
      return _userProfile!.displayName ?? _userProfile!.email ?? 'User';
    }
    return 'User';
  }

  /// Common method to get user points
  @protected
  int getUserPoints() {
    return _gamificationProfile?.points.total ?? 0;
  }

  /// Common loading widget
  @protected
  Widget buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// Common error widget
  @protected
  Widget buildErrorWidget(String message, {VoidCallback? onRetry}) {
    return Center(
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
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
