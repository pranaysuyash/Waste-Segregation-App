import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/user_contribution.dart';
import '../services/firestore_schema_registry.dart';
import '../utils/firebase_gate.dart';
import '../utils/waste_app_logger.dart';

class ContributionPhotoUploadResult {
  const ContributionPhotoUploadResult({
    required this.uploadedUrls,
    required this.failedIndexes,
  });

  final List<String> uploadedUrls;
  final List<int> failedIndexes;
}

class ContributionSubmissionResult {
  const ContributionSubmissionResult({
    required this.success,
    required this.contributionId,
    required this.uploadedPhotos,
    required this.failedPhotoUploads,
  });

  final bool success;
  final String contributionId;
  final int uploadedPhotos;
  final int failedPhotoUploads;
}

/// Dedicated service for community contribution flows.
///
/// Long-term this should route through a secured backend entrypoint,
/// but it keeps app logic additive and testable right now by enforcing
/// a single submission contract from UI -> Firestore.
class CommunityContributionService {
  CommunityContributionService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<ContributionSubmissionResult> submitContribution({
    required UserContribution contribution,
    List<File> photos = const [],
  }) async {
    if (!isFirebaseEnabled) {
      throw StateError('Contributions are unavailable in this build.');
    }

    final uploadResult = photos.isEmpty
        ? const ContributionPhotoUploadResult(
            uploadedUrls: <String>[],
            failedIndexes: <int>[],
          )
        : await uploadContributionPhotos(images: photos, userId: contribution.userId);

    final submission = contribution.copyWith(
      photoUrls:
          uploadResult.uploadedUrls.isEmpty ? null : uploadResult.uploadedUrls,
    );

    final contributionData = submission.toJson();
    final requiredFieldErrors = FirestoreSchemaValidator.validateRequiredFields(
      FirestoreCollections.userContributions,
      contributionData,
    );
    final unexpectedFieldErrors = FirestoreSchemaValidator.validateAllowedFields(
      FirestoreCollections.userContributions,
      contributionData,
      CommunityContributionSchema.modelFieldNames,
    );

    if (requiredFieldErrors.isNotEmpty) {
      throw StateError(
        'Contribution payload is missing required fields: ${requiredFieldErrors.join(', ')}',
      );
    }

    if (unexpectedFieldErrors.isNotEmpty) {
      WasteAppLogger.warning(
        'Contribution payload has unexpected fields',
        context: {
          'collection': FirestoreCollections.userContributions,
          'errors': unexpectedFieldErrors,
        },
      );
    }

    final docRef = await _firestore
        .collection(FirestoreCollections.userContributions)
        .add(contributionData);

    WasteAppLogger.info('Community contribution submitted', context: {
      'contributionId': docRef.id,
      'contributionType': contributionTypeToString(contribution.contributionType),
      'facilityId': contribution.facilityId,
      'photoUploads': {
        'successCount': uploadResult.uploadedUrls.length,
        'failCount': uploadResult.failedIndexes.length,
      }
    });

    return ContributionSubmissionResult(
      success: true,
      contributionId: docRef.id,
      uploadedPhotos: uploadResult.uploadedUrls.length,
      failedPhotoUploads: uploadResult.failedIndexes.length,
    );
  }

  Future<ContributionPhotoUploadResult> uploadContributionPhotos({
    required List<File> images,
    required String userId,
  }) async {
    final uploadedUrls = <String>[];
    final failedIndexes = <int>[];

    for (var i = 0; i < images.length; i++) {
      final imageFile = images[i];
      try {
        final imageBytes = await imageFile.readAsBytes();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'contribution_${timestamp}_$i.jpg';
        final path = 'contribution_photos/$userId/$fileName';

        final ref = _storage.ref().child(path);
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'purpose': 'facility_contribution',
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        );

        final uploadTask = await ref.putData(imageBytes, metadata);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        uploadedUrls.add(downloadUrl);
      } catch (e, stackTrace) {
        failedIndexes.add(i);
        WasteAppLogger.warning(
          'Error uploading contribution photo',
          context: {
            'userId': userId,
            'photoIndex': i,
            'collection': 'contribution_photos',
          },
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    return ContributionPhotoUploadResult(
      uploadedUrls: uploadedUrls,
      failedIndexes: failedIndexes,
    );
  }
}
