import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/model_selection_service.dart';
import '../models/vision_model_config.dart';

/// Performance monitoring dashboard for vision models
/// 
/// Displays:
/// - Model usage distribution (pie chart)
/// - Cost analysis over time
/// - Latency comparison
/// - Success rates
/// - Storage usage
class PerformanceMonitoringDashboard extends StatefulWidget {
  const PerformanceMonitoringDashboard({
    required this.modelService,
    super.key,
  });

  final ModelSelectionService modelService;

  @override
  State<PerformanceMonitoringDashboard> createState() =>
      _PerformanceMonitoringDashboardState();
}

class _PerformanceMonitoringDashboardState
    extends State<PerformanceMonitoringDashboard> {
  @override
  Widget build(BuildContext context) {
    final stats = widget.modelService.getStatistics();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Performance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(stats),
            const SizedBox(height: 24),
            _buildUsageDistributionChart(stats),
            const SizedBox(height: 24),
            _buildCostAnalysis(stats),
            const SizedBox(height: 24),
            _buildRecommendations(stats),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> stats) {
    final totalAnalyses = stats['total_analyses'] as int;
    final totalCost = stats['total_cost'] as String;
    final avgCost = stats['average_cost_per_analysis'] as String;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Analyses',
            totalAnalyses.toString(),
            Icons.analytics,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total Cost',
            totalCost,
            Icons.attach_money,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Avg Cost',
            avgCost,
            Icons.trending_down,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageDistributionChart(Map<String, dynamic> stats) {
    final onDeviceCount = stats['on_device_analyses'] as int;
    final cloudCount = stats['cloud_analyses'] as int;
    final batchCount = stats['batch_analyses'] as int;
    final total = onDeviceCount + cloudCount + batchCount;

    if (total == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Usage Distribution',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'No analyses yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Usage Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    if (onDeviceCount > 0)
                      PieChartSectionData(
                        value: onDeviceCount.toDouble(),
                        title: '${(onDeviceCount / total * 100).toStringAsFixed(0)}%',
                        color: Colors.green,
                        radius: 100,
                      ),
                    if (cloudCount > 0)
                      PieChartSectionData(
                        value: cloudCount.toDouble(),
                        title: '${(cloudCount / total * 100).toStringAsFixed(0)}%',
                        color: Colors.blue,
                        radius: 100,
                      ),
                    if (batchCount > 0)
                      PieChartSectionData(
                        value: batchCount.toDouble(),
                        title: '${(batchCount / total * 100).toStringAsFixed(0)}%',
                        color: Colors.orange,
                        radius: 100,
                      ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      children: [
        _buildLegendItem('On-Device', Colors.green, 'Zero cost, fast'),
        _buildLegendItem('Cloud', Colors.blue, 'High accuracy'),
        _buildLegendItem('Batch', Colors.orange, '50% discount'),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            description,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCostAnalysis(Map<String, dynamic> stats) {
    final totalCostStr = stats['total_cost'] as String;
    final totalCost = double.tryParse(
          totalCostStr.replaceAll('\$', '').replaceAll(',', ''),
        ) ??
        0.0;
    final totalAnalyses = stats['total_analyses'] as int;
    
    // Estimate potential savings with different strategies
    final currentAvgCost = totalAnalyses > 0 ? totalCost / totalAnalyses : 0.0;
    final onDevicePercent =
        double.tryParse(stats['on_device_percentage'].toString().replaceAll('%', '')) ?? 0.0;
    
    // Calculate what cost would be with different strategies
    final cloudOnlyCost = totalAnalyses * 0.01; // $0.01 per analysis
    final hybridCost = totalAnalyses * 0.003; // 70% on-device
    final onDeviceCost = 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cost Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCostRow('Current', totalCost, Colors.blue),
            _buildCostRow('Cloud Only', cloudOnlyCost, Colors.red),
            _buildCostRow('Hybrid', hybridCost, Colors.orange),
            _buildCostRow('On-Device', onDeviceCost, Colors.green),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Potential Monthly Savings:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${((cloudOnlyCost - totalCost) * 30).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, double cost, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            '\$${cost.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(Map<String, dynamic> stats) {
    final totalAnalyses = stats['total_analyses'] as int;
    final onDevicePercent =
        double.tryParse(stats['on_device_percentage'].toString().replaceAll('%', '')) ?? 0.0;
    final recommendedStrategy = widget.modelService.getRecommendedStrategy();
    
    final recommendations = <String>[];
    
    if (totalAnalyses < 10) {
      recommendations.add('Not enough data yet. Continue using the app to get recommendations.');
    } else {
      if (onDevicePercent < 50) {
        recommendations.add('💡 Consider increasing on-device usage to reduce costs.');
        recommendations.add('Try lowering the confidence threshold to 0.6.');
      }
      
      if (onDevicePercent > 90) {
        recommendations.add('⚠️ Very high on-device usage. Consider if accuracy is sufficient.');
      }
      
      if (recommendedStrategy != widget.modelService.strategy) {
        recommendations.add(
          '🎯 Recommended strategy: ${recommendedStrategy.name}',
        );
      }
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('✅ Your current configuration looks optimal!');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommendations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...recommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(rec)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
