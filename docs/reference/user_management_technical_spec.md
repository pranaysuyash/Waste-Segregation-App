# Technical Specification: Multi-User Family System

## Document Purpose

This technical specification outlines the implementation details for adding family/team functionality to the Waste Segregation App. It provides technical guidance for developers implementing the features described in the `user_management_enhancements.md` document.

## System Architecture

### 1. Data Models

#### 1.1 Core Models

The following data models will be implemented:

```
UserProfile
  ├── id: String
  ├── displayName: String
  ├── email: String
  ├── photoUrl: String?
  ├── phoneNumber: String?
  ├── preferences: Map<String, dynamic>
  ├── createdAt: DateTime
  ├── lastActive: DateTime
  ├── familyId: String?
  └── role: UserRole

Family
  ├── id: String
  ├── name: String
  ├── photoUrl: String?
  ├── createdBy: String (userId)
  ├── createdAt: DateTime
  ├── members: List<FamilyMember>
  └── settings: Map<String, dynamic>

FamilyMember
  ├── userId: String
  ├── role: UserRole
  └── joinedAt: DateTime

Invitation
  ├── id: String
  ├── familyId: String
  ├── createdBy: String (userId)
  ├── createdAt: DateTime
  ├── expiresAt: DateTime
  ├── email: String
  ├── role: UserRole
  ├── used: bool
  └── usedAt: DateTime?
```

#### 1.2 Enums

```
enum UserRole {
  admin,   // Can manage family settings and members
  member,  // Regular family member
  child,   // Limited permissions
  guest    // Temporary access
}
```

### 2. Storage Schema

#### 2.1 Hive Box Structure

```
'user_profiles'
  ├── [userId1]: UserProfile (JSON)
  ├── [userId2]: UserProfile (JSON)
  └── ...

'families'
  ├── [familyId1]: Family (JSON)
  ├── [familyId2]: Family (JSON)
  └── ...

'invitations'
  ├── [invitationId1]: Invitation (JSON)
  ├── [invitationId2]: Invitation (JSON)
  └── ...

'family_classifications'
  ├── [familyId1]_[timestamp1]: Classification (JSON)
  ├── [familyId1]_[timestamp2]: Classification (JSON)
  └── ...
```

#### 2.2 Firebase Integration (Optional)

If implementing Firebase backend:

```
// Firestore Collections
'users'
  └── [userId]
      ├── profile: { ... }
      └── settings: { ... }

'families'
  └── [familyId]
      ├── name: String
      ├── createdBy: String
      ├── createdAt: Timestamp
      ├── photoUrl: String?
      └── settings: { ... }

'family_members'
  └── [familyId]
      └── [userId]
          ├── role: String
          └── joinedAt: Timestamp

'invitations'
  └── [invitationId]
      ├── familyId: String
      ├── email: String
      ├── ...
      └── used: Boolean
```

### 3. Service Architecture

#### 3.1 Key Services

```
UserService
  ├── Authentication methods (existing)
  ├── Profile management methods
  └── User query methods

FamilyService
  ├── Family CRUD operations
  ├── Member management
  └── Family data aggregation

InvitationService
  ├── Invitation creation
  ├── Invitation validation
  └── Invitation acceptance

SharedStorageService
  ├── Multi-user data access
  ├── Shared classification operations
  └── Permissions enforcement
```

#### 3.2 Service Dependencies

```
FamilyService
  ├── depends on UserService
  └── depends on SharedStorageService

InvitationService
  ├── depends on FamilyService
  └── depends on UserService
```

## Implementation Details

### 1. Database Updates

#### 1.1 Hive Box Modifications

```dart
// Pseudocode for initializing new boxes
await Hive.openBox('user_profiles');
await Hive.openBox('families');
await Hive.openBox('invitations');
await Hive.openBox('family_classifications');
```

#### 1.2 Data Migration

```dart
// Pseudocode for migrating existing user data
Future<void> migrateExistingUserData() async {
  final userBox = Hive.box(StorageKeys.userBox);
  final profileBox = Hive.box('user_profiles');
  
  final userId = userBox.get(StorageKeys.userIdKey);
  if (userId != null && !profileBox.containsKey(userId)) {
    final userProfile = UserProfile(
      id: userId,
      displayName: userBox.get(StorageKeys.userDisplayNameKey) ?? '',
      email: userBox.get(StorageKeys.userEmailKey) ?? '',
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
      // Other fields initialized with defaults
    );
    
    await profileBox.put(userId, jsonEncode(userProfile.toJson()));
  }
}
```

### 2. Authentication Flow

#### 2.1 Sign-In Process

