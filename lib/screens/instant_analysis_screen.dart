import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:waste_segregation_app/models/waste_classification.dart';
import '../services/ai_service.dart';
import '../utils/ai_error_messages.dart';
import '../widgets/analysis_progress_view.dart';
import '../screens/result_screen_wrapper.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Screen that performs instant analysis without showing review screen
/// Provides the most streamlined experience: capture → analyze → results
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
  bool _isAnalyzing = false;
  bool _isCancelled = false;
  AnalysisProgressStage _analysisStage = AnalysisProgressStage.checkingQuality;
  String? _analysisErrorMessage;

  @override
  void initState() {
    super.initState();
    // Start analysis immediately when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInstantAnalysis();
    });
  }

  Future<void> _startInstantAnalysis() async {
    if (_isCancelled || _isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _analysisErrorMessage = null;
      _analysisStage = AnalysisProgressStage.checkingQuality;
    });

    try {
      WasteAppLogger.info(
          '🚀 Auto-analyze enabled - starting analysis immediately');
      if (mounted) {
        setState(() {
          _analysisStage = AnalysisProgressStage.uploading;
        });
      }

      final aiService = Provider.of<AiService>(context, listen: false);
      WasteClassification? result;

      if (kIsWeb) {
        // Web platform
        final bytes = await widget.image.readAsBytes();
        if (bytes.isEmpty) {
          throw Exception('Failed to read image data - empty bytes');
        }
        if (mounted) {
          setState(() {
            _analysisStage = AnalysisProgressStage.analyzingImage;
          });
        }
        result = await aiService.analyzeWebImage(bytes, widget.image.name);
      } else {
        // Mobile platform
        final file = File(widget.image.path);
        if (!await file.exists()) {
          throw Exception('Image file does not exist: ${widget.image.path}');
        }
        if (mounted) {
          setState(() {
            _analysisStage = AnalysisProgressStage.analyzingImage;
          });
        }
        result = await aiService.analyzeImage(file);
      }

      if (!_isCancelled && mounted) {
        WasteAppLogger.info(
            '✅ Analysis complete - saving classification immediately');
        setState(() {
          _analysisStage = AnalysisProgressStage.applyingLocalRules;
        });
        await Future<void>.delayed(const Duration(milliseconds: 320));
        if (_isCancelled || !mounted) return;

        setState(() {
          _analysisStage = AnalysisProgressStage.success;
        });
        await Future<void>.delayed(const Duration(milliseconds: 280));
        if (_isCancelled || !mounted) return;

        WasteAppLogger.info(
            '✅ Classification saved - navigating to results screen');

        // Fire-and-forget replacement avoids hanging async completion until the
        // destination route is popped, which can stall widget tests and callers.
        unawaited(
          Navigator.pushReplacement<void, void>(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreenWrapper(
                classification: result!,
                autoAnalyze: true,
              ),
            ),
          ),
        );

        // Note: Removed the conflicting Navigator.pop(result) call that was causing
        // the double navigation issue. The result is now handled entirely by the
        // ResultScreen, and the parent screen will get the result through the
        // normal navigation flow.
      }
    } catch (e) {
      if (!_isCancelled && mounted) {
        WasteAppLogger.severe('Error during instant analysis: $e');
        setState(() {
          _analysisErrorMessage = AiErrorMessages.toUserMessage(e);
          _analysisStage = AnalysisProgressStage.failedRetryable;
          _isAnalyzing = false;
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
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _retryAnalysis() async {
    if (_isAnalyzing) return;
    setState(() {
      _isCancelled = false;
      _analysisErrorMessage = null;
      _analysisStage = AnalysisProgressStage.checkingQuality;
    });
    await _startInstantAnalysis();
  }

  void _cancelAnalysis() {
    // Cancel the AI service analysis
    final aiService = Provider.of<AiService>(context, listen: false);
    aiService.cancelAnalysis();

    setState(() {
      _isCancelled = true;
      _isAnalyzing = false;
      _analysisStage = AnalysisProgressStage.checkingQuality;
    });
    WasteAppLogger.info('Analysis cancelled by user');

    // Show cancellation feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analysis cancelled.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    // Navigate back to home screen.
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isAnalyzing ||
              _analysisStage == AnalysisProgressStage.failedRetryable
          ? AnalysisProgressView(
              stage: _analysisStage,
              imageName: widget.image.name,
              statusMessage: _analysisErrorMessage,
              localRuleChipText:
                  'Applying disposal rules and processing result.',
              onCancel: _analysisStage ==
                          AnalysisProgressStage.failedRetryable ||
                      _analysisStage == AnalysisProgressStage.checkingQuality ||
                      _analysisStage == AnalysisProgressStage.uploading ||
                      _analysisStage == AnalysisProgressStage.analyzingImage ||
                      _analysisStage == AnalysisProgressStage.applyingLocalRules
                  ? _cancelAnalysis
                  : null,
              onRetry: _analysisStage == AnalysisProgressStage.failedRetryable
                  ? _retryAnalysis
                  : null,
              showRetry:
                  _analysisStage == AnalysisProgressStage.failedRetryable,
              showCancel: _analysisStage != AnalysisProgressStage.success,
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
