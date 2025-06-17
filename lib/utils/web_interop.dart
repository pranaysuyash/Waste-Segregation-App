import 'dart:js_interop';

@JS('window')
external JSObject get _window;

extension type _Window(JSObject o) {
  external _Flutter get _flutter;
}

extension type _Flutter(JSObject o) {
  external JSObject? get buildConfig;
}

bool get hasWebError {
  try {
    return (_window as _Window)._flutter.buildConfig == null;
  } catch (e) {
    return true;
  }
}

@JS('navigator')
external JSObject? get _navigator;

extension type _Navigator(JSObject o) {
  external JSObject? get mediaDevices;
  external JSObject? get share;
  external JSObject? get clipboard;
}

bool get hasCameraSupport {
  try {
    return (_navigator as _Navigator?)?.mediaDevices != null;
  } catch (e) {
    return false;
  }
}

bool get hasShareSupport {
  try {
    return (_navigator as _Navigator?)?.share != null;
  } catch (e) {
    return false;
  }
}

bool get hasClipboardSupport {
  try {
    return (_navigator as _Navigator?)?.clipboard != null;
  } catch (e) {
    return false;
  }
}

@JS('File')
external JSObject? get _file;

bool get hasFileSupport => _file != null; 