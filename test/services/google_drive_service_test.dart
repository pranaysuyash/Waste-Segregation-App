import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:waste_segregation_app/services/google_drive_service.dart';

@GenerateMocks([drive.DriveApi, drive.FilesResource, AuthClient])
import 'google_drive_service_test.mocks.dart';

void main() {
  group('GoogleDriveService Tests', () {
    late GoogleDriveService googleDriveService;
    late MockDriveApi mockDriveApi;
    late MockFilesResource mockFilesResource;
    late MockAuthClient mockAuthClient;

    setUp(() {
      mockDriveApi = MockDriveApi();
      mockFilesResource = MockFilesResource();
      mockAuthClient = MockAuthClient();
      
      when(mockDriveApi.files).thenReturn(mockFilesResource);
      
      googleDriveService = GoogleDriveService();
      // Inject mocked dependencies
      googleDriveService.setDriveApi(mockDriveApi);
    });

    group('Authentication', () {
      test('should authenticate with Google Drive successfully', () async {
        when(mockAuthClient.credentials).thenReturn(
          AccessCredentials(
            AccessToken('token', 'Bearer', DateTime.now().add(const Duration(hours: 1))),
            'refresh_token',
            ['https://www.googleapis.com/auth/drive.file'],
          ),
        );

        final result = await googleDriveService.authenticate();

        expect(result, true);
        expect(googleDriveService.isAuthenticated, true);
      });

      test('should handle authentication failure', () async {
        when(mockAuthClient.credentials).thenThrow(Exception('Auth failed'));

        final result = await googleDriveService.authenticate();

        expect(result, false);
        expect(googleDriveService.isAuthenticated, false);
      });

      test('should refresh expired token', () async {
        final expiredCredentials = AccessCredentials(
          AccessToken('old_token', 'Bearer', DateTime.now().subtract(const Duration(hours: 1))),
          'refresh_token',
          ['https://www.googleapis.com/auth/drive.file'],
        );

        final refreshedCredentials = AccessCredentials(
          AccessToken('new_token', 'Bearer', DateTime.now().add(const Duration(hours: 1))),
          'refresh_token',
          ['https://www.googleapis.com/auth/drive.file'],
        );

        when(mockAuthClient.credentials).thenReturn(expiredCredentials);
        when(mockAuthClient.refreshCredentials()).thenAnswer((_) async => refreshedCredentials);

        final result = await googleDriveService.refreshToken();

        expect(result, true);
        verify(mockAuthClient.refreshCredentials()).called(1);
      });

      test('should handle token refresh failure', () async {
        when(mockAuthClient.refreshCredentials()).thenThrow(Exception('Refresh failed'));

        final result = await googleDriveService.refreshToken();

        expect(result, false);
      });
    });

    group('File Operations', () {
      test('should upload file to Google Drive successfully', () async {
        const testData = 'test file content';
        const testFileName = 'test_backup.json';
        
        final mockFile = drive.File();
        mockFile.id = 'file_123';
        mockFile.name = testFileName;
        mockFile.size = testData.length.toString();

        when(mockFilesResource.create(
          any,
          uploadMedia: anyNamed('uploadMedia'),
        )).thenAnswer((_) async => mockFile);

        final result = await googleDriveService.uploadFile(
          testData.codeUnits,
          testFileName,
          'application/json',
        );

        expect(result, isNotNull);
        expect(result?.id, 'file_123');
        expect(result?.name, testFileName);
        verify(mockFilesResource.create(any, uploadMedia: anyNamed('uploadMedia'))).called(1);
      });

      test('should handle file upload failure', () async {
        when(mockFilesResource.create(
          any,
          uploadMedia: anyNamed('uploadMedia'),
        )).thenThrow(Exception('Upload failed'));

        final result = await googleDriveService.uploadFile(
          'test'.codeUnits,
          'test.txt',
          'text/plain',
        );

        expect(result, null);
      });

      test('should download file from Google Drive successfully', () async {
        const fileId = 'file_123';
        final mockMedia = drive.Media(Stream.value([1, 2, 3, 4, 5]), 5);

        when(mockFilesResource.get(
          fileId,
          downloadOptions: anyNamed('downloadOptions'),
        )).thenAnswer((_) async => mockMedia);

        final result = await googleDriveService.downloadFile(fileId);

        expect(result, isNotNull);
        expect(result, [1, 2, 3, 4, 5]);
        verify(mockFilesResource.get(
          fileId,
          downloadOptions: anyNamed('downloadOptions'),
        )).called(1);
      });

      test('should handle file download failure', () async {
        const fileId = 'file_123';

        when(mockFilesResource.get(
          fileId,
          downloadOptions: anyNamed('downloadOptions'),
        )).thenThrow(Exception('Download failed'));

        final result = await googleDriveService.downloadFile(fileId);

        expect(result, null);
      });

      test('should delete file from Google Drive successfully', () async {
        const fileId = 'file_123';

        when(mockFilesResource.delete(fileId)).thenAnswer((_) async => null);

        final result = await googleDriveService.deleteFile(fileId);

        expect(result, true);
        verify(mockFilesResource.delete(fileId)).called(1);
      });

      test('should handle file deletion failure', () async {
        const fileId = 'file_123';

        when(mockFilesResource.delete(fileId)).thenThrow(Exception('Delete failed'));

        final result = await googleDriveService.deleteFile(fileId);

        expect(result, false);
      });

      test('should update existing file successfully', () async {
        const fileId = 'file_123';
        const newData = 'updated content';
        
        final mockFile = drive.File();
        mockFile.id = fileId;
        mockFile.name = 'updated_file.json';

        when(mockFilesResource.update(
          any,
          fileId,
          uploadMedia: anyNamed('uploadMedia'),
        )).thenAnswer((_) async => mockFile);

        final result = await googleDriveService.updateFile(
          fileId,
          newData.codeUnits,
          'application/json',
        );

        expect(result, isNotNull);
        expect(result?.id, fileId);
        verify(mockFilesResource.update(
          any,
          fileId,
          uploadMedia: anyNamed('uploadMedia'),
        )).called(1);
      });
    });

    group('File Listing and Search', () {
      test('should list files in Google Drive successfully', () async {
        final mockFileList = drive.FileList();
        final mockFiles = [
          drive.File()..id = 'file_1'..name = 'backup_1.json'..size = '1024',
          drive.File()..id = 'file_2'..name = 'backup_2.json'..size = '2048',
        ];
        mockFileList.files = mockFiles;

        when(mockFilesResource.list(
          q: anyNamed('q'),
          spaces: anyNamed('spaces'),
          fields: anyNamed('fields'),
        )).thenAnswer((_) async => mockFileList);

        final result = await googleDriveService.listFiles();

        expect(result, isNotNull);
        expect(result!.length, 2);
        expect(result[0].id, 'file_1');
        expect(result[1].id, 'file_2');
        verify(mockFilesResource.list(
          q: anyNamed('q'),
          spaces: anyNamed('spaces'),
          fields: anyNamed('fields'),
        )).called(1);
      });

      test('should search files by name successfully', () async {
        const searchQuery = 'backup';
        final mockFileList = drive.FileList();
        final mockFiles = [
          drive.File()..id = 'file_1'..name = 'backup_data.json'..size = '1024',
        ];
        mockFileList.files = mockFiles;

        when(mockFilesResource.list(
          q: contains(searchQuery),
          spaces: anyNamed('spaces'),
          fields: anyNamed('fields'),
        )).thenAnswer((_) async => mockFileList);

        final result = await googleDriveService.searchFiles(searchQuery);

        expect(result, isNotNull);
        expect(result!.length, 1);
        expect(result[0].name, contains('backup'));
        verify(mockFilesResource.list(
          q: argThat(contains(searchQuery), named: 'q'),
          spaces: anyNamed('spaces'),
          fields: anyNamed('fields'),
        )).called(1);
      });

      test('should filter files by type successfully', () async {
        const mimeType = 'application/json';
        final mockFileList = drive.FileList();
        final mockFiles = [
          drive.File()..id = 'file_1'..name = 'data.json'..mimeType = mimeType,
        ];
        mockFileList.files = mockFiles;

        when(mockFilesResource.list(
          q: contains(mimeType),
          spaces: anyNamed('spaces'),
          fields: anyNamed('fields'),
        )).thenAnswer((_) async => mockFileList);

        final result = await googleDriveService.listFilesByType(mimeType);

        expect(result, isNotNull);
        expect(result!.length, 1);
        expect(result[0].mimeType, mimeType);
        verify(mockFilesResource.list(
          q: argThat(contains(mimeType), named: 'q'),
          spaces: anyNamed('spaces'),
          fields: anyNamed('fields'),
        )).called(1);
      });

      test('should handle empty file list', () async {
        final mockFileList = drive.FileList();
        mockFileList.files = [];

        when(mockFilesResource.list(
          q: anyNamed('q'),
          spaces: anyNamed('spaces'),
          fields: anyNamed('fields'),
        )).thenAnswer((_) async => mockFileList);

        final result = await googleDriveService.listFiles();

        expect(result, isNotNull);
        expect(result!.isEmpty, true);
      });

      test('should handle file listing failure', () async {
        when(mockFilesResource.list(
          q: anyNamed('q'),
          spaces: anyNamed('spaces'),
          fields: anyNamed('fields'),
        )).thenThrow(Exception('List failed'));

        final result = await googleDriveService.listFiles();

        expect(result, null);
      });
    });

    group('Backup Operations', () {
      test('should create backup successfully', () async {
        final backupData = {
          'classifications': [],
          'settings': {},
          'timestamp': DateTime.now().toIso8601String(),
        };

        final mockFile = drive.File();
        mockFile.id = 'backup_123';
        mockFile.name = 'waste_app_backup_${DateTime.now().millisecondsSinceEpoch}.json';

        when(mockFilesResource.create(
          any,
          uploadMedia: anyNamed('uploadMedia'),
        )).thenAnswer((_) async => mockFile);

        final result = await googleDriveService.createBackup(backupData);

        expect(result, isNotNull);
        expect(result?.id, 'backup_123');
        expect(result?.name, contains('waste_app_backup_'));
        verify(mockFilesResource.create(any, uploadMedia: anyNamed('uploadMedia'))).called(1);
      });

      test('should restore backup successfully', () async {
        const backupId = 'backup_123';
        const backupData = '''
        {
          "classifications": [],
          "settings": {},
          "timestamp": "2024-01-15T10:30:00.000Z"
        }
        ''';

        final mockMedia = drive.Media(
          Stream.value(backupData.codeUnits),
          backupData.length,
        );

        when(mockFilesResource.get(
          backupId,
          downloadOptions: anyNamed('downloadOptions'),
        )).thenAnswer((_) async => mockMedia);

        final result = await googleDriveService.restoreBackup(backupId);

        expect(result, isNotNull);
        expect(result!['timestamp'], '2024-01-15T10:30:00.000Z');
        verify(mockFilesResource.get(
          backupId,
          downloadOptions: anyNamed('downloadOptions'),
        )).called(1);
      });

      test('should list backup files successfully', () async {
        final mockFileList = drive.FileList();
        final mockFiles = [
          drive.File()
            ..id = 'backup_1'
            ..name = 'waste_app_backup_1704186600000.json'
            ..createdTime = DateTime(2024, 1, 1, 10)
            ..size = '1024',
          drive.File()
            ..id = 'backup_2'
            ..name = 'waste_app_backup_1704273000000.json'
            ..createdTime = DateTime(2024, 1, 2, 10)
            ..size = '2048',
        ];
        mockFileList.files = mockFiles;

        when(mockFilesResource.list(
          q: contains('waste_app_backup_'),
          spaces: anyNamed('spaces'),
          fields: anyNamed('fields'),
          orderBy: anyNamed('orderBy'),
        )).thenAnswer((_) async => mockFileList);

        final result = await googleDriveService.listBackups();

        expect(result, isNotNull);
        expect(result!.length, 2);
        expect(result[0].name, contains('waste_app_backup_'));
        expect(result[1].name, contains('waste_app_backup_'));
        verify(mockFilesResource.list(
          q: argThat(contains('waste_app_backup_'), named: 'q'),
          spaces: anyNamed('spaces'),
          fields: anyNamed('fields'),
          orderBy: anyNamed('orderBy'),
        )).called(1);
      });

      test('should delete old backups successfully', () async {
        final oldBackups = [
          drive.File()
            ..id = 'old_backup_1'
            ..name = 'waste_app_backup_old1.json'
            ..createdTime = DateTime.now().subtract(const Duration(days: 35)),
          drive.File()
            ..id = 'old_backup_2'
            ..name = 'waste_app_backup_old2.json'
            ..createdTime = DateTime.now().subtract(const Duration(days: 40)),
        ];

        final mockFileList = drive.FileList();
        mockFileList.files = oldBackups;

        when(mockFilesResource.list(
          q: anyNamed('q'),
          spaces: anyNamed('spaces'),
          fields: anyNamed('fields'),
          orderBy: anyNamed('orderBy'),
        )).thenAnswer((_) async => mockFileList);

        when(mockFilesResource.delete(any)).thenAnswer((_) async => null);

        final result = await googleDriveService.cleanupOldBackups(30); // Keep 30 days

        expect(result, 2); // Should delete 2 old backups
        verify(mockFilesResource.delete('old_backup_1')).called(1);
        verify(mockFilesResource.delete('old_backup_2')).called(1);
      });
    });

    group('Synchronization', () {
      test('should sync data to Google Drive successfully', () async {
        final syncData = {
          'user_data': {'classifications': [], 'preferences': {}},
          'app_version': '1.0.0',
          'sync_timestamp': DateTime.now().toIso8601String(),
        };

        final existingFiles = <drive.File>[];
        final mockFileList = drive.FileList();
        mockFileList.files = existingFiles;

        when(mockFilesResource.list(
          q: contains('waste_app_sync.json'),
          spaces: anyNamed('spaces'),
          fields: anyNamed('fields'),
        )).thenAnswer((_) async => mockFileList);

        final mockFile = drive.File();
        mockFile.id = 'sync_123';
        mockFile.name = 'waste_app_sync.json';

        when(mockFilesResource.create(
          any,
          uploadMedia: anyNamed('uploadMedia'),
        )).thenAnswer((_) async => mockFile);

        final result = await googleDriveService.syncToCloud(syncData);

        expect(result, true);
        verify(mockFilesResource.create(any, uploadMedia: anyNamed('uploadMedia'))).called(1);
      });

      test('should update existing sync file', () async {
        final syncData = {
          'user_data': {'classifications': [], 'preferences': {}},
          'app_version': '1.0.0',
          'sync_timestamp': DateTime.now().toIso8601String(),
        };

        final existingFile = drive.File()
          ..id = 'existing_sync_123'
          ..name = 'waste_app_sync.json';

        final mockFileList = drive.FileList();
        mockFileList.files = [existingFile];

        when(mockFilesResource.list(
          q: contains('waste_app_sync.json'),
          spaces: anyNamed('spaces'),
          fields: anyNamed('fields'),
        )).thenAnswer((_) async => mockFileList);

        when(mockFilesResource.update(
          any,
          'existing_sync_123',
          uploadMedia: anyNamed('uploadMedia'),
        )).thenAnswer((_) async => existingFile);

        final result = await googleDriveService.syncToCloud(syncData);

        expect(result, true);
        verify(mockFilesResource.update(
          any,
          'existing_sync_123',
          uploadMedia: anyNamed('uploadMedia'),
        )).called(1);
      });

      test('should sync from Google Drive successfully', () async {
        const syncFileId = 'sync_123';
        const syncData = '''
        {
          "user_data": {"classifications": [], "preferences": {}},
          "app_version": "1.0.0",
          "sync_timestamp": "2024-01-15T10:30:00.000Z"
        }
        ''';

        final existingFile = drive.File()
          ..id = syncFileId
          ..name = 'waste_app_sync.json';

        final mockFileList = drive.FileList();
        mockFileList.files = [existingFile];

        when(mockFilesResource.list(
          q: contains('waste_app_sync.json'),
          spaces: anyNamed('spaces'),
          fields: anyNamed('fields'),
        )).thenAnswer((_) async => mockFileList);

        final mockMedia = drive.Media(
          Stream.value(syncData.codeUnits),
          syncData.length,
        );

        when(mockFilesResource.get(
          syncFileId,
          downloadOptions: anyNamed('downloadOptions'),
        )).thenAnswer((_) async => mockMedia);

        final result = await googleDriveService.syncFromCloud();

        expect(result, isNotNull);
        expect(result!['app_version'], '1.0.0');
        expect(result['sync_timestamp'], '2024-01-15T10:30:00.000Z');
        verify(mockFilesResource.get(
          syncFileId,
          downloadOptions: anyNamed('downloadOptions'),
        )).called(1);
      });

      test('should handle no sync file available', () async {
        final mockFileList = drive.FileList();
        mockFileList.files = [];

        when(mockFilesResource.list(
          q: contains('waste_app_sync.json'),
          spaces: anyNamed('spaces'),
          fields: anyNamed('fields'),
        )).thenAnswer((_) async => mockFileList);

        final result = await googleDriveService.syncFromCloud();

        expect(result, null);
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle network timeout', () async {
        when(mockFilesResource.list(
          q: anyNamed('q'),
          spaces: anyNamed('spaces'),
          fields: anyNamed('fields'),
        )).thenThrow(TimeoutException('Network timeout', const Duration(seconds: 30)));

        final result = await googleDriveService.listFiles();

        expect(result, null);
      });

      test('should handle quota exceeded error', () async {
        when(mockFilesResource.create(
          any,
          uploadMedia: anyNamed('uploadMedia'),
        )).thenThrow(Exception('Quota exceeded'));

        final result = await googleDriveService.uploadFile(
          'test'.codeUnits,
          'test.txt',
          'text/plain',
        );

        expect(result, null);
      });

      test('should handle insufficient permissions', () async {
        when(mockFilesResource.delete(any))
            .thenThrow(Exception('Insufficient permissions'));

        final result = await googleDriveService.deleteFile('file_123');

        expect(result, false);
      });

      test('should handle large file upload', () async {
        final largeData = List.filled(10 * 1024 * 1024, 65); // 10MB of 'A' characters
        const fileName = 'large_backup.json';

        final mockFile = drive.File();
        mockFile.id = 'large_file_123';
        mockFile.name = fileName;
        mockFile.size = largeData.length.toString();

        when(mockFilesResource.create(
          any,
          uploadMedia: anyNamed('uploadMedia'),
        )).thenAnswer((_) async => mockFile);

        final result = await googleDriveService.uploadFile(
          largeData,
          fileName,
          'application/json',
        );

        expect(result, isNotNull);
        expect(result?.size, largeData.length.toString());
      });

      test('should handle corrupted backup data', () async {
        const backupId = 'corrupted_backup';
        const corruptedData = 'invalid json data {{{';

        final mockMedia = drive.Media(
          Stream.value(corruptedData.codeUnits),
          corruptedData.length,
        );

        when(mockFilesResource.get(
          backupId,
          downloadOptions: anyNamed('downloadOptions'),
        )).thenAnswer((_) async => mockMedia);

        final result = await googleDriveService.restoreBackup(backupId);

        expect(result, null);
      });
    });

    group('Storage Management', () {
      test('should get storage usage information', () async {
        final mockAbout = drive.About();
        mockAbout.storageQuota = drive.AboutStorageQuota()
          ..limit = '15000000000' // 15GB
          ..usage = '5000000000'  // 5GB
          ..usageInDrive = '3000000000'; // 3GB

        when(mockDriveApi.about).thenReturn(MockAboutResource());
        when(mockDriveApi.about.get(fields: 'storageQuota'))
            .thenAnswer((_) async => mockAbout);

        final result = await googleDriveService.getStorageInfo();

        expect(result, isNotNull);
        expect(result!['totalSpace'], '15000000000');
        expect(result['usedSpace'], '5000000000');
        expect(result['availableSpace'], '10000000000');
      });

      test('should check if enough storage space available', () async {
        final mockAbout = drive.About();
        mockAbout.storageQuota = drive.AboutStorageQuota()
          ..limit = '15000000000' // 15GB
          ..usage = '5000000000'; // 5GB

        when(mockDriveApi.about).thenReturn(MockAboutResource());
        when(mockDriveApi.about.get(fields: 'storageQuota'))
            .thenAnswer((_) async => mockAbout);

        final hasSpace = await googleDriveService.hasEnoughSpace(1000000); // 1MB

        expect(hasSpace, true);
      });

      test('should detect insufficient storage space', () async {
        final mockAbout = drive.About();
        mockAbout.storageQuota = drive.AboutStorageQuota()
          ..limit = '15000000000' // 15GB
          ..usage = '14500000000'; // 14.5GB

        when(mockDriveApi.about).thenReturn(MockAboutResource());
        when(mockDriveApi.about.get(fields: 'storageQuota'))
            .thenAnswer((_) async => mockAbout);

        final hasSpace = await googleDriveService.hasEnoughSpace(1000000000); // 1GB

        expect(hasSpace, false);
      });
    });

    group('Performance and Optimization', () {
      test('should handle multiple concurrent uploads', () async {
        final futures = <Future<drive.File?>>[];
        
        for (var i = 0; i < 5; i++) {
          final mockFile = drive.File();
          mockFile.id = 'file_$i';
          mockFile.name = 'test_$i.json';

          when(mockFilesResource.create(
            argThat(predicate((file) => file.name == 'test_$i.json')),
            uploadMedia: anyNamed('uploadMedia'),
          )).thenAnswer((_) async => mockFile);

          futures.add(googleDriveService.uploadFile(
            'test data $i'.codeUnits,
            'test_$i.json',
            'application/json',
          ));
        }

        final results = await Future.wait(futures);

        expect(results.length, 5);
        for (var i = 0; i < 5; i++) {
          expect(results[i]?.id, 'file_$i');
        }
      });

      test('should implement retry logic for failed operations', () async {
        var attempts = 0;
        when(mockFilesResource.create(
          any,
          uploadMedia: anyNamed('uploadMedia'),
        )).thenAnswer((_) async {
          attempts++;
          if (attempts < 3) {
            throw Exception('Temporary failure');
          }
          
          final mockFile = drive.File();
          mockFile.id = 'retry_success';
          mockFile.name = 'retry_test.json';
          return mockFile;
        });

        final result = await googleDriveService.uploadFileWithRetry(
          'test'.codeUnits,
          'retry_test.json',
          'application/json',
          maxRetries: 3,
        );

        expect(result, isNotNull);
        expect(result?.id, 'retry_success');
        expect(attempts, 3);
      });

      test('should cache frequently accessed data', () async {
        final mockFile = drive.File();
        mockFile.id = 'cached_file';
        mockFile.name = 'cache_test.json';

        final mockFileList = drive.FileList();
        mockFileList.files = [mockFile];

        when(mockFilesResource.list(
          q: anyNamed('q'),
          spaces: anyNamed('spaces'),
          fields: anyNamed('fields'),
        )).thenAnswer((_) async => mockFileList);

        // First call should hit the API
        final result1 = await googleDriveService.listFiles();
        
        // Second call should use cached result
        final result2 = await googleDriveService.listFiles();

        expect(result1, equals(result2));
        // Verify API was called only once due to caching
        verify(mockFilesResource.list(
          q: anyNamed('q'),
          spaces: anyNamed('spaces'),
          fields: anyNamed('fields'),
        )).called(1);
      });
    });
  });
}

// Mock class for AboutResource
class MockAboutResource extends Mock implements drive.AboutResource {}
