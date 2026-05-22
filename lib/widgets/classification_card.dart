import 'package:flutter/material.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../screens/history_screen.dart';
import '../utils/waste_theme.dart';
import 'helpers/thumbnail_widget.dart';

/// The new beautified classification card with modern Material Design
class ClassificationCard extends StatelessWidget {
  const ClassificationCard({
    super.key,
    required this.classification,
  });
  final WasteClassification classification;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
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
                child: ThumbnailWidget(
                  imagePath: classification.thumbnailRelativePath ??
                      classification.imageUrl,
                  size: 60,
                  errorWidget: _fallbackIcon(catColor),
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
                              style: TextStyle(
                                  color: catColor,
                                  fontWeight: FontWeight.w500)),
                          visualDensity: VisualDensity.compact,
                        ),
                        if (classification.disposalMethod != null)
                          Chip(
                            backgroundColor: Colors.white,
                            shape: StadiumBorder(
                                side: BorderSide(color: catColor)),
                            label: Text(
                              _disposalText(classification.disposalMethod),
                              style: TextStyle(color: catColor, fontSize: 12),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (classification.confidence != null)
                          Chip(
                            backgroundColor: _confidenceColor(confidencePct)
                                .withValues(alpha: 0.1),
                            avatar: Icon(Icons.verified,
                                size: 16,
                                color: _confidenceColor(confidencePct)),
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
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(timeAgo,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
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
                      avatar:
                          const Icon(Icons.eco, size: 16, color: Colors.green),
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
      child: Icon(_categoryIcon(classification.category),
          color: Colors.white, size: 32),
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

  Color _categoryColor(String cat) => WasteTheme.categoryColor(cat);

  IconData _categoryIcon(String cat) => WasteTheme.categoryIcon(cat);

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

  Color _confidenceColor(int pct) => WasteTheme.confidenceColor(pct.toDouble());

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
}
