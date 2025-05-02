// Web implementation - this file is only imported on web platforms
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as web_js;

// Re-export the web_js.context to match our stub interface
// The dart:js context has the same methods as our WebContext stub class
final context = web_js.context;