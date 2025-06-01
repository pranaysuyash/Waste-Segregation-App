import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// A responsive dialog that adapts to different screen sizes
class ResponsiveDialog extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? actionsPadding;
  final MainAxisAlignment? actionsAlignment;
  final bool scrollable;
  final double? maxWidth;
  final double? maxHeight;

  const ResponsiveDialog({
    super.key,
    this.title,
    this.titleWidget,
    required this.content,
    this.actions,
    this.contentPadding,
    this.actionsPadding,
    this.actionsAlignment,
    this.scrollable = false,
    this.maxWidth,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isTablet = screenWidth >= 768;
    final isMobile = screenWidth < 600;

    // Determine dialog dimensions based on screen size
    final dialogWidth = maxWidth ?? (isTablet 
        ? screenWidth * 0.5 
        : isMobile 
            ? screenWidth * 0.9 
            : screenWidth * 0.6);
    
    final dialogHeight = maxHeight ?? (isMobile 
        ? screenHeight * 0.8 
        : screenHeight * 0.7);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: dialogHeight,
          maxWidth: dialogWidth,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title section
            if (title != null || titleWidget != null)
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingLarge),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: titleWidget ?? Text(
                  title!,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            // Content section
            Flexible(
              child: Container(
                padding: contentPadding ?? const EdgeInsets.all(AppTheme.paddingLarge),
                child: scrollable
                    ? SingleChildScrollView(
                        child: content,
                      )
                    : content,
              ),
            ),
            
            // Actions section
            if (actions != null && actions!.isNotEmpty)
              Container(
                padding: actionsPadding ?? const EdgeInsets.all(AppTheme.paddingLarge),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: actionsAlignment ?? MainAxisAlignment.end,
                  children: [
                    for (int i = 0; i < actions!.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppTheme.paddingSmall),
                      actions![i],
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Show a responsive dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
  }) {
    return showDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
    );
  }
} 