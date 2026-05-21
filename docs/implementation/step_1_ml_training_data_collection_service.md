# Step 1: ML Training Data Collection Service Implementation

> **Status update, 2026-05-21:** This older plan is superseded for production
> behavior by `docs/review/TRAINING_DATA_PIPELINE_FOUNDATION_2026-05-21.md`.
> The automatic "collect ML training data from every classification" framing is
> unsafe for a real product. Current policy: no image, correction, or
> classification record enters training use unless explicit
> `training-data-v1` consent exists, the consent snapshot is captured, deletion
> and revocation can exclude the record, and review/dataset state is tracked.

## 🎯 **OBJECTIVE**
Implement explicit-consent training candidate collection that separates app
history from future model-training data, preserves deletion/revocation rights,
and enables future model training without silent retention.

## 📋 **PREREQUISITES**
- ✅ `CloudStorageService` exists and handles classification saving
- ✅ Firebase collections structure established
- ✅ Classification model with required fields
- ✅ User authentication system in place

## 🏗️ **IMPLEMENTATION TASKS**

### **Task 1.1: Create MLTrainingDataService**

#### **File: `lib/core/services/ml_training_data_service.dart`**

**Action Items:**
1. **Create base service class**
   ```dart
   class MLTrainingDataService {
     static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
     static const String _appSalt = 'waste_segregation_app_salt_2024';
     
     // Core methods to implement
   }
   ```

2. **Implement privacy-preserving hash function**
   ```dart
   static String _hashUserId(String userId) {
     final bytes = utf8.encode(userId + _appSalt);
     final digest = sha256.convert(bytes);
     return digest.toString();
   }
   ```

3. **Create anonymous classification data structure**
   ```dart
   Map<String, dynamic> _createAnonymousClassification(
     Classification classification, 
     String hashedUserId
   ) {
     return {
       'itemName': classification.itemName,
       'category': classification.category,
       'subcategory': classification.subcategory,
       'materialType': classification.materialType,
       'isRecyclable': classification.isRecyclable,
       'explanation': classification.explanation,
       'hashedUserId': hashedUserId,
       'mlTrainingData': true,
       'timestamp': FieldValue.serverTimestamp(),
       'region': 'India', // TODO: Make dynamic based on user location
       'appVersion': PackageInfo.fromPlatform().version,
     };
   }
   ```

4. **Implement ML data collection method**
   ```dart
   static Future<void> collectMLTrainingData(
     Classification classification,
     String userId,
   ) async {
     try {
       final hashedUserId = _hashUserId(userId);
       final anonymousData = _createAnonymousClassification(
         classification, 
         hashedUserId
       );
       
       // Save to admin_classifications collection
       await _firestore
           .collection('admin_classifications')
           .add(anonymousData);
           
       // Update recovery metadata
       await _updateRecoveryMetadata(hashedUserId);
       
       debugPrint('✅ ML training data collected successfully');
     } catch (e) {
       debugPrint('❌ Error collecting ML training data: $e');
       // Don't throw - ML collection failure shouldn't break user flow
     }
   }
   ```

5. **Implement recovery metadata tracking**
   ```dart
   static Future<void> _updateRecoveryMetadata(String hashedUserId) async {
     final docRef = _firestore
         .collection('admin_user_recovery')
         .doc(hashedUserId);
         
     await docRef.set({
       'lastBackup': FieldValue.serverTimestamp(),
       'classificationCount': FieldValue.increment(1),
       'appVersion': (await PackageInfo.fromPlatform()).version,
       'region': 'India', // TODO: Make dynamic
     }, SetOptions(merge: true));
   }
   ```

### **Task 1.2: Integrate with Existing CloudStorageService**

#### **File: `lib/core/services/enhanced_storage_service.dart`**

**Action Items:**
1. **Import the new ML service**
   ```dart
   import 'ml_training_data_service.dart';
   ```

2. **Modify existing `saveClassification` method**
   ```dart
   Future<void> saveClassification(Classification classification) async {
     try {
       // Existing user classification save logic (keep unchanged)
       await _saveUserClassification(classification);
       
       // NEW: Collect ML training data
       final user = FirebaseAuth.instance.currentUser;
       if (user != null) {
         // For signed-in users
         await MLTrainingDataService.collectMLTrainingData(
           classification, 
           user.uid
         );
       } else {
         // For guest users - create anonymous identifier
         final guestId = await _getOrCreateGuestId();
         await MLTrainingDataService.collectMLTrainingData(
           classification, 
           guestId
         );
       }
       
       debugPrint('✅ Classification saved with ML data collection');
     } catch (e) {
       debugPrint('❌ Error in enhanced classification save: $e');
       rethrow;
     }
   }
   ```

3. **Implement guest ID generation**
   ```dart
   Future<String> _getOrCreateGuestId() async {
     final prefs = await SharedPreferences.getInstance();
     String? guestId = prefs.getString('guest_user_id');
     
     if (guestId == null) {
       // Create persistent anonymous guest ID
       guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
       await prefs.setString('guest_user_id', guestId);
     }
     
     return guestId;
   }
   ```

### **Task 1.3: Create Firebase Collection Structure**

#### **Firestore Collections to Create:**

**Action Items:**
1. **Set up `admin_classifications` collection structure**
   ```
   admin_classifications/{autoId}
   ├── itemName: string
   ├── category: string  
   ├── subcategory: string
   ├── materialType: string
   ├── isRecyclable: boolean
   ├── explanation: string
   ├── hashedUserId: string (SHA-256 hash)
   ├── mlTrainingData: boolean (always true)
   ├── timestamp: timestamp
   ├── region: string
   └── appVersion: string
   ```

