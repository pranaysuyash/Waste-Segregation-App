import 'package:flutter/material.dart';
import 'constants.dart';

/// Comprehensive UI consistency utilities to ensure standardized design across the app
class UIConsistency {
  
  // ==================== BUTTON STYLES ====================
  
  /// Primary action button style (for main CTAs)
  static ButtonStyle primaryButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: AppTheme.elevationSm,
      shadowColor: AppTheme.primaryColor.withOpacity(0.3),
      textStyle: const TextStyle(
        fontSize: AppTheme.fontSizeMedium,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingLarge,
        vertical: AppTheme.paddingMedium,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
      ),
      minimumSize: const Size(0, AppTheme.buttonHeightMd),
    );
  }
  
  /// Secondary action button style (for secondary CTAs)
  static ButtonStyle secondaryButtonStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppTheme.primaryColor,
      side: const BorderSide(
        color: AppTheme.primaryColor,
        width: 1.5,
      ),
      textStyle: const TextStyle(
        fontSize: AppTheme.fontSizeMedium,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingLarge,
        vertical: AppTheme.paddingMedium,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
      ),
      minimumSize: const Size(0, AppTheme.buttonHeightMd),
    );
  }
  
  /// Tertiary action button style (for text buttons)
  static ButtonStyle tertiaryButtonStyle(BuildContext context) {
    return TextButton.styleFrom(
      foregroundColor: AppTheme.primaryColor,
      textStyle: const TextStyle(
        fontSize: AppTheme.fontSizeRegular,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
      ),
      minimumSize: const Size(0, AppTheme.buttonHeightSm),
    );
  }
  
  /// Destructive action button style (for delete, reset actions)
  static ButtonStyle destructiveButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppTheme.errorColor,
      foregroundColor: Colors.white,
      elevation: AppTheme.elevationSm,
      shadowColor: AppTheme.errorColor.withOpacity(0.3),
      textStyle: const TextStyle(
        fontSize: AppTheme.fontSizeMedium,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingLarge,
        vertical: AppTheme.paddingMedium,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
      ),
      minimumSize: const Size(0, AppTheme.buttonHeightMd),
    );
  }
  
  /// Success action button style (for confirm, save actions)
  static ButtonStyle successButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppTheme.successColor,
      foregroundColor: Colors.white,
      elevation: AppTheme.elevationSm,
      shadowColor: AppTheme.successColor.withOpacity(0.3),
      textStyle: const TextStyle(
        fontSize: AppTheme.fontSizeMedium,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingLarge,
        vertical: AppTheme.paddingMedium,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
      ),
      minimumSize: const Size(0, AppTheme.buttonHeightMd),
    );
  }
  
  // ==================== STANDARDIZED BUTTON WIDGETS ====================
  
  /// Standard primary button widget
  static Widget primaryButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isExpanded = false,
    bool isLoading = false,
  }) {
    return Builder(
      builder: (context) {
        Widget button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: primaryButtonStyle(context),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: AppTheme.iconSizeMd),
                      const SizedBox(width: AppTheme.spacingSm),
                    ],
                    Text(text),
                  ],
                ),
        );
        
        return isExpanded ? SizedBox(width: double.infinity, child: button) : button;
      },
    );
  }
  
  /// Standard secondary button widget
  static Widget secondaryButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isExpanded = false,
  }) {
    return Builder(
      builder: (context) {
        Widget button = OutlinedButton(
          onPressed: onPressed,
          style: secondaryButtonStyle(context),
          child: Row(
            mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppTheme.iconSizeMd),
                const SizedBox(width: AppTheme.spacingSm),
              ],
              Text(text),
            ],
          ),
        );
        
        return isExpanded ? SizedBox(width: double.infinity, child: button) : button;
      },
    );
  }
  
  /// Standard view all button widget
  static Widget viewAllButton({
    required String text,
    required VoidCallback onPressed,
    IconData icon = Icons.arrow_forward,
  }) {
    return Builder(
      builder: (context) {
        return TextButton.icon(
          onPressed: onPressed,
          style: tertiaryButtonStyle(context),
          icon: Icon(icon, size: AppTheme.iconSizeSm),
          label: Text(text),
        );
      },
    );
  }
  
  // ==================== CARD STYLES ====================
  
  /// Standard card decoration
  static BoxDecoration standardCardDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
         return BoxDecoration(
       color: isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
       borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
       boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
          blurRadius: AppTheme.elevationMd,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  
  /// Standard card widget
  static Widget standardCard({
    required Widget child,
    EdgeInsets? padding,
    VoidCallback? onTap,
  }) {
    return Builder(
      builder: (context) {
        return Container(
          decoration: standardCardDecoration(context),
          child: Material(
            color: Colors.transparent,
                         child: InkWell(
               onTap: onTap,
               borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
               child: Padding(
                padding: padding ?? const EdgeInsets.all(AppTheme.paddingMedium),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
  
  // ==================== TYPOGRAPHY STYLES ====================
  
  /// Standard heading styles
  static TextStyle headingLarge(BuildContext context) {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: AppTheme.fontSizeLarge,
      fontWeight: FontWeight.bold,
      color: theme.textTheme.headlineLarge?.color,
      letterSpacing: -0.5,
      height: 1.2,
    );
  }
  
  static TextStyle headingMedium(BuildContext context) {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: AppTheme.fontSizeLarge,
      fontWeight: FontWeight.w600,
      color: theme.textTheme.headlineMedium?.color,
      letterSpacing: -0.25,
      height: 1.3,
    );
  }
  
  static TextStyle headingSmall(BuildContext context) {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: AppTheme.fontSizeMedium,
      fontWeight: FontWeight.w600,
      color: theme.textTheme.headlineSmall?.color,
      letterSpacing: 0,
      height: 1.4,
    );
  }
  
  /// Standard body text styles
  static TextStyle bodyLarge(BuildContext context) {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: AppTheme.fontSizeMedium,
      fontWeight: FontWeight.normal,
      color: theme.textTheme.bodyLarge?.color,
      height: 1.5,
    );
  }
  
  static TextStyle bodyMedium(BuildContext context) {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: AppTheme.fontSizeRegular,
      fontWeight: FontWeight.normal,
      color: theme.textTheme.bodyMedium?.color,
      height: 1.5,
    );
  }
  
  static TextStyle caption(BuildContext context) {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: AppTheme.fontSizeSmall,
      fontWeight: FontWeight.normal,
      color: theme.textTheme.bodySmall?.color,
      height: 1.4,
    );
  }
  
  // ==================== ICON STANDARDS ====================
  
  /// Standardized icon sizes
  static const double iconSizeSmall = AppTheme.iconSizeSm;
  static const double iconSizeMedium = AppTheme.iconSizeMd;
  static const double iconSizeLarge = AppTheme.iconSizeLg;
  static const double iconSizeExtraLarge = AppTheme.iconSizeXl;
  
  /// Standardized icon color for different contexts
  static Color iconColorPrimary(BuildContext context) {
    return Theme.of(context).iconTheme.color ?? AppTheme.primaryColor;
  }
  
  static Color iconColorSecondary(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
  
  static Color iconColorDisabled(BuildContext context) {
    return Theme.of(context).disabledColor;
  }
  
  // ==================== SPACING STANDARDS ====================
  
  /// Standard spacing constants
  static const double spacingTiny = AppTheme.spacingXs;
  static const double spacingSmall = AppTheme.spacingSm;
  static const double spacingMedium = AppTheme.spacingMd;
  static const double spacingLarge = AppTheme.spacingLg;
  static const double spacingExtraLarge = AppTheme.spacingXl;
  
  /// Standard padding constants
  static const double paddingTiny = AppTheme.paddingMicro;
  static const double paddingSmall = AppTheme.paddingSmall;
  static const double paddingMedium = AppTheme.paddingMedium;
  static const double paddingLarge = AppTheme.paddingLarge;
  static const double paddingExtraLarge = AppTheme.paddingExtraLarge;
  
  // ==================== MODAL/DIALOG STANDARDS ====================
  
  /// Standard dialog actions
  static List<Widget> dialogActions({
    required BuildContext context,
    required String cancelText,
    required String confirmText,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    bool isDestructive = false,
  }) {
    return [
      TextButton(
        onPressed: onCancel,
        style: AppTheme.dialogCancelButtonStyle(context),
        child: Text(cancelText),
      ),
      const SizedBox(width: AppTheme.spacingSm),
      ElevatedButton(
        onPressed: onConfirm,
        style: isDestructive 
            ? destructiveButtonStyle(context) 
            : primaryButtonStyle(context),
        child: Text(confirmText),
      ),
    ];
  }
  
  /// Standard dialog padding
  static const EdgeInsets dialogPadding = EdgeInsets.all(AppTheme.paddingLarge);
  
  /// Standard dialog title style
  static TextStyle dialogTitleStyle(BuildContext context) {
    return headingMedium(context);
  }
  
  /// Standard dialog content style
  static TextStyle dialogContentStyle(BuildContext context) {
    return bodyMedium(context);
  }
  
  // ==================== COLOR CONSISTENCY ====================
  
  /// Waste category colors (standardized)
  static const Map<String, Color> wasteCategoryColors = {
    'Wet Waste': Color(0xFF4CAF50), // Green
    'Dry Waste': Color(0xFFFFC107), // Amber
    'Hazardous Waste': Color(0xFFFF5722), // Deep Orange
    'Medical Waste': Color(0xFFF44336), // Red
    'E-Waste': Color(0xFF9C27B0), // Purple
    'Non-Waste': Color(0xFF607D8B), // Blue Grey
  };
  
  /// Get standardized category color
  static Color getCategoryColor(String category) {
    return wasteCategoryColors[category] ?? AppTheme.neutralColor;
  }
  
  /// Status colors
  static const Color successColor = AppTheme.successColor;
  static const Color warningColor = AppTheme.warningColor;
  static const Color errorColor = AppTheme.errorColor;
  static const Color infoColor = AppTheme.infoColor;
  
  // ==================== ACCESSIBILITY HELPERS ====================
  
  /// Ensure minimum touch target size
  static Widget ensureTouchTarget({
    required Widget child,
    double minSize = 44.0,
  }) {
    return SizedBox(
      width: minSize,
      height: minSize,
      child: Center(child: child),
    );
  }
  
  /// Add semantic label for accessibility
  static Widget withSemantics({
    required Widget child,
    required String label,
    String? hint,
    bool isButton = false,
    bool isEnabled = true,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      enabled: isEnabled,
      child: child,
    );
  }
} 