```dart
// Pseudocode for updated sign-in
Future<UserProfile?> signIn() async {
  try {
    // Existing Google sign-in code
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    
    if (account != null) {
      // Check if user profile exists
      final UserProfile? profile = await getUserProfile(account.id);
      
      if (profile != null) {
        // Update last active time
        await updateLastActive(profile.id);
        return profile;
      } else {
        // Create new user profile
        final newProfile = UserProfile(
          id: account.id,
          displayName: account.displayName ?? account.email.split('@').first,
          email: account.email,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );
        
        await saveUserProfile(newProfile);
        return newProfile;
      }
    }
    return null;
  } catch (e) {
    debugPrint('Error signing in: $e');
    rethrow;
  }
}
```

#### 2.2 User Switching

```dart
// Pseudocode for user switching
Future<bool> switchUser(String userId, {String? pin}) async {
  try {
    // Verify user belongs to the current family
    final currentUser = await getCurrentUser();
    if (currentUser == null || currentUser.familyId == null) {
      return false;
    }
    
    final family = await getFamily(currentUser.familyId!);
    final isMember = family.members.any((m) => m.userId == userId);
    
    if (!isMember) {
      return false;
    }
    
    // Verify PIN if required
    if (pin != null) {
      final isValidPin = await verifyUserPin(userId, pin);
      if (!isValidPin) {
        return false;
      }
    }
    
    // Switch active user
    await setActiveUser(userId);
    return true;
  } catch (e) {
    debugPrint('Error switching user: $e');
    return false;
  }
}
```

### 3. Family Management

#### 3.1 Family Creation

```dart
// Pseudocode for family creation
Future<String?> createFamily(String name, String creatorId) async {
  try {
    // Get creator profile
    final creator = await getUserProfile(creatorId);
    if (creator == null) {
      return null;
    }
    
    // Check if user already in a family
    if (creator.familyId != null) {
      return null;
    }
    
    // Create family
    final family = Family(
      id: _generateUniqueId(),
      name: name,
      createdBy: creatorId,
      createdAt: DateTime.now(),
      members: [
        FamilyMember(
          userId: creatorId,
          role: UserRole.admin,
          joinedAt: DateTime.now(),
        ),
      ],
      settings: {},
    );
    
    // Save family
    await saveFamily(family);
    
    // Update creator profile
    final updatedCreator = creator.copyWith(
      familyId: family.id,
      role: UserRole.admin,
    );
    await saveUserProfile(updatedCreator);
    
    return family.id;
  } catch (e) {
    debugPrint('Error creating family: $e');
    return null;
  }
}
```

#### 3.2 Member Management

```dart
// Pseudocode for adding family member
Future<bool> addFamilyMember(String familyId, String userId, UserRole role) async {
  try {
    // Get family
    final family = await getFamily(familyId);
    if (family == null) {
      return false;
    }
    
    // Get user
    final user = await getUserProfile(userId);
    if (user == null) {
      return false;
    }
    
    // Check if user already in the family
    if (family.members.any((m) => m.userId == userId)) {
      return false;
    }
    
    // Add member to family
    final updatedMembers = [...family.members, 
      FamilyMember(
        userId: userId,
        role: role,
        joinedAt: DateTime.now(),
      ),
    ];
    
    final updatedFamily = family.copyWith(members: updatedMembers);
    await saveFamily(updatedFamily);
    
    // Update user profile
    final updatedUser = user.copyWith(
      familyId: familyId,
      role: role,
    );
    await saveUserProfile(updatedUser);
    
    return true;
  } catch (e) {
    debugPrint('Error adding family member: $e');
    return false;
  }
}
```

### 4. Invitation System

#### 4.1 Creating Invitations

```dart
// Pseudocode for creating invitation
Future<String?> createInvitation(String familyId, String email, UserRole role) async {
  try {
    // Get family
    final family = await getFamily(familyId);
    if (family == null) {
      return null;
    }
    
    // Check if invitation already exists
    final existingInvitation = await getInvitationByEmail(familyId, email);
    if (existingInvitation != null && !existingInvitation.used) {
      return existingInvitation.id;
    }
    
    // Create invitation
    final invitation = Invitation(
      id: _generateUniqueId(),
      familyId: familyId,
      createdBy: family.createdBy,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(days: 7)),
      email: email,
      role: role,
      used: false,
    );
    
    // Save invitation
    await saveInvitation(invitation);
    
    // Send invitation email (implementation depends on email service)
    await _sendInvitationEmail(invitation);
    
    return invitation.id;
  } catch (e) {
    debugPrint('Error creating invitation: $e');
    return null;
  }
}
```

