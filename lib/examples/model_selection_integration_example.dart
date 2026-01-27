import 'package:flutter/material.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/services/model_selection_service.dart';
import 'package:waste_segregation_app/services/on_device_vision_service.dart';
import 'package:waste_segregation_app/services/batching_service.dart';
import 'package:waste_segregation_app/models/vision_model_config.dart';

/// Example integration of ModelSelectionService with existing AI service
///
/// This example shows how to integrate the new alternative vision models
/// into the existing app architecture.
class ModelSelectionIntegrationExample {
  /// Create a model selection service that integrates with existing AI service
  ///
  /// This can be used as a drop-in replacement for AIService in most cases.
  static ModelSelectionService createModelSelectionService(
    AiService existingAiService, {
    ModelSelectionStrategy strategy = ModelSelectionStrategy.hybrid,
  }) {
    // Create on-device service
    final onDeviceService = OnDeviceVisionService(
      config: VisionModelConfig.hybrid(),
    );

    // Create batching service (optional)
    final batchingService = BatchingService(
      config: VisionModelConfig.batchCloud(),
    );

    // Create model selection service
    return ModelSelectionService(
      aiService: existingAiService,
      onDeviceService: onDeviceService,
      batchingService: batchingService,
      strategy: strategy,
    );
  }

  /// Initialize the model selection service
  ///
  /// Call this during app startup, after initializing your existing AI service.
  static Future<void> initialize(ModelSelectionService service) async {
    await service.initialize();
  }

  /// Example widget showing model selection in settings
  static Widget buildModelStrategySelector({
    required ModelSelectionStrategy currentStrategy,
    required ValueChanged<ModelSelectionStrategy> onStrategyChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Model Strategy',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose how the app analyzes images',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        _buildStrategyTile(
          strategy: ModelSelectionStrategy.hybrid,
          title: 'Hybrid (Recommended)',
          subtitle: 'Try on-device first, fallback to cloud. Best balance.',
          icon: Icons.sync,
          currentStrategy: currentStrategy,
          onChanged: onStrategyChanged,
        ),
        _buildStrategyTile(
          strategy: ModelSelectionStrategy.onDeviceFirst,
          title: 'On-Device Only',
          subtitle: 'Zero cost, works offline, privacy-preserving.',
          icon: Icons.smartphone,
          currentStrategy: currentStrategy,
          onChanged: onStrategyChanged,
        ),
        _buildStrategyTile(
          strategy: ModelSelectionStrategy.cloudOnly,
          title: 'Cloud Only',
          subtitle: 'Highest accuracy, requires internet.',
          icon: Icons.cloud,
          currentStrategy: currentStrategy,
          onChanged: onStrategyChanged,
        ),
        _buildStrategyTile(
          strategy: ModelSelectionStrategy.batchMode,
          title: 'Batch Mode',
          subtitle: '50% cost reduction, slight delay.',
          icon: Icons.batch_prediction,
          currentStrategy: currentStrategy,
          onChanged: onStrategyChanged,
        ),
        _buildStrategyTile(
          strategy: ModelSelectionStrategy.costOptimized,
          title: 'Cost-Optimized',
          subtitle: 'Minimize costs, prefer free options.',
          icon: Icons.savings,
          currentStrategy: currentStrategy,
          onChanged: onStrategyChanged,
        ),
        _buildStrategyTile(
          strategy: ModelSelectionStrategy.performanceOptimized,
          title: 'Performance-Optimized',
          subtitle: 'Fastest inference, on-device when possible.',
          icon: Icons.speed,
          currentStrategy: currentStrategy,
          onChanged: onStrategyChanged,
        ),
        _buildStrategyTile(
          strategy: ModelSelectionStrategy.accuracyOptimized,
          title: 'Accuracy-Optimized',
          subtitle: 'Best models regardless of cost.',
          icon: Icons.verified,
          currentStrategy: currentStrategy,
          onChanged: onStrategyChanged,
        ),
      ],
    );
  }

  static Widget _buildStrategyTile({
    required ModelSelectionStrategy strategy,
    required String title,
    required String subtitle,
    required IconData icon,
    required ModelSelectionStrategy currentStrategy,
    required ValueChanged<ModelSelectionStrategy> onChanged,
  }) {
    final isSelected = strategy == currentStrategy;

    return Card(
      color: isSelected ? Colors.green.shade50 : null,
      child: RadioListTile<ModelSelectionStrategy>(
        value: strategy,
        groupValue: currentStrategy,
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
        title: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(title),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ],
        ),
        subtitle: Text(subtitle),
      ),
    );
  }

  /// Example widget showing usage statistics
  static Widget buildStatisticsCard(ModelSelectionService service) {
    final stats = service.getStatistics();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Usage Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Analyses', '${stats['total_analyses']}'),
            _buildStatRow('On-Device', stats['on_device_percentage'] as String),
            _buildStatRow('Cloud', stats['cloud_percentage'] as String),
            _buildStatRow('Batch', stats['batch_percentage'] as String),
            const Divider(),
            _buildStatRow('Total Cost', stats['total_cost'] as String),
            _buildStatRow('Avg Cost/Analysis',
                stats['average_cost_per_analysis'] as String),
          ],
        ),
      ),
    );
  }

  static Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Example settings page with model selection
class ModelSelectionSettingsPage extends StatefulWidget {
  const ModelSelectionSettingsPage({
    required this.modelService,
    super.key,
  });

  final ModelSelectionService modelService;

  @override
  State<ModelSelectionSettingsPage> createState() =>
      _ModelSelectionSettingsPageState();
}

class _ModelSelectionSettingsPageState
    extends State<ModelSelectionSettingsPage> {
  late ModelSelectionStrategy _currentStrategy;

  @override
  void initState() {
    super.initState();
    _currentStrategy = widget.modelService.strategy;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Selection'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ModelSelectionIntegrationExample.buildStatisticsCard(
              widget.modelService,
            ),
            const SizedBox(height: 24),
            ModelSelectionIntegrationExample.buildModelStrategySelector(
              currentStrategy: _currentStrategy,
              onStrategyChanged: (strategy) {
                setState(() {
                  _currentStrategy = strategy;
                });
                // TODO: Save preference and recreate service with new strategy
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Strategy changed to ${strategy.name}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
