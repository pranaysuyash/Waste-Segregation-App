import '../models/waste_classification.dart';

/// Hardcoded disposal instructions for the most common waste subcategories.
///
/// This allows Layer 0 accepted results to produce a complete
/// [WasteClassification] without calling any AI service.
///
/// The [DisposalInstructions] here are intentionally simpler than
/// AI-generated ones — no environmental impact or CO2 estimates.
/// They are verified correct for Bangalore/India defaults.
class Layer0DisposalMapping {
  Layer0DisposalMapping._();

  static DisposalInstructions? getDisposalInstructions(
    String category,
    String? subcategory,
  ) {
    if (subcategory != null) {
      final key = '$category|$subcategory';
      final entry = _mapping[key];
      if (entry != null) return entry;
    }

    // Fall back to category-only instructions.
    return _categoryFallback[category];
  }

  /// Primary key: "Category|Subcategory" → DisposalInstructions.
  static final Map<String, DisposalInstructions> _mapping = {
    // Dry Waste subcategories
    'Dry Waste|Plastic Bottle': DisposalInstructions(
      primaryMethod: 'Recycle in blue bin',
      steps: [
        'Empty and rinse the bottle',
        'Remove cap (recycle separately)',
        'Crush to save space',
        'Place in blue dry waste bin',
      ],
      hasUrgentTimeframe: false,
      warnings: ['Do not recycle if contaminated with food or oil'],
      tips: ['Check for recycling code on the bottom (PET #1 is widely accepted)'],
    ),
    'Dry Waste|PET Plastic': DisposalInstructions(
      primaryMethod: 'Recycle in blue bin',
      steps: [
        'Clean the container',
        'Remove labels if possible',
        'Flatten to save space',
        'Place in blue dry waste bin',
      ],
      hasUrgentTimeframe: false,
      tips: ['PET (#1) is the most widely recycled plastic'],
    ),
    'Dry Waste|HDPE Plastic': DisposalInstructions(
      primaryMethod: 'Recycle in blue bin',
      steps: [
        'Rinse clean',
        'Remove caps',
        'Place in blue dry waste bin',
      ],
      hasUrgentTimeframe: false,
      tips: ['HDPE (#2) is recyclable in most programs'],
    ),
    'Dry Waste|Plastic': DisposalInstructions(
      primaryMethod: 'Recycle in blue bin',
      steps: [
        'Clean the item',
        'Check for recycling code',
        'Place in blue dry waste bin',
      ],
      hasUrgentTimeframe: false,
      warnings: ['Some plastics (film, bags) may need separate collection'],
    ),
    'Dry Waste|Glass Bottle': DisposalInstructions(
      primaryMethod: 'Recycle separately',
      steps: [
        'Rinse the bottle',
        'Remove cap or cork',
        'Place in glass recycling or blue bin',
        'Handle carefully to avoid breakage',
      ],
      hasUrgentTimeframe: false,
      warnings: ['Broken glass should be wrapped in paper before disposal'],
    ),
    'Dry Waste|Glass': DisposalInstructions(
      primaryMethod: 'Recycle separately',
      steps: [
        'Rinse if food container',
        'Place in glass recycling or blue bin',
        'Wrap broken pieces in paper',
      ],
      hasUrgentTimeframe: false,
    ),
    'Dry Waste|Cardboard': DisposalInstructions(
      primaryMethod: 'Recycle in blue bin',
      steps: [
        'Remove tape and staples',
        'Flatten the cardboard',
        'Place in blue dry waste bin or paper recycling',
      ],
      hasUrgentTimeframe: false,
      tips: ['Waxed cardboard (like juice cartons) goes in Tetra Pak recycling'],
    ),
    'Dry Waste|Paper': DisposalInstructions(
      primaryMethod: 'Recycle in blue bin',
      steps: [
        'Remove plastic wrapping',
        'Flatten or fold',
        'Place in blue dry waste bin',
      ],
      hasUrgentTimeframe: false,
      warnings: ['Greasy or food-soiled paper goes in wet waste, not recycling'],
    ),
    'Dry Waste|Aluminium Can': DisposalInstructions(
      primaryMethod: 'Recycle in blue bin',
      steps: [
        'Rinse the can',
        'Crush to save space',
        'Place in blue dry waste bin',
      ],
      hasUrgentTimeframe: false,
      tips: ['Aluminium is infinitely recyclable — one of the most valuable materials'],
    ),
    'Dry Waste|Metal Can': DisposalInstructions(
      primaryMethod: 'Recycle in blue bin',
      steps: [
        'Rinse the can',
        'Remove labels if possible',
        'Place in blue dry waste bin',
      ],
      hasUrgentTimeframe: false,
    ),
    'Dry Waste|Metal': DisposalInstructions(
      primaryMethod: 'Recycle in blue bin',
      steps: [
        'Clean if contaminated',
        'Place in blue dry waste bin',
      ],
      hasUrgentTimeframe: false,
      tips: ['Scrap metal has value — consider selling to kabadiwala (scrap dealer)'],
    ),
    'Dry Waste|Tetra Pak': DisposalInstructions(
      primaryMethod: 'Recycle separately',
      steps: [
        'Rinse the carton',
        'Flatten',
        'Place in blue dry waste bin or Tetra Pak collection point',
      ],
      hasUrgentTimeframe: false,
      tips: ['Tetra Pak recycling recovers paper, plastic, and aluminium layers'],
    ),
    'Dry Waste|Packaging (multi-color)': DisposalInstructions(
      primaryMethod: 'Recycle in blue bin',
      steps: [
        'Empty contents completely',
        'Clean if food residue present',
        'Flatten packaging',
        'Place in blue dry waste bin',
      ],
      hasUrgentTimeframe: false,
      warnings: ['Multi-material packaging may need separation for recycling'],
    ),
    'Dry Waste|Packaged Item': DisposalInstructions(
      primaryMethod: 'Recycle packaging in blue bin',
      steps: [
        'Empty contents',
        'Clean packaging',
        'Separate materials if possible',
        'Place in blue dry waste bin',
      ],
      hasUrgentTimeframe: false,
    ),
    // Wet Waste subcategories
    'Wet Waste|Organic / Food Scraps': DisposalInstructions(
      primaryMethod: 'Compost or green bin',
      steps: [
        'Remove any packaging',
        'Drain excess liquid',
        'Place in green wet waste bin',
        'Consider home composting if available',
      ],
      hasUrgentTimeframe: false,
      tips: ['Composting food scraps reduces methane emissions from landfills'],
    ),
    'Wet Waste|Garden Waste / Compost': DisposalInstructions(
      primaryMethod: 'Compost or green bin',
      steps: [
        'Place in green wet waste bin',
        'If composting at home, chop into smaller pieces',
      ],
      hasUrgentTimeframe: false,
      tips: ['Dry leaves and garden waste make excellent compost material'],
    ),
    'Wet Waste|Liquid / Beverage': DisposalInstructions(
      primaryMethod: 'Drain and dispose',
      steps: [
        'Pour liquid down the drain',
        'Rinse container',
        'Recycle container in blue bin',
      ],
      hasUrgentTimeframe: false,
      warnings: ['Do not pour oil or grease down the drain — collect and bin separately'],
    ),
    'Wet Waste|Dairy': DisposalInstructions(
      primaryMethod: 'Green bin',
      steps: [
        'Empty dairy product',
        'Rinse container',
        'Place food residue in green wet waste bin',
        'Recycle container in blue bin',
      ],
      hasUrgentTimeframe: false,
    ),
    'Wet Waste|Meat / Fish': DisposalInstructions(
      primaryMethod: 'Green bin — dispose promptly',
      steps: [
        'Wrap in newspaper to reduce odour',
        'Place in green wet waste bin',
        'Dispose within 24 hours',
      ],
      hasUrgentTimeframe: true,
      warnings: ['Meat and fish spoil quickly — do not leave in open bins'],
    ),
    'Wet Waste|Fruit': DisposalInstructions(
      primaryMethod: 'Compost or green bin',
      steps: [
        'Remove stickers',
        'Place in green wet waste bin',
        'Fruit peels are excellent for composting',
      ],
      hasUrgentTimeframe: false,
    ),
    'Wet Waste|Vegetable': DisposalInstructions(
      primaryMethod: 'Compost or green bin',
      steps: [
        'Place in green wet waste bin',
        'Vegetable scraps are ideal for composting',
      ],
      hasUrgentTimeframe: false,
    ),
    'Wet Waste|Food Scraps': DisposalInstructions(
      primaryMethod: 'Green bin',
      steps: [
        'Remove non-compostable items',
        'Drain excess liquid',
        'Place in green wet waste bin',
      ],
      hasUrgentTimeframe: false,
    ),
    'Wet Waste|Baked Goods': DisposalInstructions(
      primaryMethod: 'Green bin',
      steps: [
        'Remove packaging',
        'Place in green wet waste bin',
      ],
      hasUrgentTimeframe: false,
    ),
  };

  /// Category-level fallback when no subcategory match exists.
  static final Map<String, DisposalInstructions> _categoryFallback = {
    'Wet Waste': DisposalInstructions(
      primaryMethod: 'Green bin',
      steps: [
        'Remove any packaging or non-organic material',
        'Drain excess liquids',
        'Place in green wet waste bin',
      ],
      hasUrgentTimeframe: false,
    ),
    'Dry Waste': DisposalInstructions(
      primaryMethod: 'Blue bin',
      steps: [
        'Clean the item if contaminated',
        'Separate materials if possible',
        'Place in blue dry waste bin',
      ],
      hasUrgentTimeframe: false,
    ),
  };
}
