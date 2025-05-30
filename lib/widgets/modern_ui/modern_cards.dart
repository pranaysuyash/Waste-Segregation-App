import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'modern_badges.dart';

/// Modern card widget with glassmorphism effect and customizable appearance
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final List<BoxShadow>? shadows;
  final Border? border;
  final VoidCallback? onTap;
  final bool enableGlassmorphism;
  final double? elevation;
  final Gradient? gradient;
  final double blur;
  final double opacity;

  const ModernCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.shadows,
    this.border,
    this.onTap,
    this.enableGlassmorphism = false,
    this.elevation,
    this.gradient,
    this.blur = 10.0,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final double effectiveRadius = borderRadius ?? AppTheme.borderRadiusLg;
    
    Widget cardContent = Container(
      margin: margin ?? const EdgeInsets.all(AppTheme.spacingSm),
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: enableGlassmorphism 
            ? (backgroundColor ?? theme.cardColor).withOpacity(opacity)
            : backgroundColor ?? theme.cardColor,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: border ?? (enableGlassmorphism 
            ? Border.all(
                color: Colors.white.withOpacity(0.2), 
                width: 1,
              ) 
            : null),
        boxShadow: shadows ?? [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: blur,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        gradient: gradient,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// Glassmorphism card with blur effect
class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double blur;
  final double opacity;

  const GlassmorphismCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.borderRadius = 16.0,
    this.onTap,
    this.backgroundColor,
    this.blur = 10.0,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      enableGlassmorphism: true,
      borderRadius: borderRadius,
      margin: margin,
      padding: padding,
      onTap: onTap,
      backgroundColor: backgroundColor,
      blur: blur,
      opacity: opacity,
      child: child,
    );
  }
}

/// Feature card with icon and content - inspired by modern app designs
class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool showChevron;
  final EdgeInsets? padding;
  final double? iconSize;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.showChevron = true,
    this.padding,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;
    final effectiveIconSize = iconSize ?? AppTheme.iconSizeLg;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive padding based on available width
        EdgeInsets effectivePadding = padding ?? EdgeInsets.all(
          constraints.maxWidth < 300 
              ? AppTheme.spacingSm  // Smaller padding for narrow screens
              : AppTheme.spacingMd, // Standard padding for normal screens
        );
        
        return ModernCard(
          onTap: onTap,
          backgroundColor: backgroundColor,
          padding: effectivePadding,
      child: Row(
        children: [
          // Icon container with modern styling
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: effectiveIconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
            ),
            child: Icon(
              icon,
              color: effectiveIconColor,
              size: effectiveIconSize,
            ),
          ),
          
          const SizedBox(width: AppTheme.spacingMd),
          
          // Content with overflow protection
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with responsive sizing and overflow protection
                    LayoutBuilder(
                      builder: (context, titleConstraints) {
                        // For very narrow cards, use smaller text
                        final titleStyle = titleConstraints.maxWidth < 150
                            ? theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              )
                            : theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              );
                        
                        return Text(
                          title,
                          style: titleStyle,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2, // Allow wrapping to 2 lines for long titles
                        );
                      },
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2, // Allow wrapping to 2 lines for long subtitles
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          
          // Trailing content
          if (trailing != null)
            trailing!
          else if (showChevron && onTap != null)
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
        ],
      ),
    );
      },
    );
  }
}

