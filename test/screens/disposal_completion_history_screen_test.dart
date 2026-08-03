import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/providers/app_providers.dart';
import 'package:waste_segregation_app/screens/disposal_completion_history_screen.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/utils/constants.dart';

class _CompletionHistoryStorageService extends StorageService {
  _CompletionHistoryStorageService(this.profile);

  final UserProfile profile;
  UserProfile? lastSavedProfile;

  @override
  Future<UserProfile?> getCurrentUserProfile() async => profile;

  @override
  Future<void> saveUserProfile(UserProfile userProfile) async {
    lastSavedProfile = userProfile;
  }
}

void main() {
  testWidgets('shows empty completion history state', (tester) async {
    final userProfile = UserProfile(
      id: 'u1',
      preferences: {UserPreferenceKeys.disposalCompletionHistory: {}},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) async => userProfile),
          storageServiceProvider.overrideWithValue(
            _CompletionHistoryStorageService(userProfile),
          ),
        ],
        child: const MaterialApp(
          home: DisposalCompletionHistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No completion records yet'), findsOneWidget);
    expect(
      find.text('Complete a scan and save its handover status to see history.'),
      findsOneWidget,
    );
  });

  testWidgets('shows sorted completion records from profile', (tester) async {
    final now = DateTime.utc(2026, 8, 3, 12);
    final older = now.subtract(const Duration(hours: 6)).toIso8601String();
    final newer = now.toIso8601String();

    final userProfile = UserProfile(
      id: 'u1',
      preferences: {
        UserPreferenceKeys.disposalCompletionHistory: {
          'old-id': {
            'status': 'prepared',
            'notes': 'Pending review',
            'recordedAt': older,
            'itemName': 'Plastic Can',
            'category': 'Dry Waste',
            'region': 'Ward 1',
            'requiresSpecialDisposal': false,
          },
          'new-id': {
            'status': 'handed_off',
            'notes': 'Handed at gate',
            'recordedAt': newer,
            'itemName': 'Cardboard Box',
            'category': 'Dry Waste',
            'region': 'Ward 2',
            'requiresSpecialDisposal': false,
          },
        },
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) async => userProfile),
          storageServiceProvider.overrideWithValue(
            _CompletionHistoryStorageService(userProfile),
          ),
        ],
        child: const MaterialApp(
          home: DisposalCompletionHistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final list = tester.widgetList(find.byType(Card)).toList();
    expect(list, isNotEmpty);
    expect(find.text('Cardboard Box'), findsOneWidget);
    expect(find.text('Plastic Can'), findsOneWidget);
    expect(find.textContaining('Status: Handed off'), findsOneWidget);
    expect(
        find.textContaining('Status: Prepared for disposal'), findsOneWidget);
  });

  testWidgets('filters follow-up and blocked completion records',
      (tester) async {
    final userProfile = UserProfile(
      id: 'u1',
      preferences: {
        UserPreferenceKeys.disposalCompletionHistory: {
          'completed-id': {
            'status': 'completed',
            'recordedAt': '2026-08-03T12:00:00.000Z',
            'itemName': 'Cardboard Box',
          },
          'follow-up-id': {
            'status': 'prepared',
            'recordedAt': '2026-08-03T11:00:00.000Z',
            'itemName': 'Plastic Can',
            'followUp': {
              'required': true,
              'policyKey': 'collection_frequency',
              'action': 'Use scheduled collection',
            },
          },
          'blocked-id': {
            'status': 'blocked',
            'recordedAt': '2026-08-03T10:00:00.000Z',
            'itemName': 'Old Battery',
          },
        },
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) async => userProfile),
          storageServiceProvider.overrideWithValue(
            _CompletionHistoryStorageService(userProfile),
          ),
        ],
        child: const MaterialApp(
          home: DisposalCompletionHistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cardboard Box'), findsOneWidget);
    expect(find.text('Plastic Can'), findsOneWidget);
    expect(find.text('Old Battery'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('completion_history_filter_follow_up')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Plastic Can'), findsOneWidget);
    expect(find.text('Old Battery'), findsOneWidget);
    expect(find.text('Cardboard Box'), findsNothing);

    await tester.tap(
      find.byKey(const Key('completion_history_filter_blocked')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Old Battery'), findsOneWidget);
    expect(find.text('Plastic Can'), findsNothing);
    expect(find.text('Cardboard Box'), findsNothing);
    expect(find.textContaining('Status: Blocked / follow-up needed'),
        findsOneWidget);
  });

  testWidgets('updates completion status via dialog and saves profile',
      (tester) async {
    final storageService = _CompletionHistoryStorageService(
      UserProfile(
        id: 'u1',
        preferences: {
          UserPreferenceKeys.disposalCompletionHistory: {
            'id-1': {
              'status': 'prepared',
              'notes': '',
              'recordedAt': '2026-08-03T08:00:00.000Z',
              'itemName': 'Food Packaging',
              'category': 'Dry Waste',
              'region': 'Ward 3',
              'requiresSpecialDisposal': false,
              'policySnapshot': {
                'collection_frequency': 'weekly',
              },
              'pickupOptions': [
                {
                  'policyKey': 'collection_frequency',
                  'title': 'Scheduled collection',
                  'detail': 'weekly',
                },
              ],
              'followUp': {
                'required': false,
              },
            },
          },
        },
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider
              .overrideWith((ref) async => storageService.profile),
          storageServiceProvider.overrideWithValue(storageService),
        ],
        child: const MaterialApp(
          home: DisposalCompletionHistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('completion_history_update_id-1')));
    await tester.pumpAndSettle();

    expect(
      find.text('Update completion for Food Packaging'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('completion_history_dialog_notes')),
      'Placed outside',
    );
    await tester.tap(find.byKey(const Key('completion_history_save_button')));
    await tester.pumpAndSettle();

    expect(storageService.lastSavedProfile, isNotNull);
    final history = storageService.lastSavedProfile
            ?.preferences?[UserPreferenceKeys.disposalCompletionHistory]
        as Map<String, dynamic>?;
    final saved = history!['id-1'] as Map<String, dynamic>?;
    expect(saved, isNotNull);
    expect(saved!['notes'], 'Placed outside');
    expect(saved['status'], 'prepared');
    expect(saved['policySnapshot'],
        containsPair('collection_frequency', 'weekly'));
    expect(saved['pickupOptions'], isA<List<dynamic>>());
    expect(saved['followUp'], containsPair('required', false));
  });

  testWidgets(
      'shows facility follow-up action when policy key is facility_lookup',
      (tester) async {
    final storageService = _CompletionHistoryStorageService(
      UserProfile(
        id: 'u1',
        preferences: {
          UserPreferenceKeys.disposalCompletionHistory: {
            'facility-id': {
              'status': 'prepared',
              'recordedAt': '2026-08-03T13:00:00.000Z',
              'itemName': 'Battery Pack',
              'followUp': {
                'required': true,
                'policyKey': 'facility_lookup',
                'action': 'Find nearby disposal facilities',
              },
              'pickupOptions': [
                {
                  'policyKey': 'facility_lookup',
                  'title': 'Find nearby disposal facilities',
                  'detail': 'Open local facility directory',
                }
              ],
            },
            'standard-id': {
              'status': 'prepared',
              'recordedAt': '2026-08-03T12:00:00.000Z',
              'itemName': 'Glass Bottle',
              'followUp': {
                'required': true,
                'policyKey': 'collection_frequency',
                'action': 'Use scheduled collection',
              },
            },
          },
        },
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider
              .overrideWith((ref) async => storageService.profile),
          storageServiceProvider.overrideWithValue(storageService),
        ],
        child: const MaterialApp(
          home: DisposalCompletionHistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Battery Pack'), findsOneWidget);
    expect(find.text('Glass Bottle'), findsOneWidget);
    expect(
      find.byKey(
        const Key('completion_history_open_facilities_facility-id'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('completion_history_open_facilities_standard-id'),
      ),
      findsNothing,
    );
  });
}
