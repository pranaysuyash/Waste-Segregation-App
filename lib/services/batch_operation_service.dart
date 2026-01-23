import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/waste_classification.dart';
import '../models/gamification.dart';
import '../utils/waste_app_logger.dart';

/// Result of a batch operation
class BatchResult {
  const BatchResult({
    required this.success,
    required this.operationsCount,
    this.error,
    this.failedOperations = const [],
  });

  final bool success;
  final int operationsCount;
  final String? error;
  final List<String> failedOperations;
}

/// Update operation for gamification data
class GamificationUpdate {
  const GamificationUpdate({
    required this.userId,
    required this.profileData,
    required this.operationType,
    this.metadata = const {},
  });

  final String userId;
  final Map<String, dynamic> profileData;
  final String operationType; // 'points', 'achievement', 'streak', 'full_profile'
  final Map<String, dynamic> metadata;
}

/// Service for batching Firestore operations to reduce costs and improve performance
class BatchOperationService {
  BatchOperationService._internal();
  
  static final BatchOperationService _instance = BatchOperationService._internal();
  static BatchOperationService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Batch configuration
  static const int _maxBatchSize = 500; // Firestore limit
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  
  // Pending operations queues
  final List<WasteClassification> _pendingClassifications = [];
  final List<GamificationUpdate> _pendingGamificationUpdates = [];
  
  // Batch execution locks
  bool _isExecutingClassificationBatch = false;
  bool _isExecutingGamificationBatch = false;
  
  // Timers for automatic batch execution
  Timer? _classificationBatchTimer;
  Timer? _gamificationBatchTimer;
  
  // Auto-batch configuration
  static const Duration _autoBatchDelay = Duration(seconds: 5);
  static const int _autoBatchThreshold = 10;

  /// Add a classification to the batch queue
  Future<void> queueClassification(WasteClassification classification) async {
    _pendingClassifications.add(classification);
    
    WasteAppLogger.debug('Classification queued for batch operation', {
      'service': 'batch_operation',
      'classification_id': classification.id,
      'queue_size': _pendingClassifications.length,
    });
    
    // Auto-execute if threshold reached
    if (_pendingClassifications.length >= _autoBatchThreshold) {
      await executeClassificationBatch();
    } else {
      _scheduleClassificationBatch();
    }
  }

  /// Add a gamification update to the batch queue
  Future<void> queueGamificationUpdate(GamificationUpdate update) async {
    _pendingGamificationUpdates.add(update);
    
    WasteAppLogger.debug('Gamification update queued for batch operation', {
      'service': 'batch_operation',
      'user_id': update.userId,
      'operation_type': update.operationType,
      'queue_size': _pendingGamificationUpdates.length,
    });
    
    // Auto-execute if threshold reached
    if (_pendingGamificationUpdates.length >= _autoBatchThreshold) {
      await executeGamificationBatch();
    } else {
      _scheduleGamificationBatch();
    }
  }

  /// Execute all pending classification operations in batches
  Future<BatchResult> executeClassificationBatch() async {
    if (_isExecutingClassificationBatch || _pendingClassifications.isEmpty) {
      return const BatchResult(success: true, operationsCount: 0);
    }

    _isExecutingClassificationBatch = true;
    _classificationBatchTimer?.cancel();
    
    try {
      final classificationsToProcess = List<WasteClassification>.from(_pendingClassifications);
      _pendingClassifications.clear();
      
      WasteAppLogger.info('Executing classification batch operation', {
        'service': 'batch_operation',
        'operation_count': classificationsToProcess.length,
      });

      var totalOperations = 0;
      final failedOperations = <String>[];
      
      // Process in chunks of max batch size
      for (int i = 0; i < classificationsToProcess.length; i += _maxBatchSize) {
        final chunk = classificationsToProcess.skip(i).take(_maxBatchSize).toList();
        
        final result = await _executeClassificationChunk(chunk);
        totalOperations += result.operationsCount;
        
        if (!result.success) {
          failedOperations.addAll(result.failedOperations);
        }
      }
      
      WasteAppLogger.performanceLog('batch_classification_complete', totalOperations, context: {
        'service': 'batch_operation',
        'total_operations': totalOperations,
        'failed_operations': failedOperations.length,
      });
      
      return BatchResult(
        success: failedOperations.isEmpty,
        operationsCount: totalOperations,
        failedOperations: failedOperations,
      );
      
    } catch (e) {
      WasteAppLogger.severe('Classification batch execution failed', e, null, {
        'service': 'batch_operation',
        'pending_count': _pendingClassifications.length,
      });
      
      return BatchResult(
        success: false,
        operationsCount: 0,
        error: e.toString(),
      );
    } finally {
      _isExecutingClassificationBatch = false;
    }
  }

