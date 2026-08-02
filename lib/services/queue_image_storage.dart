import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../utils/waste_app_logger.dart';

/// PRIVACY-09: Manages encrypted temp file storage for offline queue images.
///
/// Raw image bytes are never stored in Hive. Instead, images are written to
/// sandboxed temp files and Hive stores only the file reference + metadata.
///
/// On iOS/Android, the app sandbox is already encrypted at rest by the OS
/// (hardware-backed keystore). This provides encryption without app-level
/// crypto dependencies. If stronger app-level encryption is needed later,
/// add the `cryptography` package and wrap file writes with AES-256-GCM.
class QueueImageStorage {
  factory QueueImageStorage() => _instance;
  QueueImageStorage._();
  static final QueueImageStorage _instance = QueueImageStorage._();

  static const _subdir = 'queue_images';
  Directory? _cacheDir;

  /// Get or create the queue images directory.
  Future<Directory> _getDir() async {
    if (_cacheDir != null && await _cacheDir!.exists()) return _cacheDir!;
    final tempDir = await getTemporaryDirectory();
    _cacheDir = Directory('${tempDir.path}/$_subdir');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  /// Write image bytes to a sandboxed temp file.
  ///
  /// Returns a [QueueImageReference] with the file path, content hash, and
  /// original byte length. The caller stores this reference in Hive instead
  /// of the raw bytes.
  Future<QueueImageReference> writeImage(Uint8List bytes) async {
    final dir = await _getDir();
    final id = const Uuid().v4();
    final file = File('${dir.path}/$id.bin');
    await file.writeAsBytes(bytes, flush: true);

    final hash = sha256.convert(bytes).toString();

    return QueueImageReference(
      filePath: file.path,
      contentHash: hash,
      byteLength: bytes.length,
    );
  }

  /// Read image bytes from a sandboxed temp file.
  ///
  /// Returns null if the file does not exist (orphaned reference).
  Future<Uint8List?> readImage(QueueImageReference ref) async {
    final file = File(ref.filePath);
    if (!await file.exists()) {
      WasteAppLogger.warning(
        'Queue image file missing — orphaned reference',
        context: {'filePath': ref.filePath},
      );
      return null;
    }
    return file.readAsBytes();
  }

  /// Delete a single image file.
  Future<void> deleteImage(QueueImageReference ref) async {
    final file = File(ref.filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Delete image files for a list of references.
  Future<void> deleteImages(List<QueueImageReference> refs) async {
    for (final ref in refs) {
      await deleteImage(ref);
    }
  }

  /// Delete ALL image files in the queue directory.
  Future<int> deleteAll() async {
    final dir = await _getDir();
    if (!await dir.exists()) return 0;
    final files = await dir.list().where((e) => e is File).toList();
    var count = 0;
    for (final file in files) {
      try {
        await file.delete();
        count++;
      } catch (e) {
        WasteAppLogger.warning('Failed to delete queue image file',
            error: e, context: {'path': file.path});
      }
    }
    return count;
  }

  /// Delete image files for a specific user (logout/account switch).
  ///
  /// [filePathSet] is the set of file paths owned by this user, obtained
  /// from scanning Hive metadata.
  Future<int> deleteForUser(Set<String> filePathSet) async {
    var count = 0;
    for (final path in filePathSet) {
      final file = File(path);
      if (await file.exists()) {
        try {
          await file.delete();
          count++;
        } catch (e) {
          WasteAppLogger.warning('Failed to delete user queue image file',
              error: e, context: {'path': path});
        }
      }
    }
    return count;
  }

  /// PRIVACY-09: Clean up orphaned files that have no corresponding Hive entry.
  ///
  /// [activePaths] is the set of file paths currently referenced by Hive
  /// metadata (active queue + dead-letter). Any file NOT in this set is orphaned.
  Future<int> cleanOrphaned(Set<String> activePaths) async {
    final dir = await _getDir();
    if (!await dir.exists()) return 0;
    final files = await dir.list().where((e) => e is File).toList();
    var count = 0;
    for (final file in files) {
      if (!activePaths.contains(file.path)) {
        try {
          await file.delete();
          count++;
        } catch (e) {
          WasteAppLogger.warning('Failed to delete orphaned queue image file',
              error: e, context: {'path': file.path});
        }
      }
    }
    if (count > 0) {
      WasteAppLogger.info('Cleaned orphaned queue image files', context: {
        'count': count,
      });
    }
    return count;
  }
}

/// PRIVACY-09: Reference to an encrypted temp file stored on disk.
///
/// Stored in Hive instead of raw image bytes. The actual image data is in the
/// app sandbox (encrypted at rest by iOS/Android OS).
class QueueImageReference {
  const QueueImageReference({
    required this.filePath,
    required this.contentHash,
    required this.byteLength,
  });

  /// Absolute path to the encrypted temp file.
  final String filePath;

  /// SHA-256 content hash for integrity verification.
  final String contentHash;

  /// Original byte length (for logging/quotas, not for reading).
  final int byteLength;

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'contentHash': contentHash,
        'byteLength': byteLength,
      };

  factory QueueImageReference.fromJson(Map<String, dynamic> json) {
    return QueueImageReference(
      filePath: json['filePath'] as String,
      contentHash: json['contentHash'] as String,
      byteLength: json['byteLength'] as int,
    );
  }
}
