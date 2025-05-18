# Credits System and Data Management Enhancements

## 1. Credits System

### 1.1 Overview

The Credits System will create an additional engagement layer by rewarding users for specific actions within the app. Unlike achievement points in the gamification system (which track progress), credits will be a currency that users can spend to unlock premium features temporarily.

### 1.2 Credit Earning Actions

Users can earn credits through various actions:

| Action | Credits | Restrictions |
|--------|---------|--------------|
| Sharing classified items on social media | 5 credits | Max 10 credits/day |
| Uploading and classifying waste | 2 credits | Max 20 credits/day |
| Contributing to family challenges | 5 credits | Per completed challenge |
| Viewing educational content | 3 credits | First view only |
| Perfect week streak | 10 credits | Weekly reward |
| Creating detailed waste reports | 5 credits | Max 10 credits/day |
| Inviting new users who join | 20 credits | Once per invited user |
| Monthly consistency bonus | 25 credits | For users active 20+ days/month |

### 1.3 Credit Redemption Options

Users can redeem credits for temporary access to premium features:

| Premium Feature | Credit Cost | Duration |
|-----------------|-------------|----------|
| Ad-free experience | 30 credits | 24 hours |
| Enhanced analytics dashboard | 50 credits | 7 days |
| Custom theme options | 40 credits | 30 days |
| Offline classification | 75 credits | 7 days |
| Data export functionality | 25 credits | Per export |
| AI-powered detailed recommendations | 60 credits | 7 days |
| All premium features | 200 credits | 7 days |

### 1.4 Technical Implementation

#### 1.4.1 Credit Model

```dart
// Pseudocode
class CreditTransaction {
  final String id;
  final String userId;
  final String? familyId;
  final int amount; // Positive for earning, negative for spending
  final CreditActionType actionType;
  final String? referenceId; // Related entity (challenge ID, content ID, etc.)
  final DateTime timestamp;
  final String? description;
  
  // Methods for serialization
}

enum CreditActionType {
  share,
  classification,
  challenge,
  education,
  streak,
  report,
  invitation,
  monthlyBonus,
  premiumFeatureRedemption,
  adminAdjustment,
}
```

#### 1.4.2 Credit Service

```dart
// Pseudocode
class CreditService {
  // Award credits to a user
  Future<bool> awardCredits(String userId, int amount, CreditActionType actionType, {
    String? referenceId,
    String? description,
    String? familyId,
  });
  
  // Deduct credits for premium feature
  Future<bool> redeemCreditsForFeature(String userId, PremiumFeature feature, Duration duration);
  
  // Check if user has enough credits
  Future<bool> hasEnoughCredits(String userId, int requiredAmount);
  
  // Get user's current credit balance
  Future<int> getUserCreditBalance(String userId);
  
  // Get credit transaction history
  Future<List<CreditTransaction>> getCreditHistory(String userId, {int limit = 20, int offset = 0});
  
  // Check if user has active premium feature
  Future<bool> hasActivePremiumFeature(String userId, PremiumFeature feature);
  
  // Get all active premium features for user
  Future<List<ActivePremiumFeature>> getActivePremiumFeatures(String userId);
}
```

#### 1.4.3 Premium Feature Management

```dart
// Pseudocode
class PremiumFeatureManager {
  // Check if feature is active
  Future<bool> isFeatureActive(String userId, PremiumFeature feature);
  
  // Activate feature for duration
  Future<void> activateFeature(String userId, PremiumFeature feature, Duration duration);
  
  // Get active features with expiration
  Future<List<ActivePremiumFeature>> getActiveFeatures(String userId);
  
  // Process expired features (called periodically)
  Future<void> processExpiredFeatures();
}

enum PremiumFeature {
  adFree,
  enhancedAnalytics,
  customThemes,
  offlineClassification,
  dataExport,
  aiRecommendations,
  allFeatures,
}

class ActivePremiumFeature {
  final String id;
  final String userId;
  final PremiumFeature feature;
  final DateTime activatedAt;
  final DateTime expiresAt;
  
  bool get isActive => DateTime.now().isBefore(expiresAt);
  
  // Methods for serialization
}
```

## 2. Content Management and Deletion

### 2.1 Overview

To improve user control over their data while maintaining system analytics integrity, we'll implement a "soft deletion" approach that:
- Removes content from user's view when requested
- Maintains anonymized data for analytics
- Optimizes storage by keeping thumbnails but removing full images when appropriate

### 2.2 Deletion Options

Users will have several options for managing their content:

1. **Hide from View**: Content not shown in history but data maintained
2. **Delete Media Only**: Remove images but keep classification data and thumbnails
3. **Full Deletion**: Remove from user view completely, but maintain anonymized analytics data

### 2.3 Data Retention Policies

| Data Type | Retention After Deletion | Purpose |
|-----------|--------------------------|---------|
| Classification records | Retained anonymized | System analytics |
| Classification images | Deleted (thumbnails retained) | Privacy compliance |
| User attribution | Removed | Privacy compliance |
| Category/material data | Retained anonymized | System analytics |
| Environmental impact | Retained anonymized | System analytics |
| Location data | Generalized to city/region | System analytics |

