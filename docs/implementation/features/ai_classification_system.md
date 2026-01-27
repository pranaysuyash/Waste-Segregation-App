# AI Waste Classification System Documentation

## Overview

This document provides comprehensive documentation for the AI-powered waste classification system, including prompts, data models, and implementation guidance for handling user corrections and disagreements.

## 1. PROMPTS

### A. SYSTEM PROMPT

```
You are an expert in international waste classification, recycling, and proper disposal practices. 
You are familiar with global and local waste management rules (including [USER_LOCALE/CITY]), brand-specific packaging, and recycling codes. 
Your goal is to provide accurate, actionable, and safe waste sorting guidance based on the latest environmental standards.
```

### B. MAIN CLASSIFICATION (USER) PROMPT

```
Analyze the provided waste item (with optional image context) and return a comprehensive, strictly formatted JSON object matching the data model below.

Classification Hierarchy & Instructions:

1. Main category (exactly one):
   - Wet Waste (organic, compostable)
   - Dry Waste (recyclable)
   - Hazardous Waste (special handling)
   - Medical Waste (potentially contaminated)
   - Non-Waste (reusable, edible, donatable, etc.)

2. Subcategory: Most specific fit, based on local guidelines if available.
3. Material type: E.g., PET plastic, cardboard, metal, glass, food scraps.
4. Recycling code: For plastics (1–7), if identified.
5. Disposal method: Short instruction (e.g., "Rinse and recycle in blue bin").
6. Disposal instructions (object):
   - primaryMethod: Main recommended action
   - steps: Step-by-step list
   - timeframe: If urgent (e.g., "Immediate", "Within 24 hours")
   - location: Drop-off or bin type
   - warnings: Any safety or contamination warnings
   - tips: Helpful tips
   - recyclingInfo: Extra recycling info
   - estimatedTime: Time needed for disposal
   - hasUrgentTimeframe: Boolean

7. Risk & safety:
   - riskLevel: "safe", "caution", "hazardous"
   - requiredPPE: ["gloves", "mask"], if needed

8. Booleans:
   - isRecyclable, isCompostable, requiresSpecialDisposal, isSingleUse

9. Brand/product/barcode: If present/visible
10. Region/locale: City/country string (e.g., "Bangalore, IN")
    - localGuidelinesReference: If possible (e.g., "BBMP 2024/5")

11. Visual features: Notable characteristics from the image (e.g., ["broken", "dirty", "label missing"])
12. Explanation: Detailed reasoning for decisions
13. Suggested action: E.g., "Recycle", "Compost", "Donate", etc.
14. Color code: Hex value for UI
15. Confidence: 0.0–1.0, with a brief note if confidence < 0.7
16. clarificationNeeded: Boolean if confidence < 0.7 or item ambiguous
17. Alternatives: Up to 2 alternative category/subcategory suggestions, each with confidence and reason

18. Gamification & Engagement:
    - environmentalImpact: Brief summary of the environmental impact (positive/negative).
    - relatedItems: Suggest up to 3 related items and their disposal methods.

19. Model info:
    - modelVersion, modelSource, processingTimeMs, analysisSessionId (set to null if not provided)

20. Multilingual support:
    - If instructionsLang provided, output translated disposal instructions as translatedInstructions for ["hi", "kn"] as well as "en".

21. User fields:
    - Set isSaved, userConfirmed, userCorrection, disagreementReason, userNotes, viewCount to null unless provided in input context.

Rules:
- Reply with only the JSON object (no extra commentary).
- Use null for any unknown fields.
- Strictly match the field names and structure below.
- Do not hallucinate image URLs or user fields unless given.

[Provide the JSON object as described, matching all fields.]
```

### C. CORRECTION/DISAGREEMENT PROMPT

```
A user has reviewed the waste item classification and provided feedback or a correction.  
Please re-analyze the item and return an updated JSON response, as per the data model, with special attention to:

- Areas of disagreement: Update the classification or reasoning as needed.
- clarificationNeeded: Set to true if ambiguity remains or confidence is low.
- disagreementReason: Explain why the original classification may have been incorrect, and how the user correction changes the analysis.

Input Context Example:
- Previous classification: {...}
- User correction: "The item is actually a milk carton, not plastic bottle."
- Reason (if provided): "Shape and texture are different."

Instructions:
- Update all relevant fields, especially category, subcategory, materialType, and explanation.
- Add a disagreementReason field, explaining the change or clarification.
- Use the same JSON model as before; fill all fields as per updated analysis.

Output:
- Only the updated JSON object.
```

