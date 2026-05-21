import 'package:flutter/material.dart';
import '../models/waste_classification.dart';
import '../widgets/interactive_tag.dart';

/// Builds a list of [TagData] from a [WasteClassification] for display
/// on the result screen.  Extracted from v1's `_ResultScreenState` so that
/// the same logic can be shared between screens and unit-tested.
List<TagData> buildClassificationTags(WasteClassification c) {
  final tags = <TagData>[];
  tags.add(TagFactory.category(c.category));
  if (c.materialType != null) {
    tags.add(TagFactory.material(c.materialType!));
  }
  _addEnvironmentalImpactTags(c, tags);
  _addLocalInformationTags(c, tags);
  _addUrgencyTags(c, tags);
  _addEducationalTips(c, tags);
  return tags;
}

// ---------------------------------------------------------------------------
// Environmental impact
// ---------------------------------------------------------------------------

double _co2Savings(WasteClassification c) {
  switch (c.category.toLowerCase()) {
    case 'paper':
    case 'dry waste':
      return 2.3;
    case 'plastic':
      return 1.8;
    case 'wet waste':
      return 0.5;
    default:
      return 0.0;
  }
}

double _waterSavings(WasteClassification c) {
  switch (c.category.toLowerCase()) {
    case 'paper':
    case 'dry waste':
      return 45.0;
    case 'plastic':
      return 12.0;
    default:
      return 0.0;
  }
}

DifficultyLevel _recyclingDifficulty(WasteClassification c) {
  final cat = c.category.toLowerCase();
  if (cat == 'hazardous waste' || cat == 'medical waste') {
    return DifficultyLevel.expert;
  }
  final mat = c.materialType?.toLowerCase();
  if (mat == 'plastic') {
    final code = c.recyclingCode;
    if (code == 1 || code == 2) return DifficultyLevel.easy;
    if (code == 5) return DifficultyLevel.medium;
    return DifficultyLevel.hard;
  }
  if (mat == 'paper') return DifficultyLevel.easy;
  if (mat == 'glass') return DifficultyLevel.medium;
  if (mat == 'metal') return DifficultyLevel.easy;
  return DifficultyLevel.medium;
}

void _addEnvironmentalImpactTags(WasteClassification c, List<TagData> tags) {
  final co2 = _co2Savings(c);
  final water = _waterSavings(c);
  if (co2 > 0) {
    tags.add(
        TagFactory.environmentalImpact('${co2}kg CO₂ saved', Colors.green));
  }
  if (water > 0) {
    tags.add(
        TagFactory.environmentalImpact('${water}L water saved', Colors.blue));
  }
  tags.add(TagFactory.recyclingDifficulty(
      _recyclingDifficulty(c).label, _recyclingDifficulty(c)));
}

// ---------------------------------------------------------------------------
// Local information
// ---------------------------------------------------------------------------

void _addLocalInformationTags(WasteClassification c, List<TagData> tags) {
  if (c.bbmpComplianceStatus != null && c.bbmpComplianceStatus!.isNotEmpty) {
    tags.add(TagFactory.localInfo(
        'Compliance: ${c.bbmpComplianceStatus}', Icons.gavel));
  }

  if (c.localGuidelinesReference != null &&
      c.localGuidelinesReference!.isNotEmpty) {
    tags.add(
        TagFactory.localInfo(c.localGuidelinesReference!, Icons.description));
  }

  if (c.localRegulations != null && c.localRegulations!.isNotEmpty) {
    for (final entry in c.localRegulations!.entries.take(2)) {
      tags.add(TagFactory.localInfo(
          '${entry.key}: ${entry.value}', Icons.policy));
    }
  }
}

// ---------------------------------------------------------------------------
// Urgency
// ---------------------------------------------------------------------------

void _addUrgencyTags(WasteClassification c, List<TagData> tags) {
  switch (c.category.toLowerCase()) {
    case 'medical waste':
      tags.add(TagFactory.timeUrgent('Medical waste', UrgencyLevel.critical));
    case 'hazardous waste':
      tags.add(TagFactory.timeUrgent('Hazardous materials', UrgencyLevel.high));
    case 'wet waste':
      tags.add(TagFactory.timeUrgent('Prevent odors', UrgencyLevel.medium));
  }
}

// ---------------------------------------------------------------------------
// Educational tips
// ---------------------------------------------------------------------------

void _addEducationalTips(WasteClassification c, List<TagData> tags) {
  final sub = c.subcategory?.toLowerCase();
  final cat = c.category.toLowerCase();
  if (sub == 'plastic') {
    tags.add(
        TagFactory.didYouKnow('Remove caps before recycling', Colors.blue));
    tags.add(TagFactory.commonMistake(
        'Leaving food residue on containers', Colors.amber));
  } else if (sub == 'paper') {
    tags.add(
        TagFactory.didYouKnow('Paper can be recycled 5-7 times', Colors.blue));
    tags.add(
        TagFactory.commonMistake('Mixing wet and dry paper', Colors.amber));
  } else if (cat == 'wet waste') {
    tags.add(TagFactory.didYouKnow(
        'Composting creates nutrient-rich soil', Colors.green));
    tags.add(TagFactory.commonMistake(
        'Adding meat or oil to compost', Colors.amber));
  }
}

/// Educational fact text keyed on the classification.
String educationalFact(WasteClassification c) {
  final sub = c.subcategory?.toLowerCase();
  final cat = c.category.toLowerCase();
  if (sub == 'plastic') {
    return 'Plastic bottles can be recycled into new bottles, clothing, carpets, and even park benches! '
        'Recycling one ton of plastic saves up to 16.3 barrels of oil.';
  }
  if (sub == 'paper') {
    return 'Paper can be recycled 5-7 times before the fibers become too short. '
        'Recycling one ton of paper saves 17 trees and 7,000 gallons of water.';
  }
  if (cat == 'wet waste') {
    return 'Composting organic waste reduces methane emissions from landfills by up to 50% '
        'and creates nutrient-rich soil for gardening.';
  }
  if (cat == 'hazardous waste') {
    return 'Hazardous waste like batteries, electronics, and chemicals require special handling '
        'to prevent environmental contamination and health risks.';
  }
  if (cat == 'e-waste') {
    return 'Electronic waste contains valuable materials like gold, silver, and rare earth elements. '
        'Proper e-waste recycling recovers these materials safely.';
  }
  return 'Proper waste segregation is the first step toward a circular economy. '
      'Every item sorted correctly reduces landfill burden and saves resources.';
}
