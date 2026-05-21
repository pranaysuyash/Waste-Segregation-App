import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/smart_suggestions_service.dart';
import '../services/storage_service.dart';
import '../services/offline_queue_service.dart';

/// Track 4: Smart Suggestions Screen
/// Displays personalized suggestions based on user behavior and offline queue data
class SmartSuggestionsScreen extends StatefulWidget {
  const SmartSuggestionsScreen({super.key});

  @override
  State<SmartSuggestionsScreen> createState() => _SmartSuggestionsScreenState();
}

class _SmartSuggestionsScreenState extends State<SmartSuggestionsScreen> {
  List<SmartSuggestion> _suggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final queueService =
          Provider.of<OfflineQueueService>(context, listen: false);
      final suggestionsService =
          SmartSuggestionsService(storageService, queueService);

      final suggestions = await suggestionsService.getSmartSuggestions();

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [SmartSuggestion.errorSuggestion()];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Suggestions'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSuggestions,
            tooltip: 'Refresh Suggestions',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSuggestions,
              child: _suggestions.isEmpty
                  ? _buildEmptyState()
                  : _buildSuggestionsList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No suggestions available',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start classifying waste to get personalized suggestions!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return _buildSuggestionCard(suggestion);
      },
    );
  }

  Widget _buildSuggestionCard(SmartSuggestion suggestion) {
    Color cardColor;
    Color textColor;

    switch (suggestion.color) {
      case 'green':
        cardColor = Colors.green[50]!;
        textColor = Colors.green[800]!;
        break;
      case 'blue':
        cardColor = Colors.blue[50]!;
        textColor = Colors.blue[800]!;
        break;
      case 'orange':
        cardColor = Colors.orange[50]!;
        textColor = Colors.orange[800]!;
        break;
      case 'purple':
        cardColor = Colors.purple[50]!;
        textColor = Colors.purple[800]!;
        break;
      case 'teal':
        cardColor = Colors.teal[50]!;
        textColor = Colors.teal[800]!;
        break;
      case 'gold':
        cardColor = Colors.amber[50]!;
        textColor = Colors.amber[800]!;
        break;
      case 'red':
        cardColor = Colors.red[50]!;
        textColor = Colors.red[800]!;
        break;
      default:
        cardColor = Colors.grey[50]!;
        textColor = Colors.grey[800]!;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  suggestion.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                  ),
                ),
                _buildPriorityIndicator(suggestion.priority),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor.withOpacity(0.8),
                  ),
            ),
            if (suggestion.actionText != null && suggestion.actionRoute != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ElevatedButton(
                  onPressed: () => _handleSuggestionAction(suggestion),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: textColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(suggestion.actionText!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(int priority) {
    IconData icon;
    Color color;

    switch (priority) {
      case 1:
        icon = Icons.priority_high;
        color = Colors.red;
        break;
      case 2:
        icon = Icons.priority_high;
        color = Colors.orange;
        break;
      case 3:
        icon = Icons.low_priority;
        color = Colors.green;
        break;
      default:
        icon = Icons.priority_high;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 16);
  }

  void _handleSuggestionAction(SmartSuggestion suggestion) {
    if (suggestion.actionRoute == null) return;

    // Navigate to the suggested route
    switch (suggestion.actionRoute) {
      case '/camera':
        Navigator.of(context).pushNamed('/camera');
        break;
      case '/settings':
        Navigator.of(context).pushNamed('/settings');
        break;
      case '/analytics':
        Navigator.of(context).pushNamed('/analytics');
        break;
      case '/contribution':
        Navigator.of(context).pushNamed('/contribution');
        break;
      case '/achievements':
        Navigator.of(context).pushNamed('/achievements');
        break;
      default:
        // For unknown routes, just pop back
        Navigator.of(context).pop();
    }
  }
}
