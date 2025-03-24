// This file provides platform-agnostic stubs for web functionality
// Empty implementation - will be ignored on all platforms

// No-op context
class Context {
  bool hasProperty(String name) => false;
  dynamic callMethod(String method, [List<dynamic>? args]) => null;
  dynamic getProperty(String name) => null;
  void setProperty(String name, dynamic value) {}
}

// Export context
final context = Context();