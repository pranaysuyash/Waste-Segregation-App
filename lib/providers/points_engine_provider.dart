import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/points_engine.dart';
import '../services/storage_service.dart';
import '../services/cloud_storage_service.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Provider for the centralized Points Engine
class PointsEngineProvider extends ChangeNotifier {
  PointsEngineProvider(this._storageService, this._cloudStorageService) {
    _pointsEngine = PointsEngine.getInstance(_storageService, _cloudStorageService);
    _pointsEngine.addListener(_onPointsEngineChanged);
    _initialize();
  }

  final StorageService _storageService;
  final CloudStorageService _cloudStorageService;
  late final PointsEngine _pointsEngine;

  /// Get the Points Engine instance
  PointsEngine get pointsEngine => _pointsEngine;

  /// Initialize the engine
  Future<void> _initialize() async {
    try {
      await _pointsEngine.initialize();
      notifyListeners();
    } catch (e) {
      WasteAppLogger.severe('🔥 PointsEngineProvider: Failed to initialize: $e');
    }
  }

  /// Handle Points Engine changes
  void _onPointsEngineChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _pointsEngine.removeListener(_onPointsEngineChanged);
    _pointsEngine.dispose();
    super.dispose();
  }
}

/// Extension to easily access Points Engine from context
extension PointsEngineContext on BuildContext {
  PointsEngine get pointsEngine => Provider.of<PointsEngineProvider>(this, listen: false).pointsEngine;
  
  PointsEngine watchPointsEngine() => Provider.of<PointsEngineProvider>(this).pointsEngine;
} 