import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'polished_divider.dart';

/// Enhanced section component with modern spacing and visual hierarchy
class PolishedSection extends StatelessWidget {
  const PolishedSection({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.showDivider = false,
    this.showTopDivider = false,
    this.onTitleTap,
    this.trailing,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  /// Creates a section with generous spacing for premium feel
  const PolishedSection.generous({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    required this.child,
    this.backgroundColor,
    this.showDivider = false,
    this.showTopDivider = false,
    this.onTitleTap,
    this.trailing,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  })  : padding = const EdgeInsets.all(AppThemePolish.spacingComfortable),
        margin = const EdgeInsets.symmetric(vertical: AppThemePolish.spacingGenerous);

  /// Creates a section with luxurious spacing for hero sections
  const PolishedSection.luxurious({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    required this.child,
    this.backgroundColor,
    this.showDivider = false,
    this.showTopDivider = false,
    this.onTitleTap,
    this.trailing,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  })  : padding = const EdgeInsets.all(AppThemePolish.spacingLuxurious),
        margin = const EdgeInsets.symmetric(vertical: AppThemePolish.spacingComfortable);
  final String? title;
  final String? subtitle;
  final Widget? titleWidget;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final bool showDivider;
  final bool showTopDivider;
  final VoidCallback? onTitleTap;
  final Widget? trailing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 16.0),
      decoration: backgroundColor != null
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          // Top divider
          if (showTopDivider) const PolishedDivider.section(),

          // Section header
          if (title != null || titleWidget != null) ...[
            Padding(
              padding: padding ?? const EdgeInsets.all(16.0),
              child: _buildHeader(context, theme),
            ),
          ],

          // Section content
          Padding(
            padding: padding ?? const EdgeInsets.all(16.0),
            child: child,
          ),

          // Bottom divider
          if (showDivider) const PolishedDivider.section(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    if (titleWidget != null) {
      return titleWidget!;
    }

    return GestureDetector(
      onTap: onTitleTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                if (title != null)
                  Text(
                    title!,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: AppThemePolish.lineHeightComfortable,
                      color: onTitleTap != null ? theme.colorScheme.primary : null,
                    ),
                  ),

                // Subtitle
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: AppThemePolish.lineHeightGenerous,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Trailing widget
          if (trailing != null) ...[
            const SizedBox(width: 16),
            trailing!,
          ],

          // Tap indicator
          if (onTitleTap != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ],
      ),
    );
  }
}

/// Enhanced section header with modern styling
class PolishedSectionHeader extends StatelessWidget {
  const PolishedSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showUnderline = false,
    this.underlineColor,
  });
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showUnderline;
  final Color? underlineColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: showUnderline
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: underlineColor ?? theme.colorScheme.primary,
                    width: 2.0,
                  ),
                ),
              )
            : null,
        child: Row(
          children: [
            // Leading widget
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ],

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: AppThemePolish.lineHeightComfortable,
                      color: onTap != null ? theme.colorScheme.primary : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: AppThemePolish.lineHeightGenerous,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Trailing widget
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],

            // Tap indicator
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
