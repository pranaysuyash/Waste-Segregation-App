import 'dart:math';

import '../models/educational_content.dart';
import 'educational_content_analytics_service.dart' as analytics_service;

/// Service for managing educational content in the app
class EducationalContentService {
  EducationalContentService([this.analytics]) {
    _initializeDailyTips();
    _initializeContent();
  }

  /// List of all available educational content
  final List<EducationalContent> _allContent = [];

  final analytics_service.EducationalContentAnalyticsService? analytics;

  /// List of daily tips for the home screen
  final List<DailyTip> _dailyTips = [];

  /// Initialize sample daily tips
  void _initializeDailyTips() {
    _dailyTips.addAll([
      DailyTip(
        id: 'daily_tip1',
        title: 'Plastic Decomposition',
        content:
            'Did you know that plastic bottles take up to 450 years to decompose? Try using a reusable water bottle instead!',
        category: 'Dry Waste',
        date: DateTime.now(),
        actionText: 'Learn More',
        actionLink: 'plastic_decomposition',
        contentId: 'article1',
      ),
      DailyTip(
        id: 'daily_tip2',
        title: 'Food Waste Reduction',
        content:
            'Approximately one-third of all food produced globally is wasted. Plan your meals and shop with a list to reduce food waste.',
        category: 'Wet Waste',
        date: DateTime.now().subtract(const Duration(days: 1)),
        actionText: 'View Tips',
        actionLink: 'food_waste_tips',
        contentId: 'article2',
      ),
      DailyTip(
        id: 'daily_tip3',
        title: 'Battery Recycling',
        content:
            'Batteries contain toxic materials that can harm the environment. Always take them to designated recycling centers.',
        category: 'Hazardous Waste',
        date: DateTime.now().subtract(const Duration(days: 2)),
        actionText: 'Find Centers',
        actionLink: 'battery_recycling',
        contentId: 'tip2',
      ),
      DailyTip(
        id: 'daily_tip4',
        title: 'Composting Benefits',
        content:
            'Composting reduces methane emissions from landfills and creates nutrient-rich soil for your garden.',
        category: 'Wet Waste',
        date: DateTime.now().subtract(const Duration(days: 3)),
        actionText: 'Start Composting',
        actionLink: 'composting_guide',
        contentId: 'video1',
      ),
      DailyTip(
        id: 'daily_tip5',
        title: 'Paper Recycling',
        content:
            'Recycling one ton of paper saves 17 trees, 7,000 gallons of water, and enough energy to power an average home for six months.',
        category: 'Dry Waste',
        date: DateTime.now().subtract(const Duration(days: 4)),
        actionText: 'Recycle Paper',
        actionLink: 'paper_recycling',
        contentId: 'infographic1',
      ),
      DailyTip(
        id: 'daily_tip6',
        title: 'E-Waste Awareness',
        content:
            'Electronic waste is the fastest-growing waste stream. Donate or recycle old electronics instead of throwing them away.',
        category: 'Hazardous Waste',
        date: DateTime.now().subtract(const Duration(days: 5)),
        actionText: 'E-Waste Guide',
        actionLink: 'ewaste_disposal',
        contentId: 'video2',
      ),
      DailyTip(
        id: 'daily_tip7',
        title: 'Reduce Single-Use Items',
        content:
            'Bring your own bags, cups, and utensils to reduce single-use plastic consumption by up to 80%.',
        category: 'General',
        date: DateTime.now().subtract(const Duration(days: 6)),
        actionText: 'Reduction Tips',
        actionLink: 'reduce_waste',
        contentId: 'article4',
      ),
      DailyTip(
        id: 'daily_tip8',
        title: 'Medical Waste Safety',
        content:
            'Never dispose of medications in regular trash or flush them. Use pharmacy take-back programs for safe disposal.',
        category: 'Medical Waste',
        date: DateTime.now().subtract(const Duration(days: 7)),
        actionText: 'Safe Disposal',
        actionLink: 'medical_disposal',
        contentId: 'article3',
      ),
    ]);
  }

