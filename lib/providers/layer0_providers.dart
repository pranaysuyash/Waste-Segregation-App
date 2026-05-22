import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/barcode_lookup_service.dart';
import '../services/color_histogram_classifier.dart';
import '../services/layer0_router.dart';
import 'cost_management_providers.dart';

final colorHistogramClassifierProvider = Provider<ColorHistogramClassifier>((ref) {
  return ColorHistogramClassifier();
});

final barcodeLookupServiceProvider = Provider<BarcodeLookupService>((ref) {
  return BarcodeLookupService();
});

final layer0RouterProvider = Provider<Layer0Router>((ref) {
  return Layer0Router(
    colorClassifier: ref.read(colorHistogramClassifierProvider),
    barcodeService: ref.read(barcodeLookupServiceProvider),
  );
});

final layer0EnabledProvider = FutureProvider<bool>((ref) async {
  final remoteConfig = ref.read(remoteConfigServiceProvider);
  await remoteConfig.initialize();
  return remoteConfig.getBool('layer0_enabled', defaultValue: true);
});

final layer0ColorHistogramEnabledProvider = FutureProvider<bool>((ref) async {
  final remoteConfig = ref.read(remoteConfigServiceProvider);
  await remoteConfig.initialize();
  return remoteConfig.getBool('layer0_color_histogram_enabled', defaultValue: true);
});

final layer0BarcodeLookupEnabledProvider = FutureProvider<bool>((ref) async {
  final remoteConfig = ref.read(remoteConfigServiceProvider);
  await remoteConfig.initialize();
  return remoteConfig.getBool('layer0_barcode_lookup_enabled', defaultValue: true);
});
