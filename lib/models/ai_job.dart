import 'token_wallet.dart';

/// AI processing job for batch queue system
class AiJob {
  const AiJob({
    required this.id,
    required this.userId,
    required this.imagePath,
    required this.speed,
    required this.status,
    required this.createdAt,
    this.result,
    this.completedAt,
    this.errorMessage,
    this.priority = false,
    this.tokensSpent = 0,
    this.metadata,
    // Enhanced fields for better UX
    this.queuePosition,
    this.estimatedCompletion,
  });

  factory AiJob.fromJson(Map<String, dynamic> json) {
    return AiJob(
      id: json['id'],
      userId: json['userId'],
      imagePath: json['imagePath'],
      speed: AnalysisSpeed.values.firstWhere(
        (e) => e.toString() == json['speed'],
      ),
      status: AiJobStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
      result: json['result']?.cast<String, dynamic>(),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      errorMessage: json['errorMessage'],
      priority: json['priority'] ?? false,
      tokensSpent: json['tokensSpent'] ?? 0,
      metadata: json['metadata']?.cast<String, dynamic>(),
      queuePosition: json['queuePosition'],
      estimatedCompletion: json['estimatedCompletion'] != null ? DateTime.parse(json['estimatedCompletion']) : null,
    );
  }

  /// Create a new job for the queue
  factory AiJob.create({
    required String userId,
    required String imagePath,
    required AnalysisSpeed speed,
    bool priority = false,
    Map<String, dynamic>? metadata,
  }) {
    return AiJob(
      id: 'job_${DateTime.now().millisecondsSinceEpoch}_${userId.substring(0, 8)}',
      userId: userId,
      imagePath: imagePath,
      speed: speed,
      status: AiJobStatus.queued,
      createdAt: DateTime.now(),
      priority: priority,
      tokensSpent: speed.cost,
      metadata: metadata,
    );
  }

  final String id;
  final String userId;
  final String imagePath; // Storage path (gs://bucket/path)
  final AnalysisSpeed speed;
  final AiJobStatus status;
  final DateTime createdAt;
  final Map<String, dynamic>? result; // Classification result
  final DateTime? completedAt;
  final String? errorMessage;
  final bool priority; // Priority queue for premium users
  final int tokensSpent; // Tokens deducted for this job
  final Map<String, dynamic>? metadata;

  // Enhanced fields for better UX
  final int? queuePosition; // Position in queue (1-based)
  final DateTime? estimatedCompletion; // Estimated completion time

  /// Check if job is still processing
  bool get isProcessing => status == AiJobStatus.queued || status == AiJobStatus.processing;

  /// Check if job is completed (success or failure)
  bool get isCompleted =>
      status == AiJobStatus.completed || status == AiJobStatus.failed || status == AiJobStatus.cancelled;

  /// Get estimated completion time based on queue position
  Duration? getEstimatedCompletion(int queuePosition) {
    if (isCompleted) return null;

    switch (speed) {
      case AnalysisSpeed.instant:
        return const Duration(seconds: 30); // Real-time processing
      case AnalysisSpeed.batch:
        // Estimate based on queue position (5 minutes per job ahead)
        return Duration(minutes: queuePosition * 5);
    }
  }