## 2. DATA MODEL

### A. WasteClassification Class (Dart)

```dart
class WasteClassification {
  final String id;
  final String itemName;
  final String category;
  final String? subcategory;
  final String? materialType;
  final int? recyclingCode;
  final String explanation;
  final String? disposalMethod;
  final DisposalInstructions disposalInstructions;
  final String? userId;
  final String region;
  final String? localGuidelinesReference;
  final String? imageUrl;
  final String? imageRelativePath;
  final String? thumbnailRelativePath;
  final String? imageHash;
  final Map<String, double>? imageMetrics;
  final List<String> visualFeatures;

  final bool? isRecyclable;
  final bool? isCompostable;
  final bool? requiresSpecialDisposal;
  final bool? isSingleUse;
  final String? colorCode;
  final String? riskLevel;
  final List<String>? requiredPPE;

  final String? brand;
  final String? product;
  final String? barcode;

  final bool? isSaved;
  final bool? userConfirmed;
  final String? userCorrection;
  final String? disagreementReason;
  final String? userNotes;
  final int? viewCount;
  final bool? clarificationNeeded;
  final double? confidence;
  final String? modelVersion;
  final int? processingTimeMs;
  final String? modelSource;
  final String? analysisSessionId;

  final List<AlternativeClassification> alternatives;
  final String? suggestedAction;
  final bool? hasUrgentTimeframe;
  final String? instructionsLang;
  final Map<String, String>? translatedInstructions;
  
  final String? source;
  final DateTime timestamp;
  final List<String>? reanalysisModelsTried;
  final String? confirmedByModel;
  final int? pointsAwarded;
  final String? environmentalImpact;
  final List<String>? relatedItems;

  // Constructor and methods...
}

class AlternativeClassification {
  final String category;
  final String? subcategory;
  final double confidence;
  final String reason;
  // Constructor and methods...
}

class DisposalInstructions {
  final String primaryMethod;
  final List<String> steps;
  final String? timeframe;
  final String? location;
  final List<String>? warnings;
  final List<String>? tips;
  final String? recyclingInfo;
  final String? estimatedTime;
  final bool hasUrgentTimeframe;
  // Constructor and methods...
}
```

