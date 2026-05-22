import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/services/google_drive_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';

class MockStorageService extends Mock implements StorageService {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class FakeUserProfile extends Fake implements UserProfile {}

class _DriveRequestRecord {
  _DriveRequestRecord({
    required this.method,
    required this.uri,
    required this.body,
  });

  final String method;
  final Uri uri;
  final String body;
}

class _RecordingDriveClient extends http.BaseClient {
  _RecordingDriveClient(this._handler);

  final http.Response Function(http.BaseRequest request) _handler;
  final List<_DriveRequestRecord> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = request is http.Request
        ? request.body
        : request is http.MultipartRequest
            ? request.fields.entries
                .map((entry) => '${entry.key}=${entry.value}')
                .join('&')
            : '';
    requests.add(
      _DriveRequestRecord(
        method: request.method,
        uri: request.url,
        body: body,
      ),
    );

    final response = _handler(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
    );
  }
}

void main() {
  late MockStorageService storageService;
  late MockGoogleSignIn googleSignIn;

  setUpAll(() {
    registerFallbackValue(FakeUserProfile());
  });

  setUp(() {
    storageService = MockStorageService();
    googleSignIn = MockGoogleSignIn();

    when(() => storageService.saveUserProfile(any()))
        .thenAnswer((_) async {});
    when(() => storageService.clearUserInfo()).thenAnswer((_) async {});
    when(() => storageService.exportUserData())
        .thenAnswer((_) async => '{"sample":true}');
    when(() => storageService.importUserData(any()))
        .thenAnswer((_) async {});

    when(() => googleSignIn.signOut()).thenAnswer((_) async => null);
    when(() => googleSignIn.isSignedIn()).thenAnswer((_) async => true);
  });

  group('GoogleDriveService', () {
    test('signOut clears Google and local user state', () async {
      final service = GoogleDriveService(
        storageService,
        googleSignIn: googleSignIn,
      );

      await service.signOut();

      verify(() => googleSignIn.signOut()).called(1);
      verify(() => storageService.clearUserInfo()).called(1);
    });

    test('isSignedIn delegates to GoogleSignIn', () async {
      when(() => googleSignIn.isSignedIn()).thenAnswer((_) async => true);
      final service = GoogleDriveService(
        storageService,
        googleSignIn: googleSignIn,
      );

      expect(await service.isSignedIn(), isTrue);

      when(() => googleSignIn.isSignedIn()).thenAnswer((_) async => false);
      expect(await service.isSignedIn(), isFalse);
    });

    test('backupUserData exports local data, creates a folder, and uploads', () async {
      final requests = <String>[];
      final client = _RecordingDriveClient((request) {
        requests.add('${request.method} ${request.url.path}');

        if (request.url.path.endsWith('/drive/v3/files') &&
            request.method == 'GET' &&
            request.url.queryParameters['q']
                ?.contains("name = 'WasteSegregationApp'") ==
            true) {
          return http.Response('{"files":[]}', 200,
              headers: {'content-type': 'application/json'});
        }

        if (request.url.path.endsWith('/drive/v3/files') &&
            request.method == 'POST' &&
            request.url.queryParameters.containsKey('uploadType')) {
          return http.Response('{"id":"backup-file-123"}', 200,
              headers: {'content-type': 'application/json'});
        }

        if (request.url.path.endsWith('/drive/v3/files') &&
            request.method == 'POST') {
          return http.Response('{"id":"folder-123"}', 200,
              headers: {'content-type': 'application/json'});
        }

        throw StateError(
          'Unhandled Drive request: ${request.method} ${request.url}',
        );
      });

      final tempDir = await Directory.systemTemp.createTemp('google_drive');
      addTearDown(() async {
        tempDir.deleteSync(recursive: true);
      });

      final service = GoogleDriveService(
        storageService,
        authenticatedHttpClientOverride: () async => client,
        temporaryDirectoryProvider: () async => tempDir,
      );

      final fileId = await service.backupUserData();

      expect(fileId, 'backup-file-123');
      expect(requests, contains('GET /drive/v3/files'));
      expect(requests, contains('POST /drive/v3/files'));
      expect(tempDir.existsSync(), isTrue);
    });

    test('downloadFromDrive returns file content from Drive', () async {
      final client = _RecordingDriveClient((request) {
        if (request.url.path.contains('/drive/v3/files/') &&
            request.url.queryParameters['alt'] == 'media') {
          return http.Response('restored data', 200,
              headers: {'content-type': 'text/plain; charset=utf-8'});
        }

        throw StateError(
          'Unhandled Drive request: ${request.method} ${request.url}',
        );
      });

      final service = GoogleDriveService(
        storageService,
        authenticatedHttpClientOverride: () async => client,
      );

      expect(await service.downloadFromDrive('file-123'), 'restored data');
    });

    test('listBackupFiles returns backup metadata from Drive', () async {
      final client = _RecordingDriveClient((request) {
        if (request.url.path.endsWith('/drive/v3/files') &&
            request.method == 'GET' &&
            request.url.queryParameters['q']
                ?.contains("name = 'WasteSegregationApp'") ==
            true) {
          return http.Response(
            '{"files":[{"id":"folder-123","name":"WasteSegregationApp"}]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('/drive/v3/files') &&
            request.method == 'GET' &&
            request.url.queryParameters['q']
                ?.contains('waste_seg_backup_') ==
            true) {
          return http.Response(
            '{"files":[{"id":"backup-1","name":"waste_seg_backup_1.json"}]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        throw StateError(
          'Unhandled Drive request: ${request.method} ${request.url}',
        );
      });

      final service = GoogleDriveService(
        storageService,
        authenticatedHttpClientOverride: () async => client,
      );

      final backups = await service.listBackupFiles();

      expect(backups, [
        {'id': 'backup-1', 'name': 'waste_seg_backup_1.json'},
      ]);
    });

    test('restoreUserData downloads and imports the payload', () async {
      final client = _RecordingDriveClient((request) {
        if (request.url.path.contains('/drive/v3/files/') &&
            request.url.queryParameters['alt'] == 'media') {
          return http.Response('{"restored":true}', 200,
              headers: {'content-type': 'application/json'});
        }

        throw StateError(
          'Unhandled Drive request: ${request.method} ${request.url}',
        );
      });

      final service = GoogleDriveService(
        storageService,
        authenticatedHttpClientOverride: () async => client,
      );

      await service.restoreUserData('file-123');

      verify(() => storageService.importUserData('{"restored":true}'))
          .called(1);
    });
  });
}