### 2.4 Technical Implementation

#### 2.4.1 Enhanced Classification Model

```dart
// Pseudocode - additions to existing model
class WasteClassification {
  // Existing properties...
  
  // New properties
  final bool isDeleted; // For soft deletion
  final bool isMediaDeleted; // If true, image is deleted but thumbnail retained
  final DateTime? deletedAt; // When the item was deleted
  final DeletionType? deletionType; // Type of deletion performed
  
  // Methods
  WasteClassification copyWithDeletion(DeletionType type) {
    return copyWith(
      isDeleted: type != DeletionType.hideFromView,
      isMediaDeleted: type != DeletionType.hideFromView,
      deletedAt: DateTime.now(),
      deletionType: type,
    );
  }
  
  // Returns an anonymized copy for analytics
  WasteClassification toAnonymized() {
    return copyWith(
      itemName: null, // Remove specific item name
      imageUrl: null, // Remove image reference
      classifiedBy: null, // Remove user attribution
      location: location?.toGeneralized(), // Generalize location data
      // Keep category, material type, timestamps for analytics
    );
  }
}

enum DeletionType {
  hideFromView,
  deleteMediaOnly,
  fullDeletion,
}
```

#### 2.4.2 Storage Service Enhancements

```dart
// Pseudocode - additions to existing service
class StorageService {
  // Existing methods...
  
  // Soft delete classification
  Future<void> softDeleteClassification(String key, DeletionType type) async {
    final classificationsBox = Hive.box(StorageKeys.classificationsBox);
    final String jsonString = classificationsBox.get(key);
    final classification = WasteClassification.fromJson(jsonDecode(jsonString));
    
    // Create deleted version
    final deletedClassification = classification.copyWithDeletion(type);
    
    // Update in storage
    await classificationsBox.put(key, jsonEncode(deletedClassification.toJson()));
    
    // If deleting media, handle the image
    if (type == DeletionType.deleteMediaOnly || type == DeletionType.fullDeletion) {
      await _deleteClassificationImage(classification.imageUrl, keepThumbnail: true);
    }
    
    // If full deletion, ensure data is anonymized for analytics
    if (type == DeletionType.fullDeletion) {
      await _saveAnonymizedForAnalytics(deletedClassification);
    }
  }
  
  // Delete classification image but keep thumbnail
  Future<void> _deleteClassificationImage(String? imageUrl, {bool keepThumbnail = true}) async {
    if (imageUrl == null) return;
    
    try {
      // Get thumbnail before deleting original
      if (keepThumbnail) {
        final thumbnail = await _generateThumbnail(imageUrl);
        await _saveThumbnail(thumbnail, imageUrl);
      }
      
      // Delete original image
      final file = File(imageUrl);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }
  
  // Save anonymized version for analytics
  Future<void> _saveAnonymizedForAnalytics(WasteClassification classification) async {
    final analyticsBox = Hive.box(StorageKeys.analyticsBox);
    final anonymized = classification.toAnonymized();
    
    // Store with analytics key format
    final String key = 'analytics_${classification.timestamp.millisecondsSinceEpoch}';
    await analyticsBox.put(key, jsonEncode(anonymized.toJson()));
  }
  
  // Get classifications with filter for deleted items
  Future<List<WasteClassification>> getAllClassifications({
    FilterOptions? filterOptions,
    bool includeDeleted = false,
    bool includeMediaDeleted = true,
  }) async {
    // Existing code...
    
    // Filter based on deletion status if needed
    if (!includeDeleted) {
      classifications = classifications.where((c) => !c.isDeleted).toList();
    }
    
    if (!includeMediaDeleted && includeDeleted) {
      classifications = classifications.where((c) => !c.isMediaDeleted).toList();
    }
    
    // Rest of existing code...
  }
}
```

#### 2.4.3 Media Management Utilities

```dart
// Pseudocode
class MediaManager {
  // Generate thumbnail from image
  Future<File> generateThumbnail(File originalImage, {int maxWidth = 200, int maxHeight = 200}) async {
    // Implementation to resize image to thumbnail
  }
  
  // Save space by converting high-res images to lower resolution after X days
  Future<void> optimizeOldImages(int daysThreshold) async {
    // Find images older than threshold
    // Convert to lower resolution to save space
  }
  
  // Batch process images for optimization
  Future<void> batchOptimizeImages() async {
    // Process images in batches to avoid memory issues
  }
}
```

## 3. Integration Points

### 3.1 Integration with User Management

```dart
// Pseudocode
class FamilyService {
  // Existing methods...
  
  // Get family credit balance (sum of all members)
  Future<int> getFamilyCreditBalance(String familyId) async {
    final members = await getUsersByFamily(familyId);
    int totalCredits = 0;
    
    for (var member in members) {
      final credits = await _creditService.getUserCreditBalance(member.id);
      totalCredits += credits;
    }
    
    return totalCredits;
  }
  
  // Award credits to all family members
  Future<void> awardCreditsToFamily(String familyId, int amount, CreditActionType actionType) async {
    final members = await getUsersByFamily(familyId);
    
    for (var member in members) {
      await _creditService.awardCredits(
        member.id, 
        amount, 
        actionType,
        familyId: familyId,
        description: 'Family reward',
      );
    }
  }
}
```

