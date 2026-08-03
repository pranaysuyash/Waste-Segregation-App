import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:waste_segregation_app/services/enhanced_image_service.dart';

/// Helper to create a minimal valid JPEG bytes for testing.
Uint8List _createTestJpeg({int width = 8, int height = 8}) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgba(x, y, 128, 128, 128, 255);
    }
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}

/// Helper to create a minimal valid PNG bytes.
Uint8List _createTestPng() {
  final image = img.Image(width: 8, height: 8);
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      image.setPixelRgba(x, y, 128, 128, 128, 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testDir;

  setUp(() {
    testDir = Directory.systemTemp.createTempSync('img_svc_test_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'getApplicationDocumentsDirectory':
          return testDir.path;
        case 'getTemporaryDirectory':
          return '${testDir.path}/tmp';
        default:
          return null;
      }
    });
  });

  tearDown(() {
    testDir.deleteSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
  });

  final service = EnhancedImageService();

  // ─── saveImagePermanently ────────────────────────────────────────

  group('saveImagePermanently', () {
    test('rejects empty bytes', () {
      expect(
        () => service.saveImagePermanently(Uint8List(0)),
        throwsArgumentError,
      );
    });

    test('rejects empty bytes with fileName', () {
      expect(
        () => service.saveImagePermanently(Uint8List(0), fileName: 'test.jpg'),
        throwsArgumentError,
      );
    });

    test('uses .jpg extension for JPEG content', () async {
      final jpeg = _createTestJpeg();
      final path = await service.saveImagePermanently(jpeg);
      expect(path, endsWith('.jpg'));
    });

    test('detects PNG content and writes .png file extension', () async {
      final png = _createTestPng();
      final path =
          await service.saveImagePermanently(png, fileName: 'uploaded.jpg');
      expect(path, endsWith('.png'));
    });

    test('detects PNG content without fileName', () async {
      final png = _createTestPng();
      final path = await service.saveImagePermanently(png);
      expect(path, endsWith('.png'));
    });

    test('writes file that exists at returned path', () async {
      final jpeg = _createTestJpeg();
      final path = await service.saveImagePermanently(jpeg);
      expect(File(path).existsSync(), isTrue);
    });

    test('writes non-empty file', () async {
      final jpeg = _createTestJpeg(width: 100, height: 100);
      final path = await service.saveImagePermanently(jpeg);
      expect(File(path).lengthSync(), greaterThan(0));
    });
  });

  // ─── saveThumbnail ──────────────────────────────────────────────

  group('saveThumbnail', () {
    test('saves thumbnail from valid JPEG', () async {
      final jpeg = _createTestJpeg(width: 640, height: 480);
      final path = await service.saveThumbnail(jpeg);
      expect(File(path).existsSync(), isTrue);
    });

    test('throws on empty bytes', () {
      expect(
        () => service.saveThumbnail(Uint8List(0)),
        throwsArgumentError,
      );
    });

    test('throws on invalid non-image bytes', () async {
      expect(
        () => service.saveThumbnail(Uint8List.fromList([0, 1, 2, 3, 4, 5])),
        throwsA(anything),
      );
    });

    test('throws on text bytes', () async {
      final textBytes = Uint8List.fromList('not_an_image'.codeUnits);
      expect(
        () => service.saveThumbnail(textBytes),
        throwsA(anything),
      );
    });
  });

  // ─── Thumbnail generation max-edge contract ─────────────────────

  group('thumbnail generation max-edge', () {
    test('landscape image produces thumbnail with width <= 256', () async {
      final jpeg = _createTestJpeg(width: 1920, height: 1080);
      final path = await service.saveThumbnail(jpeg);
      final savedBytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(savedBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, lessThanOrEqualTo(256));
      expect(decoded.height, lessThanOrEqualTo(256));
    });

    test('portrait image produces thumbnail with height <= 256', () async {
      final jpeg = _createTestJpeg(width: 1080, height: 1920);
      final path = await service.saveThumbnail(jpeg);
      final savedBytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(savedBytes);
      expect(decoded, isNotNull);
      expect(decoded!.height, lessThanOrEqualTo(256));
      expect(decoded.width, lessThanOrEqualTo(256));
    });

    test('square image produces thumbnail with both edges <= 256', () async {
      final jpeg = _createTestJpeg(width: 800, height: 800);
      final path = await service.saveThumbnail(jpeg);
      final savedBytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(savedBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, lessThanOrEqualTo(256));
      expect(decoded.height, lessThanOrEqualTo(256));
    });

    test('thumbnail failure does not save original bytes', () async {
      final badBytes = Uint8List.fromList(
        [0xFF, 0xD8, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00],
      );
      expect(
        () => service.saveThumbnail(badBytes),
        throwsA(isA<FormatException>()),
      );
    });
  });

  // ─── resolveTrustedLocalPath ────────────────────────────────────

  group('resolveTrustedLocalPath', () {
    test('returns null for empty input', () async {
      final result = await service.resolveTrustedLocalPath('');
      expect(result, isNull);
    });

    test('rejects traversal with relative dotdot', () async {
      final result = await service.resolveTrustedLocalPath('../../etc/passwd');
      expect(result, isNull);
    });

    test('rejects traversal with encoded segments', () async {
      final result =
          await service.resolveTrustedLocalPath('thumbnails/../../etc');
      expect(result, isNull);
    });

    test('rejects external absolute paths', () async {
      final result = await service.resolveTrustedLocalPath('/tmp/outside.jpg');
      expect(result, isNull);
    });

    test('accepts absolute images path that exists', () async {
      final jpeg = _createTestJpeg();
      final savedPath = await service.saveImagePermanently(jpeg);
      final result = await service.resolveTrustedLocalPath(savedPath);
      expect(result, equals(savedPath));
    });

    test('rejects non-existing paths', () async {
      final result = await service.resolveTrustedLocalPath(
        'images/does_not_exist_12345.jpg',
      );
      expect(result, isNull);
    });
  });

  // ─── fetchImageWithRetry ───────────────────────────────────────

  group('fetchImageWithRetry', () {
    test('returns null for non-http scheme', () async {
      final result = await service.fetchImageWithRetry('file:///etc/passwd');
      expect(result, isNull);
    });

    test('returns null for ftp scheme', () async {
      final result = await service.fetchImageWithRetry(
        'ftp://example.com/image.jpg',
      );
      expect(result, isNull);
    });
  });

  // ─── cleanUpTempImages ─────────────────────────────────────────

  group('cleanUpTempImages', () {
    test('does not throw when no app temp dir exists', () async {
      await service.cleanUpTempImages();
    });

    test('cleans old files in app temp subdirectory only', () async {
      // Create an old file directly in the system temp dir
      final strayFile = File('${testDir.path}/tmp/stray_plugin_file.txt');
      await strayFile.parent.create(recursive: true);
      await strayFile.writeAsString('stray content');

      // Create an old app temp file
      final appTempDir = Directory('${testDir.path}/tmp/app_temp_images');
      await appTempDir.create(recursive: true);
      final appFile = File('${appTempDir.path}/old_image.jpg');
      await appFile.writeAsString('old image');

      await service.cleanUpTempImages(olderThan: Duration.zero);

      // Stray file should still exist (not in app temp subdir)
      expect(strayFile.existsSync(), isTrue);
      // App temp file should have been cleaned
      expect(appFile.existsSync(), isFalse);
    });
  });

  // ─── cleanUpOrphanedThumbnails ─────────────────────────────────

  group('cleanUpOrphanedThumbnails', () {
    test('succeeds without throwing when called with empty list', () async {
      await service.cleanUpOrphanedThumbnails([]);
    });

    test('does not remove valid thumbnails', () async {
      final jpeg = _createTestJpeg();
      final thumbPath = await service.saveThumbnail(jpeg);
      await service.cleanUpOrphanedThumbnails([thumbPath]);
      expect(File(thumbPath).existsSync(), isTrue);
    });
  });

  // ─── Content-based extension ───────────────────────────────────

  // ─── purgeExpiredLocalImages (PRIVACY-02 retention) ────────────

  group('purgeExpiredLocalImages', () {
    test('removes only stale unreferenced files older than retention', () async {
      final imagesDir = Directory('${testDir.path}/images');
      await imagesDir.create(recursive: true);

      // Stale (older than 90-day retention) + unreferenced → MUST be purged.
      final staleOrphan = File('${imagesDir.path}/stale_orphan_uuid.jpg');
      await staleOrphan.writeAsBytes(_createTestJpeg());
      staleOrphan.setLastModifiedSync(
          DateTime.now().subtract(const Duration(days: 120)));

      // Stale + referenced by a saved classification → MUST survive.
      final staleReferenced = File('${imagesDir.path}/stale_referenced_uuid.jpg');
      await staleReferenced.writeAsBytes(_createTestJpeg());
      staleReferenced.setLastModifiedSync(
          DateTime.now().subtract(const Duration(days: 120)));

      // Fresh (within retention window) + unreferenced → MUST survive.
      // This is the "only stale files are removed" guarantee.
      final freshOrphan = File('${imagesDir.path}/fresh_orphan_uuid.jpg');
      await freshOrphan.writeAsBytes(_createTestJpeg());
      freshOrphan.setLastModifiedSync(
          DateTime.now().subtract(const Duration(days: 10)));

      // Just inside the retention window → MUST survive. purge compares with
      // strict `>` (now.difference(modified) <= olderThan is kept), so an
      // exactly-at-boundary mtime would be flaky; 1h inside is deterministic.
      final justInside = File('${imagesDir.path}/just_inside_uuid.jpg');
      await justInside.writeAsBytes(_createTestJpeg());
      justInside.setLastModifiedSync(DateTime.now().subtract(
          EnhancedImageService.localImageRetention -
              const Duration(hours: 1)));

      final removed = await service.purgeExpiredLocalImages(
        referencedPaths: {staleReferenced.path},
      );

      expect(removed, 1, reason: 'exactly one stale orphan is purged');
      expect(staleOrphan.existsSync(), isFalse,
          reason: 'stale unreferenced image must be purged');
      expect(staleReferenced.existsSync(), isTrue,
          reason: 'stale but referenced image must survive');
      expect(freshOrphan.existsSync(), isTrue,
          reason: 'fresh unreferenced image must survive (only stale removed)');
      expect(justInside.existsSync(), isTrue,
          reason: 'image inside retention window is not stale');
    });

    test('returns 0 and leaves files untouched when images dir is absent',
        () async {
      final removed =
          await service.purgeExpiredLocalImages(referencedPaths: {});
      expect(removed, 0);
    });

    test('purges every stale orphan when referenced set is empty', () async {
      final imagesDir = Directory('${testDir.path}/images');
      await imagesDir.create(recursive: true);

      final staleOne = File('${imagesDir.path}/stale_one_uuid.jpg');
      await staleOne.writeAsBytes(_createTestJpeg());
      staleOne.setLastModifiedSync(
          DateTime.now().subtract(const Duration(days: 100)));

      final staleTwo = File('${imagesDir.path}/stale_two_uuid.jpg');
      await staleTwo.writeAsBytes(_createTestJpeg());
      staleTwo.setLastModifiedSync(
          DateTime.now().subtract(const Duration(days: 200)));

      final removed =
          await service.purgeExpiredLocalImages(referencedPaths: {});
      expect(removed, 2);
      expect(staleOne.existsSync(), isFalse);
      expect(staleTwo.existsSync(), isFalse);
    });
  });

  group('content-based extension', () {
    test('saves PNG content with .png extension', () async {
      final png = _createTestPng();
      final path = await service.saveImagePermanently(png);
      expect(path, endsWith('.png'));
    });

    test('saves JPEG content with .jpg extension', () async {
      final jpeg = _createTestJpeg();
      final path = await service.saveImagePermanently(jpeg);
      expect(path, endsWith('.jpg'));
    });

    test('saves PNG as .png even when fileName suggests .jpg', () async {
      final png = _createTestPng();
      final path =
          await service.saveImagePermanently(png, fileName: 'image.jpg');
      expect(path, endsWith('.png'));
    });
  });
}
