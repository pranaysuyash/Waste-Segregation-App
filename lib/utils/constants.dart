import 'package:flutter/material.dart';

// API Configuration
class ApiConfig {
  // Gemini API via OpenAI-compatible endpoint
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/openai';
  
  // API Key - Gemini API key
  static const String apiKey = 'AIzaSyDYXPY95PneMi0m7UTiI6ciY8sQyst2jV8';
  
  // Model to use - free tier with vision capabilities and good throughput
  static const String model = 'gemini-2.0-flash';
  
  // OpenAI API Configuration (Fallback)
  static const String openAiBaseUrl = 'https://api.openai.com/v1';
  static const String openAiApiKey = 'YOUR_OPENAI_API_KEY'; // Replace with actual key in production
  static const String openAiModel = 'gpt-4-vision-preview'; // Vision-capable model
}

// Local Storage Keys
class StorageKeys {
  static const String userBox = 'userBox';
  static const String classificationsBox = 'classificationsBox';
  static const String settingsBox = 'settingsBox';
  /// Box for caching image classification results by hash
  static const String cacheBox = 'cacheBox';
  static const String gamificationBox = 'gamificationBox';
  static const String userIdKey = 'userId';
  static const String userEmailKey = 'userEmail';
  static const String userDisplayNameKey = 'userDisplayName';
  static const String isDarkModeKey = 'isDarkMode';
  static const String isGoogleSyncEnabledKey = 'isGoogleSyncEnabled';
  static const String userGamificationProfileKey = 'userGamificationProfile';
  static const String achievementsKey = 'achievements';
  static const String streakKey = 'streak';
  static const String pointsKey = 'points';
  static const String challengesKey = 'challenges';
  static const String weeklyStatsKey = 'weeklyStats';
}

// App Theme Constants
class AppTheme {
  // Light Theme Colors
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color secondaryColor = Color(0xFF2196F3);
  static const Color accentColor = Color(0xFFFF9800);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  
  // Dark Theme Colors
  static const Color darkPrimaryColor = Color(0xFF388E3C);
  static const Color darkSecondaryColor = Color(0xFF1976D2);
  static const Color darkAccentColor = Color(0xFFFFA726);
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkTextPrimaryColor = Color(0xFFFFFFFF);
  static const Color darkTextSecondaryColor = Color(0xFFBDBDBD);
  
  // Category Colors
  static const Color wetWasteColor = Color(0xFF4CAF50); // Green
  static const Color dryWasteColor = Color(0xFF2196F3); // Blue
  static const Color hazardousWasteColor = Color(0xFFFF5722); // Deep Orange
  static const Color medicalWasteColor = Color(0xFFF44336); // Red
  static const Color nonWasteColor = Color(0xFF9C27B0); // Purple
  
  // Font Sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeRegular = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeExtraLarge = 24.0;
  
  // Padding and Margin
  static const double paddingSmall = 8.0;
  static const double paddingRegular = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingExtraLarge = 32.0;
  
  // Border Radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusRegular = 8.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusExtraLarge = 24.0;
}

// App String Constants
class AppStrings {
  // App Title
  static const String appName = 'Waste Segregation';
  
  // Auth Screen
  static const String signInWithGoogle = 'Sign in with Google';
  static const String continueAsGuest = 'Continue as Guest';
  static const String welcomeMessage = 'Learn to segregate waste correctly';
  
  // Home Screen
  static const String captureImage = 'Capture Image';
  static const String uploadImage = 'Upload Image';
  static const String dailyChallenge = 'Daily Challenge';
  static const String learnMore = 'Learn More';
  static const String history = 'History';
  static const String settings = 'Settings';
  
  // Image Capture Screen
  static const String analyzeImage = 'Analyze Image';
  static const String retakePhoto = 'Retake Photo';
  static const String analyzing = 'Analyzing...';
  
  // Result Screen
  static const String identifiedAs = 'Identified As';
  static const String category = 'Category';
  static const String explanation = 'Explanation';
  static const String saveResult = 'Save Result';
  static const String shareResult = 'Share Result';
  static const String backToHome = 'Back to Home';
  
  // Error Messages
  static const String errorCamera = 'Unable to access camera';
  static const String errorGallery = 'Unable to access gallery';
  static const String errorAnalysis = 'Failed to analyze image';
  static const String errorNetwork = 'Network error. Please check your connection';
  static const String errorGeneral = 'Something went wrong';
  
  // Success Messages
  static const String successSaved = 'Result saved successfully';
  static const String successShared = 'Result shared successfully';
  static const String successSync = 'Data synced to Google Drive';
  
