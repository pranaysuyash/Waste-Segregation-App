import 'package:flutter/material.dart';

/// A reusable widget that provides smooth expand/collapse animations for content sections.
/// Perfect for explanations, educational facts, and other collapsible content.
class ExpandableSection extends StatefulWidget {
  
  const ExpandableSection({
    super.key,
    required this.title,
    required this.content,
    this.trimLines = 3,
    this.titleColor = Colors.blueAccent,
    this.titleIcon,
    this.backgroundColor,
    this.borderColor,
  });
  final String title;
  final String content;
  final int trimLines;
  final Color titleColor;
  final IconData? titleIcon;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection>
    with TickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller, 
      curve: Curves.easeInOut,
    );
  }
  
  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Use theme-aware colors
    final effectiveTitleColor = widget.titleColor == Colors.blueAccent 
        ? theme.colorScheme.primary 
        : widget.titleColor;
    
    final effectiveBackgroundColor = widget.backgroundColor ?? 
        (isDark ? Colors.grey.shade800 : const Color(0xFFE3F2FD));
    
    final effectiveBorderColor = widget.borderColor ?? 
        (isDark ? Colors.grey.shade600 : const Color(0xFF1976D2));
    
    final textColor = isDark ? Colors.white : const Color(0xFF212121);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: effectiveBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with optional icon
          Row(
            children: [
              if (widget.titleIcon != null) ...[
                Icon(
                  widget.titleIcon,
                  color: effectiveTitleColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: effectiveTitleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Content with animation
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.content,
                  maxLines: _expanded ? null : widget.trimLines,
                  overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _toggle,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expanded ? 'Show Less' : 'Read More',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: effectiveTitleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: effectiveTitleColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 