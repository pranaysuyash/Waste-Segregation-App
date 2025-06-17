# Step 2: Enhanced FirebaseCleanupService with ML Data Preservation

## 🎯 **OBJECTIVE**
Enhance the existing `FirebaseCleanupService` to preserve ML training data during all deletion operations while implementing GDPR-compliant account deletion that respects user privacy rights.

## 📋 **PREREQUISITES**
- ✅ Step 1 completed: ML Training Data Collection Service implemented
- ✅ Existing `FirebaseCleanupService` with `clearAllDataForFreshInstall()` and `adminDeleteUser()`
- ✅ ML training data being collected in `admin_classifications` and `admin_user_recovery`
- ✅ `FreshStartService` integration exists

## 🏗️ **IMPLEMENTATION TASKS**

### **Task 2.1: Enhance Existing clearAllDataForFreshInstall Method**

#### **File: `lib/core/services/firebase_cleanup_service.dart`**

**Action Items:**
1. **Add ML data preservation to existing method**
   ```dart
   // Modify existing clearAllDataForFreshInstall method
   static Future<void> clearAllDataForFreshInstall({bool preserveMLData = true}) async {
     final user = FirebaseAuth.instance.currentUser;
     if (user == null) {
       debugPrint('No user signed in, performing local cleanup only');
       await _clearLocalDataOnly();
       return;
     }

     try {
       debugPrint('🔄 Starting Ultimate Factory Reset with ML preservation: $preserveMLData');
       
       // NEW: Preserve ML training data before deletion (if enabled)
       if (preserveMLData) {
         await _preserveMLTrainingDataBeforeReset(user.uid);
       }
       
       // Existing deletion logic (keep unchanged)
       await _wipeCloudAndFirestoreCache(user.uid);
       await _signOutAndClearLocal();
       await _initializeFreshUser();
       
       debugPrint('✅ Ultimate Factory Reset completed with ML preservation');
     } catch (e) {
       debugPrint('❌ Error during factory reset: $e');
       rethrow;
     }
   }
   ```

2. **Implement ML data preservation method**
   ```dart
   static Future<void> _preserveMLTrainingDataBeforeReset(String userId) async {
     try {
       final hashedUserId = MLTrainingDataService._hashUserId(userId);
       
       // Update recovery metadata with reset timestamp
       await FirebaseFirestore.instance
           .collection('admin_user_recovery')
           .doc(hashedUserId)
           .set({
         'lastBackup': FieldValue.serverTimestamp(),
         'resetTimestamp': FieldValue.serverTimestamp(),
         'resetType': 'factory_reset',
         'dataPreserved': true,
         'appVersion': (await PackageInfo.fromPlatform()).version,
       }, SetOptions(merge: true));
       
       debugPrint('✅ ML training data preserved before reset');
     } catch (e) {
       debugPrint('⚠️ Warning: Could not preserve ML data before reset: $e');
       // Don't throw - reset should continue even if ML preservation fails
     }
   }
   ```

3. **Add user notification about ML preservation**
   ```dart
   static Future<void> _showMLPreservationNotice() async {
     // Add this to be called from UI before reset
     return showDialog(
       context: context, // TODO: Pass context from UI
       builder: (context) => AlertDialog(
         title: Text('Data Reset'),
         content: Text(
           'Your personal data will be cleared, but anonymous usage data '
           'will be preserved to help improve the app for everyone. '
           'No personal information is included in this data.'
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context, false),
             child: Text('Cancel'),
           ),
           TextButton(
             onPressed: () => Navigator.pop(context, true),
             child: Text('Continue'),
           ),
         ],
       ),
     );
   }
   ```

### **Task 2.2: Enhance Existing adminDeleteUser Method**

#### **File: `lib/core/services/firebase_cleanup_service.dart`**

**Action Items:**
1. **Update existing admin deletion to preserve ML data**
   ```dart
   // Enhance existing adminDeleteUser method
   static Future<void> adminDeleteUser(String userIdToDelete, {
     bool preserveMLData = true,
     String reason = 'Admin deletion',
   }) async {
     await _verifyCurrentUserIsAdmin();
     
     debugPrint('🔥 [ADMIN] Deleting user data: $userIdToDelete (ML preservation: $preserveMLData)');
     
     try {
       // NEW: Create deletion audit log
       await _createDeletionAuditLog(userIdToDelete, reason, preserveMLData);
       
       // NEW: Preserve ML data if requested
       if (preserveMLData) {
         await _preserveMLDataBeforeAdminDeletion(userIdToDelete);
       }
       
       // Existing deletion logic (keep unchanged)
       await _wipeCloudAndFirestoreCache(userIdToDelete);
       
       // NEW: Update ML metadata to reflect deletion
       if (preserveMLData) {
         await _updateMLMetadataAfterDeletion(userIdToDelete);
       }
       
       debugPrint('✅ [ADMIN] User deletion completed');
     } catch (e) {
       debugPrint('❌ [ADMIN] Error deleting user: $e');
       throw Exception('Failed to delete user data. Error: $e');
     }
   }
   ```

