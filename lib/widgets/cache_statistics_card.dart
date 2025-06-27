import 'dart:async';
import 'package:flutter/material.dart';
import 'package:waste_segregation_app/services/cache_service.dart';

/// A widget that displays classification cache statistics
///
/// This widget shows real-time cache performance metrics such as:
/// - Cache hit rate
/// - Number of entries in cache
/// - Estimated data savings
/// - Cache age
class CacheStatisticsCard extends StatefulWidget {
  const CacheStatisticsCard({
    super.key,
    required this.cacheService,
    this.autoRefresh = true,
    this.refreshInterval = const Duration(seconds: 30),
  });
  final ClassificationCacheService cacheService;
  final bool autoRefresh;
  final Duration refreshInterval;

  @override
  State<CacheStatisticsCard> createState() => _CacheStatisticsCardState();
}

class _CacheStatisticsCardState extends State<CacheStatisticsCard> {
  Map<String, dynamic> _statistics = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _updateStatistics();

    // Set up auto-refresh if enabled
    if (widget.autoRefresh) {
      _refreshTimer = Timer.periodic(widget.refreshInterval, (_) {
        _updateStatistics();
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _updateStatistics() {
    setState(() {
      _statistics = widget.cacheService.getCacheStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Classification Cache',
                  style: theme.textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _updateStatistics,
                  tooltip: 'Refresh statistics',
                ),
              ],
            ),
            const Divider(),
            if (_statistics.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Column(
                children: [
                  _buildStatRow(
                    context,
                    'Hit Rate:',
                    _statistics['hitRate'] ?? '0%',
                    Icons.trending_up,
                    _getHitRateColor(context),
                  ),
                  _buildStatRow(
                    context,
                    'Cache Size:',
                    '${_statistics['size'] ?? 0} entries',
                    Icons.storage,
                    null,
                  ),
                  _buildStatRow(
                    context,
                    'Data Saved:',
                    _statistics['bytesSavedFormatted'] ?? '0 bytes',
                    Icons.save,
                    Colors.green,
                  ),
                  _buildStatRow(
                    context,
                    'Cache Age:',
                    '${_statistics['ageHours'] ?? 0} hours',
                    Icons.access_time,
                    null,
                  ),

                  // Show similar hit rate when available
                  if (_statistics.containsKey('similarHits'))
                    _buildStatRow(
                      context,
                      'Similar Matches:',
                      _statistics['similarHitRate'] ?? '0%',
                      Icons.find_replace,
                      Colors.blue,
                    ),

                  // Show hash type breakdown
                  if (_statistics.containsKey('pHashCount'))
                    _buildStatRow(
                      context,
                      'Perceptual Hashes:',
                      '${_statistics['pHashCount']} entries',
                      Icons.image_search,
                      Colors.purple,
                    ),
                ],
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    final confirmed = await _showClearCacheDialog(context);
                    if (confirmed == true) {
                      await widget.cacheService.clearCache();
                      _updateStatistics();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cache cleared successfully'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Clear Cache'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color? valueColor,
  ) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.titleMedium?.copyWith(
      color: valueColor,
      fontWeight: FontWeight.bold,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.bodyLarge),
          const Spacer(),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }

  Color _getHitRateColor(BuildContext context) {
    final hitRateStr = (_statistics['hitRate'] as String?) ?? '0%';
    final hitRate = double.tryParse(hitRateStr.replaceAll('%', '')) ?? 0;

    if (hitRate >= 80) {
      return Colors.green;
    } else if (hitRate >= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Future<bool?> _showClearCacheDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text('This will remove all cached image classifications. '
            'You will need to re-analyze images that were previously classified.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
