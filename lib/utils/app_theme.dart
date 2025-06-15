import 'package:flutter/material.dart';

/// Enhanced UI polish constants for modern app feel
class AppThemePolish {
  // Enhanced spacing for better visual hierarchy
  static const double spacingGenerous = 20.0;  // Between major sections
  static const double spacingComfortable = 28.0; // For premium feel
  static const double spacingLuxurious = 36.0;   // For hero sections

  // Modern shadow system
  static const double elevationSubtle = 1.0;
  static const double elevationModerate = 2.0;
  static const double elevationProminent = 4.0;
  
  // Shadow colors for modern depth
  static Color shadowColorLight = Colors.black.withValues(alpha: 0.05);
  static Color shadowColorMedium = Colors.black.withValues(alpha: 0.08);
  static Color shadowColorStrong = Colors.black.withValues(alpha: 0.12);

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 350);

  // Micro-interaction scales
  static const double scalePressed = 0.97;
  static const double scaleHover = 1.02;

  // Enhanced typography line heights
  static const double lineHeightComfortable = 1.4;
  static const double lineHeightGenerous = 1.5;
  static const double lineHeightLuxurious = 1.6;

  // Accent colors for CTAs
  static const Color accentVibrant = Color(0xFF00BCD4); // Cyan accent
  static const Color accentWarm = Color(0xFFFF6B35);    // Orange accent
  static const Color accentCool = Color(0xFF6C5CE7);    // Purple accent
} 