/// Stats card with modern number display and overflow protection
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final String? trend;
  final bool isPositiveTrend;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
    this.trend,
    this.isPositiveTrend = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;
    
    return ModernCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(
                  icon,
                  color: effectiveColor,
                  size: AppTheme.iconSizeSm,
                ),
              ],
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingSm),
          
          // Main value with responsive sizing
          LayoutBuilder(
            builder: (context, constraints) {
              // Determine appropriate text style based on available width and value length
              TextStyle? valueStyle;
              if (constraints.maxWidth < 100 || value.length > 6) {
                // Use smaller text for narrow cards or long values
                valueStyle = theme.textTheme.headlineMedium?.copyWith(
                  color: effectiveColor,
                  fontWeight: FontWeight.bold,
                );
              } else if (constraints.maxWidth < 150 || value.length > 4) {
                // Use medium text for medium cards or medium values
                valueStyle = theme.textTheme.headlineLarge?.copyWith(
                  color: effectiveColor,
                  fontWeight: FontWeight.bold,
                );
              } else {
                // Use large text for wide cards with short values
                valueStyle = theme.textTheme.displaySmall?.copyWith(
                  color: effectiveColor,
                  fontWeight: FontWeight.bold,
                );
              }
              
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: valueStyle,
                  maxLines: 1,
                ),
              );
            },
          ),
          
          // Subtitle and trend with improved layout
          if (subtitle != null || trend != null) ...[
            const SizedBox(height: AppTheme.spacingXs),
            LayoutBuilder(
              builder: (context, constraints) {
                // For very narrow cards, stack subtitle and trend vertically
                if (constraints.maxWidth < 80) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      if (subtitle != null && trend != null)
                        const SizedBox(height: 2),
                      if (trend != null)
                        _buildTrendChip(theme),
                    ],
                  );
                }
                
                // For normal width cards, use horizontal layout
                return Row(
                  children: [
                    if (subtitle != null)
                      Flexible(
                        child: Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    if (subtitle != null && trend != null)
                      const SizedBox(width: 4),
                    if (trend != null)
                      Flexible(child: _buildTrendChip(theme)),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTrendChip(ThemeData theme) {
    // Standardized colors for trend chips
    final trendColor = isPositiveTrend 
        ? AppTheme.successColor 
        : AppTheme.errorColor;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // For very narrow spaces, show only the trend text
        if (constraints.maxWidth < 50) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 1,
            ),
            decoration: BoxDecoration(
              color: trendColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusXs),
            ),
            child: Text(
              trend!,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: trendColor,
              ),
            ),
          );
        }
        
        // For normal spaces, show icon and text
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: trendColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusXs),
            border: Border.all(
              color: trendColor.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositiveTrend 
                    ? Icons.trending_up 
                    : Icons.trending_down,
                size: 10,
                color: trendColor,
              ),
              const SizedBox(width: 2),
              Text(
                trend!,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: trendColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Action card with gradient background and modern styling
class ActionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Gradient? gradient;
  final Color? color;
  final Widget? badge;

  const ActionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
    this.gradient,
    this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;
    
    final effectiveGradient = gradient ?? LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        effectiveColor,
        effectiveColor.withOpacity(0.8),
      ],
    );
    
    return ModernCard(
      onTap: onTap,
      gradient: effectiveGradient,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: AppTheme.iconSizeXl,
              ),
              
              const SizedBox(height: AppTheme.spacingMd),
              
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              if (subtitle != null) ...[
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ],
          ),
          
          if (badge != null)
            Positioned(
              top: 0,
              right: 0,
              child: badge!,
            ),
        ],
      ),
    );
  }
}

/// Enhanced Active Challenge Card with overflow protection and responsive layout
class ActiveChallengeCard extends StatelessWidget {
  final String title;
  final String description;
  final double progress; // 0.0 to 1.0
  final Color? challengeColor;
  final IconData? icon;
  final String? timeRemaining;
  final String? reward;
  final VoidCallback? onTap;
  final bool showProgressText;