  /// Execute all pending gamification operations in batches
  Future<BatchResult> executeGamificationBatch() async {
    if (_isExecutingGamificationBatch || _pendingGamificationUpdates.isEmpty) {
      return const BatchResult(success: true, operationsCount: 0);
    }

    _isExecutingGamificationBatch = true;
    _gamificationBatchTimer?.cancel();
    
    try {
      final updatesToProcess = List<GamificationUpdate>.from(_pendingGamificationUpdates);
      _pendingGamificationUpdates.clear();
      
      WasteAppLogger.info('Executing gamification batch operation', {
        'service': 'batch_operation',
        'operation_count': updatesToProcess.length,
      });

      var totalOperations = 0;
      final failedOperations = <String>[];
      
      // Group updates by user to optimize batch operations
      final userUpdates = <String, List<GamificationUpdate>>{};
      for (final update in updatesToProcess) {
        userUpdates.putIfAbsent(update.userId, () => []).add(update);
      }
      
      // Process each user's updates in batches
      for (final userEntry in userUpdates.entries) {
        final userId = userEntry.key;
        final updates = userEntry.value;
        
        // Process in chunks of max batch size
        for (int i = 0; i < updates.length; i += _maxBatchSize) {
          final chunk = updates.skip(i).take(_maxBatchSize).toList();
          
          final result = await _executeGamificationChunk(userId, chunk);
          totalOperations += result.operationsCount;
          
          if (!result.success) {
            failedOperations.addAll(result.failedOperations);
          }
        }
      }
      
      WasteAppLogger.performanceLog('batch_gamification_complete', totalOperations, context: {
        'service': 'batch_operation',
        'total_operations': totalOperations,
        'failed_operations': failedOperations.length,
        'unique_users': userUpdates.length,
      });
      
      return BatchResult(
        success: failedOperations.isEmpty,
        operationsCount: totalOperations,
        failedOperations: failedOperations,
      );
      
    } catch (e) {
      WasteAppLogger.severe('Gamification batch execution failed', e, null, {
        'service': 'batch_operation',
        'pending_count': _pendingGamificationUpdates.length,
      });
      
      return BatchResult(
        success: false,
        operationsCount: 0,
        error: e.toString(),
      );
    } finally {
      _isExecutingGamificationBatch = false;
    }
  }

  /// Execute a chunk of classification operations with retry logic
  Future<BatchResult> _executeClassificationChunk(List<WasteClassification> classifications) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final batch = _firestore.batch();
        final operationIds = <String>[];
        
        for (final classification in classifications) {
          final docRef = _firestore
              .collection('users')
              .doc(classification.userId ?? 'guest')
              .collection('classifications')
              .doc(classification.id);
          
          batch.set(docRef, classification.toJson(), SetOptions(merge: true));
          operationIds.add(classification.id);
        }
        
        await batch.commit();
        
        WasteAppLogger.debug('Classification batch chunk executed successfully', {
          'service': 'batch_operation',
          'chunk_size': classifications.length,
          'attempt': attempt,
        });
        