  /// Initialize sample educational content
  void _initializeContent() {
    // Articles
    _allContent.add(
      EducationalContent.article(
        id: 'article1',
        title: 'Understanding Plastic Recycling Codes',
        description:
            'Learn what those numbers inside the recycling symbol mean and how to properly recycle different types of plastic.',
        thumbnailUrl: 'assets/images/education/plastic_codes.jpg',
        contentText:
            'Plastic recycling codes are numbers 1-7 found inside the recycling symbol on plastic products. Code 1 (PET) is commonly used for water bottles and is widely recyclable. Code 2 (HDPE) is used for milk jugs and detergent bottles. Code 3 (PVC) is harder to recycle and often goes to landfill. Code 4 (LDPE) includes plastic bags and wraps. Code 5 (PP) includes yogurt containers and bottle caps. Code 6 (PS) is styrofoam and rarely recyclable. Code 7 includes all other plastics and mixed materials.',
        categories: ['Dry Waste', 'Plastic', 'Recycling'],
        level: ContentLevel.beginner,
        durationMinutes: 5,
        tags: ['recycling', 'plastic', 'codes'],
      ),
    );

    _allContent.add(
      EducationalContent.article(
        id: 'article2',
        title: 'Advanced Composting Techniques',
        description:
            'Master advanced composting methods including hot composting, vermicomposting, and bokashi fermentation.',
        thumbnailUrl: 'assets/images/education/advanced_composting.jpg',
        contentText:
            'Advanced composting techniques can significantly improve decomposition rates and compost quality. Hot composting maintains temperatures of 140-160°F to kill pathogens and weed seeds. Vermicomposting uses worms to break down organic matter. Bokashi fermentation uses beneficial microorganisms to pre-process food waste.',
        categories: ['Wet Waste', 'Composting'],
        level: ContentLevel.advanced,
        durationMinutes: 12,
        tags: ['composting', 'advanced', 'organic'],
      ),
    );

    _allContent.add(
      EducationalContent.article(
        id: 'article3',
        title: 'Medical Waste Safety Guidelines',
        description:
            'Essential safety protocols for handling and disposing of medical waste at home.',
        thumbnailUrl: 'assets/images/education/medical_waste.jpg',
        contentText:
            'Medical waste requires special handling to prevent contamination and injury. Sharps should be placed in puncture-resistant containers. Medications should never be flushed down toilets. Many pharmacies offer take-back programs for unused medications.',
        categories: ['Medical Waste', 'Hazardous Waste'],
        level: ContentLevel.intermediate,
        durationMinutes: 8,
        tags: ['medical', 'safety', 'disposal'],
      ),
    );

    // Videos
    _allContent.add(
      EducationalContent.video(
        id: 'video1',
        title: 'Home Composting for Beginners',
        description:
            'A step-by-step guide to start composting at home with minimal equipment.',
        thumbnailUrl: 'assets/images/education/composting.jpg',
        videoUrl: 'https://example.com/videos/home_composting.mp4',
        categories: ['Wet Waste', 'Composting'],
        level: ContentLevel.beginner,
        durationMinutes: 8,
        tags: ['composting', 'tutorial', 'organic'],
      ),
    );

    _allContent.add(
      EducationalContent.video(
        id: 'video2',
        title: 'E-Waste Recycling Process',
        description:
            'See how electronic waste is processed and recycled in modern facilities.',
        thumbnailUrl: 'assets/images/education/ewaste.jpg',
        videoUrl: 'https://example.com/videos/ewaste_recycling.mp4',
        categories: ['Hazardous Waste', 'Electronics', 'Recycling'],
        level: ContentLevel.intermediate,
        durationMinutes: 15,
        tags: ['electronics', 'recycling', 'hazardous'],
      ),
    );

    // Infographics
    _allContent.add(
      EducationalContent.infographic(
        id: 'infographic1',
        title: 'Waste Segregation Quick Guide',
        description:
            'Visual guide showing how to properly segregate different types of waste.',
        thumbnailUrl: 'assets/images/education/segregation_guide.jpg',
        imageUrl: 'assets/images/education/segregation_infographic.jpg',
        categories: ['General', 'Dry Waste', 'Wet Waste', 'Hazardous Waste'],
        level: ContentLevel.beginner,
        durationMinutes: 3,
        tags: ['segregation', 'guide', 'visual'],
      ),
    );

    _allContent.add(
      EducationalContent.infographic(
        id: 'infographic2',
        title: 'Plastic Pollution Impact',
        description:
            'Visualizing the environmental impact of plastic pollution on marine life.',
        thumbnailUrl: 'assets/images/education/plastic_pollution.jpg',
        imageUrl: 'assets/images/education/plastic_impact_infographic.jpg',
        categories: ['Environmental Impact', 'Plastic'],
        level: ContentLevel.intermediate,
        durationMinutes: 5,
        tags: ['pollution', 'environment', 'marine'],
      ),
    );

    // Quizzes
    _allContent.add(
      EducationalContent.quiz(
        id: 'quiz1',
        title: 'Test Your Recycling Knowledge',
        description:
            'Challenge yourself to see how much you know about proper recycling practices.',
        thumbnailUrl: 'assets/images/education/recycling_quiz.jpg',
        questions: [
          const QuizQuestion(
            question:
                'Which of these items cannot be recycled in most curbside programs?',
            options: [
              'Plastic water bottles',
              'Aluminum cans',
              'Styrofoam containers',
              'Cardboard boxes'
            ],
            correctOptionIndex: 2,
            explanation:
                'Styrofoam (polystyrene) is not accepted in most curbside recycling programs and usually goes to landfill.',
          ),
          const QuizQuestion(
            question: 'What should you do with pizza boxes?',
            options: [
              'Recycle them as-is',
              'Remove greasy parts before recycling',
              'Throw them in regular trash',
              'Compost the entire box'
            ],
            correctOptionIndex: 1,
            explanation:
                'Pizza boxes can be recycled if you remove the greasy, food-soiled parts. Clean cardboard is recyclable.',
          ),
        ],
        categories: ['General', 'Recycling', 'Dry Waste'],
        level: ContentLevel.beginner,
        durationMinutes: 5,
        tags: ['quiz', 'test', 'knowledge'],
      ),
    );

    _allContent.add(
      EducationalContent.quiz(
        id: 'quiz2',
        title: 'Advanced Waste Management Quiz',
        description:
            'Test your knowledge of complex waste management scenarios.',
        thumbnailUrl: 'assets/images/education/advanced_quiz.jpg',
        questions: [
          const QuizQuestion(
            question:
                'What is the most effective method for treating medical waste?',
            options: [
              'Incineration',
              'Autoclaving',
              'Chemical treatment',
              'All of the above'
            ],
            correctOptionIndex: 3,
            explanation:
                'Different types of medical waste require different treatment methods. All three are effective for different scenarios.',
          ),
        ],
        categories: ['Medical Waste', 'Hazardous Waste'],
        level: ContentLevel.advanced,
        durationMinutes: 8,
        tags: ['quiz', 'advanced', 'medical'],
      ),
    );

    // Tutorials
    _allContent.add(
      EducationalContent.tutorial(
        id: 'tutorial1',
        title: 'Setting Up a Home Recycling System',
        description:
            'Step-by-step guide to organize an efficient recycling system at home.',
        thumbnailUrl: 'assets/images/education/home_recycling.jpg',
        steps: [
          const TutorialStep(
            title: 'Choose Your Containers',
            description:
                'Select appropriate containers for different waste types. Use clearly labeled bins for dry waste, wet waste, and hazardous materials.',
            imageUrl: 'assets/images/education/step1_containers.jpg',
          ),
          const TutorialStep(
            title: 'Set Up Collection Points',
            description:
                'Place containers in convenient locations throughout your home. Kitchen for wet waste, office for paper, bathroom for medical waste.',
            imageUrl: 'assets/images/education/step2_placement.jpg',
          ),
          const TutorialStep(
            title: 'Create a Schedule',
            description:
                'Establish regular collection and disposal schedules. Check local pickup days and plan accordingly.',
            imageUrl: 'assets/images/education/step3_schedule.jpg',
          ),
        ],
        categories: ['General', 'Recycling', 'Organization'],
        level: ContentLevel.beginner,
        durationMinutes: 10,
        tags: ['tutorial', 'home', 'organization'],
      ),
    );

    _allContent.add(
      EducationalContent.tutorial(
        id: 'tutorial2',
        title: 'Building a Compost Bin',
        description:
            'Learn to build your own compost bin using recycled materials.',
        thumbnailUrl: 'assets/images/education/compost_bin.jpg',
        steps: [
          const TutorialStep(
            title: 'Gather Materials',
            description:
                'Collect wooden pallets, wire mesh, and basic tools. You can often get pallets for free from local businesses.',
            imageUrl: 'assets/images/education/compost_materials.jpg',
          ),
          const TutorialStep(
            title: 'Assemble the Frame',
            description:
                'Connect the pallets to form a three-sided enclosure. Leave one side open for easy access.',
            imageUrl: 'assets/images/education/compost_assembly.jpg',
          ),
          const TutorialStep(
            title: 'Add Ventilation',
            description:
                'Install wire mesh for airflow and add a lid to control moisture.',
            imageUrl: 'assets/images/education/compost_ventilation.jpg',
          ),
        ],
        categories: ['Wet Waste', 'Composting', 'DIY'],
        level: ContentLevel.intermediate,
        durationMinutes: 25,
        tags: ['tutorial', 'diy', 'composting'],
      ),
    );

    // Tips
    _allContent.add(
      EducationalContent.tip(
        id: 'tip1',
        title: 'Reduce Food Packaging Waste',
        description:
            'Simple strategies to minimize packaging waste when shopping.',
        thumbnailUrl: 'assets/images/education/packaging_tip.jpg',
        contentText:
            'Bring reusable bags, choose products with minimal packaging, buy in bulk when possible, and opt for refillable containers.',
        categories: ['Dry Waste', 'Reduction'],
        tags: ['tip', 'packaging', 'reduction'],
      ),
    );

    _allContent.add(
      EducationalContent.tip(
        id: 'tip2',
        title: 'Battery Disposal Safety',
        description: 'Proper way to dispose of different types of batteries.',
        thumbnailUrl: 'assets/images/education/battery_tip.jpg',
        contentText:
            'Never throw batteries in regular trash. Take them to designated collection points at electronics stores or hazardous waste facilities.',
        categories: ['Hazardous Waste', 'Electronics'],
        tags: ['tip', 'battery', 'safety'],
      ),
    );

    // Additional content to meet test requirements
    _allContent.add(
      EducationalContent.article(
        id: 'article4',
        title: 'Zero Waste Lifestyle Guide',
        description:
            'Complete guide to adopting a zero waste lifestyle and reducing your environmental footprint.',
        thumbnailUrl: 'assets/images/education/zero_waste.jpg',
        contentText:
            'Zero waste is a philosophy that encourages the redesign of resource life cycles so that all products are reused. Start small with reusable bags, containers, and water bottles.',
        categories: ['General', 'Reduction'],
        level: ContentLevel.intermediate,
        durationMinutes: 15,
        tags: ['zero-waste', 'lifestyle', 'reduction'],
      ),
    );

    _allContent.add(
      EducationalContent.video(
        id: 'video3',
        title: 'Plastic-Free Kitchen Setup',
        description:
            'Transform your kitchen to be plastic-free with these simple swaps and alternatives.',
        thumbnailUrl: 'assets/images/education/plastic_free_kitchen.jpg',
        videoUrl: 'https://example.com/videos/plastic_free_kitchen.mp4',
        categories: ['Plastic', 'Reduction', 'Kitchen'],
        level: ContentLevel.beginner,
        durationMinutes: 12,
        tags: ['plastic-free', 'kitchen', 'alternatives'],
      ),
    );

    // Recommendation-targeted content
    _allContent.add(
      EducationalContent.article(
        id: 'article5',
        title: 'How to safely dispose hazardous household items',
        description:
            'Practical guide for identifying and disposing of common hazardous waste found in homes, including paints, solvents, pesticides, and cleaning chemicals.',
        thumbnailUrl: 'assets/images/education/hazardous_disposal.jpg',
        contentText:
            'Hazardous household items require special handling to prevent environmental contamination and health risks. Never pour chemicals down the drain. Use designated hazardous waste collection days or permanent drop-off facilities. Store items in original containers with labels intact. Keep them sealed and away from heat sources until disposal.',
        categories: ['Hazardous Waste', 'Safety'],
        level: ContentLevel.beginner,
        durationMinutes: 6,
        tags: ['hazardous', 'safety', 'disposal', 'household'],
      ),
    );

    _allContent.add(
      EducationalContent.tip(
        id: 'tip3',
        title: 'How to take clearer waste photos',
        description:
            'Simple photography tips to help the AI identify your waste items accurately.',
        thumbnailUrl: 'assets/images/education/photo_tips.jpg',
        contentText:
            '1. Ensure good lighting – natural daylight works best.\n2. Place the item on a plain, contrasting background.\n3. Keep the camera steady and in focus.\n4. Capture the entire item without cropping important details.\n5. Avoid glare and shadows by diffusing harsh light.\n6. If the item has labels or codes, take a close-up shot as well.',
        categories: ['General', 'Guide'],
        tags: ['photo', 'tips', 'ai', 'classification'],
      ),
    );
  }

