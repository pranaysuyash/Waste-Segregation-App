/// Version constants for the app
class AppVersion {
  // Semantic version components
  static const int major = 0;
  static const int minor = 1;
  static const int patch = 4;

  // Build number (incremented with each build)
  static const int buildNumber = 96;

  // Android version code
  static const int versionCode = major * 10000 + minor * 100 + patch;

  // Is this a beta version?
  static const bool isBeta = false;

  // Beta version suffix
  static const String betaSuffix = isBeta ? ' (beta)' : '';

  // Full semantic version string
  static String get semanticVersion => '$major.$minor.$patch';

  // Display version (for UI)
  static String get displayVersion => '$semanticVersion$betaSuffix';

  // Full version with build number (for debugging)
  static String get fullVersion => '$semanticVersion+$buildNumber$betaSuffix';
}
