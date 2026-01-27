import 'dart:typed_data' show Uint8List;
import 'package:flutter/services.dart' show rootBundle;

Future<bool> fileExists(String path) async {
  try {
    await rootBundle.load(path);
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> writeFileBytes(String path, Uint8List bytes) async {
  throw UnsupportedError(
      'Writing to local filesystem is not supported on web.');
}

Future<Uint8List> readFileBytes(String path) async {
  final data = await rootBundle.load(path);
  return data.buffer.asUint8List();
}

Future<void> createDirectory(String dirPath) async {
  // No-op on web
  return;
}