  /// Get a random daily tip (non-mutating)
  DailyTip getRandomDailyTip() {
    if (_dailyTips.isEmpty) {
      return DailyTip(
        id: 'default',
        title: 'Reduce, Reuse, Recycle',
        content:
            'The three Rs of waste management form the hierarchy for reducing waste. First try to reduce consumption, then reuse items, and finally recycle.',
        category: 'General',
        date: DateTime.now(),
      );
    }

    final rng = Random(DateTime.now().millisecondsSinceEpoch);
    return _dailyTips[rng.nextInt(_dailyTips.length)];
  }

  /// Get a daily tip for a specific day, optionally preferring a category.
  ///
  /// The tip is deterministically selected from the date alone: same date
  /// always returns the same tip. If [preferredCategory] is provided and
  /// content for that category is available for the selected day, the tip
  /// is rotated to the matching one within the same logical day-window.
  DailyTip getDailyTip({DateTime? date, String? preferredCategory}) {
    if (_dailyTips.isEmpty) {
      return DailyTip(
        id: 'default',
        title: 'Reduce, Reuse, Recycle',
        content:
            'The three Rs of waste management form the hierarchy for reducing waste. First try to reduce consumption, then reuse items, and finally recycle.',
        category: 'General',
        date: date ?? DateTime.now(),
      );
    }

    final targetDate = date ?? DateTime.now();
    final seed =
        targetDate.year * 10000 + targetDate.month * 100 + targetDate.day;
    final rng = Random(seed);
    final baseIndex = rng.nextInt(_dailyTips.length);
    var tip = _dailyTips[baseIndex];

    if (preferredCategory != null && preferredCategory.isNotEmpty) {
      final matchingIdx = _dailyTips.indexWhere(
        (t) => t.category == preferredCategory,
      );
      if (matchingIdx >= 0) {
        tip = _dailyTips[matchingIdx];
      }
    }

    return tip;
  }

