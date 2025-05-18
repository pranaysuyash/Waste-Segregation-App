# Data Storage and Management Strategy

This document outlines a comprehensive strategy for efficiently managing data in the Waste Segregation App, with a focus on classification data, user-generated content, images, and app assets. The strategy emphasizes performance, efficiency, and data privacy while accounting for the resource constraints of solo development.

## 1. Data Requirements Overview

### Data Types and Characteristics

| Data Type | Estimated Size | Growth Rate | Access Pattern | Sensitivity |
|-----------|----------------|-------------|----------------|-------------|
| User Profiles | 2-5 KB per user | Linear with users | Frequent reads, occasional writes | High |
| Classification History | 1-3 KB per classification | High growth with usage | Frequent reads, write once | Medium |
| Classification Images | 100-500 KB per image | High potential growth | Temporary access | Medium-High |
| Image Hashes | 100-200 bytes per image | Matches classification rate | Frequent reads | Low |
| Educational Content | 10-50 KB per item | Planned incremental growth | Frequent reads, rare writes | Low |
| App Assets | 1-50 MB total | Incremental with updates | Read-only, infrequent | Low |
| User Achievements | 100-500 bytes per achievement | Moderate, event-based | Frequent reads, occasional writes | Low |
| Analytics Data | 1-5 KB per session | High growth with usage | Write-heavy, batch reads | Medium |

### Data Relationships

```
User
 ├── Profile Information
 ├── Settings/Preferences
 ├── Classification History
 │    ├── Classification Results
 │    └── Image Hashes (not original images)
 ├── Educational Progress
 │    ├── Completed Content
 │    ├── Quiz Results
 │    └── Reading History
 ├── Achievements/Gamification
 │    ├── Points History
 │    ├── Badges Earned
 │    └── Challenges Completed
 └── Usage Statistics
      ├── Session Data
      ├── Feature Usage
      └── Engagement Metrics
```

### Data Governance Principles

1. **Data Minimization**: Collect only what's necessary for functionality
2. **Purpose Limitation**: Use data only for intended purposes
3. **Storage Limitation**: Retain data only as long as needed
4. **User Control**: Provide clear data management options
5. **Security by Design**: Implement appropriate protection measures
6. **Privacy by Default**: Privacy-preserving settings as default

## 2. Local Storage Strategy

### Local Database Architecture

#### Database Selection

For the Waste Segregation App, a combination of storage solutions will be used:

1. **Primary Structured Data**: Hive (NoSQL)
   - Advantages: Fast performance, type safety, encryption support
   - Use cases: User profiles, classification history, achievements

2. **Key-Value Storage**: Shared Preferences
   - Advantages: Simple, lightweight, built-in
   - Use cases: App settings, user preferences, feature flags

3. **File Storage**: App Documents Directory
   - Advantages: Flexible, good for larger binary data
   - Use cases: Cached images, downloaded educational content

#### Schema Design (Hive)

```dart
// User Profile
@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String? email;
  
  @HiveField(3)
  DateTime createdAt;
  
  @HiveField(4)
  UserPreferences preferences;
  
  @HiveField(5)
  bool isPremium;
  
  @HiveField(6)
  DateTime? premiumExpiryDate;
  
  @HiveField(7)
  Map<String, dynamic> additionalData;
}

// Classification History
@HiveType(typeId: 1)
class ClassificationResult extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String userId;
  
  @HiveField(2)
  String category;
  
  @HiveField(3)
  String subcategory;
  
  @HiveField(4)
  String disposalInstructions;
  
  @HiveField(5)
  DateTime classifiedAt;
  
  @HiveField(6)
  String imageHash;
  
  @HiveField(7)
  Uint8List? thumbnailData;
  
  @HiveField(8)
  double confidenceScore;
  
  @HiveField(9)
  String classificationSource; // AI service used
  
  @HiveField(10)
  Map<String, dynamic> additionalData;

  // Note: The runtime WasteClassification model may have additional transient fields 
  // like 'isSaved' that are handled by the StorageService before persistence.
}

// Achievement
@HiveType(typeId: 2)
class Achievement extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String userId;
  
  @HiveField(2)
  String achievementType;
  
  @HiveField(3)
  DateTime unlockedAt;
  
  @HiveField(4)
  int pointsEarned;
  
  @HiveField(5)
  Map<String, dynamic> metadata;
}

// Educational Content Progress
@HiveType(typeId: 3)
class ContentProgress extends HiveObject {
  @HiveField(0)
  String contentId;
  
  @HiveField(1)
  String userId;
  
  @HiveField(2)
  double completionPercentage;
  
  @HiveField(3)
  DateTime lastAccessedAt;
  
  @HiveField(4)
  bool isCompleted;
  
  @HiveField(5)
  int timeSpentSeconds;
}
```

#### Indexing Strategy

Implement custom indices to optimize query performance:

```dart
// Example indexing implementation
class ClassificationRepository {
  late Box<ClassificationResult> _classificationBox;
  late Map<String, List<String>> _categoryIndex;
  late Map<String, List<String>> _dateIndex;
  
  Future<void> initialize() async {
    _classificationBox = await Hive.openBox<ClassificationResult>('classifications');
    await _buildIndices();
  }
  
  Future<void> _buildIndices() async {
    _categoryIndex = {};
    _dateIndex = {};
    
    for (var i = 0; i < _classificationBox.length; i++) {
      final classification = _classificationBox.getAt(i);
      if (classification != null) {
        // Build category index
        final category = classification.category;
        if (!_categoryIndex.containsKey(category)) {
          _categoryIndex[category] = [];
        }
        _categoryIndex[category]!.add(classification.id);
        
        // Build date index (by month for efficiency)
        final monthKey = _getMonthKey(classification.classifiedAt);
        if (!_dateIndex.containsKey(monthKey)) {
          _dateIndex[monthKey] = [];
        }
        _dateIndex[monthKey]!.add(classification.id);
      }
    }
  }
  
  String _getMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }
  
  // Query using indices
  Future<List<ClassificationResult>> getClassificationsByCategory(String category) async {
    if (!_categoryIndex.containsKey(category)) {
      return [];
    }
    
    return _categoryIndex[category]!
        .map((id) => _classificationBox.get(id))
        .where((classification) => classification != null)
        .cast<ClassificationResult>()
        .toList();
  }
  
  // Additional query methods...
}
```

### Image and Media Management

#### Image Processing Pipeline

(Details of the image processing pipeline, from capture/selection to pre-processing for AI, thumbnail generation, and caching, should be documented here.)

#### Image Caching Strategy

