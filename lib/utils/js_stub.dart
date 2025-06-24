// This is a simplified stub file for non-web platforms
// It provides empty implementations of JS functionalities

// A simplified context object with empty method implementations
class Context {
  // Returns a Future that completes immediately
  Future<dynamic> callMethod(String method, [List<dynamic>? args]) async {
    return null;
  }
}

// The context object to be used as js.context
final Context context = Context();
