import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/constants.dart';

/// A modern Android-style bottom navigation bar with smooth animations,
/// customizable appearance, and haptic feedback
class ModernBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;
  final ModernBottomNavStyle style;
  final Duration animationDuration;
  final bool enableHapticFeedback;

  const ModernBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.style = const ModernBottomNavStyle(),
    this.animationDuration = const Duration(milliseconds: 300),
    this.enableHapticFeedback = true,
  });

  @override
  State<ModernBottomNavigation> createState() => _ModernBottomNavigationState();
}

class _ModernBottomNavigationState extends State<ModernBottomNavigation>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _rippleController;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Individual controllers for each nav item
    _itemControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 250),
        vsync: this,
      ),
    );

    // Animations for each item
    _itemAnimations = _itemControllers.map((controller) {
      return CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      );
    }).toList();

    // Animate initial selection
    if (widget.currentIndex < _itemControllers.length) {
      _itemControllers[widget.currentIndex].forward();
    }
  }

  @override
  void didUpdateWidget(ModernBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.currentIndex != widget.currentIndex) {
      // Animate out the old selection
      if (oldWidget.currentIndex < _itemControllers.length) {
        _itemControllers[oldWidget.currentIndex].reverse();
      }
      
      // Animate in the new selection
      if (widget.currentIndex < _itemControllers.length) {
        _itemControllers[widget.currentIndex].forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rippleController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleTap(int index) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    
    _rippleController.forward().then((_) {
      _rippleController.reverse();
    });
    
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: widget.style.backgroundColor ?? 
               (isDark ? Colors.grey[900] : Colors.white),
        boxShadow: widget.style.shadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: widget.style.borderRadius,
        border: widget.style.border,
      ),
      child: ClipRRect(
        borderRadius: widget.style.borderRadius ?? BorderRadius.zero,
        child: Container(
          height: widget.style.height,
          padding: widget.style.padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              widget.items.length,
              (index) => _buildNavItem(index, isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDark) {
    final item = widget.items[index];
    final isSelected = index == widget.currentIndex;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _itemAnimations[index],
          builder: (context, child) {
            final scale = isSelected ? 
                       1.0 + (_itemAnimations[index].value * 0.1) : 1.0;
            
            return Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon with animation
                    Flexible(
                      child: AnimatedContainer(
                        duration: widget.animationDuration,
                        curve: Curves.elasticOut,
                        padding: isSelected ? 
                                 const EdgeInsets.all(6) : 
                                 const EdgeInsets.all(2),
                        decoration: isSelected ? BoxDecoration(
                          color: (widget.style.selectedColor ?? AppTheme.primaryColor)
                                 .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ) : null,
                        child: Icon(
                          isSelected ? item.selectedIcon : item.icon,
                          color: isSelected
                              ? (widget.style.selectedColor ?? AppTheme.primaryColor)
                              : (widget.style.unselectedColor ?? 
                                 (isDark ? Colors.grey[400] : Colors.grey[600])),
                          size: widget.style.iconSize,
                        ),
                      ),
                    ),
                    
                    // Label with fade animation
                    if (item.label != null) ...[
                      const SizedBox(height: 2),
                      Flexible(
                        child: AnimatedDefaultTextStyle(
                          duration: widget.animationDuration,
                          style: TextStyle(
                            fontSize: widget.style.labelFontSize,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? (widget.style.selectedColor ?? AppTheme.primaryColor)
                                : (widget.style.unselectedColor ?? 
                                   (isDark ? Colors.grey[400] : Colors.grey[600])),
                          ),
                          child: Text(
                            item.label!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                    
                    // Selection indicator dot
                    if (widget.style.showIndicator && isSelected)
                      AnimatedContainer(
                        duration: widget.animationDuration,
                        margin: const EdgeInsets.only(top: 1),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: widget.style.selectedColor ?? AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Configuration class for the modern bottom navigation styling
class ModernBottomNavStyle {
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final List<BoxShadow>? shadow;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsets padding;
  final double height;
  final double iconSize;
  final double labelFontSize;
  final bool showIndicator;

  const ModernBottomNavStyle({
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.shadow,
    this.borderRadius,
    this.border,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.height = 65,
    this.iconSize = 22,
    this.labelFontSize = 11,
    this.showIndicator = true,
  });

  /// Glassmorphism style (like iOS/modern Android)
  static ModernBottomNavStyle glassmorphism({
    Color? primaryColor,
    bool isDark = false,
  }) {
    final baseColor = isDark ? Colors.black : Colors.white;
    final primary = primaryColor ?? AppTheme.primaryColor;
    
    return ModernBottomNavStyle(
      backgroundColor: baseColor.withOpacity(0.8),
      selectedColor: primary,
      unselectedColor: isDark ? Colors.grey[300] : Colors.grey[600],
      borderRadius: BorderRadius.circular(24),
      shadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, -5),
        ),
      ],
      height: 68,
      iconSize: 24,
      labelFontSize: 11,
      showIndicator: false,
    );
  }

  /// Material 3 style
  static ModernBottomNavStyle material3({
    Color? primaryColor,
    bool isDark = false,
  }) {
    return ModernBottomNavStyle(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      selectedColor: primaryColor ?? AppTheme.primaryColor,
      unselectedColor: isDark ? Colors.grey[400] : Colors.grey[700],
      borderRadius: BorderRadius.circular(16),
      shadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, -3),
        ),
      ],
      height: 66,
      iconSize: 22,
      labelFontSize: 11,
      showIndicator: true,
    );
  }

  /// Floating style (like some modern apps)
  static ModernBottomNavStyle floating({
    Color? primaryColor,
    bool isDark = false,
  }) {
    return ModernBottomNavStyle(
      backgroundColor: isDark ? Colors.grey[850] : Colors.white,
      selectedColor: primaryColor ?? AppTheme.primaryColor,
      unselectedColor: isDark ? Colors.grey[300] : Colors.grey[600],
      borderRadius: BorderRadius.circular(32),
      shadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      height: 64,
      iconSize: 20,
      labelFontSize: 10,
      showIndicator: false,
    );
  }
}

/// Data class for bottom navigation items
class BottomNavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String? label;
  final Widget? badge;

  const BottomNavItem({
    required this.icon,
    this.selectedIcon,
    this.label,
    this.badge,
  });
}
