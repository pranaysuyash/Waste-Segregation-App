import 'package:uuid/uuid.dart';
import 'waste_classification.dart';
// Import family reaction/comment classes from gamification.dart
import 'gamification.dart' show FamilyReaction, FamilyComment, ClassificationLocation;

/// Types of visibility levels for shared classifications.
enum ClassificationVisibility {
  /// Visible only to the classifier.
  private,
  /// Visible to family members only.
  family,
  /// Visible to friends and family.
  friends,
  /// Visible to everyone (public).
  public,
}

/// Represents a waste classification that has been shared with family members.
class SharedWasteClassification {
  /// Unique identifier for this shared classification.
  final String id;

  /// The original waste classification.
  final WasteClassification classification;

  /// The user ID who shared this classification.
  final String sharedBy;

  /// Display name of the user who shared this.
  final String sharedByDisplayName;

  /// Profile photo URL of the user who shared this.
  final String? sharedByPhotoUrl;

  /// When this was shared.
  final DateTime sharedAt;

  /// Family ID this classification was shared with.
  final String familyId;

  /// Reactions from family members.
  final List<FamilyReaction> reactions;

  /// Comments from family members.
  final List<FamilyComment> comments;

  /// Location where this classification was made (optional).
  final ClassificationLocation? location;

  /// Whether this classification is visible to all family members.
  final bool isVisible;

  /// Custom tags added by family members.
  final List<String> familyTags;

  SharedWasteClassification({
    required this.id,
    required this.classification,
    required this.sharedBy,
    required this.sharedByDisplayName,
    this.sharedByPhotoUrl,
    required this.sharedAt,
    required this.familyId,
    this.reactions = const [],
    this.comments = const [],
    this.location,
    this.isVisible = true,
    this.familyTags = const [],
  });

  /// Creates a SharedWasteClassification from a regular WasteClassification.
  factory SharedWasteClassification.fromClassification({
    required WasteClassification classification,
    required String sharedBy,
    required String sharedByDisplayName,
    String? sharedByPhotoUrl,
    required String familyId,
    ClassificationLocation? location,
    List<String> familyTags = const [],
  }) {
    return SharedWasteClassification(
      id: const Uuid().v4(),
      classification: classification,
      sharedBy: sharedBy,
      sharedByDisplayName: sharedByDisplayName,
      sharedByPhotoUrl: sharedByPhotoUrl,
      sharedAt: DateTime.now(),
      familyId: familyId,
      location: location,
      familyTags: familyTags,
    );
  }

  /// Creates a copy of this SharedWasteClassification with the given fields replaced.
  SharedWasteClassification copyWith({
    String? id,
    WasteClassification? classification,
    String? sharedBy,
    String? sharedByDisplayName,
    String? sharedByPhotoUrl,
    DateTime? sharedAt,
    String? familyId,
    List<FamilyReaction>? reactions,
    List<FamilyComment>? comments,
    ClassificationLocation? location,
    bool? isVisible,
    List<String>? familyTags,
  }) {
    return SharedWasteClassification(
      id: id ?? this.id,
      classification: classification ?? this.classification,
      sharedBy: sharedBy ?? this.sharedBy,
      sharedByDisplayName: sharedByDisplayName ?? this.sharedByDisplayName,
      sharedByPhotoUrl: sharedByPhotoUrl ?? this.sharedByPhotoUrl,
      sharedAt: sharedAt ?? this.sharedAt,
      familyId: familyId ?? this.familyId,
      reactions: reactions ?? this.reactions,
      comments: comments ?? this.comments,
      location: location ?? this.location,
      isVisible: isVisible ?? this.isVisible,
      familyTags: familyTags ?? this.familyTags,
    );
  }

  /// Converts this SharedWasteClassification instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classification': classification.toJson(),
      'sharedBy': sharedBy,
      'sharedByDisplayName': sharedByDisplayName,
      'sharedByPhotoUrl': sharedByPhotoUrl,
      'sharedAt': sharedAt.toIso8601String(),
      'familyId': familyId,
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'comments': comments.map((c) => c.toJson()).toList(),
      'location': location?.toJson(),
      'isVisible': isVisible,
      'familyTags': familyTags,
    };
  }

  /// Creates a SharedWasteClassification instance from a JSON map.
  factory SharedWasteClassification.fromJson(Map<String, dynamic> json) {
    return SharedWasteClassification(
      id: json['id'] as String,
      classification: WasteClassification.fromJson(json['classification'] as Map<String, dynamic>),
      sharedBy: json['sharedBy'] as String,
      sharedByDisplayName: json['sharedByDisplayName'] as String,
      sharedByPhotoUrl: json['sharedByPhotoUrl'] as String?,
      sharedAt: DateTime.parse(json['sharedAt'] as String),
      familyId: json['familyId'] as String,
      reactions: (json['reactions'] as List<dynamic>?)
              ?.map((r) => FamilyReaction.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      comments: (json['comments'] as List<dynamic>?)
              ?.map((c) => FamilyComment.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      location: json['location'] != null
          ? ClassificationLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      isVisible: json['isVisible'] as bool? ?? true,
      familyTags: List<String>.from(json['familyTags'] as List? ?? []),
    );
  }

  /// Gets the most recent activity timestamp.
  DateTime get lastActivityTimestamp {
    DateTime latest = sharedAt;
    
    for (final reaction in reactions) {
      if (reaction.timestamp.isAfter(latest)) {
        latest = reaction.timestamp;
      }
    }
    
    for (final comment in comments) {
      if (comment.timestamp.isAfter(latest)) {
        latest = comment.timestamp;
      }
    }
    
    return latest;
  }

  /// Gets the total engagement count (reactions + comments).
  int get engagementCount => reactions.length + comments.length;

  /// Checks if a specific user has reacted to this classification.
  bool hasUserReacted(String userId) {
    return reactions.any((reaction) => reaction.userId == userId);
  }

  /// Gets a specific user's reaction, if any.
  FamilyReaction? getUserReaction(String userId) {
    try {
      return reactions.firstWhere((reaction) => reaction.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Gets top-level comments (excluding replies).
  List<FamilyComment> get topLevelComments {
    return comments.where((comment) => !comment.isReply).toList();
  }

  /// Gets the total number of comments including replies.
  int get totalCommentCount {
    int count = comments.length;
    for (final comment in comments) {
      count += comment.totalReplies;
    }
    return count;
  }

  /// Checks if this classification is from today.
  bool get isFromToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final classificationDate = DateTime(sharedAt.year, sharedAt.month, sharedAt.day);
    return classificationDate == today;
  }

  /// Gets a user-friendly time display for when this was shared.
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(sharedAt);

    if (difference.inDays > 7) {
      return '${sharedAt.day}/${sharedAt.month}/${sharedAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