```dart
class ImageManager {
  static const int THUMBNAIL_SIZE = 100; // pixels (square)
  static const int MAX_CACHED_IMAGES = 100;
  static const String CACHE_DIRECTORY = 'image_cache';
  
  final Directory _cacheDir;
  
  ImageManager(this._cacheDir);
  
  /// Process a captured or selected image
  Future<ProcessedImage> processImage(Uint8List originalImage) async {
    // Resize for classification (preserve aspect ratio)
    final resizedImage = await _resizeImage(
      originalImage,
      maxWidth: 800,
      maxHeight: 800,
      preserveAspectRatio: true,
    );
    
    // Generate thumbnail for history display
    final thumbnail = await _generateThumbnail(originalImage);
    
    // Generate image hash for caching
    final imageHash = await _generatePerceptualHash(resizedImage);
    
    return ProcessedImage(
      original: originalImage,
      resized: resizedImage,
      thumbnail: thumbnail,
      imageHash: imageHash,
    );
  }
  
  /// Cache an image for offline access if needed
  Future<void> cacheImage(String imageHash, Uint8List imageData) async {
    final file = File('${_cacheDir.path}/$CACHE_DIRECTORY/$imageHash.jpg');
    
    // Create directory if it doesn't exist
    final directory = file.parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    // Write image file
    await file.writeAsBytes(imageData);
    
    // Perform cache maintenance
    await _maintainCacheSize();
  }
  
  /// Retrieve a cached image
  Future<Uint8List?> getCachedImage(String imageHash) async {
    final file = File('${_cacheDir.path}/$CACHE_DIRECTORY/$imageHash.jpg');
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }
  
  /// Keep cache size under control
  Future<void> _maintainCacheSize() async {
    final directory = Directory('${_cacheDir.path}/$CACHE_DIRECTORY');
    if (!await directory.exists()) return;
    
    final files = await directory.list().toList();
    if (files.length <= MAX_CACHED_IMAGES) return;
    
    // Sort by last accessed time
    files.sort((a, b) async {
      final statA = await (a as File).stat();
      final statB = await (b as File).stat();
      return statA.accessed.compareTo(statB.accessed);
    });
    
    // Remove oldest files exceeding the limit
    for (int i = 0; i < files.length - MAX_CACHED_IMAGES; i++) {
      await (files[i] as File).delete();
    }
  }
  
  // Helper methods for image processing...
  Future<Uint8List> _resizeImage(Uint8List imageData, {required int maxWidth, required int maxHeight, required bool preserveAspectRatio}) async {
    // Implementation using Flutter's image package or native code
  }
  
  Future<Uint8List> _generateThumbnail(Uint8List imageData) async {
    // Create small thumbnail for UI display
  }
  
  Future<String> _generatePerceptualHash(Uint8List imageData) async {
    // Implement perceptual hashing algorithm for similarity detection
  }
}

class ProcessedImage {
  final Uint8List original;
  final Uint8List resized;
  final Uint8List thumbnail;
  final String imageHash;
  
  ProcessedImage({
    required this.original,
    required this.resized,
    required this.thumbnail,
    required this.imageHash,
  });
}
```

#### Perceptual Hashing Implementation

For classification caching, implement a perceptual hash that can identify similar images:

```dart
class PerceptualHashGenerator {
  static const int HASH_SIZE = 8; // 8x8 hash (64 bits)
  
  /// Generate a perceptual hash for an image
  Future<String> generateHash(Uint8List imageData) async {
    // 1. Resize image to a small square (8x8 pixels)
    final resized = await _resizeToSquare(imageData, HASH_SIZE);
    
    // 2. Convert to grayscale
    final grayscale = _convertToGrayscale(resized);
    
    // 3. Compute the mean pixel value
    final mean = _computeMeanValue(grayscale);
    
    // 4. Create the hash (1 for pixels above mean, 0 for below)
    final hash = _computeHash(grayscale, mean);
    
    // Convert binary hash to hexadecimal string
    return _binaryToHex(hash);
  }
  
  /// Compare two hashes to determine similarity
  double calculateSimilarity(String hash1, String hash2) {
    final binary1 = _hexToBinary(hash1);
    final binary2 = _hexToBinary(hash2);
    
    // Count differing bits (Hamming distance)
    int distance = 0;
    for (int i = 0; i < binary1.length; i++) {
      if (binary1[i] != binary2[i]) {
        distance++;
      }
    }
    
    // Convert to similarity percentage
    return (64 - distance) / 64 * 100;
  }
  
  // Helper methods...
  Future<Uint8List> _resizeToSquare(Uint8List imageData, int size) async {
    // Implementation for resizing
  }
  
  List<int> _convertToGrayscale(Uint8List rgbaData) {
    // Convert RGBA data to grayscale values
  }
  
  double _computeMeanValue(List<int> grayscaleData) {
    // Compute the mean value of all pixels
  }
  
  List<bool> _computeHash(List<int> grayscaleData, double mean) {
    // Generate hash based on comparison with mean
  }
  
  String _binaryToHex(List<bool> binaryHash) {
    // Convert binary hash to hexadecimal string
  }
  
  List<bool> _hexToBinary(String hexHash) {
    // Convert hex hash back to binary
  }
}
```

### Data Synchronization Framework

For syncing local data with cloud services when available:

```dart
class DataSyncManager {
  final String userId;
  final FirebaseFirestore _firestore;
  final Box<ClassificationResult> _classificationBox;
  final Box<Achievement> _achievementsBox;
  final Box<ContentProgress> _contentProgressBox;
  final ConnectivityService _connectivityService;
  
  DataSyncManager({
    required this.userId,
    required FirebaseFirestore firestore,
    required Box<ClassificationResult> classificationBox,
    required Box<Achievement> achievementsBox,
    required Box<ContentProgress> contentProgressBox,
    required ConnectivityService connectivityService,
  }) : 
    _firestore = firestore,
    _classificationBox = classificationBox,
    _achievementsBox = achievementsBox,
    _contentProgressBox = contentProgressBox,
    _connectivityService = connectivityService;
  
  /// Perform a complete sync operation
  Future<SyncResult> performSync() async {
    if (!await _connectivityService.isConnected()) {
      return SyncResult(success: false, reason: 'No connection available');
    }
    
    try {
      // Sync classifications
      final classificationResult = await _syncClassifications();
      
      // Sync achievements
      final achievementsResult = await _syncAchievements();
      
      // Sync educational progress
      final progressResult = await _syncContentProgress();
      
      return SyncResult(
        success: true,
        itemsSynced: classificationResult + achievementsResult + progressResult,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        reason: 'Sync failed: ${e.toString()}',
      );
    }
  }
  
  /// Sync classification history with Firestore
  Future<int> _syncClassifications() async {
    // Get last sync timestamp
    final lastSync = await _getLastSyncTimestamp('classifications');
    
    // Get local changes since last sync
    final localChanges = _getLocalChangesSince(_classificationBox, lastSync);
    
    // Upload local changes
    for (final classification in localChanges) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('classifications')
          .doc(classification.id)
          .set(_classificationToJson(classification));
    }
    
    // Get remote changes since last sync
    final remoteChanges = await _firestore
        .collection('users')
        .doc(userId)
        .collection('classifications')
        .where('updatedAt', isGreaterThan: lastSync)
        .get();
    
    // Apply remote changes locally
    for (final doc in remoteChanges.docs) {
      final remoteData = doc.data();
      final localId = doc.id;
      
      // Skip if local version is newer
      final localItem = _classificationBox.get(localId);
      if (localItem != null && 
          localItem.updatedAt.isAfter(remoteData['updatedAt'].toDate())) {
        continue;
      }
      
      // Create or update local record
      final classification = _jsonToClassification(remoteData, localId);
      await _classificationBox.put(localId, classification);
    }
    
    // Update last sync timestamp
    await _updateLastSyncTimestamp('classifications');
    
    return localChanges.length + remoteChanges.docs.length;
  }
  
  // Additional sync methods for achievements and educational progress...
  
  // Helper methods
  Future<DateTime> _getLastSyncTimestamp(String dataType) async {
    // Get timestamp from secure storage
  }
  
  Future<void> _updateLastSyncTimestamp(String dataType) async {
    // Update timestamp in secure storage
  }
  
  List<T> _getLocalChangesSince<T extends HiveObject>(Box<T> box, DateTime since) {
    // Find items updated since timestamp
  }
  
  Map<String, dynamic> _classificationToJson(ClassificationResult classification) {
    // Convert to JSON
  }
  
  ClassificationResult _jsonToClassification(
      Map<String, dynamic> json, String id) {
    // Convert from JSON
  }
}

class SyncResult {
  final bool success;
  final String? reason;
  final int itemsSynced;
  
  SyncResult({
    required this.success,
    this.reason,
    this.itemsSynced = 0,
  });
}
```

