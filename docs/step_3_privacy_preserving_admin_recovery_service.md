# Step 3: Privacy-Preserving Admin Recovery Service

## 🎯 **OBJECTIVE**
Build a comprehensive admin recovery system that enables admins to help users recover their data without exposing personal information, using privacy-preserving lookup and recovery mechanisms.

## 📋 **PREREQUISITES**
- ✅ Step 1 completed: ML Training Data Collection Service with hashed user correlation
- ✅ Step 2 completed: Enhanced deletion flows with ML preservation and recovery metadata
- ✅ `admin_user_recovery` collection with hashed user IDs
- ✅ Admin authentication system (`pranaysuyash@gmail.com`)

## 🏗️ **IMPLEMENTATION TASKS**

### **Task 3.1: Create AdminDataRecoveryService**

#### **File: `lib/core/services/admin_data_recovery_service.dart`**

**Action Items:**
1. **Create base recovery service class**
   ```dart
   class AdminDataRecoveryService {
     static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
     static final FirebaseAuth _auth = FirebaseAuth.instance;
     static const String _adminEmail = 'pranaysuyash@gmail.com';
     static const String _appSalt = 'waste_segregation_app_salt_2024';
     
     // Core recovery methods
   }
   ```

2. **Implement admin verification**
   ```dart
   static Future<void> _verifyAdminAccess() async {
     final currentUser = _auth.currentUser;
     if (currentUser == null) {
       throw AdminAccessException('No user authenticated');
     }
     
     if (currentUser.email != _adminEmail) {
       throw AdminAccessException('Unauthorized: Admin access required');
     }
     
     // Additional security check - verify token is still valid
     await currentUser.getIdToken(true);
     debugPrint('✅ Admin access verified for: ${currentUser.email}');
   }
   ```

3. **Implement privacy-preserving user lookup**
   ```dart
   static Future<UserRecoveryInfo?> lookupUserForRecovery(String userEmail) async {
     await _verifyAdminAccess();
     
     try {
       // Hash the user email for privacy-preserving lookup
       final hashedUserId = _hashUserId(userEmail);
       
       // Look up recovery metadata using hashed ID
       final recoveryDoc = await _firestore
           .collection('admin_user_recovery')
           .doc(hashedUserId)
           .get();
           
       if (!recoveryDoc.exists) {
         debugPrint('❌ No recovery data found for user');
         return null;
       }
       
       final data = recoveryDoc.data()!;
       return UserRecoveryInfo.fromMap(hashedUserId, data);
       
     } catch (e) {
       debugPrint('❌ Error in user lookup: $e');
       rethrow;
     }
   }
   
   static String _hashUserId(String userId) {
     final bytes = utf8.encode(userId + _appSalt);
     final digest = sha256.convert(bytes);
     return digest.toString();
   }
   ```

4. **Create UserRecoveryInfo model**
   ```dart
   class UserRecoveryInfo {
     final String hashedUserId;
     final int classificationCount;
     final DateTime? lastBackup;
     final String? appVersion;
     final String? region;
     final bool accountDeleted;
     final bool dataPreserved;
     final String? deletionType;
     final DateTime? deletionTimestamp;
     
     UserRecoveryInfo({
       required this.hashedUserId,
       required this.classificationCount,
       this.lastBackup,
       this.appVersion,
       this.region,
       this.accountDeleted = false,
       this.dataPreserved = true,
       this.deletionType,
       this.deletionTimestamp,
     });
     
     factory UserRecoveryInfo.fromMap(String hashedUserId, Map<String, dynamic> data) {
       return UserRecoveryInfo(
         hashedUserId: hashedUserId,
         classificationCount: data['classificationCount'] ?? 0,
         lastBackup: (data['lastBackup'] as Timestamp?)?.toDate(),
         appVersion: data['appVersion'],
         region: data['region'],
         accountDeleted: data['accountDeleted'] ?? false,
         dataPreserved: data['dataPreserved'] ?? true,
         deletionType: data['deletionType'],
         deletionTimestamp: (data['deletionTimestamp'] as Timestamp?)?.toDate(),
       );
     }
     
     Map<String, dynamic> toMap() {
       return {
         'hashedUserId': hashedUserId,
         'classificationCount': classificationCount,
         'lastBackup': lastBackup,
         'appVersion': appVersion,
         'region': region,
         'accountDeleted': accountDeleted,
         'dataPreserved': dataPreserved,
         'deletionType': deletionType,
         'deletionTimestamp': deletionTimestamp,
       };
     }
   }
   ```

