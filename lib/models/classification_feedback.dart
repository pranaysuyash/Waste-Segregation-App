import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Represents user feedback on an AI classification result.
class ClassificationFeedback {
  ClassificationFeedback({
    String? id,
    required this.userId,
    required this.originalClassificationId,
    required this.originalAIItemName,
    required this.originalAICategory,
    this.originalAIMaterial,
    this.originalAIConfidence,
    this.userSuggestedItemName,
    required this.userSuggestedCategory,
    this.userSuggestedMaterial,
    this.userNotes,
    this.reviewStatus = 'pending_review',
    this.adminReviewerId,
    this.adminReviewTimestamp,
    this.adminNotes,
    String? appVersion,
    this.deviceInfo,
    Timestamp? feedbackTimestamp,
  })  : id = id ?? const Uuid().v4(),
        appVersion = appVersion ?? '0.1.0',
        feedbackTimestamp = feedbackTimestamp ?? Timestamp.now();

  factory ClassificationFeedback.fromJson(
      Map<String, dynamic> json, String documentId) {
    return ClassificationFeedback(
      id: documentId,
      userId: json['userId'] as String,
      originalClassificationId: json['originalClassificationId'] as String,
      originalAIItemName: json['originalAIItemName'] as String,
      originalAICategory: json['originalAICategory'] as String,
      originalAIMaterial: json['originalAIMaterial'] as String?,
      originalAIConfidence: (json['originalAIConfidence'] as num?)?.toDouble(),
      userSuggestedItemName: json['userSuggestedItemName'] as String?,
      userSuggestedCategory: json['userSuggestedCategory'] as String,
      userSuggestedMaterial: json['userSuggestedMaterial'] as String?,
      userNotes: json['userNotes'] as String?,
      feedbackTimestamp: json['feedbackTimestamp'] as Timestamp?,
      reviewStatus: json['reviewStatus'] as String? ?? 'pending_review',
      adminReviewerId: json['adminReviewerId'] as String?,
      adminReviewTimestamp: json['adminReviewTimestamp'] as Timestamp?,
      adminNotes: json['adminNotes'] as String?,
      appVersion: json['appVersion'] as String? ?? '0.1.0',
      deviceInfo: json['deviceInfo'] as Map<String, dynamic>?,
    );
  }

  final String id;
  final String userId;
  final String originalClassificationId;
  final String originalAIItemName;
  final String originalAICategory;
  final String? originalAIMaterial;
  final double? originalAIConfidence;
  final String? userSuggestedItemName;
  final String userSuggestedCategory;
  final String? userSuggestedMaterial;
  final String? userNotes;
  final Timestamp feedbackTimestamp;
  final String reviewStatus;
  final String? adminReviewerId;
  final Timestamp? adminReviewTimestamp;
  final String? adminNotes;
  final String appVersion;
  final Map<String, dynamic>? deviceInfo;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'originalClassificationId': originalClassificationId,
      'originalAIItemName': originalAIItemName,
      'originalAICategory': originalAICategory,
      'originalAIMaterial': originalAIMaterial,
      'originalAIConfidence': originalAIConfidence,
      'userSuggestedItemName': userSuggestedItemName,
      'userSuggestedCategory': userSuggestedCategory,
      'userSuggestedMaterial': userSuggestedMaterial,
      'userNotes': userNotes,
      'feedbackTimestamp': feedbackTimestamp,
      'reviewStatus': reviewStatus,
      'adminReviewerId': adminReviewerId,
      'adminReviewTimestamp': adminReviewTimestamp,
      'adminNotes': adminNotes,
      'appVersion': appVersion,
      'deviceInfo': deviceInfo,
    };
  }
}
