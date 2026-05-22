import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/models/vision_model_config.dart';
import 'package:waste_segregation_app/services/enhanced_storage_service.dart';
import 'package:waste_segregation_app/services/model_download_service.dart';
import 'package:waste_segregation_app/utils/constants.dart';
import 'package:waste_segregation_app/utils/design_system.dart';
import 'package:waste_segregation_app/utils/enhanced_animations.dart';

class OfflineModeSettingsScreen extends StatefulWidget {
  const OfflineModeSettingsScreen({super.key});

  @override
  State<OfflineModeSettingsScreen> createState() =>
      _OfflineModeSettingsScreenState();
}

class _OfflineModeSettingsScreenState extends State<OfflineModeSettingsScreen> {
  bool _offlineEnabled = false;
  bool _autoDownloadModels = true;
  bool _compressImages = true;
  bool _storageOptimization = true;
  bool _isLoading = true;

  final ModelDownloadService _downloadService = ModelDownloadService();
  Map<VisionModelType, ModelStatus> _modelStatus = {};
  int _totalDownloadedSize = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSettings(),
      _loadModelStatus(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSettings() async {
    final storage = Provider.of<EnhancedStorageService>(context, listen: false);
    final settings =
        await storage.get<Map<String, dynamic>>('offline_settings') ??
            <String, dynamic>{};
    if (!mounted) return;
    setState(() {
      _offlineEnabled = settings['enabled'] ?? false;
      _autoDownloadModels = settings['auto_download'] ?? true;
      _compressImages = settings['compress_images'] ?? true;
      _storageOptimization = settings['storage_optimization'] ?? true;
    });
  }

  Future<void> _loadModelStatus() async {
    final status = await _downloadService.getAllModelStatus();
    final totalSize = await _downloadService.getTotalDownloadedSize();
    if (!mounted) return;
    setState(() {
      _modelStatus = status;
      _totalDownloadedSize = totalSize;
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

  String _modelDisplayName(VisionModelType type) {
    switch (type) {
      case VisionModelType.smolVLM:
        return 'SmolVLM Vision-Language Model';
      case VisionModelType.mobileNetV3:
        return 'MobileNetV3 Classifier';
      case VisionModelType.efficientNet:
        return 'EfficientNet Classifier';
      case VisionModelType.yoloV8:
        return 'YOLOv8 Detector';
      case VisionModelType.yoloV11:
        return 'YOLOv11 Detector';
      default:
        return type.name;
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
                        if (!mounted) return;
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
            if (_offlineEnabled) ...[
              const Text(
                'Downloaded Models',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: WasteAppDesignSystem.spacingM),
              ...ModelDownloadService.modelMetadata.entries
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) {
                final index = entry.key;
                final modelEntry = entry.value;
                final modelType = modelEntry.key;
                final metadata = modelEntry.value;
                final status = _modelStatus[modelType];
                final isDownloaded = status?.isDownloaded ?? false;
                return AnimatedCard(
                  index: index,
                  margin: const EdgeInsets.only(
                      bottom: WasteAppDesignSystem.spacingM),
                  child: _buildModelCard(modelType, metadata, isDownloaded),
                );
              }),
              const SizedBox(height: WasteAppDesignSystem.spacingL),
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
                          if (!mounted) return;
                          setState(() {
                            _autoDownloadModels = value;
                          });
                        },
                        title: const Text('Auto-download Model Updates'),
                        subtitle: const Text(
                            'Automatically download new model versions'),
                        activeColor: WasteAppDesignSystem.primaryGreen,
                      ),
                      SwitchListTile(
                        value: _compressImages,
                        onChanged: (value) {
                          if (!mounted) return;
                          setState(() {
                            _compressImages = value;
                          });
                        },
                        title: const Text('Compress Images'),
                        subtitle: const Text(
                            'Reduce image size for faster processing'),
                        activeColor: WasteAppDesignSystem.primaryGreen,
                      ),
                      SwitchListTile(
                        value: _storageOptimization,
                        onChanged: (value) {
                          if (!mounted) return;
                          setState(() {
                            _storageOptimization = value;
                          });
                        },
                        title: const Text('Storage Optimization'),
                        subtitle: const Text(
                            'Automatically clean up old cache files'),
                        activeColor: WasteAppDesignSystem.primaryGreen,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: WasteAppDesignSystem.spacingL),
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

  Widget _buildModelCard(
      VisionModelType modelType, ModelMetadata metadata, bool isDownloaded) {
    final displayName = _modelDisplayName(modelType);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isDownloaded ? Colors.green.shade100 : Colors.grey.shade100,
        child: Icon(
          isDownloaded ? Icons.check_circle : Icons.download,
          color: isDownloaded ? Colors.green : Colors.grey,
        ),
      ),
      title: Text(
        displayName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metadata.description),
          const SizedBox(height: 4),
          Text(metadata.sizeString),
        ],
      ),
      trailing: isDownloaded
          ? IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _removeModel(modelType),
            )
          : IconButton(
              icon: const Icon(Icons.download, color: Colors.blue),
              onPressed: () => _downloadModel(modelType),
            ),
      isThreeLine: true,
    );
  }

  Widget _buildStorageInfo() {
    final downloadedCount =
        _modelStatus.values.where((s) => s.isDownloaded).length;
    final totalCount = _modelStatus.length;
    final sizeMb = _totalDownloadedSize / (1024 * 1024);
    const double capacityMb = 500;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Models Downloaded:'),
            Text('$downloadedCount/$totalCount'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Storage Used:'),
            Text('${sizeMb.toStringAsFixed(1)} MB'),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: capacityMb > 0 ? sizeMb / capacityMb : 0,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation(
            sizeMb > 400 ? Colors.red : Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Available: ${(capacityMb - sizeMb).toStringAsFixed(1)} MB',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _downloadModel(VisionModelType modelType) async {
    final displayName = _modelDisplayName(modelType);

    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DownloadProgressDialog(
        downloadService: _downloadService,
        modelType: modelType,
        displayName: displayName,
      ),
    );

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await _loadModelStatus();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success == true
              ? '$displayName downloaded successfully'
              : 'Failed to download $displayName',
        ),
        backgroundColor: success == true ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _removeModel(VisionModelType modelType) async {
    final displayName = _modelDisplayName(modelType);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Model'),
        content: Text(
            'Are you sure you want to remove $displayName? You can download it again later.'),
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

    if (confirmed != true) return;

    try {
      await _downloadService.deleteModel(modelType);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove $displayName'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await _loadModelStatus();
    messenger.showSnackBar(
      SnackBar(
        content: Text('$displayName removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

class _DownloadProgressDialog extends StatefulWidget {
  const _DownloadProgressDialog({
    required this.downloadService,
    required this.modelType,
    required this.displayName,
  });

  final ModelDownloadService downloadService;
  final VisionModelType modelType;
  final String displayName;

  @override
  State<_DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double? _progress;
  String _status = 'Preparing...';
  String? _error;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      await widget.downloadService.downloadModel(
        widget.modelType,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
        onStatusChange: (s) {
          if (mounted) setState(() => _status = s);
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return AlertDialog(
        title: const Text('Download Failed'),
        content: Text(_error!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text('Downloading ${widget.displayName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(value: _progress),
          const SizedBox(height: 16),
          Text(_status),
        ],
      ),
    );
  }
}
