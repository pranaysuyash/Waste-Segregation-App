import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../models/waste_classification.dart';
import '../services/gamification_service.dart';
import '../models/gamification.dart';
// import '../widgets/enhanced_loading_widget.dart'; // Removed
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
      
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
              ? const EmptyStateWidget(
                  title: 'No Data Yet',
                  message: 'Start classifying waste items to see your personalized analytics dashboard.',
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
                      style: const TextStyle(
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
        return Card(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.25,
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Not enough data yet'),
                Text('Classify some items to see your activity chart!', 
                     style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }
    
      return Card(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.3,
        padding: const EdgeInsets.all(AppTheme.paddingSmall),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Items classified over time',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Expanded(
              child: WebChartWidget(
                data: timeSeriesData,
                title: 'Recent Activity',
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryDistribution() {
      if (_wasteCategoryCounts.isEmpty) {
        return Card(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.25,
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pie_chart, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Not enough data yet'),
                Text('Classify items to see category breakdown!', 
                     style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }
    
    final total = _wasteCategoryCounts.values.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) {
      return const Center(child: Text('No category data available'));
    }
    
    // Prepare data for the chart
    final pieData = <Map<String, dynamic>>[];
    
    for (final entry in _wasteCategoryCounts.entries) {
      final color = _getCategoryColor(entry.key);
      final colorHex = '#${color.toARGB32().toRadixString(16).substring(2)}';
      final percentage = entry.value / total;
      
      pieData.add({
        'label': entry.key,
        'value': entry.value,
        'color': colorHex,
        'percentage': '${(percentage * 100).toStringAsFixed(0)}%',
      });
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          children: [
            Text(
              'Category breakdown of your classifications',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppTheme.paddingRegular),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
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
        ),
      ),
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
      return Card(
        child: Container(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: const Center(
            child: Column(
              children: [
                Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Not enough data yet'),
                Text('Classify more items to see top waste types!', 
                     style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }
    
    final topSubcategories = _getTopSubcategories(5);
    final maxValue = topSubcategories.isNotEmpty 
        ? topSubcategories.map((e) => e.value).reduce((a, b) => a > b ? a : b) 
        : 1;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most frequently identified waste types',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            ...topSubcategories.map((entry) => 
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
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentClassifications() {
    if (_classifications.isEmpty) {
      return Card(
        child: Container(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: const Center(
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('No classifications yet'),
                Text('Start classifying items to see your history!', 
                     style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }
    
    // Get the most recent classifications (up to 5)
    final recentClassifications = _classifications.reversed
        .take(5)
        .toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your latest classifications',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            ...recentClassifications.map((classification) => 
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
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
            ),
          ],
        ),
      ),
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
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your positive environmental impact',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppTheme.paddingRegular),
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
              Icons.air,
              Colors.green,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            _buildImpactMetric(
              'Water Saved', 
              '${estimatedWaterSaved.toStringAsFixed(0)} L',
              Icons.water_drop,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImpactMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingSmall),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      backgroundColor: color.withValues(alpha: 0.2),
      radius: 16,
      child: Icon(iconData, color: color, size: 18),
    );
  }
  
  List<MapEntry<String, int>> _getTopSubcategories(int count) {
    final sortedEntries = _wasteSubcategoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.take(count).toList();
  }

  Widget _buildGamificationSection() {
    return FutureBuilder<GamificationProfile>(
      future: Provider.of<GamificationService>(context, listen: false).getProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingLarge),
              child: Center(
                child: Text(snapshot.hasError 
                    ? 'Error loading gamification data.' 
                    : 'Gamification data not available.'),
              ),
            ),
          );
        }
        final profile = snapshot.data!;
        final points = profile.points;
        final dailyStreak = profile.streaks[StreakType.dailyClassification.toString()];
        final streakCurrent = dailyStreak?.currentCount ?? 0;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your Gamification Progress',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingRegular),
                  
                  Row(
                    children: [
                      GamificationSummaryCard(
                        title: 'Streak',
                        value: streakCurrent.toString(),
                        unit: 'days',
                        icon: Icons.local_fire_department,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: AppTheme.paddingSmall),
                      GamificationSummaryCard(
                        title: 'Points',
                        value: points.total.toString(),
                        unit: 'Level ${points.level}',
                        icon: Icons.stars,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                
                const SizedBox(height: AppTheme.paddingRegular),
                Container(
                  padding: const EdgeInsets.all(AppTheme.paddingRegular),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                  ),
                    child: Row(
                    children: [
                        Icon(
                          Icons.leaderboard, 
                          color: Colors.blueGrey.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Leaderboard coming soon! Compete with others to see who's the top recycler.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blueGrey.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Revert EmptyStateWidget to its simpler, original form (StatelessWidget)
class EmptyStateWidget extends StatelessWidget { // Optional icon if it had one originally

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.actionButton,
    this.icon,
  });
  final String title;
  final String message;
  final Widget? actionButton; // Kept for basic functionality
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: AppTheme.paddingLarge),
            ],
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor, // Use theme color
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: AppTheme.fontSizeRegular,
                height: 1.4,
              ),
            ),
            if (actionButton != null) ...[
              const SizedBox(height: AppTheme.paddingLarge),
              actionButton!,
            ],
          ],
        ),
      ),
    );
  }
}

class WebChartWidget extends StatefulWidget {
  
  const WebChartWidget({
    super.key,
    required this.data,
    required this.title,
  });
  final List<Map<String, dynamic>> data;
  final String title;

  @override
  State<WebChartWidget> createState() => _WebChartWidgetState();
}

class _WebChartWidgetState extends State<WebChartWidget> {
  late final WebViewController controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
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
    final primaryColorHex = '#${AppTheme.primaryColor.toARGB32().toRadixString(16).substring(2)}';
    
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/chartjs-adapter-date-fns@3.0.0/dist/chartjs-adapter-date-fns.bundle.min.js"></script>
        <style>
          body { 
            margin: 0; 
            padding: 8px; 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: transparent;
          }
          .chart-container { 
            width: 100%; 
            height: 100%; 
            position: relative;
          }
          canvas {
            max-width: 100%;
            height: auto !important;
          }
        </style>
      </head>
      <body>
        <div class="chart-container">
          <canvas id="myChart"></canvas>
        </div>
        
        <script>
          try {
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
                  label: 'Items',
                  data: data,
                  fill: true,
                  borderColor: '$primaryColorHex',
                  backgroundColor: '$primaryColorHex' + '33', // 20% opacity
                  tension: 0.3,
                  pointRadius: 3,
                  pointHoverRadius: 5,
                  pointBackgroundColor: '$primaryColorHex',
                  pointBorderColor: '#ffffff',
                  pointBorderWidth: 2
                }]
              },
              options: {
                responsive: true,
                maintainAspectRatio: false,
                interaction: {
                  intersect: false,
                  mode: 'index',
                },
                plugins: {
                  tooltip: {
                    backgroundColor: 'rgba(0, 0, 0, 0.8)',
                    titleColor: '#ffffff',
                    bodyColor: '#ffffff',
                    borderColor: '$primaryColorHex',
                    borderWidth: 1,
                    cornerRadius: 8,
                    padding: 12,
                    displayColors: false,
                    callbacks: {
                      title: (context) => {
                        return formatDate(context[0].parsed.x);
                      },
                      label: (context) => {
                        const value = context.parsed.y;
                        return value + (value === 1 ? ' item' : ' items');
                      }
                    }
                  },
                  legend: {
                    display: false
                  }
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
                    grid: {
                      color: 'rgba(0,0,0,0.1)'
                    },
                    ticks: {
                      maxTicksLimit: 6
                    }
                  },
                  y: {
                    beginAtZero: true,
                    grid: {
                      color: 'rgba(0,0,0,0.1)'
                    },
                    ticks: {
                      precision: 0,
                      callback: function(value) {
                        return value + (value === 1 ? ' item' : ' items');
                      }
                    }
                  }
                }
              }
            });
          } catch (error) {
            console.error('Chart creation failed:', error);
            document.body.innerHTML = '<div style="text-align: center; padding: 20px; color: #666;">Chart loading failed</div>';
          }
        </script>
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
      if (_hasError) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.25,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Chart failed to load'),
            Text('Please check your internet connection', 
                 style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }
    
    return Stack(
      children: [
        WebViewWidget(controller: controller),
          if (_isLoading)
            Container(
              height: MediaQuery.of(context).size.height * 0.25,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          ),
      ],
    );
  }
}