### **Task 3.2: Implement Data Recovery Operations**

#### **File: `lib/core/services/admin_data_recovery_service.dart`**

**Action Items:**
1. **Implement classification data recovery**
   ```dart
   static Future<List<Map<String, dynamic>>> getRecoverableClassifications(
     String hashedUserId
   ) async {
     await _verifyAdminAccess();
     
     try {
       // Fetch anonymized classification data
       final classificationsQuery = await _firestore
           .collection('admin_classifications')
           .where('hashedUserId', isEqualTo: hashedUserId)
           .orderBy('timestamp', descending: true)
           .get();
           
       final classifications = classificationsQuery.docs.map((doc) {
         final data = doc.data();
         return {
           'id': doc.id,
           'itemName': data['itemName'],
           'category': data['category'],
           'subcategory': data['subcategory'],
           'materialType': data['materialType'],
           'isRecyclable': data['isRecyclable'],
           'explanation': data['explanation'],
           'timestamp': data['timestamp'],
           'region': data['region'],
           'appVersion': data['appVersion'],
           // Note: No personal data exposed to admin
         };
       }).toList();
       
       debugPrint('✅ Found ${classifications.length} recoverable classifications');
       return classifications;
       
     } catch (e) {
       debugPrint('❌ Error fetching recoverable classifications: $e');
       rethrow;
     }
   }
   ```

2. **Implement recovery request processing**
   ```dart
   static Future<String> createRecoveryRequest({
     required String userEmail,
     required String targetUserId,
     required String reason,
     List<String>? specificClassificationIds,
   }) async {
     await _verifyAdminAccess();
     
     try {
       final requestId = 'recovery_${DateTime.now().millisecondsSinceEpoch}';
       final hashedUserId = _hashUserId(userEmail);
       
       // Create recovery request document
       await _firestore
           .collection('admin_recovery_requests')
           .doc(requestId)
           .set({
         'requestId': requestId,
         'hashedUserId': hashedUserId,
         'targetUserId': targetUserId,
         'adminEmail': _auth.currentUser!.email,
         'reason': reason,
         'specificClassificationIds': specificClassificationIds,
         'status': 'pending',
         'createdAt': FieldValue.serverTimestamp(),
         'estimatedRecoveryTime': DateTime.now().add(Duration(hours: 1)),
       });
       
       debugPrint('✅ Recovery request created: $requestId');
       return requestId;
       
     } catch (e) {
       debugPrint('❌ Error creating recovery request: $e');
       rethrow;
     }
   }
   ```