## 3. Cloud Storage Strategy

### Firebase Implementation

#### Firestore Data Model

```
users/
  {userId}/
    profile/
      [User profile data]
    settings/
      [User settings]
    classifications/
      {classificationId}/
        [Classification metadata]
    achievements/
      {achievementId}/
        [Achievement data]
    contentProgress/
      {contentId}/
        [Content progress data]

contentLibrary/
  {contentId}/
    [Educational content metadata]

classificationCache/
  {imageHash}/
    [Shared classification result]
```

#### Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User data - only accessible by the user
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Educational content - readable by all authenticated users
    match /contentLibrary/{contentId} {
      allow read: if request.auth != null;
      allow write: if false; // Only admin can write through admin SDK
    }
    
    // Shared classification cache - read by all, write with validation
    match /classificationCache/{imageHash} {
      allow read: if request.auth != null;
      allow create, update: if request.auth != null 
                            && validateClassificationData();
      
      function validateClassificationData() {
        return request.resource.data.keys().hasAll(['category', 'subcategory', 'disposalInstructions', 'createdAt', 'createdBy'])
            && request.resource.data.createdBy == request.auth.uid;
      }
    }
  }
}
```

#### Cloud Functions for Data Management

Implement Firebase Cloud Functions for data management tasks:

```javascript
// Cache maintenance function (runs daily)
exports.cleanupClassificationCache = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const db = admin.firestore();
    
    // Find cache entries older than 90 days
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 90);
    
    const oldCacheQuery = await db.collection('classificationCache')
      .where('createdAt', '<', cutoffDate)
      .limit(500) // Batch size
      .get();
    
    // Delete old entries
    const batch = db.batch();
    let count = 0;
    
    oldCacheQuery.forEach(doc => {
      batch.delete(doc.ref);
      count++;
    });
    
    if (count > 0) {
      await batch.commit();
      console.log(`Deleted ${count} old cache entries`);
    }
    
    return null;
  });

// User data export function (for GDPR compliance)
exports.exportUserData = functions.https.onCall(async (data, context) => {
  // Ensure authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }
  
  const userId = context.auth.uid;
  const db = admin.firestore();
  
  // Collect all user data
  const userData = {
    profile: null,
    settings: null,
    classifications: [],
    achievements: [],
    contentProgress: []
  };
  
  // Get profile
  const profileDoc = await db.collection('users').doc(userId).collection('profile').doc('data').get();
  if (profileDoc.exists) {
    userData.profile = profileDoc.data();
  }
  
  // Get settings
  const settingsDoc = await db.collection('users').doc(userId).collection('settings').doc('data').get();
  if (settingsDoc.exists) {
    userData.settings = settingsDoc.data();
  }
  
  // Get classifications
  const classificationsQuery = await db.collection('users').doc(userId).collection('classifications').get();
  classificationsQuery.forEach(doc => {
    userData.classifications.push({
      id: doc.id,
      ...doc.data()
    });
  });
  
  // Get achievements
  const achievementsQuery = await db.collection('users').doc(userId).collection('achievements').get();
  achievementsQuery.forEach(doc => {
    userData.achievements.push({
      id: doc.id,
      ...doc.data()
    });
  });
  
  // Get content progress
  const progressQuery = await db.collection('users').doc(userId).collection('contentProgress').get();
  progressQuery.forEach(doc => {
    userData.contentProgress.push({
      id: doc.id,
      ...doc.data()
    });
  });
  
  return userData;
});
```

### Firebase Storage Usage

For educational content assets and larger media files:

```dart
class FirebaseStorageService {
  final FirebaseStorage _storage;
  final String userId;
  
  FirebaseStorageService({
    required FirebaseStorage storage,
    required this.userId,
  }) : _storage = storage;
  
  /// Upload a user classification image (premium backup feature)
  Future<String> uploadClassificationImage(String classificationId, Uint8List imageData) async {
    final path = 'users/$userId/classifications/$classificationId.jpg';
    final ref = _storage.ref().child(path);
    
    // Upload with metadata
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'uploadedAt': DateTime.now().toIso8601String(),
        'userId': userId,
        'classificationId': classificationId,
      },
    );
    
    await ref.putData(imageData, metadata);
    return path;
  }
  
  /// Download an educational content image
  Future<Uint8List?> getEducationalContentImage(String contentId, String imageName) async {
    try {
      final path = 'educational_content/$contentId/images/$imageName';
      final ref = _storage.ref().child(path);
      
      final data = await ref.getData();
      return data;
    } catch (e) {
      print('Error downloading image: $e');
      return null;
    }
  }
  
  /// Get a download URL for sharing content
  Future<String?> getShareableUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error generating shareable URL: $e');
      return null;
    }
  }
}
```

## 4. App Asset Management

### Asset Organization Strategy

#### Directory Structure

```
assets/
  images/
    ui/
      [Interface elements and icons]
    categories/
      [Waste category icons]
    placeholders/
      [Placeholder images]
    illustrations/
      [Educational illustrations]
  icons/
    [App icons in various sizes]
  animations/
    [Lottie animations]
  educational/
    categories/
      [Category-specific content]
    material_types/
      [Material-specific content]
    disposal_methods/
      [Disposal method guides]
  localization/
    [Language files]
```

#### Asset Loading Management

```dart
class AssetManager {
  final AssetManifest _manifest;
  final Map<String, Uint8List> _cachedAssets = {};
  
  AssetManager(this._manifest);
  
  /// Preload critical assets during app startup
  Future<void> preloadCriticalAssets() async {
    final criticalAssets = [
      'assets/images/ui/splash_logo.png',
      'assets/images/categories/recyclable.png',
      'assets/images/categories/compostable.png',
      'assets/images/categories/hazardous.png',
      'assets/images/categories/general_waste.png',
      'assets/animations/loading.json',
    ];
    
    for (final asset in criticalAssets) {
      await _loadAndCacheAsset(asset);
    }
  }
  
  /// Get an asset, either from cache or loading it
  Future<Uint8List> getAsset(String assetPath) async {
    if (_cachedAssets.containsKey(assetPath)) {
      return _cachedAssets[assetPath]!;
    }
    
    return await _loadAndCacheAsset(assetPath);
  }
  
