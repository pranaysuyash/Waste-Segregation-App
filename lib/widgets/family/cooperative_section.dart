import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/cooperative_mechanics.dart';
import '../../services/cooperative_mechanics_service.dart';
import '../../utils/constants.dart';
import '../../utils/time_ago.dart';

/// Renders the four cooperative-mechanics cards on the family dashboard
/// (household streak, shared goals, tasks, team challenges) and owns the
/// creation sheets for admins.
///
/// Designed as a self-contained StatefulWidget so the parent dashboard
/// screen does not need to manage cooperative streams or creation state.
class CooperativeMechanicsSection extends StatefulWidget {
  const CooperativeMechanicsSection({
    super.key,
    required this.familyId,
    required this.cooperativeMechanicsService,
    this.isAdmin = false,
    this.currentUserId,
  });

  final String familyId;
  final CooperativeMechanicsService cooperativeMechanicsService;

  /// True when the currently signed-in user is a family admin. Controls
  /// whether the "New Goal / Task / Challenge" creation entry points are shown.
  final bool isAdmin;

  /// UID of the currently signed-in user, forwarded as the `createdBy`
  /// field when creating goals and tasks.
  final String? currentUserId;

  @override
  State<CooperativeMechanicsSection> createState() =>
      _CooperativeMechanicsSectionState();
}

