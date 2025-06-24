import 'package:flutter/material.dart';
import '../widgets/navigation_wrapper.dart';
import '../utils/constants.dart';

/// Demo screen to showcase different navigation styles
class NavigationDemoScreen extends StatelessWidget {
  const NavigationDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Styles Demo'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Your Navigation Style',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingSmall),
                const Text(
                  'Select from modern Android navigation styles inspired by popular apps',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingLarge * 2),

                Expanded(
                  child: ListView(
                    children: [
                      _buildNavigationStyleCard(
                        context,
                        'Glassmorphism Style',
                        'Modern iOS/Android style with glass effect and smooth animations',
                        Icons.blur_on,
                        Colors.blue,
                        NavigationStyle.glassmorphism,
                        'Used by: Spotify, Instagram, iOS Control Center',
                      ),
                      const SizedBox(height: AppTheme.paddingRegular),
                      _buildNavigationStyleCard(
                        context,
                        'Material 3 Design',
                        'Google\'s latest Material Design with elevated surfaces and bold colors',
                        Icons.design_services,
                        Colors.green,
                        NavigationStyle.material3,
                        'Used by: Google apps, Android 12+, Material You',
                      ),
                      const SizedBox(height: AppTheme.paddingRegular),
                      _buildNavigationStyleCard(
                        context,
                        'Floating Navigation',
                        'Elevated floating bar with rounded corners and subtle shadows',
                        Icons.fiber_manual_record,
                        Colors.purple,
                        NavigationStyle.floating,
                        'Used by: Discord, Figma, Modern productivity apps',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.paddingLarge),

                // Back to current navigation button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainNavigationWrapper(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Back to App'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.primaryColor),
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationStyleCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    NavigationStyle style,
    String examples,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AlternativeNavigationWrapper(
                style: style,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 28,
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
                            fontSize: AppTheme.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeRegular,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: color,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.paddingRegular),
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingSmall),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        examples,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
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
}