3. **Implement data restoration to new account**
   ```dart
   static Future<void> restoreDataToAccount({
     required String requestId,
     required String targetUserId,
     required String hashedUserId,
     List<String>? specificClassificationIds,
   }) async {
     await _verifyAdminAccess();
     
     try {
       debugPrint('🔄 Starting data restoration for request: $requestId');
       
       // Get recoverable classifications
       final classifications = await getRecoverableClassifications(hashedUserId);
       
       // Filter to specific IDs if provided
       final classificationsToRestore = specificClassificationIds != null
           ? classifications.where((c) => specificClassificationIds.contains(c['id'])).toList()
           : classifications;
           
       // Restore classifications to new user account
       final batch = _firestore.batch();
       final userClassificationsRef = _firestore
           .collection('users')
           .doc(targetUserId)
           .collection('classifications');
           
       int restoredCount = 0;
       for (final classification in classificationsToRestore) {
         final newClassificationRef = userClassificationsRef.doc();
         batch.set(newClassificationRef, {
           ...classification,
           'id': newClassificationRef.id,
           'restoredAt': FieldValue.serverTimestamp(),
           'restoredBy': 'admin_recovery',
           'originalId': classification['id'],
         });
         restoredCount++;
       }
       
       // Update user's gamification data based on restored classifications
       final userRef = _firestore.collection('users').doc(targetUserId);
       batch.update(userRef, {
         'totalClassifications': FieldValue.increment(restoredCount),
         'restoredData': true,
         'dataRestoredAt': FieldValue.serverTimestamp(),
         'dataRestoredCount': restoredCount,
       });
       
       // Update recovery request status
       final requestRef = _firestore.collection('admin_recovery_requests').doc(requestId);
       batch.update(requestRef, {
         'status': 'completed',
         'completedAt': FieldValue.serverTimestamp(),
         'restoredClassificationCount': restoredCount,
       });
       
       // Execute batch
       await batch.commit();
       
       debugPrint('✅ Data restoration completed: $restoredCount classifications restored');
       
     } catch (e) {
       debugPrint('❌ Error during data restoration: $e');
       
       // Update request status to failed
       await _firestore
           .collection('admin_recovery_requests')
           .doc(requestId)
           .update({
         'status': 'failed',
         'failedAt': FieldValue.serverTimestamp(),
         'errorMessage': e.toString(),
       });
       
       rethrow;
     }
   }
   ```

### **Task 3.3: Implement Recovery Request Management**

#### **File: `lib/core/services/admin_data_recovery_service.dart`**

**Action Items:**
1. **Implement recovery request tracking**
   ```dart
   static Future<List<RecoveryRequest>> getPendingRecoveryRequests() async {
     await _verifyAdminAccess();
     
     try {
       final querySnapshot = await _firestore
           .collection('admin_recovery_requests')
           .where('status', isEqualTo: 'pending')
           .orderBy('createdAt', descending: true)
           .get();
           
       return querySnapshot.docs
           .map((doc) => RecoveryRequest.fromDocument(doc))
           .toList();
           
     } catch (e) {
       debugPrint('❌ Error fetching pending requests: $e');
       rethrow;
     }
   }
   
   static Future<List<RecoveryRequest>> getAllRecoveryRequests({
     int limit = 50,
   }) async {
     await _verifyAdminAccess();
     
     try {
       final querySnapshot = await _firestore
           .collection('admin_recovery_requests')
           .orderBy('createdAt', descending: true)
           .limit(limit)
           .get();
           
       return querySnapshot.docs
           .map((doc) => RecoveryRequest.fromDocument(doc))
           .toList();
           
     } catch (e) {
       debugPrint('❌ Error fetching recovery requests: $e');
       rethrow;
     }
   }
   ```

2. **Create RecoveryRequest model**
   ```dart
   class RecoveryRequest {
     final String requestId;
     final String hashedUserId;
     final String targetUserId;
     final String adminEmail;
     final String reason;
     final List<String>? specificClassificationIds;
     final String status; // pending, completed, failed, cancelled
     final DateTime createdAt;
     final DateTime? completedAt;
     final DateTime? failedAt;
     final int? restoredClassificationCount;
     final String? errorMessage;
     
     RecoveryRequest({
       required this.requestId,
       required this.hashedUserId,
       required this.targetUserId,
       required this.adminEmail,
       required this.reason,
       this.specificClassificationIds,
       required this.status,
       required this.createdAt,
       this.completedAt,
       this.failedAt,
       this.restoredClassificationCount,
       this.errorMessage,
     });
     
     factory RecoveryRequest.fromDocument(DocumentSnapshot doc) {
       final data = doc.data() as Map<String, dynamic>;
       return RecoveryRequest(
         requestId: data['requestId'],
         hashedUserId: data['hashedUserId'],
         targetUserId: data['targetUserId'],
         adminEmail: data['adminEmail'],
         reason: data['reason'],
         specificClassificationIds: data['specificClassificationIds']?.cast<String>(),
         status: data['status'],
         createdAt: (data['createdAt'] as Timestamp).toDate(),
         completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
         failedAt: (data['failedAt'] as Timestamp?)?.toDate(),
         restoredClassificationCount: data['restoredClassificationCount'],
         errorMessage: data['errorMessage'],
       );
     }
   }
   ```