2. **Implement ML data preservation before admin deletion**
   ```dart
   static Future<void> _preserveMLDataBeforeAdminDeletion(String userId) async {
     try {
       final hashedUserId = MLTrainingDataService._hashUserId(userId);
       
       // Mark data as preserved in recovery metadata
       await FirebaseFirestore.instance
           .collection('admin_user_recovery')
           .doc(hashedUserId)
           .set({
         'deletionTimestamp': FieldValue.serverTimestamp(),
         'deletionType': 'admin_deletion',
         'dataPreserved': true,
         'personalDataDeleted': true,
         'mlDataPreserved': true,
       }, SetOptions(merge: true));
       
       debugPrint('✅ [ADMIN] ML data preservation logged');
     } catch (e) {
       debugPrint('⚠️ [ADMIN] Warning: ML preservation logging failed: $e');
     }
   }
   ```

3. **Implement deletion audit logging**
   ```dart
   static Future<void> _createDeletionAuditLog(
     String userId, 
     String reason, 
     bool preserveMLData
   ) async {
     try {
       final adminUser = FirebaseAuth.instance.currentUser!;
       
       await FirebaseFirestore.instance
           .collection('admin_audit_logs')
           .add({
         'action': 'user_deletion',
         'targetUserId': userId, // Only for admin logs, not accessible to user
         'adminUserId': adminUser.uid,
         'adminEmail': adminUser.email,
         'reason': reason,
         'mlDataPreserved': preserveMLData,
         'timestamp': FieldValue.serverTimestamp(),
         'appVersion': (await PackageInfo.fromPlatform()).version,
       });
       
       debugPrint('✅ [ADMIN] Deletion audit log created');
     } catch (e) {
       debugPrint('⚠️ [ADMIN] Warning: Audit log creation failed: $e');
     }
   }
   ```

### **Task 2.3: Implement Complete Account Deletion Flow**

#### **File: `lib/core/services/firebase_cleanup_service.dart`**

**Action Items:**
1. **Create new GDPR-compliant account deletion method**
   ```dart
   static Future<void> deleteAccountPermanently({
     bool preserveMLData = true,
     bool enable30DayRecovery = true,
   }) async {
     final user = FirebaseAuth.instance.currentUser;
     if (user == null) {
       throw Exception('No user signed in');
     }

     try {
       debugPrint('🗑️ Starting permanent account deletion for: ${user.uid}');
       
       // Step 1: Create account deletion archive (30-day recovery)
       if (enable30DayRecovery) {
         await _createAccountDeletionArchive(user.uid);
       }
       
       // Step 2: Preserve ML training data
       if (preserveMLData) {
         await _preserveMLDataForAccountDeletion(user.uid);
       }
       
       // Step 3: Delete personal data completely
       await _deletePersonalDataCompletely(user.uid);
       
       // Step 4: Update ML metadata
       if (preserveMLData) {
         await _updateMLMetadataForAccountDeletion(user.uid);
       }
       
       // Step 5: Delete authentication account
       await user.delete();
       
       // Step 6: Clear local data
       await _clearLocalDataCompletely();
       
       debugPrint('✅ Account deletion completed');
     } catch (e) {
       debugPrint('❌ Error during account deletion: $e');
       rethrow;
     }
   }
   ```

2. **Implement 30-day recovery archive creation**
   ```dart
   static Future<void> _createAccountDeletionArchive(String userId) async {
     try {
       final timestamp = DateTime.now().toIso8601String().replaceAll(':', '_');
       final archiveId = 'deletion_archive_${timestamp}_$userId';
       
       // Archive user data for 30-day recovery
       final userDoc = await FirebaseFirestore.instance
           .collection('users')
           .doc(userId)
           .get();
           
       if (userDoc.exists) {
         await FirebaseFirestore.instance
             .collection('deletion_archives')
             .doc(archiveId)
             .set({
           'originalUserId': userId,
           'userData': userDoc.data(),
           'createdAt': FieldValue.serverTimestamp(),
           'expiresAt': Timestamp.fromDate(
             DateTime.now().add(Duration(days: 30))
           ),
           'recoveryPossible': true,
           'archiveType': 'account_deletion',
         });
         
         debugPrint('✅ 30-day recovery archive created: $archiveId');
       }
     } catch (e) {
       debugPrint('⚠️ Warning: Recovery archive creation failed: $e');
     }
   }
   ```

