import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/token_wallet.dart';
import '../models/gamification.dart';
import '../utils/waste_app_logger.dart';
import 'storage_service.dart';
import 'cloud_storage_service.dart';

/// Service for managing token micro-economy
/// 
/// Handles token earning, spending, conversion from points, and transaction history.
/// Provides atomic operations to prevent race conditions and ensure wallet consistency.
class TokenService extends ChangeNotifier {
  TokenService(this._storageService, this._cloudStorageService);

  final StorageService _storageService;
  final CloudStorageService _cloudStorageService;
  final Uuid _uuid = const Uuid();

  // Cached wallet and transaction history
  TokenWallet? _cachedWallet;
  List<TokenTransaction>? _cachedTransactions;

  // Synchronization lock
  bool _isUpdating = false;
  final List<Completer<void>> _pendingOperations = [];

  // Configuration constants
  static const int pointsToTokenRate = 100;  // 100 points = 1 token
  static const int maxDailyConversions = 5;  // Max 5 conversions per day
  static const int welcomeBonus = 10;        // 10 tokens for new users
  static const int dailyLoginBonus = 2;      // 2 tokens for daily login

  /// Get current wallet (cached or fresh)
  TokenWallet? get currentWallet => _cachedWallet;

  /// Initialize token service and load wallet
  Future<void> initialize() async {
    if (_cachedWallet != null) return;
    
    try {
      await _loadWallet();
    } catch (e) {
      WasteAppLogger.severe('TokenService initialization failed', e, null, {
        'component': 'token_service',
        'operation': 'initialize'
      });
      // Create emergency fallback wallet
      _cachedWallet = TokenWallet.newUser();
    }
  }

  /// Load wallet from storage
  Future<TokenWallet> _loadWallet() async {
    final userProfile = await _storageService.getCurrentUserProfile();
    
    if (userProfile?.tokenWallet != null) {
      _cachedWallet = userProfile!.tokenWallet!;
      notifyListeners();
      return _cachedWallet!;
    }
    
    // Create new wallet for new users
    final newWallet = TokenWallet.newUser();
    await _saveWallet(newWallet);
    return newWallet;
  }

  /// Earn tokens with atomic operation
  Future<TokenWallet> earnTokens(
    int amount, 
    TokenTransactionType type, 
    String description, {
    String? reference,
    Map<String, dynamic>? metadata,
  }) async {
    return _executeAtomicOperation(() async {
      await initialize();
      
      final wallet = _cachedWallet!;
      
      if (amount <= 0) {
        WasteAppLogger.warning('Invalid token amount to earn', null, null, {
          'component': 'token_service',
          'amount': amount,
          'type': type.toString()
        });
        return wallet;
      }

      // Calculate new wallet state
      final newWallet = wallet.copyWith(
        balance: wallet.balance + amount,
        totalEarned: wallet.totalEarned + amount,
        lastUpdated: DateTime.now(),
      );

      // Create transaction record
      final transaction = TokenTransaction(
        id: _uuid.v4(),
        delta: amount,
        type: type,
        timestamp: DateTime.now(),
        description: description,
        reference: reference,
        metadata: metadata,
      );

      // Save wallet and transaction
      await _saveWallet(newWallet);
      await _saveTransaction(transaction);

      WasteAppLogger.gamificationEvent('tokens_earned', 
        context: {
          'type': type.toString(),
          'description': description,
          'tokens_earned': amount,
          'new_balance': newWallet.balance,
          'reference': reference,
          'metadata': metadata
        }
      );

      return newWallet;
    });
  }

