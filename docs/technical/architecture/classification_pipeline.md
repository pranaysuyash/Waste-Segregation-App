# Classification Pipeline Architecture

## Overview
This document provides a detailed overview of the end-to-end classification pipeline, from image capture to result display, with particular focus on the multi-object segmentation implementation based on the video demo review from May 2025.

## Current Implementation Status

Based on the video demo review, the classification pipeline is functional but has important gaps:

- **Basic Classification Flow**: Working end-to-end for single, clear objects
- **Image Capture/Upload**: Both camera capture and gallery upload function well
- **Results Display**: Comprehensive information shown, though with UI overflow issues
- **Segmentation UI**: Toggle and grid UI present but functionality appears limited
- **Multi-Object Handling**: Inconsistent results for complex scenes with multiple objects

## High-Level Flow

The complete classification pipeline consists of these major steps:

1. **Image Acquisition** (Camera/Gallery)
2. **Preprocessing & Segmentation** 
3. **Classification API Request**
4. **Result Processing**
5. **Display & User Feedback**

## Detailed Component Architecture

### 1. Image Acquisition

#### Current Implementation
- Camera integration via Flutter camera plugin (working)
- Gallery selection via image_picker (working)
- Basic image preview and confirmation screen (working)

#### Architecture Diagram

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Camera View │     │ Image Preview│     │Analyze Screen│
│              │────>│ & Confirm    │────>│ w/ Segment   │
│              │     │              │     │ Toggle       │
└──────────────┘     └──────────────┘     └──────────────┘
       ▲                                         │
       │           ┌──────────────┐              │
       └───────────┤ Gallery View │◄─────────────┘
                   │              │
                   └──────────────┘
```

#### Key Components (Pseudocode)
```
CameraScreen:
  - Initialize camera
  - Capture image function
  - Gallery selection function
  - Navigation to preview screen

ImagePreviewScreen:
  - Display captured/selected image
  - Confirmation controls
  - Navigation to analysis screen
```

### 2. Preprocessing & Segmentation

#### Current Implementation
- Basic image preparation (likely resizing/compression)
- Segmentation toggle present but functionality limited to UI grid overlay
- No visible actual object detection/segmentation in the demo

#### Planned Segmentation Architecture

```
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│ Image Input   │    │ Preprocessor  │    │Segmentation   │
│ (from camera/ │───>│ - Resize      │───>│Model (SAM Lite│
│  gallery)     │    │ - Normalize   │    │or GluonCV)    │
└───────────────┘    └───────────────┘    └───────────────┘
                                                  │
┌───────────────┐    ┌───────────────┐           │
│ User Selection│    │ Segmentation  │           │
│ Interface     │<───│ Results UI    │<──────────┘
│ (Tap to select│    │ - Object      │
│  objects)     │    │   Boundaries  │
└───────────────┘    └───────────────┘
         │
         ▼
┌───────────────┐
│ Selected      │
│ Segments sent │
│ to classifier │
└───────────────┘
```

#### Key Components (Pseudocode)
```
SegmentationManager:
  - Process image for segmentation
  - Select optimal model based on device capabilities
  - Support user refinement (tap, box, scribble)
  - Extract selected segments for classification

SegmentationModelService:
  - Run segmentation using SAM or other models
  - Handle server-side or local processing
  - Support different refinement methods
  - Return segmentation results

SegmentationResult:
  - Store masks, bounding boxes, confidence scores
  - Support serialization and deserialization

UserInteraction:
  - Support different interaction types (tap, box, scribble)
  - Store interaction parameters
```

### 3. Classification API Request

#### Current Implementation
- Working API requests to Gemini Vision API
- Possible fallback to other models (not visibly demonstrated)
- Response parsing into structured data

#### Enhanced Classification Flow

```
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│ Segmented or  │    │ Cache Check   │    │ API Service   │
│ Whole Image   │───>│ (Perceptual   │───>│ - Gemini      │
│               │    │  Hashing)     │    │ - OpenAI      │
└───────────────┘    └───────────────┘    │ - TFLite      │
                            │             └───────────────┘
                            │                     │
                            ▼                     ▼
                     ┌───────────────┐    ┌───────────────┐
                     │ Cached Result │    │ API Response  │
                     │ (if available)│    │ Processing    │
                     └───────────────┘    └───────────────┘
                            │                     │
                            └─────────┬───────────┘
                                      │
                                      ▼
                             ┌───────────────┐
                             │ Classification│
                             │ Result Model  │
                             └───────────────┘
```

#### Key Components (Pseudocode)
```
AIService:
  - Classify a single image
  - Classify multiple segments
  - Check cache before API calls
  - Handle fallback logic between models
  - Process API responses
  
CacheService:
  - Store and retrieve cached classifications
  - Use perceptual hashing for similarity
  - Manage cache size and eviction