3. **Implement user notification system**
   ```dart
   static Future<void> notifyUserOfRecoveryCompletion({
     required String targetUserId,
     required int restoredCount,
     required String requestId,
   }) async {
     try {
       // Create in-app notification for user
       await _firestore
           .collection('users')
           .doc(targetUserId)
           .collection('notifications')
           .add({
         'type': 'data_recovery_completed',
         'title': 'Data Recovery Completed',
         'message': 'Your data has been successfully restored. '
                   '$restoredCount classifications were recovered.',
         'requestId': requestId,
         'createdAt': FieldValue.serverTimestamp(),
         'read': false,
         'actionRequired': false,
       });
       
       debugPrint('✅ User notified of recovery completion');
       
     } catch (e) {
       debugPrint('⚠️ Warning: Failed to notify user of recovery: $e');
     }
   }
   ```

### **Task 3.4: Implement Recovery Analytics and Monitoring**

#### **File: `lib/core/services/admin_data_recovery_service.dart`**

**Action Items:**
1. **Implement recovery analytics**
   ```dart
   static Future<RecoveryAnalytics> getRecoveryAnalytics({
     DateTime? startDate,
     DateTime? endDate,
   }) async {
     await _verifyAdminAccess();
     
     try {
       final start = startDate ?? DateTime.now().subtract(Duration(days: 30));
       final end = endDate ?? DateTime.now();
       
       // Get recovery requests in date range
       final requestsQuery = await _firestore
           .collection('admin_recovery_requests')
           .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
           .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
           .get();
           
       final requests = requestsQuery.docs
           .map((doc) => RecoveryRequest.fromDocument(doc))
           .toList();
           
       // Calculate analytics
       final analytics = RecoveryAnalytics(
         totalRequests: requests.length,
         completedRequests: requests.where((r) => r.status == 'completed').length,
         failedRequests: requests.where((r) => r.status == 'failed').length,
         pendingRequests: requests.where((r) => r.status == 'pending').length,
         totalClassificationsRestored: requests
             .where((r) => r.restoredClassificationCount != null)
             .fold(0, (sum, r) => sum + r.restoredClassificationCount!),
         averageRestorationTime: _calculateAverageRestorationTime(
           requests.where((r) => r.status == 'completed').toList()
         ),
         startDate: start,
         endDate: end,
       );
       
       return analytics;
       
     } catch (e) {
       debugPrint('❌ Error generating recovery analytics: $e');
       rethrow;
     }
   }
   
   static Duration? _calculateAverageRestorationTime(List<RecoveryRequest> completedRequests) {
     if (completedRequests.isEmpty) return null;
     
     final totalMinutes = completedRequests
         .where((r) => r.completedAt != null)
         .map((r) => r.completedAt!.difference(r.createdAt).inMinutes)
         .reduce((a, b) => a + b);
         
     return Duration(minutes: totalMinutes ~/ completedRequests.length);
   }
   ```

2. **Create RecoveryAnalytics model**
   ```dart
   class RecoveryAnalytics {
     final int totalRequests;
     final int completedRequests;
     final int failedRequests;
     final int pendingRequests;
     final int totalClassificationsRestored;
     final Duration? averageRestorationTime;
     final DateTime startDate;
     final DateTime endDate;
     
     RecoveryAnalytics({
       required this.totalRequests,
       required this.completedRequests,
       required this.failedRequests,
       required this.pendingRequests,
       required this.totalClassificationsRestored,
       this.averageRestorationTime,
       required this.startDate,
       required this.endDate,
     });
     
     double get successRate => 
         totalRequests > 0 ? completedRequests / totalRequests : 0.0;
         
     double get failureRate => 
         totalRequests > 0 ? failedRequests / totalRequests : 0.0;
   }
   ```