  /// Spend tokens with atomic operation and validation
  Future<TokenWallet> spendTokens(
    int amount, 
    String description, {
    String? reference,
    Map<String, dynamic>? metadata,
  }) async {
    return _executeAtomicOperation(() async {
      await initialize();
      
      final wallet = _cachedWallet!;
      
      if (amount <= 0) {
        throw Exception('Invalid token amount to spend: $amount');
      }

      if (!wallet.canAfford(amount)) {
        throw Exception('Insufficient tokens. Need $amount, have ${wallet.balance}');
      }

      // Calculate new wallet state
      final newWallet = wallet.copyWith(
        balance: wallet.balance - amount,
        totalSpent: wallet.totalSpent + amount,
        lastUpdated: DateTime.now(),
      );

      // Create transaction record
      final transaction = TokenTransaction(
        id: _uuid.v4(),
        delta: -amount,
        type: TokenTransactionType.spend,
        timestamp: DateTime.now(),
        description: description,
        reference: reference,
        metadata: metadata,
      );

      // Save wallet and transaction
      await _saveWallet(newWallet);
      await _saveTransaction(transaction);

      WasteAppLogger.gamificationEvent('tokens_spent', 
        context: {
          'description': description,
          'tokens_spent': amount,
          'new_balance': newWallet.balance,
          'reference': reference,
          'metadata': metadata
        }
      );

      return newWallet;
    });
  }

  /// Convert points to tokens with daily limit validation
  Future<TokenWallet> convertPointsToTokens(
    int pointsToConvert,
    int currentUserPoints,
  ) async {
    return _executeAtomicOperation(() async {
      await initialize();
      
      final wallet = _cachedWallet!;
      
      // Validate conversion amount
      if (pointsToConvert <= 0 || pointsToConvert % pointsToTokenRate != 0) {
        throw Exception('Points must be a multiple of $pointsToTokenRate');
      }

      if (pointsToConvert > currentUserPoints) {
        throw Exception('Insufficient points. Need $pointsToConvert, have $currentUserPoints');
      }

      // Check daily conversion limit
      if (!wallet.canConvertToday(maxDailyConversions)) {
        throw Exception('Daily conversion limit reached. Try again tomorrow.');
      }

      final tokensToAdd = pointsToConvert ~/ pointsToTokenRate;
      final today = DateTime.now();
      
      // Update conversion tracking
      final isNewDay = wallet.lastConversionDate == null ||
          today.day != wallet.lastConversionDate!.day ||
          today.month != wallet.lastConversionDate!.month ||
          today.year != wallet.lastConversionDate!.year;

      final newConversionsUsed = isNewDay ? 1 : wallet.dailyConversionsUsed + 1;

      // Calculate new wallet state
      final newWallet = wallet.copyWith(
        balance: wallet.balance + tokensToAdd,
        totalEarned: wallet.totalEarned + tokensToAdd,
        lastUpdated: DateTime.now(),
        dailyConversionsUsed: newConversionsUsed,
        lastConversionDate: today,
      );

      // Create transaction record
      final transaction = TokenTransaction(
        id: _uuid.v4(),
        delta: tokensToAdd,
        type: TokenTransactionType.convert,
        timestamp: DateTime.now(),
        description: 'Converted $pointsToConvert points to $tokensToAdd tokens',
        metadata: {
          'points_converted': pointsToConvert,
          'conversion_rate': pointsToTokenRate,
          'conversions_used_today': newConversionsUsed,
        },
      );

      // Save wallet and transaction
      await _saveWallet(newWallet);
      await _saveTransaction(transaction);

      WasteAppLogger.gamificationEvent('points_converted_to_tokens', 
        context: {
          'points_converted': pointsToConvert,
          'tokens_earned': tokensToAdd,
          'conversion_rate': pointsToTokenRate,
          'new_balance': newWallet.balance,
          'conversions_used_today': newConversionsUsed,
        }
      );

      return newWallet;
    });
  }

  /// Process daily login bonus
  Future<TokenWallet> processDailyLogin() async {
    await initialize();
    
    final wallet = _cachedWallet!;
    final today = DateTime.now();
    final lastUpdate = wallet.lastUpdated;
    
    // Check if already received bonus today
    if (lastUpdate.day == today.day && 
        lastUpdate.month == today.month && 
        lastUpdate.year == today.year) {
      return wallet; // Already received today's bonus
    }
    
    return earnTokens(
      dailyLoginBonus,
      TokenTransactionType.earn,
      'Daily login bonus',
      metadata: {'bonus_type': 'daily_login'},
    );
  }

