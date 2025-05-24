import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/premium_service.dart';
import '../providers/theme_provider.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  ThemeMode? _currentThemeMode;

  @override
  void initState() {
    super.initState();
    // Initialize immediately with the current theme provider value
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _currentThemeMode = themeProvider.themeMode;
  }

  @override
  Widget build(BuildContext context) {
    final premiumService = Provider.of<PremiumService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isPremium = premiumService.isPremiumFeature('theme_customization');
    
    // Ensure _currentThemeMode is always set
    _currentThemeMode ??= themeProvider.themeMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
      ),
      body: ListView(
        children: [
          // Theme Mode Selection
          ListTile(
            leading: const Icon(Icons.brightness_auto),
            title: const Text('System Default'),
            subtitle: const Text('Follow system theme settings'),
            isThreeLine: false,
            trailing: Radio<ThemeMode>(
              value: ThemeMode.system,
              groupValue: _currentThemeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  setState(() {
                    _currentThemeMode = value;
                  });
                  _updateThemeMode(value);
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.light_mode),
            title: const Text('Light Theme'),
            subtitle: const Text('Always use light theme'),
            isThreeLine: false,
            trailing: Radio<ThemeMode>(
              value: ThemeMode.light,
              groupValue: _currentThemeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  setState(() {
                    _currentThemeMode = value;
                  });
                  _updateThemeMode(value);
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Theme'),
            subtitle: const Text('Always use dark theme'),
            isThreeLine: false,
            trailing: Radio<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: _currentThemeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  setState(() {
                    _currentThemeMode = value;
                  });
                  _updateThemeMode(value);
                }
              },
            ),
          ),
          const Divider(),

          // Premium Features Section
          if (!isPremium) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Premium Features',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.palette, color: Colors.amber),
              title: const Text('Custom Themes'),
              subtitle: const Text('Create your own theme colors'),
              trailing: const Icon(Icons.workspace_premium, color: Colors.amber),
              onTap: () {
                _showPremiumFeaturePrompt(context);
              },
            ),
          ],
        ],
      ),
    );
  }

  void _updateThemeMode(ThemeMode mode) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.setThemeMode(mode);
  }

  void _showPremiumFeaturePrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text(
          'Custom themes are available with a premium subscription. Upgrade to unlock this feature!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to premium features screen
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
} 