#### 4.2 Accepting Invitations

```dart
// Pseudocode for accepting invitation
Future<bool> acceptInvitation(String invitationId, String userId) async {
  try {
    // Get invitation
    final invitation = await getInvitation(invitationId);
    if (invitation == null || invitation.used || DateTime.now().isAfter(invitation.expiresAt)) {
      return false;
    }
    
    // Get user
    final user = await getUserProfile(userId);
    if (user == null) {
      return false;
    }
    
    // Check if user's email matches invitation
    if (user.email.toLowerCase() != invitation.email.toLowerCase()) {
      return false;
    }
    
    // Add user to family
    final success = await addFamilyMember(invitation.familyId, userId, invitation.role);
    if (!success) {
      return false;
    }
    
    // Mark invitation as used
    final updatedInvitation = invitation.copyWith(
      used: true,
      usedAt: DateTime.now(),
    );
    await saveInvitation(updatedInvitation);
    
    return true;
  } catch (e) {
    debugPrint('Error accepting invitation: $e');
    return false;
  }
}
```

### 5. Shared Data Access

#### 5.1 Family Classifications

```dart
// Pseudocode for saving family classification
Future<void> saveFamilyClassification(String familyId, String userId, WasteClassification classification) async {
  try {
    final String key = 'family_${familyId}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Add user information to classification
    final familyClassification = classification.copyWith(
      classifiedBy: userId,
      familyId: familyId,
    );
    
    // Save to family classifications box
    final familyClassificationsBox = Hive.box('family_classifications');
    await familyClassificationsBox.put(key, jsonEncode(familyClassification.toJson()));
    
    // Also save to user's personal classifications
    await saveClassification(classification);
  } catch (e) {
    debugPrint('Error saving family classification: $e');
    rethrow;
  }
}

// Pseudocode for getting family classifications
Future<List<WasteClassification>> getFamilyClassifications(String familyId) async {
  try {
    final familyClassificationsBox = Hive.box('family_classifications');
    final List<WasteClassification> classifications = [];
    
    for (var key in familyClassificationsBox.keys) {
      if (key.toString().startsWith('family_${familyId}_')) {
        final String jsonString = familyClassificationsBox.get(key);
        final Map<String, dynamic> json = jsonDecode(jsonString);
        classifications.add(WasteClassification.fromJson(json));
      }
    }
    
    // Sort by timestamp (newest first)
    classifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return classifications;
  } catch (e) {
    debugPrint('Error getting family classifications: $e');
    return [];
  }
}
```

#### 5.2 Family Dashboard Data

```dart
// Pseudocode for getting family waste statistics
Future<Map<String, dynamic>> getFamilyWasteStatistics(String familyId) async {
  try {
    final familyClassifications = await getFamilyClassifications(familyId);
    
    // Get family members
    final family = await getFamily(familyId);
    if (family == null) {
      return {};
    }
    
    final memberIds = family.members.map((m) => m.userId).toList();
    
    // Calculate statistics
    Map<String, int> categoryCounts = {};
    Map<String, int> userCounts = {};
    Map<String, Map<String, int>> userCategoryCounts = {};
    
    // Initialize member counts
    for (var userId in memberIds) {
      userCounts[userId] = 0;
      userCategoryCounts[userId] = {};
    }
    
    // Process classifications
    for (var classification in familyClassifications) {
      // Count by category
      final category = classification.category;
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      
      // Count by user
      final userId = classification.classifiedBy;
      if (userId != null && memberIds.contains(userId)) {
        userCounts[userId] = (userCounts[userId] ?? 0) + 1;
        
        // Count category by user
        final userCategories = userCategoryCounts[userId] ?? {};
        userCategories[category] = (userCategories[category] ?? 0) + 1;
        userCategoryCounts[userId] = userCategories;
      }
    }
    
    // Calculate environmental impact
    final recyclableCount = familyClassifications.where((c) => c.isRecyclable == true).length;
    final estimatedCO2Saved = recyclableCount * 0.5; // kg of CO2 (simplified calculation)
    
    return {
      'totalItems': familyClassifications.length,
      'categoryCounts': categoryCounts,
      'userCounts': userCounts,
      'userCategoryCounts': userCategoryCounts,
      'recyclableCount': recyclableCount,
      'estimatedCO2Saved': estimatedCO2Saved,
    };
  } catch (e) {
    debugPrint('Error getting family waste statistics: $e');
    return {};
  }
}
```

### 6. UI Component Design

#### 6.1 Family Dashboard

