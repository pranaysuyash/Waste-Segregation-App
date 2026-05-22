import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:waste_segregation_app/models/classification_state.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../services/ai_service.dart';
import '../services/instant_analysis_flow_coordinator.dart';
import '../utils/ai_error_messages.dart';
import '../widgets/analysis_progress_view.dart';
import '../screens/result_screen_wrapper.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Screen that performs instant analysis without showing review screen.
class InstantAnalysisScreen extends StatefulWidget {
  const InstantAnalysisScreen({
    super.key,
    required this.image,
  });
  final XFile image;

  @override
  State<InstantAnalysisScreen> createState() => _InstantAnalysisScreenState();
}

class _InstantAnalysisScreenState extends State<InstantAnalysisScreen> {
  static const InstantAnalysisFlowCoordinator _flowCoordinator =
      InstantAnalysisFlowCoordinator();
  ClassificationState _state = ClassificationState.idle;
  String? _analysisErrorMessage;

  bool get _isAnalyzing =>
      _state != ClassificationState.idle &&
      _state != ClassificationState.failedRetryable &&
      _state != ClassificationState.failedPermanent &&
      _state != ClassificationState.cancelled;

  bool get _isCancelled => _state == ClassificationState.cancelled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInstantAnalysis();
    });
  }

  Future<void> _startInstantAnalysis() async {
    if (_isCancelled || _isAnalyzing) return;

    setState(() {
      _state = ClassificationState.cloudClassifying;
      _analysisErrorMessage = null;
    });

    try {
      final aiService = Provider.of<AiService>(context, listen: false);
      late final WasteClassification result;

      if (kIsWeb) {
        final bytes = await widget.image.readAsBytes();
        if (bytes.isEmpty) {
          throw Exception('Failed to read image data - empty bytes');
        }
        result = await aiService.analyzeWebImage(bytes, widget.image.name);
      } else {
        final file = File(widget.image.path);
        if (!await file.exists()) {
          throw Exception('Image file does not exist: ${widget.image.path}');
        }
        result = await aiService.analyzeImage(file);
      }

      if (!_isCancelled && mounted) {
        WasteAppLogger.info('Analysis complete - saving classification');
        await _flowCoordinator.completeSuccessFlow(
          classification: result,
          isMounted: () => mounted,
          isCancelled: () => _isCancelled,
          setStage: (state) {
            if (!mounted) return;
            setState(() {
              _state = state;
            });
          },
          navigateToResult: (classification) async {
            WasteAppLogger.info('Navigating to results screen');
            unawaited(
              Navigator.pushReplacement<void, void>(
                context,
                MaterialPageRoute(
                  builder: (context) => ResultScreenWrapper(
                    classification: classification,
                    autoAnalyze: true,
                  ),
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (!_isCancelled && mounted) {
        WasteAppLogger.severe('Error during instant analysis: $e');
        setState(() {
          _analysisErrorMessage = AiErrorMessages.toUserMessage(e);
          _state = ClassificationState.failedRetryable;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_analysisErrorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _state = ClassificationState.idle;
        });
      }
    }
  }

  Future<void> _retryAnalysis() async {
    if (_isAnalyzing) return;
    setState(() {
      _analysisErrorMessage = null;
      _state = ClassificationState.cloudClassifying;
    });
    await _startInstantAnalysis();
  }

  void _cancelAnalysis() {
    final aiService = Provider.of<AiService>(context, listen: false);
    aiService.cancelAnalysis();

    setState(() {
      _state = ClassificationState.cancelled;
    });
    WasteAppLogger.info('Analysis cancelled by user');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analysis cancelled.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isAnalyzing ||
              _state == ClassificationState.failedRetryable
          ? AnalysisProgressView(
              state: _state,
              imageName: widget.image.name,
              statusMessage: _analysisErrorMessage,
              localRuleChipText:
                  'Applying disposal rules and processing result.',
              onCancel: _state == ClassificationState.failedRetryable ||
                      _state == ClassificationState.cloudClassifying
                  ? _cancelAnalysis
                  : null,
              onRetry: _state == ClassificationState.failedRetryable
                  ? _retryAnalysis
                  : null,
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Preparing instant analysis...'),
                ],
              ),
            ),
    );
  }
}
