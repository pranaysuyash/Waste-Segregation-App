import 'dart:js_interop';

@JS('window')
external JSObject get _window;

/// Check if window object is available
bool get hasWindowSupport {
  try {
    // External JSObject getters are never null, check by accessing a property
    _window.toString();
    return true;
  } catch (e) {
    return false;
  }
}

@JS('window.flutter')
external JSObject? get _windowFlutter;

@JS('window.flutter.buildConfig')
external JSObject? get _buildConfig;

bool get hasWebError {
  try {
    // Check if flutter object exists by checking buildConfig
    final config = _buildConfig;
    final flutter = _windowFlutter;
    return config == null || flutter == null;
  } catch (e) {
    return true;
  }
}

@JS('navigator')
external JSObject? get _navigator;

/// Check if navigator object is available
bool get hasNavigatorSupport {
  try {
    return _navigator != null;
  } catch (e) {
    return false;
  }
}

@JS('navigator.mediaDevices')
external JSObject? get _navigatorMediaDevices;

@JS('navigator.share')
external JSObject? get _navigatorShare;

@JS('navigator.clipboard')
external JSObject? get _navigatorClipboard;

bool get hasCameraSupport {
  try {
    return _navigatorMediaDevices != null;
  } catch (e) {
    return false;
  }
}

bool get hasShareSupport {
  try {
    return _navigatorShare != null;
  } catch (e) {
    return false;
  }
}

bool get hasClipboardSupport {
  try {
    return _navigatorClipboard != null;
  } catch (e) {
    return false;
  }
}

@JS('File')
external JSObject? get _file;

bool get hasFileSupport => _file != null;