### B. JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "WasteClassification",
  "type": "object",
  "properties": {
    "itemName": { "type": "string" },
    "category": { "type": "string" },
    "subcategory": { "type": ["string", "null"] },
    "materialType": { "type": ["string", "null"] },
    "recyclingCode": { "type": ["integer", "null"] },
    "explanation": { "type": "string" },
    "disposalMethod": { "type": ["string", "null"] },
    "disposalInstructions": {
      "type": "object",
      "properties": {
        "primaryMethod": { "type": "string" },
        "steps": { "type": "array", "items": { "type": "string" } },
        "timeframe": { "type": ["string", "null"] },
        "location": { "type": ["string", "null"] },
        "warnings": { "type": "array", "items": { "type": "string" } },
        "tips": { "type": "array", "items": { "type": "string" } },
        "recyclingInfo": { "type": ["string", "null"] },
        "estimatedTime": { "type": ["string", "null"] },
        "hasUrgentTimeframe": { "type": "boolean" }
      },
      "required": ["primaryMethod", "steps", "hasUrgentTimeframe"]
    },
    "region": { "type": "string" },
    "localGuidelinesReference": { "type": ["string", "null"] },
    "imageUrl": { "type": ["string", "null"] },
    "imageHash": { "type": ["string", "null"] },
    "imageMetrics": { "type": ["object", "null"] },
    "visualFeatures": { "type": "array", "items": { "type": "string" } },
    "isRecyclable": { "type": ["boolean", "null"] },
    "isCompostable": { "type": ["boolean", "null"] },
    "requiresSpecialDisposal": { "type": ["boolean", "null"] },
    "isSingleUse": { "type": ["boolean", "null"] },
    "colorCode": { "type": ["string", "null"] },
    "riskLevel": { "type": ["string", "null"] },
    "requiredPPE": { "type": "array", "items": { "type": "string" } },
    "brand": { "type": ["string", "null"] },
    "product": { "type": ["string", "null"] },
    "barcode": { "type": ["string", "null"] },
    "isSaved": { "type": ["boolean", "null"] },
    "userConfirmed": { "type": ["boolean", "null"] },
    "userCorrection": { "type": ["string", "null"] },
    "disagreementReason": { "type": ["string", "null"] },
    "userNotes": { "type": ["string", "null"] },
    "viewCount": { "type": ["integer", "null"] },
    "clarificationNeeded": { "type": ["boolean", "null"] },
    "confidence": { "type": ["number", "null"], "minimum": 0.0, "maximum": 1.0 },
    "modelVersion": { "type": ["string", "null"] },
    "processingTimeMs": { "type": ["integer", "null"] },
    "modelSource": { "type": ["string", "null"] },
    "analysisSessionId": { "type": ["string", "null"] },
    "environmentalImpact": { "type": ["string", "null"] },
    "relatedItems": {
      "type": ["array", "null"],
      "items": { "type": "string" }
    },
    "alternatives": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "category": { "type": "string" },
          "subcategory": { "type": ["string", "null"] },
          "confidence": { "type": "number" },
          "reason": { "type": "string" }
        },
        "required": ["category", "confidence", "reason"]
      }
    },
    "suggestedAction": { "type": ["string", "null"] },
    "hasUrgentTimeframe": { "type": ["boolean", "null"] },
    "instructionsLang": { "type": ["string", "null"] },
    "translatedInstructions": {
      "type": "object",
      "properties": {
        "en": { "type": "string" },
        "hi": { "type": "string" },
        "kn": { "type": "string" }
      }
    }
  },
  "required": [
    "itemName", "category", "explanation", "disposalInstructions", "region", "visualFeatures", "alternatives"
  ]
}
```

## 3. CORRECTION/DISAGREEMENT WORKFLOW

### When to Use the Correction Prompt

Use the Correction/Disagreement Prompt whenever a user disagrees with the AI's output and submits a correction or feedback on a classification.

**Example User Actions Triggering It:**
- User clicks "Wrong Category" and selects a different one
- User edits the suggested disposal method or subcategory
- User types a note like "This is not plastic, it's tetrapak"
- User adds a photo/note saying the detected item is not what the app thinks

### Step-by-Step Usage Flow

1. **Original Classification Flow**
   - User uploads/takes a photo
   - AI runs the main prompt and produces output (the full JSON)
   - Output is displayed to the user (category, subcategory, instructions, etc)

2. **User Correction Event**
   - User indicates disagreement and supplies a correction:
     - Selects a different category/subcategory
     - Adds a textual reason
     - (Optional) Adds a new image or comment

3. **App Constructs Correction Prompt**
   - App gathers:
     - The previous AI JSON output (from step 1)
     - The user's correction (e.g., "Should be 'Carton' not 'Plastic'")
     - Any extra user reason/comment

4. **App Sends Correction Prompt to LLM**
   - Use the Correction/Disagreement Prompt (Part C)
   - Fill in the input context section in the prompt:
     - Include the previous AI output (the JSON)
     - Include the user correction and reason
   - Send this as the new LLM prompt

5. **LLM Returns Updated JSON**
   - LLM analyzes the user feedback, revises its classification, reasoning, and all other fields
   - LLM sets disagreementReason to explain the change or highlight ambiguity
   - If confidence is low, sets clarificationNeeded: true

6. **Updated Output is Stored/Displayed**
   - Your app saves both the original and corrected output for analytics/model improvement
   - The corrected output is shown to the user
   - This event can also be logged for AI retraining and continuous learning

### Example Implementation

```dart
// On user correction event:
Future<WasteClassification> handleUserCorrection(
  WasteClassification originalClassification,
  String userCorrection,
  String? userReason, {
  Uint8List? imageBytes,
  File? imageFile,
}) async {
  // Prepare the correction prompt
  final correctionPrompt = _getCorrectionPrompt(
    originalClassification.toJson(),
    userCorrection,
    userReason,
  );

  // Send to AI service and get corrected classification
  final correctedClassification = await _sendCorrectionToAI(correctionPrompt);
  
  // Store both original and corrected for analytics
  await _storeCorrectionEvent(originalClassification, correctedClassification);
  
  return correctedClassification;
}
```

### Example Correction Flow

**Original AI Output:**
```json
{
  "itemName": "Plastic Water Bottle",
  "category": "Dry Waste",
  "subcategory": "Plastic",
  ...
}
```

**User Correction:**
- User says: "This is not plastic, it's a tetrapak juice box."
- Optionally provides reason: "See the folds and foil inside."

**LLM's Updated Output:**
```json
{
  "itemName": "Tetrapak Juice Box",
  "category": "Dry Waste",
  "subcategory": "Carton",
  "explanation": "User indicated the item is a tetrapak. Based on visible folds and foil inside, this is consistent with composite beverage cartons, not plastic bottles.",
  "disagreementReason": "Original classification was based on shape, but user clarified material and construction.",
  ...
}
```

## 4. IMPLEMENTATION NOTES

### Key Points
- This is a specialized flow, NOT your default prompt
- Use only when the user flags a problem/correction
- Always store both the original and corrected outputs for model improvement
- Over time, collect these cases to retrain or fine-tune your AI
- The correction prompt helps improve classification accuracy through user feedback

### API Integration
- Use the same API endpoints as the main classification
- Include the correction prompt as the user message
- Optionally include the original image for visual context
- Set appropriate temperature (0.1) for consistent corrections

### Data Storage
- Store correction events for analytics
- Track disagreement patterns to improve prompts
- Use feedback for continuous model improvement
- Monitor correction frequency by category/item type

This comprehensive system provides accurate waste classification with built-in correction mechanisms to continuously improve through user feedback.

## 3. AI Service (`lib/services/ai_service.dart`)

### A. API Key Management & Security

- **Environment Variables**: API keys for OpenAI and Gemini are **not** hardcoded. They are managed using a `.env` file in the project root.
- **Access in Code**: Keys are accessed via `String.fromEnvironment()` in `lib/utils/constants.dart` (e.g., `ApiConfig.openAiApiKey`, `ApiConfig.apiKey` for Gemini).
- **Setup**: Developers must create a `.env` file from `.env.example` (if provided) or manually, and populate it with their API keys. See `docs/config/environment_variables.md` for detailed setup instructions.
- **Security**: The `.env` file is listed in `.gitignore` to prevent accidental commits of sensitive keys.

### B. Model Fallback Strategy

The `AiService` implements a multi-layered fallback strategy to ensure resilience and availability:

1.  **Primary Model**: `ApiConfig.primaryModel` (e.g., 'gpt-4.1-nano') - Attempted first.
2.  **Secondary Model 1**: `ApiConfig.secondaryModel1` (e.g., 'gpt-4o-mini') - Used if the primary model fails.
3.  **Secondary Model 2**: `ApiConfig.secondaryModel2` (e.g., 'gpt-4.1-mini') - Used if the first secondary model fails.
4.  **Tertiary Model (Gemini)**: `ApiConfig.tertiaryModel` (e.g., 'gemini-2.0-flash') using `ApiConfig.apiKey` for Gemini - Used if all OpenAI models fail.

This tiered approach helps maintain functionality even if one or more models are unavailable or experience issues.

### C. Core Classification Logic

The AI service uses a combination of machine learning models and human-in-the-loop to classify waste items. The classification process involves the following steps:

1. **Image Processing**: The AI service processes the image of the waste item to extract visual features.
2. **Feature Extraction**: The extracted features are fed into the machine learning model to predict the category of the waste item.
3. **Human Review**: If the machine learning model's prediction is not confident enough or if the item is ambiguous, it is sent to a human reviewer for further analysis.
4. **Classification**: The human reviewer provides a final classification based on their analysis.

The AI service ensures that the classification process is transparent and explainable. The AI service provides detailed reasoning for its classification decisions, which helps users understand the reasoning behind the AI's classification.

This comprehensive system provides accurate waste classification with built-in correction mechanisms to continuously improve through user feedback. 