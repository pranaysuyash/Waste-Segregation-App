# AI Model Management and Retraining Strategy

## Overview
This document outlines how user feedback from the AI accuracy feedback loop will be collected, processed, and utilized to improve classification accuracy over time. It covers both cloud-based and on-device models, versioning strategies, and evaluation processes.

## Current AI Implementation Status

Based on the video demo review (May 2025), the current AI implementation:

- Successfully classifies clear, single objects (e.g., cake) with good accuracy
- Struggles with complex scenes containing multiple objects (inconsistent results for basket of toys)
- Lacks an implemented user feedback mechanism for accuracy improvement
- Has a UI placeholder for segmentation but needs functional implementation
- Shows some inconsistencies in recycling code identification

## User Feedback Collection

### Data Collection Points

#### Classification Result Screen
- **"Was this classification correct?"** prompt 
  - Yes/No binary feedback
  - "Correct It" option for detailed corrections
- **Correction Interface**
  - Category selection
  - Material type correction
  - Recyclability/compostability toggles
  - Free-text field for additional information

#### Feedback Data Structure
```dart
// Pseudocode for feedback data model
class ClassificationFeedback {
  final String classificationId;
  final String imageHash;
  final bool isCorrect;
  final Map<String, dynamic>? userCorrections;
  final DateTime timestamp;
  final String userId;
  final SubscriptionTier userTier;
  
  // Optional fields for analysis
  final ClassificationSource originalSource; // Gemini, OpenAI, TFLite
  final double originalConfidence;
}

class UserCorrection {
  final String originalItemName;
  final String correctedItemName;
  final WasteCategory originalCategory;
  final WasteCategory correctedCategory;
  final String? originalMaterial;
  final String? correctedMaterial;
  final bool originalIsRecyclable;
  final bool correctedIsRecyclable;
  final bool originalIsCompostable;
  final bool correctedIsCompostable;
  final RecyclingCode? originalRecyclingCode;
  final RecyclingCode? correctedRecyclingCode;
  final String? additionalNotes;
}
```

### Storage and Privacy

#### Local Storage
- Store feedback data in encrypted Hive box
- Include image hash but not the actual image
- Aggregate multiple feedback points for the same image hash

#### Cloud Storage (Firebase)
- Send anonymized feedback data to Firestore collection
- Strip personally identifiable information
- Maintain image hash to link feedback to classification without storing images

#### Privacy Policy Implications
- Clear disclosure in privacy policy about feedback collection
- Option to disable anonymous feedback contribution in settings
- Regular purging of old feedback data after model updates

### Collection Frequency Controls
```dart
// Pseudocode for feedback submission policy
bool shouldRequestFeedback(UserProfile profile) {
  // Avoid asking too frequently
  if (profile.lastFeedbackRequestTime != null) {
    final hoursSinceLastRequest = DateTime.now()
        .difference(profile.lastFeedbackRequestTime!)
        .inHours;
    if (hoursSinceLastRequest < 24) {
      return false;
    }
  }
  
  // More likely to ask for feedback on uncertain classifications
  final currentClassification = getCurrentClassification();
  if (currentClassification.confidence < 0.85) {
    return true;
  }
  
  // Random sampling for other classifications
  return Random().nextDouble() < 0.3; // 30% chance
}
```

## Feedback Processing Pipeline

### Data Aggregation

#### Feedback Aggregation Service
```dart
// Pseudocode for aggregation service
class FeedbackAggregationService {
  Future<AggregatedFeedback> aggregateFeedbackForImageHash(String imageHash) async {
    final feedbackList = await _fetchFeedbackByImageHash(imageHash);
    
    // Count agreements/disagreements
    int correctCount = 0;
    int incorrectCount = 0;
    Map<String, int> categoryVotes = {};
    Map<String, int> materialVotes = {};
    
    for (final feedback in feedbackList) {
      if (feedback.isCorrect) {
        correctCount++;
      } else {
        incorrectCount++;
        
        // Count correction votes
        if (feedback.userCorrections != null) {
          _countVote(categoryVotes, feedback.userCorrections!.correctedCategory.toString());
          _countVote(materialVotes, feedback.userCorrections!.correctedMaterial ?? 'unknown');
          // Count other corrections...
        }
      }
    }
    
    return AggregatedFeedback(
      imageHash: imageHash,
      totalFeedback: feedbackList.length,
      correctPercentage: feedbackList.isEmpty ? 0 : correctCount / feedbackList.length,
      categoryConsensus: _findConsensus(categoryVotes),
      materialConsensus: _findConsensus(materialVotes),
      // Other consensus values...
    );
  }
  
  void _countVote(Map<String, int> votes, String value) {
    votes[value] = (votes[value] ?? 0) + 1;
  }
  
  String? _findConsensus(Map<String, int> votes) {
    if (votes.isEmpty) return null;
    
    final totalVotes = votes.values.reduce((a, b) => a + b);
    final threshold = totalVotes * 0.7; // 70% agreement required
    
    final mostVotedEntry = votes.entries
        .reduce((a, b) => a.value > b.value ? a : b);
        
    return mostVotedEntry.value >= threshold ? mostVotedEntry.key : null;
  }
}
```

