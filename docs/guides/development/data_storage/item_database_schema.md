# Item Database Schema

This document outlines the proposed schema for individual items within the Waste Segregation App's database. A rich item database is crucial for enabling advanced and AI-powered gamification features, such as hidden badges, content unlocks based on discovery, and personalized quests.

## Item Object Structure

Each item in the database could be represented by a JSON-like object with the following fields:

```json
{
  "itemId": "string",               // Unique identifier for the item (e.g., UUID, or a structured ID like "plastic_bottle_coke_500ml_2023")
  "itemName": "string",             // Full, descriptive name of the item (e.g., "Coca-Cola Classic Soda Can 12 fl oz")
  "genericName": "string",          // Broader, common name (e.g., "Aluminum Can", "Plastic Bottle", "Newspaper")
  "description": "string",          // A detailed description of the item, its appearance, common uses, and any notable features.
  "brand": "string",                // (Optional) Brand name if applicable (e.g., "Coca-Cola", "Apple", "Sony")
  "model": "string",                // (Optional) Model name or number if applicable (e.g., "iPhone 14 Pro")
  "materials": ["string"],          // Array of primary materials (e.g., ["Aluminum"], ["PET Plastic", "HDPE Plastic Cap"], ["Paper", "Ink"])
  "subMaterials": ["string"],       // (Optional) Array of more specific materials or components (e.g., ["Soda-lime glass"], ["Lithium-ion Battery"])
  "categories": ["string"],         // Array of broad categories this item belongs to (e.g., ["Packaging", "Electronics", "Textiles", "Organic"])
  "subCategories": ["string"],      // (Optional) Array of more specific sub-categories (e.g., ["Soda Can", "Smartphone", "T-Shirt", "Fruit Peel"])
  "recyclability": {
    "status": "string",             // Enum: "Recyclable", "NotRecyclable", "ConditionallyRecyclable", "Hazardous", "Unknown"
    "notes": "string",              // Specific recycling instructions or reasons for its status (e.g., "Recyclable if clean and dry. Remove cap.", "Not recyclable due to mixed materials.")
    "commonContaminants": ["string"], // (Optional) List of common things that make this item hard to recycle (e.g., ["Food residue"], ["Plastic film still attached"])
    "regionalVariations": [         // (Optional) If recycling rules vary significantly by region and this info is available
      {
        "region": "string",         // e.g., "California, USA", "EU"
        "status": "string",
        "notes": "string"
      }
    ]
  },
  "disposalInstructions": {
    "general": "string",            // General disposal advice
    "recycling": "string",          // Specific to recycling if applicable
    "compost": "string",            // Specific to composting if applicable
    "landfill": "string",           // If landfill is the only option
    "hazardous": "string"           // If hazardous waste disposal is required
  },
  "environmentalImpact": {
    "production": "string",         // (Optional) Brief notes on environmental impact of production
    "disposalOptions": "string",    // (Optional) Brief notes on impact of different disposal methods
    "positiveAlternatives": ["string"] // (Optional) List of more sustainable alternatives (e.g., ["Reusable water bottle"], ["Cloth shopping bag"])
  },
  "eraOfManufacture": "string",     // (Optional) e.g., "1970-1979", "2020s", "Antique"
  "countryOfOrigin": "string",      // (Optional) If relevant/known
  "rarityScore": "number",          // (Optional) Subjective scale, e.g., 1 (very common) to 10 (very rare). Useful for AI.
  "interestingFacts": ["string"],   // (Optional) Array of interesting facts or trivia about the item, its history, or its material.
  "tags": ["string"],               // (Optional) Array of keywords for searching and AI processing (e.g., ["vintage", "collectible", "single-use", "electronic_waste", "biodegradable"])
  "imageUrl": "string",             // (Optional) URL or path to a representative image of the item.
  "aiHints": {                      // (Optional) Specific hints for AI to generate gamified content
    "discoveryContext": "string",   // What makes discovering this item interesting or unique? (e.g., "Finding this suggests an older site.", "This item is often misidentified.")
    "relatedItemKeywords": ["string"],// Keywords of items that might be thematically related for quests/badges (e.g., ["other 70s items"], ["items with lithium batteries"])
    "potentialLoreTheme": "string", // Suggests a theme for lore snippets (e.g., "History of beverage packaging", "Evolution of portable electronics")
    "challengeIdeas": ["string"]    // AI-seed ideas for challenges, e.g., ["Find 3 variations of this.", "Learn how this item is recycled."]
  },
  "dataSource": "string",           // (Optional) Source of this item's data (e.g., "Manual Entry", "OpenFoodFacts API", "User Submission")
  "lastUpdated": "timestamp"        // Timestamp of the last update to this item's record.
}
```

## Considerations for AI Usage:

*   **Richness of Data:** The more detailed and accurate the fields like `description`, `materials`, `categories`, `tags`, `interestingFacts`, and `aiHints`, the better the AI will be able to:
    *   Generate relevant and engaging hidden badge criteria.
    *   Suggest thematic map unlocks or lore snippets.
    *   Create personalized discovery quests.
    *   Provide accurate information back to the user.
*   **Consistency:** Consistent use of `tags`, `categories`, and `materials` is important for AI pattern recognition.
*   **Rarity Score:** This can be a key input for AI to identify items suitable for "rare find" achievements or quests. It might be initially subjective and refined over time, possibly even with AI assistance by looking at relative scan frequencies.
*   **`aiHints` field:** This field allows for a degree of human guidance to steer AI content generation, making it more targeted and aligned with app goals.

## Evolution:

This schema is a starting point. As the app and its gamification features evolve:
*   New fields may be added (e.g., for specific chemical compositions, detailed life-cycle analysis data).
*   The `aiHints` section could become more structured.
*   Links to external knowledge bases or ontologies could be incorporated.

This structured item database will be a valuable asset not just for gamification but also for enhancing the core classification and educational aspects of the app. 