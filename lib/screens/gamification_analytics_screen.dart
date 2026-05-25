import 'package:flutter/material.dart';
import '../models/cooperative_mechanics.dart';
import '../services/gamification_analytics_service.dart';
import '../utils/constants.dart';

/// Internal analytics dashboard for measuring gamification mechanic effectiveness.
///
/// This screen is the kill-switch layer: if a mechanic isn't moving the
/// numbers shown here, it gets removed. It's not meant for end users —
/// it's an operator/admin view (can be gated behind admin check in nav).
///
/// Key metrics tracked:
///   - Household participation rate (target: >0.5)
///   - Goal completion rate (target: >0.3)
///   - Cooperative challenge join rate (target: >0.4)
///   - Non-primary user 7-day return (target: ≥2 returns/week)
///   - Household streak distribution
class GamificationAnalyticsScreen extends StatefulWidget {
  const GamificationAnalyticsScreen({
    super.key,
    required this.analyticsService,
    this.familyId,
  });

  final GamificationAnalyticsService analyticsService;

  /// If provided, shows per-family metrics. If null, shows aggregate view.
  final String? familyId;

  @override
  State<GamificationAnalyticsScreen> createState() =>
      _GamificationAnalyticsScreenState();
}

class _GamificationAnalyticsScreenState
    extends State<GamificationAnalyticsScreen> {
  List<CooperativeMechanicSnapshot> _snapshots = [];
  bool _isLoading = true;
  String? _error;
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final snapshots = widget.familyId != null
          ? await widget.analyticsService.getSnapshotHistory(
              familyId: widget.familyId!,
              days: _selectedDays,
            )
          : <CooperativeMechanicSnapshot>[];

      if (!mounted) return;
      setState(() {
        _snapshots = snapshots;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load analytics: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamification Analytics'),
        centerTitle: false,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.date_range),
            tooltip: 'Select time range',
            onSelected: (days) {
              setState(() => _selectedDays = days);
              _loadData();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 7, child: Text('Last 7 days')),
              PopupMenuItem(value: 30, child: Text('Last 30 days')),
              PopupMenuItem(value: 90, child: Text('Last 90 days')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_snapshots.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No data yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Cooperative mechanics snapshots will appear here once\nfamilies start using goals, tasks, and challenges.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        children: [
          _buildSummaryHeader(),
          const SizedBox(height: AppTheme.paddingLarge),
          _buildKillCriteriaCard(),
          const SizedBox(height: AppTheme.paddingLarge),
          _buildParticipationChart(),
          const SizedBox(height: AppTheme.paddingLarge),
          _buildGoalMetricsCard(),
          const SizedBox(height: AppTheme.paddingLarge),
          _buildChallengeMetricsCard(),
          const SizedBox(height: AppTheme.paddingLarge),
          _buildStreakDistributionCard(),
          const SizedBox(height: AppTheme.paddingLarge),
          _buildRawSnapshotList(),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    if (_snapshots.isEmpty) return const SizedBox.shrink();
    final latest = _snapshots.last;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last snapshot: ${_formatDate(latest.snapshotDate)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statChip(
                  '${(latest.participationRate * 100).toStringAsFixed(0)}%',
                  'Participation',
                  latest.participationRate >= 0.5
                      ? Colors.green
                      : Colors.orange,
                ),
                _statChip(
                  '${(latest.goalCompletionRate * 100).toStringAsFixed(0)}%',
                  'Goal completion',
                  latest.goalCompletionRate >= 0.3
                      ? Colors.green
                      : Colors.orange,
                ),
                _statChip(
                  '${latest.householdStreakDays}d',
                  'Streak',
                  latest.householdStreakDays >= 7
                      ? Colors.green
                      : Colors.orange,
                ),
                _statChip(
                  '${latest.nonPrimaryUserReturnCount}',
                  'Non-primary returns',
                  latest.nonPrimaryUserReturnCount >= 2
                      ? Colors.green
                      : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildKillCriteriaCard() {
    if (_snapshots.isEmpty) return const SizedBox.shrink();
    final latest = _snapshots.last;

    final criteria = [
      _KillCriterion(
        label: 'Participation rate ≥ 50%',
        value: '${(latest.participationRate * 100).toStringAsFixed(0)}%',
        passes: latest.participationRate >= 0.5,
        consequence: 'Below threshold: demote dashboard to presentation layer',
      ),
      _KillCriterion(
        label: 'Goal completion rate ≥ 30%',
        value: '${(latest.goalCompletionRate * 100).toStringAsFixed(0)}%',
        passes: latest.goalCompletionRate >= 0.3,
        consequence: 'Below threshold: simplify goals or remove them',
      ),
      _KillCriterion(
        label: 'Non-primary user returns ≥ 2/week',
        value: '${latest.nonPrimaryUserReturnCount}',
        passes: latest.nonPrimaryUserReturnCount >= 2,
        consequence:
            'Below threshold: cooperative mechanics not driving return',
      ),
      _KillCriterion(
        label: 'Active cooperative challenges ≥ 1',
        value: '${latest.activeCoopChallenges}',
        passes: latest.activeCoopChallenges >= 1,
        consequence: 'No active challenges: mechanic not being adopted',
      ),
    ];

    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kill Criteria',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              'If a criterion fails after 30 days, its mechanic is removed.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            ...criteria.map((c) => _buildKillRow(c)),
          ],
        ),
      ),
    );
  }

  Widget _buildKillRow(_KillCriterion criterion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            criterion.passes ? Icons.check_circle : Icons.cancel,
            color: criterion.passes ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        criterion.label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      criterion.value,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            criterion.passes ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                if (!criterion.passes)
                  Text(
                    criterion.consequence,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipationChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participation Rate (${_selectedDays}d)',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            SizedBox(
              height: 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _snapshots.map((s) {
                  final h = (s.participationRate * 80).clamp(4.0, 80.0);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Tooltip(
                        message:
                            '${_formatDate(s.snapshotDate)}: ${(s.participationRate * 100).toStringAsFixed(0)}%',
                        child: Container(
                          height: h,
                          decoration: BoxDecoration(
                            color: s.participationRate >= 0.5
                                ? Colors.green
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(_snapshots.first.snapshotDate),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  _formatDate(_snapshots.last.snapshotDate),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalMetricsCard() {
    if (_snapshots.isEmpty) return const SizedBox.shrink();
    final latest = _snapshots.last;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goal Metrics',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            _metricRow('Active goals', '${latest.activeGoalCount}'),
            _metricRow('Completed goals', '${latest.completedGoalCount}'),
            _metricRow('Completion rate',
                '${(latest.goalCompletionRate * 100).toStringAsFixed(1)}%'),
            _metricRow('Active tasks', '${latest.activeTaskCount}'),
            _metricRow('Completed tasks', '${latest.completedTaskCount}'),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeMetricsCard() {
    if (_snapshots.isEmpty) return const SizedBox.shrink();
    final latest = _snapshots.last;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cooperative Challenge Metrics',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            _metricRow('Active challenges', '${latest.activeCoopChallenges}'),
            _metricRow(
                'Completed challenges', '${latest.completedCoopChallenges}'),
            _metricRow('Challenge joins', '${latest.challengeJoinCount}'),
            _metricRow('Non-primary returns (7d)',
                '${latest.nonPrimaryUserReturnCount}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakDistributionCard() {
    if (_snapshots.isEmpty) return const SizedBox.shrink();
    final maxStreak = _snapshots
        .map((s) => s.householdStreakDays)
        .fold(1, (a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Household Streak (${_selectedDays}d)',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            SizedBox(
              height: 60,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _snapshots.map((s) {
                  final h =
                      maxStreak > 0 ? (s.householdStreakDays / maxStreak * 60).clamp(4.0, 60.0) : 4.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Tooltip(
                        message:
                            '${_formatDate(s.snapshotDate)}: ${s.householdStreakDays}d',
                        child: Container(
                          height: h,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRawSnapshotList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Snapshot History',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            ...(_snapshots.reversed.take(7).map((s) => ListTile(
                  dense: true,
                  title: Text(_formatDate(s.snapshotDate)),
                  subtitle: Text(
                      'Participation: ${(s.participationRate * 100).toStringAsFixed(0)}% · '
                      'Streak: ${s.householdStreakDays}d · '
                      'Goals: ${s.completedGoalCount}/${s.activeGoalCount + s.completedGoalCount}'),
                ))),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}

class _KillCriterion {
  const _KillCriterion({
    required this.label,
    required this.value,
    required this.passes,
    required this.consequence,
  });
  final String label;
  final String value;
  final bool passes;
  final String consequence;
}
