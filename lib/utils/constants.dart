import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- App Strings ---
class AppStrings {
  static const String appName = 'Waste Segregation App';
  
  // Welcome / Home
  static const String welcomeMessage = 'Identify waste items quickly and learn proper disposal methods.';
  static const String identifyWaste = 'Identify Waste';
  static const String camera = 'Camera';
  static const String gallery = 'Gallery';
  static const String learnMore = 'Learn More';
  static const String dailyTipTitle = 'Daily Waste Tip';
  static const String identifiedAs = 'Identified as:';
  static const String explanation = 'Explanation:';
  static const String examples = 'Examples:';
  static const String howToDispose = 'How to dispose:';
  static const String saveResult = 'Save Result';
  static const String shareResult = 'Share Result';
  static const String backToHome = 'Back to Home';
  static const String successSaved = 'Classification saved successfully!';
  static const String successShared = 'Result shared successfully!';

  // Auth
  static const String signInWithGoogle = 'Sign in with Google';
  static const String continueAsGuest = 'Continue as Guest';

  // Capture Button
  static const String captureImage = 'Capture Image';
  static const String uploadImage = 'Upload Image';
  static const String analyzeImage = 'Analyze Image';
  static const String retakePhoto = 'Retake Photo';
  static const String analyzing = 'Analyzing...';

  // Achievements
  static const String achievements = 'Achievements';
  static const String badges = 'Badges';
  static const String challenges = 'Challenges';
  static const String stats = 'Stats';
  static const String level = 'Level';
  static const String rank = 'Rank';
  static const String points = 'Points';
  static const String pointsEarned = 'points earned'; // Lowercase for sentence context
  static const String dailyStreak = 'Daily Streak';
  static const String progress = 'Progress';
  static const String viewAll = 'View All';
  static const String newAchievement = 'New Achievement!';

  // Add more strings as needed
}

// --- API Configuration ---
class ApiConfig {
  // Direct Gemini API endpoint for vision model
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  
  // API Key - Gemini API key
  static const String apiKey = 'AIzaSyDYXPY95PneMi0m7UTiI6ciY8sQyst2jV8';
  
  // Model to use - free tier with vision capabilities and good throughput
  static const String model = 'gemini-2.0-flash';
  
  // Headers for API request
  static Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
    };
  }
}

// --- Storage Keys ---
class StorageKeys {
  static const String classificationsBox = 'classifications';
  static const String gamificationBox = 'gamification';
  static const String educationalContentBox = 'educationalContent';
  static const String userInfoBox = 'userInfo';
  static const String appSettingsBox = 'appSettings';

  // UserInfo keys
  static const String userIdKey = 'userId';
  static const String userEmailKey = 'userEmail';
  static const String userDisplayNameKey = 'userDisplayName';

  // Settings keys
  static const String isDarkModeKey = 'isDarkMode';
  static const String isGoogleSyncEnabledKey = 'isGoogleSyncEnabled';
  static const String lastStreakUpdateKey = 'lastStreakUpdate';
  static const String lastSyncTimestampKey = 'lastSyncTimestamp';
}


// --- App Theme --- 
class AppTheme {
  // Padding and Radius
  static const double paddingSmall = 8.0;
  static const double paddingRegular = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingExtraLarge = 32.0;
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusRegular = 8.0;
  static const double borderRadiusLarge = 16.0;

  // Font Sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeRegular = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeExtraLarge = 24.0;

  // --- Refined Color Palette ---
  // Base Colors (Using slightly different shades for UI vs Categories)
  static const Color primaryColor = Color(0xFF388E3C); // Green 700
  static const Color secondaryColor = Color(0xFF1976D2); // Blue 700
  static const Color accentColor = Color(0xFFF57C00); // Orange 700 - Keep for accents if needed
  
  // Private base colors used in themes - keep in sync with above colors
  static const Color _primaryBase = Color(0xFF388E3C); // Same as primaryColor
  static const Color _secondaryBase = Color(0xFF1976D2); // Same as secondaryColor
  static const Color _accentBase = Color(0xFFF57C00); // Same as accentColor

