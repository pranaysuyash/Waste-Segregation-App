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

class NewModernHomeScreen extends ConsumerStatefulWidget {
  const NewModernHomeScreen({Key? key, this.isGuestMode = false}) : super(key: key);
  final bool isGuestMode;

  @override
  NewModernHomeScreenState createState() => NewModernHomeScreenState();
}

class NewModernHomeScreenState extends ConsumerState<NewModernHomeScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  late TutorialCoachMark _coachMark;
  List<TargetFocus> _targets = [];
  bool _showedCoach = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prepareCoachTargets();
    _loadFirstRunFlag();
  }

  Future<void> _loadFirstRunFlag() async {
    final prefs = await SharedPreferences.getInstance();
    _showedCoach = prefs.getBool('home_coach_shown') ?? false;
    if (!_showedCoach) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showCoachMark());
      prefs.setBool('home_coach_shown', true);
    }
  }

  void _prepareCoachTargets() {
    _targets = [
      TargetFocus(
        identify: "takePhoto",
        keyTarget: GlobalObjectKey('takePhoto'),
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Text(
              'Tap here to take a photo of your waste.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "bottomNav",
        keyTarget: GlobalObjectKey('bottomNav'),
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Text(
              'Use the bottom menu to navigate the app.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    ];
  }

  void _showCoachMark() {
    _coachMark = TutorialCoachMark(
      targets: _targets,
      colorShadow: Colors.black54,
      textSkip: "SKIP",
      onFinish: () {},
      onClickTarget: (target) {},
    );
    _coachMark.show(context: context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = ref.watch(connectivityProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('WasteWise', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: connectivity.when(
          data: (results) => results.contains(ConnectivityResult.none) 
            ? PreferredSize(
                preferredSize: Size.fromHeight(24),
                child: Container(
                  color: Colors.redAccent,
                  height: 24,
                  child: Center(child: Text('Offline Mode', style: TextStyle(color: Colors.white))),
                ),
              )
            : null,
          loading: () => null,
          error: (_, __) => null,
        ),
        actions: [
          // Inline badge display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Consumer(
              builder: (_, ref, __) {
                final gamificationService = ref.watch(gamificationServiceProvider);
                final profile = gamificationService.currentProfile;
                return ModernBadge(
                  text: '${profile?.points.total ?? 0}',
                  icon: Icons.stars,
                  showPulse: false, // Simplified for now
                );
              },
            ),
          ),
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (_) => [
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuItem(value: 'help', child: Text('Help & Support')),
              PopupMenuItem(value: 'about', child: Text('About')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Text('Sign Out')),
            ],
          )
        ],
      ),
      body: _buildContent(),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: SpeedDial(
        icon: Icons.menu,
        backgroundColor: Theme.of(context).primaryColor,
        children: [
          SpeedDialChild(
            child: Icon(Icons.emoji_events),
            label: 'Achievements',
            onTap: _navigateToAchievements,
          ),
          SpeedDialChild(
            child: Icon(Icons.location_on),
            label: 'Disposal Facilities',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DisposalFacilitiesScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Lazy load tabs via IndexedStack
    return IndexedStack(
      index: ref.watch(_navIndexProvider),
      children: [
        HomeTab(picker: _picker),
        AnalyticsTab(),
        LearnTab(),
        CommunityTab(),
        ProfileTab(),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      key: GlobalObjectKey('bottomNav'),
      currentIndex: ref.watch(_navIndexProvider),
      onTap: (idx) => ref.read(_navIndexProvider.notifier).state = idx,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
        BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Learn'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      type: BottomNavigationBarType.fixed,
    );
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'settings':
        Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
        break;
      case 'help':
        _showHelp();
        break;
      case 'about':
        _showAbout();
        break;
      case 'logout':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AuthScreen()));
        break;
    }
  }

  void _navigateToAchievements() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AchievementsScreen()));
  }

  void _showHelp() { 
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Help & Support'),
        content: Text('For help and support, please visit our website or contact us at support@wastewise.com'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showAbout() { 
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About WasteWise'),
        content: Text('WasteWise v2.1.0\nSmart waste classification and management app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Navigation index provider
final _navIndexProvider = StateProvider<int>((_) => 0);

class HomeTab extends ConsumerWidget {
  final ImagePicker picker;
  HomeTab({Key? key, required this.picker}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageService = ref.watch(storageServiceProvider);
    
    return ListView(padding: EdgeInsets.all(16), children: [
      ModernCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: 'Take photo button',
              child: ElevatedButton.icon(
                key: GlobalObjectKey('takePhoto'),
                onPressed: () async => _take(picker, context),
                icon: Icon(Icons.camera_alt),
                label: Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ),
            SizedBox(height: 8),
            Semantics(
              label: 'Upload image button',
              child: ElevatedButton.icon(
                onPressed: () async => _upload(picker, context),
                icon: Icon(Icons.photo_library),
                label: Text('Upload'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 16),
      SectionHeader(title: "Today's Impact"),
      FutureBuilder<List<WasteClassification>>(
        future: storageService.getAllClassifications(),
        builder: (context, snapshot) {
          final todayCount = snapshot.hasData 
            ? snapshot.data!.where((c) => 
                DateTime.now().difference(c.timestamp).inDays == 0
              ).length 
            : 0;
          return TodaysImpactGoal(
            currentClassifications: todayCount,
          );
        },
      ),
      SizedBox(height: 16),
      SectionHeader(title: 'Recent Classifications'),
      FutureBuilder<List<WasteClassification>>(
        future: storageService.getAllClassifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.recycling, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No classifications yet'),
                    Text('Start by taking a photo of waste to classify!'),
                  ],
                ),
              ),
            );
          }
          final recentClassifications = snapshot.data!.take(3).toList();
          return Column(
            children: recentClassifications.map((classification) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Icon(Icons.recycling, color: Colors.white),
                ),
                title: Text(classification.itemName),
                subtitle: Text(classification.category),
                trailing: Text(
                  '${DateTime.now().difference(classification.timestamp).inHours}h ago',
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HistoryScreen()),
                ),
              ),
            )).toList(),
          );
        },
      ),
    ]);
  }

  Future<void> _take(ImagePicker picker, BuildContext context) async {
    final x = await picker.pickImage(source: ImageSource.camera);
    if (x != null) Navigator.push(context, MaterialPageRoute(builder: (_) => ImageCaptureScreen(imageFile: File(x.path))));
  }

  Future<void> _upload(ImagePicker picker, BuildContext context) async {
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x != null) Navigator.push(context, MaterialPageRoute(builder: (_) => ImageCaptureScreen(imageFile: File(x.path))));
  }
}

class AnalyticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Analytics Content', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 8),
          Text('Coming soon! Track your waste classification analytics here.'),
        ],
      ),
    );
  }
}

class LearnTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Educational Content', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 8),
          Text('Coming soon! Learn about waste management and recycling.'),
        ],
      ),
    );
  }
}

class CommunityTab extends ConsumerStatefulWidget {
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
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Error loading community feed'),
                TextButton(
                  onPressed: () => setState(() {}),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No community activity'),
                SizedBox(height: 8),
                Text('Be the first to share your waste classification!'),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data.length,
          itemBuilder: (context, index) {
            final item = snapshot.data[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text(item.title ?? 'Community Activity'),
                subtitle: Text(item.description ?? 'No description'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => SocialScreen())
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ProfileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Profile Settings', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 8),
          Text('Manage your profile and preferences here.'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => ProfileScreen())
            ),
            child: Text('Go to Profile'),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({required this.title});
  
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );
} 