class _CooperativeMechanicsSectionState
    extends State<CooperativeMechanicsSection> {
  late Stream<HouseholdStreak?> _streakStream;
  late Stream<List<FamilyGoal>> _goalsStream;
  late Stream<List<FamilyTask>> _tasksStream;
  late Stream<List<CooperativeChallenge>> _challengesStream;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  @override
  void didUpdateWidget(CooperativeMechanicsSection old) {
    super.didUpdateWidget(old);
    if (old.familyId != widget.familyId ||
        old.cooperativeMechanicsService != widget.cooperativeMechanicsService) {
      _initStreams();
    }
  }

  void _initStreams() {
    _streakStream =
        widget.cooperativeMechanicsService.watchStreak(widget.familyId);
    _goalsStream =
        widget.cooperativeMechanicsService.watchActiveGoals(widget.familyId);
    _tasksStream =
        widget.cooperativeMechanicsService.watchPendingTasks(widget.familyId);
    _challengesStream =
        widget.cooperativeMechanicsService.watchActiveChallenges(widget.familyId);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHouseholdStreakSection(),
        const SizedBox(height: AppTheme.paddingLarge),
        _buildActiveGoalsSection(),
        const SizedBox(height: AppTheme.paddingLarge),
        _buildActiveTasksSection(),
        const SizedBox(height: AppTheme.paddingLarge),
        _buildCoopChallengesSection(),
      ],
    );
  }

  // ── Streak ────────────────────────────────────────────────────────────────

  Widget _buildHouseholdStreakSection() {
    return StreamBuilder<HouseholdStreak?>(
      stream: _streakStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final streak = snap.data;
        if (streak == null || streak.currentStreak == 0) {
          return const SizedBox.shrink();
        }
        return Card(
          key: const Key('family-dashboard-household-streak-card'),
          elevation: AppTheme.elevationSm,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 32)),
                const SizedBox(width: AppTheme.paddingRegular),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Household Streak',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${streak.currentStreak} day${streak.currentStreak == 1 ? '' : 's'} — '
                        'someone scanned today keeps the streak alive!',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${streak.currentStreak}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Goals ─────────────────────────────────────────────────────────────────

  Widget _buildActiveGoalsSection() {
    return StreamBuilder<List<FamilyGoal>>(
      stream: _goalsStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final goals = snap.data ?? [];
        if (goals.isEmpty && !widget.isAdmin) return const SizedBox.shrink();
        return Card(
          key: const Key('family-dashboard-goals-card'),
          elevation: AppTheme.elevationSm,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🎯 ', style: TextStyle(fontSize: 18)),
                    Text(
                      'Shared Goals',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${goals.length} active',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                    ),
                    if (widget.isAdmin) ...[
                      const SizedBox(width: 8),
                      _addButton(
                        tooltip: 'Create goal',
                        onTap: () => _showCreateGoalSheet(context),
                      ),
                    ],
                  ],
                ),
                if (goals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.paddingSmall),
                    child: Text(
                      'No active goals yet. Tap + to create the first one.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.textSecondaryColor),
                    ),
                  )
                else ...[
                  const SizedBox(height: AppTheme.paddingRegular),
                  ...goals.take(3).map(_buildGoalTile),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalTile(FamilyGoal goal) {
    final pct = goal.progressFraction;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(goal.iconEmoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  goal.title,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${goal.currentValue}/${goal.targetValue}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textSecondaryColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 1.0 ? Colors.green : AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  Widget _buildActiveTasksSection() {
    return StreamBuilder<List<FamilyTask>>(
      stream: _tasksStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final tasks = snap.data ?? [];
        if (tasks.isEmpty && !widget.isAdmin) return const SizedBox.shrink();
        return Card(
          key: const Key('family-dashboard-tasks-card'),
          elevation: AppTheme.elevationSm,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('✅ ', style: TextStyle(fontSize: 18)),
                    Text(
                      'Household Tasks',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${tasks.length} pending',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                    ),
                    if (widget.isAdmin) ...[
                      const SizedBox(width: 8),
                      _addButton(
                        tooltip: 'Create task',
                        onTap: () => _showCreateTaskSheet(context),
                      ),
                    ],
                  ],
                ),
                if (tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.paddingSmall),
                    child: Text(
                      'No tasks yet. Tap + to assign one.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.textSecondaryColor),
                    ),
                  )
                else ...[
                  const SizedBox(height: AppTheme.paddingRegular),
                  ...tasks.take(3).map(_buildTaskTile),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskTile(FamilyTask task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
      child: Row(
        children: [
          Text(task.iconEmoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'For: ${_taskRoleLabel(task.targetRole)} · '
                  'Due: ${TimeAgo.format(task.dueDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: task.isOverdue
                            ? Colors.red
                            : AppTheme.textSecondaryColor,
                      ),
                ),
              ],
            ),
          ),
          if (task.pointsReward > 0)
            Chip(
              label: Text('+${task.pointsReward} pts'),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  String _taskRoleLabel(TaskTargetRole role) {
    switch (role) {
      case TaskTargetRole.anyAdult:
        return 'Any adult';
      case TaskTargetRole.adminOnly:
        return 'Admin';
      case TaskTargetRole.child:
        return 'Child';
      case TaskTargetRole.anyMember:
        return 'Anyone';
      case TaskTargetRole.specificMember:
        return 'Assigned member';
    }
  }

  // ── Challenges ────────────────────────────────────────────────────────────

  Widget _buildCoopChallengesSection() {
    return StreamBuilder<List<CooperativeChallenge>>(
      stream: _challengesStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final challenges = snap.data ?? [];
        if (challenges.isEmpty) return const SizedBox.shrink();
        return Card(
          key: const Key('family-dashboard-coop-challenges-card'),
          elevation: AppTheme.elevationSm,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🤝 ', style: TextStyle(fontSize: 18)),
                    Text(
                      'Team Challenges',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${challenges.length} active',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.paddingRegular),
                ...challenges.take(2).map(_buildChallengeTile),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChallengeTile(CooperativeChallenge challenge) {
    final pct = challenge.progressFraction;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingRegular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(challenge.iconEmoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  challenge.title,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${challenge.participantCount}/${challenge.minParticipants} members',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: challenge.hasMinParticipants
                          ? Colors.green
                          : Colors.orange,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 1.0 ? Colors.green : Colors.teal,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${challenge.totalProgress}/${challenge.targetValue} · '
            'Ends ${TimeAgo.format(challenge.endDate)}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _addButton({required String tooltip, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Tooltip(
        message: tooltip,
        child: const Icon(Icons.add_circle_outline, size: 20),
      ),
    );
  }

  // ── Creation sheets ───────────────────────────────────────────────────────

  void _showCreateGoalSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CreateGoalSheet(
        familyId: widget.familyId,
        createdBy: widget.currentUserId ?? '',
        service: widget.cooperativeMechanicsService,
      ),
    );
  }

  void _showCreateTaskSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CreateTaskSheet(
        familyId: widget.familyId,
        createdBy: widget.currentUserId ?? '',
        service: widget.cooperativeMechanicsService,
      ),
    );
  }
}

// ── Goal creation sheet ───────────────────────────────────────────────────────

class CreateGoalSheet extends StatefulWidget {
  const CreateGoalSheet({
    super.key,
    required this.familyId,
    required this.createdBy,
    required this.service,
  });

  final String familyId;
  final String createdBy;
  final CooperativeMechanicsService service;

  @override
  State<CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<CreateGoalSheet> {
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  GoalType _type = GoalType.scanCount;
  DateTime? _deadline;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final targetText = _targetController.text.trim();
    if (title.isEmpty || targetText.isEmpty) {
      setState(() => _error = 'Title and target are required.');
      return;
    }
    final target = int.tryParse(targetText);
    if (target == null || target <= 0) {
      setState(() => _error = 'Target must be a positive number.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final deadline =
          _deadline ?? DateTime.now().add(const Duration(days: 30));
      final goal = FamilyGoal.create(
        familyId: widget.familyId,
        title: title,
        description: '',
        type: _type,
        targetValue: target,
        createdBy: widget.createdBy,
        deadline: deadline,
      );
      await widget.service.createGoal(goal);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Failed to create goal: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.paddingRegular,
        AppTheme.paddingLarge,
        AppTheme.paddingRegular,
        AppTheme.paddingRegular + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎯  New Shared Goal',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.paddingLarge),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Goal title',
              hintText: 'e.g. Recycle 100 items this month',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppTheme.paddingRegular),
          _GoalTypeSelector(
            selected: _type,
            onChanged: (t) => setState(() => _type = t),
          ),
          const SizedBox(height: AppTheme.paddingRegular),
          TextField(
            controller: _targetController,
            decoration: InputDecoration(
              labelText: _targetLabel(_type),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: AppTheme.paddingRegular),
          _DeadlinePicker(
            value: _deadline,
            onChanged: (d) => setState(() => _deadline = d),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppTheme.paddingSmall),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: AppTheme.paddingLarge),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create Goal'),
            ),
          ),
        ],
      ),
    );
  }

  String _targetLabel(GoalType type) {
    switch (type) {
      case GoalType.scanCount:
        return 'Target scans';
      case GoalType.disposalCount:
        return 'Target disposals';
      case GoalType.pointsTarget:
        return 'Target points';
      case GoalType.categoryFocus:
        return 'Target items in category';
      case GoalType.educationCompletion:
        return 'Target lessons';
      case GoalType.custom:
        return 'Target value';
    }
  }
}

class _GoalTypeSelector extends StatelessWidget {
  const _GoalTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  final GoalType selected;
  final ValueChanged<GoalType> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      (GoalType.scanCount, 'Scans'),
      (GoalType.disposalCount, 'Disposals'),
      (GoalType.pointsTarget, 'Points'),
    ];
    return Wrap(
      spacing: 8,
      children: options
          .map(
            (o) => ChoiceChip(
              label: Text(o.$2),
              selected: selected == o.$1,
              onSelected: (_) => onChanged(o.$1),
            ),
          )
          .toList(),
    );
  }
}

