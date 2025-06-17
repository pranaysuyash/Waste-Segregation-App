// Platform-agnostic web utilities
// This file imports the appropriate implementation based on the platform

export 'web_interop.dart' if (dart.library.io) 'web_interop_stub.dart';

// This is the stub implementation for web-specific utilities.
// The actual implementation is in `web_interop.dart`.

// ignore: camel_case_types
class web_interop {
  static bool get hasWebError => false;
  static bool get hasCameraSupport => false;
  static bool get hasShareSupport => false;
  static bool get hasClipboardSupport => false;
  static bool get hasFileSupport => false;
}