  // Category Specific Colors (Using original 500 shades for distinction)
  static const Color wetWasteColor = Color(0xFF4CAF50); // Green 500
  static const Color dryWasteColor = Color(0xFF2196F3); // Blue 500
  static const Color hazardousWasteColor = Color(0xFFFF9800); // Orange 500
  static const Color medicalWasteColor = Color(0xFFF44336); // Red 500
  static const Color nonWasteColor = Color(0xFF607D8B); // Blue Grey 500
  
  // Text Colors
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textPrimaryLight = Color(0xFF212121); // Same as textPrimaryColor for compatibility
  static const Color textSecondaryLight = Color(0xFF757575); // Same as textSecondaryColor for compatibility
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFBDBDBD);
  
  // Background Colors
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardBackgroundLight = Color(0xFFF5F5F5);
  static const Color cardBackgroundDark = Color(0xFF1E1E1E);

  // --- Themes --- 
  static ThemeData get lightTheme {
    final baseTheme = ThemeData.light();
    final textTheme = GoogleFonts.latoTextTheme(baseTheme.textTheme);

    return baseTheme.copyWith(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor, // Use Orange 700 as tertiary
        error: medicalWasteColor,
        surface: backgroundLight, 
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: textPrimaryLight,
        onError: Colors.white,
        surfaceContainerHighest: cardBackgroundLight, // Use for card backgrounds etc
        outline: textSecondaryLight.withOpacity(0.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _primaryBase,
        foregroundColor: Colors.white, 
        elevation: 4,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: cardBackgroundLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusRegular),
        ),
         surfaceTintColor: Colors.transparent, // Avoid default tint
      ),
      textTheme: textTheme.copyWith(
            bodyMedium: textTheme.bodyMedium?.copyWith(color: textPrimaryLight),
            bodySmall: textTheme.bodySmall?.copyWith(color: textSecondaryLight),
            titleLarge: textTheme.titleLarge?.copyWith(color: textPrimaryLight), // AppBar title uses foregroundColor
            titleMedium: textTheme.titleMedium?.copyWith(color: textPrimaryLight),
            titleSmall: textTheme.titleSmall?.copyWith(color: textPrimaryLight),
            labelLarge: textTheme.labelLarge?.copyWith(color: Colors.white), // For Elevated Buttons
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBase,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusRegular),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          textStyle: textTheme.labelLarge, // Use themed text style
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryBase,
          side: BorderSide(color: _primaryBase),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusRegular),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
           textStyle: textTheme.labelLarge?.copyWith(color: _primaryBase), // Use themed text style
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _secondaryBase,
           textStyle: textTheme.labelLarge?.copyWith(color: _secondaryBase), // Use themed text style
        ),
      ),
      iconTheme: IconThemeData(
        color: _secondaryBase, 
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusRegular),
          borderSide: BorderSide(color: textSecondaryLight.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusRegular),
          borderSide: BorderSide(color: textSecondaryLight.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusRegular),
          borderSide: BorderSide(color: _primaryBase, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondaryLight),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _secondaryBase.withOpacity(0.1),
        labelStyle: textTheme.labelSmall?.copyWith(color: _secondaryBase, fontWeight: FontWeight.bold),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
        padding: EdgeInsets.symmetric(horizontal: paddingSmall, vertical: 4),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusLarge)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark();
    final textTheme = GoogleFonts.latoTextTheme(baseTheme.textTheme);

    return baseTheme.copyWith(
      primaryColor: primaryColor, // Keep primary vibrant
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor, // Use Orange 700 as tertiary
        error: medicalWasteColor,
        surface: cardBackgroundDark, // Use for card backgrounds etc
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: textPrimaryDark,
        onError: Colors.white,
        surfaceContainerHighest: cardBackgroundDark, // Use for card backgrounds etc
        outline: textSecondaryDark.withOpacity(0.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cardBackgroundDark, // Darker AppBar
        foregroundColor: textPrimaryDark, 
        elevation: 0, // Flat app bar for dark mode
        titleTextStyle: textTheme.titleLarge?.copyWith(color: textPrimaryDark),
      ),
      cardTheme: CardTheme(
        color: cardBackgroundDark,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusRegular),
        ),
        surfaceTintColor: Colors.transparent, // Avoid default tint
      ),
      textTheme: textTheme.copyWith(
            bodyMedium: textTheme.bodyMedium?.copyWith(color: textPrimaryDark),
            bodySmall: textTheme.bodySmall?.copyWith(color: textSecondaryDark),
            titleLarge: textTheme.titleLarge?.copyWith(color: textPrimaryDark),
            titleMedium: textTheme.titleMedium?.copyWith(color: textPrimaryDark),
            titleSmall: textTheme.titleSmall?.copyWith(color: textPrimaryDark),
            labelLarge: textTheme.labelLarge?.copyWith(color: Colors.white), // For Elevated Buttons
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBase,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusRegular),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          textStyle: textTheme.labelLarge, // Use themed text style
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryBase,
          side: BorderSide(color: _primaryBase),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusRegular),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          textStyle: textTheme.labelLarge?.copyWith(color: _primaryBase), // Use themed text style
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _secondaryBase,
           textStyle: textTheme.labelLarge?.copyWith(color: _secondaryBase), // Use themed text style
        ),
      ),
       iconTheme: IconThemeData(
        color: _secondaryBase, 
      ),
       inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundDark, // Or cardBackgroundDark
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusRegular),
          borderSide: BorderSide(color: textSecondaryDark.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusRegular),
          borderSide: BorderSide(color: textSecondaryDark.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusRegular),
          borderSide: BorderSide(color: _primaryBase, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondaryDark),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _secondaryBase.withOpacity(0.2),
        labelStyle: textTheme.labelSmall?.copyWith(color: _secondaryBase, fontWeight: FontWeight.bold),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
        padding: EdgeInsets.symmetric(horizontal: paddingSmall, vertical: 4),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: cardBackgroundDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusLarge)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
    );
  }
}