3. **Implement complete personal data deletion**
   ```dart
   static Future<void> _deletePersonalDataCompletely(String userId) async {
     final batch = FirebaseFirestore.instance.batch();
     
     try {
       // Delete user profile
       final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
       batch.delete(userRef);
       
       // Delete user's personal classifications
       final classificationsQuery = await FirebaseFirestore.instance
           .collection('users')
           .doc(userId)
           .collection('classifications')
           .get();
           
       for (final doc in classificationsQuery.docs) {
         batch.delete(doc.reference);
       }
       
       // Delete user's achievements and gamification data
       final achievementsQuery = await FirebaseFirestore.instance
           .collection('users')
           .doc(userId)
           .collection('achievements')
           .get();
           
       for (final doc in achievementsQuery.docs) {
         batch.delete(doc.reference);
       }
       
       // Execute batch deletion
       await batch.commit();
       
       debugPrint('✅ Personal data deleted completely');
     } catch (e) {
       debugPrint('❌ Error deleting personal data: $e');
       rethrow;
     }
   }
   ```

4. **Implement ML metadata update for account deletion**
   ```dart
   static Future<void> _updateMLMetadataForAccountDeletion(String userId) async {
     try {
       final hashedUserId = MLTrainingDataService._hashUserId(userId);
       
       await FirebaseFirestore.instance
           .collection('admin_user_recovery')
           .doc(hashedUserId)
           .set({
         'accountDeleted': true,
         'deletionTimestamp': FieldValue.serverTimestamp(),
         'deletionType': 'user_requested',
         'personalDataDeleted': true,
         'mlDataPreserved': true,
         'gdprCompliant': true,
         'recoveryWindowDays': 30,
       }, SetOptions(merge: true));
       
       debugPrint('✅ ML metadata updated for account deletion');
     } catch (e) {
       debugPrint('⚠️ Warning: ML metadata update failed: $e');
     }
   }
   ```

### **Task 2.4: Add Enhanced Reset Options**

#### **File: `lib/core/services/firebase_cleanup_service.dart`**

**Action Items:**
1. **Create multiple reset type options**
   ```dart
   enum ResetType {
     archiveAndFreshStart,  // Safe - creates archive first
     localResetOnly,        // Quick - clears local only
     completeAccountReset,  // Nuclear - deletes account
     temporaryCleanSlate,   // Testing - 24hr temporary
   }
   
   static Future<void> performReset(
     ResetType resetType, {
     bool preserveMLData = true,
     String? customArchiveName,
   }) async {
     switch (resetType) {
       case ResetType.archiveAndFreshStart:
         await _archiveAndFreshStart(preserveMLData, customArchiveName);
         break;
       case ResetType.localResetOnly:
         await _localResetOnly(preserveMLData);
         break;
       case ResetType.completeAccountReset:
         await deleteAccountPermanently(preserveMLData: preserveMLData);
         break;
       case ResetType.temporaryCleanSlate:
         await _temporaryCleanSlate();
         break;
     }
   }
   ```

2. **Implement archive and fresh start option**
   ```dart
   static Future<void> _archiveAndFreshStart(
     bool preserveMLData, 
     String? customName
   ) async {
     final user = FirebaseAuth.instance.currentUser!;
     
     try {
       // Create user-requested archive
       final archiveId = await _createUserArchive(user.uid, customName);
       
       // Preserve ML data
       if (preserveMLData) {
         await _preserveMLTrainingDataBeforeReset(user.uid);
       }
       
       // Perform fresh start
       await clearAllDataForFreshInstall(preserveMLData: preserveMLData);
       
       // Return archive ID to user
       debugPrint('✅ Archive created: $archiveId');
     } catch (e) {
       debugPrint('❌ Error in archive and fresh start: $e');
       rethrow;
     }
   }
   ```

3. **Implement temporary clean slate for testing**
   ```dart
   static Future<void> _temporaryCleanSlate() async {
     final user = FirebaseAuth.instance.currentUser!;
     
     try {
       // Create temporary data hiding
       await FirebaseFirestore.instance
           .collection('temporary_cleanslates')
           .doc(user.uid)
           .set({
         'originalData': await _exportUserData(user.uid),
         'createdAt': FieldValue.serverTimestamp(),
         'restoreAt': Timestamp.fromDate(
           DateTime.now().add(Duration(hours: 24))
         ),
         'active': true,
       });
       
       // Hide user data temporarily (don't delete)
       await _hideUserDataTemporarily(user.uid);
       
       debugPrint('✅ Temporary clean slate activated (24hr restore)');
     } catch (e) {
       debugPrint('❌ Error creating temporary clean slate: $e');
       rethrow;
     }
   }
   ```

