import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/memory_management_service.dart';
import '../utils/waste_app_logger.dart';

/// Mixin for services that need proper disposal and memory management
mixin DisposableServiceMixin on ChangeNotifier implements DisposableResource {
  bool _isDisposed = false;
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];
  final Set<String> _activeOperations = {};
  
  /// Whether this service has been disposed
  bool get isDisposed => _isDisposed;
  
  /// Service identifier for memory tracking
  @override
  String get resourceId => '${runtimeType}_${hashCode}';
  
  /// Service type for memory tracking
  @override
  String get resourceType => runtimeType.toString();

  /// Initialize the service with memory management
  @protected
  void initializeService() {
    if (_isDisposed) {
      throw StateError('Cannot initialize disposed service: $resourceType');
    }
    
    // Register with memory management service
    MemoryManagementService.instance.registerDisposableResource(this);
    
    WasteAppLogger.debug('Service initialized with memory management', {
      'service': resourceType,
      'resource_id': resourceId,
    });
  }

  /// Add a stream subscription for automatic disposal
  @protected
  void addSubscription(StreamSubscription subscription) {
    if (_isDisposed) {
      subscription.cancel();
      return;
    }
    
    _subscriptions.add(subscription);
  }

  /// Add a timer for automatic disposal
  @protected
  void addTimer(Timer timer) {
    if (_isDisposed) {
      timer.cancel();
      return;
    }
    
    _timers.add(timer);
  }

  /// Track an active operation
  @protected
  void trackOperation(String operationId) {
    if (_isDisposed) return;
    
    _activeOperations.add(operationId);
    WasteAppLogger.debug('Operation tracked', {
      'service': resourceType,
      'operation_id': operationId,
      'active_operations': _activeOperations.length,
    });
  }

  /// Complete an active operation
  @protected
  void completeOperation(String operationId) {
    _activeOperations.remove(operationId);
    WasteAppLogger.debug('Operation completed', {
      'service': resourceType,
      'operation_id': operationId,
      'remaining_operations': _activeOperations.length,
    });
  }

  /// Execute an operation with automatic tracking
  @protected
  Future<T> executeTrackedOperation<T>(
    String operationId,
    Future<T> Function() operation,
  ) async {
    if (_isDisposed) {
      throw StateError('Cannot execute operation on disposed service: $resourceType');
    }
    
    trackOperation(operationId);
    
    try {
      final result = await operation();
      return result;
    } finally {
      completeOperation(operationId);
    }
  }

  /// Check if service is in a valid state for operations
  @protected
  void ensureNotDisposed([String? operation]) {
    if (_isDisposed) {
      final message = operation != null 
        ? 'Cannot perform $operation on disposed service: $resourceType'
        : 'Service is disposed: $resourceType';
      throw StateError(message);
    }
  }

  /// Dispose of all resources
  @override
  @mustCallSuper
  void dispose() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    
    try {
      // Cancel all subscriptions
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
      _subscriptions.clear();
      
      // Cancel all timers
      for (final timer in _timers) {
        timer.cancel();
      }
      _timers.clear();
      
      // Log any remaining active operations
      if (_activeOperations.isNotEmpty) {
        WasteAppLogger.warning('Service disposed with active operations', null, null, {
          'service': resourceType,
          'active_operations': _activeOperations.toList(),
          'operation_count': _activeOperations.length,
        });
      }
      _activeOperations.clear();
      
      // Unregister from memory management
      MemoryManagementService.instance.unregisterDisposableResource(resourceId);
      
      WasteAppLogger.debug('Service disposed', {
        'service': resourceType,
        'resource_id': resourceId,
      });
      
    } catch (e) {
      WasteAppLogger.severe('Error during service disposal', e, null, {
        'service': resourceType,
        'resource_id': resourceId,
      });
    } finally {
      // Always call super.dispose() to notify listeners
      super.dispose();
    }
  }

  /// Get service health information
  @protected
  Map<String, dynamic> getServiceHealth() {
    return {
      'isDisposed': _isDisposed,
      'activeSubscriptions': _subscriptions.length,
      'activeTimers': _timers.length,
      'activeOperations': _activeOperations.length,
      'hasListeners': hasListeners,
      'resourceId': resourceId,
      'resourceType': resourceType,
    };
  }
}