```dart
// Pseudocode for family dashboard screen
class FamilyDashboardScreen extends StatefulWidget {
  final String familyId;
  
  const FamilyDashboardScreen({required this.familyId});
  
  @override
  _FamilyDashboardScreenState createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};
  List<UserProfile> _members = [];
  Family? _family;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load family data
      final family = await _familyService.getFamily(widget.familyId);
      if (family == null) {
        throw Exception('Family not found');
      }
      
      // Load members
      final members = await _userService.getUsersByFamily(widget.familyId);
      
      // Load statistics
      final statistics = await _familyService.getFamilyWasteStatistics(widget.familyId);
      
      setState(() {
        _family = family;
        _members = members;
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      // Show error
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // UI implementation
  }
  
  // Dashboard UI components
  Widget _buildMemberContributions() {
    // ...
  }
  
  Widget _buildCategoryDistribution() {
    // ...
  }
  
  Widget _buildEnvironmentalImpact() {
    // ...
  }
}
```

#### 6.2 Family Management UI

```dart
// Pseudocode for family management screen
class FamilyManagementScreen extends StatefulWidget {
  final String familyId;
  
  const FamilyManagementScreen({required this.familyId});
  
  @override
  _FamilyManagementScreenState createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  bool _isLoading = true;
  Family? _family;
  List<UserProfile> _members = [];
  List<Invitation> _invitations = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    // Load family, members, and invitations
  }
  
  Future<void> _addMember() async {
    // Show dialog to add member
  }
  
  Future<void> _removeMember(String userId) async {
    // Confirm and remove member
  }
  
  Future<void> _updateMemberRole(String userId, UserRole newRole) async {
    // Update member role
  }
  
  @override
  Widget build(BuildContext context) {
    // UI implementation
  }
  
  // UI components
  Widget _buildMembersList() {
    // ...
  }
  
  Widget _buildInvitationsList() {
    // ...
  }
  
  Widget _buildFamilySettings() {
    // ...
  }
}
```

## Testing Strategy

### 1. Unit Tests

```dart
// Pseudocode for FamilyService tests
void main() {
  group('FamilyService Tests', () {
    late FamilyService familyService;
    late MockUserService mockUserService;
    
    setUp(() {
      mockUserService = MockUserService();
      familyService = FamilyService(mockUserService);
    });
    
    test('createFamily should create a new family', () async {
      // Test implementation
    });
    
    test('addFamilyMember should add member to family', () async {
      // Test implementation
    });
    
    // More tests...
  });
}
```

### 2. Integration Tests

```dart
// Pseudocode for family flow integration test
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Family Management Flow Tests', () {
    testWidgets('Create family and invite member flow', (tester) async {
      // Test implementation
    });
    
    testWidgets('Accept invitation flow', (tester) async {
      // Test implementation
    });
    
    // More tests...
  });
}
```

## API Integration Points

### 1. Firebase Integration (Optional)

```dart
// Pseudocode for Firebase family data sync
Future<void> syncFamilyData(String familyId) async {
  try {
    final localFamily = await getLocalFamily(familyId);
    
    // Get Firestore reference
    final familyRef = FirebaseFirestore.instance.collection('families').doc(familyId);
    
    // Get remote data
    final familyDoc = await familyRef.get();
    
    if (familyDoc.exists) {
      // Remote family exists, merge data
      final remoteFamily = Family.fromFirestore(familyDoc.data()!);
      
      // Determine which is newer
      if (remoteFamily.lastUpdated.isAfter(localFamily.lastUpdated)) {
        // Remote is newer, update local
        await saveLocalFamily(remoteFamily);
      } else {
        // Local is newer, update remote
        await familyRef.set(localFamily.toFirestore());
      }
    } else {
      // Remote doesn't exist, create it
      await familyRef.set(localFamily.toFirestore());
    }
    
    // Sync members
    await syncFamilyMembers(familyId);
    
    // Sync invitations
    await syncFamilyInvitations(familyId);
    
    // Sync classifications
    await syncFamilyClassifications(familyId);
  } catch (e) {
    debugPrint('Error syncing family data: $e');
    rethrow;
  }
}
```

## Implementation Approach

1. Use an iterative approach, focusing first on the core family model
2. Implement one feature at a time, with proper testing
3. Add UI components as services are completed
4. Integrate with existing features gradually

## Migration Strategy

1. Create a migration path for existing users
2. Maintain backward compatibility for guest users
3. Provide clear onboarding for new family features

## Deployment Considerations

1. Update the app version for these significant changes
2. Consider a phased rollout
3. Prepare user documentation for the new features

---

This technical specification provides a comprehensive blueprint for implementing the multi-user family system in the Waste Segregation App. It should be used in conjunction with the `user_management_enhancements.md` document to guide the development process.
