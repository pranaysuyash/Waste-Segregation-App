import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/utils/constants.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';
import 'package:waste_segregation_app/providers/app_providers.dart';
import 'package:waste_segregation_app/screens/disposal_facilities_screen.dart';

class DisposalCompletionHistoryScreen extends ConsumerStatefulWidget {
  const DisposalCompletionHistoryScreen({super.key});

  @override
  ConsumerState<DisposalCompletionHistoryScreen> createState() =>
      _DisposalCompletionHistoryScreenState();
}

class _DisposalCompletionHistoryScreenState
    extends ConsumerState<DisposalCompletionHistoryScreen> {
  _CompletionHistoryFilter _selectedFilter = _CompletionHistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Disposal completion history')),
      body: userProfileAsync.when(
        data: (userProfile) {
          final allRecords = _buildHistoryItems(userProfile);
          if (allRecords.isEmpty) return _buildEmptyState(context);

          final records = _recordsForFilter(allRecords);
          return Column(
            children: [
              _buildFilterBar(context, allRecords),
              Expanded(
                child: records.isEmpty
                    ? _buildFilteredEmptyState(context)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: records.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return _CompletionHistoryRow(
                            key: ValueKey(
                              'completion_history_row_${record.classificationId}',
                            ),
                            record: record,
                            onUpdate: () => _openUpdateDialog(record),
                            onOpenFacilities:
                                record.followUpPolicyKey == 'facility_lookup'
                                    ? () => _openFacilitiesFinder(record)
                                    : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          return Center(
            child: Text(
              'Unable to load completion history.\n$error',
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checklist_rtl, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 10),
          const Text('No completion records yet'),
          const SizedBox(height: 4),
          const Text(
            'Complete a scan and save its handover status to see history.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredEmptyState(BuildContext context) {
    final filterLabel = _selectedFilter.label.toLowerCase();
    return Center(
      child: Text(
        'No $filterLabel completion records.',
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    List<_CompletionHistoryRecord> allRecords,
  ) {
    final followUpCount =
        allRecords.where((record) => record.followUpRequired).length;
    final blockedCount = allRecords.where((record) => record.isBlocked).length;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${allRecords.length} completion record${allRecords.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    key: const Key('completion_history_filter_all'),
                    label: 'All',
                    selected: _selectedFilter == _CompletionHistoryFilter.all,
                    onSelected: () => setState(
                      () => _selectedFilter = _CompletionHistoryFilter.all,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    key: const Key('completion_history_filter_follow_up'),
                    label: 'Follow-up ($followUpCount)',
                    selected:
                        _selectedFilter == _CompletionHistoryFilter.followUp,
                    onSelected: () => setState(
                      () => _selectedFilter = _CompletionHistoryFilter.followUp,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    key: const Key('completion_history_filter_blocked'),
                    label: 'Blocked ($blockedCount)',
                    selected:
                        _selectedFilter == _CompletionHistoryFilter.blocked,
                    onSelected: () => setState(
                      () => _selectedFilter = _CompletionHistoryFilter.blocked,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      key: key,
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }

  List<_CompletionHistoryRecord> _recordsForFilter(
    List<_CompletionHistoryRecord> records,
  ) {
    switch (_selectedFilter) {
      case _CompletionHistoryFilter.all:
        return records;
      case _CompletionHistoryFilter.followUp:
        return records.where((record) => record.followUpRequired).toList();
      case _CompletionHistoryFilter.blocked:
        return records.where((record) => record.isBlocked).toList();
    }
  }

  List<_CompletionHistoryRecord> _buildHistoryItems(UserProfile? profile) {
    final raw =
        profile?.preferences?[UserPreferenceKeys.disposalCompletionHistory];
    if (raw is! Map) return const [];

    final records = <_CompletionHistoryRecord>[];

    for (final entry in raw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! Map) continue;

      final map = Map<String, dynamic>.from(value);
      final status = map['status']?.toString() ?? 'not_recorded';
      final notes = map['notes']?.toString();
      final recordedAt = map['recordedAt']?.toString();
      final category = map['category']?.toString();
      final region = map['region']?.toString();
      final itemName = map['itemName']?.toString();
      final requiresSpecialDisposal = map['requiresSpecialDisposal'] == true;
      final followUp = map['followUp'];
      final followUpMap = followUp is Map
          ? Map<String, dynamic>.from(followUp)
          : const <String, dynamic>{};
      final followUpRequired = followUpMap['required'] == true ||
          map['followUpRequired'] == true ||
          status == 'blocked';
      final followUpPolicyKey = followUpMap['policyKey']?.toString() ??
          map['followUpPolicyKey']?.toString();
      final followUpAction = followUpMap['action']?.toString() ??
          map['followUpAction']?.toString();
      final pickupOptions = map['pickupOptions'] is List
          ? (map['pickupOptions'] as List)
              .whereType<Map>()
              .map(_CompletionPickupOption.fromMap)
              .whereType<_CompletionPickupOption>()
              .toList()
          : const <_CompletionPickupOption>[];
      final policySnapshot = map['policySnapshot'] is Map
          ? Map<String, String>.from(
              (map['policySnapshot'] as Map).map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              ),
            )
          : const <String, String>{};

      records.add(
        _CompletionHistoryRecord(
          classificationId: key,
          status: status,
          notes: notes?.isNotEmpty == true ? notes : null,
          recordedAt: _parseDateTime(recordedAt),
          recordedAtRaw: recordedAt,
          category: category,
          region: region,
          itemName: itemName,
          requiresSpecialDisposal: requiresSpecialDisposal,
          followUpRequired: followUpRequired,
          followUpPolicyKey: followUpPolicyKey,
          followUpAction: followUpAction,
          pickupOptions: pickupOptions,
          policySnapshot: policySnapshot,
        ),
      );
    }

    records.sort((a, b) {
      final aTime = a.recordedAt;
      final bTime = b.recordedAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return records;
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> _openUpdateDialog(_CompletionHistoryRecord record) async {
    if (!mounted) return;

    final notesController = TextEditingController(text: record.notes ?? '');
    var selectedStatus = _CompletionStatus.fromValue(record.status) ??
        _CompletionStatus.notRecorded;
    var followUpRequired = record.followUpRequired;
    var followUpPolicyKey = record.followUpPolicyKey;
    var followUpAction = record.followUpAction;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update completion for ${record.displayItemName}'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<_CompletionStatus>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      labelText: 'Completion status',
                    ),
                    items: _CompletionStatus.values
                        .map(
                          (status) => DropdownMenuItem<_CompletionStatus>(
                            value: status,
                            child: Text(status.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedStatus = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    key: const Key('completion_history_dialog_notes'),
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      labelText: 'Notes (optional)',
                    ),
                  ),
                  const SizedBox(height: 4),
                  CheckboxListTile(
                    key: const Key('completion_history_dialog_follow_up'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: followUpRequired ||
                        selectedStatus == _CompletionStatus.blocked,
                    title: const Text('Follow-up required'),
                    subtitle: const Text(
                      'Keep this record visible in the follow-up queue until the next step is handled.',
                    ),
                    onChanged: selectedStatus == _CompletionStatus.blocked
                        ? null
                        : (value) {
                            setState(() {
                              followUpRequired = value ?? false;
                              if (!followUpRequired) {
                                followUpPolicyKey = null;
                                followUpAction = null;
                              }
                            });
                          },
                  ),
                  if (record.pickupOptions.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: followUpPolicyKey,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        labelText: 'Follow-up route',
                      ),
                      items: record.pickupOptions
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option.policyKey,
                              child: Text(option.title),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        final option = record.pickupOptions.firstWhere(
                          (candidate) => candidate.policyKey == value,
                        );
                        setState(() {
                          followUpRequired = true;
                          followUpPolicyKey = option.policyKey;
                          followUpAction = option.title;
                        });
                      },
                    ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              key: const Key('completion_history_save_button'),
              onPressed: () async {
                await _saveCompletion(record.classificationId, selectedStatus,
                    notesController.text.trim(),
                    followUpRequired: followUpRequired ||
                        selectedStatus == _CompletionStatus.blocked,
                    followUpPolicyKey: followUpPolicyKey,
                    followUpAction: followUpAction);
                if (!mounted) return;
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _openFacilitiesFinder(_CompletionHistoryRecord record) {
    if (!mounted) return;
    WasteAppLogger.userAction('completion_history_open_facilities', context: {
      'classification_id': record.classificationId,
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DisposalFacilitiesScreen(),
      ),
    );
  }

  Future<void> _saveCompletion(
    String classificationId,
    _CompletionStatus status,
    String notes, {
    required bool followUpRequired,
    String? followUpPolicyKey,
    String? followUpAction,
  }) async {
    final storageService = ref.read(storageServiceProvider);
    final profile = await storageService.getCurrentUserProfile();
    if (profile == null) return;

    final preferences = Map<String, dynamic>.from(profile.preferences ?? {});
    final raw = preferences[UserPreferenceKeys.disposalCompletionHistory];
    final history = <String, dynamic>{};

    if (raw is Map) {
      for (final entry in raw.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key == null || value is! Map) continue;
        history[key.toString()] = Map<String, dynamic>.from(value);
      }
    }

    final existing = history[classificationId] as Map<String, dynamic>?;
    final existingFollowUp = existing?['followUp'];
    final followUp = existingFollowUp is Map
        ? Map<String, dynamic>.from(existingFollowUp)
        : <String, dynamic>{};
    final now = DateTime.now().toIso8601String();
    final persistedFollowUpRequired =
        followUpRequired || status == _CompletionStatus.blocked;
    followUp['required'] = persistedFollowUpRequired;
    followUp['policyKey'] = followUpPolicyKey;
    followUp['action'] = followUpAction;
    followUp['recordedAt'] = now;

    history[classificationId] = {
      ...?existing,
      'status': status.persistenceValue,
      'notes': notes,
      'recordedAt': now,
      'category': existing?['category'] as String?,
      'region': existing?['region'] as String?,
      'requiresSpecialDisposal': existing?['requiresSpecialDisposal'] == true,
      if (existing?['itemName'] != null) 'itemName': existing!['itemName'],
      'followUp': followUp,
    };

    preferences[UserPreferenceKeys.disposalCompletionHistory] = history;
    preferences[UserPreferenceKeys.disposalCompletionLast] = {
      'classificationId': classificationId,
      'status': status.persistenceValue,
      'recordedAt': now,
      'notes': notes,
      'followUpRequired': persistedFollowUpRequired,
      'followUpPolicyKey': followUpPolicyKey,
      'followUpAction': followUpAction,
    };

    await storageService
        .saveUserProfile(profile.copyWith(preferences: preferences));
    if (!mounted) return;

    ref.invalidate(userProfileProvider);
    WasteAppLogger.userAction('home_completion_history_update', context: {
      'classification_id': classificationId,
      'status': status.persistenceValue,
      'notes_present': notes.isNotEmpty,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completion status updated.'),
          duration: Duration(milliseconds: 900),
        ),
      );
    }
  }
}

class _CompletionHistoryRow extends StatelessWidget {
  const _CompletionHistoryRow({
    required this.record,
    required this.onUpdate,
    this.onOpenFacilities,
    super.key,
  });

  final _CompletionHistoryRecord record;
  final VoidCallback onUpdate;
  final VoidCallback? onOpenFacilities;

  @override
  Widget build(BuildContext context) {
    final status = _CompletionStatus.fromValue(record.status);
    final statusColor = _statusColor(context, status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.displayItemName,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Status: ${status?.label ?? 'Not recorded'}',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (record.followUpRequired)
                  const Chip(
                    avatar: Icon(Icons.flag_outlined, size: 16),
                    label: Text('Follow-up'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (record.category != null)
              Text('Category: ${record.category}',
                  style: const TextStyle(fontSize: 12)),
            if (record.region != null)
              Text('Area: ${record.region}',
                  style: const TextStyle(fontSize: 12)),
            if (record.recordedAtRaw != null)
              Text('Recorded: ${record.recordedAtRaw}',
                  style: const TextStyle(fontSize: 12)),
            if (record.notes != null && record.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Notes: ${record.notes}',
                    style: const TextStyle(fontSize: 12)),
              ),
            if (record.followUpRequired)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Follow-up required',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            if (record.followUpAction != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Next step: ${record.followUpAction}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            if (record.followUpPolicyKey != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Policy key: ${record.followUpPolicyKey}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onOpenFacilities != null)
                    OutlinedButton(
                      key: Key(
                        'completion_history_open_facilities_'
                        '${record.classificationId}',
                      ),
                      onPressed: onOpenFacilities,
                      child: const Text('Open facilities'),
                    ),
                  FilledButton(
                    key: Key(
                        'completion_history_update_${record.classificationId}'),
                    onPressed: onUpdate,
                    child: const Text('Update status'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, _CompletionStatus? status) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case _CompletionStatus.completed:
      case _CompletionStatus.handedOff:
        return Colors.green.shade700;
      case _CompletionStatus.blocked:
        return cs.error;
      case _CompletionStatus.pickupBooked:
        return cs.primary;
      case _CompletionStatus.prepared:
      case _CompletionStatus.notRecorded:
      case null:
        return cs.onSurface;
    }
  }
}

class _CompletionHistoryRecord {
  const _CompletionHistoryRecord({
    required this.classificationId,
    required this.status,
    required this.recordedAtRaw,
    this.notes,
    this.recordedAt,
    this.category,
    this.region,
    this.itemName,
    this.requiresSpecialDisposal = false,
    this.followUpRequired = false,
    this.followUpPolicyKey,
    this.followUpAction,
    this.pickupOptions = const [],
    this.policySnapshot = const {},
  });

  final String classificationId;
  final String status;
  final String? notes;
  final DateTime? recordedAt;
  final String? recordedAtRaw;
  final String? category;
  final String? region;
  final String? itemName;
  final bool requiresSpecialDisposal;
  final bool followUpRequired;
  final String? followUpPolicyKey;
  final String? followUpAction;
  final List<_CompletionPickupOption> pickupOptions;
  final Map<String, String> policySnapshot;

  bool get isBlocked => status == _CompletionStatus.blocked.persistenceValue;

  String get displayItemName =>
      itemName?.trim().isNotEmpty == true ? itemName! : classificationId;
}

class _CompletionPickupOption {
  const _CompletionPickupOption({
    required this.policyKey,
    required this.title,
    required this.detail,
  });

  final String policyKey;
  final String title;
  final String detail;

  static _CompletionPickupOption? fromMap(Map<dynamic, dynamic> raw) {
    final policyKey = raw['policyKey']?.toString().trim();
    final title = raw['title']?.toString().trim();
    final detail = raw['detail']?.toString().trim();
    if (policyKey == null ||
        policyKey.isEmpty ||
        title == null ||
        title.isEmpty ||
        detail == null ||
        detail.isEmpty) {
      return null;
    }
    return _CompletionPickupOption(
      policyKey: policyKey,
      title: title,
      detail: detail,
    );
  }
}

enum _CompletionHistoryFilter {
  all('All'),
  followUp('Follow-up'),
  blocked('Blocked');

  const _CompletionHistoryFilter(this.label);

  final String label;
}

enum _CompletionStatus {
  notRecorded('not_recorded', 'Not recorded'),
  prepared('prepared', 'Prepared for disposal'),
  pickupBooked('pickup_booked', 'Pickup booked'),
  handedOff('handed_off', 'Handed off'),
  completed('completed', 'Completed'),
  blocked('blocked', 'Blocked / follow-up needed');

  const _CompletionStatus(this.persistenceValue, this.label);

  final String persistenceValue;
  final String label;

  static _CompletionStatus? fromValue(String? value) {
    if (value == null) return null;
    for (final status in _CompletionStatus.values) {
      if (status.persistenceValue == value) return status;
    }
    return null;
  }
}
