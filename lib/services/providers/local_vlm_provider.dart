import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'ai_provider_response.dart';
import 'classification_provider.dart';

/// Placeholder for future on-device VLM (e.g. MobileVLM, moondream2, SmolVLM).
///
/// Throws [UnimplementedError] until a real model is bundled.
/// Presence of this class ensures the [ClassificationProvider] contract is
/// ready for local inference without modifying the router.
///
/// When a real model is bundled:
/// 1. Replace [analyze] with a TFLite / ONNX runtime call.
/// 2. Update [modelName] to the bundled model identifier.
/// 3. Update [estimatedCostPerCall] to `0.0` (confirmed free).
/// 4. Remove the [UnimplementedError].
///
/// See: docs/review/AI_GATEWAY_ROUTER_IMPLEMENTATION_2026-05-21.md — Phase 3.
class LocalVlmProvider implements ClassificationProvider {
  const LocalVlmProvider();

  @override
  String get providerName => 'local_vlm';

  @override
  String get modelName => 'not-yet-bundled';

  /// Free — runs on device. Set to `0.0` as a forward declaration.
  @override
  double? get estimatedCostPerCall => 0.0;

  @override
  Future<AiProviderResponse> analyze({
    required Uint8List imageBytes,
    required String mimeType,
    String prompt = '',
    String? clientHash,
    String? region,
    String? lang,
    String? requestId,
    CancelToken? cancelToken,
  }) {
    throw UnimplementedError(
      'LocalVlmProvider: on-device VLM not yet available. '
      'Escalate to cloud provider. '
      'See docs/review/AI_GATEWAY_ROUTER_IMPLEMENTATION_2026-05-21.md',
    );
  }
}