// ── Task creation sheet ───────────────────────────────────────────────────────

class CreateTaskSheet extends StatefulWidget {
  const CreateTaskSheet({
    super.key,
    required this.familyId,
    required this.createdBy,
    required this.service,
  });

  final String familyId;
  final String createdBy;
  final CooperativeMechanicsService service;

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  final _titleController = TextEditingController();
  final _pointsController = TextEditingController();
  TaskTargetRole _role = TaskTargetRole.anyMember;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title is required.');
      return;
    }
    final points = int.tryParse(_pointsController.text.trim()) ?? 0;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final task = FamilyTask.create(
        familyId: widget.familyId,
        title: title,
        description: '',
        targetRole: _role,
        createdBy: widget.createdBy,
        dueDate: _dueDate,
        pointsReward: points,
      );
      await widget.service.createTask(task);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Failed to create task: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.paddingRegular,
        AppTheme.paddingLarge,
        AppTheme.paddingRegular,
        AppTheme.paddingRegular + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✅  New Household Task',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.paddingLarge),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Task title',
              hintText: 'e.g. Sort plastics from last week',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppTheme.paddingRegular),
          Text(
            'Assign to',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 6),
          _RoleSelector(
            selected: _role,
            onChanged: (r) => setState(() => _role = r),
          ),
          const SizedBox(height: AppTheme.paddingRegular),
          TextField(
            controller: _pointsController,
            decoration: const InputDecoration(
              labelText: 'Points reward (optional)',
              hintText: '0',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: AppTheme.paddingRegular),
          _DeadlinePicker(
            label: 'Due date',
            value: _dueDate,
            onChanged: (d) => setState(() => _dueDate = d ?? _dueDate),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppTheme.paddingSmall),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: AppTheme.paddingLarge),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create Task'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.selected,
    required this.onChanged,
  });

  final TaskTargetRole selected;
  final ValueChanged<TaskTargetRole> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      (TaskTargetRole.anyMember, 'Anyone'),
      (TaskTargetRole.anyAdult, 'Adults'),
      (TaskTargetRole.adminOnly, 'Admin'),
      (TaskTargetRole.child, 'Child'),
    ];
    return Wrap(
      spacing: 8,
      children: options
          .map(
            (o) => ChoiceChip(
              label: Text(o.$2),
              selected: selected == o.$1,
              onSelected: (_) => onChanged(o.$1),
            ),
          )
          .toList(),
    );
  }
}

// ── Shared deadline picker ────────────────────────────────────────────────────

class _DeadlinePicker extends StatelessWidget {
  const _DeadlinePicker({
    required this.onChanged,
    this.label = 'Deadline (optional)',
    this.value,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now().add(const Duration(days: 7)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value == null
              ? 'Tap to set a deadline'
              : '${value!.day}/${value!.month}/${value!.year}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: value == null ? AppTheme.textSecondaryColor : null,
              ),
        ),
      ),
    );
  }
}
