import 'waste_classification.dart';
import 'user_profile.dart';

/// Types of reactions family members can give to classifications.
enum FamilyReactionType {
  /// Like/thumbs up reaction.
  like,
  /// Love/heart reaction.
  love,
  /// Helpful reaction for educational content.
  helpful,
  /// Funny reaction for amusing classifications.
  funny,
  /// Wow/surprised reaction.
  wow,
  /// Sad reaction for concerning waste.
  sad,
}

/// Visibility levels for shared classifications.
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

/// Represents a reaction from a family member to a waste classification.
class FamilyReaction {
  /// The user ID who gave the reaction.
  final String userId;

  /// Display name of the user who reacted.
  final String displayName;

  /// Profile photo URL of the user who reacted.
  final String? photoUrl;

  /// Type of reaction given.
  final FamilyReactionType type;

  /// When the reaction was given.
  final DateTime timestamp;

  /// Optional comment with the reaction.
  final String? comment;

  FamilyReaction({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.type,
    required this.timestamp,
    this.comment,
  });

  /// Creates a copy of this FamilyReaction with the given fields replaced.
  FamilyReaction copyWith({
    String? userId,
    String? displayName,
    String? photoUrl,
    FamilyReactionType? type,
    DateTime? timestamp,
    String? comment,
  }) {
    return FamilyReaction(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      comment: comment ?? this.comment,
    );
  }

  /// Converts this FamilyReaction instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'comment': comment,
    };
  }

  /// Creates a FamilyReaction instance from a JSON map.
  factory FamilyReaction.fromJson(Map<String, dynamic> json) {
    return FamilyReaction(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      type: FamilyReactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => FamilyReactionType.like,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      comment: json['comment'] as String?,
    );
  }
}

/// Represents a comment from a family member on a waste classification.
class FamilyComment {
  /// Unique identifier for this comment.
  final String id;

  /// The user ID who made the comment.
  final String userId;

  /// Display name of the commenter.
  final String displayName;

  /// Profile photo URL of the commenter.
  final String? photoUrl;

  /// The comment text.
  final String text;

  /// When the comment was made.
  final DateTime timestamp;

  /// Whether this comment has been edited.
  final bool isEdited;

  /// When the comment was last edited (if applicable).
  final DateTime? editedAt;

  /// Replies to this comment.
  final List<FamilyComment> replies;

  /// ID of the parent comment if this is a reply.
  final String? parentCommentId;

  FamilyComment({
    required this.id,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.text,
    required this.timestamp,
    this.isEdited = false,
    this.editedAt,
    this.replies = const [],
    this.parentCommentId,
  });

  /// Creates a copy of this FamilyComment with the given fields replaced.
  FamilyComment copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? photoUrl,
    String? text,
    DateTime? timestamp,
    bool? isEdited,
    DateTime? editedAt,
    List<FamilyComment>? replies,
    String? parentCommentId,
  }) {
    return FamilyComment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      replies: replies ?? this.replies,
      parentCommentId: parentCommentId ?? this.parentCommentId,
    );
  }

  /// Converts this FamilyComment instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'replies': replies.map((r) => r.toJson()).toList(),
      'parentCommentId': parentCommentId,
    };
  }

  /// Creates a FamilyComment instance from a JSON map.
  factory FamilyComment.fromJson(Map<String, dynamic> json) {
    return FamilyComment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isEdited: json['isEdited'] as bool? ?? false,
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'] as String)
          : null,
      replies: (json['replies'] as List<dynamic>?)
              ?.map((r) => FamilyComment.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      parentCommentId: json['parentCommentId'] as String?,
    );
  }

  /// Checks if this is a reply to another comment.
  bool get isReply => parentCommentId != null;

  /// Gets the total number of replies (including nested replies).
  int get totalReplies {
    int count = replies.length;
    for (final reply in replies) {
      count += reply.totalReplies;
    }
    return count;
  }
}

/// Location information for a waste classification.
class ClassificationLocation {
  /// Latitude coordinate.
  final double latitude;

  /// Longitude coordinate.
  final double longitude;

  /// Human-readable address or location name.
  final String? address;

  /// Location context (e.g., "Home", "Office", "Park").
  final String? context;

  ClassificationLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.context,
  });

  /// Converts this ClassificationLocation instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'context': context,
    };
  }

  /// Creates a ClassificationLocation instance from a JSON map.
  factory ClassificationLocation.fromJson(Map<String, dynamic> json) {
    return ClassificationLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      context: json['context'] as String?,
    );
  }
}

/// Represents a waste classification that can be shared and viewed by family members.
class SharedWasteClassification {
  /// Unique identifier for this shared classification.
  final String id;

  /// The ID of the family this classification belongs to.
  final String familyId;

  /// The user ID of who made the classification.
  final String classifiedBy;

  /// Display name of the classifier (cached for performance).
  final String classifierName;

  /// Profile photo of the classifier (cached for performance).
  final String? classifierPhotoUrl;

  /// The original waste classification data.
  final WasteClassification classification;

  /// When this classification was made.
  final DateTime timestamp;

  /// Reactions from family members.
  final List<FamilyReaction> reactions;

  /// Comments from family members.
  final List<FamilyComment> comments;

  /// Whether this classification is part of a family challenge.
  final bool isChallenge;

  /// Challenge ID if this is part of a challenge.
  final String? challengeId;

