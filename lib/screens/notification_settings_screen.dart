import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/l10n/app_localizations.dart';

import '../services/storage_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _educationalEnabled = true;
  bool _gamificationEnabled = true;
  bool _reminderEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final settings = await storage.getSettings();
      if (mounted) {
        setState(() {
          _notificationsEnabled = settings['notifications'] ?? true;
          _educationalEnabled = settings['eduNotifications'] ?? true;
          _gamificationEnabled = settings['gamificationNotifications'] ?? true;
          _reminderEnabled = settings['reminderNotifications'] ?? true;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final settings = await storage.getSettings();
      await storage.saveSettings(
        isDarkMode: settings['isDarkMode'] ?? false,
        isGoogleSyncEnabled: settings['isGoogleSyncEnabled'] ?? false,
        allowHistoryFeedback: settings['allowHistoryFeedback'] ?? true,
        feedbackTimeframeDays: settings['feedbackTimeframeDays'] ?? 7,
        notifications: _notificationsEnabled,
        eduNotifications: _educationalEnabled,
        gamificationNotifications: _gamificationEnabled,
        reminderNotifications: _reminderEnabled,
      );
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.notificationSettingsSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(t.notificationSettings),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(t.enableNotifications),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          const Divider(),
          SwitchListTile(
            title: Text(t.educationalContent),
            value: _educationalEnabled,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() {
                      _educationalEnabled = value;
                    });
                  }
                : null,
          ),
          SwitchListTile(
            title: Text(t.gamification),
            value: _gamificationEnabled,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() {
                      _gamificationEnabled = value;
                    });
                  }
                : null,
          ),
          SwitchListTile(
            title: Text(t.reminders),
            value: _reminderEnabled,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() {
                      _reminderEnabled = value;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
