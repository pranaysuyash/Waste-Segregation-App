import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:waste_segregation_app/providers/leaderboard_provider.dart';
import 'package:waste_segregation_app/services/leaderboard_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/models/leaderboard.dart';
import 'package:waste_segregation_app/models/user_profile.dart';

import 'leaderboard_provider_test.mocks.dart';

@GenerateMocks([LeaderboardService, StorageService])
void main() {
  group('LeaderboardProvider Tests', () {
    late MockLeaderboardService mockLeaderboardService;
    late MockStorageService mockStorageService;
    late ProviderContainer container;

    setUp(() {
      mockLeaderboardService = MockLeaderboardService();
      mockStorageService = MockStorageService();

      container = ProviderContainer(
        overrides: [
          leaderboardServiceProvider.overrideWithValue(mockLeaderboardService),
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('LeaderboardService Provider', () {
      test('should provide LeaderboardService instance', () {
        final leaderboardService = container.read(leaderboardServiceProvider);
        expect(leaderboardService, isA<LeaderboardService>());
        expect(leaderboardService, equals(mockLeaderboardService));
      });
    });

    group('Top Leaderboard Entries Provider', () {
      test('should fetch top N entries successfully', () async {
        // Arrange
        const limit = 10;
        final mockEntries = [
          LeaderboardEntry(
            userId: 'user1',
            username: 'EcoWarrior',
            totalPoints: 1000,
            rank: 1,
            avatarUrl: 'https://example.com/avatar1.png',
          ),
          LeaderboardEntry(
            userId: 'user2',
            username: 'GreenThumb',
            totalPoints: 950,
            rank: 2,
            avatarUrl: 'https://example.com/avatar2.png',
          ),
        ];

        when(mockLeaderboardService.getTopNEntries(limit))
            .thenAnswer((_) async => mockEntries);

        // Act
        final result = await container.read(topLeaderboardEntriesProvider(limit).future);

        // Assert
        expect(result, equals(mockEntries));
        expect(result.length, equals(2));
        expect(result.first.rank, equals(1));
        expect(result.last.rank, equals(2));
        verify(mockLeaderboardService.getTopNEntries(limit)).called(1);
      });

      test('should handle empty leaderboard', () async {
        // Arrange
        const limit = 10;
        when(mockLeaderboardService.getTopNEntries(limit))
            .thenAnswer((_) async => <LeaderboardEntry>[]);

        // Act
        final result = await container.read(topLeaderboardEntriesProvider(limit).future);

        // Assert
        expect(result, isEmpty);
        verify(mockLeaderboardService.getTopNEntries(limit)).called(1);
      });

      test('should handle service errors', () async {
        // Arrange
        const limit = 10;
        when(mockLeaderboardService.getTopNEntries(limit))
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => container.read(topLeaderboardEntriesProvider(limit).future),
          throwsException,
        );
      });

      test('should auto-dispose when not used', () async {
        // Arrange
        const limit = 5;
        when(mockLeaderboardService.getTopNEntries(limit))
            .thenAnswer((_) async => <LeaderboardEntry>[]);

        // Act
        final provider = topLeaderboardEntriesProvider(limit);
        await container.read(provider.future);
        
        // The provider should auto-dispose when container is disposed
        container.dispose();
        
        // Assert
        verify(mockLeaderboardService.getTopNEntries(limit)).called(1);
      });
    });

    group('Current User Leaderboard Entry Provider', () {
      test('should fetch current user entry when user exists', () async {
        // Arrange
        final mockUserProfile = UserProfile(
          id: 'user123',
          name: 'Test User',
          email: 'test@example.com',
        );
        final mockLeaderboardEntry = LeaderboardEntry(
          userId: 'user123',
          username: 'Test User',
          totalPoints: 750,
          rank: 5,
          avatarUrl: 'https://example.com/avatar.png',
        );

        when(mockStorageService.getCurrentUserProfile())
            .thenAnswer((_) async => mockUserProfile);
        when(mockLeaderboardService.getUserEntry('user123'))
            .thenAnswer((_) async => mockLeaderboardEntry);

        // Act
        final result = await container.read(currentUserLeaderboardEntryProvider.future);

        // Assert
        expect(result, equals(mockLeaderboardEntry));
        expect(result?.userId, equals('user123'));
        expect(result?.rank, equals(5));
        verify(mockStorageService.getCurrentUserProfile()).called(1);
        verify(mockLeaderboardService.getUserEntry('user123')).called(1);
      });

      test('should return null when no user is logged in', () async {
        // Arrange
        when(mockStorageService.getCurrentUserProfile())
            .thenAnswer((_) async => null);

        // Act
        final result = await container.read(currentUserLeaderboardEntryProvider.future);

        // Assert
        expect(result, isNull);
        verify(mockStorageService.getCurrentUserProfile()).called(1);
        verifyNever(mockLeaderboardService.getUserEntry(any));
      });

      test('should return null when user has empty ID', () async {
        // Arrange
        final mockUserProfile = UserProfile(
          id: '',
          name: 'Test User',
          email: 'test@example.com',
        );

        when(mockStorageService.getCurrentUserProfile())
            .thenAnswer((_) async => mockUserProfile);

        // Act
        final result = await container.read(currentUserLeaderboardEntryProvider.future);

        // Assert
        expect(result, isNull);
        verify(mockStorageService.getCurrentUserProfile()).called(1);
        verifyNever(mockLeaderboardService.getUserEntry(any));
      });

      test('should handle user not found on leaderboard', () async {
        // Arrange
        final mockUserProfile = UserProfile(
          id: 'user123',
          name: 'Test User',
          email: 'test@example.com',
        );

        when(mockStorageService.getCurrentUserProfile())
            .thenAnswer((_) async => mockUserProfile);
        when(mockLeaderboardService.getUserEntry('user123'))
            .thenAnswer((_) async => null);

        // Act
        final result = await container.read(currentUserLeaderboardEntryProvider.future);

        // Assert
        expect(result, isNull);
        verify(mockStorageService.getCurrentUserProfile()).called(1);
        verify(mockLeaderboardService.getUserEntry('user123')).called(1);
      });
    });

    group('Current User Rank Provider', () {
      test('should fetch current user rank when user exists', () async {
        // Arrange
        final mockUserProfile = UserProfile(
          id: 'user123',
          name: 'Test User',
          email: 'test@example.com',
        );
        const expectedRank = 15;

        when(mockStorageService.getCurrentUserProfile())
            .thenAnswer((_) async => mockUserProfile);
        when(mockLeaderboardService.getCurrentUserRank('user123'))
            .thenAnswer((_) async => expectedRank);

        // Act
        final result = await container.read(currentUserRankProvider.future);

        // Assert
        expect(result, equals(expectedRank));
        verify(mockStorageService.getCurrentUserProfile()).called(1);
        verify(mockLeaderboardService.getCurrentUserRank('user123')).called(1);
      });

      test('should return null when no user is logged in', () async {
        // Arrange
        when(mockStorageService.getCurrentUserProfile())
            .thenAnswer((_) async => null);

        // Act
        final result = await container.read(currentUserRankProvider.future);

        // Assert
        expect(result, isNull);
        verify(mockStorageService.getCurrentUserProfile()).called(1);
        verifyNever(mockLeaderboardService.getCurrentUserRank(any));
      });

      test('should return null when user not ranked', () async {
        // Arrange
        final mockUserProfile = UserProfile(
          id: 'user123',
          name: 'Test User',
          email: 'test@example.com',
        );

        when(mockStorageService.getCurrentUserProfile())
            .thenAnswer((_) async => mockUserProfile);
        when(mockLeaderboardService.getCurrentUserRank('user123'))
            .thenAnswer((_) async => null);

        // Act
        final result = await container.read(currentUserRankProvider.future);

        // Assert
        expect(result, isNull);
        verify(mockStorageService.getCurrentUserProfile()).called(1);
        verify(mockLeaderboardService.getCurrentUserRank('user123')).called(1);
      });
    });

    group('Leaderboard Screen Data Provider', () {
      test('should combine all leaderboard data successfully', () async {
        // Arrange
        final mockUserProfile = UserProfile(
          id: 'user123',
          name: 'Test User',
          email: 'test@example.com',
        );
        final mockTopEntries = [
          LeaderboardEntry(
            userId: 'user1',
            username: 'TopPlayer',
            totalPoints: 2000,
            rank: 1,
            avatarUrl: 'https://example.com/avatar1.png',
          ),
          LeaderboardEntry(
            userId: 'user123',
            username: 'Test User',
            totalPoints: 1500,
            rank: 2,
            avatarUrl: 'https://example.com/avatar123.png',
          ),
        ];
        final mockUserEntry = LeaderboardEntry(
          userId: 'user123',
          username: 'Test User',
          totalPoints: 1500,
          rank: 2,
          avatarUrl: 'https://example.com/avatar123.png',
        );
        const mockUserRank = 2;

        when(mockStorageService.getCurrentUserProfile())
            .thenAnswer((_) async => mockUserProfile);
        when(mockLeaderboardService.getTopNEntries(20))
            .thenAnswer((_) async => mockTopEntries);
        when(mockLeaderboardService.getUserEntry('user123'))
            .thenAnswer((_) async => mockUserEntry);
        when(mockLeaderboardService.getCurrentUserRank('user123'))
            .thenAnswer((_) async => mockUserRank);

        // Act
        final result = await container.read(leaderboardScreenDataProvider.future);

        // Assert
        expect(result.topEntries, equals(mockTopEntries));
        expect(result.currentUserEntry, equals(mockUserEntry));
        expect(result.currentUserRank, equals(mockUserRank));
        expect(result.topEntries.length, equals(2));
      });

      test('should handle anonymous user scenario', () async {
        // Arrange
        final mockTopEntries = [
          LeaderboardEntry(
            userId: 'user1',
            username: 'TopPlayer',
            totalPoints: 2000,
            rank: 1,
            avatarUrl: 'https://example.com/avatar1.png',
          ),
        ];

        when(mockStorageService.getCurrentUserProfile())
            .thenAnswer((_) async => null);
        when(mockLeaderboardService.getTopNEntries(20))
            .thenAnswer((_) async => mockTopEntries);

        // Act
        final result = await container.read(leaderboardScreenDataProvider.future);

        // Assert
        expect(result.topEntries, equals(mockTopEntries));
        expect(result.currentUserEntry, isNull);
        expect(result.currentUserRank, isNull);
        verify(mockStorageService.getCurrentUserProfile()).called(2); // Called by both user providers
      });

      test('should handle service errors gracefully', () async {
        // Arrange
        when(mockStorageService.getCurrentUserProfile())
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => container.read(leaderboardScreenDataProvider.future),
          throwsException,
        );
      });

      test('should handle partial failures', () async {
        // Arrange
        final mockUserProfile = UserProfile(
          id: 'user123',
          name: 'Test User',
          email: 'test@example.com',
        );
        final mockTopEntries = [
          LeaderboardEntry(
            userId: 'user1',
            username: 'TopPlayer',
            totalPoints: 2000,
            rank: 1,
            avatarUrl: 'https://example.com/avatar1.png',
          ),
        ];

        when(mockStorageService.getCurrentUserProfile())
            .thenAnswer((_) async => mockUserProfile);
        when(mockLeaderboardService.getTopNEntries(20))
            .thenAnswer((_) async => mockTopEntries);
        when(mockLeaderboardService.getUserEntry('user123'))
            .thenAnswer((_) async => null); // User not on leaderboard
        when(mockLeaderboardService.getCurrentUserRank('user123'))
            .thenAnswer((_) async => null); // User not ranked

        // Act
        final result = await container.read(leaderboardScreenDataProvider.future);

        // Assert
        expect(result.topEntries, equals(mockTopEntries));
        expect(result.currentUserEntry, isNull);
        expect(result.currentUserRank, isNull);
      });
    });

    group('Provider Caching and Performance', () {
      test('should cache results for same parameters', () async {
        // Arrange
        const limit = 10;
        final mockEntries = [
          LeaderboardEntry(
            userId: 'user1',
            username: 'TestUser',
            totalPoints: 1000,
            rank: 1,
            avatarUrl: 'https://example.com/avatar.png',
          ),
        ];

        when(mockLeaderboardService.getTopNEntries(limit))
            .thenAnswer((_) async => mockEntries);

        // Act
        final result1 = await container.read(topLeaderboardEntriesProvider(limit).future);
        final result2 = await container.read(topLeaderboardEntriesProvider(limit).future);

        // Assert
        expect(result1, equals(result2));
        expect(result1, equals(mockEntries));
        // Should only call the service once due to caching
        verify(mockLeaderboardService.getTopNEntries(limit)).called(1);
      });

      test('should handle different parameters separately', () async {
        // Arrange
        final mockEntries5 = [
          LeaderboardEntry(
            userId: 'user1',
            username: 'TestUser1',
            totalPoints: 1000,
            rank: 1,
            avatarUrl: 'https://example.com/avatar1.png',
          ),
        ];
        final mockEntries10 = [
          LeaderboardEntry(
            userId: 'user1',
            username: 'TestUser1',
            totalPoints: 1000,
            rank: 1,
            avatarUrl: 'https://example.com/avatar1.png',
          ),
          LeaderboardEntry(
            userId: 'user2',
            username: 'TestUser2',
            totalPoints: 950,
            rank: 2,
            avatarUrl: 'https://example.com/avatar2.png',
          ),
        ];

        when(mockLeaderboardService.getTopNEntries(5))
            .thenAnswer((_) async => mockEntries5);
        when(mockLeaderboardService.getTopNEntries(10))
            .thenAnswer((_) async => mockEntries10);

        // Act
        final result5 = await container.read(topLeaderboardEntriesProvider(5).future);
        final result10 = await container.read(topLeaderboardEntriesProvider(10).future);

        // Assert
        expect(result5.length, equals(1));
        expect(result10.length, equals(2));
        verify(mockLeaderboardService.getTopNEntries(5)).called(1);
        verify(mockLeaderboardService.getTopNEntries(10)).called(1);
      });
    });

    group('Error Recovery', () {
      test('should handle network timeouts gracefully', () async {
        // Arrange
        when(mockLeaderboardService.getTopNEntries(any))
            .thenThrow(Exception('Timeout'));

        // Act & Assert
        expect(
          () => container.read(topLeaderboardEntriesProvider(10).future),
          throwsException,
        );
      });

      test('should handle malformed data gracefully', () async {
        // Arrange
        when(mockStorageService.getCurrentUserProfile())
            .thenThrow(const FormatException('Invalid user data'));

        // Act & Assert
        expect(
          () => container.read(currentUserLeaderboardEntryProvider.future),
          throwsException,
        );
      });
    });
  });
}