/// Mixin for providers that need proper disposal
mixin DisposableProviderMixin {
  bool _isDisposed = false;
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];
  
  /// Whether this provider has been disposed
  bool get isDisposed => _isDisposed;

  /// Add a stream subscription for automatic disposal
  @protected
  void addSubscription(StreamSubscription subscription) {
    if (_isDisposed) {
      subscription.cancel();
      return;
    }
    
    _subscriptions.add(subscription);
  }

  /// Add a timer for automatic disposal
  @protected
  void addTimer(Timer timer) {
    if (_isDisposed) {
      timer.cancel();
      return;
    }
    
    _timers.add(timer);
  }

  /// Check if provider is in a valid state
  @protected
  void ensureNotDisposed([String? operation]) {
    if (_isDisposed) {
      final message = operation != null 
        ? 'Cannot perform $operation on disposed provider: $runtimeType'
        : 'Provider is disposed: $runtimeType';
      throw StateError(message);
    }
  }

  /// Dispose of all resources
  @protected
  @mustCallSuper
  void disposeProvider() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    
    try {
      // Cancel all subscriptions
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
      _subscriptions.clear();
      
      // Cancel all timers
      for (final timer in _timers) {
        timer.cancel();
      }
      _timers.clear();
      
      WasteAppLogger.debug('Provider disposed', {
        'provider': runtimeType.toString(),
      });
      
    } catch (e) {
      WasteAppLogger.severe('Error during provider disposal', e, null, {
        'provider': runtimeType.toString(),
      });
    }
  }
}

/// Extension for automatic resource cleanup in async operations
extension ResourceCleanupExtension<T> on Future<T> {
  /// Automatically cleanup resources when future completes
  Future<T> withResourceCleanup(List<DisposableResource> resources) {
    return then((result) {
      _cleanupResources(resources);
      return result;
    }).catchError((error) {
      _cleanupResources(resources);
      throw error;
    });
  }
  
  void _cleanupResources(List<DisposableResource> resources) {
    for (final resource in resources) {
      try {
        resource.dispose();
      } catch (e) {
        WasteAppLogger.warning('Error cleaning up resource', e, null, {
          'resource_type': resource.resourceType,
          'resource_id': resource.resourceId,
        });
      }
    }
  }
}

/// Utility class for managing temporary resources
class TemporaryResourceManager {
  final List<DisposableResource> _resources = [];
  bool _isDisposed = false;
  
  /// Add a resource for automatic cleanup
  void addResource(DisposableResource resource) {
    if (_isDisposed) {
      resource.dispose();
      return;
    }
    
    _resources.add(resource);
  }
  
  /// Remove a resource from management (without disposing)
  void removeResource(DisposableResource resource) {
    _resources.remove(resource);
  }
  
  /// Dispose all managed resources
  void dispose() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    
    for (final resource in _resources) {
      try {
        resource.dispose();
      } catch (e) {
        WasteAppLogger.warning('Error disposing temporary resource', e, null, {
          'resource_type': resource.resourceType,
          'resource_id': resource.resourceId,
        });
      }
    }
    
    _resources.clear();
  }
}

/// Wrapper for disposable resources with automatic cleanup
class DisposableWrapper<T> implements DisposableResource {
  DisposableWrapper(this.resource, this.disposeCallback, {
    String? resourceId,
    String? resourceType,
  }) : _resourceId = resourceId ?? 'wrapper_${resource.hashCode}',
       _resourceType = resourceType ?? T.toString();

  final T resource;
  final void Function(T) disposeCallback;
  final String _resourceId;
  final String _resourceType;
  bool _isDisposed = false;

  @override
  String get resourceId => _resourceId;

  @override
  String get resourceType => _resourceType;

  /// Get the wrapped resource
  T get value {
    if (_isDisposed) {
      throw StateError('Cannot access disposed resource: $_resourceType');
    }
    return resource;
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    
    try {
      disposeCallback(resource);
    } catch (e) {
      WasteAppLogger.warning('Error in dispose callback', e, null, {
        'resource_type': _resourceType,
        'resource_id': _resourceId,
      });
    }
  }
}