3. **Implement proactive recovery monitoring**
   ```dart
   static Future<List<UserRecoveryInfo>> detectUsersNeedingRecovery() async {
     await _verifyAdminAccess();
     
     try {
       // Find users who may have lost data
       final cutoffDate = DateTime.now().subtract(Duration(days: 7));
       
       final recoveryDocsQuery = await _firestore
           .collection('admin_user_recovery')
           .where('accountDeleted', isEqualTo: true)
           .where('deletionTimestamp', isGreaterThan: Timestamp.fromDate(cutoffDate))
           .get();
           
       final usersNeedingRecovery = <UserRecoveryInfo>[];
       
       for (final doc in recoveryDocsQuery.docs) {
         final recoveryInfo = UserRecoveryInfo.fromMap(doc.id, doc.data());
         
         // Check if user has contacted support or shown signs of wanting recovery
         if (recoveryInfo.classificationCount > 10 && // Had significant data
             recoveryInfo.deletionTimestamp != null &&
             DateTime.now().difference(recoveryInfo.deletionTimestamp!) < Duration(days: 30)) {
           usersNeedingRecovery.add(recoveryInfo);
         }
       }
       
       debugPrint('✅ Found ${usersNeedingRecovery.length} users potentially needing recovery');
       return usersNeedingRecovery;
       
     } catch (e) {
       debugPrint('❌ Error detecting users needing recovery: $e');
       rethrow;
     }
   }
   ```

### **Task 3.5: Add Audit Logging and Compliance**

#### **File: `lib/core/services/admin_data_recovery_service.dart`**

**Action Items:**
1. **Implement comprehensive audit logging**
   ```dart
   static Future<void> _logAdminAction({
     required String action,
     required Map<String, dynamic> details,
     String? hashedUserId,
   }) async {
     try {
       final adminUser = _auth.currentUser!;
       
       await _firestore
           .collection('admin_audit_logs')
           .add({
         'action': action,
         'adminEmail': adminUser.email,
         'adminUserId': adminUser.uid,
         'hashedUserId': hashedUserId,
         'details': details,
         'timestamp': FieldValue.serverTimestamp(),
         'appVersion': (await PackageInfo.fromPlatform()).version,
         'ipAddress': await _getAdminIPAddress(), // Implement if needed
       });
       
       debugPrint('✅ Admin action logged: $action');
       
     } catch (e) {
       debugPrint('⚠️ Warning: Failed to log admin action: $e');
     }
   }
   
   // Usage in other methods:
   // await _logAdminAction(
   //   action: 'user_lookup',
   //   details: {'userEmail': 'hashed_value', 'found': true},
   //   hashedUserId: hashedUserId,
   // );
   ```

2. **Implement privacy compliance verification**
   ```dart
   static Future<bool> verifyPrivacyCompliance(String hashedUserId) async {
     await _verifyAdminAccess();
     
     try {
       // Check that admin can only see anonymized data
       final classifications = await getRecoverableClassifications(hashedUserId);
       
       for (final classification in classifications) {
         // Verify no personal data is exposed
         if (_containsPersonalData(classification)) {
           debugPrint('❌ Privacy violation detected in classification data');
           return false;
         }
       }
       
       debugPrint('✅ Privacy compliance verified');
       return true;
       
     } catch (e) {
       debugPrint('❌ Error verifying privacy compliance: $e');
       return false;
     }
   }
   
   static bool _containsPersonalData(Map<String, dynamic> data) {
     final personalDataPatterns = [
       RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), // Email
       RegExp(r'\b\d{10}\b'), // Phone numbers
       RegExp(r'\b[A-Z][a-z]+ [A-Z][a-z]+\b'), // Full names
     ];
     
     for (final value in data.values) {
       if (value is String) {
         for (final pattern in personalDataPatterns) {
           if (pattern.hasMatch(value)) {
             return true;
           }
         }
       }
     }
     return false;
   }
   ```

