import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constants.dart';

/// Data model for chart data points
class ChartData {
  
  ChartData(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

/// A pie chart widget for displaying waste category distribution
class WasteCategoryPieChart extends StatelessWidget {
  
  const WasteCategoryPieChart({
    super.key,
    required this.data,
    required this.animationController,
  });
  final List<ChartData> data;
  final AnimationController animationController;
  
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }
    
    // Calculate total for percentages
    final total = data.fold<double>(0, (sum, item) => sum + item.value);
    
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return PieChart(
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
              },
            ),
          ),
        );
      },
    );
  }
}

/// A bar chart widget for displaying subcategories
class TopSubcategoriesBarChart extends StatelessWidget {
  
  const TopSubcategoriesBarChart({
    super.key,
    required this.data,
    required this.animationController,
  });
  final List<ChartData> data;
  final AnimationController animationController;
  
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }
    
    // Sort data by value (descending)
    final sortedData = List<ChartData>.from(data)
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Calculate the maximum value for scaling
    final maxValue = sortedData.map((item) => item.value).reduce((a, b) => a > b ? a : b);
    
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxValue * 1.2,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${sortedData[groupIndex].label}\n',
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
              topTitles: const AxisTitles(sideTitles: SideTitles()),
              rightTitles: const AxisTitles(sideTitles: SideTitles()),
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
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
              topTitles: const AxisTitles(sideTitles: SideTitles()),
              rightTitles: const AxisTitles(sideTitles: SideTitles()),
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
                  color: AppTheme.primaryColor.withOpacity(0.2),
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
              topTitles: const AxisTitles(sideTitles: SideTitles()),
              rightTitles: const AxisTitles(sideTitles: SideTitles()),
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
            color: color.withOpacity(0.7),
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

/// A bar chart widget for displaying weekly items
class WeeklyItemsChart extends StatelessWidget {
  
  const WeeklyItemsChart({
    super.key,
    required this.data,
    required this.animationController,
  });
  final List<ChartData> data;
  final AnimationController animationController;
  
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }
    
    // Calculate the maximum value for scaling
    final maxValue = data.map((item) => item.value).reduce((a, b) => a > b ? a : b);
    
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxValue * 1.2,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${data[groupIndex].label}\n',
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
                    
                    final label = data[value.toInt()].label;
                    
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 9,
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
              topTitles: const AxisTitles(sideTitles: SideTitles()),
              rightTitles: const AxisTitles(sideTitles: SideTitles()),
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
                    width: 12,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
