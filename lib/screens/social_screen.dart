import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'community_screen.dart';
import 'family_dashboard_screen.dart';
import '../utils/constants.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const CommunityScreen(),
          SafeArea(
            top: false,
            left: false,
            right: false,
            child: FamilyDashboardScreen(
              analyticsService: ref.read(analyticsServiceProvider),
            ),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _currentIndex = 1),
              icon: const Icon(Icons.family_restroom),
              label: const Text(AppStrings.family),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 6,
            )
          : FloatingActionButton.extended(
              onPressed: () => setState(() => _currentIndex = 0),
              icon: const Icon(Icons.people),
              label: const Text(AppStrings.community),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 6,
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
