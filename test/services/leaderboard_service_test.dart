import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/services/firestore_schema_registry.dart';
import 'package:waste_segregation_app/services/leaderboard_service.dart';

import 'leaderboard_service_test.mocks.dart';

class FakeAggregateQuerySnapshot implements AggregateQuerySnapshot {
  FakeAggregateQuerySnapshot(this._count, this.query);

  final int? _count;

  @override
  final Query query;

  @override
  int? get count => _count;

  @override
  double? getAverage(String field) => null;

  @override
  double? getSum(String field) => null;
}

class FakeAggregateQuery implements AggregateQuery {
  FakeAggregateQuery(this._snapshot, this.query);

  final FakeAggregateQuerySnapshot _snapshot;

  @override
  final Query query;

  @override
  Future<AggregateQuerySnapshot> get({
    AggregateSource source = AggregateSource.server,
  }) async {
    return _snapshot;
  }

  @override
  AggregateQuery count() => this;
}

Map<String, dynamic> _entryData({
  required String displayName,
  required int points,
}) {
  return {
    'displayName': displayName,
    'points': points,
    'photoUrl': null,
    'categoryBreakdown': <String, int>{},
    'recentAchievements': <Map<String, dynamic>>[],
    'stats': null,
    'isCurrentUser': false,
    'familyId': null,
    'familyName': null,
  };
}

void main() {
  group('LeaderboardService', () {
    test('getTopNEntries returns ranked entries ordered by query results', () async {
      final firestore = MockFirebaseFirestore();
      final collection = MockCollectionReference<Map<String, dynamic>>();
      final query = MockQuery<Map<String, dynamic>>();
      final snapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final first = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final second = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(firestore.collection(FirestoreCollections.leaderboardAllTime))
          .thenAnswer((_) => collection);
      when(collection.orderBy('points', descending: true))
          .thenAnswer((_) => query);
      when(query.limit(2)).thenAnswer((_) => query);
      when(query.get()).thenAnswer((_) async => snapshot);

      when(snapshot.docs).thenReturn([first, second]);

      when(first.id).thenReturn('user-a');
      when(first.data()).thenReturn(_entryData(displayName: 'Alpha', points: 240));
      when(second.id).thenReturn('user-b');
      when(second.data()).thenReturn(_entryData(displayName: 'Beta', points: 180));

      final service = LeaderboardService(firestore: firestore);
      final entries = await service.getTopNEntries(2);

      expect(entries, hasLength(2));
      expect(entries[0].userId, 'user-a');
      expect(entries[0].displayName, 'Alpha');
      expect(entries[0].points, 240);
      expect(entries[0].rank, 1);
      expect(entries[1].userId, 'user-b');
      expect(entries[1].rank, 2);

      verify(firestore.collection(FirestoreCollections.leaderboardAllTime))
          .called(1);
      verify(collection.orderBy('points', descending: true)).called(1);
      verify(query.limit(2)).called(1);
      verify(query.get()).called(1);
    });

    test('getTopNEntries returns empty list for non-positive limits', () async {
      final service = LeaderboardService(firestore: MockFirebaseFirestore());

      expect(await service.getTopNEntries(0), isEmpty);
      expect(await service.getTopNEntries(-1), isEmpty);
    });

    test('getUserEntry returns null when user id is empty', () async {
      final service = LeaderboardService(firestore: MockFirebaseFirestore());

      expect(await service.getUserEntry(''), isNull);
    });

    test('getUserEntry returns parsed entry from Firestore document', () async {
      final firestore = MockFirebaseFirestore();
      final collection = MockCollectionReference<Map<String, dynamic>>();
      final docRef = MockDocumentReference<Map<String, dynamic>>();
      final docSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(firestore.collection(FirestoreCollections.leaderboardAllTime))
          .thenAnswer((_) => collection);
      when(collection.doc('user-123')).thenAnswer((_) => docRef);
      when(docRef.get()).thenAnswer((_) async => docSnapshot);
      when(docSnapshot.exists).thenReturn(true);
      when(docSnapshot.id).thenReturn('user-123');
      when(docSnapshot.data()).thenReturn(_entryData(
        displayName: 'Current User',
        points: 1250,
      ));

      final service = LeaderboardService(firestore: firestore);
      final entry = await service.getUserEntry('user-123');

      expect(entry, isNotNull);
      expect(entry!.userId, 'user-123');
      expect(entry.displayName, 'Current User');
      expect(entry.points, 1250);
      expect(entry.rank, isNull);
    });

    test('getCurrentUserRank returns null when user id is empty', () async {
      final service = LeaderboardService(firestore: MockFirebaseFirestore());

      expect(await service.getCurrentUserRank(''), isNull);
    });

    test('getCurrentUserRank returns rank derived from count query', () async {
      final firestore = MockFirebaseFirestore();
      final collection = MockCollectionReference<Map<String, dynamic>>();
      final userDoc = MockDocumentReference<Map<String, dynamic>>();
      final userSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      final query = MockQuery<Map<String, dynamic>>();
      final aggregateQuery = FakeAggregateQuery(
        FakeAggregateQuerySnapshot(4, query),
        query,
      );

      when(firestore.collection(FirestoreCollections.leaderboardAllTime))
          .thenAnswer((_) => collection);
      when(collection.doc('user-123')).thenAnswer((_) => userDoc);
      when(userDoc.get()).thenAnswer((_) async => userSnapshot);
      when(userSnapshot.exists).thenReturn(true);
      when(userSnapshot.data()).thenReturn(_entryData(
        displayName: 'Current User',
        points: 125,
      ));

      when(collection.where('points', isGreaterThan: 125))
          .thenAnswer((_) => query);
      when(query.count()).thenAnswer((_) => aggregateQuery);

      final service = LeaderboardService(firestore: firestore);
      final rank = await service.getCurrentUserRank('user-123');

      expect(rank, 5);
      verify(collection.where('points', isGreaterThan: 125)).called(1);
      // The fake aggregate query returns the count snapshot directly.
    });

    test('getCurrentUserRank returns null for missing user document', () async {
      final firestore = MockFirebaseFirestore();
      final collection = MockCollectionReference<Map<String, dynamic>>();
      final userDoc = MockDocumentReference<Map<String, dynamic>>();
      final userSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(firestore.collection(FirestoreCollections.leaderboardAllTime))
          .thenAnswer((_) => collection);
      when(collection.doc('missing-user')).thenAnswer((_) => userDoc);
      when(userDoc.get()).thenAnswer((_) async => userSnapshot);
      when(userSnapshot.exists).thenReturn(false);

      final service = LeaderboardService(firestore: firestore);
      final rank = await service.getCurrentUserRank('missing-user');

      expect(rank, isNull);
    });
  });
}