### **Task 3.6: Create Recovery Exception Classes**

#### **File: `lib/core/exceptions/admin_recovery_exceptions.dart`**

**Action Items:**
1. **Create custom exception classes**
   ```dart
   class AdminAccessException implements Exception {
     final String message;
     AdminAccessException(this.message);
     
     @override
     String toString() => 'AdminAccessException: $message';
   }
   
   class UserNotFoundForRecoveryException implements Exception {
     final String userIdentifier;
     UserNotFoundForRecoveryException(this.userIdentifier);
     
     @override
     String toString() => 'UserNotFoundForRecoveryException: User $userIdentifier not found';
   }
   
   class DataRecoveryException implements Exception {
     final String message;
     final String? requestId;
     DataRecoveryException(this.message, {this.requestId});
     
     @override
     String toString() => 'DataRecoveryException: $message${requestId != null ? ' (Request: $requestId)' : ''}';
   }
   
   class PrivacyComplianceException implements Exception {
     final String message;
     PrivacyComplianceException(this.message);
     
     @override
     String toString() => 'PrivacyComplianceException: $message';
   }
   ```

### **Task 3.7: Update Firebase Security Rules**

#### **File: `firestore.rules`**

**Action Items:**
1. **Add security rules for recovery collections**
   ```javascript
   // Add to existing firestore.rules
   
   // Admin recovery requests - admin only
   match /admin_recovery_requests/{document} {
     allow read, write: if request.auth != null && 
       request.auth.token.email == 'pranaysuyash@gmail.com';
   }
   
   // User notifications - user and admin access
   match /users/{userId}/notifications/{notificationId} {
     allow read, write: if request.auth != null && 
       (request.auth.uid == userId || 
        request.auth.token.email == 'pranaysuyash@gmail.com');
   }
   ```

## 🔍 **VERIFICATION CHECKLIST**

### **Functional Verification:**
- [ ] Admin can lookup users using email without seeing personal data
- [ ] Recovery requests are created and tracked properly
- [ ] Data restoration works with proper user correlation
- [ ] User notifications are sent on recovery completion
- [ ] Recovery analytics provide meaningful insights

### **Privacy Verification:**
- [ ] Admin never sees personal user data during lookup
- [ ] All user correlation uses hashed identifiers only
- [ ] Classification data shown to admin contains no personal info
- [ ] Audit logs track all admin actions comprehensively

### **Security Verification:**
- [ ] Only verified admin email can access recovery functions
- [ ] All admin actions are logged with full details
- [ ] Privacy compliance verification catches any data leaks
- [ ] Recovery operations are secure and tamper-proof

## 🚨 **CRITICAL SUCCESS FACTORS**

1. **Privacy Protection**: Admin must never see personal user data
2. **Secure Authentication**: Only verified admin can access recovery functions
3. **Complete Audit Trail**: Every admin action must be logged
4. **Data Integrity**: Recovered data must match original classifications exactly

## 📈 **SUCCESS METRICS**

- **Recovery Success Rate**: >95% of recovery requests completed successfully
- **Privacy Compliance**: 0 personal data exposures to admin
- **Response Time**: <30 minutes average for recovery request processing
- **Audit Coverage**: 100% of admin actions logged

## 🔄 **NEXT STEPS**
After completing this step:
1. Move to Step 4: Enable Guest User ML Data Collection
2. Test admin recovery workflows thoroughly
3. Verify privacy protection in all scenarios
4. Train admin users on new recovery tools

## 💡 **NOTES FOR AI AGENTS**

- **Privacy Critical**: Admin must NEVER see personal user data
- **Security First**: Verify admin access for every operation
- **Audit Everything**: Log all admin actions for compliance
- **User-Centric**: Recovery should be seamless for users
- **Error Handling**: Graceful failure with proper logging
- **Testing Essential**: Test all privacy scenarios thoroughly