  // Gamification Strings
  static const String achievements = 'Achievements';
  static const String badges = 'Badges';
  static const String challenges = 'Challenges';
  static const String dailyStreak = 'Daily Streak';
  static const String level = 'Level';
  static const String points = 'Points';
  static const String rank = 'Rank';
  static const String leaderboard = 'Leaderboard';
  static const String stats = 'Stats';
  static const String rewards = 'Rewards';
  static const String streakMaintained = 'Streak Maintained';
  static const String newAchievement = 'New Achievement';
  static const String challengeCompleted = 'Challenge Completed';
  static const String levelUp = 'Level Up';
  static const String pointsEarned = 'Points Earned';
  static const String progress = 'Progress';
  static const String viewAll = 'View All';
  static const String completeChallenge = 'Complete Challenge';
}

// Waste Category Descriptions for Education
// Material Icons constants
class AppIcons {
  // Standard icons used throughout the app
  static const IconData emojiObjects = IconData(0xe23e, fontFamily: 'MaterialIcons');
  static const IconData recycling = IconData(0xe7c0, fontFamily: 'MaterialIcons');
  static const IconData workspacePremium = IconData(0xef56, fontFamily: 'MaterialIcons');
  static const IconData category = IconData(0xe574, fontFamily: 'MaterialIcons');
  static const IconData localFireDepartment = IconData(0xe78d, fontFamily: 'MaterialIcons');
  static const IconData eventAvailable = IconData(0xe614, fontFamily: 'MaterialIcons');
  static const IconData emojiEvents = IconData(0xea65, fontFamily: 'MaterialIcons');
  static const IconData school = IconData(0xe80c, fontFamily: 'MaterialIcons');
  static const IconData quiz = IconData(0xf04c, fontFamily: 'MaterialIcons');
  static const IconData eco = IconData(0xe63f, fontFamily: 'MaterialIcons');
  static const IconData taskAlt = IconData(0xe8fe, fontFamily: 'MaterialIcons');
  static const IconData shoppingBag = IconData(0xf1cc, fontFamily: 'MaterialIcons');
  static const IconData restaurant = IconData(0xe56c, fontFamily: 'MaterialIcons');
  static const IconData compost = IconData(0xe761, fontFamily: 'MaterialIcons');
  static const IconData warning = IconData(0xe002, fontFamily: 'MaterialIcons');
  static const IconData medicalServices = IconData(0xe95a, fontFamily: 'MaterialIcons');
  static const IconData autorenew = IconData(0xe5d5, fontFamily: 'MaterialIcons');
  static const IconData description = IconData(0xe873, fontFamily: 'MaterialIcons');
  static const IconData waterDrop = IconData(0xef71, fontFamily: 'MaterialIcons');
  static const IconData hardware = IconData(0xe890, fontFamily: 'MaterialIcons');
  static const IconData devices = IconData(0xe1b4, fontFamily: 'MaterialIcons');
  static const IconData autoAwesome = IconData(0xe65f, fontFamily: 'MaterialIcons');
  static const IconData militaryTech = IconData(0xe3d0, fontFamily: 'MaterialIcons');
  static const IconData stars = IconData(0xe8d0, fontFamily: 'MaterialIcons');
  static const IconData search = IconData(0xe8b6, fontFamily: 'MaterialIcons');
  static const IconData verified = IconData(0xef76, fontFamily: 'MaterialIcons');
  static const IconData timerOutlined = IconData(0xef71, fontFamily: 'MaterialIcons');
  static const IconData barChart = IconData(0xe26b, fontFamily: 'MaterialIcons');
  
  // Icon mapping for string to IconData conversion
  static IconData fromString(String iconName) {
    switch (iconName) {
      case 'emoji_objects': return emojiObjects;
      case 'recycling': return recycling;
      case 'workspace_premium': return workspacePremium;
      case 'category': return category;
      case 'local_fire_department': return localFireDepartment;
      case 'event_available': return eventAvailable;
      case 'emoji_events': return emojiEvents;
      case 'school': return school;
      case 'quiz': return quiz;
      case 'eco': return eco;
      case 'task_alt': return taskAlt;
      case 'shopping_bag': return shoppingBag;
      case 'restaurant': return restaurant;
      case 'compost': return compost;
      case 'warning': return warning;
      case 'medical_services': return medicalServices;
      case 'autorenew': return autorenew;
      case 'description': return description;
      case 'water_drop': return waterDrop;
      case 'hardware': return hardware;
      case 'devices': return devices;
      case 'auto_awesome': return autoAwesome;
      case 'military_tech': return militaryTech;
      case 'stars': return stars;
      case 'search': return search;
      case 'verified': return verified;
      case 'timer_outlined': return timerOutlined;
      case 'bar_chart': return barChart;
      default: return autorenew; // Default to refresh icon
    }
  }
}

