import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constants.dart';

/// Data model for chart data points
class ChartData {
  
  ChartData(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

/// A pie chart widget for displaying waste category distribution with accessibility support
class WasteCategoryPieChart extends StatelessWidget {
  
  const WasteCategoryPieChart({
    super.key,
    required this.data,
    required this.animationController,
    this.semanticsLabel,
  });
  final List<ChartData> data;
  final AnimationController animationController;
  final String? semanticsLabel;
  
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Semantics(
        label: 'No waste category data available',
        child: const Center(
          child: Text('No data available'),
        ),
      );
    }
    
    // Calculate total for percentages
    final total = data.fold<double>(0, (sum, item) => sum + item.value);
    
    // Create accessible description
    final accessibleDescription = _createAccessibleDescription(data, total);
    
    return Semantics(
      label: semanticsLabel ?? 'Waste category distribution pie chart',
      value: accessibleDescription,
      hint: 'Double tap to hear detailed breakdown',
      onTap: () => _announceDetailedBreakdown(context, data, total),
      child: MergeSemantics(
        child: Column(
          children: [
            // Visual chart
            Expanded(
              child: AnimatedBuilder(
                animation: animationController,
                builder: (context, child) {
                  return ExcludeSemantics(
                    child: PieChart(
                      PieChartData(
                        sections: data.map((item) {
                          final percentage = (item.value / total) * 100;
                          return PieChartSectionData(
                            color: item.color,
                            value: item.value,
                            title: '${percentage.toStringAsFixed(1)}%',
                            radius: 80 * animationController.value,
                            titleStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              return;
                            }
                            
                            // Announce touched section for accessibility
                            final sectionIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            if (sectionIndex >= 0 && sectionIndex < data.length) {
                              final item = data[sectionIndex];
                              final percentage = (item.value / total) * 100;
                              SemanticsService.announce(
                                '${item.label}: ${item.value.toInt()} items, ${percentage.toStringAsFixed(1)} percent',
                                TextDirection.ltr,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Accessible legend
            const SizedBox(height: 16),
            _buildAccessibleLegend(data, total),
          ],
        ),
      ),
    );
  }
  
  String _createAccessibleDescription(List<ChartData> data, double total) {
    final sortedData = List<ChartData>.from(data)
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final descriptions = sortedData.map((item) {
      final percentage = (item.value / total) * 100;
      return '${item.label}: ${item.value.toInt()} items (${percentage.toStringAsFixed(1)}%)';
    }).toList();
    
    return 'Chart showing ${descriptions.join(', ')}';
  }
  
  void _announceDetailedBreakdown(BuildContext context, List<ChartData> data, double total) {
    final sortedData = List<ChartData>.from(data)
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final announcement = sortedData.map((item) {
      final percentage = (item.value / total) * 100;
      return '${item.label}: ${item.value.toInt()} items, ${percentage.toStringAsFixed(1)} percent';
    }).join('. ');
    
    SemanticsService.announce(
      'Detailed breakdown: $announcement',
      TextDirection.ltr,
    );
  }
  
  Widget _buildAccessibleLegend(List<ChartData> data, double total) {
    return Semantics(
      label: 'Chart legend',
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: data.map((item) {
          final percentage = (item.value / total) * 100;
          return Semantics(
            label: '${item.label}: ${item.value.toInt()} items, ${percentage.toStringAsFixed(1)} percent',
            child: Chip(
              avatar: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              label: Text(
                '${item.label} (${percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(fontSize: 12),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A bar chart widget for displaying subcategories with accessibility support
class TopSubcategoriesBarChart extends StatelessWidget {
  
  const TopSubcategoriesBarChart({
    super.key,
    required this.data,
    required this.animationController,
    this.semanticsLabel,
  });
  final List<ChartData> data;
  final AnimationController animationController;
  final String? semanticsLabel;
  
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Semantics(
        label: 'No subcategory data available',
        child: const Center(
          child: Text('No data available'),
        ),
      );
    }
    
    // Sort data by value (descending)
    final sortedData = List<ChartData>.from(data)
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Calculate the maximum value for scaling
    final maxValue = sortedData.map((item) => item.value).reduce((a, b) => a > b ? a : b);
    
    // Create accessible description
    final accessibleDescription = _createAccessibleDescription(sortedData);
    
    return Semantics(
      label: semanticsLabel ?? 'Top subcategories bar chart',
      value: accessibleDescription,
      hint: 'Double tap to hear detailed breakdown',
      onTap: () => _announceDetailedBreakdown(context, sortedData),
      child: MergeSemantics(
        child: Column(
          children: [
            // Visual chart
            Expanded(
              child: AnimatedBuilder(
                animation: animationController,
                builder: (context, child) {
                  return ExcludeSemantics(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxValue * 1.2,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              if (groupIndex >= sortedData.length) return null;
                              
                              final item = sortedData[groupIndex];
                              // Announce touched bar for accessibility
                              SemanticsService.announce(
                                '${item.label}: ${rod.toY.toInt()} items',
                                TextDirection.ltr,
                              );
                              
                              return BarTooltipItem(
                                '${item.label}\n',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: rod.toY.toInt().toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value >= sortedData.length || value < 0) {
                                  return const SizedBox.shrink();
                                }
                                
                                final label = sortedData[value.toInt()].label;
                                // Truncate long labels
                                final displayLabel = label.length > 10 
                                    ? '${label.substring(0, 7)}...' 
                                    : label;
                                    
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    displayLabel,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) {
                                  return const SizedBox.shrink();
                                }
                                
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                        ),
                        gridData: FlGridData(
                          horizontalInterval: maxValue / 5,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                            );
                          },
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        barGroups: List.generate(
                          sortedData.length,
                          (index) => BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: sortedData[index].value * animationController.value,
                                color: sortedData[index].color,
                                width: 20,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Accessible data table
            const SizedBox(height: 16),
            _buildAccessibleDataTable(sortedData),
          ],
        ),
      ),
    );
  }
  
  String _createAccessibleDescription(List<ChartData> sortedData) {
    final topItems = sortedData.take(3).map((item) => 
      '${item.label}: ${item.value.toInt()} items'
    ).toList();
    
    return 'Bar chart showing top subcategories: ${topItems.join(', ')}';
  }
  
  void _announceDetailedBreakdown(BuildContext context, List<ChartData> sortedData) {
    final announcement = sortedData.map((item) => 
      '${item.label}: ${item.value.toInt()} items'
    ).join('. ');
    
    SemanticsService.announce(
      'Detailed breakdown: $announcement',
      TextDirection.ltr,
    );
  }
  
  Widget _buildAccessibleDataTable(List<ChartData> sortedData) {
    return Semantics(
      label: 'Data table for subcategories',
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Subcategory',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Count',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            
            // Data rows
            ...sortedData.map((item) => Semantics(
              label: '${item.label}: ${item.value.toInt()} items',
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(item.label),
                    ),
                    Expanded(
                      child: Text(
                        item.value.toInt().toString(),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

/// Weekly items chart with accessibility support
class WeeklyItemsChart extends StatelessWidget {
  
  const WeeklyItemsChart({
    super.key,
    required this.data,
    required this.animationController,
    this.semanticsLabel,
  });
  final List<ChartData> data;
  final AnimationController animationController;
  final String? semanticsLabel;
  
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Semantics(
        label: 'No weekly data available',
        child: const Center(
          child: Text('No data available'),
        ),
      );
    }
    
    // Calculate the maximum value for scaling
    final maxValue = data.map((item) => item.value).reduce((a, b) => a > b ? a : b);
    
    // Create accessible description
    final accessibleDescription = _createAccessibleDescription(data);
    
    return Semantics(
      label: semanticsLabel ?? 'Weekly items chart',
      value: accessibleDescription,
      hint: 'Double tap to hear detailed breakdown',
      onTap: () => _announceDetailedBreakdown(context, data),
      child: MergeSemantics(
        child: Column(
          children: [
            // Visual chart
            Expanded(
              child: AnimatedBuilder(
                animation: animationController,
                builder: (context, child) {
                  return ExcludeSemantics(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxValue * 1.2,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              if (groupIndex >= data.length) return null;
                              
                              final item = data[groupIndex];
                              // Announce touched bar for accessibility
                              SemanticsService.announce(
                                '${item.label}: ${rod.toY.toInt()} items',
                                TextDirection.ltr,
                              );
                              
                              return BarTooltipItem(
                                '${item.label}\n',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: '${rod.toY.toInt()} items',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value >= data.length || value < 0) {
                                  return const SizedBox.shrink();
                                }
                                
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    data[value.toInt()].label,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) {
                                  return const SizedBox.shrink();
                                }
                                
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                        ),
                        gridData: FlGridData(
                          horizontalInterval: maxValue / 5,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                            );
                          },
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        barGroups: List.generate(
                          data.length,
                          (index) => BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: data[index].value * animationController.value,
                                color: data[index].color,
                                width: 20,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Accessible summary
            const SizedBox(height: 16),
            _buildAccessibleSummary(data),
          ],
        ),
      ),
    );
  }
  
  String _createAccessibleDescription(List<ChartData> data) {
    final totalItems = data.fold<double>(0, (sum, item) => sum + item.value);
    final topDay = data.reduce((a, b) => a.value > b.value ? a : b);
    
    return 'Weekly chart showing ${totalItems.toInt()} total items. Highest day: ${topDay.label} with ${topDay.value.toInt()} items';
  }
  
  void _announceDetailedBreakdown(BuildContext context, List<ChartData> data) {
    final announcement = data.map((item) => 
      '${item.label}: ${item.value.toInt()} items'
    ).join('. ');
    
    SemanticsService.announce(
      'Weekly breakdown: $announcement',
      TextDirection.ltr,
    );
  }
  
  Widget _buildAccessibleSummary(List<ChartData> data) {
    final totalItems = data.fold<double>(0, (sum, item) => sum + item.value);
    final averageItems = totalItems / data.length;
    
    return Semantics(
      label: 'Weekly summary',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Summary',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Total items: ${totalItems.toInt()}'),
            Text('Average per day: ${averageItems.toStringAsFixed(1)}'),
          ],
        ),
      ),
    );
  }
}

/// A line chart widget for displaying waste generation over time
class WasteTimeSeriesChart extends StatelessWidget {
  
  const WasteTimeSeriesChart({
    super.key,
    required this.data,
    required this.animationController,
  });
  final List<Map<String, dynamic>> data;
  final AnimationController animationController;
  
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }
    
    // Calculate the maximum value for scaling
    final maxValue = data.map((item) => item['count'] as int).reduce((a, b) => a > b ? a : b).toDouble();
    
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return LineChart(
          LineChartData(
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipPadding: const EdgeInsets.all(8),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((touchedSpot) {
                    final itemIndex = touchedSpots.indexOf(touchedSpot);
                    if (itemIndex >= 0 && itemIndex < data.length) {
                      final item = data[itemIndex];
                      return LineTooltipItem(
                        '${item['formattedDate']}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: 'Items: ${item['count']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      );
                    } else {
                      return const LineTooltipItem(
                        '',
                        TextStyle(),
                      );
                    }
                  }).toList();
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: data.length > 5 ? (data.length / 5).ceil().toDouble() : 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= data.length) {
                      return const SizedBox.shrink();
                    }
                    
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        data[index]['formattedDate'] as String,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
            ),
            gridData: FlGridData(
              horizontalInterval: maxValue > 5 ? maxValue / 5 : 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.shade300,
                  strokeWidth: 1,
                );
              },
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(
              show: false,
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  data.length,
                  (index) => FlSpot(
                    index.toDouble(), 
                    (data[index]['count'] as int).toDouble() * animationController.value,
                  ),
                ),
                isCurved: true,
                color: AppTheme.primaryColor,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: AppTheme.primaryColor,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.primaryColor.withValues(alpha:0.2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A stacked area chart for displaying category distribution over time
class CategoryDistributionChart extends StatelessWidget {
  
  const CategoryDistributionChart({
    super.key,
    required this.data,
    required this.animationController,
  });
  final List<Map<String, dynamic>> data;
  final AnimationController animationController;
  
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }
    
    // Get all category keys excluding 'month'
    final categories = data.first.keys.where((key) => key != 'month').toList();
    
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return LineChart(
          LineChartData(
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipPadding: const EdgeInsets.all(8),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final lineIndex = touchedSpots.indexOf(spot);
                    final itemIndex = spot.x.toInt();
                    
                    if (itemIndex >= 0 && itemIndex < data.length && lineIndex < categories.length) {
                      final category = categories[lineIndex];
                      final month = data[itemIndex]['month'] as String;
                      final value = data[itemIndex][category] as double;
                      
                      return LineTooltipItem(
                        '$category\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: '$month: ${(value * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      );
                    } else {
                      return const LineTooltipItem('', TextStyle());
                    }
                  }).toList();
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= data.length) {
                      return const SizedBox.shrink();
                    }
                    
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        data[index]['month'] as String,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 0.2,
                  getTitlesWidget: (value, meta) {
                    // Show as percentage
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        '${(value * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 9,
                        ),
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
            ),
            gridData: FlGridData(
              horizontalInterval: 0.2,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.shade300,
                  strokeWidth: 1,
                );
              },
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(
              show: false,
            ),
            // Create a line for each category
            lineBarsData: _createStackedAreaData(categories),
          ),
        );
      },
    );
  }
  
  List<LineChartBarData> _createStackedAreaData(List<String> categories) {
    final result = <LineChartBarData>[];
    
    // Track cumulative values for stacking
    final cumulativeValues = <int, double>{};
    
    // Get colors for categories
    final categoryColors = <String, Color>{
      'Wet Waste': AppTheme.wetWasteColor,
      'Dry Waste': AppTheme.dryWasteColor,
      'Hazardous Waste': AppTheme.hazardousWasteColor,
      'Medical Waste': AppTheme.medicalWasteColor,
      'Non-Waste': AppTheme.nonWasteColor,
    };
    
    // Create a line for each category
    for (var i = 0; i < categories.length; i++) {
      final category = categories[i];
      final color = categoryColors[category] ?? Colors.grey;
      
      final spots = <FlSpot>[];
      
      for (var j = 0; j < data.length; j++) {
        final value = data[j][category] as double;
        // Get previous cumulative value or 0
        final prevCumulative = cumulativeValues[j] ?? 0.0;
        
        // Current value is previous cumulative plus this value
        final currentValue = prevCumulative + value;
        
        // Save current cumulative value for next category
        cumulativeValues[j] = currentValue;
        
        // Add spot with stacked value
        spots.add(FlSpot(j.toDouble(), currentValue * animationController.value));
      }
      
      result.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 0,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: color.withValues(alpha:0.7),
            // For area below, we need the previous category's value
            cutOffY: i > 0 
                ? (result[i - 1].spots.isNotEmpty ? result[i - 1].spots.last.y : 0.0)
                : 0.0,
            applyCutOffY: true,
          ),
        ),
      );
    }
    
    return result;
  }
}


