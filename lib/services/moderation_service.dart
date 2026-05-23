import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Report reasons for community content.
enum ReportReason {
  inappropriate,
  spam,
  misinformation,
  harmful,
  privacy,
  other,
}

/// Status of a content report.
enum ReportStatus {
  pending,
  reviewed,
  dismissed,
  actioned,
}

/// A content report submitted by a user.
class ContentReport {
  const ContentReport({
    required this.id,
    required this.postId,
    required this.reportedBy,
    required this.reason,
    this.details,
    required this.status,
    required this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
    this.resolution,
  });

  final String id;
  final String postId;
  final String reportedBy;
  final ReportReason reason;
  final String? details;
  final ReportStatus status;
  final DateTime createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? resolution;

  factory ContentReport.fromFirestore(Map<String, dynamic> data) {
    return ContentReport(
      id: data['id'] as String? ?? '',
      postId: data['postId'] as String? ?? '',
      reportedBy: data['reportedBy'] as String? ?? '',
      reason: ReportReason.values.firstWhere(
        (r) => r.name == data['reason'],
        orElse: () => ReportReason.other,
      ),
      details: data['details'] as String?,
      status: ReportStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ReportStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      resolution: data['resolution'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'postId': postId,
        'reportedBy': reportedBy,
        'reason': reason.name,
        'details': details,
        'status': status.name,
        'createdAt': FieldValue.serverTimestamp(),
        'reviewedBy': reviewedBy,
        'reviewedAt': reviewedAt != null
            ? Timestamp.fromDate(reviewedAt!)
            : null,
        'resolution': resolution,
      };
}

/// Service for reporting and moderating community content.
class ModerationService {
  ModerationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const _reportsCollection = 'community_reports';
  static const _feedCollection = 'community_feed';

  /// Number of reports before a post is auto-hidden.
  static const autoHideThreshold = 3;

  /// Submit a report for a community post.
  Future<void> reportPost({
    required String postId,
    required ReportReason reason,
    String? details,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be authenticated to report');

    final reportId =
        '${postId}_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';

    final report = ContentReport(
      id: reportId,
      postId: postId,
      reportedBy: user.uid,
      reason: reason,
      details: details,
      status: ReportStatus.pending,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(_reportsCollection)
        .doc(reportId)
        .set(report.toFirestore());

    WasteAppLogger.info('content_reported', context: {
      'post_id': postId,
      'reason': reason.name,
      'reporter': user.uid,
    });

    // Check if auto-hide threshold is reached.
    await _checkAutoHide(postId);
  }

  /// Check if a post should be auto-hidden based on report count.
  Future<void> _checkAutoHide(String postId) async {
    final reports = await _firestore
        .collection(_reportsCollection)
        .where('postId', isEqualTo: postId)
        .where('status', isEqualTo: ReportStatus.pending.name)
        .get();

    if (reports.size >= autoHideThreshold) {
      await _hidePost(postId, reason: 'Auto-hidden: ${reports.size} reports');
    }
  }

  /// Hide a post from the community feed.
  Future<void> _hidePost(String postId, {String? reason}) async {
    await _firestore.collection(_feedCollection).doc(postId).update({
      'isHidden': true,
      'hiddenReason': reason ?? 'Reported',
      'hiddenAt': FieldValue.serverTimestamp(),
    });

    WasteAppLogger.info('post_hidden', context: {
      'post_id': postId,
      'reason': reason,
    });
  }

  /// Review a report (admin action).
  Future<void> reviewReport({
    required String reportId,
    required ReportStatus resolution,
    required String resolutionNote,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be authenticated');

    await _firestore.collection(_reportsCollection).doc(reportId).update({
      'status': resolution.name,
      'reviewedBy': user.uid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'resolution': resolutionNote,
    });

    // If actioned, also hide the post.
    if (resolution == ReportStatus.actioned) {
      final reportDoc =
          await _firestore.collection(_reportsCollection).doc(reportId).get();
      final postId = reportDoc.data()?['postId'] as String?;
      if (postId != null) {
        await _hidePost(postId, reason: 'Moderator action: $resolutionNote');
      }
    }
  }

  /// Get reports for a specific post (admin view).
  Future<List<ContentReport>> getReportsForPost(String postId) async {
    final snapshot = await _firestore
        .collection(_reportsCollection)
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ContentReport.fromFirestore(doc.data()))
        .toList();
  }

  /// Get all pending reports (admin view).
  Future<List<ContentReport>> getPendingReports() async {
    final snapshot = await _firestore
        .collection(_reportsCollection)
        .where('status', isEqualTo: ReportStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => ContentReport.fromFirestore(doc.data()))
        .toList();
  }

  /// Check if the current user has already reported a post.
  Future<bool> hasUserReported(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final snapshot = await _firestore
        .collection(_reportsCollection)
        .where('postId', isEqualTo: postId)
        .where('reportedBy', isEqualTo: user.uid)
        .limit(1)
        .get();

    return snapshot.size > 0;
  }
}