class WasteInfo {
  static const Map<String, String> categoryExamples = {
    'Wet Waste': 'Food scraps, fruit peels, vegetable waste, garden trimmings, tea bags, coffee grounds',
    'Dry Waste': 'Paper, cardboard, plastic bottles, glass bottles, metal cans, tetra packs',
    'Hazardous Waste': 'Batteries, electronic items, lightbulbs, paint cans, aerosol cans, chemicals',
    'Medical Waste': 'Medicine, bandages, syringes, expired medicines, blood-soaked items',
    'Non-Waste': 'Reusable items, items for donation, functional electronics, books, toys',
  };
  
  static const Map<String, String> disposalInstructions = {
    'Wet Waste': 'Dispose in green bin. Can be composted to create nutrient-rich soil.',
    'Dry Waste': 'Dispose in blue bin. Can be recycled into new products.',
    'Hazardous Waste': 'Do not mix with regular waste. Take to designated collection centers.',
    'Medical Waste': 'Seal in special bags and dispose according to local medical waste guidelines.',
    'Non-Waste': 'Consider donating, reusing, or repurposing instead of disposing.',
  };
  
  // Maps subcategories to examples
  static const Map<String, String> subcategoryExamples = {
    // Wet Waste Subcategories
    'Food Waste': 'Fruit peels, vegetable scraps, leftover food, spoiled food, eggshells, bones',
    'Garden Waste': 'Grass clippings, leaves, small branches, flowers, plant trimmings',
    'Animal Waste': 'Pet waste, manure, bedding material from pet cages',
    'Biodegradable Packaging': 'Paper bags, compostable food containers, biodegradable plastics',
    'Other Wet Waste': 'Soiled paper towels, tissues, natural cork, sawdust',
    
    // Dry Waste Subcategories
    'Paper': 'Newspapers, magazines, office paper, envelopes, books, paper bags',
    'Plastic': 'Plastic bottles, containers, packaging, toys, utensils (with recycling codes)',
    'Glass': 'Glass bottles, jars, containers (clear, green, brown)',
    'Metal': 'Aluminum cans, steel cans, foil, scrap metal, bottle caps',
    'Carton': 'Milk cartons, juice boxes, tetra packs, cardboard boxes',
    'Textile': 'Clothing, fabrics, curtains, bedsheets, towels (clean and dry)',
    'Rubber': 'Rubber bands, erasers, non-tire rubber products',
    'Wood': 'Wooden items, furniture pieces, crates, untreated lumber',
    'Other Dry Waste': 'Mixed materials, ceramics, leather items',
    
    // Hazardous Waste Subcategories
    'Electronic Waste': 'Old computers, phones, TVs, cables, chargers, electronic devices',
    'Batteries': 'Car batteries, household batteries, lithium-ion batteries, button cells',
    'Chemical Waste': 'Cleaning products, pesticides, herbicides, solvents, pool chemicals',
    'Paint Waste': 'Paint cans, thinners, varnishes, stains, paint removers',
    'Light Bulbs': 'Fluorescent tubes, CFLs, LED bulbs, halogen bulbs',
    'Aerosol Cans': 'Spray paints, deodorants, air fresheners, insecticides',
    'Automotive Waste': 'Motor oil, antifreeze, brake fluid, filters, wiper fluid',
    'Other Hazardous Waste': 'Thermometers, barometers, smoke detectors',
    
    // Medical Waste Subcategories
    'Sharps': 'Needles, syringes, lancets, scalpels, broken glass',
    'Pharmaceutical': 'Expired medications, unused medicines, vitamins, supplements',
    'Infectious': 'Bandages, swabs, gloves contaminated with blood or bodily fluids',
    'Non-Infectious': 'Unused medical supplies, packaging from medical devices',
    'Other Medical Waste': 'Medical devices, testing kits, first aid materials',
    
    // Non-Waste Subcategories
    'Reusable Items': 'Containers, water bottles, shopping bags, utensils',
    'Donatable Items': 'Clothes, toys, books, furniture in good condition',
    'Edible Food': 'Unexpired packaged food, fresh produce, canned goods',
    'Repurposable Items': 'Glass jars, paper scraps for crafts, old furniture for upcycling',
    'Other Non-Waste': 'Materials that can be shared or reused in community programs',
  };
  
