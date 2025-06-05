import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'community_screen.dart';
import 'family_dashboard_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  int _currentIndex = 0;

  static final List<Widget> _screens = [
    const CommunityScreen(showAppBar: false),
    const FamilyDashboardScreen(showAppBar: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _currentIndex == 0
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Community',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _currentIndex == 0
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: _currentIndex == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _currentIndex == 1
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Family',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _currentIndex == 1
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: _currentIndex == 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: true,
        top: false,
        left: false,
        right: false,
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
    );
  }
}
