import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/training_data_service.dart';

class TrainingReviewQueueScreen extends StatefulWidget {
  const TrainingReviewQueueScreen({super.key});

  @override
  State<TrainingReviewQueueScreen> createState() =>
      _TrainingReviewQueueScreenState();
}

class _TrainingReviewQueueScreenState extends State<TrainingReviewQueueScreen> {
  static const List<String> _reviewStatuses = <String>[
    'unreviewed',
    'approved',
    'rejected',
    'needs_redaction',
    'golden',
    'training_eligible',
    'deleted',
  ];

  String _selectedFilter = 'unreviewed';
  bool _isLoading = false;
  String? _error;
  List<TrainingReviewCandidate> _items = const [];

  Future<TrainingDataService> _service() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    return TrainingDataService(storageService: storage);
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = await _service();
      final items = await service.getTrainingReviewQueue(
        status: _selectedFilter,
        limit: 60,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _setStatus(TrainingReviewCandidate item, String status) async {
    try {
      final service = await _service();
      await service.reviewTrainingCandidate(
        candidateId: item.id,
        status: status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated ${item.id} -> $status')),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update review: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Review Queue'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh queue',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: const InputDecoration(
                labelText: 'Review Status Filter',
                border: OutlineInputBorder(),
              ),
              items: _reviewStatuses
                  .map((status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedFilter = value;
                });
                _reload();
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: _items.isEmpty && !_isLoading
                ? const Center(
                    child: Text('No candidates found for selected status.'),
                  )
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ListTile(
                        title: Text(item.itemName ?? item.id),
                        subtitle: Text(
                          'status=${item.reviewStatus} | '
                          'category=${item.category ?? '-'} | '
                          'eligible=${item.datasetEligible} \n'
                          'image=${item.imageStoragePath ?? 'metadata-only'}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) => _setStatus(item, value),
                          itemBuilder: (_) => _reviewStatuses
                              .map((status) => PopupMenuItem<String>(
                                    value: status,
                                    child: Text(status),
                                  ))
                              .toList(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
