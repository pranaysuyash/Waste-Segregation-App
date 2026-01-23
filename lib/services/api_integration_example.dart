import 'dart:typed_data';
import '../utils/waste_app_logger.dart';
import 'api_management_service.dart';
import '../models/waste_classification.dart';

/// Example integration showing how to use the new API management system
/// 
/// This demonstrates:
/// - Service initialization
/// - AI analysis with automatic fallback
/// - Cost monitoring
/// - Performance tracking
/// - Error handling
class ApiIntegrationExample {
  static final ApiManagementService _apiManager = ApiManagementService();

  /// Initialize the API management system
  static Future<void> initialize() async {
    try {
      await _apiManager.initialize(
        enableMonitoring: true,
        enableOptimization: true,
        monitoringInterval: const Duration(minutes: 5),
        optimizationInterval: const Duration(minutes: 15),
      );

      WasteAppLogger.info('API integration initialized successfully', null, null, {
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      WasteAppLogger.severe('Failed to initialize API integration', e, null, {
        'error_type': e.runtimeType.toString(),
      });
      rethrow;
    }
  }

  /// Example: Analyze waste image with enhanced API management
  static Future<WasteClassification> analyzeWasteImage({
    required Uint8List imageBytes,
    required String imageName,
    String? region,
    String? language,
    String? preferredModel,
  }) async {
    final startTime = DateTime.now();
    
    try {
      WasteAppLogger.info('Starting waste analysis with enhanced API', null, null, {
        'image_name': imageName,
        'image_size_bytes': imageBytes.length,
        'preferred_model': preferredModel,
        'region': region,
        'language': language,
      });

      // Use the enhanced AI API service through the management layer
      final result = await _apiManager.aiApiService.analyzeWasteImage(
        imageBytes: imageBytes,
        imageName: imageName,
        region: region,
        language: language,
        preferredModel: preferredModel,
        enableSegmentation: imageBytes.length > 1024 * 1024, // Enable for large images
      );

      final processingTime = DateTime.now().difference(startTime);
      
      // Update the result with processing time
      final enhancedResult = WasteClassification(
        category: result.category,
        subcategory: result.subcategory,
        confidence: result.confidence,
        explanation: result.explanation,
        disposalInstructions: result.disposalInstructions,
        environmentalImpact: result.environmentalImpact,
        imageName: result.imageName,
        timestamp: result.timestamp,
        source: result.source,
        processingTimeMs: processingTime.inMilliseconds,
        modelVersion: result.modelVersion,
        segments: result.segments,
        itemCount: result.itemCount,
      );

      WasteAppLogger.info('Waste analysis completed successfully', null, null, {
        'image_name': imageName,
        'category': result.category,
        'confidence': result.confidence,
        'processing_time_ms': processingTime.inMilliseconds,
        'model_used': result.source,
      });

      return enhancedResult;
    } catch (e) {
      final processingTime = DateTime.now().difference(startTime);
      
      WasteAppLogger.severe('Waste analysis failed', e, null, {
        'image_name': imageName,
        'processing_time_ms': processingTime.inMilliseconds,
        'error_type': e.runtimeType.toString(),
      });
      
      rethrow;
    }
  }

  /// Example: Get comprehensive API statistics
  static Map<String, dynamic> getApiStatistics() {
    try {
      final stats = _apiManager.getStatistics();
      
      WasteAppLogger.info('API statistics retrieved', null, null, {
        'total_services': stats['client_statistics']?.length ?? 0,
        'health_alerts': stats['health_alerts']?.length ?? 0,
        'monitoring_enabled': stats['monitoring_enabled'],
      });
      
      return stats;
    } catch (e) {
      WasteAppLogger.warning('Failed to get API statistics', e, null, {
        'error_type': e.runtimeType.toString(),
      });
      
      return {
        'error': 'Failed to retrieve statistics',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Example: Get health status
  static Map<String, dynamic> getHealthStatus() {
    try {
      final health = _apiManager.getHealthStatus();
      
      WasteAppLogger.info('Health status retrieved', null, null, {
        'overall_status': health['overall_status'],
        'alert_count': health['alert_count'],
      });
      
      return health;
    } catch (e) {
      WasteAppLogger.warning('Failed to get health status', e, null, {
        'error_type': e.runtimeType.toString(),
      });
      
      return {
        'overall_status': 'error',
        'error': 'Failed to retrieve health status',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Example: Get cost summary
  static Map<String, dynamic> getCostSummary() {
    try {
      final costs = _apiManager.getCostSummary();
      
      WasteAppLogger.info('Cost summary retrieved', null, null, {
        'total_cost': costs['total_cost'],
        'total_requests': costs['total_requests'],
        'average_cost_per_request': costs['average_cost_per_request'],
      });
      
      return costs;
    } catch (e) {
      WasteAppLogger.warning('Failed to get cost summary', e, null, {
        'error_type': e.runtimeType.toString(),
      });
      
      return {
        'error': 'Failed to retrieve cost summary',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Example: Update API configuration
  static void updateConfiguration({
    bool? enableMonitoring,
    bool? enableOptimization,
    Duration? monitoringInterval,
    Duration? optimizationInterval,
  }) {
    try {
      _apiManager.updateConfiguration(
        enableMonitoring: enableMonitoring,
        enableOptimization: enableOptimization,
        monitoringInterval: monitoringInterval,
        optimizationInterval: optimizationInterval,
      );

      WasteAppLogger.info('API configuration updated', null, null, {
        'monitoring_enabled': enableMonitoring,
        'optimization_enabled': enableOptimization,
        'monitoring_interval_minutes': monitoringInterval?.inMinutes,
        'optimization_interval_minutes': optimizationInterval?.inMinutes,
      });
    } catch (e) {
      WasteAppLogger.warning('Failed to update API configuration', e, null, {
        'error_type': e.runtimeType.toString(),
      });
    }
  }

  /// Example: Reset all statistics
  static void resetStatistics() {
    try {
      _apiManager.resetStatistics();
      
      WasteAppLogger.info('API statistics reset successfully', null, null, {
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      WasteAppLogger.warning('Failed to reset API statistics', e, null, {
        'error_type': e.runtimeType.toString(),
      });
    }
  }

  /// Example: Batch analyze multiple images
  static Future<List<WasteClassification>> batchAnalyzeImages({
    required List<Uint8List> imageBytesList,
    required List<String> imageNames,
    String? region,
    String? language,
    int? maxConcurrent,
  }) async {
    if (imageBytesList.length != imageNames.length) {
      throw ArgumentError('Image bytes list and names list must have the same length');
    }

    final results = <WasteClassification>[];
    final concurrent = maxConcurrent ?? 3; // Limit concurrent requests
    
    WasteAppLogger.info('Starting batch image analysis', null, null, {
      'total_images': imageBytesList.length,
      'max_concurrent': concurrent,
      'region': region,
      'language': language,
    });

    // Process images in batches to avoid overwhelming the API
    for (int i = 0; i < imageBytesList.length; i += concurrent) {
      final batchEnd = (i + concurrent).clamp(0, imageBytesList.length);
      final batch = <Future<WasteClassification>>[];
      
      for (int j = i; j < batchEnd; j++) {
        batch.add(analyzeWasteImage(
          imageBytes: imageBytesList[j],
          imageName: imageNames[j],
          region: region,
          language: language,
        ));
      }
      
      try {
        final batchResults = await Future.wait(batch);
        results.addAll(batchResults);
        
        WasteAppLogger.info('Batch completed', null, null, {
          'batch_start': i,
          'batch_end': batchEnd,
          'successful_analyses': batchResults.length,
        });
      } catch (e) {
        WasteAppLogger.warning('Batch analysis partially failed', e, null, {
          'batch_start': i,
          'batch_end': batchEnd,
        });
        
        // Continue with individual processing for failed batch
        for (int j = i; j < batchEnd; j++) {
          try {
            final result = await analyzeWasteImage(
              imageBytes: imageBytesList[j],
              imageName: imageNames[j],
              region: region,
              language: language,
            );
            results.add(result);
          } catch (individualError) {
            WasteAppLogger.warning('Individual image analysis failed', individualError, null, {
              'image_name': imageNames[j],
              'image_index': j,
            });
          }
        }
      }
    }

    WasteAppLogger.info('Batch analysis completed', null, null, {
      'total_images': imageBytesList.length,
      'successful_analyses': results.length,
      'failed_analyses': imageBytesList.length - results.length,
    });

    return results;
  }

  /// Dispose resources
  static void dispose() {
    try {
      _apiManager.dispose();
      
      WasteAppLogger.info('API integration disposed successfully', null, null, {
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      WasteAppLogger.warning('Failed to dispose API integration', e, null, {
        'error_type': e.runtimeType.toString(),
      });
    }
  }
}