// --- Waste Category Info ---
class WasteInfo {
  // Examples for each waste category
  static const Map<String, String> categoryExamples = {
    'Wet Waste': 'Fruit peels, vegetable scraps, leftover food, coffee grounds, tea bags, eggshells, garden waste (leaves, grass clippings)',
    'Dry Waste': 'Paper (newspapers, cardboard, magazines), plastic bottles, plastic containers, glass bottles, metal cans, aluminum foil, Tetra Paks',
    'Hazardous Waste': 'Batteries, paints, solvents, pesticides, CFL bulbs, tube lights, electronic waste (e-waste), expired medicines',
    'Medical Waste': 'Used syringes, needles, soiled bandages, expired medicines (specific protocols apply), disposable masks, gloves',
    'Non-Waste': 'Items suitable for donation, edible food, reusable containers, items that can be repaired',
  };

  // Examples for specific subcategories (More specific)
  static const Map<String, String> subcategoryExamples = {
    'Food Waste': 'Vegetable peels, fruit cores, leftover cooked meals, meat scraps, dairy products',
    'Garden Waste': 'Grass clippings, leaves, small twigs, weeds',
    'Paper': 'Newspapers, office paper, junk mail, cardboard boxes, paper bags',
    'Plastic': 'PET bottles (water/soda), HDPE containers (milk jugs, detergent), PVC items, LDPE bags, PP containers (yogurt cups)',
    'Glass': 'Food jars, beverage bottles (clear, green, brown)',
    'Metal': 'Aluminum cans, steel food cans, empty aerosol cans, clean aluminum foil',
    'Electronic Waste': 'Old phones, laptops, chargers, cables, circuit boards, small appliances',
    'Batteries': 'AA, AAA, C, D, 9V, button cells, lithium-ion batteries',
    'Sharps': 'Needles, syringes, lancets',
    'Pharmaceutical': 'Expired or unused pills, liquid medicines, creams',
    'Reusable Items': 'Glass jars, plastic containers (if sturdy), fabric bags, usable clothing',
    'Edible Food': 'Untouched leftovers, surplus packaged food',
  };