  /// Get user-friendly status description
  String get statusDescription {
    switch (status) {
      case AiJobStatus.queued:
        if (queuePosition != null) {
          return 'Queued (position $queuePosition)';
        }
        return 'Queued for processing';
      case AiJobStatus.processing:
        return 'Processing your image...';
      case AiJobStatus.completed:
        return 'Analysis complete';
      case AiJobStatus.failed:
        return 'Analysis failed';
      case AiJobStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get estimated completion time string
  String get estimatedCompletionString {
    if (estimatedCompletion == null) return 'Unknown';
    final now = DateTime.now();
    if (estimatedCompletion!.isBefore(now)) return 'Processing...';

    final diff = estimatedCompletion!.difference(now);
    if (diff.inMinutes < 5) return 'Less than 5 minutes';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes';
    if (diff.inHours < 24) return '${diff.inHours} hours';
    return '${diff.inDays} days';
  }

  /// Check if job is actively processing
  bool get isActive {
    return status == AiJobStatus.queued || status == AiJobStatus.processing;
  }

  /// Get processing duration if completed
  Duration? get processingDuration {
    if (completedAt == null) return null;
    return completedAt!.difference(createdAt);
  }

  AiJob copyWith({
    String? id,
    String? userId,
    String? imagePath,
    AnalysisSpeed? speed,
    AiJobStatus? status,
    DateTime? createdAt,
    Map<String, dynamic>? result,
    DateTime? completedAt,
    String? errorMessage,
    bool? priority,
    int? tokensSpent,
    Map<String, dynamic>? metadata,
    int? queuePosition,
    DateTime? estimatedCompletion,
  }) {
    return AiJob(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imagePath: imagePath ?? this.imagePath,
      speed: speed ?? this.speed,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      result: result ?? this.result,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      priority: priority ?? this.priority,
      tokensSpent: tokensSpent ?? this.tokensSpent,
      metadata: metadata ?? this.metadata,
      queuePosition: queuePosition ?? this.queuePosition,
      estimatedCompletion: estimatedCompletion ?? this.estimatedCompletion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'imagePath': imagePath,
      'speed': speed.toString(),
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'result': result,
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
      'priority': priority,
      'tokensSpent': tokensSpent,
      'metadata': metadata,
      'queuePosition': queuePosition,
      'estimatedCompletion': estimatedCompletion?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AiJob(id: $id, status: $status, speed: $speed, tokens: $tokensSpent)';
  }
}

/// Status of an AI processing job
enum AiJobStatus {
  queued, // Waiting in queue
  processing, // Currently being processed
  completed, // Successfully completed
  failed, // Failed with error
  cancelled, // Cancelled by user or system
}

/// Queue statistics for monitoring
class QueueStats {
  const QueueStats({
    required this.totalJobs,
    required this.queuedJobs,
    required this.processingJobs,
    required this.completedToday,
    required this.failedToday,
    required this.averageWaitTime,
    required this.lastUpdated,
    // Enhanced fields for better monitoring and UX
    required this.averageProcessingTime,
    required this.estimatedWaitTime,
    required this.successRate,
    required this.failureRate,
    required this.pendingJobs,
  });

  factory QueueStats.fromJson(Map<String, dynamic> json) {
    return QueueStats(
      totalJobs: json['totalJobs'],
      queuedJobs: json['queuedJobs'],
      processingJobs: json['processingJobs'],
      completedToday: json['completedToday'],
      failedToday: json['failedToday'],
      averageWaitTime: Duration(milliseconds: json['averageWaitTimeMs']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      // Enhanced fields with fallbacks for backward compatibility
      averageProcessingTime: Duration(milliseconds: json['averageProcessingTimeMs'] ?? 30000), // 30s default
      estimatedWaitTime: Duration(milliseconds: json['estimatedWaitTimeMs'] ?? json['averageWaitTimeMs']),
      successRate: (json['successRate'] ?? 0.95).toDouble(), // 95% default
      failureRate: (json['failureRate'] ?? 0.05).toDouble(), // 5% default
      pendingJobs: json['pendingJobs'] ?? json['queuedJobs'], // Use queuedJobs as fallback
    );
  }

  /// Create empty stats for initialization
  factory QueueStats.empty() {
    return QueueStats(
      totalJobs: 0,
      queuedJobs: 0,
      processingJobs: 0,
      completedToday: 0,
      failedToday: 0,
      averageWaitTime: Duration.zero,
      lastUpdated: DateTime.now(),
      averageProcessingTime: const Duration(seconds: 30),
      estimatedWaitTime: Duration.zero,
      successRate: 1.0,
      failureRate: 0.0,
      pendingJobs: 0,
    );
  }

  final int totalJobs;
  final int queuedJobs;
  final int processingJobs;
  final int completedToday;
  final int failedToday;
  final Duration averageWaitTime;
  final DateTime lastUpdated;

  // Enhanced monitoring fields
  final Duration averageProcessingTime; // How long each job takes to process
  final Duration estimatedWaitTime; // Estimated wait time for new jobs
  final double successRate; // Success rate (0.0 - 1.0)
  final double failureRate; // Failure rate (0.0 - 1.0)
  final int pendingJobs; // Alias for queuedJobs for clarity

  /// Get queue health status
  QueueHealth get health {
    if (queuedJobs > 1000) return QueueHealth.overloaded;
    if (queuedJobs > 500) return QueueHealth.busy;
    if (queuedJobs > 100) return QueueHealth.moderate;
    return QueueHealth.healthy;
  }

  /// Get user-friendly wait time estimate
  String get waitTimeEstimate {
    final minutes = estimatedWaitTime.inMinutes;
    if (minutes < 5) return 'Less than 5 minutes';
    if (minutes < 30) return '$minutes minutes';
    if (minutes < 120) return '${(minutes / 60).round()} hour';
    return '${(minutes / 60).round()} hours';
  }

  /// Get user-friendly processing time
  String get processingTimeEstimate {
    final seconds = averageProcessingTime.inSeconds;
    if (seconds < 60) return '$seconds seconds';
    final minutes = averageProcessingTime.inMinutes;
    return '$minutes minutes';
  }

  /// Get success rate as percentage string
  String get successRatePercentage {
    return '${(successRate * 100).toStringAsFixed(1)}%';
  }

  /// Get failure rate as percentage string
  String get failureRatePercentage {
    return '${(failureRate * 100).toStringAsFixed(1)}%';
  }

  /// Calculate estimated completion time for a new job
  DateTime get estimatedCompletionTime {
    return DateTime.now().add(estimatedWaitTime).add(averageProcessingTime);
  }

  /// Get queue position estimate for new jobs
  int get queuePositionForNewJob {
    return pendingJobs + 1;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalJobs': totalJobs,
      'queuedJobs': queuedJobs,
      'processingJobs': processingJobs,
      'completedToday': completedToday,
      'failedToday': failedToday,
      'averageWaitTimeMs': averageWaitTime.inMilliseconds,
      'lastUpdated': lastUpdated.toIso8601String(),
      // Enhanced fields
      'averageProcessingTimeMs': averageProcessingTime.inMilliseconds,
      'estimatedWaitTimeMs': estimatedWaitTime.inMilliseconds,
      'successRate': successRate,
      'failureRate': failureRate,
      'pendingJobs': pendingJobs,
    };
  }
}

/// Queue health indicators
enum QueueHealth {
  healthy, // < 100 jobs
  moderate, // 100-500 jobs
  busy, // 500-1000 jobs
  overloaded, // > 1000 jobs
}

extension QueueHealthExtension on QueueHealth {
  String get description {
    switch (this) {
      case QueueHealth.healthy:
        return 'Queue is running smoothly';
      case QueueHealth.moderate:
        return 'Moderate queue load';
      case QueueHealth.busy:
        return 'High queue load - longer wait times';
      case QueueHealth.overloaded:
        return 'Queue overloaded - consider instant analysis';
    }
  }

  String get colorHex {
    switch (this) {
      case QueueHealth.healthy:
        return '#4CAF50'; // Green
      case QueueHealth.moderate:
        return '#FF9800'; // Orange
      case QueueHealth.busy:
        return '#F44336'; // Red
      case QueueHealth.overloaded:
        return '#9C27B0'; // Purple
    }
  }
}
