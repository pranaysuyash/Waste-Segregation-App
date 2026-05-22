import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/vision_model_config.dart';
import 'package:waste_segregation_app/services/on_device_vision_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testDir;

  setUp(() {
    testDir = Directory.systemTemp.createTempSync('on_device_vision_service_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'getApplicationDocumentsDirectory':
          return testDir.path;
        case 'getTemporaryDirectory':
          return '${testDir.path}/tmp';
        default:
          return null;
      }
    });
  });

  tearDown(() {
    testDir.deleteSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
  });

  group('OnDeviceVisionService', () {
    test('analyzeImage returns placeholder on-device classification', () async {
      final service = OnDeviceVisionService(
        config: VisionModelConfig.onDevice(),
      );
      final imageFile = File('${testDir.path}/test-image.jpg')
        ..writeAsBytesSync(Uint8List.fromList([1, 2, 3, 4, 5]));

      final result = await service.analyzeImage(
        imageFile,
        region: 'IN',
        classificationId: 'classification-1',
      );

      expect(result.itemName, 'On-Device Analysis Required');
      expect(result.category, 'On-Device Mode');
      expect(result.region, 'IN');
      expect(result.id, 'classification-1');
      expect(result.modelSource, 'on-device-yoloV8');
      expect(result.processingTimeMs, greaterThanOrEqualTo(0));
    });

    test('analyzeWebImage returns placeholder on-device classification', () async {
      final service = OnDeviceVisionService(
        config: VisionModelConfig(
          modelType: VisionModelType.mobileNetV3,
          analysisMode: AnalysisMode.onDevice,
        ),
      );

      final result = await service.analyzeWebImage(
        Uint8List.fromList([9, 8, 7, 6]),
        region: 'US',
        classificationId: 'web-classification-1',
      );

      expect(result.itemName, 'On-Device Analysis Required');
      expect(result.category, 'On-Device Mode');
      expect(result.region, 'US');
      expect(result.id, 'web-classification-1');
      expect(result.modelSource, 'on-device-mobileNetV3');
      expect(result.processingTimeMs, greaterThanOrEqualTo(0));
    });
  });
}
