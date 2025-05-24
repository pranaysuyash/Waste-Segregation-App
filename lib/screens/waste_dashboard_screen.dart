import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../models/waste_classification.dart';
import '../widgets/gamification_widgets.dart';
import '../widgets/enhanced_gamification_widgets.dart';
import '../services/gamification_service.dart';
import '../models/gamification.dart';
// Removed import for '../widgets/empty_state_widget.dart'; as EmptyStateWidget is defined below

class WasteDashboardScreen extends StatefulWidget {
  const WasteDashboardScreen({super.key});

  @override
  State<WasteDashboardScreen> createState() => _WasteDashboardScreenState();
}

class _WasteDashboardScreenState extends State<WasteDashboardScreen> {
  // Classification data
  late List<WasteClassification> _classifications = [];
  DateTime? _firstClassificationDate;
  Map<String, int> _wasteCategoryCounts = {};
  Map<String, int> _wasteSubcategoryCounts = {};
  Map<DateTime, int> _wasteByDate = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the real data from storage service
      final storageService = Provider.of<StorageService>(context, listen: false);
      final classifications = await storageService.getAllClassifications();
      
      // Process the classifications to generate statistics
      _processClassifications(classifications);
      
      setState(() {
        _classifications = classifications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading analytics data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _processClassifications(List<WasteClassification> classifications) {
    // Skip processing if no data
    if (classifications.isEmpty) return;
    
    // Sort classifications by timestamp
    classifications.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Set first classification date
    _firstClassificationDate = classifications.first.timestamp;
    
    // Reset counters
    _wasteCategoryCounts = {};
    _wasteSubcategoryCounts = {};
    _wasteByDate = {};
    
    // Process each classification
    for (final classification in classifications) {
      // Count categories
      _wasteCategoryCounts.update(
        classification.category, 
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      
      // Count subcategories
      if (classification.subcategory?.isNotEmpty == true) {
        _wasteSubcategoryCounts.update(
          classification.subcategory!,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
      
      // Count by date (using date only, not time)
      final date = DateTime(
        classification.timestamp.year,
        classification.timestamp.month,
        classification.timestamp.day,
      );
      
      _wasteByDate.update(
        date, 
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _classifications.isEmpty
              ? EmptyStateWidget(
                  title: 'No Data Yet',
                  message: 'Start classifying waste items to see your personalized analytics dashboard.',
                  actionButton: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Start Classifying'),
                  ),
                )
              : _buildDashboard(),
    );
  }
  
  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary stats
          _buildSummaryStats(),
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Recent activity chart
          _buildSectionHeader('Recent Activity'),
          _buildActivityChart(),
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Category distribution
          _buildSectionHeader('Waste Category Distribution'),
          _buildCategoryDistribution(),
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Top subcategories
          _buildSectionHeader('Top Waste Types'),
          _buildTopSubcategories(),
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Recent classifications
          _buildSectionHeader('Recent Classifications'),
          _buildRecentClassifications(),
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Environmental impact
          _buildSectionHeader('Your Environmental Impact'),
          _buildImpactSection(),
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Gamification section
          _buildGamificationSection(),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
  
  Widget _buildSummaryStats() {
    final totalItems = _wasteCategoryCounts.values.fold<int>(0, (sum, count) => sum + count);
    final trackingDays = _getDaysOfTracking();
    final recyclableItems = _classifications.where((c) => c.isRecyclable == true).length;
    
    return Row(
      children: [
        _buildStatBox(
          context,
          'Total Items',
          totalItems.toString(),
          Icons.category,
          AppTheme.primaryColor,
        ),
        _buildStatBox(
          context,
          'Days Tracking',
          trackingDays.toString(),
          Icons.calendar_today,
          AppTheme.secondaryColor,
        ),
        _buildStatBox(
          context,
          'Recyclable',
          '$recyclableItems',
          Icons.recycling,
          AppTheme.secondaryColor,
        ),
      ],
    );
  }
  
  Widget _buildStatBox(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(4),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingSmall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActivityChart() {
    final timeSeriesData = _getWasteTimeSeriesData();
    if (timeSeriesData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppTheme.paddingLarge),
        child: Center(child: Text('Not enough data yet')),
      );
    }
    
    return SizedBox(
      height: 200,
      child: WebChartWidget(
        data: timeSeriesData,
        title: 'Recent Activity',
      ),
    );
  }
  
  Widget _buildCategoryDistribution() {
    if (_wasteCategoryCounts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppTheme.paddingLarge),
        child: Center(child: Text('Not enough data yet')),
      );
    }
    
    final total = _wasteCategoryCounts.values.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) {
      return const Center(child: Text('No category data available'));
    }
    
    // Prepare data for the chart
    final List<Map<String, dynamic>> pieData = [];
    
    for (final entry in _wasteCategoryCounts.entries) {
      final color = _getCategoryColor(entry.key);
      final colorHex = '#${color.value.toRadixString(16).substring(2)}';
      final percentage = entry.value / total;
      
      pieData.add({
        'label': entry.key,
        'value': entry.value,
        'color': colorHex,
        'percentage': '${(percentage * 100).toStringAsFixed(0)}%',
      });
    }
    
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: WebPieChartWidget(data: pieData),
        ),
        const SizedBox(height: AppTheme.paddingRegular),
        
        // Legend
        Wrap(
          spacing: AppTheme.paddingRegular,
          runSpacing: AppTheme.paddingSmall,
          children: _wasteCategoryCounts.entries.map((entry) => 
            _buildLegendItem(entry.key, _getCategoryColor(entry.key))
          ).toList(),
        ),
      ],
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTopSubcategories() {
    if (_wasteSubcategoryCounts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppTheme.paddingLarge),
        child: Center(child: Text('Not enough data yet')),
      );
    }
    
    final topSubcategories = _getTopSubcategories(5);
    final maxValue = topSubcategories.isNotEmpty 
        ? topSubcategories.map((e) => e.value).reduce((a, b) => a > b ? a : b) 
        : 1;
    
    return Column(
      children: topSubcategories.map((entry) => 
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: AppTheme.fontSizeSmall),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: entry.value / maxValue,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
              SizedBox(
                width: 40,
                child: Padding(
                  padding: const EdgeInsets.only(left: AppTheme.paddingSmall),
                  child: Text(
                    '${entry.value}',
                    style: const TextStyle(fontSize: AppTheme.fontSizeSmall),
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ],
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildRecentClassifications() {
    if (_classifications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppTheme.paddingLarge),
        child: Center(child: Text('No classifications yet')),
      );
    }
    
    // Get the most recent classifications (up to 5)
    final recentClassifications = _classifications
        .sublist(0, _classifications.length > 5 ? 5 : _classifications.length);
    
    return Column(
      children: recentClassifications.map((classification) => 
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: _getCategoryIcon(classification.category),
            title: Text(
              classification.itemName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${classification.category} • ${DateFormat.yMMMd().format(classification.timestamp)}',
            ),
            trailing: classification.isRecyclable == true
                ? const Icon(Icons.recycling, color: AppTheme.primaryColor)
                : const Icon(Icons.do_not_disturb, color: Colors.red),
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildImpactSection() {
    // Calculate environmental impact metrics
    final recyclableCount = _classifications.where((c) => c.isRecyclable == true).length;
    final totalItems = _classifications.length;
    
    // Avoid division by zero
    final recyclingRate = totalItems > 0 ? (recyclableCount / totalItems) : 0;
    
    // Very simplified impact calculations - these would be more sophisticated in a real app
    final estimatedCO2Saved = recyclableCount * 0.5; // kg of CO2
    final estimatedWaterSaved = recyclableCount * 100; // liters of water
    
    return Column(
      children: [
        _buildImpactMetric(
          'Recycling Rate', 
          '${(recyclingRate * 100).toStringAsFixed(1)}%',
          Icons.eco,
          AppTheme.primaryColor,
        ),
        const SizedBox(height: AppTheme.paddingSmall),
        _buildImpactMetric(
          'CO₂ Emissions Saved', 
          '${estimatedCO2Saved.toStringAsFixed(1)} kg',
          Icons.cloud_outlined,
          AppTheme.secondaryColor,
        ),
        const SizedBox(height: AppTheme.paddingSmall),
        _buildImpactMetric(
          'Water Saved', 
          '${estimatedWaterSaved.toStringAsFixed(0)} L',
          Icons.water_drop_outlined,
          Colors.blue,
        ),
        const SizedBox(height: AppTheme.paddingSmall),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(AppTheme.paddingRegular),
            child: Text(
              'These are estimated figures based on average environmental impact data. '
              'Actual impact varies based on local waste management practices.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildImpactMetric(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: AppTheme.paddingRegular),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
  
  // Helper methods
  int _getDaysOfTracking() {
    if (_firstClassificationDate == null) return 0;
    
    final now = DateTime.now();
    return now.difference(_firstClassificationDate!).inDays + 1;
  }
  
  List<Map<String, dynamic>> _getWasteTimeSeriesData() {
    if (_wasteByDate.isEmpty) return [];
    
    // Sort the dates
    final sortedDates = _wasteByDate.keys.toList()..sort();
    
    // Create the time series data
    return sortedDates.map((date) => {
      'date': date,
      'count': _wasteByDate[date] ?? 0,
    }).toList();
  }
  
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Wet Waste': return AppTheme.wetWasteColor;
      case 'Dry Waste': return AppTheme.dryWasteColor;
      case 'Hazardous Waste': return AppTheme.hazardousWasteColor;
      case 'Medical Waste': return AppTheme.medicalWasteColor;
      case 'Non-Waste': return AppTheme.nonWasteColor;
      default: return AppTheme.lightGreyColor;
    }
  }
  
  Widget _getCategoryIcon(String category) {
    IconData iconData;
    Color color;
    
    switch (category) {
      case 'Wet Waste':
        iconData = Icons.compost;
        color = AppTheme.wetWasteColor;
        break;
      case 'Dry Waste':
        iconData = Icons.recycling;
        color = AppTheme.dryWasteColor;
        break;
      case 'Hazardous Waste':
        iconData = Icons.warning;
        color = AppTheme.hazardousWasteColor;
        break;
      case 'Medical Waste':
        iconData = Icons.medical_services;
        color = AppTheme.medicalWasteColor;
        break;
      case 'Non-Waste':
        iconData = Icons.replay;
        color = AppTheme.nonWasteColor;
        break;
      default:
        iconData = Icons.category;
        color = AppTheme.lightGreyColor;
    }
    
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(iconData, color: color),
    );
  }
  
  List<MapEntry<String, int>> _getTopSubcategories(int count) {
    final sortedEntries = _wasteSubcategoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.take(count).toList();
  }

  Widget _buildGamificationSection() {
    return FutureBuilder<GamificationProfile>(
      future: GamificationService().getProfile(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final profile = snapshot.data!;
        final points = profile.points;
        final streak = profile.streak;
        final achievements = profile.achievements.where((a) => a.isEarned).toList();
        final activeChallenges = profile.activeChallenges.where((c) => !c.isExpired && !c.isCompleted).toList();
        final pointsToNextLevel = points.pointsToNextLevel;
        final motivational = pointsToNextLevel > 0
            ? 'Only $pointsToNextLevel points to reach the next level!'
            : 'Level up! Keep going!';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Gamification & Progress'),
            const SizedBox(height: AppTheme.paddingSmall),
            Row(
              children: [
                Expanded(child: StreakIndicator(streak: streak)),
                const SizedBox(width: AppTheme.paddingSmall),
                Expanded(child: EnhancedPointsIndicator(points: points)),
              ],
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            Text(motivational, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: AppTheme.paddingRegular),
            if (achievements.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Badges', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: achievements.length > 3 ? 3 : achievements.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final a = achievements[i];
                        return _BadgePreview(achievement: a);
                      },
                    ),
                  ),
                ],
              ),
            if (activeChallenges.isNotEmpty) ...[
              const SizedBox(height: AppTheme.paddingRegular),
              const Text('Active Challenge', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ChallengeCard(challenge: activeChallenges.first),
            ],
            const SizedBox(height: AppTheme.paddingRegular),
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingRegular),
                child: Row(
                  children: [
                    const Icon(Icons.leaderboard, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Leaderboard coming soon! Compete with others to see who's the top recycler.",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- Badge preview widget ---
class _BadgePreview extends StatelessWidget {
  final Achievement achievement;
  const _BadgePreview({required this.achievement});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: achievement.color.withOpacity(0.2),
          child: Icon(
            Icons.emoji_events,
            color: achievement.color,
            size: 32,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: Text(
            achievement.title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
final String title;
final String message;
final Widget? actionButton;

const EmptyStateWidget({
super.key,
required this.title,
required this.message,
this.actionButton,
});

@override
Widget build(BuildContext context) {
return Center(
child: Padding(
padding: const EdgeInsets.all(AppTheme.paddingLarge),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.analytics_outlined,
size: 64,
color: AppTheme.primaryColor.withOpacity(0.5),
),
const SizedBox(height: AppTheme.paddingRegular),
Text(
title,
style: Theme.of(context).textTheme.headlineSmall,
textAlign: TextAlign.center,
),
const SizedBox(height: AppTheme.paddingSmall),
Text(
message,
textAlign: TextAlign.center,
style: TextStyle(
color: AppTheme.textSecondaryColor,
),
),
if (actionButton != null) ...[  
const SizedBox(height: AppTheme.paddingRegular),
actionButton!,
],
],
),
),
);
}
}

class WebChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final String title;
  
  const WebChartWidget({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  State<WebChartWidget> createState() => _WebChartWidgetState();
}

class _WebChartWidgetState extends State<WebChartWidget> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_generateChartHtml());
  }

  String _generateChartHtml() {
    // Format the data for JavaScript
    final chartData = widget.data.map((item) {
      final date = item['date'] as DateTime;
      return {
        'x': date.millisecondsSinceEpoch,
        'y': item['count'],
      };
    }).toList();
    
    final jsonData = jsonEncode(chartData);
    final primaryColorHex = '#${AppTheme.primaryColor.value.toRadixString(16).substring(2)}';
    
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
        <style>
          body { margin: 0; padding: 0; }
          .chart-container { width: 100%; height: 100%; }
        </style>
      </head>
      <body>
        <div class="chart-container">
          <canvas id="myChart"></canvas>
        </div>
        
        <script>
          // Parse the data passed from Flutter
          const data = $jsonData;
          
          // Format dates for display
          const formatDate = (timestamp) => {
            const date = new Date(timestamp);
            return date.toLocaleDateString();
          };
          
          // Create chart
          const ctx = document.getElementById('myChart');
          new Chart(ctx, {
            type: 'line',
            data: {
              datasets: [{
                label: '${widget.title}',
                data: data,
                fill: true,
                borderColor: '$primaryColorHex',
                backgroundColor: '$primaryColorHex' + '33', // 20% opacity
                tension: 0.3,
                pointRadius: 3,
                pointHoverRadius: 5
              }]
            },
            options: {
              responsive: true,
              maintainAspectRatio: false,
              parsing: {
                xAxisKey: 'x',
                yAxisKey: 'y'
              },
              scales: {
                x: {
                  type: 'time',
                  time: {
                    unit: 'day',
                    displayFormats: {
                      day: 'MMM d'
                    }
                  },
                  title: {
                    display: false
                  }
                },
                y: {
                  beginAtZero: true,
                  ticks: {
                    precision: 0
                  },
                  title: {
                    display: false
                  }
                }
              },
              plugins: {
                tooltip: {
                  callbacks: {
                    title: (context) => {
                      return formatDate(context[0].parsed.x);
                    },
                    label: (context) => {
                      return context.parsed.y + ' items';
                    }
                  },
                  backgroundColor: 'rgba(0, 0, 0, 0.7)',
                  padding: 10,
                  cornerRadius: 6
                },
                legend: {
                  display: false
                }
              }
            }
          });
        </script>
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: controller);
  }
}

class WebPieChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  
  const WebPieChartWidget({
    super.key,
    required this.data,
  });

  @override
  State<WebPieChartWidget> createState() => _WebPieChartWidgetState();
}

class _WebPieChartWidgetState extends State<WebPieChartWidget> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_generateChartHtml());
  }

  String _generateChartHtml() {
    final jsonData = jsonEncode(widget.data);
    
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
        <style>
          body { margin: 0; padding: 0; }
          .chart-container { width: 100%; height: 100%; }
        </style>
      </head>
      <body>
        <div class="chart-container">
          <canvas id="myChart"></canvas>
        </div>
        
        <script>
          // Parse the data passed from Flutter
          const data = $jsonData;
          
          // Extract data for the chart
          const labels = data.map(item => item.label);
          const values = data.map(item => item.value);
          const colors = data.map(item => item.color);
          const percentages = data.map(item => item.percentage);
          
          // Create chart
          const ctx = document.getElementById('myChart');
          new Chart(ctx, {
            type: 'doughnut',
            data: {
              labels: labels,
              datasets: [{
                data: values,
                backgroundColor: colors,
                borderColor: colors.map(color => color),
                borderWidth: 1,
                hoverOffset: 5
              }]
            },
            options: {
              responsive: true,
              maintainAspectRatio: false,
              cutout: '40%',
              plugins: {
                tooltip: {
                  callbacks: {
                    label: (context) => {
                      return context.parsed + ' items (' + percentages[context.dataIndex] + ')';
                    }
                  },
                  backgroundColor: 'rgba(0, 0, 0, 0.7)',
                  padding: 10,
                  cornerRadius: 6
                },
                legend: {
                  display: false
                }
              }
            }
          });
        </script>
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: controller);
  }
}
