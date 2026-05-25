import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/models/community_feed.dart';
import 'package:waste_segregation_app/models/filter_options.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/screens/community_screen.dart';
import 'package:waste_segregation_app/services/community_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';

class MockCommunityService extends Mock implements CommunityService {
  @override
  Future<void> initCommunity() => super.noSuchMethod(
        Invocation.method(#initCommunity, const []),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> syncWithUserData(List<WasteClassification> classifications,
          UserProfile? userProfile) =>
      super.noSuchMethod(
        Invocation.method(#syncWithUserData, [classifications, userProfile]),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<List<CommunityFeedItem>> getFeedItems({int limit = 50}) =>
      super.noSuchMethod(
        Invocation.method(#getFeedItems, const [], {#limit: limit}),
        returnValue: Future<List<CommunityFeedItem>>.value(const []),
        returnValueForMissingStub:
            Future<List<CommunityFeedItem>>.value(const []),
      ) as Future<List<CommunityFeedItem>>;

  @override
  Future<CommunityStats> getStats({bool forceRecompute = false}) =>
      super.noSuchMethod(
        Invocation.method(
            #getStats, const [], {#forceRecompute: forceRecompute}),
        returnValue: Future<CommunityStats>.value(const CommunityStats(
          totalUsers: 0,
          totalClassifications: 0,
          totalPoints: 0,
        )),
        returnValueForMissingStub:
            Future<CommunityStats>.value(const CommunityStats(
          totalUsers: 0,
          totalClassifications: 0,
          totalPoints: 0,
        )),
      ) as Future<CommunityStats>;
}

class MockStorageService extends Mock implements StorageService {
  @override
  Future<UserProfile?> getCurrentUserProfile() => super.noSuchMethod(
        Invocation.method(#getCurrentUserProfile, const []),
        returnValue: Future<UserProfile?>.value(null),
        returnValueForMissingStub: Future<UserProfile?>.value(null),
      ) as Future<UserProfile?>;

  @override
  Future<List<WasteClassification>> getAllClassifications(
          {FilterOptions? filterOptions}) =>
      super.noSuchMethod(
        Invocation.method(
          #getAllClassifications,
          const [],
          {#filterOptions: filterOptions},
        ),
        returnValue: Future<List<WasteClassification>>.value(const []),
        returnValueForMissingStub:
            Future<List<WasteClassification>>.value(const []),
      ) as Future<List<WasteClassification>>;
}

void main() {
  group('CommunityScreen', () {
    testWidgets('renders tabs after loading', (tester) async {
      final storageService = MockStorageService();
      final communityService = MockCommunityService();

      when(storageService.getCurrentUserProfile())
          .thenAnswer((_) async => null);
      when(storageService.getAllClassifications())
          .thenAnswer((_) async => const []);

      when(communityService.initCommunity()).thenAnswer((_) async {});
      when(communityService.syncWithUserData(const [], null))
          .thenAnswer((_) async {});
      when(communityService.getFeedItems())
          .thenAnswer((_) async => <CommunityFeedItem>[]);
      when(communityService.getStats()).thenAnswer(
        (_) async => const CommunityStats(
          totalUsers: 0,
          totalClassifications: 0,
          totalPoints: 0,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storageService),
            Provider<CommunityService>.value(value: communityService),
          ],
          child: const MaterialApp(home: CommunityScreen()),
        ),
      );

      // Let the async load complete; avoid pumpAndSettle while progress indicators animate.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Community'), findsOneWidget);
    });

    testWidgets('shows loading and empty-state copy when no community data', (
      tester,
    ) async {
      final storageService = MockStorageService();
      final communityService = MockCommunityService();

      when(storageService.getCurrentUserProfile()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return null;
      });
      when(storageService.getAllClassifications())
          .thenAnswer((_) async => const []);

      when(communityService.initCommunity()).thenAnswer((_) async {});
      when(communityService.syncWithUserData(const [], null))
          .thenAnswer((_) async {});
      when(communityService.getFeedItems())
          .thenAnswer((_) async => <CommunityFeedItem>[]);
      when(communityService.getStats()).thenAnswer(
        (_) async => const CommunityStats(
          totalUsers: 0,
          totalClassifications: 0,
          totalPoints: 0,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storageService),
            Provider<CommunityService>.value(value: communityService),
          ],
          child: const MaterialApp(home: CommunityScreen()),
        ),
      );

      await tester.pump();

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('No community activity yet'), findsOneWidget);
      expect(find.text('Pull to refresh'), findsWidgets);
    });
  });
}