  const ActiveChallengeCard({
    super.key,
    required this.title,
    required this.description,
    required this.progress,
    this.challengeColor,
    this.icon,
    this.timeRemaining,
    this.reward,
    this.onTap,
    this.showProgressText = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = challengeColor ?? theme.colorScheme.primary;
    final clampedProgress = progress.clamp(0.0, 1.0);
    
    return ModernCard(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determine layout based on available width
          final isNarrow = constraints.maxWidth < 300;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: effectiveColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                      ),
                      child: Icon(
                        icon,
                        color: effectiveColor,
                        size: isNarrow ? 20 : 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: isNarrow ? 14 : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (timeRemaining != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            timeRemaining!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: isNarrow ? 11 : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Progress badge
                  ProgressBadge(
                    progress: clampedProgress,
                    progressColor: effectiveColor,
                    size: isNarrow ? 28 : 36,
                    showPercentage: showProgressText,
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingSm),
              
              // Description
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: isNarrow ? 12 : null,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: isNarrow ? 1 : 2,
              ),
              
              const SizedBox(height: AppTheme.spacingSm),
              
              // Progress bar and reward
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusXs),
                      child: LinearProgressIndicator(
                        value: clampedProgress,
                        minHeight: isNarrow ? 4 : 6,
                        backgroundColor: effectiveColor.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                      ),
                    ),
                  ),
                  if (reward != null) ...[
                    const SizedBox(width: AppTheme.spacingSm),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isNarrow ? 6 : 8,
                        vertical: isNarrow ? 2 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusXs),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stars,
                            color: Colors.amber,
                            size: isNarrow ? 12 : 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            reward!,
                            style: TextStyle(
                              fontSize: isNarrow ? 10 : 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Enhanced Recent Classification Card with overflow protection and responsive layout
class RecentClassificationCard extends StatelessWidget {
  final String itemName;
  final String category;
  final String? subcategory;
  final DateTime timestamp;
  final String? imageUrl;
  final bool? isRecyclable;
  final bool? isCompostable;
  final bool? requiresSpecialDisposal;
  final Color? categoryColor;
  final VoidCallback? onTap;
  final bool showImage;
  final bool showPropertyIndicators;

  const RecentClassificationCard({
    super.key,
    required this.itemName,
    required this.category,
    required this.timestamp,
    this.subcategory,
    this.imageUrl,
    this.isRecyclable,
    this.isCompostable,
    this.requiresSpecialDisposal,
    this.categoryColor,
    this.onTap,
    this.showImage = true,
    this.showPropertyIndicators = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveCategoryColor = categoryColor ?? _getDefaultCategoryColor(category);
    
    return ModernCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(
        vertical: AppTheme.spacingXs,
        horizontal: 0,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      border: Border.all(
        color: effectiveCategoryColor.withOpacity(0.3),
        width: 1,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determine layout based on available width
          final isNarrow = constraints.maxWidth < 350;
          final isVeryNarrow = constraints.maxWidth < 280;
          
          return Row(
            children: [
              // Thumbnail (if available and enabled)
              if (showImage && imageUrl != null && !isVeryNarrow) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                  child: Container(
                    width: isNarrow ? 50 : 60,
                    height: isNarrow ? 50 : 60,
                    color: effectiveCategoryColor.withOpacity(0.1),
                    child: _buildImageWidget(isNarrow ? 50 : 60),
                  ),
                ),
                SizedBox(width: isNarrow ? AppTheme.spacingSm : AppTheme.spacingMd),
              ],
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item name and date row
                    Row(
                      children: [
                        // Item name
                        Expanded(
                          flex: isNarrow ? 2 : 3,
                          child: Text(
                            itemName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: isVeryNarrow ? 13 : (isNarrow ? 14 : null),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        const SizedBox(width: AppTheme.spacingXs),
                        
                        // Date
                        Flexible(
                          child: Text(
                            _formatDate(timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: isVeryNarrow ? 10 : (isNarrow ? 11 : null),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: isNarrow ? 6 : 8),
                    
                    // Categories and indicators row
                    LayoutBuilder(
                      builder: (context, badgeConstraints) {
                        return _buildBadgesAndIndicators(
                          context,
                          effectiveCategoryColor,
                          badgeConstraints.maxWidth,
                          isNarrow,
                          isVeryNarrow,
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Navigation arrow
              Icon(
                Icons.chevron_right,
                size: isNarrow ? 18 : 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildBadgesAndIndicators(
    BuildContext context,
    Color categoryColor,
    double availableWidth,
    bool isNarrow,
    bool isVeryNarrow,
  ) {
    final theme = Theme.of(context);
    
    // Calculate space needed for property indicators
    int indicatorCount = 0;
    if (showPropertyIndicators) {
      if (isRecyclable == true) indicatorCount++;
      if (isCompostable == true) indicatorCount++;
      if (requiresSpecialDisposal == true) indicatorCount++;
    }
    
    // Reserve space for indicators and arrow
    final indicatorSpace = indicatorCount * (isNarrow ? 18 : 20) + (indicatorCount > 0 ? AppTheme.spacingXs : 0);
    final availableForBadges = availableWidth - indicatorSpace - 24; // 24 for arrow
    
    // Determine if we need to stack badges vertically
    final shouldStackVertically = isVeryNarrow || availableForBadges < 120;
    
    if (shouldStackVertically) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badges row
          Row(
            children: [
              Flexible(
                child: _buildCategoryBadges(categoryColor, isNarrow, isVeryNarrow),
              ),
            ],
          ),
          if (showPropertyIndicators && indicatorCount > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                ..._buildPropertyIndicators(isNarrow),
                const Spacer(),
              ],
            ),
          ],
        ],
      );
    }
    
    // Horizontal layout for wider screens
    return Row(
      children: [
        Flexible(
          child: _buildCategoryBadges(categoryColor, isNarrow, isVeryNarrow),
        ),
        if (showPropertyIndicators && indicatorCount > 0) ...[
          const SizedBox(width: AppTheme.spacingXs),
          ..._buildPropertyIndicators(isNarrow),
        ],
        const Spacer(),
      ],
    );
  }
  
  Widget _buildCategoryBadges(Color categoryColor, bool isNarrow, bool isVeryNarrow) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main category badge - always flexible to prevent overflow
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isVeryNarrow ? 6 : 8,
                  vertical: isVeryNarrow ? 1 : 2,
                ),
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusXs),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isVeryNarrow ? 9 : (isNarrow ? 10 : AppTheme.fontSizeSmall),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            
            // Subcategory badge if available and space permits
            if (subcategory != null && !isVeryNarrow && constraints.maxWidth > 100) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 4 : 6,
                    vertical: isNarrow ? 1 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusXs),
                    border: Border.all(
                      color: categoryColor.withOpacity(0.5),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    subcategory!,
                    style: TextStyle(
                      color: categoryColor,
                      fontSize: isNarrow ? 9 : 10,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
  
  List<Widget> _buildPropertyIndicators(bool isNarrow) {
    final List<Widget> indicators = [];
    final iconSize = isNarrow ? 14.0 : 16.0;
    
    if (isRecyclable == true) {
      indicators.add(
        Tooltip(
          message: 'Recyclable',
          child: Icon(
            Icons.recycling,
            size: iconSize,
            color: Colors.blue,
          ),
        ),
      );
    }
    
    if (isCompostable == true) {
      indicators.add(
        Tooltip(
          message: 'Compostable',
          child: Icon(
            Icons.eco,
            size: iconSize,
            color: Colors.green,
          ),
        ),
      );
    }
    
    if (requiresSpecialDisposal == true) {
      indicators.add(
        Tooltip(
          message: 'Special Disposal Required',
          child: Icon(
            Icons.warning_amber,
            size: iconSize,
            color: Colors.orange,
          ),
        ),
      );
    }
    
    // Add spacing between indicators
    final spacedIndicators = <Widget>[];
    for (int i = 0; i < indicators.length; i++) {
      spacedIndicators.add(indicators[i]);
      if (i < indicators.length - 1) {
        spacedIndicators.add(const SizedBox(width: 2));
      }
    }
    
    return spacedIndicators;
  }
  
  Widget _buildImageWidget(double size) {
    if (imageUrl == null) {
      return Icon(
        Icons.image,
        size: size * 0.4,
        color: Colors.grey,
      );
    }
    
    // For now, return a placeholder - in real implementation, this would handle
    // the actual image loading with proper error handling
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusXs),
      ),
      child: Icon(
        Icons.image,
        size: size * 0.4,
        color: Colors.grey,
      ),
    );
  }
  
  Color _getDefaultCategoryColor(String category) {
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
      default:
        return AppTheme.neutralColor;
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
