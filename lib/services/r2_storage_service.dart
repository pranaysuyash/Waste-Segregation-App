import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

class R2UploadResult {
  const R2UploadResult({
    required this.publicUrl,
    required this.objectKey,
  });

  final String publicUrl;
  final String objectKey;
}

class R2StorageService {
  Future<R2UploadResult> uploadImage({
    required Uint8List imageBytes,
    required String fileName,
    String? folder,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    final functions = FirebaseFunctions.instanceFor(region: 'asia-south1');
    final callable = functions.httpsCallable('getR2UploadUrl');
    final result = await callable.call(<String, dynamic>{
      'file_name': fileName,
      'content_type': 'image/jpeg',
      if (folder != null) 'folder': folder,
    });

    final data = result.data as Map<String, dynamic>;
    final uploadUrl = data['upload_url'] as String;
    final publicUrl = data['public_url'] as String;
    final objectKey = data['object_key'] as String;

    final putResponse = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': 'image/jpeg'},
      body: imageBytes,
    );

    if (putResponse.statusCode != 200) {
      WasteAppLogger.severe('R2 upload failed', context: {
        'statusCode': putResponse.statusCode,
        'objectKey': objectKey,
        'service': 'r2_storage_service',
      });
      throw Exception('R2 upload failed with status ${putResponse.statusCode}');
    }

    WasteAppLogger.info('R2 upload successful', context: {
      'objectKey': objectKey,
      'service': 'r2_storage_service',
    });

    return R2UploadResult(
      publicUrl: publicUrl,
      objectKey: objectKey,
    );
  }

  Future<R2UploadResult> uploadImageFromFile({
    required File imageFile,
    String? folder,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final fileName = imageFile.uri.pathSegments.last;
    return uploadImage(
      imageBytes: bytes,
      fileName: fileName,
      folder: folder,
    );
  }
}