```

### 4. Result Processing

#### Current Implementation
- Basic response parsing into waste categories
- Detection of material type and recyclability
- Recycling code identification (sometimes inaccurate in demo)

#### Enhanced Processing Flow

```
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│ API Response  │    │ Response      │    │ Enrichment    │
│ JSON          │───>│ Parsing       │───>│ - Facts       │
│               │    │               │    │ - Instructions│
└───────────────┘    └───────────────┘    └───────────────┘
                                                  │
┌───────────────┐    ┌───────────────┐           │
│ Final         │    │ Results       │           │
│ Classification│<───│ Validation    │<──────────┘
│ Result        │    │               │
└───────────────┘    └───────────────┘
```

#### Key Components (Pseudocode)
```
ResponseParser:
  - Parse API response based on source (Gemini, OpenAI, Local)
  - Extract structured data from text if needed
  - Create ClassificationResult objects
  - Enrich with educational content
  - Parse waste categories and recycling codes
```

### 5. Display & User Feedback

#### Current Implementation
- Results screen with comprehensive information
- Issue: UI text overflow in some cases
- Issue: No visible user feedback mechanism for AI accuracy
- Issue: "Recycling Code" section has inconsistent display

#### Improved Results Screen Architecture

```
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│ Classification│    │ Results       │    │ UI Components │
│ Results       │───>│ Formatter     │───>│ - Material    │
│               │    │               │    │   Info        │
└───────────────┘    └───────────────┘    │ - Disposal    │
                                          │   Instructions│
                                          │ - Educational │
                                          │   Facts       │
                                          └───────────────┘
                                                  │
┌───────────────┐    ┌───────────────┐           │
│ User Feedback │    │ Action        │           │
│ Collection    │<───│ Buttons       │<──────────┘
│ - Accuracy    │    │ - Save        │
│ - Corrections │    │ - Share       │
└───────────────┘    └───────────────┘
```

#### Key Components (Pseudocode)
```
ClassificationResultScreen:
  - Display classification results
  - Show immediate reward animations
  - Collect user feedback on accuracy
  - Support export/sharing
  - Fix overflow issues with Flexible/Expanded widgets
  - Show dynamic recycling code information
```

## Tiered Feature Strategy Based on Subscription Level

Based on recent feedback, the classification pipeline will implement a tiered approach to features:

### Free Tier (Ad-Supported)
- **Basic Classification**: Single-object classification of the dominant item in an image
- **No Segmentation**: The entire image is processed as one unit
- **Online Only**: No offline classification capabilities
- **Basic Results**: Standard classification details and disposal instructions

### Middle Tier (Premium / Eco-Plus)
- **Automatic Multi-Object Segmentation**: When online, the app automatically identifies and classifies multiple waste items in a single image
- **Limited Offline Classification**: Basic on-device model for common waste items when offline
- **Enhanced Results**: More detailed classification with better material analysis

### Top Tier (Pro / Eco-Master)
- **Interactive Segmentation**: Users can tap, draw boxes, or define boundaries to precisely select specific objects for classification
- **Component-Level Analysis**: For complex items, users can analyze sub-components separately (e.g., bottle and cap)
- **Advanced Offline Classification**: More comprehensive on-device model with basic segmentation capabilities
- **Premium Results**: Most detailed classification with advanced recycling information

## Implementation Roadmap

### Phase 1: Core Classification (Current/Next Sprint)
- Fix UI overflow issues in result display
- Implement AI accuracy feedback loop
- Improve recycling code display consistency

### Phase 2: Automatic Segmentation (Middle Tier Feature)
- Implement SAM/GluonCV integration for automatic object detection
- Create UI for displaying multiple classification results
- Design upgrade prompts for free users

### Phase 3: Interactive Segmentation (Top Tier Feature)
- Develop interactive object selection tools
- Implement promptable segmentation via SAM
- Create advanced UI for segment refinement

### Phase 4: Offline & Component Analysis
- Implement tiered offline models
- Develop component-level analysis for complex items
- Complete the full tiered feature set

## Success Metrics

- **Segmentation Accuracy**: Measure precision of object boundaries
- **Classification Consistency**: Ensure same objects get same results when segmented
- **User Satisfaction**: Track feedback on segmentation and classification accuracy
- **Subscription Conversion**: Monitor upgrades driven by segmentation features
- **Performance Metrics**: Ensure acceptable processing times across device tiers

## Conclusion

The classification pipeline architecture provides a framework for enhancing the app's core functionality with advanced segmentation features. By implementing these improvements and adopting a tiered approach, the app will deliver significant value to users while creating clear incentives for subscription upgrades. The focus on fixing the inconsistencies observed in the demo while building toward a more sophisticated segmentation system will ensure both immediate improvement and long-term competitive advantage.
