import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/cloud_storage_service.dart';
import '../services/gamification_service.dart';
import '../services/analytics_service.dart';
import '../services/ad_service.dart';
import '../services/google_drive_service.dart';
import '../services/premium_service.dart';
import '../services/community_service.dart';
import '../services/enhanced_storage_service.dart';

/// Centralized service locator to eliminate duplicate service initialization patterns
class ServiceLocator {
  static StorageService getStorageService(BuildContext context) {
    return Provider.of<StorageService>(context, listen: false);
  }

  static CloudStorageService getCloudStorageService(BuildContext context) {
    return Provider.of<CloudStorageService>(context, listen: false);
  }

  static GamificationService getGamificationService(BuildContext context) {
    return Provider.of<GamificationService>(context, listen: false);
  }

  static AnalyticsService getAnalyticsService(BuildContext context) {
    return Provider.of<AnalyticsService>(context, listen: false);
  }

  static AdService getAdService(BuildContext context) {
    return Provider.of<AdService>(context, listen: false);
  }

  static GoogleDriveService getGoogleDriveService(BuildContext context) {
    return Provider.of<GoogleDriveService>(context, listen: false);
  }

  static PremiumService getPremiumService(BuildContext context) {
    return Provider.of<PremiumService>(context, listen: false);
  }

  static CommunityService getCommunityService(BuildContext context) {
    return Provider.of<CommunityService>(context, listen: false);
  }

  static EnhancedStorageService getEnhancedStorageService(
      BuildContext context) {
    return Provider.of<EnhancedStorageService>(context, listen: false);
  }

  /// Get multiple services at once to reduce boilerplate
  static ServiceBundle getServiceBundle(BuildContext context) {
    return ServiceBundle(
      storage: getStorageService(context),
      cloudStorage: getCloudStorageService(context),
      gamification: getGamificationService(context),
      analytics: getAnalyticsService(context),
      ad: getAdService(context),
      googleDrive: getGoogleDriveService(context),
      premium: getPremiumService(context),
      community: getCommunityService(context),
    );
  }
}

/// Bundle of commonly used services together
class ServiceBundle {
  const ServiceBundle({
    required this.storage,
    required this.cloudStorage,
    required this.gamification,
    required this.analytics,
    required this.ad,
    required this.googleDrive,
    required this.premium,
    required this.community,
  });
  final StorageService storage;
  final CloudStorageService cloudStorage;
  final GamificationService gamification;
  final AnalyticsService analytics;
  final AdService ad;
  final GoogleDriveService googleDrive;
  final PremiumService premium;
  final CommunityService community;
}
