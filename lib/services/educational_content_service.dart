import 'package:flutter/material.dart';
import '../models/educational_content.dart';

/// Service for managing educational content in the app
class EducationalContentService {
  /// List of all available educational content
  final List<EducationalContent> _allContent = [];
  
  /// List of daily tips for the home screen
  final List<DailyTip> _dailyTips = [];
  
  EducationalContentService() {
    _initializeDailyTips();
    _initializeContent();
  }
  
  /// Initialize sample daily tips
  void _initializeDailyTips() {
    _dailyTips.addAll([
      DailyTip(
        id: 'tip1',
        title: 'Plastic Decomposition',
        content: 'Did you know that plastic bottles take up to 450 years to decompose? Try using a reusable water bottle instead!',
        category: 'Dry Waste',
        date: DateTime.now(),
        actionText: 'Learn More',
        actionLink: 'plastic_decomposition',
      ),
      DailyTip(
        id: 'tip2',
        title: 'Food Waste Reduction',
        content: 'Approximately one-third of all food produced globally is wasted. Plan your meals and shop with a list to reduce food waste.',
        category: 'Wet Waste',
        date: DateTime.now().subtract(const Duration(days: 1)),
        actionText: 'View Tips',
        actionLink: 'food_waste_tips',
      ),
      DailyTip(
        id: 'tip3',
        title: 'Battery Disposal',
        content: 'Batteries contain toxic chemicals that can leach into soil and groundwater. Always take them to designated collection points.',
        category: 'Hazardous Waste',
        date: DateTime.now().subtract(const Duration(days: 2)),
        actionText: 'Find Collection Points',
        actionLink: 'battery_collection',
      ),
      DailyTip(
        id: 'tip4',
        title: 'Paper Recycling',
        content: 'Recycling one ton of paper saves 17 trees, 7,000 gallons of water, and 3.3 cubic yards of landfill space.',
        category: 'Dry Waste',
        date: DateTime.now().subtract(const Duration(days: 3)),
        actionText: 'Recycling Guide',
        actionLink: 'paper_recycling',
      ),
      DailyTip(
        id: 'tip5',
        title: 'Energy Conservation',
        content: 'Unplug electronics when not in use. Even when turned off, many appliances still use power in standby mode.',
        category: 'General',
        date: DateTime.now().subtract(const Duration(days: 4)),
        actionText: 'Energy Saving Tips',
        actionLink: 'energy_conservation',
      ),
      DailyTip(
        id: 'tip6',
        title: 'Medication Disposal',
        content: 'Never flush medications down the toilet. Take unused medications to pharmacy take-back programs.',
        category: 'Medical Waste',
        date: DateTime.now().subtract(const Duration(days: 5)),
        actionText: 'Proper Disposal',
        actionLink: 'medication_disposal',
      ),
      DailyTip(
        id: 'tip7',
        title: 'Composting',
        content: 'Composting at home can reduce your household waste by up to 30% while creating nutrient-rich soil for your garden.',
        category: 'Wet Waste',
        date: DateTime.now().subtract(const Duration(days: 6)),
        actionText: 'Start Composting',
        actionLink: 'composting_guide',
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
        description: 'Learn what those numbers inside the recycling symbol mean and how to properly recycle different types of plastic.',
        thumbnailUrl: 'assets/images/education/plastic_codes.jpg',
        contentText: '''
# Understanding Plastic Recycling Codes

Plastic products typically have a number (1-7) inside a recycling symbol. These numbers identify the type of plastic used:

## 1 - PET (Polyethylene Terephthalate)
- Common items: Water bottles, soft drink bottles, food jars
- Recyclability: Highly recyclable
- Disposal: Rinse and place in recycling bin

## 2 - HDPE (High-Density Polyethylene)
- Common items: Milk jugs, detergent bottles, shampoo bottles
- Recyclability: Highly recyclable
- Disposal: Rinse and place in recycling bin

## 3 - PVC (Polyvinyl Chloride)
- Common items: Pipes, shower curtains, food wrap
- Recyclability: Rarely recyclable
- Disposal: Check local guidelines; often goes to landfill

## 4 - LDPE (Low-Density Polyethylene)
- Common items: Plastic bags, squeeze bottles
- Recyclability: Sometimes recyclable
- Disposal: Return to store collection points or check local recycling guidelines

## 5 - PP (Polypropylene)
- Common items: Yogurt containers, medicine bottles, bottle caps
- Recyclability: Increasingly recyclable
- Disposal: Rinse and place in recycling bin if accepted locally

## 6 - PS (Polystyrene)
- Common items: Foam cups, packing peanuts, rigid plastics
- Recyclability: Rarely recyclable
- Disposal: Check local guidelines; often goes to landfill

## 7 - Other (BPA, Polycarbonate, etc.)
- Common items: Baby bottles, CDs, medical storage containers
- Recyclability: Rarely recyclable
- Disposal: Check local guidelines; often goes to landfill

Remember to always check your local recycling guidelines, as they can vary significantly by location.
''',
        categories: ['Dry Waste', 'Plastic'],
        level: ContentLevel.beginner,
        durationMinutes: 5,
        tags: ['recycling', 'plastic', 'codes'],
      ),
    );
    
    // Videos
    _allContent.add(
      EducationalContent.video(
        id: 'video1',
        title: 'Home Composting for Beginners',
        description: 'A step-by-step guide to start composting at home with minimal equipment.',
        thumbnailUrl: 'assets/images/education/composting.jpg',
        videoUrl: 'https://example.com/videos/home_composting.mp4',
        categories: ['Wet Waste', 'Composting'],
        level: ContentLevel.beginner,
        durationMinutes: 8,
        tags: ['composting', 'tutorial', 'organic'],
      ),
    );
    
    // Infographics
    _allContent.add(
      EducationalContent.infographic(
        id: 'infographic1',
        title: 'Waste Segregation at a Glance',
        description: 'Visual guide to common waste items and which bin they belong in.',
        thumbnailUrl: 'assets/images/education/waste_segregation.jpg',
        imageUrl: 'assets/images/education/waste_segregation_infographic.jpg',
        contentText: 'This infographic shows common household items and guides you on which bin to place them in for proper waste segregation.',
        categories: ['General', 'Segregation'],
        level: ContentLevel.beginner,
        durationMinutes: 3,
        tags: ['visual', 'guide', 'sorting'],
      ),
    );
    
    // Quizzes
    _allContent.add(
      EducationalContent.quiz(
        id: 'quiz1',
        title: 'Test Your Recycling Knowledge',
        description: 'Challenge yourself to see how much you know about proper recycling practices.',
        thumbnailUrl: 'assets/images/education/recycling_quiz.jpg',
        questions: [
          QuizQuestion(
            question: 'Which of these items cannot be recycled in most curbside programs?',
            options: ['Plastic water bottles', 'Aluminum cans', 'Styrofoam containers', 'Cardboard boxes'],
            correctOptionIndex: 2,
            explanation: 'Styrofoam (polystyrene) is not accepted in most curbside recycling programs and usually goes to landfill.',
          ),
          QuizQuestion(
            question: 'What should you do with plastic bags?',
            options: [
              'Put them in your curbside recycling bin',
              'Return them to grocery store collection points',
              'Always throw them in the trash',
              'Burn them at home'
            ],
            correctOptionIndex: 1,
            explanation: 'Most curbside programs don\'t accept plastic bags because they jam sorting equipment. Many grocery stores have collection points for plastic bag recycling.',
          ),
          QuizQuestion(
            question: 'Which of these is considered hazardous waste?',
            options: ['Newspaper', 'Glass bottles', 'Batteries', 'Cardboard'],
            correctOptionIndex: 2,
            explanation: 'Batteries contain heavy metals and toxic chemicals that can harm the environment. They should be taken to hazardous waste collection points.',
          ),
          QuizQuestion(
            question: 'Food-soiled paper products like pizza boxes should be:',
            options: [
              'Recycled with paper',
              'Composted if possible',
              'Always placed in general trash',
              'Rinsed and then recycled'
            ],
            correctOptionIndex: 1,
            explanation: 'Food residue contaminates paper recycling, but food-soiled paper can be composted if you have access to composting.',
          ),
          QuizQuestion(
            question: 'What does the "chasing arrows" recycling symbol actually mean?',
            options: [
              'The item is recyclable everywhere',
              'The item is made from recycled materials',
              'The type of plastic the item is made from',
              'The item must be recycled by law'
            ],
            correctOptionIndex: 2,
            explanation: 'The chasing arrows symbol with a number inside identifies the type of plastic resin used to make the product, not its recyclability.',
          ),
        ],
        categories: ['General', 'Recycling'],
        level: ContentLevel.intermediate,
        durationMinutes: 5,
        tags: ['quiz', 'test', 'knowledge'],
      ),
    );
    
    // Tutorials
    _allContent.add(
      EducationalContent.tutorial(
        id: 'tutorial1',
        title: 'Setting Up a Home Recycling System',
        description: 'Learn how to create an efficient recycling system in your home.',
        thumbnailUrl: 'assets/images/education/home_recycling.jpg',
        steps: [
          TutorialStep(
            title: '1. Understand Local Requirements',
            description: 'Research your local recycling guidelines. Different areas accept different materials.',
            imageUrl: 'assets/images/education/recycling_guidelines.jpg',
          ),
          TutorialStep(
            title: '2. Choose Container System',
            description: 'Select containers for different recyclables. You need separate bins for paper, plastic, glass, and metal at minimum.',
            imageUrl: 'assets/images/education/recycling_bins.jpg',
          ),
          TutorialStep(
            title: '3. Set Up Collection Area',
            description: 'Designate a convenient location in your home for recycling bins. Consider kitchen, garage, or utility room.',
            imageUrl: 'assets/images/education/collection_area.jpg',
          ),
          TutorialStep(
            title: '4. Create Clear Labels',
            description: 'Make clear labels with pictures and text to show what goes in each bin.',
            imageUrl: 'assets/images/education/bin_labels.jpg',
          ),
          TutorialStep(
            title: '5. Establish Preparation Routine',
            description: 'Create a routine for preparing recyclables: rinse containers, remove caps, flatten boxes.',
            imageUrl: 'assets/images/education/preparation_routine.jpg',
          ),
          TutorialStep(
            title: '6. Set Up a Schedule',
            description: 'Create a regular schedule for transferring recyclables from home bins to curbside collection or drop-off centers.',
            imageUrl: 'assets/images/education/schedule.jpg',
          ),
        ],
        categories: ['General', 'Home Organization'],
        level: ContentLevel.beginner,
        durationMinutes: 10,
        tags: ['guide', 'setup', 'home'],
      ),
    );
    
    // E-waste article
    _allContent.add(
      EducationalContent.article(
        id: 'article2',
        title: 'The Growing E-Waste Problem',
        description: 'Learn about the environmental impact of electronic waste and how to dispose of it properly.',
        thumbnailUrl: 'assets/images/education/ewaste.jpg',
        contentText: '''
# The Growing E-Waste Problem

Electronic waste, or e-waste, is one of the fastest-growing waste streams globally. As technology advances and devices become more affordable, we replace our electronics more frequently, generating millions of tons of e-waste annually.

## What is E-Waste?

E-waste includes any discarded electrical or electronic device:
- Computers and laptops
- Mobile phones and tablets
- Televisions and monitors
- Printers and scanners
- Small household appliances
- Batteries and cables

## Environmental Impact

Improper disposal of e-waste has serious environmental consequences:

- **Toxic Materials**: Electronics contain hazardous materials like lead, mercury, cadmium, and flame retardants that can leach into soil and water.
- **Resource Waste**: E-waste contains valuable recoverable materials including gold, silver, copper, and rare earth elements.
- **Energy Waste**: Manufacturing new devices uses significantly more energy than recycling materials from existing ones.

## Proper E-Waste Disposal

1. **Repair First**: Consider repairing broken electronics before replacing them.
2. **Donate Working Devices**: Donate functioning electronics to schools, charities, or community organizations.
3. **Manufacturer Take-Back Programs**: Many manufacturers offer recycling programs for their products.
4. **E-Waste Collection Events**: Many cities host special collection events for electronic waste.
5. **Certified E-Waste Recyclers**: Use certified e-waste recyclers that adhere to environmentally responsible practices.
6. **Retail Drop-Off**: Some electronics retailers offer recycling programs, often providing discounts on new purchases.

## Before Disposal

Before disposing of any electronic device:
- Back up important data
- Perform a factory reset to remove personal information
- Remove batteries (they may need to be recycled separately)
- Remove any removable media (SD cards, etc.)

Remember that proper e-waste disposal isn't just good for the environment—it's often required by law in many jurisdictions.
''',
        categories: ['Hazardous Waste', 'E-waste'],
        level: ContentLevel.intermediate,
        durationMinutes: 7,
        tags: ['electronic', 'disposal', 'environment'],
      ),
    );
    
    // Hazardous waste infographic
    _allContent.add(
      EducationalContent.infographic(
        id: 'infographic2',
        title: 'Identifying Hazardous Household Waste',
        description: 'Visual guide to identifying common hazardous waste items in your home.',
        thumbnailUrl: 'assets/images/education/hazardous_waste.jpg',
        imageUrl: 'assets/images/education/hazardous_waste_infographic.jpg',
        contentText: 'This infographic shows common household hazardous waste items and explains how to identify, handle, and dispose of them safely.',
        categories: ['Hazardous Waste'],
        level: ContentLevel.beginner,
        durationMinutes: 3,
        tags: ['visual', 'guide', 'safety'],
      ),
    );
    
    // Composting tutorial
    _allContent.add(
      EducationalContent.tutorial(
        id: 'tutorial2',
        title: 'Building Your First Compost Bin',
        description: 'Step-by-step guide to building an affordable compost bin for your home.',
        thumbnailUrl: 'assets/images/education/compost_bin.jpg',
        steps: [
          TutorialStep(
            title: '1. Choose Your Compost Bin Style',
            description: 'Decide between a tumbler, multi-bin system, or simple pile based on your space and needs.',
            imageUrl: 'assets/images/education/compost_styles.jpg',
          ),
          TutorialStep(
            title: '2. Gather Materials',
            description: 'For a simple bin, you\'ll need: wooden pallets or wire fencing, screws or wire ties, hammer or wire cutters, and a drill.',
            imageUrl: 'assets/images/education/compost_materials.jpg',
          ),
          TutorialStep(
            title: '3. Select Location',
            description: 'Choose a level spot with partial shade and good drainage, ideally near your garden but not too close to your home.',
            imageUrl: 'assets/images/education/compost_location.jpg',
          ),
          TutorialStep(
            title: '4. Assemble the Bin',
            description: 'For a pallet bin: Stand four pallets upright to form a square, secure corners with screws or wire. For wire bin: Form a circle with fencing and secure ends together.',
            imageUrl: 'assets/images/education/compost_assembly.jpg',
          ),
          TutorialStep(
            title: '5. Start Layering',
            description: 'Begin with a 4-inch layer of brown materials (leaves, twigs) for drainage, then alternate green materials (food scraps) and brown materials.',
            imageUrl: 'assets/images/education/compost_layering.jpg',
          ),
          TutorialStep(
            title: '6. Maintain Your Compost',
            description: 'Turn the pile every few weeks, keep it as moist as a wrung-out sponge, and continue adding green and brown materials in roughly equal amounts.',
            imageUrl: 'assets/images/education/compost_maintenance.jpg',
          ),
        ],
        categories: ['Wet Waste', 'Composting'],
        level: ContentLevel.intermediate,
        durationMinutes: 15,
        tags: ['DIY', 'compost', 'garden'],
      ),
    );
    
    // Medical waste article
    _allContent.add(
      EducationalContent.article(
        id: 'article3',
        title: 'Safe Disposal of Home Medical Waste',
        description: 'Guidelines for safely disposing of medical waste generated at home.',
        thumbnailUrl: 'assets/images/education/medical_waste.jpg',
        contentText: '''
# Safe Disposal of Home Medical Waste

Medical waste generated at home requires special handling to protect waste workers, the public, and the environment. This guide covers proper disposal methods for common household medical waste.

## Types of Home Medical Waste

### Sharps
- Needles
- Syringes
- Lancets
- Infusion sets
- Epinephrine auto-injectors

### Pharmaceuticals
- Prescription medications
- Over-the-counter drugs
- Vitamins and supplements

### Potentially Infectious Materials
- Bandages and dressings with body fluids
- Disposable medical gloves
- Personal protective equipment
- Ostomy supplies

## Proper Disposal Methods

### Sharps Disposal
1. **Never** place loose sharps in the trash or recycling
2. Use an FDA-cleared sharps container or puncture-resistant container with tight lid (like a laundry detergent bottle)
3. When 3/4 full, seal the container
4. Disposal options:
   - Drop-off at collection sites (pharmacies, hospitals, or health departments)
   - Mail-back programs (available for purchase)
   - Household hazardous waste collection events
   - Special waste pickups (contact local waste authority)

### Medication Disposal
1. **Do not** flush medications down the toilet (except those specifically listed as safe to flush by the FDA)
2. Use medication take-back programs:
   - DEA-sponsored take-back events
   - Pharmacy collection kiosks
   - Mail-back programs
3. If no take-back options are available:
   - Mix medications with unpalatable substances (coffee grounds, dirt, cat litter)
   - Place in sealed container
   - Remove personal information from bottles
   - Place in household trash

### Potentially Infectious Materials
1. For items soaked with body fluids:
   - Double-bag in plastic bags
   - Tie securely and dispose in regular trash
2. For disposable equipment with minimal contamination:
   - Place in sealed plastic bag
   - Dispose in regular trash

## Local Regulations

Always check your local regulations, as requirements vary by location. Some areas have specific guidelines and services for home medical waste disposal.

## Resources

- FDA Safe Sharps Disposal guidelines
- DEA Drug Take-Back program locator
- Earth911 disposal location search

Safety should always be your top priority when handling and disposing of medical waste.
''',
        categories: ['Medical Waste'],
        level: ContentLevel.beginner,
        durationMinutes: 6,
        tags: ['safety', 'medical', 'disposal'],
      ),
    );
    
    // Recycling quiz
    _allContent.add(
      EducationalContent.quiz(
        id: 'quiz2',
        title: 'Waste Sorting Challenge',
        description: 'Test your knowledge of which waste goes into which bin.',
        thumbnailUrl: 'assets/images/education/sorting_quiz.jpg',
        questions: [
          QuizQuestion(
            question: 'Where should you dispose of a used pizza box with food stains?',
            options: ['Recycling bin', 'Compost bin', 'General waste bin', 'Hazardous waste bin'],
            correctOptionIndex: 1,
            explanation: 'Pizza boxes with food stains can\'t be recycled because the oils contaminate the recycling process, but they can be composted.',
          ),
          QuizQuestion(
            question: 'Used cooking oil should be disposed of by:',
            options: [
              'Pouring it down the drain',
              'Putting it in a sealed container in the trash',
              'Taking it to a cooking oil collection point',
              'Pouring it in the garden'
            ],
            correctOptionIndex: 2,
            explanation: 'Cooking oil should never be poured down drains as it can cause blockages. Many cities have collection points for used cooking oil recycling.',
          ),
          QuizQuestion(
            question: 'Which of these belongs in the hazardous waste category?',
            options: ['Cereal box', 'Expired milk', 'Paint cans', 'Banana peels'],
            correctOptionIndex: 2,
            explanation: 'Paint contains chemicals that can harm the environment if disposed of improperly. Most communities have special collection for paint and other hazardous materials.',
          ),
          QuizQuestion(
            question: 'Where should you dispose of broken drinking glasses?',
            options: [
              'Glass recycling bin',
              'General waste bin wrapped in paper',
              'Hazardous waste bin',
              'Broken glass collection bin'
            ],
            correctOptionIndex: 1,
            explanation: 'Drinking glasses are made from a different type of glass than bottles and jars, and can\'t be recycled with them. Wrap broken glass in paper before placing in general waste for safety.',
          ),
          QuizQuestion(
            question: 'Disposable coffee cups with plastic lining should go in:',
            options: [
              'Paper recycling bin',
              'Plastic recycling bin',
              'General waste bin',
              'Compost bin'
            ],
            correctOptionIndex: 2,
            explanation: 'Most disposable coffee cups have a plastic lining that prevents them from being recycled with paper or composted. They typically need to go in general waste.',
          ),
        ],
        categories: ['General', 'Sorting'],
        level: ContentLevel.beginner,
        durationMinutes: 5,
        tags: ['quiz', 'sorting', 'bins'],
      ),
    );
  }
  
  /// Get a random daily tip
  DailyTip getRandomDailyTip() {
    if (_dailyTips.isEmpty) {
      return DailyTip(
        id: 'default',
        title: 'Reduce, Reuse, Recycle',
        content: 'The three Rs of waste management form the hierarchy for reducing waste. First try to reduce consumption, then reuse items, and finally recycle.',
        category: 'General',
        date: DateTime.now(),
      );
    }
    
    _dailyTips.shuffle();
    return _dailyTips.first;
  }
  
  /// Get a daily tip for a specific day
  DailyTip getDailyTip({DateTime? date}) {
    final targetDate = date ?? DateTime.now();
    final day = targetDate.day % _dailyTips.length;
    return _dailyTips[day];
  }
  
  /// Get all educational content
  List<EducationalContent> getAllContent() {
    return List.from(_allContent);
  }
  
  /// Get content by category
  List<EducationalContent> getContentByCategory(String category) {
    return _allContent.where((content) => 
      content.categories.contains(category)).toList();
  }
  
  /// Get content by type
  List<EducationalContent> getContentByType(ContentType type) {
    return _allContent.where((content) => content.type == type).toList();
  }
  
  /// Search content by query
  List<EducationalContent> searchContent(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _allContent.where((content) => 
      content.title.toLowerCase().contains(lowercaseQuery) || 
      content.description.toLowerCase().contains(lowercaseQuery) ||
      content.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ||
      content.categories.any((category) => category.toLowerCase().contains(lowercaseQuery))
    ).toList();
  }
  
  /// Get content by ID
  EducationalContent? getContentById(String id) {
    try {
      return _allContent.firstWhere((content) => content.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Get featured content (4 random items)
  List<EducationalContent> getFeaturedContent() {
    if (_allContent.length <= 4) {
      return List.from(_allContent);
    }
    
    final List<EducationalContent> contentCopy = List.from(_allContent);
    contentCopy.shuffle();
    return contentCopy.take(4).toList();
  }
  
  /// Get all daily tips
  List<DailyTip> getAllDailyTips() {
    return List.from(_dailyTips);
  }
}