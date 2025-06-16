import 'package:flutter/material.dart';
import 'dart:io';
import 'community_screen.dart';
import 'family_dashboard_screen.dart';
import '../utils/constants.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  int _currentIndex = 0;
  // Offset to keep the FAB above the bottom navigation bar
  static const double _fabBottomOffset = 72.0; // 56 nav bar height + 16 padding

  @override
  Widget build(BuildContext context) {
    // Calculate safe bottom padding for FAB
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isIOS = Platform.isIOS;
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          // Community Screen with its own tabs and AppBar
          CommunityScreen(),
          // Family Screen with its own AppBar
          SafeArea(
            top: false,
            left: false,
            right: false,
            child: FamilyDashboardScreen(),
          ),
        ],
      ),
      // Floating action button positioned to avoid bottom nav overlap
      floatingActionButton: Container(
        margin: EdgeInsets.only(
          bottom: (isIOS ? bottomPadding : 0) + _fabBottomOffset,
        ),
        child: _currentIndex == 0 
            ? FloatingActionButton.extended(
                onPressed: () => setState(() => _currentIndex = 1),
                icon: const Icon(Icons.family_restroom),
                label: const Text(AppStrings.family),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                elevation: 6,
              ) 
            : FloatingActionButton.extended(
                onPressed: () => setState(() => _currentIndex = 0),
                icon: const Icon(Icons.people),
                label: const Text(AppStrings.community),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                elevation: 6,
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