  /// Get transaction history
  Future<List<TokenTransaction>> getTransactionHistory({int limit = 50}) async {
    if (_cachedTransactions != null && limit >= _cachedTransactions!.length) {
      return _cachedTransactions!;
    }

    try {
      final userProfile = await _storageService.getCurrentUserProfile();
      if (userProfile?.tokenTransactions != null) {
        _cachedTransactions = userProfile!.tokenTransactions!
            .take(limit)
            .toList();
        return _cachedTransactions!;
      }
      
      return [];
    } catch (e) {
      WasteAppLogger.severe('Error loading transaction history', e, null, {
        'component': 'token_service',
        'operation': 'get_transaction_history'
      });
      return [];
    }
  }

  /// Get wallet statistics
  Future<Map<String, dynamic>> getWalletStats() async {
    await initialize();
    
    final wallet = _cachedWallet!;
    final transactions = await getTransactionHistory();
    
    // Calculate stats
    final earnedToday = transactions
        .where((t) => t.delta > 0 && _isToday(t.timestamp))
        .fold(0, (sum, t) => sum + t.delta);
    
    final spentToday = transactions
        .where((t) => t.delta < 0 && _isToday(t.timestamp))
        .fold(0, (sum, t) => sum + t.delta.abs());

    final conversionStats = transactions
        .where((t) => t.type == TokenTransactionType.convert)
        .length;

    return {
      'current_balance': wallet.balance,
      'total_earned': wallet.totalEarned,
      'total_spent': wallet.totalSpent,
      'earned_today': earnedToday,
      'spent_today': spentToday,
      'total_conversions': conversionStats,
      'conversions_remaining_today': wallet.remainingConversions(maxDailyConversions),
      'last_updated': wallet.lastUpdated.toIso8601String(),
    };
  }

  /// Execute operation atomically with lock
  Future<T> _executeAtomicOperation<T>(Future<T> Function() operation) async {
    // Wait for any pending operations
    while (_isUpdating) {
      final completer = Completer<void>();
      _pendingOperations.add(completer);
      await completer.future;
    }
    
    _isUpdating = true;
    
    try {
      final result = await operation();
      return result;
    } finally {
      _isUpdating = false;
      
      // Complete all pending operations
      final pending = List<Completer<void>>.from(_pendingOperations);
      _pendingOperations.clear();
      for (final completer in pending) {
        completer.complete();
      }
    }
  }

  /// Save wallet to storage
  Future<void> _saveWallet(TokenWallet wallet) async {
    _cachedWallet = wallet;
    notifyListeners();
    
    // Save to user profile
    final userProfile = await _storageService.getCurrentUserProfile();
    if (userProfile != null) {
      final updatedProfile = userProfile.copyWith(
        tokenWallet: wallet,
        lastActive: DateTime.now(),
      );
      
      await _storageService.saveUserProfile(updatedProfile);
      
      // Try cloud sync (non-blocking)
      unawaited(_cloudStorageService.saveUserProfileToFirestore(updatedProfile));
    }
  }

  /// Save transaction to storage
  Future<void> _saveTransaction(TokenTransaction transaction) async {
    try {
      final userProfile = await _storageService.getCurrentUserProfile();
      if (userProfile != null) {
        final currentTransactions = userProfile.tokenTransactions ?? [];
        final updatedTransactions = [transaction, ...currentTransactions]
            .take(200) // Keep last 200 transactions
            .toList();
        
        final updatedProfile = userProfile.copyWith(
          tokenTransactions: updatedTransactions,
        );
        
        await _storageService.saveUserProfile(updatedProfile);
        _cachedTransactions = updatedTransactions;
      }
    } catch (e) {
      WasteAppLogger.severe('Error saving transaction', e, null, {
        'component': 'token_service',
        'transaction_id': transaction.id
      });
    }
  }

  /// Check if date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.day == now.day && 
           date.month == now.month && 
           date.year == now.year;
  }

  /// Dispose resources
  @override
  void dispose() {
    super.dispose();
  }
}

/// Extension to add unawaited helper
extension on Future {
  void unawaited() {}
} 