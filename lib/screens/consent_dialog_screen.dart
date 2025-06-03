import 'package:flutter/material.dart';
import '../services/user_consent_service.dart';
import '../utils/constants.dart';
import 'legal_document_screen.dart';

class ConsentDialogScreen extends StatelessWidget {
  
  const ConsentDialogScreen({
    super.key,
    required this.onConsent,
    required this.onDecline,
  });
  final VoidCallback onConsent;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            children: [
              const SizedBox(height: AppTheme.paddingLarge),
              
              // App logo or icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.restore_from_trash,
                  size: 60,
                  color: AppTheme.primaryColor,
                ),
              ),
              
              const SizedBox(height: AppTheme.paddingLarge),
              
              // Welcome text
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppTheme.paddingSmall),
              
              const Text(
                'Please review and accept our Privacy Policy and Terms of Service to continue',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppTheme.paddingLarge * 2),
              
              // Explanation text
              const Text(
                'We care about your privacy and data security. We only collect data necessary to provide our waste classification service and improve your experience.',
                style: TextStyle(fontSize: AppTheme.fontSizeRegular, color: AppTheme.textPrimaryColor),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppTheme.paddingRegular),
              
              // Links to legal documents
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LegalDocumentScreen(
                            title: 'Privacy Policy',
                            assetPath: 'assets/docs/privacy_policy.md',
                          ),
                        ),
                      );
                    },
                    child: const Text('Privacy Policy'),
                  ),
                  const Text(' | '),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LegalDocumentScreen(
                            title: 'Terms of Service',
                            assetPath: 'assets/docs/terms_of_service.md',
                          ),
                        ),
                      );
                    },
                    child: const Text('Terms of Service'),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Accept button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Record user consent and continue
                    final consentService = UserConsentService();
                    await consentService.recordAllConsents();
                    onConsent();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                    ),
                  ),
                  child: const Text(
                    'Accept & Continue',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: AppTheme.paddingRegular),
              
              // Decline button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onDecline,
                  child: const Text(
                    'Decline & Exit',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeRegular,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