class WebPieChartWidget extends StatefulWidget {
  
  const WebPieChartWidget({
    super.key,
    required this.data,
  });
  final List<Map<String, dynamic>> data;

  @override
  State<WebPieChartWidget> createState() => _WebPieChartWidgetState();
}

class _WebPieChartWidgetState extends State<WebPieChartWidget> {
  late final WebViewController controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadHtmlString(_generateChartHtml());
  }

  String _generateChartHtml() {
    final jsonData = jsonEncode(widget.data);
    
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.js"></script>
        <style>
          body { 
            margin: 0; 
            padding: 8px; 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: transparent;
          }
          .chart-container { 
            width: 100%; 
            height: 100%; 
            position: relative;
          }
          canvas {
            max-width: 100%;
            height: auto !important;
          }
        </style>
      </head>
      <body>
        <div class="chart-container">
          <canvas id="myChart"></canvas>
        </div>
        
        <script>
          try {
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
                  borderWidth: 2,
                  hoverOffset: 8,
                  hoverBorderWidth: 3
                }]
              },
              options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: '50%',
                plugins: {
                  tooltip: {
                    backgroundColor: 'rgba(0, 0, 0, 0.8)',
                    titleColor: '#ffffff',
                    bodyColor: '#ffffff',
                    borderColor: '#ffffff',
                    borderWidth: 1,
                    cornerRadius: 8,
                    padding: 12,
                    displayColors: true,
                    callbacks: {
                      label: (context) => {
                        const value = context.parsed;
                        const percentage = percentages[context.dataIndex];
                        return ` \${value} items (\${percentage})`;
                      }
                    }
                  },
                  legend: {
                    display: false
                  }
                },
                elements: {
                  arc: {
                    borderJoinStyle: 'round'
                  }
                }
              }
            });
          } catch (error) {
            console.error('Chart creation failed:', error);
            document.body.innerHTML = '<div style="text-align: center; padding: 20px; color: #666;">Chart loading failed</div>';
          }
        </script>
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
      if (_hasError) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.25,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Chart failed to load'),
            Text('Please check your internet connection', 
                 style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }
    
    return Stack(
      children: [
        WebViewWidget(controller: controller),
          if (_isLoading)
            Container(
              height: MediaQuery.of(context).size.height * 0.25,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          ),
      ],
    );
  }
}

// Gamification summary card for individual stats
class GamificationSummaryCard extends StatelessWidget { // e.g., "+12%"

  const GamificationSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.trend,
  });
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final String? trend;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.paddingSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondaryColor.withValues(alpha: 0.8),
                  ),
                ),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: AppTheme.paddingMicro), 
            Text(
              value,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeExtraLarge,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.paddingMicro),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textSecondaryColor.withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (trend != null) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.paddingMicro, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                    child: Text(
                      trend!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