  // Disposal instructions for each waste category
  static const Map<String, String> disposalInstructions = {
    'Wet Waste': 'Collect in a separate bin, preferably lined with paper or a compostable bag. Can be composted at home or given to municipal composting facilities. Avoid adding diseased plants or meat scraps to home compost unless experienced.',
    'Dry Waste': 'Clean and dry items before disposal. Separate paper, plastic, glass, and metal if required by local collection services. Check local recycling guidelines for specific plastic types.',
    'Hazardous Waste': 'Never dispose of in regular bins or drains. Find designated collection points or hazardous waste disposal events in your area. Store safely until disposal.',
    'Medical Waste': 'Use designated sharps containers for needles. Follow local regulations for disposal, often involving special collection services or drop-off points. Do not mix with regular waste.',
    'Non-Waste': 'Donate usable items to charity. Offer edible food through food banks or community fridges. Repair broken items if possible. Find creative ways to reuse containers.',
  };
  
  // Disposal instructions for specific subcategories (More specific)
  // NOTE: Fixed syntax error - removed curly braces around the map literal value
  static const Map<String, String> subcategoryDisposal = {
    'Food Waste': 'Best composted. If composting is not available, double-bag and place in general waste bin designated for wet waste.',
    'Garden Waste': 'Compost at home or use municipal green waste collection services. Avoid composting diseased plants.',
    'Paper': 'Keep dry and clean. Remove plastic windows from envelopes. Flatten cardboard boxes. Check if pizza boxes (clean parts) are accepted.',
    'Plastic': 'Check the recycling code (1-7). Rinse containers. Many local programs accept #1 (PET) and #2 (HDPE). Check local rules for others.',
    'Glass': 'Rinse bottles and jars. Remove lids (metal lids can often be recycled separately). Check if different colors need separation.',
    'Metal': 'Rinse cans. Aluminum cans are highly recyclable. Steel cans are also recyclable. Check local guidelines for foil and aerosol cans.',
    'Electronic Waste': 'Find dedicated e-waste recycling centers or collection events. Data sanitization is recommended for devices containing personal information.',
    'Batteries': 'Do not put in regular trash or recycling. Many retail stores and municipal centers have battery collection bins.',
    'Sharps': 'Place immediately into an FDA-cleared sharps disposal container. Seal container when 3/4 full. Follow community guidelines for disposal (drop-off sites, mail-back programs).',
    'Pharmaceutical': 'Use drug take-back programs if available. If not, mix medication (do not crush tablets) with undesirable substance (dirt, coffee grounds), place in sealed bag, and put in trash.',
    'Reusable Items': 'Clean before donating or reusing. Check charity shop requirements.',
    'Edible Food': 'Offer to food banks, shelters, or community fridges promptly. Ensure food is safe and properly stored.',
  };

  // Plastic Recycling Codes
  static const Map<String, String> recyclingCodes = {
    '1': 'PET (Polyethylene Terephthalate): Commonly used for beverage bottles and food jars. Widely recyclable.',
    '2': 'HDPE (High-Density Polyethylene): Used for milk jugs, detergent bottles, and some toys. Widely recyclable.',
    '3': 'PVC (Polyvinyl Chloride): Found in plumbing pipes, some packaging films, and window profiles. Less commonly recycled.',
    '4': 'LDPE (Low-Density Polyethylene): Used for plastic bags, films, and squeeze bottles. Recyclability varies by location.',
    '5': 'PP (Polypropylene): Used for yogurt containers, bottle caps, and some food containers. Increasingly recyclable.',
    '6': 'PS (Polystyrene): Includes Styrofoam, disposable cups, and cutlery. Difficult to recycle; often not accepted.',
    '7': 'Other: Includes various plastics like polycarbonate (PC), acrylic, and bioplastics. Recyclability is rare.',
  };
}

// Extension on Color to add withValues method
extension ColorExtensions on Color {
  Color withValues({double? opacity, double? alpha, double lightness = 1.0, double saturation = 1.0}) {
    // Convert to HSL
    final HSLColor hsl = HSLColor.fromColor(this);
    
    // Use alpha if provided, otherwise use opacity, defaulting to 1.0 if neither is provided
    final double opacityValue = alpha ?? opacity ?? 1.0;
    
    // Apply scaling factors
    final HSLColor adjusted = HSLColor.fromAHSL(
      opacityValue * hsl.alpha,
      hsl.hue,
      saturation * hsl.saturation,
      lightness * hsl.lightness,
    );
    
    // Convert back to Color
    return adjusted.toColor();
  }
}