### Data Validation

#### Automated Validation
- Detect and exclude outlier feedback
- Check for consistent patterns in user corrections
- Identify users with high disagreement rates with the consensus

#### Manual Review Process
- Dashboard for reviewing aggregated feedback
- Tools to visualize feedback patterns
- Interface for approving correctible items for model retraining

### Threshold-Based Decision Making
```dart
// Pseudocode for decision thresholds
class ModelUpdateDecider {
  Future<List<ModelUpdateCandidate>> findUpdateCandidates() async {
    final feedbackAggregator = FeedbackAggregationService();
    final results = <ModelUpdateCandidate>[];
    
    // Get image hashes with sufficient feedback volume
    final imageHashes = await _getImageHashesWithMinimumFeedback(5);
    
    for (final hash in imageHashes) {
      final aggregated = await feedbackAggregator.aggregateFeedbackForImageHash(hash);
      
      // Check if accuracy is poor and consensus is strong
      if (aggregated.correctPercentage < 0.5 && 
          (aggregated.categoryConsensus != null || 
           aggregated.materialConsensus != null)) {
        
        results.add(ModelUpdateCandidate(
          imageHash: hash,
          aggregatedFeedback: aggregated,
          updatePriority: _calculatePriority(aggregated),
        ));
      }
    }
    
    return results;
  }
  
  double _calculatePriority(AggregatedFeedback feedback) {
    // Prioritize by:
    // 1. Lower accuracy (more incorrect)
    // 2. Higher feedback volume
    // 3. Stronger consensus
    
    double priorityScore = (1.0 - feedback.correctPercentage) * 0.6; // 60% weight
    priorityScore += min(1.0, feedback.totalFeedback / 20.0) * 0.3; // 30% weight
    
    // Consensus strength (10% weight)
    double consensusStrength = 0.0;
    if (feedback.categoryConsensus != null) consensusStrength += 0.5;
    if (feedback.materialConsensus != null) consensusStrength += 0.5;
    
    priorityScore += consensusStrength * 0.1;
    
    return priorityScore;
  }
}
```

## Model Retraining Process

### Cloud API Model Updates

#### Prompt Engineering Improvements
- Refine prompts based on user feedback
- Add specific examples for commonly misclassified items
- Incorporate detailed instructions for challenging categories

```dart
// Pseudocode for prompt management
class PromptManager {
  Future<String> generateOptimizedPrompt(File imageFile, PromptConfig config) async {
    // Base prompt template
    String prompt = "Classify this waste item with detailed information about disposal. ";
    
    // Add configuration for segmentation
    if (config.isSegmented) {
      prompt += "This image contains a single isolated object after segmentation. ";
    }
    
    // Add specific guidance for challenging categories
    final imageFeatures = await _detectBasicImageFeatures(imageFile);
    
    if (imageFeatures.containsTransparentObject) {
      prompt += "Pay special attention to transparent materials like glass or clear plastics. ";
    }
    
    if (imageFeatures.hasMixedMaterials) {
      prompt += "This item may contain multiple materials. Identify the primary material and any secondary components. ";
    }
    
    // Add examples for commonly misclassified items
    final misclassifiedExamples = await _getMisclassificationExamples(3);
    if (misclassifiedExamples.isNotEmpty) {
      prompt += "\n\nHere are examples of similar items: \n";
      for (final example in misclassifiedExamples) {
        prompt += "- ${example.itemName}: ${example.correctCategory}, ${example.correctMaterial}\n";
      }
    }
    
    // Add structured output format
    prompt += "\n\nProvide a structured response with the following information:\n";
    prompt += "- Item name\n- Waste category (Wet Waste, Dry Waste, Hazardous Waste, Medical Waste, or Non-Waste)\n";
    prompt += "- Material type\n- Recyclability\n- Recycling code (if applicable)\n";
    prompt += "- Disposal instructions\n- Explanation";
    
    return prompt;
  }
}
```

#### Model Selection Strategy
- A/B testing between different AI models
- Periodic evaluation of Gemini vs. OpenAI vs. other providers
- Model selection based on accuracy metrics and cost

#### API Parameter Optimization
- Adjust temperature and other parameters based on feedback
- Use higher precision for critical classifications
- Balance cost, speed, and accuracy

### On-Device Model Updates

