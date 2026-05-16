import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'result_screen.dart';

/// Thin delegation layer that maps the old feature-flag API to the
/// single canonical [ResultScreen].
///
/// Kept as a pass-through so that all navigation callers use a single
/// import.  Once the old feature-flag infrastructure is fully removed
/// this wrapper can be inlined.
class ResultScreenWrapper extends ConsumerWidget {
  const ResultScreenWrapper({
    super.key,
    required this.classification,
    this.showActions = true,
    this.autoAnalyze = false,
    this.heroTag,
  });

  final WasteClassification classification;
  final bool showActions;
  final bool autoAnalyze;
  final String? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResultScreen(
      classification: classification,
      showActions: showActions,
      autoAnalyze: autoAnalyze,
      heroTag: heroTag,
    );
  }
}
