// Platform-conditional wrapper for file operations.
// This module exposes a small set of helpers that delegate to a
// platform-specific implementation (native / web) via conditional imports.

import 'dart:typed_data' show Uint8List;
import 'platform_file_io_io.dart'
    if (dart.library.html) 'platform_file_io_web.dart' as impl;

export 'platform_file_io_io.dart'
    if (dart.library.html) 'platform_file_io_web.dart';

Future<bool> fileExists(String path) => impl.fileExists(path);
Future<void> writeFileBytes(String path, Uint8List bytes) =>
    impl.writeFileBytes(path, bytes);
Future<Uint8List> readFileBytes(String path) => impl.readFileBytes(path);
Future<void> createDirectory(String dirPath) => impl.createDirectory(dirPath);
