import 'package:flutter/material.dart';
import 'constants.dart';

/// Comprehensive UI consistency utilities to ensure standardized design across the app
class UIConsistency {
  
  // ==================== BUTTON STYLES ====================
  
  /// Primary action button style (for main CTAs)
  static ButtonStyle primaryButtonStyle(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final scaleFactor = textScaler.scale(AppTheme.fontSizeMedium);
    final scaledMinHeight = (AppTheme.buttonHeightMd * scaleFactor / AppTheme.fontSizeMedium).clamp(48.0, double.infinity);
    
    return ElevatedButton.styleFrom(
      elevation: AppTheme.elevationSm,
      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
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
      minimumSize: Size(0, scaledMinHeight),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return AppTheme.neutralColor;
          }
          if (states.contains(WidgetState.pressed)) {
            return AppTheme.primaryColor.withValues(alpha: 0.8);
          }
          return AppTheme.primaryColor;
        },
      ),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.white70;
          }
          return Colors.white;
        },
      ),
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withValues(alpha: 0.1);
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.white.withValues(alpha: 0.05);
          }
          return null;
        },
      ),
    );
  }
  
  /// Secondary action button style (for secondary CTAs)
  static ButtonStyle secondaryButtonStyle(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final scaleFactor = textScaler.scale(AppTheme.fontSizeMedium);
    final scaledMinHeight = (AppTheme.buttonHeightMd * scaleFactor / AppTheme.fontSizeMedium).clamp(48.0, double.infinity);
    
    return OutlinedButton.styleFrom(
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
      minimumSize: Size(0, scaledMinHeight),
    ).copyWith(
      foregroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return AppTheme.neutralColor;
          }
          if (states.contains(WidgetState.pressed)) {
            return AppTheme.primaryColor.withValues(alpha: 0.8);
          }
          return AppTheme.primaryColor;
        },
      ),
      side: WidgetStateProperty.resolveWith<BorderSide?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return const BorderSide(color: AppTheme.neutralColor, width: 1.5);
          }
          return const BorderSide(color: AppTheme.primaryColor, width: 1.5);
        },
      ),
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            return AppTheme.primaryColor.withValues(alpha: 0.1);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppTheme.primaryColor.withValues(alpha: 0.05);
          }
          return null;
        },
      ),
    );
  }
  
  /// Tertiary action button style (for text buttons)
  static ButtonStyle tertiaryButtonStyle(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final scaleFactor = textScaler.scale(AppTheme.fontSizeRegular);
    final scaledMinHeight = (AppTheme.buttonHeightMd * scaleFactor / AppTheme.fontSizeRegular).clamp(48.0, double.infinity);
    
    return TextButton.styleFrom(
      textStyle: const TextStyle(
        fontSize: AppTheme.fontSizeRegular,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingLarge,
        vertical: AppTheme.paddingMedium,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
      ),
      minimumSize: Size(0, scaledMinHeight),
    ).copyWith(
      foregroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return AppTheme.neutralColor;
          }
          if (states.contains(WidgetState.pressed)) {
            return AppTheme.primaryColor.withValues(alpha: 0.8);
          }
          return AppTheme.primaryColor;
        },
      ),
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            return AppTheme.primaryColor.withValues(alpha: 0.1);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppTheme.primaryColor.withValues(alpha: 0.05);
          }
          return null;
        },
      ),
    );
  }
  
  /// Destructive action button style (for delete, reset actions)
  static ButtonStyle destructiveButtonStyle(BuildContext context) {
    const destructiveColor = Color(0xFFD32F2F);
    
    final textScaler = MediaQuery.textScalerOf(context);
    final scaleFactor = textScaler.scale(AppTheme.fontSizeMedium);
    final scaledMinHeight = (AppTheme.buttonHeightMd * scaleFactor / AppTheme.fontSizeMedium).clamp(48.0, double.infinity);
    
    return ElevatedButton.styleFrom(
      elevation: AppTheme.elevationSm,
      shadowColor: destructiveColor.withValues(alpha: 0.3),
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
      minimumSize: Size(0, scaledMinHeight),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return AppTheme.neutralColor;
          }
          if (states.contains(WidgetState.pressed)) {
            return destructiveColor.withValues(alpha: 0.8);
          }
          return destructiveColor;
        },
      ),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.white70;
          }
          return Colors.white;
        },
      ),
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withValues(alpha: 0.1);
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.white.withValues(alpha: 0.05);
          }
          return null;
        },
      ),
    );
  }
  
  /// Success action button style (for confirm, save actions)
  static ButtonStyle successButtonStyle(BuildContext context) {
    const successColor = Color(0xFF2E7D32);
    
    final textScaler = MediaQuery.textScalerOf(context);
    final scaleFactor = textScaler.scale(AppTheme.fontSizeMedium);
    final scaledMinHeight = (AppTheme.buttonHeightMd * scaleFactor / AppTheme.fontSizeMedium).clamp(48.0, double.infinity);
    
    return ElevatedButton.styleFrom(
      elevation: AppTheme.elevationSm,
      shadowColor: successColor.withValues(alpha: 0.3),
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
      minimumSize: Size(0, scaledMinHeight),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return AppTheme.neutralColor;
          }
          if (states.contains(WidgetState.pressed)) {
            return successColor.withValues(alpha: 0.8);
          }
          return successColor;
        },
      ),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.white70;
          }
          return Colors.white;
        },
      ),
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withValues(alpha: 0.1);
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.white.withValues(alpha: 0.05);
          }
          return null;
        },
      ),
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
        final Widget button = ElevatedButton(
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
        final Widget button = OutlinedButton(
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
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
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
      fontSize: AppTheme.fontSizeExtraLarge,
      fontWeight: FontWeight.bold,
      fontFamily: theme.textTheme.headlineLarge?.fontFamily ?? 'Roboto',
      color: theme.textTheme.headlineLarge?.color ?? AppTheme.textPrimaryColor,
      letterSpacing: -0.5,
      height: 1.2,
    );
  }
  
  static TextStyle headingMedium(BuildContext context) {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w600,
      fontFamily: theme.textTheme.headlineMedium?.fontFamily ?? 'Roboto',
      color: theme.textTheme.headlineMedium?.color ?? AppTheme.textPrimaryColor,
      letterSpacing: -0.25,
      height: 1.3,
    );
  }
  
  static TextStyle headingSmall(BuildContext context) {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: AppTheme.fontSizeLarge,
      fontWeight: FontWeight.w600,
      fontFamily: theme.textTheme.headlineSmall?.fontFamily ?? 'Roboto',
      color: theme.textTheme.headlineSmall?.color ?? AppTheme.textPrimaryColor,
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
      fontFamily: theme.textTheme.bodyLarge?.fontFamily ?? 'Roboto',
      color: theme.textTheme.bodyLarge?.color ?? AppTheme.textPrimaryColor,
      height: 1.5,
    );
  }
  
  static TextStyle bodyMedium(BuildContext context) {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: AppTheme.fontSizeRegular,
      fontWeight: FontWeight.normal,
      fontFamily: theme.textTheme.bodyMedium?.fontFamily ?? 'Roboto',
      color: theme.textTheme.bodyMedium?.color ?? AppTheme.textPrimaryColor,
      height: 1.5,
    );
  }
  
  static TextStyle caption(BuildContext context) {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: AppTheme.fontSizeSmall,
      fontWeight: FontWeight.normal,
      fontFamily: theme.textTheme.bodySmall?.fontFamily ?? 'Roboto',
      color: theme.textTheme.bodySmall?.color ?? AppTheme.textSecondaryColor,
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