  /// Preload assets for a specific category
  Future<void> preloadCategoryAssets(String category) async {
    final categoryAssets = _manifest.findByPattern('assets/images/categories/$category');
    
    for (final asset in categoryAssets) {
      await _loadAndCacheAsset(asset);
    }
  }
  
  /// Clear cached assets that haven't been used recently
  Future<void> manageCacheSize() async {
    // Implementation for cache pruning
  }
  
  /// Load and cache an asset
  Future<Uint8List> _loadAndCacheAsset(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    _cachedAssets[assetPath] = bytes;
    return bytes;
  }
}
```

### On-Demand Asset Loading

For efficient app size and memory management:

```dart
class DynamicAssetLoader {
  final FirebaseStorage _storage;
  final Directory _cacheDir;
  final Map<String, DateTime> _assetAccessTimes = {};
  
  static const String ASSET_CACHE_DIR = 'dynamic_assets';
  static const int MAX_CACHED_ASSETS = 50;
  
  DynamicAssetLoader({
    required FirebaseStorage storage,
    required Directory cacheDir,
  }) : _storage = storage,
       _cacheDir = cacheDir;
  
  /// Get a dynamic asset, either from cache or download
  Future<Uint8List?> getDynamicAsset(String assetPath) async {
    // Check local cache first
    final cachedAsset = await _getFromCache(assetPath);
    if (cachedAsset != null) {
      // Update access time
      _assetAccessTimes[assetPath] = DateTime.now();
      return cachedAsset;
    }
    
    // Download from Firebase Storage
    try {
      final ref = _storage.ref().child(assetPath);
      final data = await ref.getData();
      
      if (data != null) {
        // Cache for future use
        await _saveToCache(assetPath, data);
        _assetAccessTimes[assetPath] = DateTime.now();
        
        // Maintain cache size
        await _maintainCacheSize();
        
        return data;
      }
    } catch (e) {
      print('Error loading dynamic asset: $e');
    }
    
    return null;
  }
  
  /// Check if a dynamic asset exists
  Future<bool> dynamicAssetExists(String assetPath) async {
    // Check cache first
    final cacheFile = File('${_cacheDir.path}/$ASSET_CACHE_DIR/${_assetPathToFilename(assetPath)}');
    if (await cacheFile.exists()) {
      return true;
    }
    
    // Check Firebase Storage
    try {
      final ref = _storage.ref().child(assetPath);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Preload a set of dynamic assets
  Future<void> preloadDynamicAssets(List<String> assetPaths) async {
    for (final path in assetPaths) {
      await getDynamicAsset(path);
    }
  }
  
  /// Get asset from local cache
  Future<Uint8List?> _getFromCache(String assetPath) async {
    final file = File('${_cacheDir.path}/$ASSET_CACHE_DIR/${_assetPathToFilename(assetPath)}');
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }
  
  /// Save asset to local cache
  Future<void> _saveToCache(String assetPath, Uint8List data) async {
    final directory = Directory('${_cacheDir.path}/$ASSET_CACHE_DIR');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    final file = File('${directory.path}/${_assetPathToFilename(assetPath)}');
    await file.writeAsBytes(data);
  }
  
  /// Convert asset path to safe filename
  String _assetPathToFilename(String assetPath) {
    return assetPath.replaceAll('/', '_').replaceAll('.', '_');
  }
  
  /// Keep cache size under control
  Future<void> _maintainCacheSize() async {
    if (_assetAccessTimes.length <= MAX_CACHED_ASSETS) {
      return;
    }
    
    // Sort by access time
    final sortedAssets = _assetAccessTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    // Remove oldest assets exceeding the limit
    for (int i = 0; i < sortedAssets.length - MAX_CACHED_ASSETS; i++) {
      final assetToRemove = sortedAssets[i].key;
      final file = File('${_cacheDir.path}/$ASSET_CACHE_DIR/${_assetPathToFilename(assetToRemove)}');
      
      if (await file.exists()) {
        await file.delete();
      }
      
      _assetAccessTimes.remove(assetToRemove);
    }
  }
}
```

## 5. Caching Strategy

### Multi-Level Caching Approach

Implement a comprehensive caching strategy for improved performance and offline functionality:

```dart
class CacheManager {
  // Configuration
  static const Duration MEMORY_CACHE_DURATION = Duration(minutes: 30);
  static const Duration DISK_CACHE_DURATION = Duration(days: 7);
  static const int MAX_MEMORY_CACHE_ITEMS = 100;
  static const int MAX_DISK_CACHE_ITEMS = 1000;
  
  // Memory cache
  final Map<String, CacheEntry<dynamic>> _memoryCache = {};
  
  // Disk cache (using Hive)
  late Box<CacheEntry<String>> _diskCache;
  
  // Initialize
  Future<void> initialize() async {
    _diskCache = await Hive.openBox<CacheEntry<String>>('diskCache');
    
    // Register cleanup task
    _scheduleCleanup();
  }
  
  /// Get an item from cache
  Future<T?> get<T>(String key, {bool forceRefresh = false}) async {
    if (forceRefresh) {
      return null;
    }
    
    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      final entry = _memoryCache[key]!;
      if (!entry.isExpired()) {
        // Update access time
        entry.lastAccessed = DateTime.now();
        return entry.value as T?;
      } else {
        // Remove expired entry
        _memoryCache.remove(key);
      }
    }
    
    // Check disk cache
    if (_diskCache.containsKey(key)) {
      final entry = _diskCache.get(key)!;
      if (!entry.isExpired()) {
        // Deserialize value
        final value = _deserialize<T>(entry.value as String);
        
        // Add to memory cache
        _addToMemoryCache(key, value);
        
        return value;
      } else {
        // Remove expired entry
        await _diskCache.delete(key);
      }
    }
    
    return null;
  }
  
  /// Add an item to cache
  Future<void> set<T>(
    String key, 
    T value, {
    Duration? memoryDuration,
    Duration? diskDuration,
    CachePolicy policy = CachePolicy.memory_then_disk,
  }) async {
    // Add to memory cache if policy allows
    if (policy == CachePolicy.memory_only || 
        policy == CachePolicy.memory_then_disk) {
      _addToMemoryCache(
        key, 
        value, 
        duration: memoryDuration ?? MEMORY_CACHE_DURATION,
      );
    }
    
    // Add to disk cache if policy allows
    if (policy == CachePolicy.disk_only || 
        policy == CachePolicy.memory_then_disk) {
      await _addToDiskCache(
        key, 
        value, 
        duration: diskDuration ?? DISK_CACHE_DURATION,
      );
    }
  }
  
  /// Remove an item from cache
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _diskCache.delete(key);
  }
  
  /// Clear all cached data
  Future<void> clearAll() async {
    _memoryCache.clear();
    await _diskCache.clear();
  }
  
  /// Add to memory cache
  void _addToMemoryCache<T>(String key, T value, {Duration? duration}) {
    final entry = CacheEntry<T>(
      value: value,
      createdAt: DateTime.now(),
      expiresAt: duration != null 
          ? DateTime.now().add(duration) 
          : DateTime.now().add(MEMORY_CACHE_DURATION),
      lastAccessed: DateTime.now(),
    );
    
    _memoryCache[key] = entry;
    
    // Check if we need to prune memory cache
    if (_memoryCache.length > MAX_MEMORY_CACHE_ITEMS) {
      _pruneMemoryCache();
    }
  }
  
