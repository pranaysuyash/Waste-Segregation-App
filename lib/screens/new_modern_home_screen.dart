import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import '../utils/web_handler.dart';
import '../utils/permission_handler.dart';
import '../utils/constants.dart';
import '../models/waste_classification.dart';
import '../services/storage_service.dart';
import '../services/cloud_storage_service.dart';
import '../services/gamification_service.dart';
import '../services/ad_service.dart';
import '../services/community_service.dart';
import '../services/google_drive_service.dart';
import '../widgets/modern_ui/modern_cards.dart';
import '../widgets/modern_ui/modern_buttons.dart';
import '../widgets/modern_ui/modern_badges.dart';
import '../widgets/responsive_text.dart';
import '../widgets/gen_z_microinteractions.dart';
import '../widgets/dashboard_widgets.dart';
import 'image_capture_screen.dart';
import 'result_screen.dart';
import 'history_screen.dart';
import 'achievements_screen.dart';
import 'educational_content_screen.dart';
import 'waste_dashboard_screen.dart';
import 'disposal_facilities_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'social_screen.dart';
import 'auth_screen.dart';

// Riverpod providers
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final cloudStorageServiceProvider = Provider<CloudStorageService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return CloudStorageService(storageService);
});
final gamificationServiceProvider = Provider<GamificationService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final cloudStorageService = ref.watch(cloudStorageServiceProvider);
  return GamificationService(storageService, cloudStorageService);
});
final communityServiceProvider = Provider<CommunityService>((ref) => CommunityService());
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) => Connectivity().onConnectivityChanged);

// Navigation state provider
final _navIndexProvider = StateProvider<int>((ref) => 0);

class NewModernHomeScreen extends ConsumerStatefulWidget {
  const NewModernHomeScreen({Key? key, this.isGuestMode = false}) : super(key: key);
  final bool isGuestMode;

  @override
  NewModernHomeScreenState createState() => NewModernHomeScreenState();
}

class NewModernHomeScreenState extends ConsumerState<NewModernHomeScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  TutorialCoachMark? _coachMark;
  List<TargetFocus> _targets = [];
  bool _showedCoach = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFirstRunFlag();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _coachMark?.finish();
    super.dispose();
  }

  Future<void> _loadFirstRunFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showedCoach = prefs.getBool('home_coach_shown') ?? false;
      if (!_showedCoach && mounted) {
        // Delay to ensure widgets are built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              _prepareCoachTargets();
              _showCoachMark();
              prefs.setBool('home_coach_shown', true);
            }
          });
        });
      }
    } catch (e) {
      debugPrint('Error loading first run flag: $e');
    }
  }

  void _prepareCoachTargets() {
    _targets = [
      TargetFocus(
        identify: "takePhoto",
        keyTarget: GlobalKey(),
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Take Photo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20.0,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Text(
                    'Tap here to take a photo of your waste item for classification.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  void _showCoachMark() {
    if (_targets.isEmpty) return;
    
    try {
      _coachMark = TutorialCoachMark(
        targets: _targets,
        colorShadow: Colors.black,
        textSkip: "SKIP",
        paddingFocus: 10,
        opacityShadow: 0.8,
        onFinish: () {
          debugPrint('Tutorial finished');
        },
        onSkip: () {
          debugPrint('Tutorial skipped');
          return true;
        },
      );
      _coachMark?.show(context: context);
    } catch (e) {
      debugPrint('Error showing coach mark: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap in ProviderScope to fix the Riverpod error
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, child) {
          final connectivity = ref.watch(connectivityProvider);
          
          return Scaffold(
            appBar: AppBar(
              title: const Text('WasteWise'),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Consumer(
                    builder: (_, ref, __) {
                      final gamificationService = ref.watch(gamificationServiceProvider);
                      return FutureBuilder(
                        future: gamificationService.getProfile(),
                        builder: (context, snapshot) {
                          final points = snapshot.data?.points.total ?? 0;
                          return ModernBadge(
                            text: '$points',
                            icon: Icons.stars,
                            showPulse: false,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
              bottom: connectivity.when(
                data: (results) => results.contains(ConnectivityResult.none) 
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(24),
                      child: Container(
                        color: Colors.redAccent,
                        height: 24,
                        child: const Center(
                          child: Text(
                            'Offline Mode',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    )
                  : null,
                loading: () => null,
                error: (_, __) => null,
              ),
            ),
            body: _buildContent(),
            bottomNavigationBar: _buildBottomNav(),
            floatingActionButton: _buildSpeedDial(),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return Consumer(
      builder: (context, ref, child) {
        final currentIndex = ref.watch(_navIndexProvider);
        return IndexedStack(
          index: currentIndex,
          children: [
            HomeTab(picker: _picker),
            const AnalyticsTab(),
            const LearnTab(),
            const CommunityTab(),
            const ProfileTab(),
          ],
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Consumer(
      builder: (context, ref, child) {
        final currentIndex = ref.watch(_navIndexProvider);
        return BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          onTap: (index) => ref.read(_navIndexProvider.notifier).state = index,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school),
              label: 'Learn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Community',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpeedDial() {
    return SpeedDial(
      icon: Icons.menu,
      activeIcon: Icons.close,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.emoji_events),
          label: 'Achievements',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AchievementsScreen()),
          ),
        ),
        SpeedDialChild(
          child: const Icon(Icons.location_on),
          label: 'Disposal Facilities',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DisposalFacilitiesScreen()),
          ),
        ),
      ],
    );
  }
}

// Tab implementations
class HomeTab extends ConsumerWidget {
  final ImagePicker picker;
  const HomeTab({Key? key, required this.picker}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageService = ref.watch(storageServiceProvider);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ModernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'Take photo button',
                child: ElevatedButton.icon(
                  key: GlobalKey(),
                  onPressed: () async => _takePhoto(picker, context),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async => _pickImage(picker, context),
                icon: const Icon(Icons.photo_library),
                label: const Text('Upload Image'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ModernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Classifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<WasteClassification>>(
                future: storageService.getAllClassifications(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final classifications = snapshot.data ?? [];
                  if (classifications.isEmpty) {
                    return const Center(
                      child: Text('No classifications yet. Take your first photo!'),
                    );
                  }
                  
                  return Column(
                    children: classifications.take(3).map((classification) {
                      return ListTile(
                        leading: const Icon(Icons.recycling),
                        title: Text(classification.itemName),
                        subtitle: Text(classification.category),
                        trailing: Text(
                          '${classification.timestamp.day}/${classification.timestamp.month}',
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _takePhoto(ImagePicker picker, BuildContext context) async {
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageCaptureScreen.fromXFile(image),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  Future<void> _pickImage(ImagePicker picker, BuildContext context) async {
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageCaptureScreen.fromXFile(image),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }
}

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Analytics Content',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Coming soon! Track your waste classification analytics here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class LearnTab extends StatelessWidget {
  const LearnTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Educational Content',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Learn about waste management and environmental impact.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class CommunityTab extends ConsumerStatefulWidget {
  const CommunityTab({Key? key}) : super(key: key);

  @override
  ConsumerState<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends ConsumerState<CommunityTab> {
  @override
  Widget build(BuildContext context) {
    final communityService = ref.watch(communityServiceProvider);
    
    return FutureBuilder(
      future: communityService.getFeedItems(limit: 3),
      builder: (_, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Error loading community feed'),
              ],
            ),
          );
        }
        
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Community Feed',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Connect with other eco-warriors and share your progress.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Profile Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Manage your account and preferences.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
} 