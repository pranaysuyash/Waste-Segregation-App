import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import '../models/enhanced_family.dart';
import '../models/user_profile.dart';
import '../services/firebase_family_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'family_dashboard_screen.dart';

class FamilyCreationScreen extends StatefulWidget {
  const FamilyCreationScreen({super.key});

  @override
  State<FamilyCreationScreen> createState() => _FamilyCreationScreenState();
}

class _FamilyCreationScreenState extends State<FamilyCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  final _familyService = FirebaseFamilyService();
  bool _isLoading = false;

  @override
  void dispose() {
    _familyNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Family'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header illustration
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.family_restroom,
                    size: 60,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.paddingLarge),

              // Title and description
              const Text(
                'Create Your Family',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeExtraLarge,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.paddingSmall),

              const Text(
                'Start tracking waste reduction together! Create a family to collaborate with household members and compete in challenges.',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeRegular,
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.paddingLarge),

              // Family name input
              const Text(
                'Family Name',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              TextFormField(
                controller: _familyNameController,
                decoration: const InputDecoration(
                  hintText: 'Enter your family name',
                  prefixIcon: Icon(Icons.family_restroom),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a family name';
                  }
                  if (value.trim().length < 2) {
                    return 'Family name must be at least 2 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppTheme.paddingLarge),

              // Features list
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.paddingRegular),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Family Features',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingRegular),
                      _buildFeatureItem(
                        icon: Icons.analytics,
                        title: 'Shared Statistics',
                        description: 'View combined family waste reduction metrics',
                      ),
                      _buildFeatureItem(
                        icon: Icons.emoji_events,
                        title: 'Family Challenges',
                        description: 'Compete together in waste reduction challenges',
                      ),
                      _buildFeatureItem(
                        icon: Icons.share,
                        title: 'Classification Sharing',
                        description: 'Share and learn from each other\'s classifications',
                      ),
                      _buildFeatureItem(
                        icon: Icons.trending_up,
                        title: 'Progress Tracking',
                        description: 'Monitor individual and family progress over time',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.paddingLarge),

              // Create button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createFamily,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isLoading ? 'Creating...' : 'Create Family'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(AppTheme.paddingRegular),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.paddingRegular),

              // Info note
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingRegular),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue),
                    const SizedBox(width: AppTheme.paddingSmall),
                    Expanded(
                      child: Text(
                        'You will be the admin of this family and can invite other members. You can change these settings later.',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingRegular),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.paddingRegular),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeRegular,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createFamily() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final currentUser = await storageService.getCurrentUserProfile();

      if (currentUser == null) {
        throw Exception('User not found. Please sign in again.');
      }

      // Create the family
      final family = await _familyService.createFamily(
        _familyNameController.text.trim(),
        currentUser,
      );

      // Update user profile with family ID
      final updatedUser = currentUser.copyWith(
        familyId: family.id,
        role: UserRole.admin,
      );
      await storageService.saveUserProfile(updatedUser);

      if (mounted) {
        // Navigate to family dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const FamilyDashboardScreen(),
          ),
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Family "${family.name}" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create family: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
