import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/waste_classification.dart';
import '../utils/waste_app_logger.dart';
import '../providers/app_providers.dart';

/// Evidence Dashboard — surfaces the 15 routing/quality fields collected
/// per classification that are invisible in all other UI surfaces.
class ModelRoutingScreen extends ConsumerStatefulWidget {
  const ModelRoutingScreen({super.key});

  @override
  ConsumerState<ModelRoutingScreen> createState() => _ModelRoutingScreenState();
}

class _ModelRoutingScreenState extends ConsumerState<ModelRoutingScreen> {
  bool _isLoading = true;

  int _totalClassifications = 0;

  // Layer breakdown
  final Map<String, _LayerStats> _layerStats = {};
  int _unknownLayerCount = 0;
  int _layerSuccessCount = 0;
  int _layerFailureCount = 0;

  // Strategy breakdown
  final Map<String, int> _strategyCounts = {};

  // Quality metrics
  double _averageQualityScore = 0;
  int _needsReviewCount = 0;
  int _duplicateCount = 0;
  final Map<String, int> _qualityReasonsCount = {};

  // Cost metrics
  double _totalCostUsd = 0;
  int _classificationsWithCost = 0;
  int _classificationsWithLatency = 0;
  double _totalLatencyMs = 0;

  // Route decision breakdown
  final Map<String, int> _routeDecisionCounts = {};

  // Source breakdown
  final Map<String, int> _sourceCounts = {};

