import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/moderation_service.dart';

void main() {
  group('ModerationService', () {
    test('ReportReason enum has expected values', () {
      expect(ReportReason.values, hasLength(6));
      expect(ReportReason.values.map((r) => r.name), containsAll([
        'inappropriate',
        'spam',
        'misinformation',
        'harmful',
        'privacy',
        'other',
      ]));
    });

    test('ReportStatus enum has expected values', () {
      expect(ReportStatus.values, hasLength(4));
      expect(ReportStatus.values.map((s) => s.name), containsAll([
        'pending',
        'reviewed',
        'dismissed',
        'actioned',
      ]));
    });

    test('ContentReport.toFirestore includes all required fields', () {
      final report = ContentReport(
        id: 'test_report_1',
        postId: 'post_123',
        reportedBy: 'user_abc',
        reason: ReportReason.spam,
        status: ReportStatus.pending,
        createdAt: DateTime(2026, 5, 23),
      );

      final json = report.toFirestore();
      expect(json['id'], equals('test_report_1'));
      expect(json['postId'], equals('post_123'));
      expect(json['reportedBy'], equals('user_abc'));
      expect(json['reason'], equals('spam'));
      expect(json['status'], equals('pending'));
    });

    test('ContentReport.fromFirestore parses correctly', () {
      final data = {
        'id': 'r1',
        'postId': 'p1',
        'reportedBy': 'u1',
        'reason': 'harmful',
        'details': 'Contains dangerous instructions',
        'status': 'reviewed',
        'reviewedBy': 'admin1',
        'resolution': 'Post removed',
      };

      final report = ContentReport.fromFirestore(data);
      expect(report.id, equals('r1'));
      expect(report.reason, equals(ReportReason.harmful));
      expect(report.status, equals(ReportStatus.reviewed));
      expect(report.details, equals('Contains dangerous instructions'));
    });

    test('ContentReport.fromFirestore handles unknown reason', () {
      final data = {
        'id': 'r2',
        'postId': 'p2',
        'reportedBy': 'u2',
        'reason': 'nonexistent_reason',
        'status': 'unknown_status',
      };

      final report = ContentReport.fromFirestore(data);
      expect(report.reason, equals(ReportReason.other));
      expect(report.status, equals(ReportStatus.pending));
    });

    test('autoHideThreshold is 3', () {
      expect(ModerationService.autoHideThreshold, equals(3));
    });
  });
}
