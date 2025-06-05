import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Modern badge with various styles and animations
class ModernBadge extends StatelessWidget {

  const ModernBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.style = ModernBadgeStyle.filled,
    this.size = ModernBadgeSize.medium,
    this.icon,
    this.onTap,
    this.showPulse = false,
  });
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final ModernBadgeStyle style;
  final ModernBadgeSize size;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool showPulse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? theme.colorScheme.primary;
    final effectiveTextColor = textColor ?? _getTextColor(theme, effectiveBackgroundColor);
    
    Widget badge = Container(
      padding: _getPadding(),
      decoration: _getDecoration(theme, effectiveBackgroundColor),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: _getIconSize(),
              color: effectiveTextColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: _getTextStyle(theme).copyWith(
              color: effectiveTextColor,
            ),
          ),
        ],
      ),
    );
    
    if (showPulse) {
      badge = PulseBadge(child: badge);
    }
    
    if (onTap != null) {
      badge = GestureDetector(
        onTap: onTap,
        child: badge,
      );
    }
    
    return badge;
  }
  
  EdgeInsets _getPadding() {
    switch (size) {
      case ModernBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case ModernBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case ModernBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }
  
  double _getIconSize() {
    switch (size) {
      case ModernBadgeSize.small:
        return 12;
      case ModernBadgeSize.medium:
        return 16;
      case ModernBadgeSize.large:
        return 20;
    }
  }
  
  TextStyle _getTextStyle(ThemeData theme) {
    switch (size) {
      case ModernBadgeSize.small:
        return theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ) ?? const TextStyle();
      case ModernBadgeSize.medium:
        return theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ) ?? const TextStyle();
      case ModernBadgeSize.large:
        return theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ) ?? const TextStyle();
    }
  }
  
  BoxDecoration _getDecoration(ThemeData theme, Color backgroundColor) {
    switch (style) {
      case ModernBadgeStyle.filled:
        return BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusXl),
        );
      case ModernBadgeStyle.outlined:
        return BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: backgroundColor, width: 1.5),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusXl),
        );
      case ModernBadgeStyle.soft:
        return BoxDecoration(
          color: backgroundColor.withValues(alpha:0.15),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusXl),
        );
      case ModernBadgeStyle.glassmorphism:
        return BoxDecoration(
          color: backgroundColor.withValues(alpha:0.1),
          border: Border.all(color: backgroundColor.withValues(alpha:0.3)),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusXl),
        );
    }
  }
  
  Color _getTextColor(ThemeData theme, Color backgroundColor) {
    switch (style) {
      case ModernBadgeStyle.filled:
        return Colors.white;
      case ModernBadgeStyle.outlined:
      case ModernBadgeStyle.soft:
      case ModernBadgeStyle.glassmorphism:
        return backgroundColor;
    }
  }
}

/// Pulsing animation wrapper for badges
class PulseBadge extends StatefulWidget {
  
  const PulseBadge({super.key, required this.child});
  final Widget child;

  @override
  State<PulseBadge> createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<PulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Modern chip with selection and filtering capabilities
class ModernChip extends StatelessWidget {