### 3.2 Integration with Analytics Dashboard

```dart
// Pseudocode
class AnalyticsService {
  // Get analytics including anonymized deleted data
  Future<Map<String, dynamic>> getComprehensiveAnalytics({bool includeAnonymized = true}) async {
    // Regular analytics calculations
    final Map<String, dynamic> regularAnalytics = await calculateRegularAnalytics();
    
    if (includeAnonymized) {
      // Add anonymized deleted data
      final anonymizedData = await getAnonymizedAnalyticsData();
      
      // Merge data sets
      return _mergeAnalytics(regularAnalytics, anonymizedData);
    }
    
    return regularAnalytics;
  }
  
  // Helper to merge regular and anonymized analytics
  Map<String, dynamic> _mergeAnalytics(Map<String, dynamic> regular, Map<String, dynamic> anonymized) {
    // Implementation to carefully merge metrics without double-counting
  }
}
```

## 4. User Interface Components

### 4.1 Credits UI

#### 4.1.1 Credits Dashboard

The Credits Dashboard will show:
- Current credit balance
- Credit earning opportunities
- Credit history (recent transactions)
- Available premium features to redeem

#### 4.1.2 Premium Feature Marketplace

The Premium Feature Marketplace will:
- Display available premium features
- Show credit cost and duration
- Allow one-click redemption
- Display currently active premium features

#### 4.1.3 Transaction History

The Transaction History will:
- List all credit earning and spending activities
- Show timestamps and descriptions
- Display running balance
- Allow filtering by transaction type

### 4.2 Content Management UI

#### 4.2.1 Deletion Controls

Add deletion options to:
- Individual classification items
- Batch selection interface
- History management screen

#### 4.2.2 Storage Management Interface

Create a Storage Management screen that:
- Shows space used by images/videos
- Offers batch optimization options
- Provides cleanup recommendations
- Displays content age statistics

## 5. Implementation Plan

### 5.1 Phase One: Credits System Foundation (3-4 weeks)
1. Implement the Credits model and database structure
2. Create core CreditService functionality
3. Add basic credit earning mechanisms for key actions
4. Implement UI for viewing credits balance and history

### 5.2 Phase Two: Premium Feature Redemption (2-3 weeks)
1. Implement PremiumFeatureManager
2. Create feature activation/deactivation logic
3. Develop Premium Feature Marketplace UI
4. Implement feature access controls throughout the app

### 5.3 Phase Three: Content Management (3-4 weeks)
1. Update WasteClassification model with deletion fields
2. Implement soft deletion functionality
3. Create thumbnail generation and management
4. Add deletion controls to history interface
5. Develop Storage Management screen

### 5.4 Phase Four: Analytics Integration (2-3 weeks)
1. Implement anonymized data retention
2. Update analytics calculations to include anonymized data
3. Create privacy-focused data management controls
4. Add storage optimization recommendations

## 6. Privacy and Ethical Considerations

### 6.1 User Control Principles
- Always provide clear information about what happens to deleted data
- Allow genuine full deletion for users who request it
- Clearly explain which analytics are retained and why
- Give users control over their contribution to anonymized data

### 6.2 Privacy Policy Updates
The app's privacy policy should be updated to clearly explain:
- Credit earning and premium feature access
- How deleted content is handled
- What anonymized data is retained and why
- How thumbnails are stored and managed
- User rights regarding data deletion

### 6.3 GDPR and Data Regulations Compliance
- Implement proper "right to be forgotten" functionality
- Create data export tool for user data
- Maintain proper audit logs for deletion requests
- Allow users to opt out of anonymized data retention

## 7. Technical Considerations

### 7.1 Performance Impact
- Implement batch processing for thumbnail generation
- Use background workers for media optimization
- Index deletion status fields for query performance
- Cache credit balances to avoid frequent calculations

### 7.2 Storage Optimization
- Automatically convert old high-resolution images to more efficient formats
- Implement progressive JPEG/WebP for thumbnails
- Use proper image compression algorithms
- Consider cloud storage options for long-term data retention

### 7.3 Testing Focus Areas
- Credit balance accuracy across transactions
- Premium feature expiration handling
- Image deletion while preserving thumbnails
- Analytics accuracy with anonymized data
- Performance with large historical datasets

## 8. Conclusion

The proposed Credits System and Content Management enhancements will significantly improve user engagement and control while maintaining valuable analytics data. By implementing a virtual currency system, users are incentivized to engage more deeply with the app while gaining access to premium features. Simultaneously, the improved content management features give users better control over their data while preserving the system's ability to provide valuable waste management insights.

These enhancements align perfectly with the app's mission of promoting better waste management practices by creating additional engagement loops and rewards for consistent usage.
