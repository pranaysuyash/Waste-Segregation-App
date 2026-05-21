import 'package:flutter/material.dart';
import 'constants.dart';

/// Canonical waste-domain theme helpers.
///
/// Single source of truth for category→color, category→icon, confidence→color,
/// and bin→color mappings. Every screen and widget that displays waste-specific
/// colours or icons MUST use these helpers rather than redefining inline maps.
///
/// The previous duplication (in `classification_card.dart`,
/// `result_screen/classification_card.dart`, `modern_cards.dart`,
/// `combined_result_screen.dart`, and several other spots) created colour drift
/// and made light/dark-mode consistency fragile.  All callers should migrate
/// here so that a single palette change applies everywhere.
class WasteTheme {
  WasteTheme._();

  // ---------------------------------------------------------------------------
  // Category → colour  (also available as a static const map for batch use)
  // ---------------------------------------------------------------------------

  static const Map<String, Color> categoryColorMap = {
    'wet waste': AppTheme.wetWasteColor,
    'organic': AppTheme.wetWasteColor,
    'dry waste': AppTheme.dryWasteColor,
    'recyclable': AppTheme.dryWasteColor,
    'hazardous waste': AppTheme.hazardousWasteColor,
    'hazardous': AppTheme.hazardousWasteColor,
    'medical waste': AppTheme.medicalWasteColor,
    'medical': AppTheme.medicalWasteColor,
    'non-waste': AppTheme.nonWasteColor,
    'non waste': AppTheme.nonWasteColor,
    'e-waste': AppTheme.errorColor,
    'electronic': AppTheme.errorColor,
    'requires manual review': AppTheme.manualReviewColor,
  };

  /// Returns the canonical display colour for [category].
  static Color categoryColor(String category) {
    return categoryColorMap[category.toLowerCase().trim()] ??
        AppTheme.neutralColor;
  }

  // ---------------------------------------------------------------------------
  // Category → icon
  // ---------------------------------------------------------------------------

  static const Map<String, IconData> categoryIconMap = {
    'wet waste': Icons.eco,
    'organic': Icons.eco,
    'dry waste': Icons.recycling,
    'recyclable': Icons.recycling,
    'hazardous waste': Icons.warning,
    'hazardous': Icons.warning,
    'medical waste': Icons.medical_services,
    'medical': Icons.medical_services,
    'non-waste': Icons.check_circle,
    'non waste': Icons.check_circle,
    'e-waste': Icons.electrical_services,
    'electronic': Icons.electrical_services,
    'requires manual review': Icons.help_outline,
  };

  static IconData categoryIcon(String category) {
    return categoryIconMap[category.toLowerCase().trim()] ?? Icons.category;
  }

  // ---------------------------------------------------------------------------
  // Confidence → colour
  // ---------------------------------------------------------------------------

  /// Maps a confidence percentage (0-100) to a semantic colour.
  static Color confidenceColor(double confidencePercent) {
    if (confidencePercent >= 80) return AppTheme.successColor;
    if (confidencePercent >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  /// Maps a confidence 0.0-1.0 fraction to a semantic colour.
  static Color confidenceColorFromFraction(double confidenceFraction) {
    return confidenceColor((confidenceFraction * 100).clamp(0, 100));
  }

  // ---------------------------------------------------------------------------
  // Confidence → icon
  // ---------------------------------------------------------------------------

  static IconData confidenceIcon(double confidencePercent) {
    if (confidencePercent >= 80) return Icons.verified;
    if (confidencePercent >= 60) return Icons.help_outline;
    return Icons.warning_amber;
  }

  // ---------------------------------------------------------------------------
  // Bin colour (Indian / universal bin colour coding)
  // ---------------------------------------------------------------------------

  static const Color _greenBin = Color(0xFF06D6A0);
  static const Color _blueBin = Color(0xFF118AB2);
  static const Color _blackBin = Color(0xFF073B4C);
  static const Color _redBin = Color(0xFFEF476F);
  static const Color _yellowBin = Color(0xFFFFD166);

  static const Map<String, Color> binColorMap = {
    'green': _greenBin,
    'g': _greenBin,
    'wet': _greenBin,
    'blue': _blueBin,
    'b': _blueBin,
    'dry': _blueBin,
    'black': _blackBin,
    'k': _blackBin,
    'red': _redBin,
    'r': _redBin,
    'hazardous': _redBin,
    'yellow': _yellowBin,
    'y': _yellowBin,
    'medical': _yellowBin,
  };

  static Color binColor(String binLabel) {
    return binColorMap[binLabel.toLowerCase().trim()] ?? AppTheme.neutralColor;
  }

  /// Returns the best bin colour for a waste category.
  static Color binColorForCategory(String category) {
    switch (category.toLowerCase().trim()) {
      case 'wet waste':
      case 'organic':
        return _greenBin;
      case 'dry waste':
      case 'recyclable':
      case 'e-waste':
      case 'electronic':
        return _blueBin;
      case 'hazardous waste':
      case 'hazardous':
        return _redBin;
      case 'medical waste':
      case 'medical':
        return _yellowBin;
      case 'non-waste':
      case 'non waste':
        return _blueBin;
      default:
        return _blackBin;
    }
  }

  // ---------------------------------------------------------------------------
  // Disposal method → colour
  // ---------------------------------------------------------------------------

  static const Map<String, Color> disposalMethodColorMap = {
    'recycle': AppTheme.dryWasteColor,
    'compost': AppTheme.wetWasteColor,
    'landfill': AppTheme.neutralColor,
    'hazardous': AppTheme.hazardousWasteColor,
    'general': AppTheme.neutralColor,
  };

  static Color disposalMethodColor(String? method) {
    if (method == null) return AppTheme.neutralColor;
    return disposalMethodColorMap[method.toLowerCase().trim()] ??
        AppTheme.neutralColor;
  }

  // ---------------------------------------------------------------------------
  // Points / reward colour
  // ---------------------------------------------------------------------------

  static Color get pointsColor => AppTheme.rewardGold;

  // ---------------------------------------------------------------------------
  // Generic helpers
  // ---------------------------------------------------------------------------

  /// Returns a label for the given category that is suitable for Accessibility
  /// (Semantics) and human reading.
  static String categoryDisplayLabel(String category) {
    final lower = category.toLowerCase().trim();
    switch (lower) {
      case 'wet waste':
      case 'organic':
        return 'Wet Waste';
      case 'dry waste':
      case 'recyclable':
        return 'Dry Waste';
      case 'hazardous waste':
      case 'hazardous':
        return 'Hazardous Waste';
      case 'medical waste':
      case 'medical':
        return 'Medical Waste';
      case 'non-waste':
      case 'non waste':
        return 'Non-Waste';
      case 'e-waste':
      case 'electronic':
        return 'E-Waste';
      case 'requires manual review':
        return 'Requires Manual Review';
      default:
        return category;
    }
  }

  /// Builds a Semantics label for a waste category badge.
  static String categorySemanticsLabel(String category) {
    return 'Waste category: ${categoryDisplayLabel(category)}';
  }

  /// Builds a Semantics label for a confidence indicator.
  static String confidenceSemanticsLabel(double percent) {
    final pct = percent.round();
    if (pct >= 80) return 'High confidence: $pct percent';
    if (pct >= 60) return 'Medium confidence: $pct percent';
    return 'Low confidence: $pct percent';
  }

  /// Builds a Semantics label for a bin recommendation.
  static String binSemanticsLabel(String binLabel) {
    return 'Dispose in $binLabel bin';
  }
}