  /// Whether this classification is pinned (highlighted) in the family feed.
  final bool isPinned;

  /// Tags associated with this classification.
  final List<String> tags;

  /// Location where this classification was made (optional).
  final ClassificationLocation? location;

  /// Visibility level for this classification.
  final ClassificationVisibility visibility;

  /// Educational content associated with this classification.
  final String? educationalNote;

  /// Points earned from this classification.
  final int pointsEarned;

  SharedWasteClassification({
    required this.id,
    required this.familyId,
    required this.classifiedBy,
    required this.classifierName,
    this.classifierPhotoUrl,
    required this.classification,
    required this.timestamp,
    this.reactions = const [],
    this.comments = const [],
    this.isChallenge = false,
    this.challengeId,
    this.isPinned = false,
    this.tags = const [],
    this.location,
    this.visibility = ClassificationVisibility.family,
    this.educationalNote,
    required this.pointsEarned,
  });

  /// Creates a copy of this SharedWasteClassification with the given fields replaced.
  SharedWasteClassification copyWith({
    String? id,
    String? familyId,
    String? classifiedBy,
    String? classifierName,
    String? classifierPhotoUrl,
    WasteClassification? classification,
    DateTime? timestamp,
    List<FamilyReaction>? reactions,
    List<FamilyComment>? comments,
    bool? isChallenge,
    String? challengeId,
    bool? isPinned,
    List<String>? tags,
    ClassificationLocation? location,
    ClassificationVisibility? visibility,
    String? educationalNote,
    int? pointsEarned,
  }) {
    return SharedWasteClassification(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      classifiedBy: classifiedBy ?? this.classifiedBy,
      classifierName: classifierName ?? this.classifierName,
      classifierPhotoUrl: classifierPhotoUrl ?? this.classifierPhotoUrl,
      classification: classification ?? this.classification,
      timestamp: timestamp ?? this.timestamp,
      reactions: reactions ?? this.reactions,
      comments: comments ?? this.comments,
      isChallenge: isChallenge ?? this.isChallenge,
      challengeId: challengeId ?? this.challengeId,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      visibility: visibility ?? this.visibility,
      educationalNote: educationalNote ?? this.educationalNote,
      pointsEarned: pointsEarned ?? this.pointsEarned,
    );
  }

  /// Converts this SharedWasteClassification instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'classifiedBy': classifiedBy,
      'classifierName': classifierName,
      'classifierPhotoUrl': classifierPhotoUrl,
      'classification': classification.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'comments': comments.map((c) => c.toJson()).toList(),
      'isChallenge': isChallenge,
      'challengeId': challengeId,
      'isPinned': isPinned,
      'tags': tags,
      'location': location?.toJson(),
      'visibility': visibility.toString().split('.').last,
      'educationalNote': educationalNote,
      'pointsEarned': pointsEarned,
    };
  }

  /// Creates a SharedWasteClassification instance from a JSON map.
  factory SharedWasteClassification.fromJson(Map<String, dynamic> json) {
    return SharedWasteClassification(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      classifiedBy: json['classifiedBy'] as String,
      classifierName: json['classifierName'] as String,
      classifierPhotoUrl: json['classifierPhotoUrl'] as String?,
      classification: WasteClassification.fromJson(json['classification'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
      reactions: (json['reactions'] as List<dynamic>?)
              ?.map((r) => FamilyReaction.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      comments: (json['comments'] as List<dynamic>?)
              ?.map((c) => FamilyComment.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      isChallenge: json['isChallenge'] as bool? ?? false,
      challengeId: json['challengeId'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
      tags: List<String>.from(json['tags'] as List? ?? []),
      location: json['location'] != null
          ? ClassificationLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      visibility: ClassificationVisibility.values.firstWhere(
        (e) => e.toString().split('.').last == json['visibility'],
        orElse: () => ClassificationVisibility.family,
      ),
      educationalNote: json['educationalNote'] as String?,
      pointsEarned: json['pointsEarned'] as int,
    );
  }

  /// Gets reactions of a specific type.
  List<FamilyReaction> getReactionsByType(FamilyReactionType type) {
    return reactions.where((r) => r.type == type).toList();
  }

  /// Gets the count of reactions by type.
  Map<FamilyReactionType, int> get reactionCounts {
    final Map<FamilyReactionType, int> counts = {};
    for (final reaction in reactions) {
      counts[reaction.type] = (counts[reaction.type] ?? 0) + 1;
    }
    return counts;
  }

  /// Checks if a specific user has reacted.
  bool hasUserReacted(String userId) {
    return reactions.any((r) => r.userId == userId);
  }

  /// Gets the reaction from a specific user.
  FamilyReaction? getUserReaction(String userId) {
    try {
      return reactions.firstWhere((r) => r.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Gets the total number of interactions (reactions + comments).
  int get totalInteractions => reactions.length + comments.length;

  /// Gets a summary of the top reactions.
  List<FamilyReactionType> get topReactionTypes {
    final counts = reactionCounts;
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).take(3).toList();
  }

  /// Checks if the classification is popular (has many interactions).
  bool get isPopular => totalInteractions >= 5;

  /// Gets the engagement score based on reactions and comments.
  double get engagementScore {
    // Weight reactions and comments differently
    return (reactions.length * 1.0) + (comments.length * 2.0);
  }

  /// Gets the most recent activity timestamp.
  DateTime get lastActivityTimestamp {
    DateTime latest = timestamp;
    
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
}
