import 'package:hive/hive.dart';

part 'token_wallet.g.dart';

/// Token wallet model for AI micro-economy
@HiveType(typeId: 20)
class TokenWallet {
  const TokenWallet({
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
    required this.lastUpdated,
    this.dailyConversionsUsed = 0,
    this.lastConversionDate,
    this.schemaVersion = 1,
  });

  factory TokenWallet.fromJson(Map<String, dynamic> json) {
    return TokenWallet(
      balance: json['balance'] ?? 0,
      totalEarned: json['totalEarned'] ?? 0,
      totalSpent: json['totalSpent'] ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated']),
      dailyConversionsUsed: json['dailyConversionsUsed'] ?? 0,
      lastConversionDate: json['lastConversionDate'] != null
          ? DateTime.parse(json['lastConversionDate'])
          : null,
      schemaVersion: json['schemaVersion'] ?? currentSchemaVersion,
    );
  }

  /// Create a default wallet for new users
  factory TokenWallet.newUser() {
    return TokenWallet(
      balance: 50, // Welcome bonus: 50 tokens for new users
      totalEarned: 50,
      totalSpent: 0,
      lastUpdated: DateTime.now(),
      schemaVersion: currentSchemaVersion,
    );
  }

  static const int currentSchemaVersion = 1;

  @HiveField(0)
  final int balance; // Current spendable tokens

  @HiveField(1)
  final int totalEarned; // Lifetime tokens earned

  @HiveField(2)
  final int totalSpent; // Lifetime tokens spent

  @HiveField(3)
  final DateTime lastUpdated; // Last balance update

  @HiveField(4)
  final int dailyConversionsUsed; // Points-to-tokens conversions today

  @HiveField(5)
  final DateTime? lastConversionDate; // Last conversion date

  @HiveField(6)
  final int schemaVersion; // Schema version for migration support

  /// Check if user can afford a purchase
  bool canAfford(int cost) => balance >= cost;

  /// Check if user can convert points today
  bool canConvertToday(int maxPerDay) {
    if (lastConversionDate == null) return true;

    final today = DateTime.now();
    final lastConversion = lastConversionDate!;

    // Reset daily count if it's a new day
    if (today.day != lastConversion.day ||
        today.month != lastConversion.month ||
        today.year != lastConversion.year) {
      return true;
    }

    return dailyConversionsUsed < maxPerDay;
  }

  /// Get remaining conversions for today
  int remainingConversions(int maxPerDay) {
    if (!canConvertToday(maxPerDay)) return 0;

    final today = DateTime.now();
    final lastConversion = lastConversionDate;

    // If it's a new day or no previous conversions, return full limit
    if (lastConversion == null ||
        today.day != lastConversion.day ||
        today.month != lastConversion.month ||
        today.year != lastConversion.year) {
      return maxPerDay;
    }

    return maxPerDay - dailyConversionsUsed;
  }

  TokenWallet copyWith({
    int? balance,
    int? totalEarned,
    int? totalSpent,
    DateTime? lastUpdated,
    int? dailyConversionsUsed,
    DateTime? lastConversionDate,
    int? schemaVersion,
  }) {
    return TokenWallet(
      balance: balance ?? this.balance,
      totalEarned: totalEarned ?? this.totalEarned,
      totalSpent: totalSpent ?? this.totalSpent,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      dailyConversionsUsed: dailyConversionsUsed ?? this.dailyConversionsUsed,
      lastConversionDate: lastConversionDate ?? this.lastConversionDate,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'totalEarned': totalEarned,
      'totalSpent': totalSpent,
      'lastUpdated': lastUpdated.toIso8601String(),
      'dailyConversionsUsed': dailyConversionsUsed,
      'lastConversionDate': lastConversionDate?.toIso8601String(),
      'schemaVersion': schemaVersion,
    };
  }

  @override
  String toString() {
    return 'TokenWallet(balance: $balance, earned: $totalEarned, spent: $totalSpent)';
  }
}

/// Token transaction history entry
@HiveType(typeId: 21)
class TokenTransaction {
  const TokenTransaction({
    required this.id,
    required this.delta,
    required this.type,
    required this.timestamp,
    required this.description,
    this.reference,
    this.metadata,
  });

  factory TokenTransaction.fromJson(Map<String, dynamic> json) {
    return TokenTransaction(
      id: json['id'],
      delta: json['delta'],
      type: TokenTransactionType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      timestamp: DateTime.parse(json['timestamp']),
      description: json['description'],
      reference: json['reference'],
      metadata: json['metadata']?.cast<String, dynamic>(),
    );
  }

  @HiveField(0)
  final String id;

  @HiveField(1)
  final int delta; // Positive for earn, negative for spend

  @HiveField(2)
  final TokenTransactionType type;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String description; // Human-readable description

  @HiveField(5)
  final String? reference; // Job ID, classification ID, etc.

  @HiveField(6)
  final Map<String, dynamic>? metadata; // Additional context

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'delta': delta,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'reference': reference,
      'metadata': metadata,
    };
  }
}

/// Types of token transactions
enum TokenTransactionType {
  earn, // Earned tokens (daily login, achievements, etc.)
  spend, // Spent tokens (AI analysis)
  convert, // Converted from points
  bonus, // Special bonuses/promotions
  refund, // Refunded for failed operations
}

/// Speed options for AI analysis
enum AnalysisSpeed {
  batch, // Slower, cheaper (1 token)
  instant, // Faster, expensive (5 tokens)
}

extension AnalysisSpeedExtension on AnalysisSpeed {
  int get cost {
    switch (this) {
      case AnalysisSpeed.batch:
        return 1;
      case AnalysisSpeed.instant:
        return 5;
    }
  }

  String get displayName {
    switch (this) {
      case AnalysisSpeed.batch:
        return 'Batch (2-6h)';
      case AnalysisSpeed.instant:
        return 'Instant';
    }
  }

  String get description {
    switch (this) {
      case AnalysisSpeed.batch:
        return 'Queued for batch processing - results in 2-6 hours';
      case AnalysisSpeed.instant:
        return 'Real-time analysis - results immediately';
    }
  }
}
