import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offline_queue_service.dart';
import '../utils/waste_app_logger.dart';
import '../providers/app_providers.dart';

/// Track 3: Impact Dashboard
/// Shows quality gate metrics, offline queue stats, and cost savings
class ImpactDashboardScreen extends ConsumerStatefulWidget {
  const ImpactDashboardScreen({super.key});

  @override
  ConsumerState<ImpactDashboardScreen> createState() => _ImpactDashboardScreenState();
}

class _ImpactDashboardScreenState extends ConsumerState<ImpactDashboardScreen> {
  bool _isLoading = true;

  // Quality Gate Metrics
  int _totalClassifications = 0;
  int _highConfidenceClassifications = 0;
  int _lowConfidenceClassifications = 0;
  double _averageConfidence = 0;

  // Accuracy Metrics (correction vs confirmation tracking)
  int _totalConfirmations = 0;
  int _totalCorrections = 0;
  double _accuracyRate = 0; // confirmations / (confirmations + corrections)

  // Offline Queue Metrics
  int _totalQueuedImages = 0;
  int _processedQueuedImages = 0;
  int _pendingQueuedImages = 0;

  // Dead-Letter Queue
  int _deadLetterCount = 0;

  // Cost Savings
  double _apiCallsSaved = 0;
  double _estimatedCostSavings = 0;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storageService = ref.read(storageServiceProvider);
      final queueService = OfflineQueueService();

      // Load all classifications to calculate quality metrics
      final classifications = await storageService.getAllClassifications();
      _totalClassifications = classifications.length;

      // Load feedback data to calculate accuracy (confirmation vs correction ratio)
      // A feedback is a correction if the user suggested a different category/item name
      // than the AI originally provided. Otherwise it's a confirmation.
      final feedbacks = await storageService.getAllClassificationFeedback();
      _totalConfirmations = feedbacks
          .where((f) =>
              f.userSuggestedCategory == f.originalAICategory &&
              (f.userSuggestedItemName == null ||
                  f.userSuggestedItemName == f.originalAIItemName))
          .length;
      _totalCorrections = feedbacks
          .where((f) =>
              f.userSuggestedCategory != f.originalAICategory ||
              (f.userSuggestedItemName != null &&
                  f.userSuggestedItemName != f.originalAIItemName))
          .length;
      final totalFeedback = _totalConfirmations + _totalCorrections;
      _accuracyRate = totalFeedback > 0
          ? _totalConfirmations / totalFeedback
          : 0;

      // Calculate quality stats from confidence scores
      double totalConfidence = 0;
      for (final classification in classifications) {
        final confidence = classification.confidence ?? 0.5;
        totalConfidence += confidence;

        if (confidence >= 0.7) {
          _highConfidenceClassifications++;
        } else {
          _lowConfidenceClassifications++;
        }
      }

      _averageConfidence = _totalClassifications > 0
          ? totalConfidence / _totalClassifications
          : 0;

      // Get offline queue stats
      final queueStats = queueService.getQueueStats();
      _totalQueuedImages = queueStats['totalQueued'] ?? 0;
      _processedQueuedImages = queueStats['processed'] ?? 0;
      _pendingQueuedImages = queueStats['pending'] ?? 0;
      _deadLetterCount = queueStats['deadLetter'] ?? 0;