  const ModernChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
    this.icon,
    this.selectedColor,
    this.unselectedColor,
    this.style = ModernChipStyle.filled,
  });
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final IconData? icon;
  final Color? selectedColor;
  final Color? unselectedColor;
  final ModernChipStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveSelectedColor = selectedColor ?? theme.colorScheme.primary;
    final effectiveUnselectedColor = unselectedColor ?? theme.colorScheme.surfaceContainerHighest;
    
    return AnimatedContainer(
      duration: AppTheme.animationFast,
      decoration: _getDecoration(theme, effectiveSelectedColor, effectiveUnselectedColor),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusXl),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: _getContentColor(theme, effectiveSelectedColor),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _getContentColor(theme, effectiveSelectedColor),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: _getContentColor(theme, effectiveSelectedColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  BoxDecoration _getDecoration(ThemeData theme, Color selectedColor, Color unselectedColor) {
    switch (style) {
      case ModernChipStyle.filled:
        return BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusXl),
        );
      case ModernChipStyle.outlined:
        return BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: isSelected ? selectedColor : theme.colorScheme.outline,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusXl),
        );
      case ModernChipStyle.soft:
        return BoxDecoration(
          color: isSelected ? selectedColor.withValues(alpha:0.15) : unselectedColor.withValues(alpha:0.5),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusXl),
        );
    }
  }
  
  Color _getContentColor(ThemeData theme, Color selectedColor) {
    if (style == ModernChipStyle.filled && isSelected) {
      return Colors.white;
    }
    return isSelected ? selectedColor : theme.colorScheme.onSurfaceVariant;
  }
}

/// Category badge for waste types with predefined colors
class WasteCategoryBadge extends StatelessWidget {

  const WasteCategoryBadge({
    super.key,
    required this.category,
    this.style = ModernBadgeStyle.filled,
    this.size = ModernBadgeSize.medium,
    this.onTap,
  });
  final String category;
  final ModernBadgeStyle style;
  final ModernBadgeSize size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(category);
    final icon = _getCategoryIcon(category);
    
    return ModernBadge(
      text: category,
      backgroundColor: color,
      icon: icon,
      style: style,
      size: size,
      onTap: onTap,
    );
  }
  
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'wet waste':
        return AppTheme.wetWasteColor;
      case 'dry waste':
        return AppTheme.dryWasteColor;
      case 'hazardous waste':
        return AppTheme.hazardousWasteColor;
      case 'medical waste':
        return AppTheme.medicalWasteColor;
      case 'non-waste':
        return AppTheme.nonWasteColor;
      case 'requires manual review':
        return AppTheme.manualReviewColor;
      default:
        return AppTheme.neutralColor;
    }
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'wet waste':
        return Icons.eco;
      case 'dry waste':
        return Icons.recycling;
      case 'hazardous waste':
        return Icons.warning;
      case 'medical waste':
        return Icons.medical_services;
      case 'non-waste':
        return Icons.check_circle;
      case 'requires manual review':
        return Icons.help_outline;
      default:
        return Icons.category;
    }
  }
}

/// Status badge with predefined colors and states
class StatusBadge extends StatelessWidget {

  const StatusBadge({
    super.key,
    required this.status,
    this.style = ModernBadgeStyle.soft,
    this.size = ModernBadgeSize.small,
  });
  final String status;
  final ModernBadgeStyle style;
  final ModernBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(status);
    
    return ModernBadge(
      text: status,
      backgroundColor: statusInfo.color,
      icon: statusInfo.icon,
      style: style,
      size: size,
    );
  }
  
  StatusInfo _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
      case 'active':
        return StatusInfo(AppTheme.successColor, Icons.check_circle);
      case 'pending':
      case 'in progress':
        return StatusInfo(AppTheme.warningColor, Icons.schedule);
      case 'failed':
      case 'error':
      case 'inactive':
        return StatusInfo(AppTheme.errorColor, Icons.error);
      case 'new':
      case 'updated':
        return StatusInfo(AppTheme.infoColor, Icons.fiber_new);
      default:
        return StatusInfo(AppTheme.neutralColor, Icons.info);
    }
  }
}

/// Helper class for status information
class StatusInfo {
  
  StatusInfo(this.color, this.icon);
  final Color color;
  final IconData icon;
}

/// Chip group with multiple selection support
class ModernChipGroup extends StatefulWidget {

  const ModernChipGroup({
    super.key,
    required this.options,
    this.selectedOptions = const [],
    this.onSelectionChanged,
    this.multiSelect = true,
    this.style = ModernChipStyle.soft,
    this.selectedColor,
    this.padding,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
  });
  final List<String> options;
  final List<String> selectedOptions;
  final Function(List<String>)? onSelectionChanged;
  final bool multiSelect;
  final ModernChipStyle style;
  final Color? selectedColor;
  final EdgeInsets? padding;
  final double spacing;
  final double runSpacing;

