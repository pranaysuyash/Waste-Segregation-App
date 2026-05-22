import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/l10n/app_localizations.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/widgets/settings/setting_tile.dart';
import 'package:waste_segregation_app/widgets/settings/settings_theme.dart';

class FeedbackSettingsSection extends StatefulWidget {
  const FeedbackSettingsSection({super.key});

  @override
  State<FeedbackSettingsSection> createState() =>
      _FeedbackSettingsSectionState();
}

class _FeedbackSettingsSectionState extends State<FeedbackSettingsSection> {
  bool _isLoading = true;
  bool _allowHistoryFeedback = true;
  int _feedbackTimeframeDays = 7;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final settings = await storageService.getSettings();
      if (!mounted) return;
      setState(() {
        _allowHistoryFeedback = settings['allowHistoryFeedback'] ?? true;
        _feedbackTimeframeDays = settings['feedbackTimeframeDays'] ?? 7;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleHistoryFeedback(bool value) async {
    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final settings = await storageService.getSettings();
      await storageService.saveSettings(
        isDarkMode: settings['isDarkMode'] ?? false,
        isGoogleSyncEnabled: settings['isGoogleSyncEnabled'] ?? false,
        allowHistoryFeedback: value,
      );
      if (!mounted) return;
      setState(() {
        _allowHistoryFeedback = value;
      });
    } catch (e) {
      if (!mounted) return;
      SettingsTheme.showErrorSnackBar(
          context, 'Failed to toggle history feedback: $e');
    }
  }

  Future<void> _updateFeedbackTimeframe(int value) async {
    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final settings = await storageService.getSettings();
      await storageService.saveSettings(
        isDarkMode: settings['isDarkMode'] ?? false,
        isGoogleSyncEnabled: settings['isGoogleSyncEnabled'] ?? false,
        allowHistoryFeedback: settings['allowHistoryFeedback'] ?? true,
        feedbackTimeframeDays: value,
      );
      if (!mounted) return;
      setState(() {
        _feedbackTimeframeDays = value;
      });
    } catch (e) {
      if (!mounted) return;
      SettingsTheme.showErrorSnackBar(
          context, 'Failed to update feedback timeframe: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: t.feedbackSettings),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Failed to load feedback settings',
                style: TextStyle(color: SettingsTheme.dangerColor),
              ),
            ),
          )
        else ...[
          SettingToggleTile(
            icon: Icons.history,
            iconColor: SettingsTheme.navigationColor,
            title: t.allowFeedbackRecentHistory,
            subtitle: _allowHistoryFeedback
                ? 'Can provide feedback on recent classifications from history'
                : 'Can only provide feedback on new classifications',
            value: _allowHistoryFeedback,
            onChanged: _toggleHistoryFeedback,
          ),
          if (_allowHistoryFeedback)
            Card(
              margin: SettingsTheme.tilePadding,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.blue,
                  ),
                ),
                title: Text(
                  t.feedbackTimeframe,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                subtitle: Text(t.feedbackTimeframeDays(_feedbackTimeframeDays)),
                trailing: DropdownButton<int>(
                  value: _feedbackTimeframeDays,
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem(value: 1, child: Text(t.oneDay)),
                    DropdownMenuItem(value: 3, child: Text(t.threeDays)),
                    DropdownMenuItem(value: 7, child: Text(t.sevenDays)),
                    DropdownMenuItem(value: 14, child: Text(t.fourteenDays)),
                    DropdownMenuItem(value: 30, child: Text(t.thirtyDays)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _updateFeedbackTimeframe(value);
                    }
                  },
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _allowHistoryFeedback
                  ? 'Perfect for scanning multiple items quickly and providing feedback later when you have more time!'
                  : 'Feedback is only available immediately after classification.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