      // Calculate cost savings (efficient offline processing)
      // Assuming $0.002 per API call saved by offline queue
      _apiCallsSaved = _processedQueuedImages.toDouble();
      _estimatedCostSavings = _apiCallsSaved * 0.002;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      WasteAppLogger.severe('Error loading impact metrics: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showDeadLetterDialog() async {
    final items = OfflineQueueService().getDeadLetterItems();
    if (items.isEmpty || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => _DeadLetterDialog(
        items: items,
        onRetry: (id) async {
          await OfflineQueueService().retryDeadLetter(id);
          if (mounted) _loadMetrics();
        },
        onClearAll: () async {
          await OfflineQueueService().clearDeadLetterQueue();
          if (mounted) _loadMetrics();
        },
      ),
    );
    if (mounted) _loadMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impact Dashboard'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMetrics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Your Environmental Impact',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track how quality checks and offline processing improve your experience',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Quality Gate Section
                    _buildSectionCard(
                      context,
                      title: '📸 Classification Quality',
                      icon: Icons.verified_outlined,
                      color: Colors.blue,
                      children: [
                        _buildStatRow('Total Classifications',
                            _totalClassifications.toString()),
                        _buildStatRow('High Confidence',
                            _highConfidenceClassifications.toString(),
                            valueColor: Colors.green),
                        _buildStatRow('Low Confidence',
                            _lowConfidenceClassifications.toString(),
                            valueColor: Colors.orange),
                        const Divider(height: 24),
                        _buildStatRow('Average Confidence',
                            '${(_averageConfidence * 100).toStringAsFixed(1)}%',
                            valueColor: _averageConfidence >= 0.7
                                ? Colors.green
                                : Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Accuracy Score Section (correction vs confirmation tracking)
                    _buildSectionCard(
                      context,
                      title: '🎯 Accuracy Score',
                      icon: Icons.fact_check_outlined,
                      color: _accuracyColor,
                      children: [
                        _buildStatRow('Confirmations',
                            _totalConfirmations.toString(),
                            valueColor: Colors.green),
                        _buildStatRow('Corrections',
                            _totalCorrections.toString(),
                            valueColor: _totalCorrections > 0
                                ? Colors.orange
                                : Colors.grey),
                        const Divider(height: 24),
                        _buildStatRow(
                            'Accuracy Rate',
                            _totalConfirmations + _totalCorrections > 0
                                ? '${(_accuracyRate * 100).toStringAsFixed(1)}%'
                                : 'N/A',
                            valueColor: _accuracyColor),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: _totalConfirmations + _totalCorrections > 0
                              ? _accuracyRate
                              : 0,
                          backgroundColor: Colors.grey[300],
                          color: _accuracyColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _totalConfirmations + _totalCorrections > 0
                              ? _accuracyRate >= 0.9
                                  ? 'Excellent! You rarely need to correct the AI.'
                                  : _accuracyRate >= 0.7
                                      ? 'Good accuracy. Keep providing feedback to improve AI.'
                                      : 'Your corrections help train the AI. Thank you!'
                              : 'Confirm or correct classifications to build your accuracy score.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Offline Queue Section
                    _buildSectionCard(
                      context,
                      title: '📱 Offline Queue Performance',
                      icon: Icons.cloud_queue,
                      color: Colors.purple,
                      children: [
                        _buildStatRow(
                            'Total Queued', _totalQueuedImages.toString()),
                        _buildStatRow(
                            'Processed', _processedQueuedImages.toString(),
                            valueColor: Colors.green),
                        _buildStatRow(
                            'Pending', _pendingQueuedImages.toString(),
                            valueColor: _pendingQueuedImages > 0
                                ? Colors.orange
                                : Colors.grey),
                        GestureDetector(
                          onTap: _deadLetterCount > 0
                              ? _showDeadLetterDialog
                              : null,
                          child: _buildStatRow(
                            'Dead-Letter',
                            _deadLetterCount.toString(),
                            valueColor: _deadLetterCount > 0
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: _totalQueuedImages > 0
                              ? _processedQueuedImages / _totalQueuedImages
                              : 0,
                          backgroundColor: Colors.grey[300],
                          color: Colors.purple,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _totalQueuedImages > 0
                              ? '${(_processedQueuedImages / _totalQueuedImages * 100).toStringAsFixed(1)}% Complete'
                              : 'No queued images',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Cost Savings Section
                    _buildSectionCard(
                      context,
                      title: '💰 Cost Savings',
                      icon: Icons.savings_outlined,
                      color: Colors.green,
                      children: [
                        _buildStatRow('API Calls Saved',
                            _apiCallsSaved.toStringAsFixed(0)),
                        _buildStatRow('Estimated Savings',
                            '\$${_estimatedCostSavings.toStringAsFixed(2)}',
                            valueColor: Colors.green),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.eco, color: Colors.green[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Offline processing saves API calls when you\'re disconnected, reducing costs and improving reliability!',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Additional Stats
                    if (_totalClassifications > 0) _buildInsightCard(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
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
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
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
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
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

  Color get _accuracyColor {
    final total = _totalConfirmations + _totalCorrections;
    if (total == 0) return Colors.grey;
    if (_accuracyRate >= 0.9) return Colors.green;
    if (_accuracyRate >= 0.7) return Colors.blue;
    if (_accuracyRate >= 0.5) return Colors.orange;
    return Colors.red;
  }

  Widget _buildInsightCard(BuildContext context) {
    final highConfidenceRate = _totalClassifications > 0
        ? (_highConfidenceClassifications / _totalClassifications * 100)
        : 0;

    String insight;
    Color insightColor;
    IconData insightIcon;

    if (highConfidenceRate >= 90) {
      insight = 'Excellent! Your classifications are highly accurate!';
      insightColor = Colors.green;
      insightIcon = Icons.emoji_events;
    } else if (highConfidenceRate >= 70) {
      insight = 'Good work! Most of your classifications are confident.';
      insightColor = Colors.blue;
      insightIcon = Icons.thumb_up;
    } else {
      insight =
          'Tip: Try taking clearer photos for better classification accuracy.';
      insightColor = Colors.orange;
      insightIcon = Icons.lightbulb_outline;
    }

    return Card(
      color: insightColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(insightIcon, color: insightColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quality Insight',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: insightColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'High Confidence Rate: ${highConfidenceRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: insightColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (_totalConfirmations + _totalCorrections > 0)
                    Text(
                      'Accuracy: ${(_accuracyRate * 100).toStringAsFixed(1)}% confirmations',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _accuracyColor,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeadLetterDialog extends StatefulWidget {
  const _DeadLetterDialog({
    required this.items,
    required this.onRetry,
    required this.onClearAll,
  });

  final List<DeadLetterClassification> items;
  final Future<void> Function(String id) onRetry;
  final Future<void> Function() onClearAll;

  @override
  State<_DeadLetterDialog> createState() => _DeadLetterDialogState();
}

class _DeadLetterDialogState extends State<_DeadLetterDialog> {
  final Set<String> _retrying = {};
  bool _clearingAll = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 24),
          const SizedBox(width: 8),
          Text('Dead-Letter Queue (${widget.items.length})'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.items.length + (_clearingAll ? 1 : 0),
          itemBuilder: (context, index) {
            if (_clearingAll) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final item = widget.items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.imageName ?? item.id,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_retrying.contains(item.id))
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 18),
                            tooltip: 'Retry',
                            onPressed: () async {
                              setState(() => _retrying.add(item.id));
                              await widget.onRetry(item.id);
                              if (mounted) {
                                setState(() => _retrying.remove(item.id));
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Error: ${item.lastError}',
                      style: TextStyle(fontSize: 12, color: Colors.red[700]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Retries: ${item.retryCount} · Queued: ${_formatDate(item.queuedAt)} · Failed: ${_formatDate(item.failedAt)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    if (item.region != 'Unknown')
                      Text(
                        'Region: ${item.region}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _clearingAll
              ? null
              : () async {
                  setState(() => _clearingAll = true);
                  await widget.onClearAll();
                  if (mounted) Navigator.of(context).pop();
                },
          child: const Text('Clear All'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
