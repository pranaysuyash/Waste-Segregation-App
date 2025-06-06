import 'package:flutter/material.dart';
import 'community_screen.dart';
import 'family_dashboard_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 1 ? AppBar(
        title: const Text('Social'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
      ) : null,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          // Community Screen with its own tabs and AppBar
          CommunityScreen(),
          // Family Screen without AppBar (uses Social AppBar)
          SafeArea(
            top: false,
            left: false,
            right: false,
            child: FamilyDashboardScreen(showAppBar: false),
          ),
        ],
      ),
      // Floating action button for switching between sections when Community is active
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton.extended(
        onPressed: () => setState(() => _currentIndex = 1),
        icon: const Icon(Icons.family_restroom),
        label: const Text('Family'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ) : FloatingActionButton.extended(
        onPressed: () => setState(() => _currentIndex = 0),
        icon: const Icon(Icons.people),
        label: const Text('Community'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
