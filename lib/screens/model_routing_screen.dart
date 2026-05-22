import 'package:flutter/material.dart';
import '../services/model_selection_service.dart';

class ModelRoutingScreen extends StatelessWidget {
  const ModelRoutingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Routing'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Strategies',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...ModelSelectionStrategy.values.map(
                    (s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.router,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(s.name),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evidence Collection',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Each classification records:\n'
                    '  • Strategy used (modelSelectionStrategy)\n'
                    '  • Analysis source (cloud/local/fallback)\n'
                    '  • Model source and version\n'
                    '  • Confidence and latency\n'
                    '  • Route cost (estimated)\n'
                    '  • Fallback reason (if applicable)',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Future: Evidence Dashboard',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This screen will host the PerformanceMonitoringDashboard '
                    'once ModelSelectionService is wired through app DI.\n\n'
                    'Planned features:\n'
                    '  • Per-source success/failure counts\n'
                    '  • Average confidence and latency\n'
                    '  • Fallback chain analysis\n'
                    '  • Correction rate per strategy\n'
                    '  • Cost breakdown by source\n'
                    '  • Strategy recommendation engine',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
