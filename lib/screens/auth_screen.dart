import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/google_drive_service.dart';
import '../utils/constants.dart';
import '../widgets/navigation_wrapper.dart';

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
    
    setState(() {
      _isLoading = true;
    });

    try {
      final googleDriveService =
          Provider.of<GoogleDriveService>(context, listen: false);
      final user = await googleDriveService.signIn();

      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationWrapper()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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
          builder: (context) => const MainNavigationWrapper(isGuestMode: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.paddingLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
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

                  // App description
                  const Text(
                    AppStrings.welcomeMessage,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Web platform warning
                  if (kIsWeb) ...[
                    const SizedBox(height: AppTheme.paddingRegular),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.paddingRegular),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
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

                  const SizedBox(height: AppTheme.paddingExtraLarge * 2),

                  // Google Sign-in button (disabled on web)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (kIsWeb || _isLoading) 
                          ? null 
                          : () => _signInWithGoogle(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.paddingRegular,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusRegular),
                        ),
                      ),
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
                          : Icon(
                              Icons
                                  .g_mobiledata, // Using a Material icon as fallback
                              size: 24,
                              color: Colors.blue,
                            ),
                      label: Text(
                        kIsWeb 
                            ? 'Sign In Unavailable on Web' 
                            : AppStrings.signInWithGoogle,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.paddingRegular),

                  // Guest mode button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => _continueAsGuest(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.paddingRegular,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusRegular),
                        ),
                      ),
                      child: const Text(
                        AppStrings.continueAsGuest,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.paddingLarge),

                  // Education note
                  Container(
                    padding: const EdgeInsets.all(AppTheme.paddingRegular),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusRegular),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.white,
                        ),
                        SizedBox(width: AppTheme.paddingSmall),
                        Expanded(
                          child: Text(
                            'Sign in to save your progress and sync data across devices',
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
