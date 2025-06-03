import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import '../services/premium_service.dart'; // Unused
// import '../services/storage_service.dart'; // Keep - used for Provider.of<StorageService>
import '../services/enhanced_storage_service.dart'; // Keep - used for Provider.of<EnhancedStorageService>
import '../utils/constants.dart';
import '../utils/design_system.dart';
import '../utils/enhanced_animations.dart';

/// Offline Mode Settings Screen
/// Allows users to configure offline classification settings
class OfflineModeSettingsScreen extends StatefulWidget {
  const OfflineModeSettingsScreen({super.key});

  @override
  State<OfflineModeSettingsScreen> createState() => _OfflineModeSettingsScreenState();
}

class _OfflineModeSettingsScreenState extends State<OfflineModeSettingsScreen> {
  bool _offlineEnabled = false;
  bool _autoDownloadModels = true;
  bool _compressImages = true;
  bool _storageOptimization = true;
  bool _isLoading = true;
  
  // Mock offline model information
  final List<OfflineModel> _offlineModels = [
    OfflineModel(
      name: 'Basic Waste Classification',
      description: 'Core waste categories classification',
      size: '125 MB',
      accuracy: 85.0,
      isDownloaded: true,
      isRequired: true,
    ),
    OfflineModel(
      name: 'Plastic Types Recognition',
      description: 'Detailed plastic identification',
      size: '78 MB',
      accuracy: 78.0,
      isDownloaded: false,
      isRequired: false,
    ),
    OfflineModel(
      name: 'Organic Material Detection',
      description: 'Food waste and compostable items',
      size: '92 MB',  
      accuracy: 82.0,
      isDownloaded: true,
      isRequired: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = Provider.of<EnhancedStorageService>(context, listen: false);
    
    // Load offline settings from storage
    final settings = await storage.get<Map<String, dynamic>>('offline_settings') ?? <String, dynamic>{};
    
    setState(() {
      _offlineEnabled = settings['enabled'] ?? false;
      _autoDownloadModels = settings['auto_download'] ?? true;
      _compressImages = settings['compress_images'] ?? true;
      _storageOptimization = settings['storage_optimization'] ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final storage = Provider.of<EnhancedStorageService>(context, listen: false);
    
    await storage.store('offline_settings', {
      'enabled': _offlineEnabled,
      'auto_download': _autoDownloadModels,
      'compress_images': _compressImages,
      'storage_optimization': _storageOptimization,
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offline settings saved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AnimatedLoadingScreen(
        message: 'Loading offline settings...',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Mode Settings'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: AnimatedCard(
        isVisible: !_isLoading,
        child: ListView(
          padding: const EdgeInsets.all(WasteAppDesignSystem.spacingM),
          children: [
            // Offline mode toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(WasteAppDesignSystem.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.offline_bolt,
                          color: WasteAppDesignSystem.primaryGreen,
                          size: 24,
                        ),
                        SizedBox(width: WasteAppDesignSystem.spacingS),
                        Text(
                          'Enable Offline Mode',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: WasteAppDesignSystem.spacingS),
                    const Text(
                      'Classify waste items without an internet connection. Offline models will be downloaded to your device.',
                      style: TextStyle(color: AppTheme.textPrimaryColor),
                    ),
                    const SizedBox(height: WasteAppDesignSystem.spacingM),
                    SwitchListTile(
                      value: _offlineEnabled,
                      onChanged: (value) {
                        setState(() {
                          _offlineEnabled = value;
                        });
                      },
                      title: const Text('Enable Offline Classification'),
                      subtitle: Text(
                        _offlineEnabled 
                          ? 'Offline mode is enabled'
                          : 'Offline mode is disabled',
                      ),
                      activeColor: WasteAppDesignSystem.primaryGreen,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: WasteAppDesignSystem.spacingL),
            
            // Model management section
            if (_offlineEnabled) ...[
              const Text(
                'Downloaded Models',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: WasteAppDesignSystem.spacingM),
              
              ..._offlineModels.asMap().entries.map((entry) {
                final index = entry.key;
                final model = entry.value;
                return AnimatedCard(
                  index: index,
                  margin: const EdgeInsets.only(bottom: WasteAppDesignSystem.spacingM),
                  child: _buildModelCard(model),
                );
              }),
              
              const SizedBox(height: WasteAppDesignSystem.spacingL),
              
              // Advanced settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(WasteAppDesignSystem.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.settings, color: Colors.grey),
                          SizedBox(width: WasteAppDesignSystem.spacingS),
                          Text(
                            'Advanced Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: WasteAppDesignSystem.spacingM),
                      
                      SwitchListTile(
                        value: _autoDownloadModels,
                        onChanged: (value) {
                          setState(() {
                            _autoDownloadModels = value;
                          });
                        },
                        title: const Text('Auto-download Model Updates'),
                        subtitle: const Text('Automatically download new model versions'),
                        activeColor: WasteAppDesignSystem.primaryGreen,
                      ),
                      
                      SwitchListTile(
                        value: _compressImages,
                        onChanged: (value) {
                          setState(() {
                            _compressImages = value;
                          });
                        },
                        title: const Text('Compress Images'),
                        subtitle: const Text('Reduce image size for faster processing'),
                        activeColor: WasteAppDesignSystem.primaryGreen,
                      ),
                      
                      SwitchListTile(
                        value: _storageOptimization,
                        onChanged: (value) {
                          setState(() {
                            _storageOptimization = value;
                          });
                        },
                        title: const Text('Storage Optimization'),
                        subtitle: const Text('Automatically clean up old cache files'),
                        activeColor: WasteAppDesignSystem.primaryGreen,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: WasteAppDesignSystem.spacingL),
              
              // Storage info
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(WasteAppDesignSystem.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.storage, color: Colors.blue),
                          SizedBox(width: WasteAppDesignSystem.spacingS),
                          Text(
                            'Storage Usage',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: WasteAppDesignSystem.spacingM),
                      _buildStorageInfo(),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModelCard(OfflineModel model) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: model.isDownloaded 
          ? Colors.green.shade100 
          : Colors.grey.shade100,
        child: Icon(
          model.isDownloaded ? Icons.check_circle : Icons.download,
          color: model.isDownloaded ? Colors.green : Colors.grey,
        ),
      ),
      title: Text(
        model.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(model.description),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('${model.size} • ${model.accuracy.toStringAsFixed(0)}% accuracy'),
              if (model.isRequired) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Required',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: model.isDownloaded
        ? (model.isRequired 
            ? const Icon(Icons.lock, color: Colors.grey)
            : IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeModel(model),
              ))
        : IconButton(
            icon: const Icon(Icons.download, color: Colors.blue),
            onPressed: () => _downloadModel(model),
          ),
      isThreeLine: true,
    );
  }

  Widget _buildStorageInfo() {
    final totalSize = _offlineModels
        .where((m) => m.isDownloaded)
        .fold<double>(0, (sum, model) => sum + _parseSize(model.size));
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Models Downloaded:'),
            Text('${_offlineModels.where((m) => m.isDownloaded).length}/${_offlineModels.length}'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Storage Used:'),
            Text('${totalSize.toStringAsFixed(0)} MB'),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: totalSize / 500, // Assume 500MB total capacity
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation(
            totalSize > 400 ? Colors.red : Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Available: ${(500 - totalSize).toStringAsFixed(0)} MB',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  double _parseSize(String sizeStr) {
    final match = RegExp(r'(\d+)').firstMatch(sizeStr);
    return match != null ? double.parse(match.group(1)!) : 0.0;
  }

  Future<void> _downloadModel(OfflineModel model) async {
    // Show download progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Downloading ${model.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Downloading ${model.size}...'),
          ],
        ),
      ),
    );

    // Simulate download
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.pop(context);
      setState(() {
        model.isDownloaded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${model.name} downloaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _removeModel(OfflineModel model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Model'),
        content: Text('Are you sure you want to remove ${model.name}? You can download it again later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        model.isDownloaded = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${model.name} removed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}

class OfflineModel {

  OfflineModel({
    required this.name,
    required this.description,
    required this.size,
    required this.accuracy,
    required this.isDownloaded,
    required this.isRequired,
  });
  final String name;
  final String description;
  final String size;
  final double accuracy;
  bool isDownloaded;
  final bool isRequired;
}