  /// Get the daily tip for the home screen, optionally preferring a category.
  ///
  /// Uses a stable date hash so the same date always yields the same tip.
  /// If [preferredCategory] is provided, searches forward from the base
  /// index for a matching category and falls back to the base index when
  /// nothing matches.
  DailyTip getDailyTipForHome({DateTime? date, String? preferredCategory}) {
    if (_dailyTips.isEmpty) {
      return _defaultTip(date: date);
    }

    final targetDate = date ?? DateTime.now();
    final baseIndex = _stableDateHash(targetDate) % _dailyTips.length;
    var tip = _dailyTips[baseIndex];

    if (preferredCategory != null && preferredCategory.isNotEmpty) {
      for (var i = 0; i < _dailyTips.length; i++) {
        final idx = (baseIndex + i) % _dailyTips.length;
        if (_categoryMatches(_dailyTips[idx].category, preferredCategory)) {
          tip = _dailyTips[idx];
          break;
        }
      }
    }

    return tip.copyWith(date: targetDate);
  }

  int _stableDateHash(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }

  bool _categoryMatches(String tipCategory, String? preferred) {
    if (preferred == null || preferred.isEmpty) return false;
    final lowerTip = tipCategory.toLowerCase();
    final lowerPref = preferred.toLowerCase();
    return lowerTip.contains(lowerPref) || lowerPref.contains(lowerTip);
  }

