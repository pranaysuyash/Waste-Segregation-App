import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/waste_classification.dart';
import '../../services/ai_service.dart';
import '../../services/analytics_service.dart';
import '../../services/haptic_settings_service.dart';

/// Enhanced re-analysis widget with better UI hooks and user experience
class EnhancedReanalysisWidget extends StatefulWidget {

  const EnhancedReanalysisWidget({
    super.key,
    required this.classification,
    this.userCorrection,
    this.userNotes,
    this.onReanalysisStarted,
    this.onReanalysisCompleted,
  });
  final WasteClassification classification;
  final String? userCorrection;
  final String? userNotes;
  final VoidCallback? onReanalysisStarted;
  final Function(WasteClassification)? onReanalysisCompleted;

  @override
  State<EnhancedReanalysisWidget> createState() => _EnhancedReanalysisWidgetState();
}

class _EnhancedReanalysisWidgetState extends State<EnhancedReanalysisWidget>
    with SingleTickerProviderStateMixin {
  bool _isReanalyzing = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildReanalysisCard(),
          ),
        );
      },
    );
  }

  Widget _buildReanalysisCard() {
    final confidence = widget.classification.confidence ?? 1.0;
    final isLowConfidence = confidence < 0.7;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLowConfidence 
            ? [Colors.orange.shade50, Colors.orange.shade100]
            : [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLowConfidence ? Colors.orange.shade300 : Colors.blue.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLowConfidence ? Colors.orange : Colors.blue).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isLowConfidence),
          const SizedBox(height: 12),
          _buildDescription(isLowConfidence),
          const SizedBox(height: 16),
          _buildActionButtons(isLowConfidence),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isLowConfidence) {
    final confidence = widget.classification.confidence ?? 1.0;
    final confidencePercent = (confidence * 100).round();
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isLowConfidence ? Colors.orange.shade200 : Colors.blue.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isLowConfidence ? Icons.warning_amber : Icons.refresh,
            color: isLowConfidence ? Colors.orange.shade700 : Colors.blue.shade700,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLowConfidence ? 'Low Confidence Result' : 'Re-analyze Available',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isLowConfidence ? Colors.orange.shade800 : Colors.blue.shade800,
                ),
              ),
              if (isLowConfidence)
                Text(
                  'Confidence: $confidencePercent%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade600,
                  ),
                ),
            ],
          ),
        ),
        if (widget.userCorrection != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 12, color: Colors.green.shade700),
                const SizedBox(width: 4),
                Text(
                  'With Correction',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDescription(bool isLowConfidence) {
    String description;
    if (widget.userCorrection != null) {
      description = 'Re-analyze this image with your correction: "${widget.userCorrection}" for improved accuracy.';
    } else if (isLowConfidence) {
      description = 'This classification has lower confidence than usual. Try re-analyzing with a clearer image or different angle.';
    } else {
      description = 'Not satisfied with the result? Re-analyze the image to get a fresh classification.';
    }

    return Text(
      description,
      style: TextStyle(
        fontSize: 14,
        color: isLowConfidence ? Colors.orange.shade700 : Colors.blue.shade700,
        height: 1.4,
      ),
    );
  }

  Widget _buildActionButtons(bool isLowConfidence) {
    if (_isReanalyzing) {
      return _buildReanalyzingState();
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _triggerReanalysis,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(
              widget.userCorrection != null 
                ? 'Re-analyze with Correction'
                : 'Re-analyze Image',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLowConfidence ? Colors.orange.shade600 : Colors.blue.shade600,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: _showReanalysisOptions,
          icon: const Icon(Icons.settings, size: 16),
          label: const Text('Options'),
          style: OutlinedButton.styleFrom(
            foregroundColor: isLowConfidence ? Colors.orange.shade700 : Colors.blue.shade700,
            side: BorderSide(
              color: isLowConfidence ? Colors.orange.shade300 : Colors.blue.shade300,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReanalyzingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Re-analyzing image...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
                if (widget.userCorrection != null)
                  Text(
                    'Using your correction: ${widget.userCorrection}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _cancelReanalysis,
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  void _triggerReanalysis() async {
    final analyticsService = context.read<AnalyticsService>();
    final hapticService = context.read<HapticSettingsService>();
    
    // Track re-analysis event
    analyticsService.trackUserAction('enhanced_reanalysis_triggered', parameters: {
      'original_category': widget.classification.category,
      'original_confidence': widget.classification.confidence,
      'has_user_correction': widget.userCorrection != null,
      'is_low_confidence': (widget.classification.confidence ?? 1.0) < 0.7,
      'user_correction': widget.userCorrection,
    });

    // Haptic feedback
    if (hapticService.enabled) {
      HapticFeedback.lightImpact();
    }

    setState(() {
      _isReanalyzing = true;
    });

    widget.onReanalysisStarted?.call();

    try {
      final aiService = context.read<AiService>();
      
      // For now, use the existing re-analyze functionality
      // Navigate back to capture screen for re-analysis
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/capture');
      }
    } catch (e) {
      if (mounted) {
        // Track failed re-analysis
        analyticsService.trackUserAction('reanalysis_failed', parameters: {
          'error': e.toString(),
          'original_category': widget.classification.category,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Re-analysis failed: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _triggerReanalysis,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReanalyzing = false;
        });
      }
    }
  }

  void _cancelReanalysis() {
    final aiService = context.read<AiService>();
    aiService.cancelAnalysis();
    
    setState(() {
      _isReanalyzing = false;
    });

    context.read<AnalyticsService>().trackUserAction('reanalysis_cancelled');
  }

  void _showReanalysisOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              'Re-analysis Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildOption(
              icon: Icons.camera_alt,
              title: 'Retake Photo',
              subtitle: 'Take a new photo for analysis',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/capture');
              },
            ),
            
            _buildOption(
              icon: Icons.refresh,
              title: 'Try Different Analysis',
              subtitle: 'Re-analyze current image with different approach',
              onTap: () {
                Navigator.pop(context);
                _triggerReanalysis();
              },
            ),
            
            _buildOption(
              icon: Icons.support_agent,
              title: 'Request Manual Review',
              subtitle: 'Get human expert review for complex items',
              onTap: () {
                Navigator.pop(context);
                _requestManualReview();
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.blue.shade600),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _requestManualReview() {
    // Implementation for manual review request
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Manual review requested. We\'ll improve our AI based on your feedback.'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
} 