  /// Add to disk cache
  Future<void> _addToDiskCache<T>(String key, T value, {Duration? duration}) async {
    // Serialize value
    final serialized = _serialize<T>(value);
    
    final entry = CacheEntry<String>(
      value: serialized,
      createdAt: DateTime.now(),
      expiresAt: duration != null 
          ? DateTime.now().add(duration) 
          : DateTime.now().add(DISK_CACHE_DURATION),
      lastAccessed: DateTime.now(),
    );
    
    await _diskCache.put(key, entry);
    
    // Check if we need to prune disk cache
    if (_diskCache.length > MAX_DISK_CACHE_ITEMS) {
      await _pruneDiskCache();
    }
  }
  
  /// Prune memory cache using LRU policy
  void _pruneMemoryCache() {
    // Sort by last accessed time
    final sortedEntries = _memoryCache.entries.toList()
      ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));
    
    // Remove oldest 20% of entries
    final removeCount = (_memoryCache.length * 0.2).ceil();
    for (int i = 0; i < removeCount && i < sortedEntries.length; i++) {
      _memoryCache.remove(sortedEntries[i].key);
    }
  }
  
  /// Prune disk cache
  Future<void> _pruneDiskCache() async {
    // Get all entries
    final entries = Map<String, CacheEntry<String>>.fromIterable(
      _diskCache.keys,
      key: (k) => k as String,
      value: (k) => _diskCache.get(k as String)!,
    );
    
    // Sort by last accessed time
    final sortedEntries = entries.entries.toList()
      ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));
    
    // Remove oldest 20% of entries
    final removeCount = (_diskCache.length * 0.2).ceil();
    for (int i = 0; i < removeCount && i < sortedEntries.length; i++) {
      await _diskCache.delete(sortedEntries[i].key);
    }
  }
  
  /// Schedule periodic cleanup
  void _scheduleCleanup() {
    // Run cleanup every 12 hours
    Timer.periodic(Duration(hours: 12), (timer) async {
      await _cleanupExpiredEntries();
    });
  }
  
  /// Clean up expired entries
  Future<void> _cleanupExpiredEntries() async {
    // Remove expired memory cache entries
    _memoryCache.removeWhere((key, entry) => entry.isExpired());
    
    // Remove expired disk cache entries
    final expiredKeys = <String>[];
    for (final key in _diskCache.keys) {
      final entry = _diskCache.get(key);
      if (entry != null && entry.isExpired()) {
        expiredKeys.add(key as String);
      }
    }
    
    for (final key in expiredKeys) {
      await _diskCache.delete(key);
    }
  }
  
  /// Serialize value to string
  String _serialize<T>(T value) {
    if (value is String) {
      return value;
    } else if (value is num || value is bool) {
      return value.toString();
    } else {
      return jsonEncode(value);
    }
  }
  
  /// Deserialize string to value
  T? _deserialize<T>(String value) {
    if (T == String) {
      return value as T;
    } else if (T == int) {
      return int.parse(value) as T;
    } else if (T == double) {
      return double.parse(value) as T;
    } else if (T == bool) {
      return (value == 'true') as T;
    } else {
      return jsonDecode(value) as T;
    }
  }
}

class CacheEntry<T> {
  final T value;
  final DateTime createdAt;
  final DateTime expiresAt;
  DateTime lastAccessed;
  
  CacheEntry({
    required this.value,
    required this.createdAt,
    required this.expiresAt,
    required this.lastAccessed,
  });
  
  bool isExpired() {
    return DateTime.now().isAfter(expiresAt);
  }
  
  // For Hive type adapter
  Map<String, dynamic> toJson() => {
    'value': value,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'lastAccessed': lastAccessed.toIso8601String(),
  };
  
  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
    value: json['value'],
    createdAt: DateTime.parse(json['createdAt']),
    expiresAt: DateTime.parse(json['expiresAt']),
    lastAccessed: DateTime.parse(json['lastAccessed']),
  );
}

enum CachePolicy {
  memory_only,
  disk_only,
  memory_then_disk,
}
```

### API Response Caching

Implement specific caching for API responses:

```dart
class ApiCacheManager {
  final CacheManager _cacheManager;
  
  ApiCacheManager(this._cacheManager);
  
  /// Get cached API response or fetch new one
  Future<Map<String, dynamic>> fetchWithCache({
    required String endpoint,
    required Future<Map<String, dynamic>> Function() apiFetch,
    Duration cacheDuration = const Duration(hours: 24),
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'api_$endpoint';
    
    // Try to get from cache first
    if (!forceRefresh) {
      final cachedData = await _cacheManager.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
    }
    
    // Fetch from API
    try {
      final response = await apiFetch();
      
      // Cache the response
      await _cacheManager.set(
        cacheKey,
        response,
        diskDuration: cacheDuration,
      );
      
      return response;
    } catch (e) {
      // Try to return stale cache on error
      final staleData = await _cacheManager.get<Map<String, dynamic>>(
        cacheKey,
        forceRefresh: false,
      );
      
      if (staleData != null) {
        return {
          ...staleData,
          'stale': true,
          'fetchError': e.toString(),
        };
      }
      
      rethrow;
    }
  }
  
  /// Invalidate API cache for specific endpoint
  Future<void> invalidateCache(String endpoint) async {
    await _cacheManager.remove('api_$endpoint');
  }
  
  /// Prefetch and cache API data
  Future<void> prefetchEndpoint({
    required String endpoint,
    required Future<Map<String, dynamic>> Function() apiFetch,
    Duration cacheDuration = const Duration(hours: 24),
  }) async {
    await fetchWithCache(
      endpoint: endpoint,
      apiFetch: apiFetch,
      cacheDuration: cacheDuration,
      forceRefresh: true,
    );
  }
}
```

## 6. Offline Mode Strategy

### Offline Capability Implementation

```dart
class OfflineManager {
  final ConnectivityService _connectivityService;
  final LocalDatabase _localDb;
  final ApiService _apiService;
  final ClassificationService _classificationService;
  final SyncQueue _syncQueue;
  
  bool _isOffline = false;
  
  OfflineManager({
    required ConnectivityService connectivityService,
    required LocalDatabase localDb,
    required ApiService apiService,
    required ClassificationService classificationService,
    required SyncQueue syncQueue,
  }) : 
    _connectivityService = connectivityService,
    _localDb = localDb,
    _apiService = apiService,
    _classificationService = classificationService,
    _syncQueue = syncQueue;
  
  /// Initialize offline manager
  Future<void> initialize() async {
    // Check initial connectivity
    _isOffline = !(await _connectivityService.isConnected());
    
    // Listen for connectivity changes
    _connectivityService.onConnectivityChanged.listen((hasConnection) {
      final wasOffline = _isOffline;
      _isOffline = !hasConnection;
      
      // If coming back online, sync queued operations
      if (wasOffline && hasConnection) {
        _syncQueue.processQueue();
      }
    });
  }
  
  /// Check if device is offline
  bool isOffline() {
    return _isOffline;
  }
  