#### TFLite Model Versioning
- Train lite models based on aggregated feedback
- Separate models for different subscription tiers:
  - Basic model (50-100 common items) for Premium tier
  - Advanced model (200+ items with segmentation) for Pro tier

#### Update Distribution Strategy
- Models packaged with app for essential objects
- Dynamic model updates via Firebase Remote Config
- Background download for larger models (Pro tier)

```dart
// Pseudocode for model update manager
class OnDeviceModelManager {
  Future<void> checkForModelUpdates(SubscriptionTier userTier) async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.fetchAndActivate();
    
    final String latestBasicModelVersion = remoteConfig.getString('basic_model_version');
    final String latestAdvancedModelVersion = remoteConfig.getString('advanced_model_version');
    
    // Check current versions
    if (userTier == SubscriptionTier.premium) {
      if (_needsUpdate('basic_model', latestBasicModelVersion)) {
        await _downloadModel('basic_model', latestBasicModelVersion);
      }
    } else if (userTier == SubscriptionTier.pro) {
      if (_needsUpdate('advanced_model', latestAdvancedModelVersion)) {
        // Pro tier gets the advanced model
        await _downloadModel('advanced_model', latestAdvancedModelVersion);
      }
    }
  }
  
  Future<void> _downloadModel(String modelName, String version) async {
    // Implement background download
    // Handle download failures
    // Verify model integrity
    // Swap models atomically
  }
}
```

#### Quantization and Optimization
- Apply post-training quantization for smaller model size
- Optimize for specific device capabilities (CPU/GPU/NPU)
- Prune model for essential waste categories only

### Segmentation Model Management

#### SAM Lite Updates
- Package stripped-down version with app updates
- Dynamic prompt-based controls for interactive segmentation
- Optimize for mobile performance

#### Segmentation Prompt Strategy
- Tune prompts based on user interactions
- Learn from successful vs. unsuccessful segmentations
- Adjust confidence thresholds for boundary detection

```dart
// Pseudocode for segmentation prompt generation
class SegmentationPromptManager {
  Future<Map<String, dynamic>> generateSegmentationPrompt(
    File imageFile,
    UserInteraction interaction
  ) async {
    final Map<String, dynamic> prompt = {};
    
    switch (interaction.type) {
      case InteractionType.tap:
        prompt['point_coords'] = [interaction.point!.x, interaction.point!.y];
        prompt['point_labels'] = [1]; // 1 for positive point
        break;
        
      case InteractionType.box:
        prompt['box'] = [
          interaction.rect!.left,
          interaction.rect!.top,
          interaction.rect!.right,
          interaction.rect!.bottom,
        ];
        break;
        
      case InteractionType.scribble:
        final pointsList = interaction.points!.map((p) => [p.x, p.y]).toList();
        prompt['point_coords'] = pointsList;
        prompt['point_labels'] = List.generate(
          pointsList.length,
          (_) => interaction.isPositive ? 1 : 0,
        );
        break;
    }
    
    // Add parameters based on success history
    final successRates = await _getInteractionSuccessRates();
    prompt['pred_iou_thresh'] = successRates.getOptimalIouThreshold();
    
    return prompt;
  }
}
```

## Model Versioning Strategy

### Version Naming Convention
- Semantic versioning (Major.Minor.Patch)
  - Major: Significant architecture changes
  - Minor: New features or significant improvements
  - Patch: Bug fixes and small optimizations
- Version metadata includes:
  - Training data timestamp
  - Model architecture identifier
  - Optimization level

### Model Registry
```dart
// Pseudocode for model registry
class ModelRegistry {
  Future<void> registerModelVersion(ModelRegistration registration) async {
    // Store in Firestore
    await FirebaseFirestore.instance
        .collection('modelVersions')
        .doc(registration.modelType)
        .collection('versions')
        .doc(registration.versionString)
        .set({
          'releaseDate': FieldValue.serverTimestamp(),
          'architecture': registration.architecture,
          'trainingDataTimestamp': registration.trainingDataTimestamp,
          'accuracy': registration.accuracy,
          'size': registration.sizeKb,
          'changes': registration.changeDescription,
          'compatibleAppVersions': registration.compatibleAppVersions,
        });
  }
  
  Future<ModelVersion?> getLatestCompatibleVersion(
    String modelType,
    String appVersion
  ) async {
    // Query for latest compatible version
    final query = await FirebaseFirestore.instance
        .collection('modelVersions')
        .doc(modelType)
        .collection('versions')
        .where('compatibleAppVersions', arrayContains: appVersion)
        .orderBy('releaseDate', descending: true)
        .limit(1)
        .get();
        
    if (query.docs.isEmpty) {
      return null;
    }
    
    return ModelVersion.fromFirestore(query.docs.first);
  }
}
```

