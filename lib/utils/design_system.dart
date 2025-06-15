import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Enhanced Design System for Waste Segregation App
/// Provides comprehensive theming, colors, typography, and component styles
class WasteAppDesignSystem {
  // Color Palette with Environmental Semantics
  static const Color primaryGreen = Color(0xFF2E7D4A);      // Forest Green
  static const Color secondaryGreen = Color(0xFF52C41A);    // Action Green  
  static const Color warningOrange = Color(0xFFFF9800);     // Warning Orange
  static const Color errorRed = Color(0xFFE53E3E);          // Alert Red
  static const Color surfaceWhite = Color(0xFFFAFAFA);      // Clean White
  static const Color textBlack = Color(0xFF1A1A1A);         // Rich Black
  static const Color lightGray = Color(0xFFF5F5F5);         // Light Surface
  static const Color mediumGray = Color(0xFFE9ECEF);        // Border Gray
  static const Color darkGray = Color(0xFF6C757D);          // Secondary Text

  // Waste Category Colors
  static const Color wetWasteColor = Color(0xFF4CAF50);     // Green
  static const Color dryWasteColor = Color(0xFF2196F3);     // Blue
  static const Color hazardousWasteColor = Color(0xFFFF5722); // Red-Orange
  static const Color medicalWasteColor = Color(0xFF9C27B0); // Purple
  static const Color nonWasteColor = Color(0xFF795548);     // Brown

  // Material 3 Color Scheme
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryGreen,
    onPrimary: Colors.white,
    secondary: secondaryGreen,
    onSecondary: Colors.white,
    tertiary: warningOrange,
    onTertiary: Colors.white,
    error: errorRed,
    onError: Colors.white,
    surface: surfaceWhite,
    onSurface: textBlack,
    surfaceContainerHighest: lightGray,
    onSurfaceVariant: darkGray,
    outline: mediumGray,
    shadow: Colors.black26,
    inverseSurface: textBlack,
    onInverseSurface: surfaceWhite,
    inversePrimary: Color(0xFF7BC984),
  );

  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF7BC984),
    onPrimary: Color(0xFF003919),
    secondary: Color(0xFF86E996),
    onSecondary: Color(0xFF00390E),
    tertiary: Color(0xFFFFB74D),
    onTertiary: Color(0xFF4A2800),
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF4A0000),
    surface: Color(0xFF121212),
    onSurface: Color(0xFFE0E0E0),
    surfaceContainerHighest: Color(0xFF1E1E1E),
    onSurfaceVariant: Color(0xFFB0B0B0),
    outline: Color(0xFF404040),
    shadow: Colors.black54,
    inverseSurface: Color(0xFFE0E0E0),
    onInverseSurface: Color(0xFF121212),
    inversePrimary: primaryGreen,
  );

  // Typography System
  static TextTheme get lightTextTheme => GoogleFonts.interTextTheme(
    TextTheme(
      // Display styles for hero content
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: textBlack,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: textBlack,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: textBlack,
      ),
      
      // Headline styles for section headers
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: textBlack,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.25,
        color: textBlack,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: textBlack,
      ),
      
      // Title styles for card headers
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: textBlack,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: textBlack,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: textBlack,
      ),
      
      // Body text styles
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.6,
        color: textBlack,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.5,
        color: textBlack,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.4,
        color: darkGray,
      ),
      
      // Label styles for buttons and form elements
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: textBlack,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: textBlack,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: darkGray,
      ),
    ),
  );

  static TextTheme get darkTextTheme => lightTextTheme.apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  );

  // Spacing System
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius System
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  // Elevation System
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 16.0;

  // Light Theme Configuration
  static ThemeData get lightTheme => ThemeData(
    colorScheme: lightColorScheme,
    textTheme: lightTextTheme,
    useMaterial3: true,
    
    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: lightColorScheme.surfaceContainerHighest,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha:0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingL,
          vertical: spacingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),
    
    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: spacingL,
          vertical: spacingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        side: const BorderSide(color: primaryGreen, width: 1.5),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightGray,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingM,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: mediumGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: mediumGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: errorRed, width: 2),
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: darkGray,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: darkGray,
      ),
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceWhite,
      selectedItemColor: primaryGreen,
      unselectedItemColor: darkGray,
      type: BottomNavigationBarType.fixed,
      elevation: elevationM,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
    
    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: elevationL,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
      ),
    ),
    
    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: lightGray,
      selectedColor: primaryGreen.withValues(alpha:0.2),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusS),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: spacingS,
        vertical: spacingXS,
      ),
    ),
    
    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceWhite,
      elevation: elevationXL,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXL),
      ),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textBlack,
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        color: textBlack,
      ),
    ),
    
    // Snack Bar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textBlack,
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusM),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: elevationM,
    ),
  );

  // Dark Theme Configuration
  static ThemeData get darkTheme => lightTheme.copyWith(
    colorScheme: darkColorScheme,
    textTheme: darkTextTheme,
    
    appBarTheme: lightTheme.appBarTheme.copyWith(
      backgroundColor: const Color(0xFF1E1E1E),
    ),
    
    cardTheme: lightTheme.cardTheme.copyWith(
      color: const Color(0xFF2C2C2C),
    ),
    
    inputDecorationTheme: lightTheme.inputDecorationTheme.copyWith(
      fillColor: const Color(0xFF2C2C2C),
    ),
    
    bottomNavigationBarTheme: lightTheme.bottomNavigationBarTheme.copyWith(
      backgroundColor: const Color(0xFF1E1E1E),
    ),
  );

  // Utility Methods for Category Colors
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'wet waste':
        return wetWasteColor;
      case 'dry waste':
        return dryWasteColor;
      case 'hazardous waste':
        return hazardousWasteColor;
      case 'medical waste':
        return medicalWasteColor;
      case 'non-waste':
        return nonWasteColor;
      default:
        return primaryGreen;
    }
  }

  // Shadow Styles
  static List<BoxShadow> getShadow(double elevation) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha:0.1),
        blurRadius: elevation * 2,
        offset: Offset(0, elevation),
      ),
    ];
  }

  // Container Decorations
  static BoxDecoration getCardDecoration({
    Color? color,
    double elevation = elevationS,
    double borderRadius = radiusM,
  }) {
    return BoxDecoration(
      color: color ?? surfaceWhite,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: getShadow(elevation),
    );
  }

  static BoxDecoration getCategoryDecoration(String category) {
    final categoryColor = getCategoryColor(category);
    return BoxDecoration(
      color: categoryColor.withValues(alpha:0.1),
      borderRadius: BorderRadius.circular(radiusM),
      border: Border.all(
        color: categoryColor.withValues(alpha:0.3),
      ),
    );
  }
}
