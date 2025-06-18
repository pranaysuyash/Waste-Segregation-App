import 'package:shared_preferences/shared_preferences.dart';

class UserConsentService {
  static const String _privacyPolicyConsentKey = 'privacy_policy_consent';
  static const String _termsOfServiceConsentKey = 'terms_of_service_consent';
  static const String _privacyPolicyVersionKey = 'privacy_policy_version';
  static const String _termsOfServiceVersionKey = 'terms_of_service_version';
  
  // Current document versions
  static const String currentPrivacyPolicyVersion = '1.0.0';
  static const String currentTermsOfServiceVersion = '1.0.0';
  
  // Check if user has consented to privacy policy
  Future<bool> hasPrivacyPolicyConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_privacyPolicyConsentKey) ?? false;
    } catch (e) {
      return false;
    }
  }
  
  // Check if user has consented to terms of service
  Future<bool> hasTermsOfServiceConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_termsOfServiceConsentKey) ?? false;
    } catch (e) {
      return false;
    }
  }
  
  // Check if user needs to re-consent due to version changes
  Future<bool> needsReconsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPrivacyVersion = prefs.getString(_privacyPolicyVersionKey) ?? '';
      final savedTermsVersion = prefs.getString(_termsOfServiceVersionKey) ?? '';
      
      return (savedPrivacyVersion != currentPrivacyPolicyVersion) || 
             (savedTermsVersion != currentTermsOfServiceVersion);
    } catch (e) {
      // If we can't check versions, assume reconsent is needed
      return true;
    }
  }
  
  // Record user consent for privacy policy
  Future<void> recordPrivacyPolicyConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyPolicyConsentKey, true);
    await prefs.setString(_privacyPolicyVersionKey, currentPrivacyPolicyVersion);
  }
  
  // Record user consent for terms of service
  Future<void> recordTermsOfServiceConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_termsOfServiceConsentKey, true);
    await prefs.setString(_termsOfServiceVersionKey, currentTermsOfServiceVersion);
  }
  
  // Record both consents at once
  Future<void> recordAllConsents() async {
    await recordPrivacyPolicyConsent();
    await recordTermsOfServiceConsent();
  }
  
  // Check if user has given all required consents
  Future<bool> hasAllRequiredConsents() async {
    try {
      final hasPrivacy = await hasPrivacyPolicyConsent();
      final hasTerms = await hasTermsOfServiceConsent();
      final needsNew = await needsReconsent();
      
      return hasPrivacy && hasTerms && !needsNew;
    } catch (e) {
      // On web or if SharedPreferences fails, assume no consent
      // This allows the app to continue and show the consent dialog
      return false;
    }
  }
}