  DailyTip _defaultTip({DateTime? date}) => DailyTip(
        id: 'default',
        title: 'Reduce, Reuse, Recycle',
        content:
            'The three Rs of waste management form the hierarchy for reducing waste. First try to reduce consumption, then reuse items, and finally recycle.',
        category: 'General',
        date: date ?? DateTime.now(),
      );

  /// Get all educational content
  List<EducationalContent> getAllContent() {
    return List.from(_allContent);
  }

  /// Get content by category
  List<EducationalContent> getContentByCategory(String category) {
    return _allContent
        .where((content) => content.categories.contains(category))
        .toList();
  }

  /// Get content by type
  List<EducationalContent> getContentByType(ContentType type) {
    return _allContent.where((content) => content.type == type).toList();
  }

  /// Search content by query
  List<EducationalContent> searchContent(String query) {
    if (query.trim().isEmpty) {
      return [];
    }

    final lowercaseQuery = query.toLowerCase();
    return _allContent
        .where((content) =>
            content.title.toLowerCase().contains(lowercaseQuery) ||
            content.description.toLowerCase().contains(lowercaseQuery) ||
            content.tags
                .any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ||
            content.categories.any(
                (category) => category.toLowerCase().contains(lowercaseQuery)))
        .toList();
  }

  /// Get content by ID
  EducationalContent? getContentById(String id) {
    try {
      return _allContent.firstWhere((content) => content.id == id);
    } catch (e) {
      // Not found
      return null;
    }
  }