        return BatchResult(
          success: true,
          operationsCount: classifications.length,
        );
        
      } catch (e) {
        WasteAppLogger.warning('Classification batch chunk failed', e, null, {
          'service': 'batch_operation',
          'chunk_size': classifications.length,
          'attempt': attempt,
          'max_retries': _maxRetries,
        });
        
        if (attempt == _maxRetries) {
          return BatchResult(
            success: false,
            operationsCount: 0,
            error: e.toString(),
            failedOperations: classifications.map((c) => c.id).toList(),
          );
        }
        
        // Exponential backoff
        await Future.delayed(_retryDelay * attempt);
      }
    }
    
    return const BatchResult(success: false, operationsCount: 0);
  }

  /// Execute a chunk of gamification operations with retry logic
  Future<BatchResult> _executeGamificationChunk(String userId, List<GamificationUpdate> updates) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final batch = _firestore.batch();
        final operationIds = <String>[];
        
        // Merge all updates for the same user into a single document update
        final mergedData = <String, dynamic>{};
        final metadata = <String, dynamic>{};
        
        for (final update in updates) {
          mergedData.addAll(update.profileData);
          metadata.addAll(update.metadata);
          operationIds.add('${update.operationType}_${DateTime.now().millisecondsSinceEpoch}');
        }
        
        // Add batch metadata
        mergedData['lastBatchUpdate'] = FieldValue.serverTimestamp();
        mergedData['batchMetadata'] = metadata;
        
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('gamification')
            .doc('profile');
        
        batch.set(docRef, mergedData, SetOptions(merge: true));
        
        await batch.commit();
        
        WasteAppLogger.debug('Gamification batch chunk executed successfully', {
          'service': 'batch_operation',
          'user_id': userId,
          'chunk_size': updates.length,
          'attempt': attempt,
        });
        
        return BatchResult(
          success: true,
          operationsCount: updates.length,
        );
        
      } catch (e) {
        WasteAppLogger.warning('Gamification batch chunk failed', e, null, {
          'service': 'batch_operation',
          'user_id': userId,
          'chunk_size': updates.length,
          'attempt': attempt,
          'max_retries': _maxRetries,
        });
        
        if (attempt == _maxRetries) {
          return BatchResult(
            success: false,
            operationsCount: 0,
            error: e.toString(),
            failedOperations: updates.map((u) => '${u.userId}_${u.operationType}').toList(),
          );
        }
        
        // Exponential backoff
        await Future.delayed(_retryDelay * attempt);
      }
    }
    
    return const BatchResult(success: false, operationsCount: 0);
  }

  /// Schedule automatic batch execution for classifications
  void _scheduleClassificationBatch() {
    _classificationBatchTimer?.cancel();
    _classificationBatchTimer = Timer(_autoBatchDelay, () {
      executeClassificationBatch();
    });
  }

  /// Schedule automatic batch execution for gamification updates
  void _scheduleGamificationBatch() {
    _gamificationBatchTimer?.cancel();
    _gamificationBatchTimer = Timer(_autoBatchDelay, () {
      executeGamificationBatch();
    });
  }

  /// Force execution of all pending batches
  Future<void> flushAllBatches() async {
    await Future.wait([
      executeClassificationBatch(),
      executeGamificationBatch(),
    ]);
  }

  /// Get current queue sizes for monitoring
  Map<String, int> getQueueSizes() {
    return {
      'classifications': _pendingClassifications.length,
      'gamification_updates': _pendingGamificationUpdates.length,
    };
  }

  /// Clear all pending operations (use with caution)
  void clearAllQueues() {
    _pendingClassifications.clear();
    _pendingGamificationUpdates.clear();
    _classificationBatchTimer?.cancel();
    _gamificationBatchTimer?.cancel();
    
    WasteAppLogger.warning('All batch operation queues cleared', null, null, {
      'service': 'batch_operation',
    });
  }

  /// Dispose of resources
  void dispose() {
    _classificationBatchTimer?.cancel();
    _gamificationBatchTimer?.cancel();
    clearAllQueues();
  }
}