  @override
  State<ModernChipGroup> createState() => _ModernChipGroupState();
}

class _ModernChipGroupState extends State<ModernChipGroup> {
  late List<String> _selectedOptions;

  @override
  void initState() {
    super.initState();
    _selectedOptions = List.from(widget.selectedOptions);
  }

  @override
  void didUpdateWidget(ModernChipGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedOptions != oldWidget.selectedOptions) {
      _selectedOptions = List.from(widget.selectedOptions);
    }
  }

  void _handleSelection(String option) {
    setState(() {
      if (widget.multiSelect) {
        if (_selectedOptions.contains(option)) {
          _selectedOptions.remove(option);
        } else {
          _selectedOptions.add(option);
        }
      } else {
        if (_selectedOptions.contains(option)) {
          _selectedOptions.clear();
        } else {
          _selectedOptions = [option];
        }
      }
    });
    
    widget.onSelectionChanged?.call(_selectedOptions);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Wrap(
        spacing: widget.spacing,
        runSpacing: widget.runSpacing,
        children: widget.options.map((option) {
          final isSelected = _selectedOptions.contains(option);
          return ModernChip(
            label: option,
            isSelected: isSelected,
            onTap: () => _handleSelection(option),
            style: widget.style,
            selectedColor: widget.selectedColor,
          );
        }).toList(),
      ),
    );
  }
}

/// Progress indicator badge with enhanced overflow protection and responsive sizing
class ProgressBadge extends StatelessWidget {

  const ProgressBadge({
    super.key,
    required this.progress,
    this.text,
    this.progressColor,
    this.backgroundColor,
    this.size = 32.0,
    this.showPercentage = true,
    this.strokeWidth,
  });
  final double progress; // 0.0 to 1.0
  final String? text;
  final Color? progressColor;
  final Color? backgroundColor;
  final double size;
  final bool showPercentage;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveProgressColor = progressColor ?? theme.colorScheme.primary;
    final effectiveBackgroundColor = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final effectiveStrokeWidth = strokeWidth ?? (size * 0.1).clamp(2.0, 4.0);
    
    // Clamp progress to valid range
    final clampedProgress = progress.clamp(0.0, 1.0);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive sizing based on available space
        final responsiveSize = constraints.maxWidth > 0 
            ? size.clamp(24.0, constraints.maxWidth.clamp(24.0, 48.0))
            : size;
        
        return SizedBox(
          width: responsiveSize,
          height: responsiveSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: clampedProgress,
                strokeWidth: effectiveStrokeWidth,
                backgroundColor: effectiveBackgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(effectiveProgressColor),
              ),
              if (text != null || showPercentage)
                _buildCenterText(responsiveSize, effectiveProgressColor, clampedProgress),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildCenterText(double size, Color color, double progress) {
    final displayText = text ?? '${(progress * 100).round()}%';
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate appropriate font size based on badge size and text length
        var fontSize = size * 0.25;
        
        // Adjust font size based on text length to prevent overflow
        if (displayText.length > 3) {
          fontSize = size * 0.2;
        }
        if (displayText.length > 4) {
          fontSize = size * 0.15;
        }
        
        // Ensure minimum readable size
        fontSize = fontSize.clamp(8.0, (size * 0.3).clamp(8.0, double.infinity));
        
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: size * 0.8, // Ensure text doesn't exceed badge bounds
            ),
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}

/// Badge and chip style enums
enum ModernBadgeStyle {
  filled,
  outlined,
  soft,
  glassmorphism,
}

enum ModernBadgeSize {
  small,
  medium,
  large,
}

enum ModernChipStyle {
  filled,
  outlined,
  soft,
}
