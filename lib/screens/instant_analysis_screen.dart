import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../models/waste_classification.dart';
import '../services/ai_service.dart';
import '../widgets/enhanced_analysis_loader.dart';
import '../screens/result_screen.dart';

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
    });

    try {
      debugPrint('🚀 Auto-analyze enabled - starting analysis immediately');
      
      final aiService = Provider.of<AiService>(context, listen: false);
      WasteClassification? result;

      if (kIsWeb) {
        // Web platform
        final bytes = await widget.image.readAsBytes();
        if (bytes.isEmpty) {
          throw Exception('Failed to read image data - empty bytes');
        }
        result = await aiService.analyzeWebImage(bytes, widget.image.name);
      } else {
        // Mobile platform
        final file = File(widget.image.path);
        if (!await file.exists()) {
          throw Exception('Image file does not exist: ${widget.image.path}');
        }
        result = await aiService.analyzeImage(file);
      }

      if (!_isCancelled && mounted) {
        debugPrint('Navigation to results screen with classification');
        
        // Navigate to results screen and wait for it to complete
        await Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              classification: result!,
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
        debugPrint('Error during instant analysis: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  void _cancelAnalysis() {
    // Cancel the AI service analysis
    final aiService = Provider.of<AiService>(context, listen: false);
    aiService.cancelAnalysis();
    
    setState(() {
      _isCancelled = true;
      _isAnalyzing = false;
    });
    debugPrint('Analysis cancelled by user');
    
    // Show cancellation feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analysis cancelled.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    // Navigate back to home screen
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isAnalyzing
          ? EnhancedAnalysisLoader(
              imageName: widget.image.name,
              onCancel: _cancelAnalysis,
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