  /// Get featured content (4 random items)
  List<EducationalContent> getFeaturedContent() {
    if (_allContent.length <= 4) {
      return List.from(_allContent);
    }

    final contentCopy = List<EducationalContent>.from(_allContent);
    contentCopy.shuffle();
    return contentCopy.take(4).toList();
  }

  /// Get all daily tips
  List<DailyTip> getAllDailyTips() {
    return List.from(_dailyTips);
  }

  /// Get new content (recently added content)
  List<EducationalContent> getNewContent() {
    // Return content added in the last 30 days, or most recent if none
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final newContent = _allContent
        .where((content) => content.dateAdded.isAfter(thirtyDaysAgo))
        .toList();

    if (newContent.isEmpty) {
      // If no recent content, return the most recently added content
      final sortedContent = List<EducationalContent>.from(_allContent);
      sortedContent.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      return sortedContent.take(5).toList();
    }

    return newContent;
  }

  /// Get interactive content (quizzes and tutorials)
  List<EducationalContent> getInteractiveContent() {
    return _allContent
        .where((content) =>
            content.type == ContentType.quiz ||
            content.type == ContentType.tutorial)
        .toList();
  }

  /// Get advanced topics content
  List<EducationalContent> getAdvancedTopics() {
    return _allContent
        .where((content) => content.level == ContentLevel.advanced)
        .toList();
  }

