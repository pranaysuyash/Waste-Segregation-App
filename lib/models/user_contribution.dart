import 'package:cloud_firestore/cloud_firestore.dart';

enum ContributionType {
  newFacility,
  editHours,
  editContact,
  editAcceptedMaterials,
  addPhoto,
  reportClosure,
  otherCorrection,
}

String contributionTypeToString(ContributionType type) {
  switch (type) {
    case ContributionType.newFacility:
      return 'NEW_FACILITY';
    case ContributionType.editHours:
      return 'EDIT_HOURS';
    case ContributionType.editContact:
      return 'EDIT_CONTACT';
    case ContributionType.editAcceptedMaterials:
      return 'EDIT_ACCEPTED_MATERIALS';
    case ContributionType.addPhoto:
      return 'ADD_PHOTO';
    case ContributionType.reportClosure:
      return 'REPORT_CLOSURE';
    case ContributionType.otherCorrection:
      return 'OTHER_CORRECTION';
    default:
      return '';
  }
}

ContributionType contributionTypeFromString(String? typeString) {
  switch (typeString) {
    case 'NEW_FACILITY':
      return ContributionType.newFacility;
    case 'EDIT_HOURS':
      return ContributionType.editHours;
    case 'EDIT_CONTACT':
      return ContributionType.editContact;
    case 'EDIT_ACCEPTED_MATERIALS':
      return ContributionType.editAcceptedMaterials;
    case 'ADD_PHOTO':
      return ContributionType.addPhoto;
    case 'REPORT_CLOSURE':
      return ContributionType.reportClosure;
    case 'OTHER_CORRECTION':
      return ContributionType.otherCorrection;
    default:
      // Handle unknown or null typeString, perhaps return a default or throw error
      return ContributionType.otherCorrection; // Or throw an ArgumentError
  }
}

enum ContributionStatus {
  pendingReview,
  approvedIntegrated,
  rejected,
  needsMoreInfo,
}

String contributionStatusToString(ContributionStatus status) {
  switch (status) {
    case ContributionStatus.pendingReview:
      return 'PENDING_REVIEW';
    case ContributionStatus.approvedIntegrated:
      return 'APPROVED_INTEGRATED';
    case ContributionStatus.rejected:
      return 'REJECTED';
    case ContributionStatus.needsMoreInfo:
      return 'NEEDS_MORE_INFO';
    default:
      return '';
  }
}

ContributionStatus contributionStatusFromString(String? statusString) {
  switch (statusString) {
    case 'PENDING_REVIEW':
      return ContributionStatus.pendingReview;
    case 'APPROVED_INTEGRATED':
      return ContributionStatus.approvedIntegrated;
    case 'REJECTED':
      return ContributionStatus.rejected;
    case 'NEEDS_MORE_INFO':
      return ContributionStatus.needsMoreInfo;
    default:
      return ContributionStatus.pendingReview; // Or throw an ArgumentError
  }
}

class UserContribution {

  UserContribution({
    this.id,
    required this.userId,
    this.facilityId,
    required this.contributionType,
    required this.suggestedData,
    this.userNotes,
    this.photoUrls,
    required this.timestamp,
    required this.status,
    this.reviewNotes,
    this.reviewerId,
    this.reviewTimestamp,
    this.upvotes = 0,
    this.downvotes = 0,
  });

  factory UserContribution.fromJson(Map<String, dynamic> json, String documentId) {
    return UserContribution(
      id: documentId,
      userId: json['userId'] as String,
      facilityId: json['facilityId'] as String?,
      contributionType: contributionTypeFromString(json['contributionType'] as String?),
      suggestedData: json['suggestedData'] as Map<String, dynamic>,
      userNotes: json['userNotes'] as String?,
      photoUrls: (json['photoUrls'] as List<dynamic>?)?.map((e) => e as String).toList(),
      timestamp: json['timestamp'] as Timestamp,
      status: contributionStatusFromString(json['status'] as String?),
      reviewNotes: json['reviewNotes'] as String?,
      reviewerId: json['reviewerId'] as String?,
      reviewTimestamp: json['reviewTimestamp'] as Timestamp?,
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
    );
  }
  final String? id; // Firestore document ID
  final String userId;
  final String? facilityId;
  final ContributionType contributionType;
  final Map<String, dynamic> suggestedData;
  final String? userNotes;
  final List<String>? photoUrls;
  final Timestamp timestamp;
  final ContributionStatus status;
  final String? reviewNotes;
  final String? reviewerId;
  final Timestamp? reviewTimestamp;
  final int upvotes;
  final int downvotes;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'facilityId': facilityId,
      'contributionType': contributionTypeToString(contributionType),
      'suggestedData': suggestedData,
      'userNotes': userNotes,
      'photoUrls': photoUrls,
      'timestamp': timestamp,
      'status': contributionStatusToString(status),
      'reviewNotes': reviewNotes,
      'reviewerId': reviewerId,
      'reviewTimestamp': reviewTimestamp,
      'upvotes': upvotes,
      'downvotes': downvotes,
    };
  }

  UserContribution copyWith({
    String? id,
    String? userId,
    String? facilityId,
    ContributionType? contributionType,
    Map<String, dynamic>? suggestedData,
    String? userNotes,
    List<String>? photoUrls,
    Timestamp? timestamp,
    ContributionStatus? status,
    String? reviewNotes,
    String? reviewerId,
    Timestamp? reviewTimestamp,
    int? upvotes,
    int? downvotes,
  }) {
    return UserContribution(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      facilityId: facilityId ?? this.facilityId,
      contributionType: contributionType ?? this.contributionType,
      suggestedData: suggestedData ?? this.suggestedData,
      userNotes: userNotes ?? this.userNotes,
      photoUrls: photoUrls ?? this.photoUrls,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewTimestamp: reviewTimestamp ?? this.reviewTimestamp,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
    );
  }
} 