  /// Perform classification in offline mode
  Future<ClassificationResult?> classifyOffline(Uint8List imageData) async {
    if (!_isOffline) {
      // If online, use regular classification
      return null;
    }
    
    // Process image
    final processedImage = await ImageManager(_localDb.getAppDirectory())
        .processImage(imageData);
    
    // Check cache for match
    final cachedResult = await _localDb.getCachedClassification(
      processedImage.imageHash,
    );
    
    if (cachedResult != null) {
      return cachedResult;
    }
    
    // If available, use on-device model
    final onDeviceResult = await _classificationService.classifyWithOnDeviceModel(
      processedImage.resized,
    );
    
    if (onDeviceResult != null) {
      // Mark as offline classification
      onDeviceResult.isOfflineClassification = true;
      
      // Save to history but with offline flag
      await _localDb.saveClassificationHistory(onDeviceResult);
      
      // Queue for verification when back online
      _syncQueue.addClassificationForVerification(
        onDeviceResult.id,
        processedImage.resized,
      );
      
      return onDeviceResult;
    }
    
    // No offline classification available
    return null;
  }
  
  /// Get educational content in offline mode
  Future<List<EducationalContent>> getOfflineEducationalContent(
    String category,
  ) async {
    return _localDb.getEducationalContentByCategory(category);
  }
  
  /// Check if a feature is available offline
  bool isFeatureAvailableOffline(FeatureType feature) {
    switch (feature) {
      case FeatureType.basicClassification:
        return true;
      case FeatureType.historyAccess:
        return true;
      case FeatureType.basicEducation:
        return true;
      case FeatureType.advancedEducation:
        return false;
      case FeatureType.gamification:
        return true;
      case FeatureType.socialFeatures:
        return false;
      case FeatureType.analytics:
        return false;
      default:
        return false;
    }
  }
}

class SyncQueue {
  final LocalDatabase _localDb;
  final ApiService _apiService;
  final Map<String, Uint8List> _pendingClassifications = {};
  bool _isProcessing = false;
  
  SyncQueue({
    required LocalDatabase localDb,
    required ApiService apiService,
  }) :
    _localDb = localDb,
    _apiService = apiService;
  
  /// Add classification for verification when online
  Future<void> addClassificationForVerification(
    String classificationId,
    Uint8List imageData,
  ) async {
    _pendingClassifications[classificationId] = imageData;
    await _saveQueueState();
  }
  
  /// Process queued operations
  Future<void> processQueue() async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    
    try {
      // Process pending classifications
      final pendingIds = List<String>.from(_pendingClassifications.keys);
      
      for (final classificationId in pendingIds) {
        final imageData = _pendingClassifications[classificationId];
        
        if (imageData != null) {
          // Get offline classification
          final offlineResult = await _localDb.getClassificationById(classificationId);
          
          if (offlineResult != null) {
            // Verify with online API
            final onlineResult = await _apiService.classifyImage(imageData);
            
            // Update local record with verified result
            if (onlineResult != null) {
              final updatedResult = ClassificationResult(
                id: classificationId,
                category: onlineResult.category,
                subcategory: onlineResult.subcategory,
                disposalInstructions: onlineResult.disposalInstructions,
                confidenceScore: onlineResult.confidenceScore,
                classificationSource: 'online_verified',
                classifiedAt: offlineResult.classifiedAt,
                updatedAt: DateTime.now(),
                imageHash: offlineResult.imageHash,
                isOfflineClassification: false,
                isVerified: true,
              );
              
              await _localDb.updateClassification(updatedResult);
            }
          }
          
          // Remove from pending queue
          _pendingClassifications.remove(classificationId);
        }
      }
      
      // Save updated queue state
      await _saveQueueState();
    } finally {
      _isProcessing = false;
    }
  }
  
  /// Save queue state to persistent storage
  Future<void> _saveQueueState() async {
    final pendingIds = _pendingClassifications.keys.toList();
    await _localDb.saveSyncQueueState(pendingIds);
  }
  
