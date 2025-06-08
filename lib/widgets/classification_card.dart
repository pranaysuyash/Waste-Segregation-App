import 'package:flutter/material.dart';
import '../models/waste_classification.dart';
import '../screens/history_screen.dart';

/// The new beautified classification card with modern Material Design
class ClassificationCard extends StatelessWidget {
  final WasteClassification classification;
  
  const ClassificationCard({
    super.key, 
    required this.classification,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(classification.category);
    final confidencePct = ((classification.confidence ?? 0) * 100).toInt();
    final timeAgo = _formatRelativeTime(classification.timestamp);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: catColor.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => _navigateToHistory(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ── Thumbnail ─────────────────────────────
              Hero(
                tag: 'photo-${classification.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: classification.imageUrl != null
                      ? Image.network(
                          classification.imageUrl!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallbackIcon(catColor),
                        )
                      : _fallbackIcon(catColor),
                ),
              ),
              const SizedBox(width: 16),

              // ── Main Info ─────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      classification.itemName,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Category / Disposal / Confidence chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Chip(
                          backgroundColor: catColor.withValues(alpha: 0.1),
                          avatar: Icon(_categoryIcon(classification.category),
                              size: 16, color: catColor),
                          label: Text(classification.category,
                              style: TextStyle(color: catColor, fontWeight: FontWeight.w500)),
                          visualDensity: VisualDensity.compact,
                        ),
                        if (classification.disposalMethod != null)
                          Chip(
                            backgroundColor: Colors.white,
                            shape: StadiumBorder(side: BorderSide(color: catColor)),
                            label: Text(
                              _disposalText(classification.disposalMethod),
                              style: TextStyle(color: catColor, fontSize: 12),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (classification.confidence != null)
                          Chip(
                            backgroundColor:
                                _confidenceColor(confidencePct).withValues(alpha: 0.1),
                            avatar: Icon(Icons.verified,
                                size: 16, color: _confidenceColor(confidencePct)),
                            label: Text('$confidencePct%',
                                style: TextStyle(
                                    color: _confidenceColor(confidencePct),
                                    fontWeight: FontWeight.w500)),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Time ago
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(timeAgo,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Impact + Chevron ───────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (classification.environmentalImpact != null)
                    Chip(
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                      avatar: const Icon(Icons.eco, size: 16, color: Colors.green),
                      label: Text(
                        '+${classification.environmentalImpact} pts',
                        style: const TextStyle(
                          color: Colors.green, 
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  const SizedBox(height: 8),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackIcon(Color color) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(_categoryIcon(classification.category), color: Colors.white, size: 32),
    );
  }

  void _navigateToHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HistoryScreen(),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, ctl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: ctl,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Classification Details',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(classification.itemName,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Category: ${classification.category}'),
              if (classification.confidence != null)
                Text('Confidence: ${(classification.confidence! * 100).toInt()}%'),
              if (classification.disposalMethod != null)
                Text('Disposal: ${classification.disposalMethod}'),
              Text('Date: ${_formatDate(classification.timestamp)} at ${_formatTime(classification.timestamp)}'),
              if (classification.environmentalImpact != null)
                Text('Environmental Impact: +${classification.environmentalImpact} points'),
            ],
          ),
        ),
      ),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'recyclable':
      case 'dry waste':
        return Colors.green;
      case 'organic':
      case 'wet waste':
        return Colors.brown;
      case 'hazardous':
      case 'hazardous waste':
        return Colors.red;
      case 'electronic':
      case 'e-waste':
        return Colors.blue;
      case 'medical':
      case 'medical waste':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'recyclable':
      case 'dry waste':
        return Icons.recycling;
      case 'organic':
      case 'wet waste':
        return Icons.eco;
      case 'hazardous':
      case 'hazardous waste':
        return Icons.warning;
      case 'electronic':
      case 'e-waste':
        return Icons.electrical_services;
      case 'medical':
      case 'medical waste':
        return Icons.medical_services;
      default:
        return Icons.delete;
    }
  }

  String _disposalText(String? method) {
    switch (method?.toLowerCase()) {
      case 'recycle':
        return 'Recycle';
      case 'compost':
        return 'Compost';
      case 'hazardous':
        return 'Hazardous';
      case 'landfill':
        return 'Landfill';
      default:
        return 'General';
    }
  }

  Color _confidenceColor(int pct) {
    if (pct >= 80) return Colors.green;
    if (pct >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatRelativeTime(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inDays == 0) {
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${ts.day}/${ts.month}/${ts.year}';
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final classificationDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (classificationDate == today) {
      return 'Today';
    } else if (classificationDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}