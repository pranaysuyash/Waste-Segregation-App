import 'dart:io';
import 'dart:typed_data';

import '../models/waste_classification.dart';
import 'ai_service.dart';
import 'result_pipeline.dart';

/// Single application boundary for scan classification and completion.
///
/// [AiService] owns provider routing and result post-processing. [ResultPipeline]
/// owns persistence and post-classification side effects. This class composes
/// those canonical services so foreground and queued scans cannot silently
/// choose different workflows.
class ScanOrchestrator {
  const ScanOrchestrator({
    required AiService aiService,
    required ResultPipeline resultPipeline,
  })  : _aiService = aiService,
        _resultPipeline = resultPipeline;

  final AiService _aiService;
  final ResultPipeline _resultPipeline;

  bool get isBackendRoutingEnabled => _aiService.isBackendRoutingEnabled;

  Future<WasteClassification> analyzeFile(
    File imageFile, {
    String? region,
    String? instructionsLang,
  }) {
    return _aiService.analyzeImage(
      imageFile,
      region: region,
      instructionsLang: instructionsLang,
    );
  }

  Future<WasteClassification> analyzeBytes(
    Uint8List imageBytes,
    String imageName, {
    String? region,
    String? instructionsLang,
  }) {
    return _aiService.analyzeWebImage(
      imageBytes,
      imageName,
      region: region,
      instructionsLang: instructionsLang,
    );
  }

  Future<List<WasteClassification>> analyzeRegions(
    Uint8List imageBytes,
    String imageName,
    List<Map<String, dynamic>> regions, {
    String? region,
    String? instructionsLang,
  }) {
    return _aiService.analyzeImageRegions(
      imageBytes,
      imageName,
      regions,
      region: region,
      instructionsLang: instructionsLang,
    );
  }

  Future<void> complete(
    WasteClassification classification, {
    bool force = false,
    bool autoAnalyze = false,
    bool manageLifecycle = true,
  }) {
    return _resultPipeline.processClassification(
      classification,
      force: force,
      autoAnalyze: autoAnalyze,
      manageLifecycle: manageLifecycle,
    );
  }

  Future<void> saveOnly(
    WasteClassification classification, {
    bool force = false,
    bool manageLifecycle = true,
  }) {
    return _resultPipeline.saveClassificationOnly(
      classification,
      force: force,
      manageLifecycle: manageLifecycle,
    );
  }

  void cancel() => _aiService.cancelAnalysis();
}
