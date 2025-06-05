import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/storage_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
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
    final storage = Provider.of<StorageService>(context, listen: false);
    final settings = await storage.getSettings();
    setState(() {
      _notificationsEnabled = settings['notifications'] ?? true;
      _educationalEnabled = settings['eduNotifications'] ?? true;
      _gamificationEnabled = settings['gamificationNotifications'] ?? true;
      _reminderEnabled = settings['reminderNotifications'] ?? true;
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final settings = await storage.getSettings();
    await storage.saveSettings(
      isDarkMode: settings['isDarkMode'] ?? false,
      isGoogleSyncEnabled: settings['isGoogleSyncEnabled'] ?? true,
      allowHistoryFeedback: settings['allowHistoryFeedback'],
      feedbackTimeframeDays: settings['feedbackTimeframeDays'],
      notifications: _notificationsEnabled,
      eduNotifications: _educationalEnabled,
      gamificationNotifications: _gamificationEnabled,
      reminderNotifications: _reminderEnabled,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
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
            title: const Text('Enable Notifications'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Educational Content'),
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
            title: const Text('Gamification'),
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
            title: const Text('Reminders'),
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
