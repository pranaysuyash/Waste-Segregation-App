import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'constants.dart';

/// Helper class for Material You dynamic colors with WCAG contrast validation
class DynamicThemeHelper {
  /// Minimum contrast ratio for WCAG AA compliance
  static const double minContrastRatio = 4.5;
  
  /// Fallback seed color for dynamic color generation
  static const Color fallbackSeedColor = Color(0xFF2E7D32); // App's primary green
  
  /// Generate dynamic light theme with WCAG contrast validation
  static ThemeData generateLightTheme(ColorScheme? dynamicColorScheme) {
    ColorScheme colorScheme;
    
    if (dynamicColorScheme != null) {
      // Use dynamic colors but validate contrast
      colorScheme = _validateAndAdjustContrast(
        dynamicColorScheme,
        Brightness.light,
      );
    } else {
      // Fallback to seed-based color scheme
      colorScheme = ColorScheme.fromSeed(
        seedColor: fallbackSeedColor,
        brightness: Brightness.light,
      );
    }
    
    return _buildThemeFromColorScheme(colorScheme, Brightness.light);
  }
  
  /// Generate dynamic dark theme with WCAG contrast validation
  static ThemeData generateDarkTheme(ColorScheme? dynamicColorScheme) {
    ColorScheme colorScheme;
    
    if (dynamicColorScheme != null) {
      // Use dynamic colors but validate contrast
      colorScheme = _validateAndAdjustContrast(
        dynamicColorScheme,
        Brightness.dark,
      );
    } else {
      // Fallback to seed-based color scheme
      colorScheme = ColorScheme.fromSeed(
        seedColor: fallbackSeedColor,
        brightness: Brightness.dark,
      );
    }
    
    return _buildThemeFromColorScheme(colorScheme, Brightness.dark);
  }
  
  /// Validate and adjust color scheme for WCAG contrast compliance
  static ColorScheme _validateAndAdjustContrast(
    ColorScheme scheme,
    Brightness brightness,
  ) {
    // Check primary color contrast
    final primaryContrast = _calculateContrast(
      scheme.primary,
      scheme.onPrimary,
    );
    
    // Check surface color contrast
    final surfaceContrast = _calculateContrast(
      scheme.surface,
      scheme.onSurface,
    );
    
    // If contrast is insufficient, fall back to seed-based scheme
    if (primaryContrast < minContrastRatio || surfaceContrast < minContrastRatio) {
      return ColorScheme.fromSeed(
        seedColor: scheme.primary.withValues(alpha: 1.0),
        brightness: brightness,
      );
    }
    
    return scheme;
  }
  
  /// Calculate contrast ratio between two colors
  static double _calculateContrast(Color color1, Color color2) {
    final luminance1 = color1.computeLuminance();
    final luminance2 = color2.computeLuminance();
    
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;
    
    return (lighter + 0.05) / (darker + 0.05);
  }
  
  /// Build complete theme from color scheme
  static ThemeData _buildThemeFromColorScheme(
    ColorScheme colorScheme,
    Brightness brightness,
  ) {
    final isLight = brightness == Brightness.light;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimary,
        ),
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: isLight ? 2 : 4,
        shadowColor: Colors.black.withValues(alpha: isLight ? 0.1 : 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.5);
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
      ),
      
      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        actionTextColor: colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
} 