  // All classifications for detail list
  List<WasteClassification> _classifications = [];

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);

    try {
      final storageService = ref.read(storageServiceProvider);
      final classifications = await storageService.getAllClassifications();
      _classifications = classifications;
      _totalClassifications = classifications.length;

      _layerStats.clear();
      _strategyCounts.clear();
      _qualityReasonsCount.clear();
      _routeDecisionCounts.clear();
      _sourceCounts.clear();
      _unknownLayerCount = 0;
      _layerSuccessCount = 0;
      _layerFailureCount = 0;
      _averageQualityScore = 0;
      _needsReviewCount = 0;
      _duplicateCount = 0;
      _totalCostUsd = 0;
      _classificationsWithCost = 0;
      _classificationsWithLatency = 0;
      _totalLatencyMs = 0;

      double qualityScoreSum = 0;
      var qualityScoreCount = 0;

      for (final c in classifications) {
        // Layer breakdown
        final layer = c.classificationLayer ?? 'not_set';
        _layerStats.putIfAbsent(layer, () => _LayerStats());
        _layerStats[layer]!.count++;
        if (c.confidence != null) {
          _layerStats[layer]!.confidenceSum += c.confidence!;
          _layerStats[layer]!.confidenceCount++;
        }

        // Strategy breakdown
        if (c.modelSelectionStrategy != null &&
            c.modelSelectionStrategy!.isNotEmpty) {
          _strategyCounts[c.modelSelectionStrategy!] =
              (_strategyCounts[c.modelSelectionStrategy!] ?? 0) + 1;
        }

        // Per-layer success/failure
        if (c.qualityScore != null) {
          qualityScoreSum += c.qualityScore!;
          qualityScoreCount++;
          if (c.qualityScore! >= 0.5 && c.needsReview != true) {
            _layerSuccessCount++;
            _layerStats[layer]!.successCount++;
          } else {
            _layerFailureCount++;
            _layerStats[layer]!.failureCount++;
          }
        }

        // Needs review
        if (c.needsReview == true) {
          _needsReviewCount++;
        }

        // Duplicate
        if (c.duplicateScore != null && c.duplicateScore! > 0) {
          _duplicateCount++;
        }

        // Quality reasons
        if (c.qualityReasons != null) {
          for (final reason in c.qualityReasons!) {
            _qualityReasonsCount[reason] =
                (_qualityReasonsCount[reason] ?? 0) + 1;
          }
        }

        // Cost
        if (c.routeCostUsd != null) {
          _totalCostUsd += c.routeCostUsd!;
          _classificationsWithCost++;
        }

        // Latency
        if (c.routeLatencyMs != null) {
          _totalLatencyMs += c.routeLatencyMs!.toDouble();
          _classificationsWithLatency++;
        }

        // Route decision
        if (c.routeDecision != null && c.routeDecision!.isNotEmpty) {
          _routeDecisionCounts[c.routeDecision!] =
              (_routeDecisionCounts[c.routeDecision!] ?? 0) + 1;
        }

        // Analysis source
        if (c.analysisSource != null && c.analysisSource!.isNotEmpty) {
          _sourceCounts[c.analysisSource!] =
              (_sourceCounts[c.analysisSource!] ?? 0) + 1;
        }
      }

      _averageQualityScore =
          qualityScoreCount > 0 ? qualityScoreSum / qualityScoreCount : 0;

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      WasteAppLogger.severe('Error loading model routing metrics: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Routing Dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMetrics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  if (_totalClassifications == 0)
                    _buildEmptyState()
                  else ...[
                    _buildSummaryCard(context),
                    const SizedBox(height: 16),
                    _buildLayerBreakdownCard(context),
                    const SizedBox(height: 16),
                    _buildQualityCard(context),
                    const SizedBox(height: 16),
                    _buildRoutingCard(context),
                    const SizedBox(height: 16),
                    _buildCostCard(context),
                    const SizedBox(height: 24),
                    _buildClassificationList(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Routing Evidence',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Every classification records 15 routing and quality fields that are '
          'hidden from all other screens. This dashboard surfaces them.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.router, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No classifications yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Classify some waste items to see routing evidence here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return _buildSectionCard(
      title: 'Overview',
      icon: Icons.dashboard,
      color: Colors.indigo,
      children: [
        _buildStatRow('Total Classifications', '$_totalClassifications'),
        _buildStatRow(
          'Layer Coverage',
          '${_layerStats.length} layer${_layerStats.length == 1 ? '' : 's'}',
          valueColor: Colors.indigo,
        ),
        _buildStatRow(
          'Strategy Variants',
          '${_strategyCounts.length} strategy${_strategyCounts.length == 1 ? '' : 'ies'}',
          valueColor: Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildLayerBreakdownCard(BuildContext context) {
    final layerColors = <String, Color>{
      'layer0_deterministic': Colors.green,
      'layer1_on_device': Colors.blue,
      'layer2_cloud_cheap': Colors.orange,
      'layer3_cloud_strong': Colors.red,
      'layer0_hint_pending_cloud': Colors.purple,
    };

    final sortedLayers = _layerStats.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));

    return _buildSectionCard(
      title: 'Layer Distribution',
      icon: Icons.layers,
      color: Colors.teal,
      children: [
        ...sortedLayers.map((entry) {
          final color = layerColors[entry.key] ?? Colors.grey;
          final avg = entry.value.confidenceCount > 0
              ? entry.value.confidenceSum / entry.value.confidenceCount
              : null;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
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
                Expanded(
                  child: Text(
                    _layerLabel(entry.key),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  '${entry.value.count}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (entry.value.successCount > 0 ||
                    entry.value.failureCount > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${entry.value.successCount}✓${entry.value.failureCount > 0 ? '/${entry.value.failureCount}✗' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: entry.value.failureCount > 0
                          ? Colors.orange[700]
                          : Colors.green[700],
                    ),
                  ),
                ],
                if (avg != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${(avg * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          );
        }),
        if (_layerSuccessCount > 0 || _layerFailureCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  'Overall: $_layerSuccessCount✓ / $_layerFailureCount✗',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _layerFailureCount > 0 ? Colors.orange[700] : Colors.green[700],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${(100 * _layerSuccessCount / (_layerSuccessCount + _layerFailureCount)).toStringAsFixed(0)}% success)',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        if (_unknownLayerCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Unknown / not set',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  '$_unknownLayerCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        if (_strategyCounts.isNotEmpty) ...[
          const Divider(height: 24),
          Text(
            'Strategies used',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          ..._strategyCounts.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(entry.key, style: const TextStyle(fontSize: 12)),
                    ),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildQualityCard(BuildContext context) {
    final topReasons = _qualityReasonsCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = topReasons.take(3).toList();

    return _buildSectionCard(
      title: 'Quality Gate',
      icon: Icons.verified_outlined,
      color: Colors.blue,
      children: [
        _buildStatRow(
          'Avg Quality Score',
          _averageQualityScore > 0
              ? _averageQualityScore.toStringAsFixed(3)
              : 'N/A',
          valueColor: _averageQualityScore >= 0.7 ? Colors.green : Colors.orange,
        ),
        _buildStatRow('Needs Review', '$_needsReviewCount',
            valueColor:
                _needsReviewCount > 0 ? Colors.orange : Colors.green),
        _buildStatRow('Duplicates', '$_duplicateCount',
            valueColor:
                _duplicateCount > 0 ? Colors.grey : Colors.green),
        if (top3.isNotEmpty) ...[
          const Divider(height: 16),
          Text(
            'Top quality issues',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          ...top3.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(entry.key, style: const TextStyle(fontSize: 12)),
                    ),
                    Text(
                      '${entry.value}×',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildRoutingCard(BuildContext context) {
    final sortedDecisions = _routeDecisionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sortedSources = _sourceCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildSectionCard(
      title: 'Routing & Sources',
      icon: Icons.alt_route,
      color: Colors.deepOrange,
      children: [
        if (sortedDecisions.isNotEmpty) ...[
          Text(
            'Route decisions',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          ...sortedDecisions.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(entry.key, style: const TextStyle(fontSize: 12)),
                    ),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )),
        ],
        if (sortedSources.isNotEmpty) ...[
          const Divider(height: 16),
          Text(
            'Analysis sources',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          ...sortedSources.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _sourceLabel(entry.key),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildCostCard(BuildContext context) {
    final avgCost = _classificationsWithCost > 0
        ? _totalCostUsd / _classificationsWithCost
        : 0.0;
    final avgLatency = _classificationsWithLatency > 0
        ? _totalLatencyMs / _classificationsWithLatency
        : 0.0;

    return _buildSectionCard(
      title: 'Cost & Performance',
      icon: Icons.savings_outlined,
      color: Colors.green,
      children: [
        _buildStatRow(
          'Total Cost',
          '\$${_totalCostUsd.toStringAsFixed(4)}',
          valueColor: Colors.green,
        ),
        _buildStatRow(
          'Avg Cost / Call',
          '\$${avgCost.toStringAsFixed(4)}',
          valueColor: Colors.green,
        ),
        _buildStatRow(
          'Avg Latency',
          '${avgLatency.toStringAsFixed(0)} ms',
        ),
      ],
    );
  }

  Widget _buildClassificationList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Per-Classification Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ..._classifications.reversed.take(50).map((c) => _ClassificationTile(c)),
        if (_classifications.length > 50)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                'Showing 50 of $_totalClassifications classifications',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _layerLabel(String layer) {
    switch (layer) {
      case 'layer0_deterministic':
        return 'L0 — Deterministic';
      case 'layer1_on_device':
        return 'L1 — On-Device ML';
      case 'layer2_cloud_cheap':
        return 'L2 — Cloud Cheap';
      case 'layer3_cloud_strong':
        return 'L3 — Cloud Strong';
      case 'layer0_hint_pending_cloud':
        return 'L0 — Offline Hint';
      case 'not_set':
        return 'Not Set';
      default:
        return layer;
    }
  }

  String _sourceLabel(String source) {
    switch (source) {
      case 'cloud_primary':
        return 'Cloud Primary';
      case 'local_experimental':
        return 'Local Experimental';
      case 'local_failed_fallback_cloud':
        return 'Local → Cloud Fallback';
      default:
        return source;
    }
  }
}

class _LayerStats {
  int count = 0;
  int successCount = 0;
  int failureCount = 0;
  double confidenceSum = 0;
  int confidenceCount = 0;
}

class _ClassificationTile extends StatelessWidget {
  const _ClassificationTile(this.classification);

  final WasteClassification classification;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                classification.itemName,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: classification.needsReview == true
                    ? Colors.orange[100]
                    : Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                classification.needsReview == true ? 'Review' : 'OK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: classification.needsReview == true
                      ? Colors.orange[800]
                      : Colors.green[800],
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${classification.category} · '
          '${classification.confidence != null ? (classification.confidence! * 100).toStringAsFixed(0) : '?'}%',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          _detailRow('Route Decision', classification.routeDecision ?? '—'),
          _detailRow('Route Reason', classification.routeReason ?? '—'),
          _detailRow('Model Route', classification.modelRoute ?? '—'),
          _detailRow('Strategy',
              classification.modelSelectionStrategy ?? '—'),
          _detailRow('Layer', classification.classificationLayer ?? '—'),
          _detailRow('Analysis Source',
              classification.analysisSource ?? '—'),
          if (classification.analysisFallbackReason != null)
            _detailRow('Fallback Reason',
                classification.analysisFallbackReason!),
          _detailRow('Quality Score',
              classification.qualityScore?.toStringAsFixed(3) ?? '—'),
          _detailRow('Quality Reasons',
              classification.qualityReasons?.join(', ') ?? '—'),
          _detailRow('Raw Confidence',
              classification.rawConfidence?.toStringAsFixed(3) ?? '—'),
          _detailRow('Calibrated Confidence',
              classification.calibratedConfidence?.toStringAsFixed(3) ?? '—'),
          _detailRow('Duplicate Score',
              classification.duplicateScore?.toStringAsFixed(2) ?? '—'),
          _detailRow('Route Latency',
              classification.routeLatencyMs != null
                  ? '${classification.routeLatencyMs} ms'
                  : '—'),
          _detailRow('Route Cost',
              classification.routeCostUsd != null
                  ? '\$${classification.routeCostUsd!.toStringAsFixed(4)}'
                  : '—'),
          _detailRow('Review Reason',
              classification.reviewReason ?? '—'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