  /// Load queue state from persistent storage
  Future<void> loadQueueState() async {
    final pendingIds = await _localDb.getSyncQueueState();
    
    for (final id in pendingIds) {
      final classification = await _localDb.getClassificationById(id);
      
      if (classification != null && classification.imageHash != null) {
        final imageData = await _localDb.getCachedImage(classification.imageHash!);
        
        if (imageData != null) {
          _pendingClassifications[id] = imageData;
        }
      }
    }
  }
}
```

## 7. Educational Content Management

### Content Repository Implementation

```dart
class EducationalContentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final CacheManager _cacheManager;
  final LocalDatabase _localDb;
  
  EducationalContentRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required CacheManager cacheManager,
    required LocalDatabase localDb,
  }) :
    _firestore = firestore,
    _storage = storage,
    _cacheManager = cacheManager,
    _localDb = localDb;
  
  /// Get educational content by category
  Future<List<EducationalContent>> getContentByCategory(
    String category, {
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'edu_content_$category';
    
    // Try cache first
    if (!forceRefresh) {
      final cached = await _cacheManager.get<List<dynamic>>(cacheKey);
      if (cached != null) {
        return cached
            .map((item) => EducationalContent.fromJson(item))
            .toList();
      }
    }
    
    try {
      // Get from Firestore
      final snapshot = await _firestore
          .collection('contentLibrary')
          .where('categories', arrayContains: category)
          .limit(limit)
          .get();
      
      final contentList = snapshot.docs
          .map((doc) => EducationalContent.fromFirestore(doc))
          .toList();
      
      // Cache results
      await _cacheManager.set(
        cacheKey,
        contentList.map((c) => c.toJson()).toList(),
        diskDuration: Duration(days: 7),
      );
      
      // Store for offline access
      for (final content in contentList) {
        await _localDb.saveEducationalContent(content);
      }
      
      return contentList;
    } catch (e) {
      // Fallback to local database for offline access
      return await _localDb.getEducationalContentByCategory(category);
    }
  }
  
  /// Get content by difficulty level
  Future<List<EducationalContent>> getContentByDifficulty(
    DifficultyLevel difficulty, {
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'edu_content_difficulty_${difficulty.toString()}';
    
    // Implementation similar to getContentByCategory
    // ...
  }
  
  /// Get educational content assets
  Future<Uint8List?> getContentAsset(
    String contentId,
    String assetPath,
  ) async {
    final cacheKey = 'edu_asset_${contentId}_$assetPath';
    
    // Check cache
    final cached = await _cacheManager.get<Uint8List>(cacheKey);
    if (cached != null) {
      return cached;
    }
    
    try {
      // Get from Firebase Storage
      final ref = _storage.ref().child('educational_content/$contentId/$assetPath');
      final data = await ref.getData();
      
      if (data != null) {
        // Cache for future use
        await _cacheManager.set(
          cacheKey,
          data,
          diskDuration: Duration(days: 30), // Long cache for static content
        );
        
        return data;
      }
    } catch (e) {
      print('Error loading content asset: $e');
    }
    
    return null;
  }
  
  /// Track content view
  Future<void> trackContentView(String contentId) async {
    // Record locally
    await _localDb.recordContentView(contentId, DateTime.now());
    
    // If online, update cloud analytics
    final connectivityService = ConnectivityService();
    if (await connectivityService.isConnected()) {
      try {
        await _firestore
            .collection('contentViews')
            .add({
              'contentId': contentId,
              'timestamp': FieldValue.serverTimestamp(),
              'anonymous': true, // For privacy
            });
      } catch (e) {
        // Ignore analytics errors
        print('Error tracking content view: $e');
      }
    }
  }
  
  /// Get recommended content
  Future<List<EducationalContent>> getRecommendedContent(
    String userId, {
    int limit = 5,
  }) async {
    // Get user's viewed content
    final viewedContent = await _localDb.getViewedContent(userId);
    
    // Get user's categories of interest
    final interests = await _localDb.getUserInterests(userId);
    
    try {
      // Query Firestore for recommendations
      var query = _firestore.collection('contentLibrary')
          .where('difficulty', isLessThanOrEqualTo: 3) // Not too advanced
          .limit(limit * 2); // Get extra to filter viewed items
      
      if (interests.isNotEmpty) {
        // If user has interests, prioritize those categories
        query = query.where('categories', arrayContainsAny: interests);
      }
      
      final snapshot = await query.get();
      
      // Filter out already viewed content
      final contentList = snapshot.docs
          .map((doc) => EducationalContent.fromFirestore(doc))
          .where((content) => !viewedContent.contains(content.id))
          .take(limit)
          .toList();
      
      // If not enough recommendations, get some general popular content
      if (contentList.length < limit) {
        final additionalCount = limit - contentList.length;
        final popularSnapshot = await _firestore
            .collection('contentLibrary')
            .orderBy('viewCount', descending: true)
            .limit(additionalCount * 2)
            .get();
        
        final popularContent = popularSnapshot.docs
            .map((doc) => EducationalContent.fromFirestore(doc))
            .where((content) => !viewedContent.contains(content.id) && 
                              !contentList.contains(content))
            .take(additionalCount)
            .toList();
        
        contentList.addAll(popularContent);
      }
      
      // Store for offline access
      for (final content in contentList) {
        await _localDb.saveEducationalContent(content);
      }
      
      return contentList;
    } catch (e) {
      // Fallback to local database
      return await _localDb.getPopularEducationalContent(limit);
    }
  }
  
  /// Prefetch essential content for offline access
  Future<void> prefetchEssentialContent() async {
    // Get basic content for main categories
    final mainCategories = [
      'recyclable',
      'compostable',
      'hazardous',
      'general_waste',
    ];
    
    for (final category in mainCategories) {
      final content = await getContentByCategory(
        category,
        limit: 3,
        forceRefresh: true,
      );
      
      // Prefetch assets for each content item
      for (final item in content) {
        if (item.mainImagePath != null) {
          await getContentAsset(item.id, item.mainImagePath!);
        }
      }
    }
  }
}
```

## 8. Analytics Data Management

### Analytics Implementation

```dart
class AnalyticsManager {
  final FirebaseAnalytics _analytics;
  final LocalDatabase _localDb;
  final ConnectivityService _connectivityService;
  
  AnalyticsManager({
    required FirebaseAnalytics analytics,
    required LocalDatabase localDb,
    required ConnectivityService connectivityService,
  }) :
    _analytics = analytics,
    _localDb = localDb,
    _connectivityService = connectivityService;
  
  /// Track app event with offline support
  Future<void> trackEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
    bool requiresOnline = false,
  }) async {
    final timestamp = DateTime.now();
    final isOnline = await _connectivityService.isConnected();
    
    // Store event locally
    await _localDb.saveAnalyticsEvent(
      eventName: eventName,
      parameters: parameters,
      timestamp: timestamp,
    );
    
    // If online, send to Firebase Analytics
    if (isOnline) {
      try {
        await _analytics.logEvent(
          name: eventName,
          parameters: parameters,
        );
      } catch (e) {
        print('Error logging analytics event: $e');
      }
      
      // Sync queued events if online
      if (!requiresOnline) {
        _syncQueuedEvents();
      }
    }
  }
  
  /// Track classification event
  Future<void> trackClassification({
    required String category,
    required String subcategory,
    required double confidence,
    required bool fromCache,
    required bool isOffline,
  }) async {
    await trackEvent(
      eventName: 'classification_completed',
      parameters: {
        'category': category,
        'subcategory': subcategory,
        'confidence': confidence,
        'from_cache': fromCache,
        'is_offline': isOffline,
      },
    );
  }
  
  /// Track educational content view
  Future<void> trackContentView({
    required String contentId,
    required String contentType,
    required String category,
    required int timeSpentSeconds,
  }) async {
    await trackEvent(
      eventName: 'content_viewed',
      parameters: {
        'content_id': contentId,
        'content_type': contentType,
        'category': category,
        'time_spent': timeSpentSeconds,
      },
    );
  }
  
  /// Track achievement unlocked
  Future<void> trackAchievementUnlocked({
    required String achievementId,
    required String achievementName,
    required int pointsEarned,
  }) async {
    await trackEvent(
      eventName: 'achievement_unlocked',
      parameters: {
        'achievement_id': achievementId,
        'achievement_name': achievementName,
        'points_earned': pointsEarned,
      },
    );
  }
  
  /// Synchronize queued analytics events
  Future<void> _syncQueuedEvents() async {
    final queuedEvents = await _localDb.getQueuedAnalyticsEvents();
    
    for (final event in queuedEvents) {
      try {
        await _analytics.logEvent(
          name: event.eventName,
          parameters: event.parameters,
        );
        
        // Mark as synced
        await _localDb.markEventSynced(event.id);
      } catch (e) {
        print('Error syncing queued event: $e');
      }
    }
  }
  
  /// Set user properties
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      print('Error setting user property: $e');
    }
  }
  
  /// Get local analytics data for user insights
  Future<Map<String, dynamic>> getUserInsights() async {
    // Get classification statistics
    final classStats = await _localDb.getClassificationStatistics();
    
    // Get content engagement metrics
    final contentEngagement = await _localDb.getContentEngagementMetrics();
    
    // Get achievement progress
    final achievementProgress = await _localDb.getAchievementProgress();
    
    return {
      'classifications': classStats,
      'content_engagement': contentEngagement,
      'achievements': achievementProgress,
      'insights_generated': DateTime.now().toIso8601String(),
    };
  }
}
```

## 9. Data Privacy Implementation

### Privacy-Focused Data Management

```dart
class PrivacyManager {
  final LocalDatabase _localDb;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final SecureStorage _secureStorage;
  final ConsentManager _consentManager;
  
  PrivacyManager({
    required LocalDatabase localDb,
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required SecureStorage secureStorage,
    required ConsentManager consentManager,
  }) :
    _localDb = localDb,
    _firestore = firestore,
    _storage = storage,
    _secureStorage = secureStorage,
    _consentManager = consentManager;
  
  /// Process data export request (GDPR compliance)
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    // Verify user authentication
    // ...
    
    // Collect user profile data
    final userData = <String, dynamic>{};
    
    // Get profile information
    final userProfile = await _localDb.getUserProfile(userId);
    userData['profile'] = userProfile.toJson();
    
    // Get classification history (metadata only, not images)
    final classificationHistory = await _localDb.getClassificationHistory(userId);
    userData['classifications'] = classificationHistory
        .map((c) => {
          'id': c.id,
          'category': c.category,
          'subcategory': c.subcategory,
          'classifiedAt': c.classifiedAt.toIso8601String(),
          'isOfflineClassification': c.isOfflineClassification,
        })
        .toList();
    
