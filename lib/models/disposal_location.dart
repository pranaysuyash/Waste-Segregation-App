import 'package:cloud_firestore/cloud_firestore.dart';

enum FacilitySource {
  adminEntered,
  userSuggestedIntegrated,
  bulkImported,
}

String facilitySourceToString(FacilitySource source) {
  switch (source) {
    case FacilitySource.adminEntered:
      return 'ADMIN_ENTERED';
    case FacilitySource.userSuggestedIntegrated:
      return 'USER_SUGGESTED_INTEGRATED';
    case FacilitySource.bulkImported:
      return 'BULK_IMPORTED';
  }
}

FacilitySource facilitySourceFromString(String? sourceString) {
  switch (sourceString) {
    case 'ADMIN_ENTERED':
      return FacilitySource.adminEntered;
    case 'USER_SUGGESTED_INTEGRATED':
      return FacilitySource.userSuggestedIntegrated;
    case 'BULK_IMPORTED':
      return FacilitySource.bulkImported;
    default:
      return FacilitySource.adminEntered; // Default or throw error
  }
}

class DisposalLocationPhoto {
  DisposalLocationPhoto({
    required this.url,
    this.uploadedByUserId,
    this.caption,
    this.uploadTimestamp,
  });

  factory DisposalLocationPhoto.fromJson(Map<String, dynamic> json) {
    return DisposalLocationPhoto(
      url: json['url'] as String,
      uploadedByUserId: json['uploadedByUserId'] as String?,
      caption: json['caption'] as String?,
      uploadTimestamp: json['uploadTimestamp'] as Timestamp?,
    );
  }
  final String url;
  final String? uploadedByUserId; // UID of the user who uploaded, if applicable
  final String? caption;
  final Timestamp? uploadTimestamp;

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'uploadedByUserId': uploadedByUserId,
      'caption': caption,
      'uploadTimestamp': uploadTimestamp,
    };
  }

  DisposalLocationPhoto copyWith({
    String? url,
    String? uploadedByUserId,
    String? caption,
    Timestamp? uploadTimestamp,
  }) {
    return DisposalLocationPhoto(
      url: url ?? this.url,
      uploadedByUserId: uploadedByUserId ?? this.uploadedByUserId,
      caption: caption ?? this.caption,
      uploadTimestamp: uploadTimestamp ?? this.uploadTimestamp,
    );
  }
}

class DisposalLocation {
  DisposalLocation({
    this.id,
    required this.name,
    required this.address,
    required this.coordinates,
    required this.operatingHours,
    required this.contactInfo,
    required this.acceptedMaterials,
    this.photos,
    this.lastAdminUpdate,
    this.lastVerifiedByAdmin,
    required this.source,
    this.isActive = true,
  });

  factory DisposalLocation.fromJson(Map<String, dynamic> json, String documentId) {
    return DisposalLocation(
      id: documentId,
      name: json['name'] as String,
      address: json['address'] as String,
      coordinates: json['coordinates'] as GeoPoint,
      operatingHours: Map<String, String>.from(json['operatingHours'] as Map),
      contactInfo: Map<String, String>.from(json['contactInfo'] as Map),
      acceptedMaterials: (json['acceptedMaterials'] as List<dynamic>).map((e) => e as String).toList(),
      photos: (json['photos'] as List<dynamic>?)
          ?.map((p) => DisposalLocationPhoto.fromJson(p as Map<String, dynamic>))
          .toList(),
      lastAdminUpdate: json['lastAdminUpdate'] as Timestamp?,
      lastVerifiedByAdmin: json['lastVerifiedByAdmin'] as Timestamp?,
      source: facilitySourceFromString(json['source'] as String?),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
  final String? id; // Firestore document ID
  final String name;
  final String address;
  final GeoPoint coordinates;
  final Map<String, String> operatingHours; // e.g., {"monday": "9am-5pm", ...}
  final Map<String, String> contactInfo; // e.g., {"phone": "...", "email": "...", "website": "..."}
  final List<String> acceptedMaterials;
  final List<DisposalLocationPhoto>? photos;
  final Timestamp? lastAdminUpdate;
  final Timestamp? lastVerifiedByAdmin;
  final FacilitySource source;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'coordinates': coordinates,
      'operatingHours': operatingHours,
      'contactInfo': contactInfo,
      'acceptedMaterials': acceptedMaterials,
      'photos': photos?.map((p) => p.toJson()).toList(),
      'lastAdminUpdate': lastAdminUpdate,
      'lastVerifiedByAdmin': lastVerifiedByAdmin,
      'source': facilitySourceToString(source),
      'isActive': isActive,
    };
  }

  DisposalLocation copyWith({
    String? id,
    String? name,
    String? address,
    GeoPoint? coordinates,
    Map<String, String>? operatingHours,
    Map<String, String>? contactInfo,
    List<String>? acceptedMaterials,
    List<DisposalLocationPhoto>? photos,
    Timestamp? lastAdminUpdate,
    Timestamp? lastVerifiedByAdmin,
    FacilitySource? source,
    bool? isActive,
  }) {
    return DisposalLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      coordinates: coordinates ?? this.coordinates,
      operatingHours: operatingHours ?? this.operatingHours,
      contactInfo: contactInfo ?? this.contactInfo,
      acceptedMaterials: acceptedMaterials ?? this.acceptedMaterials,
      photos: photos ?? this.photos,
      lastAdminUpdate: lastAdminUpdate ?? this.lastAdminUpdate,
      lastVerifiedByAdmin: lastVerifiedByAdmin ?? this.lastVerifiedByAdmin,
      source: source ?? this.source,
      isActive: isActive ?? this.isActive,
    );
  }
}