### Compatibility Management
- Backward compatibility for older app versions
- Graceful fallback for incompatible models
- Minimum app version requirements for certain models

## Model Evaluation Framework

### Metrics

#### Accuracy Metrics
- Overall accuracy percentage
- Category-specific precision and recall
- Confusion matrix for waste categories
- Material identification accuracy

#### Performance Metrics
- Inference time (device-specific benchmarks)
- Memory usage
- Battery impact
- Network bandwidth (for cloud models)

#### User Satisfaction Metrics
- Correction rate (% of results corrected)
- User retention correlation
- Feature usage patterns by model version

### A/B Testing

#### Testing Methodology
- Segment users for model comparison
- Distribute different models/prompts to test groups
- Collect performance and satisfaction metrics
- Statistical analysis of results

```dart
// Pseudocode for A/B test manager
class ModelABTestManager {
  Future<String> determineUserTestGroup(String userId) async {
    // Deterministic but evenly distributed assignment
    final testHash = _computeHash(userId);
    final groupIndex = testHash % _currentTestGroups.length;
    return _currentTestGroups[groupIndex];
  }
  
  Future<ModelConfig> getModelConfigForUser(String userId) async {
    final group = await determineUserTestGroup(userId);
    return await _getConfigForGroup(group);
  }
  
  Future<void> recordTestResult(
    String userId,
    String testGroup,
    ModelTestResult result
  ) async {
    // Store result for analysis
    await FirebaseFirestore.instance
        .collection('abTests')
        .doc(_currentTestId)
        .collection('results')
        .add({
          'userId': userId,
          'testGroup': testGroup,
          'timestamp': FieldValue.serverTimestamp(),
          'isCorrect': result.isCorrect,
          'confidence': result.confidence,
          'processingTimeMs': result.processingTimeMs,
          'userCorrected': result.userCorrected,
        });
  }
}
```

#### Success Criteria
- Primary metric: Classification accuracy
- Secondary metrics: Processing speed, user corrections, feature usage
- Minimum improvement threshold for adoption

## Continuous Learning Loop

### End-to-End Process

```
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│ User          │    │ Feedback      │    │ Aggregation   │
│ Corrections   │───>│ Collection    │───>│ & Validation  │
│               │    │               │    │               │
└───────────────┘    └───────────────┘    └───────────────┘
                                                  │
┌───────────────┐    ┌───────────────┐           │
│ Model         │    │ Testing &     │           │
│ Deployment    │<───│ Evaluation    │<──────────┘
│               │    │               │
└───────────────┘    └───────────────┘
        │                    ▲
        └────────────────────┘
```

### Timeline Expectations
- Rapid updates for critical issues (1-2 weeks)
- Regular prompt engineering updates (monthly)
- On-device model updates (quarterly)
- Major model architecture changes (annually)

### User Impact Minimization
- Background updates without disruption
- Progressive rollouts to detect issues early
- Transparent messaging about model improvements

## Subscription Tier Considerations

### Free Tier
- Basic cloud API access
- Standard prompts without optimization
- Limited to general classification without segmentation
- No offline model access

### Premium Tier
- Priority cloud API access
- Optimized prompts with error correction
- Automatic segmentation when online
- Basic offline model for common items

### Pro Tier
- Highest priority API access
- Most sophisticated prompts with correction and comparison
- Interactive segmentation with user refinement
- Advanced offline model with basic segmentation

## Implementation Timeline

### Phase 1: Core Feedback Loop (1-2 Months)
- Implement "Was this classification correct?" UI
- Set up feedback storage and aggregation
- Create basic dashboard for monitoring feedback

### Phase 2: Prompt Engineering (2-3 Months)
- Implement dynamic prompt generation
- Develop prompt templates for challenging categories
- Create A/B testing framework for prompt optimization

### Phase 3: On-Device Models (3-4 Months)
- Develop and train basic TFLite model
- Implement model update system
- Create model registry and version management

### Phase 4: Advanced Segmentation (4-6 Months)
- Implement SAM Lite for client-side segmentation
- Develop interactive refinement tools
- Optimize segmentation performance for mobile

## Conclusion

This AI model management and retraining strategy provides a comprehensive framework for continually improving the app's classification accuracy through user feedback. By implementing a systematic feedback collection process, robust data validation, and a structured retraining approach, we can address the inconsistencies observed in the demo and deliver increasingly accurate results over time.

The strategy is aligned with the subscription tier model, providing appropriate AI capabilities at each level while ensuring all users benefit from core improvements. By prioritizing the implementation of the feedback loop, prompt engineering, and segmentation enhancements, we can create a significantly more reliable classification experience that handles complex, real-world waste scenarios accurately.
