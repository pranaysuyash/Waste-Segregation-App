import 'dart:io';
import 'dart:typed_data' show Uint8List;

Future<bool> fileExists(String path) async => File(path).exists();
Future<void> writeFileBytes(String path, Uint8List bytes) async =>
    File(path).writeAsBytes(bytes, flush: true);
Future<Uint8List> readFileBytes(String path) async => File(path).readAsBytes();
Future<void> createDirectory(String dirPath) async {
  final dir = Directory(dirPath);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
}