### **Task 2.5: Update Firebase Security Rules**

#### **File: `firestore.rules`**

**Action Items:**
1. **Add security rules for new collections**
   ```javascript
   // Add to existing firestore.rules
   
   // Admin audit logs - admin only
   match /admin_audit_logs/{document} {
     allow read, write: if request.auth != null && 
       request.auth.token.email == 'pranaysuyash@gmail.com';
   }
   
   // Deletion archives - admin only
   match /deletion_archives/{document} {
     allow read, write: if request.auth != null && 
       request.auth.token.email == 'pranaysuyash@gmail.com';
   }
   
   // Temporary clean slates - user and admin
   match /temporary_cleanslates/{userId} {
     allow read, write: if request.auth != null && 
       (request.auth.uid == userId || 
        request.auth.token.email == 'pranaysuyash@gmail.com');
   }
   ```

### **Task 2.6: Create User Interface Integration Points**

#### **File: `lib/features/settings/screens/data_management_screen.dart`**

**Action Items:**
1. **Create data management screen**
   ```dart
   class DataManagementScreen extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: Text('Data Management')),
         body: ListView(
           children: [
             _buildResetOption(
               'Archive & Fresh Start',
               'Creates backup before clearing',
               () => _showArchiveDialog(context),
             ),
             _buildResetOption(
               'Local Reset Only',
               'Clears device, keeps cloud data',
               () => _performLocalReset(context),
             ),
             _buildResetOption(
               'Complete Account Reset',
               'Permanently deletes account',
               () => _showAccountDeletionDialog(context),
             ),
             _buildResetOption(
               'Temporary Clean Slate',
               '24-hour test mode',
               () => _performTemporaryReset(context),
             ),
           ],
         ),
       );
     }
   }
   ```

2. **Add confirmation dialogs with ML transparency**
   ```dart
   Future<void> _showAccountDeletionDialog(BuildContext context) async {
     return showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text('Delete Account'),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Text('This will permanently delete your account and personal data.'),
             SizedBox(height: 16),
             Text(
               'Anonymous usage data will be preserved to help improve '
               'the app for everyone. No personal information is included.',
               style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: Text('Cancel'),
           ),
           TextButton(
             onPressed: () => _performAccountDeletion(context),
             child: Text('Delete Account', style: TextStyle(color: Colors.red)),
           ),
         ],
       ),
     );
   }
   ```

## 🔍 **VERIFICATION CHECKLIST**

### **Functional Verification:**
- [ ] Existing reset functionality works unchanged
- [ ] ML training data is preserved during all deletion types
- [ ] Account deletion creates 30-day recovery archive
- [ ] Admin deletion preserves ML data with audit logging
- [ ] New reset options work correctly

### **Privacy Verification:**
- [ ] Personal data is completely removed during account deletion
- [ ] ML training data contains no personal identifiers
- [ ] Audit logs are only accessible to admins
- [ ] User receives clear information about ML data preservation

### **GDPR Compliance Verification:**
- [ ] Right to erasure is properly implemented
- [ ] Legitimate interest for ML data is documented
- [ ] User consent for ML data is clear
- [ ] Recovery window respects user rights

## 🚨 **CRITICAL SUCCESS FACTORS**

1. **Preserve Existing Behavior**: All current reset functionality must work as before
2. **ML Data Continuity**: ML training data must survive all deletion operations
3. **Privacy Compliance**: Zero personal data in preserved ML collections
4. **User Transparency**: Clear communication about what data is preserved

## 📈 **SUCCESS METRICS**

- **Deletion Success Rate**: 100% of deletion operations complete successfully
- **ML Data Preservation**: 100% of ML training data preserved during deletions
- **Privacy Compliance**: 0 personal identifiers found in preserved data
- **User Satisfaction**: >80% user understanding of deletion process

## 🔄 **NEXT STEPS**
After completing this step:
1. Move to Step 3: Privacy-Preserving Admin Recovery Service
2. Test all deletion scenarios thoroughly
3. Verify ML data preservation in Firebase console
4. Validate GDPR compliance with legal review

## 💡 **NOTES FOR AI AGENTS**

- **Zero Breaking Changes**: Existing functionality must work exactly as before
- **ML Preservation Critical**: Every deletion must preserve ML training data
- **Privacy First**: Personal data deletion must be complete and irreversible
- **User Communication**: Always inform users about ML data preservation
- **Testing Essential**: Test all deletion paths with both guest and signed-in users