  // ==================== BASIC ANALYTICS ====================

  /// Record that content was viewed
  void trackContentViewed(EducationalContent content) {
    analytics?.trackContentView(content.id, content.categories.first);
    analytics?.startContentSession(content.id);
  }

  /// End the session and optionally mark completion
  Future<void> endContentView({bool completed = false}) async {
    await analytics?.endContentSession(wasCompleted: completed);
  }

  List<EducationalContent> get allContent => _allContent;

  // ==================== RECOMMENDATIONS ====================

  /// Returns the single most relevant educational content for a given classification,
  /// or null if nothing matches.
  ///
  /// Matching logic (deterministic and testable):
  /// 1. clarificationNeeded / low confidence  -> photo tips
  /// 2. requiresSpecialDisposal == true      -> hazardous safety guide
  /// 3. category == 'Hazardous Waste'        -> hazardous safety guide
  /// 4. category == 'Wet Waste'              -> composting basics
  /// 5. category == 'Dry Waste' && subcategory/material == plastic -> plastic recycling codes
  /// 6. category == 'Medical Waste'          -> medical waste safety guidelines
  /// 7. category match fallback                -> first content matching category
  /// 8. no match                               -> null (card hidden)
  EducationalContent? getRecommendationForClassification({
    required String category,
    String? subcategory,
    String? riskLevel,
    bool? requiresSpecialDisposal,
    bool? clarificationNeeded,
    double? confidence,
  }) {
    final catLower = category.toLowerCase().trim();
    final subLower = (subcategory ?? '').toLowerCase().trim();
    final conf = confidence ?? 1.0;
    final needsClarification = clarificationNeeded == true || conf < 0.7;

    // 1. Low confidence / needs review -> photo tips
    if (needsClarification) {
      final match = _findById('tip3');
      if (match != null) return match;
    }

    // 2. Special disposal required -> hazardous safety guide
    if (requiresSpecialDisposal == true) {
      final match = _findById('article5');
      if (match != null) return match;
    }

    // 3. Hazardous Waste -> hazardous safety guide
    if (catLower == 'hazardous waste') {
      final match = _findById('article5');
      if (match != null) return match;
    }

    // 4. Wet Waste -> composting basics
    if (catLower == 'wet waste') {
      final match = _findById('video1');
      if (match != null) return match;
    }

    // 5. Dry Waste + plastic -> plastic recycling codes
    if (catLower == 'dry waste' &&
        (subLower == 'plastic' || subLower.contains('plastic'))) {
      final match = _findById('article1');
      if (match != null) return match;
    }

    // 6. Medical Waste -> medical waste safety guidelines
    if (catLower == 'medical waste') {
      final match = _findById('article3');
      if (match != null) return match;
    }

    // 7. Fallback: first content matching the exact category
    final fallback = _allContent.firstWhere(
      (c) => c.categories.any(
        (cat) => cat.toLowerCase().trim() == catLower,
      ),
      orElse: () => _allContent.firstWhere(
        (c) => c.categories.any(
          (cat) => cat.toLowerCase().contains(catLower),
        ),
        orElse: () => _allContent.first,
      ),
    );
    final matchesExactly = fallback.categories.any(
      (cat) => cat.toLowerCase().trim() == catLower,
    );
    final matchesPartially = fallback.categories.any(
      (cat) => cat.toLowerCase().contains(catLower),
    );
    if (matchesExactly || matchesPartially) {
      return fallback;
    }

    return null;
  }

  EducationalContent? _findById(String id) {
    try {
      return _allContent.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
