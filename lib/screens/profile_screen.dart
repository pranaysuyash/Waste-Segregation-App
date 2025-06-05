import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gamification.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../services/gamification_service.dart';
import '../utils/constants.dart';
import '../widgets/profile_summary_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_ProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadData();
  }

  Future<_ProfileData> _loadData() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final gamificationService =
        Provider.of<GamificationService>(context, listen: false);

    // Ensure points haven't fallen behind classifications
    await gamificationService.syncClassificationPoints();

    final userProfile = await storageService.getCurrentUserProfile();
    final classifications = await storageService.getAllClassifications();
    final gamProfile = await gamificationService.getProfile();

    return _ProfileData(
      userProfile,
      classifications.length,
      gamProfile.points,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: FutureBuilder<_ProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Failed to load profile'));
          }

          final data = snapshot.data!;
          final profile = data.userProfile;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: profile?.photoUrl != null &&
                          profile!.photoUrl!.isNotEmpty
                      ? NetworkImage(profile!.photoUrl!)
                      : null,
                  child: profile?.photoUrl == null ||
                          profile?.photoUrl?.isEmpty == true
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                const SizedBox(height: AppTheme.paddingRegular),
                if (profile?.displayName != null)
                  Text(
                    profile!.displayName!,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                if (profile?.email != null)
                  Text(
                    profile!.email!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: AppTheme.paddingRegular),
                ProfileSummaryCard(points: data.points),
                const SizedBox(height: AppTheme.paddingRegular),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Classifications'),
                    trailing: Text('${data.classificationCount}'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileData {
  _ProfileData(this.userProfile, this.classificationCount, this.points);
  
  final UserProfile? userProfile;
  final int classificationCount;
  final UserPoints points;
}