2. **Set up `admin_user_recovery` collection structure**
   ```
   admin_user_recovery/{hashedUserId}
   ├── lastBackup: timestamp
   ├── classificationCount: number
   ├── appVersion: string
   └── region: string
   ```

3. **Update Firestore security rules**
   ```javascript
   // Add to firestore.rules
   match /admin_classifications/{document} {
     allow read, write: if request.auth != null && 
       request.auth.token.email == 'pranaysuyash@gmail.com';
   }
   
   match /admin_user_recovery/{document} {
     allow read, write: if request.auth != null && 
       request.auth.token.email == 'pranaysuyash@gmail.com';
   }
   ```

### **Task 1.4: Add Privacy Compliance Features**

#### **File: `lib/core/services/ml_training_data_service.dart`**

**Action Items:**
1. **Implement data validation to prevent personal data leaks**
   ```dart
   static bool _validateAnonymousData(Map<String, dynamic> data) {
     // Check for personal information patterns
     final personalDataPatterns = [
       RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), // Email
       RegExp(r'\b\d{10}\b'), // Phone numbers
       RegExp(r'\b[A-Z][a-z]+ [A-Z][a-z]+\b'), // Names
     ];
     
     for (final entry in data.entries) {
       if (entry.value is String) {
         for (final pattern in personalDataPatterns) {
           if (pattern.hasMatch(entry.value)) {
             debugPrint('⚠️ Personal data detected in ML training data: ${entry.key}');
             return false;
           }
         }
       }
     }
     return true;
   }
   ```

2. **Add data export functionality for transparency**
   ```dart
   static Future<List<Map<String, dynamic>>> exportUserMLData(String userId) async {
     final hashedUserId = _hashUserId(userId);
     
     final querySnapshot = await _firestore
         .collection('admin_classifications')
         .where('hashedUserId', isEqualTo: hashedUserId)
         .get();
         
     return querySnapshot.docs
         .map((doc) => {
           ...doc.data(),
           'id': doc.id,
           'note': 'This is anonymized data used for ML training'
         })
         .toList();
   }
   ```

### **Task 1.5: Testing and Validation**

#### **File: `test/ml_training_data_service_test.dart`**

**Action Items:**
1. **Create unit tests for hash function**
   ```dart
   group('MLTrainingDataService Hash Function', () {
     test('should generate consistent hashes', () {
       const userId = 'test@example.com';
       final hash1 = MLTrainingDataService._hashUserId(userId);
       final hash2 = MLTrainingDataService._hashUserId(userId);
       expect(hash1, equals(hash2));
     });
     
     test('should generate different hashes for different users', () {
       final hash1 = MLTrainingDataService._hashUserId('user1@example.com');
       final hash2 = MLTrainingDataService._hashUserId('user2@example.com');
       expect(hash1, isNot(equals(hash2)));
     });
   });
   ```

2. **Create integration tests for ML data collection**
   ```dart
   group('ML Data Collection Integration', () {
     testWidgets('should collect ML data on classification save', (tester) async {
       // Test that ML data is collected when classification is saved
       // Verify anonymous data structure
       // Verify recovery metadata update
     });
   });
   ```

3. **Create privacy validation tests**
   ```dart
   group('Privacy Compliance', () {
     test('should reject data with personal information', () {
       final dataWithEmail = {'itemName': 'bottle', 'userEmail': 'test@example.com'};
       expect(MLTrainingDataService._validateAnonymousData(dataWithEmail), isFalse);
     });
   });
   ```

## 🔍 **VERIFICATION CHECKLIST**

### **Functional Verification:**
- [ ] ML training data is collected on every classification save
- [ ] Guest users get persistent anonymous IDs
- [ ] Signed-in users get proper hashed correlation
- [ ] Recovery metadata is updated correctly
- [ ] Firebase collections are created with proper structure

### **Privacy Verification:**
- [ ] No personal identifiers in admin_classifications
- [ ] Hash function generates irreversible hashes
- [ ] Data validation prevents personal data leaks
- [ ] Only admin email can access ML collections

### **Integration Verification:**
- [ ] Existing classification save flow works unchanged
- [ ] ML collection failure doesn't break user experience
- [ ] Performance impact is minimal
- [ ] Works for both guest and signed-in users

## 🚨 **CRITICAL SUCCESS FACTORS**

1. **Zero Breaking Changes**: Existing user flows must work exactly as before
2. **Privacy First**: Absolutely no personal data in ML training collections
3. **Failure Resilience**: ML collection failures must not affect user experience
4. **Performance**: ML data collection must be fast and asynchronous

## 📈 **SUCCESS METRICS**

- **Collection Rate**: 100% of classifications should trigger ML data collection
- **Privacy Compliance**: 0 personal identifiers found in admin collections
- **Performance**: ML collection adds <100ms to classification save time
- **Error Rate**: <1% of ML collections should fail

## 🔄 **NEXT STEPS**
After completing this step:
1. Move to Step 2: Enhanced FirebaseCleanupService with ML Data Preservation
2. Verify ML data is being collected in Firebase console
3. Test with both guest and signed-in users
4. Monitor performance and error rates

## 💡 **NOTES FOR AI AGENTS**

- **Preserve Existing Functionality**: Never modify existing user-facing behavior
- **Add, Don't Replace**: Extend existing services rather than replacing them
- **Privacy Critical**: Any personal data leak in ML collections is a critical failure
- **Error Handling**: ML collection should fail silently to protect user experience
- **Testing Essential**: This is foundation for all future ML features - test thoroughly