    // Get achievement data
    final achievements = await _localDb.getUserAchievements(userId);
    userData['achievements'] = achievements
        .map((a) => a.toJson())
        .toList();
    
    // Get content progress
    final contentProgress = await _localDb.getContentProgress(userId);
    userData['content_progress'] = contentProgress
        .map((p) => p.toJson())
        .toList();
    
    // Get consent records
    final consentRecords = await _consentManager.getUserConsentRecords(userId);
    userData['consent_records'] = consentRecords
        .map((c) => c.toJson())
        .toList();
    
    return userData;
  }
  
  /// Delete user data (GDPR compliance)
  Future<bool> deleteUserData(String userId) async {
    // Verify user authentication
    // ...
    
    try {
      // Delete local data
      await _localDb.deleteAllUserData(userId);
      
      // Delete secure storage data
      await _secureStorage.deleteAll();
      
      // Delete cloud data
      await _deleteCloudData(userId);
      
      return true;
    } catch (e) {
      print('Error deleting user data: $e');
      return false;
    }
  }
  
  /// Delete cloud data
  Future<void> _deleteCloudData(String userId) async {
    // Delete Firestore data
    final batch = _firestore.batch();
    
    // Delete user profile
    final userDoc = _firestore.collection('users').doc(userId);
    batch.delete(userDoc);
    
    // Delete classifications
    final classificationsQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('classifications')
        .get();
    
    for (final doc in classificationsQuery.docs) {
      batch.delete(doc.reference);
    }
    
    // Delete achievements
    final achievementsQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .get();
    
    for (final doc in achievementsQuery.docs) {
      batch.delete(doc.reference);
    }
    
    // Delete content progress
    final progressQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('contentProgress')
        .get();
    
    for (final doc in progressQuery.docs) {
      batch.delete(doc.reference);
    }
    
    // Execute batch delete
    await batch.commit();
    
    // Delete Firebase Storage data
    try {
      final storageRef = _storage.ref().child('users/$userId');
      await storageRef.delete();
    } catch (e) {
      // Ignore if folder doesn't exist
      print('Error deleting storage data: $e');
    }
  }
  
  /// Anonymize user data (partial GDPR compliance)
  Future<bool> anonymizeUserData(String userId) async {
    try {
      // Update user profile with anonymized data
      final anonymizedProfile = AnonymizedUserProfile(
        id: userId,
        createdAt: DateTime.now(),
      );
      
      await _localDb.updateUserProfile(anonymizedProfile);
      
      // Keep classification data but remove personal identifiers
      await _localDb.anonymizeClassificationHistory(userId);
      
      // Delete sensitive data
      await _secureStorage.deleteAll();
      
      // Anonymize cloud data
      await _anonymizeCloudData(userId);
      
      return true;
    } catch (e) {
      print('Error anonymizing user data: $e');
      return false;
    }
  }
  
  /// Anonymize cloud data
  Future<void> _anonymizeCloudData(String userId) async {
    // Similar to delete but update user profile with anonymized data
    // ...
  }
  
  /// Update data retention settings
  Future<void> updateDataRetentionSettings({
    required String userId,
    required int classificationRetentionDays,
    required bool retainImages,
    required bool shareAnonymizedData,
  }) async {
    // Update user preferences
    await _localDb.updateDataRetentionSettings(
      userId: userId,
      classificationRetentionDays: classificationRetentionDays,
      retainImages: retainImages,
      shareAnonymizedData: shareAnonymizedData,
    );
    
    // Apply retention policy immediately
    await _applyRetentionPolicy(userId);
    
    // Update cloud preferences if online
    // ...
  }
  
  /// Apply data retention policy
  Future<void> _applyRetentionPolicy(String userId) async {
    // Get retention settings
    final settings = await _localDb.getDataRetentionSettings(userId);
    
    // Calculate retention date
    final retentionDate = DateTime.now().subtract(
      Duration(days: settings.classificationRetentionDays),
    );
    
    // Delete classifications older than retention date
    await _localDb.deleteClassificationsOlderThan(userId, retentionDate);
    
    // Delete images if setting is false
    if (!settings.retainImages) {
      await _localDb.deleteAllClassificationImages(userId);
    }
  }
}

class SecureStorage {
  final FlutterSecureStorage _storage;
  
  SecureStorage(this._storage);
  
  /// Store sensitive data securely
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  /// Retrieve sensitive data
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }
  
  /// Delete sensitive data
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
  
  /// Delete all sensitive data
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
```

## 10. Implementation Roadmap

### Phase 1: Core Data Foundation (Weeks 1-2)

1. **Local Database Setup**
   - Implement Hive configuration
   - Create core data models
   - Set up basic CRUD operations

2. **User Data Management**
   - Implement user profile storage
   - Set up settings persistence
   - Create authentication state management

3. **Classification Storage**
   - Implement classification result model
   - Create classification history repository
   - Set up image hashing implementation

### Phase 2: Cloud Integration (Weeks 3-4)

1. **Firebase Configuration**
   - Set up Firestore structure
   - Implement security rules
   - Create initial cloud functions

2. **Synchronization Framework**
   - Implement data synchronization logic
   - Create conflict resolution strategy
   - Set up background sync operations

3. **Educational Content Fetching**
   - Implement content repository
   - Create content caching logic
   - Set up offline content access

### Phase 3: Advanced Features (Weeks 5-6)

1. **Caching System**
   - Implement multi-level caching
   - Create API response caching
   - Set up cache management utilities

2. **Offline Mode Support**
   - Implement offline detection logic
   - Create offline operation queue
   - Set up background synchronization

3. **Analytics Implementation**
   - Set up event tracking system
   - Implement offline analytics storage
   - Create analytics synchronization logic

### Phase 4: Optimization & Privacy (Weeks 7-8)

1. **Performance Optimization**
   - Implement efficient indexing
   - Create data access patterns optimization
   - Set up query performance monitoring

2. **Privacy Features**
   - Implement data export functionality
   - Create data deletion processes
   - Set up privacy-preserving analytics

3. **Edge Case Handling**
   - Implement error recovery mechanisms
   - Create data migration utilities
   - Set up data validation and sanitization

## Conclusion

This comprehensive data storage and management strategy provides a robust approach for efficiently handling the various data types and access patterns in the Waste Segregation App. By implementing a layered architecture with local-first storage, efficient caching, and thoughtful cloud integration, the app can provide excellent performance and offline capabilities while respecting user privacy.

The implementation roadmap provides a structured approach for incrementally building the data management system, allowing a solo developer to make consistent progress while maintaining a functional application throughout development.

Key benefits of this strategy include:

1. **Efficient Performance**: Through optimized local storage and multi-level caching
2. **Robust Offline Support**: With local-first architecture and sync queue system
3. **Privacy Protection**: Through data minimization and user control
4. **Scalable Architecture**: Supporting growth from initial users to large-scale adoption
5. **Resource Efficiency**: Optimized for solo development with phased implementation

By following this strategy, the Waste Segregation App will have a solid data foundation that supports its core functionality while enabling future feature expansion.
