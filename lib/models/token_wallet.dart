/// Token wallet model for AI micro-economy
class TokenWallet {

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
    );
  }

  /// Create a default wallet for new users
  factory TokenWallet.newUser() {
    return TokenWallet(
      balance: 10,  // Welcome bonus: 10 tokens for new users
      totalEarned: 10,
      totalSpent: 0,
      lastUpdated: DateTime.now(),
    );
  }
  const TokenWallet({
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
    required this.lastUpdated,
    this.dailyConversionsUsed = 0,
    this.lastConversionDate,
  });

  final int balance;           // Current spendable tokens
  final int totalEarned;       // Lifetime tokens earned
  final int totalSpent;        // Lifetime tokens spent
  final DateTime lastUpdated;  // Last balance update
  final int dailyConversionsUsed;  // Points-to-tokens conversions today
  final DateTime? lastConversionDate;  // Last conversion date

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
  }) {
    return TokenWallet(
      balance: balance ?? this.balance,
      totalEarned: totalEarned ?? this.totalEarned,
      totalSpent: totalSpent ?? this.totalSpent,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      dailyConversionsUsed: dailyConversionsUsed ?? this.dailyConversionsUsed,
      lastConversionDate: lastConversionDate ?? this.lastConversionDate,
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
    };
  }

  @override
  String toString() {
    return 'TokenWallet(balance: $balance, earned: $totalEarned, spent: $totalSpent)';
  }
}

/// Token transaction history entry
class TokenTransaction {

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
  const TokenTransaction({
    required this.id,
    required this.delta,
    required this.type,
    required this.timestamp,
    required this.description,
    this.reference,
    this.metadata,
  });

  final String id;
  final int delta;              // Positive for earn, negative for spend
  final TokenTransactionType type;
  final DateTime timestamp;
  final String description;     // Human-readable description
  final String? reference;      // Job ID, classification ID, etc.
  final Map<String, dynamic>? metadata;  // Additional context

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
  earn,           // Earned tokens (daily login, achievements, etc.)
  spend,          // Spent tokens (AI analysis)
  convert,        // Converted from points
  bonus,          // Special bonuses/promotions
  refund,         // Refunded for failed operations
}

/// Speed options for AI analysis
enum AnalysisSpeed {
  batch,    // Slower, cheaper (1 token)
  instant,  // Faster, expensive (5 tokens)
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