// The main entry point that conditionally imports the appropriate implementation
export 'share_service.dart';
export 'share_service_native.dart' if (dart.library.html) 'share_service_web.dart';
