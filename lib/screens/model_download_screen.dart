import 'package:flutter/material.dart';
import '../services/model_download_service.dart';
import '../models/vision_model_config.dart';

/// UI for managing model downloads
///
/// Features:
/// - View available models
/// - Download models with progress
/// - Manage storage
/// - Delete models
class ModelDownloadScreen extends StatefulWidget {
  const ModelDownloadScreen({
    required this.downloadService,
    super.key,
  });

  final ModelDownloadService downloadService;

  @override
  State<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen> {
  Map<VisionModelType, ModelStatus>? _modelStatus;
  final Map<VisionModelType, double> _downloadProgress = {};
  final Map<VisionModelType, String> _downloadStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModelStatus();
  }

  Future<void> _loadModelStatus() async {
    setState(() => _isLoading = true);

    try {
      final status = await widget.downloadService.getAllModelStatus();
      setState(() {
        _modelStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading models: $e')),
        );
      }
    }
  }

  Future<void> _downloadModel(VisionModelType modelType) async {
    setState(() {
      _downloadProgress[modelType] = 0.0;
      _downloadStatus[modelType] = 'Starting...';
    });

    try {
      await widget.downloadService.downloadModel(
        modelType,
        onProgress: (progress) {
          setState(() {
            _downloadProgress[modelType] = progress;
          });
        },
        onStatusChange: (status) {
          setState(() {
            _downloadStatus[modelType] = status;
          });
        },
      );

      // Refresh status
      await _loadModelStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Model downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _downloadProgress.remove(modelType);
        _downloadStatus.remove(modelType);
      });
    }
  }

  Future<void> _deleteModel(VisionModelType modelType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: const Text('Are you sure you want to delete this model?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.downloadService.deleteModel(modelType);
      await _loadModelStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Downloads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadModelStatus,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildModelList(),
    );
  }

  Widget _buildModelList() {
    if (_modelStatus == null || _modelStatus!.isEmpty) {
      return const Center(
        child: Text('No models available'),
      );
    }

    return Column(
      children: [
        _buildStorageInfo(),
        Expanded(
          child: ListView.builder(
            itemCount: _modelStatus!.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final entry = _modelStatus!.entries.elementAt(index);
              return _buildModelCard(entry.key, entry.value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStorageInfo() {
    return FutureBuilder<int>(
      future: widget.downloadService.getTotalDownloadedSize(),
      builder: (context, snapshot) {
        final totalSize = snapshot.data ?? 0;
        final sizeMB = (totalSize / (1024 * 1024)).toStringAsFixed(1);

        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              const Icon(Icons.storage, color: Colors.blue),
              const SizedBox(width: 8),
              Text('Storage used: $sizeMB MB'),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Show storage details
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Storage Details'),
                      content: Text(
                        'Total models downloaded: ${_modelStatus?.values.where((s) => s.isDownloaded).length ?? 0}\n'
                        'Total size: $sizeMB MB',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Details'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelCard(VisionModelType modelType, ModelStatus status) {
    final isDownloading = _downloadProgress.containsKey(modelType);
    final progress = _downloadProgress[modelType] ?? 0.0;
    final downloadStatusText = _downloadStatus[modelType] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildModelIcon(modelType),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getModelDisplayName(modelType),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status.metadata.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(Icons.file_download, status.metadata.sizeString),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.speed, _getModelSpeed(modelType)),
                const Spacer(),
                if (status.isDownloaded)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20)
                else
                  const Icon(Icons.cloud_download,
                      color: Colors.grey, size: 20),
              ],
            ),
            if (isDownloading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 4),
              Text(
                downloadStatusText,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status.isDownloaded && !isDownloading)
                  TextButton.icon(
                    onPressed: () => _deleteModel(modelType),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                  ),
                if (!status.isDownloaded && !isDownloading)
                  ElevatedButton.icon(
                    onPressed: () => _downloadModel(modelType),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelIcon(VisionModelType modelType) {
    IconData icon;
    Color color;

    switch (modelType) {
      case VisionModelType.yoloV8:
      case VisionModelType.yoloV11:
        icon = Icons.camera_alt;
        color = Colors.purple;
        break;
      case VisionModelType.smolVLM:
        icon = Icons.psychology;
        color = Colors.blue;
        break;
      case VisionModelType.mobileNetV3:
        icon = Icons.speed;
        color = Colors.green;
        break;
      case VisionModelType.efficientNet:
        icon = Icons.balance;
        color = Colors.orange;
        break;
      default:
        icon = Icons.model_training;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  String _getModelDisplayName(VisionModelType modelType) {
    switch (modelType) {
      case VisionModelType.smolVLM:
        return 'SmolVLM';
      case VisionModelType.mobileNetV3:
        return 'MobileNetV3';
      case VisionModelType.efficientNet:
        return 'EfficientNet';
      case VisionModelType.yoloV8:
        return 'YOLOv8';
      case VisionModelType.yoloV11:
        return 'YOLOv11';
      default:
        return modelType.name;
    }
  }

  String _getModelSpeed(VisionModelType modelType) {
    switch (modelType) {
      case VisionModelType.mobileNetV3:
        return '~50ms';
      case VisionModelType.efficientNet:
        return '~80ms';
      case VisionModelType.yoloV8:
        return '~100ms';
      case VisionModelType.smolVLM:
        return '~100ms';
      case VisionModelType.yoloV11:
        return '~120ms';
      default:
        return 'N/A';
    }
  }
}