  // Maps subcategories to disposal instructions
  static const Map<String, String> subcategoryDisposal = {
    // Wet Waste Subcategories
    'Food Waste': 'Compost in a compost bin or dispose in green bin. Keep meat and dairy separate if specified by local guidelines.',
    'Garden Waste': 'Compost or dispose in green bin. Large branches may need to be cut into smaller pieces.',
    'Animal Waste': 'Check local regulations. Some areas allow disposal in green bins, others require special handling.',
    'Biodegradable Packaging': 'Ensure packaging is certified compostable before adding to compost. Otherwise, dispose in green bin.',
    'Other Wet Waste': 'Dispose in green bin. Ensure paper products are not contaminated with chemicals.',
    
    // Dry Waste Subcategories
    'Paper': 'Recycle in blue bin. Remove any plastic coatings or metal attachments when possible.',
    'Plastic': 'Check recycling codes (1-7). Clean containers before recycling. Dispose in blue bin.',
    'Glass': 'Rinse and recycle in blue bin. Remove lids and caps which may be recycled separately.',
    'Metal': 'Clean and recycle in blue bin. Larger metal items may need to go to special recycling centers.',
    'Carton': 'Rinse, flatten, and recycle in blue bin. Some areas collect cartons separately.',
    'Textile': 'Clean textiles can be donated or recycled at textile collection points.',
    'Rubber': 'Small rubber items may go in general waste. Check for specialized recycling programs.',
    'Wood': 'Untreated wood can be recycled or repurposed. Treated wood requires special disposal.',
    'Other Dry Waste': 'Check local guidelines for specific materials. Some may require special handling.',
    
    // Hazardous Waste Subcategories
    'Electronic Waste': 'Take to e-waste collection centers or electronic retailer take-back programs.',
    'Batteries': 'Never put in regular trash. Take to battery recycling drop-off points.',
    'Chemical Waste': 'Take to hazardous waste collection events. Never pour down drains or put in regular trash.',
    'Paint Waste': 'Take to paint recycling centers. Dried latex paint can sometimes go in regular trash.',
    'Light Bulbs': 'CFL and fluorescent tubes contain mercury - take to special collection points.',
    'Aerosol Cans': 'Ensure completely empty. Some areas accept in metal recycling if empty.',
    'Automotive Waste': 'Take to auto parts stores or garages that accept used fluids and parts.',
    'Other Hazardous Waste': 'Take to hazardous waste collection events or facilities.',
    
    // Medical Waste Subcategories
    'Sharps': 'Always place in approved sharps containers and take to collection points.',
    'Pharmaceutical': 'Take to medication take-back programs. Do not flush down toilet.',
    'Infectious': 'Double-bag and seal. Follow local healthcare waste guidelines.',
    'Non-Infectious': 'Some items may be recyclable if not contaminated. Otherwise dispose as general waste.',
    'Other Medical Waste': 'Follow healthcare provider instructions or contact local health department.',
    
    // Non-Waste Subcategories
    'Reusable Items': 'Continue using or share with friends and family.',
    'Donatable Items': 'Give to charity shops, shelters, or community organizations.',
    'Edible Food': 'Share with food banks, community fridges, or through food sharing apps.',
    'Repurposable Items': 'Use for DIY projects, crafts, or find creative reuse ideas online.',
    'Other Non-Waste': 'Consider free cycle networks or community exchange programs.',
  };
  
  // Color codes for different waste types (standard international color coding)
  static const Map<String, String> colorCoding = {
    'Wet Waste': '#4CAF50',  // Green
    'Dry Waste': '#2196F3',  // Blue
    'Hazardous Waste': '#FF5722',  // Deep Orange/Red
    'Medical Waste': '#F44336',  // Red
    'Non-Waste': '#9C27B0',  // Purple
    
    // Material-specific color coding (follows international standards where applicable)
    'Paper': '#90CAF9',  // Light Blue
    'Plastic': '#2196F3',  // Blue
    'Glass': '#1976D2',  // Dark Blue
    'Metal': '#0D47A1',  // Deep Blue
    'Organic': '#4CAF50',  // Green
    'E-waste': '#FF9800',  // Orange
    'Batteries': '#FF5722',  // Deep Orange
    'General Waste': '#9E9E9E',  // Gray
  };
  
  // Recycling codes for plastics
  static const Map<String, String> recyclingCodes = {
    '1': 'PET (Polyethylene Terephthalate) - Water bottles, soft drink bottles',
    '2': 'HDPE (High-Density Polyethylene) - Milk jugs, detergent bottles',
    '3': 'PVC (Polyvinyl Chloride) - Pipes, shower curtains, food wrap',
    '4': 'LDPE (Low-Density Polyethylene) - Plastic bags, squeeze bottles',
    '5': 'PP (Polypropylene) - Yogurt containers, bottle caps',
    '6': 'PS (Polystyrene) - Foam cups, packing peanuts',
    '7': 'Other (BPA, Polycarbonate, etc.) - Various plastic products',
  };
}