import 'dart:js_interop';

@JS('window')
external JSObject get _window;

@JS('window.flutter')
external JSObject? get _windowFlutter;

@JS('window.flutter.buildConfig')
external JSObject? get _buildConfig;

bool get hasWebError {
  try {
    return _buildConfig == null;
  } catch (e) {
    return true;
  }
}

@JS('navigator')
external JSObject? get _navigator;

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
