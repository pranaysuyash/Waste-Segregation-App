/*
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import '../test_helper.dart';

// Mock classes for testing
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}
class MockStorageService extends Mock implements StorageService {}
class MockBatch extends Mock implements WriteBatch {}

void main() {
  group('CloudStorageService Critical Tests', () {
    late CloudStorageService cloudStorageService;
    late MockStorageService mockLocalStorage;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockUsersCollection;
    late MockDocumentReference mockUserDoc;
    late MockCollectionReference mockClassificationsCollection;
    late MockDocumentReference mockClassificationDoc;
    late WasteClassification testClassification;
    late UserProfile testUserProfile;

    setUpAll(() async {
      await TestHelper.setupCompleteTest();
    });

    tearDownAll(() async {
      await TestHelper.tearDownCompleteTest();
    });

    setUp(() {
      mockLocalStorage = MockStorageService();
      mockFirestore = MockFirebaseFirestore();
      mockUsersCollection = MockCollectionReference();
      mockUserDoc = MockDocumentReference();
      mockClassificationsCollection = MockCollectionReference();
      mockClassificationDoc = MockDocumentReference();

      // Setup basic Firestore mock structure
      when(mockFirestore.collection('users')).thenReturn(mockUsersCollection);
      when(mockUsersCollection.doc(any)).thenReturn(mockUserDoc);
      when(mockUserDoc.collection('classifications')).thenReturn(mockClassificationsCollection);
      when(mockClassificationsCollection.doc(any)).thenReturn(mockClassificationDoc);

      cloudStorageService = CloudStorageService(mockLocalStorage);
      // Note: In real tests, you'd need to inject the mock firestore instance

      // Setup test data
      testClassification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        itemName: 'Test Plastic Bottle',
        subcategory: 'Plastic',
        explanation: 'Test recyclable plastic bottle',
          primaryMethod: 'Recycle in blue bin',
          steps: ['Remove cap', 'Rinse clean'],
          hasUrgentTimeframe: false,
        ),
        timestamp: DateTime.parse('2024-01-15T10:30:00Z'),
        region: 'Test Region',
        visualFeatures: ['plastic', 'bottle'],
        alternatives: [],
        confidence: 0.95,
        userId: 'test_user_123',
      );

      testUserProfile = UserProfile(
        id: 'test_user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        lastActive: DateTime.now(),
        gamificationProfile: GamificationProfile(
          userId: 'test_user_123',
          points: const UserPoints(total: 150),
          streak: Streak(current: 5, longest: 10, lastUsageDate: DateTime.now()),
          achievements: [],
        ),
      );
    });

    group('User Profile Save Tests', () {
      test('should save user profile to Firestore successfully', () async {
        // Mock successful Firestore operations
        when(mockUserDoc.set(any, any)).thenAnswer((_) async {
          return null;
        });
        when(mockLocalStorage.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);

        // Mock leaderboard collection
        final mockLeaderboardCollection = MockCollectionReference();
        final mockLeaderboardDoc = MockDocumentReference();
        when(mockFirestore.collection('leaderboard_allTime')).thenReturn(mockLeaderboardCollection);
        when(mockLeaderboardCollection.doc(any)).thenReturn(mockLeaderboardDoc);
        when(mockLeaderboardDoc.set(any, any)).thenAnswer((_) async {});

        await cloudStorageService.saveUserProfileToFirestore(testUserProfile);

        // Verify profile was saved
        verify(mockUserDoc.set(any, any)).called(1);
      });

      test('should not save user profile with empty ID', () async {
        final emptyIdProfile = testUserProfile.copyWith(id: '');

        await cloudStorageService.saveUserProfileToFirestore(emptyIdProfile);

        // Verify no Firestore operations were called
        verifyNever(mockUserDoc.set(any, any));
      });

      test('should handle Firestore errors gracefully', () async {
        when(mockUserDoc.set(any, any)).thenThrow(Exception('Firestore error'));

        expect(
          () async => await cloudStorageService.saveUserProfileToFirestore(testUserProfile),
          throwsException,
        );
      });

      test('should update leaderboard when profile has gamification data', () async {
        when(mockUserDoc.set(any, any)).thenAnswer((_) async {
          return null;
        });

        // Mock leaderboard operations
        final mockLeaderboardCollection = MockCollectionReference();
        final mockLeaderboardDoc = MockDocumentReference();
        when(mockFirestore.collection('leaderboard_allTime')).thenReturn(mockLeaderboardCollection);
        when(mockLeaderboardCollection.doc(testUserProfile.id)).thenReturn(mockLeaderboardDoc);
        when(mockLeaderboardDoc.set(any, any)).thenAnswer((_) async {});

        await cloudStorageService.saveUserProfileToFirestore(testUserProfile);

        // Verify leaderboard was updated
        verify(mockLeaderboardDoc.set(any, any)).called(1);
      });

      test('should handle leaderboard update failure gracefully', () async {
        when(mockUserDoc.set(any, any)).thenAnswer((_) async {
          return null;
        });

        // Mock leaderboard failure
        final mockLeaderboardCollection = MockCollectionReference();
        final mockLeaderboardDoc = MockDocumentReference();
        when(mockFirestore.collection('leaderboard_allTime')).thenReturn(mockLeaderboardCollection);
        when(mockLeaderboardCollection.doc(any)).thenReturn(mockLeaderboardDoc);
        when(mockLeaderboardDoc.set(any, any)).thenThrow(Exception('Leaderboard error'));

        // Should not throw exception even if leaderboard update fails
        await cloudStorageService.saveUserProfileToFirestore(testUserProfile);

        // Profile save should still succeed
        verify(mockUserDoc.set(any, any)).called(1);
      });
    });

    group('Classification Sync Tests', () {
      test('should save classification with sync enabled', () async {
        when(mockLocalStorage.saveClassification(any)).thenAnswer((_) async {
          return null;
        });
        when(mockLocalStorage.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockClassificationDoc.set(any)).thenAnswer((_) async {
          return null;
        });

        // Mock admin collections
        final mockAdminCollection = MockCollectionReference();
        when(mockFirestore.collection('admin_classifications')).thenReturn(mockAdminCollection);
        when(mockAdminCollection.add(any)).thenAnswer((_) async => mockClassificationDoc);

        final mockRecoveryCollection = MockCollectionReference();
        final mockRecoveryDoc = MockDocumentReference();
        when(mockFirestore.collection('admin_user_recovery')).thenReturn(mockRecoveryCollection);
        when(mockRecoveryCollection.doc(any)).thenReturn(mockRecoveryDoc);
        when(mockRecoveryDoc.set(any, any)).thenAnswer((_) async {});

        await cloudStorageService.saveClassificationWithSync(
          testClassification,
          true, // Google sync enabled
          processGamification: false, // Skip gamification for this test
        );

        // Verify local save was called
        verify(mockLocalStorage.saveClassification(testClassification)).called(1);
        
        // Verify cloud sync was attempted
        verify(mockClassificationDoc.set(any)).called(1);
      });

      test('should save classification locally only when sync disabled', () async {
        when(mockLocalStorage.saveClassification(any)).thenAnswer((_) async {
          return null;
        });

        await cloudStorageService.saveClassificationWithSync(
          testClassification,
          false, // Google sync disabled
          processGamification: false,
        );

        // Verify local save was called
        verify(mockLocalStorage.saveClassification(testClassification)).called(1);
        
        // Verify no cloud operations
        verifyNever(mockClassificationDoc.set(any));
      });

      test('should handle classification sync failure gracefully', () async {
        when(mockLocalStorage.saveClassification(any)).thenAnswer((_) async {
          return null;
        });
        when(mockLocalStorage.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockClassificationDoc.set(any)).thenThrow(Exception('Sync error'));

        // Should not throw exception even if cloud sync fails
        await cloudStorageService.saveClassificationWithSync(
          testClassification,
          true,
          processGamification: false,
        );

        // Local save should still succeed
        verify(mockLocalStorage.saveClassification(testClassification)).called(1);
      });

      test('should not sync when user is not signed in', () async {
        when(mockLocalStorage.saveClassification(any)).thenAnswer((_) async {
          return null;
        });
        when(mockLocalStorage.getCurrentUserProfile()).thenAnswer((_) async => null);

        await cloudStorageService.saveClassificationWithSync(
          testClassification,
          true,
          processGamification: false,
        );

        // Verify local save was called but no cloud operations
        verify(mockLocalStorage.saveClassification(testClassification)).called(1);
        verifyNever(mockClassificationDoc.set(any));
      });
    });

    group('Data Privacy and Admin Collection Tests', () {
      test('should save anonymized data to admin collection', () async {
        when(mockLocalStorage.saveClassification(any)).thenAnswer((_) async {
          return null;
        });
        when(mockLocalStorage.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockClassificationDoc.set(any)).thenAnswer((_) async {
          return null;
        });

        // Mock admin collection
        final mockAdminCollection = MockCollectionReference();
        final mockAdminDoc = MockDocumentReference();
        when(mockFirestore.collection('admin_classifications')).thenReturn(mockAdminCollection);
        when(mockAdminCollection.add(any)).thenAnswer((_) async => mockAdminDoc);

        // Mock recovery collection
        final mockRecoveryCollection = MockCollectionReference();
        final mockRecoveryDoc = MockDocumentReference();
        when(mockFirestore.collection('admin_user_recovery')).thenReturn(mockRecoveryCollection);
        when(mockRecoveryCollection.doc(any)).thenReturn(mockRecoveryDoc);
        when(mockRecoveryDoc.set(any, any)).thenAnswer((_) async {});

        await cloudStorageService.saveClassificationWithSync(
          testClassification,
          true,
          processGamification: false,
        );

        // Verify admin data was saved (anonymized)
        verify(mockAdminCollection.add(any)).called(1);
        
        // Verify recovery metadata was updated
        verify(mockRecoveryDoc.set(any, any)).called(1);
      });

      test('should handle admin collection failure gracefully', () async {
        when(mockLocalStorage.saveClassification(any)).thenAnswer((_) async {
          return null;
        });
        when(mockLocalStorage.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockClassificationDoc.set(any)).thenAnswer((_) async {
          return null;
        });

        // Mock admin collection failure
        final mockAdminCollection = MockCollectionReference();
        when(mockFirestore.collection('admin_classifications')).thenReturn(mockAdminCollection);
        when(mockAdminCollection.add(any)).thenThrow(Exception('Admin collection error'));

        // Should not throw exception even if admin collection fails
        await cloudStorageService.saveClassificationWithSync(
          testClassification,
          true,
          processGamification: false,
        );

        // Main operations should still succeed
        verify(mockLocalStorage.saveClassification(testClassification)).called(1);
        verify(mockClassificationDoc.set(any)).called(1);
      });

      test('should not save to admin collection without user ID', () async {
        final classificationWithoutUserId = testClassification.copyWith(userId: null);
        
        when(mockLocalStorage.saveClassification(any)).thenAnswer((_) async {
          return null;
        });
        when(mockLocalStorage.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockClassificationDoc.set(any)).thenAnswer((_) async {
          return null;
        });

        final mockAdminCollection = MockCollectionReference();
        when(mockFirestore.collection('admin_classifications')).thenReturn(mockAdminCollection);

        await cloudStorageService.saveClassificationWithSync(
          classificationWithoutUserId,
          true,
          processGamification: false,
        );

        // Verify no admin data was saved
        verifyNever(mockAdminCollection.add(any));
      });
    });

    group('Classification Loading and Merging Tests', () {
      test('should return local classifications when sync disabled', () async {
        final localClassifications = [testClassification];
        when(mockLocalStorage.getAllClassifications()).thenAnswer((_) async => localClassifications);

        final result = await cloudStorageService.getAllClassificationsWithCloudSync(false);

        expect(result.length, equals(1));
        expect(result.first.itemName, equals('Test Plastic Bottle'));
        
        // Verify only local storage was accessed
        verify(mockLocalStorage.getAllClassifications()).called(1);
        verifyNever(mockUsersCollection.doc(any));
      });

      test('should return local classifications when user not signed in', () async {
        final localClassifications = [testClassification];
        when(mockLocalStorage.getAllClassifications()).thenAnswer((_) async => localClassifications);
        when(mockLocalStorage.getCurrentUserProfile()).thenAnswer((_) async => null);

        final result = await cloudStorageService.getAllClassificationsWithCloudSync(true);

        expect(result.length, equals(1));
        verify(mockLocalStorage.getAllClassifications()).called(1);
        verifyNever(mockUsersCollection.doc(any));
      });

      test('should merge local and cloud classifications', () async {
        final localClassifications = [testClassification];
        final cloudClassification = testClassification.copyWith(
          itemName: 'Cloud Classification',
          timestamp: DateTime.parse('2024-01-16T10:30:00Z'),
        );

        when(mockLocalStorage.getAllClassifications()).thenAnswer((_) async => localClassifications);
        when(mockLocalStorage.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockLocalStorage.saveClassification(any)).thenAnswer((_) async {
          return null;
        });

        // Mock cloud query
        final mockQuery = MockQuery();
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockDocSnapshot = MockDocumentSnapshot();

        when(mockClassificationsCollection.orderBy('timestamp', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
        when(mockDocSnapshot.data()).thenReturn(cloudClassification.toJson());

        final result = await cloudStorageService.getAllClassificationsWithCloudSync(true);

        // Should have both local and cloud classifications
        expect(result.length, equals(2));
        
        // Should be sorted by timestamp (newest first)
        expect(result.first.itemName, equals('Cloud Classification'));
        expect(result.last.itemName, equals('Test Plastic Bottle'));
      });

      test('should handle cloud loading failure gracefully', () async {
        final localClassifications = [testClassification];
        when(mockLocalStorage.getAllClassifications()).thenAnswer((_) async => localClassifications);
        when(mockLocalStorage.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);

        // Mock cloud failure
        final mockQuery = MockQuery();
        when(mockClassificationsCollection.orderBy('timestamp', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenThrow(Exception('Cloud loading error'));

        final result = await cloudStorageService.getAllClassificationsWithCloudSync(true);

        // Should return local classifications even if cloud fails
        expect(result.length, equals(1));
        expect(result.first.itemName, equals('Test Plastic Bottle'));
      });

      test('should handle corrupted cloud data gracefully', () async {
        final localClassifications = [testClassification];
        when(mockLocalStorage.getAllClassifications()).thenAnswer((_) async => localClassifications);
        when(mockLocalStorage.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);

        // Mock cloud query with corrupted data
        final mockQuery = MockQuery();
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockDocSnapshot = MockDocumentSnapshot();

        when(mockClassificationsCollection.orderBy('timestamp', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);
        when(mockDocSnapshot.data()).thenReturn({'invalid': 'data'}); // Corrupted data

        final result = await cloudStorageService.getAllClassificationsWithCloudSync(true);

        // Should return local classifications and ignore corrupted cloud data
        expect(result.length, equals(1));
        expect(result.first.itemName, equals('Test Plastic Bottle'));
      });
    });

    group('Bulk Sync Tests', () {
      test('should sync all local classifications to cloud', () async {
        final localClassifications = [
          testClassification,
          testClassification.copyWith(itemName: 'Second Classification'),
        ];

        when(mockLocalStorage.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockLocalStorage.getAllClassifications()).thenAnswer((_) async => localClassifications);
        when(mockClassificationDoc.set(any)).thenAnswer((_) async {
          return null;
        });

        // Mock admin collections
        final mockAdminCollection = MockCollectionReference();
        when(mockFirestore.collection('admin_classifications')).thenReturn(mockAdminCollection);
        when(mockAdminCollection.add(any)).thenAnswer((_) async => mockClassificationDoc);

        final mockRecoveryCollection = MockCollectionReference();
        final mockRecoveryDoc = MockDocumentReference();
        when(mockFirestore.collection('admin_user_recovery')).thenReturn(mockRecoveryCollection);
        when(mockRecoveryCollection.doc(any)).thenReturn(mockRecoveryDoc);
        when(mockRecoveryDoc.set(any, any)).thenAnswer((_) async {});

        final syncedCount = await cloudStorageService.syncAllLocalClassificationsToCloud();

        expect(syncedCount, equals(2));
        verify(mockClassificationDoc.set(any)).called(2);
      });

      test('should handle partial sync failures', () async {
        final localClassifications = [
          testClassification,
          testClassification.copyWith(itemName: 'Second Classification'),
        ];

        when(mockLocalStorage.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockLocalStorage.getAllClassifications()).thenAnswer((_) async => localClassifications);
        
        // First sync succeeds, second fails
        when(mockClassificationDoc.set(any))
            .thenAnswer((_) async {
              return null;
            })
            .thenThrow(Exception('Sync error'));

        // Mock admin operations for successful sync
        final mockAdminCollection = MockCollectionReference();
        when(mockFirestore.collection('admin_classifications')).thenReturn(mockAdminCollection);
        when(mockAdminCollection.add(any)).thenAnswer((_) async => mockClassificationDoc);

        final mockRecoveryCollection = MockCollectionReference();
        final mockRecoveryDoc = MockDocumentReference();
        when(mockFirestore.collection('admin_user_recovery')).thenReturn(mockRecoveryCollection);
        when(mockRecoveryCollection.doc(any)).thenReturn(mockRecoveryDoc);
        when(mockRecoveryDoc.set(any, any)).thenAnswer((_) async {});

        final syncedCount = await cloudStorageService.syncAllLocalClassificationsToCloud();

        // Should return count of successful syncs only
        expect(syncedCount, equals(1));
      });

      test('should return 0 when user not signed in for bulk sync', () async {
        when(mockLocalStorage.getCurrentUserProfile()).thenAnswer((_) async => null);

        final syncedCount = await cloudStorageService.syncAllLocalClassificationsToCloud();

        expect(syncedCount, equals(0));
        verifyNever(mockClassificationDoc.set(any));
      });
    });

    group('Cloud Data Clearing Tests', () {
      test('should clear all cloud data for user', () async {
        when(mockLocalStorage.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);

        // Mock query and batch operations
        final mockQuery = MockQuery();
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockDocSnapshot = MockDocumentSnapshot();
        final mockBatch = MockBatch();

        when(mockClassificationsCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockDocSnapshot, mockDocSnapshot]);
        when(mockDocSnapshot.reference).thenReturn(mockClassificationDoc);
        when(mockFirestore.batch()).thenReturn(mockBatch);
        when(mockBatch.delete(any)).thenReturn(null);
        when(mockBatch.commit()).thenAnswer((_) async {});

        await cloudStorageService.clearCloudData();

        // Verify batch operations
        verify(mockBatch.delete(any)).called(2); // Two documents
        verify(mockBatch.commit()).called(1);
      });

      test('should not clear data when user not signed in', () async {
        when(mockLocalStorage.getCurrentUserProfile()).thenAnswer((_) async => null);

        await cloudStorageService.clearCloudData();

        // Verify no operations were performed
        verifyNever(mockClassificationsCollection.get());
      });

      test('should handle cloud data clearing failure', () async {
        when(mockLocalStorage.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockClassificationsCollection.get()).thenThrow(Exception('Clear error'));

        expect(
          () async => await cloudStorageService.clearCloudData(),
          throwsException,
        );
      });
    });

    group('Gamification Integration Tests', () {
      test('should process gamification for recent classifications', () async {
        final recentClassification = testClassification.copyWith(
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        );

        when(mockLocalStorage.saveClassification(any)).thenAnswer((_) async {
          return null;
        });
        when(mockLocalStorage.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);

        // Mock gamification service dependencies
        when(mockLocalStorage.getGamificationProfile()).thenAnswer((_) async => testUserProfile.gamificationProfile);

        await cloudStorageService.saveClassificationWithSync(
          recentClassification,
          false, // Disable cloud sync to focus on gamification
          processGamification: true,
        );

        // Verify local save was called
        verify(mockLocalStorage.saveClassification(recentClassification)).called(1);
      });

      test('should skip gamification for old classifications', () async {
        final oldClassification = testClassification.copyWith(
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        );

        when(mockLocalStorage.saveClassification(any)).thenAnswer((_) async {
          return null;
        });

        await cloudStorageService.saveClassificationWithSync(
          oldClassification,
          false,
          processGamification: true,
        );

        // Verify local save was called
        verify(mockLocalStorage.saveClassification(oldClassification)).called(1);
      });

      test('should handle gamification processing errors gracefully', () async {
        when(mockLocalStorage.saveClassification(any)).thenAnswer((_) async {
          return null;
        });
        when(mockLocalStorage.getGamificationProfile()).thenThrow(Exception('Gamification error'));

        // Should not throw exception even if gamification fails
        await cloudStorageService.saveClassificationWithSync(
          testClassification,
          false,
          processGamification: true,
        );

        // Main save operation should still succeed
        verify(mockLocalStorage.saveClassification(testClassification)).called(1);
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle empty classification list', () async {
        when(mockLocalStorage.getAllClassifications()).thenAnswer((_) async => []);

        final result = await cloudStorageService.getAllClassificationsWithCloudSync(false);

        expect(result, isEmpty);
      });

      test('should handle null user profile gracefully', () async {
        when(mockLocalStorage.saveClassification(any)).thenAnswer((_) async {
          return null;
        });
        when(mockLocalStorage.getCurrentUserProfile()).thenAnswer((_) async => null);

        await cloudStorageService.saveClassificationWithSync(
          testClassification,
          true,
          processGamification: false,
        );

        // Should save locally but not sync to cloud
        verify(mockLocalStorage.saveClassification(testClassification)).called(1);
        verifyNever(mockClassificationDoc.set(any));
      });

      test('should handle very large classification data', () async {
        final largeClassification = testClassification.copyWith(
          itemName: 'A' * 1000,
          explanation: 'B' * 5000,
          visualFeatures: List.generate(100, (i) => 'feature_\$i'),
        );

        when(mockLocalStorage.saveClassification(any)).thenAnswer((_) async {
          return null;
        });

        await cloudStorageService.saveClassificationWithSync(
          largeClassification,
          false,
          processGamification: false,
        );

        verify(mockLocalStorage.saveClassification(largeClassification)).called(1);
      });

      test('should handle concurrent operations', () async {
        when(mockLocalStorage.saveClassification(any)).thenAnswer((_) async {
          return null;
        });

        // Simulate concurrent saves
        final futures = List.generate(10, (i) {
          final classification = testClassification.copyWith(
            itemName: 'Concurrent Classification \$i',
          );
          return cloudStorageService.saveClassificationWithSync(
            classification,
            false,
            processGamification: false,
          );
        });

        await Future.wait(futures);

        // All saves should succeed
        verify(mockLocalStorage.saveClassification(any)).called(10);
      });

      test('should handle network connectivity issues', () async {
        when(mockLocalStorage.saveClassification(any)).thenAnswer((_) async {
          return null;
        });
        when(mockLocalStorage.getCurrentUserProfile()).thenAnswer((_) async => testUserProfile);
        when(mockClassificationDoc.set(any)).thenThrow(Exception('Network error'));

        // Should handle network errors gracefully
        await cloudStorageService.saveClassificationWithSync(
          testClassification,
          true,
          processGamification: false,
        );

        // Local save should still succeed
        verify(mockLocalStorage.saveClassification(testClassification)).called(1);
      });
    });
  });
}
*/
