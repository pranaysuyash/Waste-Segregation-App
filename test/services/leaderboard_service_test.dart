import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:waste_segregation_app/services/leaderboard_service.dart';
import 'package:waste_segregation_app/models/leaderboard.dart';
import 'dart:async'; // Added for TimeoutException

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  Query,
  QuerySnapshot,
  DocumentSnapshot,
  QueryDocumentSnapshot,
])
import 'leaderboard_service_test.mocks.dart';

void main() {
  group('LeaderboardService Tests', () {
    late LeaderboardService leaderboardService;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockQuery<Map<String, dynamic>> mockQuery;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      
      when(mockFirestore.collection('leaderboard')).thenReturn(mockCollection);
      
      leaderboardService = LeaderboardService(mockFirestore);
    });

    group('Global Leaderboard', () {
      test('should fetch global leaderboard successfully', () async {
        final mockDocs = [
          _createMockDoc('user1', {
            'userId': 'user1',
            'userName': 'John Doe',
            'score': 1500,
            'rank': 1,
            'avatar': 'avatar1.jpg',
            'classificationsCount': 150,
            'accuracyRate': 0.95,
            'streakDays': 12,
          }),
          _createMockDoc('user2', {
            'userId': 'user2',
            'userName': 'Jane Smith',
            'score': 1200,
            'rank': 2,
            'avatar': 'avatar2.jpg',
            'classificationsCount': 120,
            'accuracyRate': 0.92,
            'streakDays': 8,
          }),
        ];

        when(mockCollection.where('period', isEqualTo: 'thisWeek'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('score', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.limit(50)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        final result = await leaderboardService.getGlobalLeaderboard(
          LeaderboardPeriod.thisWeek,
        );

        expect(result.length, 2);
        expect(result[0].userId, 'user1');
        expect(result[0].userName, 'John Doe');
        expect(result[0].score, 1500);
        expect(result[0].rank, 1);
        expect(result[1].userId, 'user2');
        expect(result[1].score, 1200);
        
        verify(mockCollection.where('period', isEqualTo: 'thisWeek')).called(1);
        verify(mockQuery.orderBy('score', descending: true)).called(1);
        verify(mockQuery.limit(50)).called(1);
      });

      test('should handle empty global leaderboard', () async {
        when(mockCollection.where('period', isEqualTo: 'thisMonth'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('score', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.limit(50)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        final result = await leaderboardService.getGlobalLeaderboard(
          LeaderboardPeriod.thisMonth,
        );

        expect(result.isEmpty, true);
      });

      test('should handle global leaderboard fetch error', () async {
        when(mockCollection.where('period', isEqualTo: 'thisWeek'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('score', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.limit(50)).thenReturn(mockQuery);
        when(mockQuery.get()).thenThrow(Exception('Firestore error'));

        expect(
          () => leaderboardService.getGlobalLeaderboard(LeaderboardPeriod.thisWeek),
          throwsException,
        );
      });

      test('should fetch global leaderboard with pagination', () async {
        final mockDocs = List.generate(25, (index) => 
          _createMockDoc('user_$index', {
            'userId': 'user_$index',
            'userName': 'User $index',
            'score': 1000 - index * 10,
            'rank': index + 1,
            'avatar': 'avatar_$index.jpg',
            'classificationsCount': 100 - index,
          })
        );

        when(mockCollection.where('period', isEqualTo: 'thisWeek'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('score', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.limit(25)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        final result = await leaderboardService.getGlobalLeaderboard(
          LeaderboardPeriod.thisWeek,
          limit: 25,
        );

        expect(result.length, 25);
        expect(result.first.score, 1000);
        expect(result.last.score, 760);
        verify(mockQuery.limit(25)).called(1);
      });
    });

    group('Family Leaderboard', () {
      test('should fetch family leaderboard successfully', () async {
        const familyId = 'family_123';
        final mockDocs = [
          _createMockDoc('family_user1', {
            'userId': 'family_user1',
            'userName': 'Dad',
            'score': 800,
            'rank': 1,
            'avatar': 'dad_avatar.jpg',
            'classificationsCount': 80,
            'familyId': familyId,
          }),
          _createMockDoc('family_user2', {
            'userId': 'family_user2',
            'userName': 'Mom',
            'score': 750,
            'rank': 2,
            'avatar': 'mom_avatar.jpg',
            'classificationsCount': 75,
            'familyId': familyId,
          }),
        ];

        when(mockCollection.where('familyId', isEqualTo: familyId))
            .thenReturn(mockQuery);
        when(mockQuery.where('period', isEqualTo: 'thisWeek'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('score', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        final result = await leaderboardService.getFamilyLeaderboard(
          familyId,
          LeaderboardPeriod.thisWeek,
        );

        expect(result.length, 2);
        expect(result[0].userName, 'Dad');
        expect(result[0].score, 800);
        expect(result[1].userName, 'Mom');
        expect(result[1].score, 750);
        
        verify(mockCollection.where('familyId', isEqualTo: familyId)).called(1);
        verify(mockQuery.where('period', isEqualTo: 'thisWeek')).called(1);
      });

      test('should handle empty family leaderboard', () async {
        const familyId = 'empty_family';

        when(mockCollection.where('familyId', isEqualTo: familyId))
            .thenReturn(mockQuery);
        when(mockQuery.where('period', isEqualTo: 'thisWeek'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('score', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        final result = await leaderboardService.getFamilyLeaderboard(
          familyId,
          LeaderboardPeriod.thisWeek,
        );

        expect(result.isEmpty, true);
      });

      test('should handle invalid family ID', () async {
        const invalidFamilyId = '';

        expect(
          () => leaderboardService.getFamilyLeaderboard(
            invalidFamilyId,
            LeaderboardPeriod.thisWeek,
          ),
          throwsArgumentError,
        );
      });
    });

    group('User Ranking', () {
      test('should get user rank successfully', () async {
        const userId = 'user_123';
        final mockDoc = _createMockDocumentSnapshot(userId, {
          'userId': userId,
          'globalRank': 42,
          'familyRank': 2,
          'score': 950,
          'classificationsCount': 95,
          'accuracyRate': 0.89,
          'currentStreak': 12,
          'longestStreak': 20,
          'lastRankUpdate': '2024-01-15T10:30:00.000Z',
          'rankTrend': 'up',
          'previousGlobalRank': 45,
          'previousFamilyRank': 3,
        });

        when(mockCollection.doc(userId)).thenReturn(MockDocumentReference());
        when(mockCollection.doc(userId).get())
            .thenAnswer((_) async => mockDoc);
        when(mockDoc.exists).thenReturn(true);

        final result = await leaderboardService.getUserRank(
          userId,
          LeaderboardPeriod.thisWeek,
        );

        expect(result, isNotNull);
        expect(result!.userId, userId);
        expect(result.globalRank, 42);
        expect(result.familyRank, 2);
        expect(result.score, 950);
        expect(result.classificationsCount, 95);
        expect(result.rankTrend, RankTrend.up);
        
        verify(mockCollection.doc(userId)).called(1);
      });

      test('should handle user not found in leaderboard', () async {
        const userId = 'non_existent_user';
        final mockDoc = _createMockDocumentSnapshot(userId, {});

        when(mockCollection.doc(userId)).thenReturn(MockDocumentReference());
        when(mockCollection.doc(userId).get())
            .thenAnswer((_) async => mockDoc);
        when(mockDoc.exists).thenReturn(false);

        final result = await leaderboardService.getUserRank(
          userId,
          LeaderboardPeriod.thisWeek,
        );

        expect(result, null);
      });

      test('should handle invalid user ID', () async {
        const invalidUserId = '';

        expect(
          () => leaderboardService.getUserRank(
            invalidUserId,
            LeaderboardPeriod.thisWeek,
          ),
          throwsArgumentError,
        );
      });
    });

    group('Leaderboard Updates', () {
      test('should update user score successfully', () async {
        const userId = 'user_123';
        const newScore = 1100;
        const classificationsCount = 110;

        when(mockCollection.doc(userId)).thenReturn(MockDocumentReference());
        when(mockCollection.doc(userId).set(any, any))
            .thenAnswer((_) async => null);

        await leaderboardService.updateUserScore(
          userId,
          newScore,
          classificationsCount,
          LeaderboardPeriod.thisWeek,
        );

        verify(mockCollection.doc(userId)).called(1);
        verify(mockCollection.doc(userId).set(
          argThat(allOf([
            containsPair('userId', userId),
            containsPair('score', newScore),
            containsPair('classificationsCount', classificationsCount),
          ])),
          any,
        )).called(1);
      });

      test('should handle negative score update', () async {
        const userId = 'user_123';
        const negativeScore = -100;

        expect(
          () => leaderboardService.updateUserScore(
            userId,
            negativeScore,
            50,
            LeaderboardPeriod.thisWeek,
          ),
          throwsArgumentError,
        );
      });

      test('should batch update multiple users', () async {
        final userUpdates = [
          LeaderboardUpdate('user1', 1000, 100),
          LeaderboardUpdate('user2', 800, 80),
          LeaderboardUpdate('user3', 600, 60),
        ];

        when(mockFirestore.batch()).thenReturn(MockWriteBatch());
        
        final mockBatch = MockWriteBatch();
        when(mockFirestore.batch()).thenReturn(mockBatch);
        when(mockBatch.commit()).thenAnswer((_) async {});

        await leaderboardService.batchUpdateUsers(
          userUpdates,
          LeaderboardPeriod.thisWeek,
        );

        verify(mockFirestore.batch()).called(1);
        verify(mockBatch.commit()).called(1);
      });

      test('should recalculate rankings after score updates', () async {
        final mockDocs = [
          _createMockDoc('user1', {
            'userId': 'user1',
            'score': 1200,
            'classificationsCount': 120,
          }),
          _createMockDoc('user2', {
            'userId': 'user2',
            'score': 1000,
            'classificationsCount': 100,
          }),
          _createMockDoc('user3', {
            'userId': 'user3',
            'score': 800,
            'classificationsCount': 80,
          }),
        ];

        when(mockCollection.where('period', isEqualTo: 'thisWeek'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('score', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        when(mockFirestore.batch()).thenReturn(MockWriteBatch());
        final mockBatch = MockWriteBatch();
        when(mockFirestore.batch()).thenReturn(mockBatch);
        when(mockBatch.commit()).thenAnswer((_) async {});

        await leaderboardService.recalculateRankings(LeaderboardPeriod.thisWeek);

        verify(mockQuery.orderBy('score', descending: true)).called(1);
        verify(mockBatch.commit()).called(1);
      });
    });

    group('Leaderboard Statistics', () {
      test('should get leaderboard statistics successfully', () async {
        final mockDocs = List.generate(100, (index) => 
          _createMockDoc('user_$index', {
            'userId': 'user_$index',
            'score': 1000 - index * 5,
            'classificationsCount': 100 - index,
            'accuracyRate': 0.9 - (index * 0.001),
          })
        );

        when(mockCollection.where('period', isEqualTo: 'thisWeek'))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        final stats = await leaderboardService.getLeaderboardStatistics(
          LeaderboardPeriod.thisWeek,
        );

        expect(stats['totalUsers'], 100);
        expect(stats['averageScore'], closeTo(752.5, 1.0));
        expect(stats['topScore'], 1000);
        expect(stats['totalClassifications'], 5050);
        expect(stats['averageAccuracy'], closeTo(0.8505, 0.001));
      });

      test('should get user position in leaderboard', () async {
        const userId = 'user_42';
        final mockDocs = List.generate(100, (index) => 
          _createMockDoc('user_$index', {
            'userId': 'user_$index',
            'score': 1000 - index * 10,
          })
        );

        when(mockCollection.where('period', isEqualTo: 'thisWeek'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('score', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        final position = await leaderboardService.getUserPosition(
          userId,
          LeaderboardPeriod.thisWeek,
        );

        expect(position, 43); // 0-indexed, so user_42 is at position 42 + 1
      });

      test('should get users around specific rank', () async {
        const targetRank = 25;
        final mockDocs = List.generate(10, (index) => 
          _createMockDoc('user_${20 + index}', {
            'userId': 'user_${20 + index}',
            'userName': 'User ${20 + index}',
            'score': 800 - index * 10,
            'rank': 20 + index + 1,
          })
        );

        when(mockCollection.where('period', isEqualTo: 'thisWeek'))
            .thenReturn(mockQuery);
        when(mockQuery.where('rank', isGreaterThanOrEqualTo: 20))
            .thenReturn(mockQuery);
        when(mockQuery.where('rank', isLessThanOrEqualTo: 30))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('rank')).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        final result = await leaderboardService.getUsersAroundRank(
          targetRank,
          LeaderboardPeriod.thisWeek,
          context: 5,
        );

        expect(result.length, 10);
        expect(result.first.rank, 21);
        expect(result.last.rank, 30);
      });
    });

    group('Leaderboard Periods', () {
      test('should handle all leaderboard periods', () async {
        for (final period in LeaderboardPeriod.values) {
          when(mockCollection.where('period', isEqualTo: period.name))
              .thenReturn(mockQuery);
          when(mockQuery.orderBy('score', descending: true))
              .thenReturn(mockQuery);
          when(mockQuery.limit(50)).thenReturn(mockQuery);
          when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
          when(mockQuerySnapshot.docs).thenReturn([]);

          final result = await leaderboardService.getGlobalLeaderboard(period);

          expect(result, isA<List<LeaderboardEntry>>());
          verify(mockCollection.where('period', isEqualTo: period.name)).called(1);
        }
      });

      test('should get current active period', () {
        final currentPeriod = leaderboardService.getCurrentPeriod();
        expect(currentPeriod, isA<LeaderboardPeriod>());
      });

      test('should check if period is active', () {
        final thisWeekActive = leaderboardService.isPeriodActive(
          LeaderboardPeriod.thisWeek,
        );
        expect(thisWeekActive, true);

        // All time is always active
        final allTimeActive = leaderboardService.isPeriodActive(
          LeaderboardPeriod.allTime,
        );
        expect(allTimeActive, true);
      });
    });

    group('Achievement Integration', () {
      test('should trigger achievement when reaching top rank', () async {
        const userId = 'achievement_user';
        final achievementCallback = MockAchievementCallback();

        leaderboardService.setAchievementCallback(achievementCallback.call);

        await leaderboardService.updateUserScore(
          userId,
          2000, // Top score
          200,
          LeaderboardPeriod.thisWeek,
          triggerAchievements: true,
        );

        verify(achievementCallback.call('top_rank_weekly')).called(1);
      });

      test('should trigger streak achievement', () async {
        const userId = 'streak_user';
        final achievementCallback = MockAchievementCallback();

        leaderboardService.setAchievementCallback(achievementCallback.call);

        await leaderboardService.updateUserStreak(
          userId,
          30, // 30-day streak
          LeaderboardPeriod.thisWeek,
        );

        verify(achievementCallback.call('monthly_streak')).called(1);
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle Firestore connection timeout', () async {
        when(mockCollection.where('period', isEqualTo: 'thisWeek'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('score', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.limit(50)).thenReturn(mockQuery);
        when(mockQuery.get()).thenThrow(
          TimeoutException('Connection timeout', const Duration(seconds: 30)),
        );

        expect(
          () => leaderboardService.getGlobalLeaderboard(LeaderboardPeriod.thisWeek),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('should handle malformed leaderboard data', () async {
        final malformedDoc = _createMockDoc('malformed', {
          'userId': 'malformed_user',
          'score': 'invalid_score', // String instead of int
          'rank': null,
        });

        when(mockCollection.where('period', isEqualTo: 'thisWeek'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('score', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.limit(50)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([malformedDoc]);

        final result = await leaderboardService.getGlobalLeaderboard(
          LeaderboardPeriod.thisWeek,
        );

        // Should skip malformed entries
        expect(result.isEmpty, true);
      });

      test('should handle concurrent rank updates', () async {
        const userId = 'concurrent_user';
        
        // Simulate concurrent updates
        final futures = List.generate(5, (index) => 
          leaderboardService.updateUserScore(
            userId,
            1000 + index * 10,
            100 + index * 10,
            LeaderboardPeriod.thisWeek,
          )
        );

        await Future.wait(futures);

        // Should handle all updates without data corruption
        verify(mockCollection.doc(userId)).called(5);
      });

      test('should cleanup old leaderboard data', () async {
        final oldDocs = List.generate(10, (index) => 
          _createMockDoc('old_user_$index', {
            'userId': 'old_user_$index',
            'period': 'thisWeek',
            'lastUpdated': DateTime.now()
                .subtract(const Duration(days: 14))
                .toIso8601String(),
          })
        );

        when(mockCollection.where(
          'lastUpdated',
          isLessThan: any,
        )).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(oldDocs);

        when(mockFirestore.batch()).thenReturn(MockWriteBatch());
        final mockBatch = MockWriteBatch();
        when(mockFirestore.batch()).thenReturn(mockBatch);
        when(mockBatch.commit()).thenAnswer((_) async {});

        final deletedCount = await leaderboardService.cleanupOldData(
          const Duration(days: 7),
        );

        expect(deletedCount, 10);
        verify(mockBatch.commit()).called(1);
      });
    });

    group('Performance Optimization', () {
      test('should cache frequently accessed leaderboard data', () async {
        final mockDocs = [
          _createMockDoc('user1', {
            'userId': 'user1',
            'userName': 'User 1',
            'score': 1000,
            'rank': 1,
          }),
        ];

        when(mockCollection.where('period', isEqualTo: 'thisWeek'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('score', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.limit(50)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(mockDocs);

        // First call should hit Firestore
        final result1 = await leaderboardService.getGlobalLeaderboard(
          LeaderboardPeriod.thisWeek,
        );

        // Second call should use cache
        final result2 = await leaderboardService.getGlobalLeaderboard(
          LeaderboardPeriod.thisWeek,
        );

        expect(result1.length, result2.length);
        // Verify Firestore was called only once due to caching
        verify(mockQuery.get()).called(1);
      });

      test('should handle large leaderboard efficiently', () async {
        final largeLeaderboard = List.generate(1000, (index) => 
          _createMockDoc('user_$index', {
            'userId': 'user_$index',
            'userName': 'User $index',
            'score': 10000 - index,
            'rank': index + 1,
          })
        );

        when(mockCollection.where('period', isEqualTo: 'allTime'))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('score', descending: true))
            .thenReturn(mockQuery);
        when(mockQuery.limit(1000)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn(largeLeaderboard);

        final startTime = DateTime.now();
        final result = await leaderboardService.getGlobalLeaderboard(
          LeaderboardPeriod.allTime,
          limit: 1000,
        );
        final endTime = DateTime.now();

        expect(result.length, 1000);
        expect(endTime.difference(startTime).inMilliseconds, lessThan(5000));
      });
    });
  });
}

// Helper functions for creating mock objects
MockQueryDocumentSnapshot<Map<String, dynamic>> _createMockDoc(
  String id,
  Map<String, dynamic> data,
) {
  final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
  when(mockDoc.id).thenReturn(id);
  when(mockDoc.data()).thenReturn(data);
  when(mockDoc.exists).thenReturn(true);
  return mockDoc;
}

MockDocumentSnapshot<Map<String, dynamic>> _createMockDocumentSnapshot(
  String id,
  Map<String, dynamic> data,
) {
  final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
  when(mockDoc.id).thenReturn(id);
  when(mockDoc.data()).thenReturn(data);
  return mockDoc;
}

// Additional mock classes
class MockWriteBatch extends Mock implements WriteBatch {}
class MockAchievementCallback extends Mock {
  void call(String achievementId);
}

// Helper class for batch updates
class LeaderboardUpdate {

  LeaderboardUpdate(this.userId, this.score, this.classificationsCount);
  final String userId;
  final int score;
  final int classificationsCount;
}
