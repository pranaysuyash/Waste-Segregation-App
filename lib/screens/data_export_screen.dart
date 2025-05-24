import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart'; // Added for DateFormat
// import 'package:path_provider/path_provider.dart'; // Unused
import '../services/storage_service.dart';
import '../services/google_drive_service.dart';
import '../models/waste_classification.dart';
import '../utils/share_service.dart'; // Added for ShareService
import '../utils/constants.dart';
import '../utils/app_version.dart'; // For AppVersion.displayVersion
// import '../utils/design_system.dart'; // Unused
// import '../utils/enhanced_animations.dart'; // Unused
// import '../utils/performance_monitor.dart'; // Unused
import '../widgets/advanced_ui/glass_morphism.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Keep kIsWeb

/// Data Export Screen
/// Allows users to export their classification history in various formats
class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  bool _isLoading = true;
  bool _isExporting = false;
  List<WasteClassification> _classifications = [];
  
  // Export options
  ExportFormat _selectedFormat = ExportFormat.csv;
  DateRange _selectedDateRange = DateRange.all;
  bool _includeImages = false;
  bool _includePersonalData = true;
  bool _includeAnalytics = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final classifications = await storage.getAllClassifications();
    
    setState(() {
      _classifications = classifications;
      _isLoading = false;
    });
  }

  List<WasteClassification> _getFilteredClassifications() {
    List<WasteClassification> filtered = List.from(_classifications);
    
    final now = DateTime.now();
    DateTime? cutoffDate;
    
    switch (_selectedDateRange) {
      case DateRange.lastWeek:
        cutoffDate = now.subtract(const Duration(days: 7));
        break;
      case DateRange.lastMonth:
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      case DateRange.lastYear:
        cutoffDate = now.subtract(const Duration(days: 365));
        break;
      case DateRange.all:
        cutoffDate = null;
        break;
    }
    
    if (cutoffDate != null) {
      filtered = filtered.where((c) => c.timestamp.isAfter(cutoffDate!)).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        actions: [
          if (!_isExporting)
            TextButton(
              onPressed: _classifications.isEmpty ? null : _exportData,
              child: const Text('Export', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isExporting 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Exporting your data...'),
              ],
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Export format selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Export Format', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ...ExportFormat.values.map((format) => RadioListTile<ExportFormat>(
                        title: Text(format.displayName),
                        subtitle: Text(format.description),
                        value: format,
                        groupValue: _selectedFormat,
                        onChanged: (value) {
                          setState(() {
                            _selectedFormat = value!;
                          });
                        },
                      )).toList(),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Date range selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date Range', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<DateRange>(
                        value: _selectedDateRange,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Select date range',
                        ),
                        items: DateRange.values.map((range) => DropdownMenuItem(
                          value: range,
                          child: Text(range.displayName),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDateRange = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Export options
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Export Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      CheckboxListTile(
                        title: const Text('Include Personal Data'),
                        subtitle: const Text('Timestamps, device info'),
                        value: _includePersonalData,
                        onChanged: (value) {
                          setState(() {
                            _includePersonalData = value ?? true;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Include Analytics'),
                        subtitle: const Text('Confidence scores and processing details'),
                        value: _includeAnalytics,
                        onChanged: (value) {
                          setState(() {
                            _includeAnalytics = value ?? true;
                          });
                        },
                      ),
                      if (!kIsWeb)
                        CheckboxListTile(
                          title: const Text('Include Image References'),
                          subtitle: const Text('File paths to images'),
                          value: _includeImages,
                          onChanged: (value) {
                            setState(() {
                              _includeImages = value ?? false;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Export Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Total classifications: ${_classifications.length}'),
                      Text('Items to export: ${_getFilteredClassifications().length}'),
                      Text('Format: ${_selectedFormat.displayName}'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Export button
              ElevatedButton.icon(
                onPressed: _classifications.isEmpty ? null : _exportData,
                icon: const Icon(Icons.file_download),
                label: Text('Export ${_getFilteredClassifications().length} Items'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final filteredData = _getFilteredClassifications();
      final exportContent = _generateExportContent(filteredData);
      
      // Share the export content
      await ShareService.share(
        text: exportContent,
        context: context,
        subject: 'Waste Classification Export',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  String _generateExportContent(List<WasteClassification> data) {
    switch (_selectedFormat) {
      case ExportFormat.csv:
        return _generateCSV(data);
      case ExportFormat.json:
        return _generateJSON(data);
      case ExportFormat.txt:
        return _generateTXT(data);
    }
  }

  String _generateCSV(List<WasteClassification> data) {
    final buffer = StringBuffer();
    
    // Headers
    final headers = <String>['Item Name', 'Category', 'Timestamp'];
    if (_includeAnalytics) {
      headers.addAll(['Confidence', 'Subcategory', 'Material Type', 'Model Version']);
    }
    if (_includePersonalData) headers.add('Device');
    if (_includeImages && !kIsWeb) headers.add('Image Path');
    
    buffer.writeln(headers.join(','));
    
    // Data rows
    for (final item in data) {
      final row = <String>[
        '"${item.itemName}"',
        '"${item.category}"',
        '"${DateFormat('yyyy-MM-dd HH:mm:ss').format(item.timestamp)}"',
      ];
      
      if (_includeAnalytics) {
        row.addAll([
          '"${item.confidence != null ? (item.confidence! * 100).toStringAsFixed(1) : 'N/A'}%"',
          '"${item.subcategory ?? 'N/A'}"',
          '"${item.materialType ?? 'N/A'}"',
          '"${item.modelVersion ?? 'N/A'}"',
        ]);
      }
      if (_includePersonalData) {
        row.add('"Mobile Device"');
      }
      if (_includeImages && !kIsWeb) {
        row.add('"${item.imageUrl ?? ''}"');
      }
      
      buffer.writeln(row.join(','));
    }
    
    return buffer.toString();
  }

  String _generateJSON(List<WasteClassification> data) {
    final exportData = {
      'metadata': {
        'exportDate': DateTime.now().toIso8601String(),
        'totalItems': data.length,
        'format': _selectedFormat.name,
        'appVersion': AppVersion.displayVersion,
      },
      'classifications': data.map((item) => {
        'itemName': item.itemName,
        'category': item.category,
        'timestamp': item.timestamp.toIso8601String(),
        'explanation': item.explanation,
        if (_includeAnalytics) ...{
          'confidence': item.confidence,
          'modelVersion': item.modelVersion,
          'processingTimeMs': item.processingTimeMs,
          'subcategory': item.subcategory,
          'materialType': item.materialType,
          'isRecyclable': item.isRecyclable,
          'isCompostable': item.isCompostable,
          'requiresSpecialDisposal': item.requiresSpecialDisposal,
          'recyclingCode': item.recyclingCode,
          'disposalMethod': item.disposalMethod,
          'source': item.source,
        },
        if (_includePersonalData) 'deviceType': 'Mobile Device',
        if (_includeImages && !kIsWeb) 'imagePath': item.imageUrl,
      }).toList(),
    };
    
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(exportData);
  }

  String _generateTXT(List<WasteClassification> data) {
    final buffer = StringBuffer();
    buffer.writeln('Waste Classification Export Report');
    buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buffer.writeln('Total Items: ${data.length}');
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      buffer.writeln('Classification ${i + 1}:');
      buffer.writeln('  Item: ${item.itemName}');
      buffer.writeln('  Category: ${item.category}');
      if (item.subcategory != null) {
        buffer.writeln('  Subcategory: ${item.subcategory}');
      }
      buffer.writeln('  Date: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(item.timestamp)}');
      
      if (_includeAnalytics) {
        if (item.materialType != null) {
          buffer.writeln('  Material: ${item.materialType}');
        }
        if (item.isRecyclable != null) {
          buffer.writeln('  Recyclable: ${item.isRecyclable! ? 'Yes' : 'No'}');
        }
        if (item.isCompostable != null) {
          buffer.writeln('  Compostable: ${item.isCompostable! ? 'Yes' : 'No'}');
        }
        if (item.recyclingCode != null) {
          buffer.writeln('  Recycling Code: ${item.recyclingCode}');
        }
      }
      
      if (item.explanation.isNotEmpty) {
        buffer.writeln('  Explanation: ${item.explanation}');
      }
      
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}

enum ExportFormat {
  csv('CSV', 'Comma-separated values for spreadsheets', 'csv'),
  json('JSON', 'Structured data format', 'json'),
  txt('Text', 'Human-readable text format', 'txt');

  const ExportFormat(this.displayName, this.description, this.extension);
  
  final String displayName;
  final String description;
  final String extension;
}

enum DateRange {
  all('All Time'),
  lastWeek('Last 7 Days'),
  lastMonth('Last 30 Days'),
  lastYear('Last Year');

  const DateRange(this.displayName);
  
  final String displayName;
}
