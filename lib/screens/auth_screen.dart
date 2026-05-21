import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/google_drive_service.dart';
import '../utils/constants.dart';
import '../widgets/navigation_wrapper.dart';
import '../widgets/modern_ui/modern_cards.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle(BuildContext context) async {
    // Don't proceed if on web platform
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Sign In is not supported on web platform'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    // Capture navigator and scaffold messenger before async operation
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final googleDriveService =
          Provider.of<GoogleDriveService>(context, listen: false);

      final user = await googleDriveService.signIn();

      if (user != null && mounted) {
        await navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainNavigationWrapper(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Sign in failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _continueAsGuest(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MainNavigationWrapper(isGuestMode: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withValues(alpha: 0.8),
              AppTheme.secondaryColor,
              AppTheme.secondaryColor.withValues(alpha: 0.6),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.paddingLarge),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App logo
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Icon(
                            Icons.restore_from_trash,
                            size: 80,
                            color: AppTheme.primaryColor,
                          ),
                        ),

                        const SizedBox(height: AppTheme.paddingLarge),

                        // App title
                        const Text(
                          AppStrings.appName,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: AppTheme.paddingSmall),

                        // Community message
                        const Text(
                          'Join the Eco-Warriors Community',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: AppTheme.paddingSmall),

                        // App description
                        const Text(
                          AppStrings.welcomeMessage,
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeMedium,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: AppTheme.paddingLarge),

                        // Impact statistics cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildImpactCard(
                                '50K+',
                                'Items Classified',
                                Icons.recycling,
                              ),
                            ),
                            const SizedBox(width: AppTheme.paddingSmall),
                            Expanded(
                              child: _buildImpactCard(
                                '2.5T',
                                'CO₂ Saved',
                                Icons.eco,
                              ),
                            ),
                            const SizedBox(width: AppTheme.paddingSmall),
                            Expanded(
                              child: _buildImpactCard(
                                '10K+',
                                'Eco-Warriors',
                                Icons.people,
                              ),
                            ),
                          ],
                        ),

                        // Web platform warning
                        if (kIsWeb) ...[
                          const SizedBox(height: AppTheme.paddingRegular),
                          Container(
                            padding:
                                const EdgeInsets.all(AppTheme.paddingRegular),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                  AppTheme.borderRadiusRegular),
                              border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.white,
                                ),
                                SizedBox(width: AppTheme.paddingSmall),
                                Expanded(
                                  child: Text(
                                    'Web version has limited functionality. For full features, please use the mobile app.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: AppTheme.fontSizeSmall,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: AppTheme.paddingExtraLarge),

                        // Google Sign-in card (disabled on web)
                        _buildAuthCard(
                          onPressed: (kIsWeb || _isLoading)
                              ? null
                              : () => _signInWithGoogle(context),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryColor,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.g_mobiledata,
                                  size: 24,
                                  color: Colors.blue,
                                ),
                          title: kIsWeb
                              ? 'Sign In Unavailable on Web'
                              : AppStrings.signInWithGoogle,
                          subtitle: 'Sync your progress across devices',
                          backgroundColor: Colors.white,
                          textColor: Colors.black87,
                        ),

                        const SizedBox(height: AppTheme.paddingRegular),

                        // Guest mode card
                        _buildAuthCard(
                          onPressed: _isLoading
                              ? null
                              : () => _continueAsGuest(context),
                          icon: const Icon(
                            Icons.person_outline,
                            size: 24,
                            color: Colors.white,
                          ),
                          title: AppStrings.continueAsGuest,
                          subtitle: 'Try the app without signing in',
                          backgroundColor: Colors.transparent,
                          textColor: Colors.white,
                          borderColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAuthCard({
    required VoidCallback? onPressed,
    required Widget icon,
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ModernCard(
        onTap: onPressed,
        backgroundColor: backgroundColor,
        enableGlassmorphism: backgroundColor == Colors.transparent,
        borderRadius: AppTheme.borderRadiusLarge,
        border: borderColor != null
            ? Border.all(color: borderColor, width: 2)
            : null,
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Row(
          children: [
            icon,
            const SizedBox(width: AppTheme.paddingRegular),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: textColor.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactCard(String value, String label, IconData icon) {
    final theme = Theme.of(context);

    return ModernCard(
      enableGlassmorphism: true,
      backgroundColor: Colors.white,
      opacity: 0.16,
      borderRadius: AppTheme.borderRadiusRegular,
      padding: const EdgeInsets.all(AppTheme.paddingSmall),
      child: SizedBox(
        height: 110,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
