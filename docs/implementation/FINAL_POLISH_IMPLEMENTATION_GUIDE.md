# Final Polish Implementation Guide

**Version**: 1.0  
**Date**: June 19, 2025  
**Status**: Ready for Implementation  
**Estimated Time**: 1-2 weeks

## 🎯 Overview

This guide provides detailed implementation instructions for the final 3% of roadmap items. These are polish features that enhance user experience and operational visibility.

---

## 🚀 Priority 1: Home Header Batch Jobs Card

### Implementation Steps

#### Step 1: Create BatchJobsHeaderCard Widget

Create `lib/widgets/batch_jobs_header_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ai_job.dart';
import '../providers/ai_job_providers.dart';
import '../providers/app_providers.dart';
import '../utils/constants.dart';

class BatchJobsHeaderCard extends ConsumerWidget {
  const BatchJobsHeaderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    
    return userProfileAsync.when(
      data: (userProfile) {
        if (userProfile == null) return const SizedBox.shrink();
        
        final jobsAsync = ref.watch(userAiJobsProvider(userProfile.id));
        
        return jobsAsync.when(
          data: (jobs) {
            final activeJobs = jobs.where((job) => job.isProcessing).toList();
            if (activeJobs.isEmpty) return const SizedBox.shrink();
            
            return _buildJobsCard(context, activeJobs);
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildJobsCard(BuildContext context, List<AiJob> activeJobs) {
    final processingCount = activeJobs.where((job) => 
      job.status == AiJobStatus.processing).length;
    final queuedCount = activeJobs.where((job) => 
      job.status == AiJobStatus.queued).length;
    
    final estimatedMinutes = _calculateEstimatedCompletion(activeJobs);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/job-queue'),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Progress indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: processingCount > 0 ? 0.6 : null,
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Job info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your batch jobs',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _buildStatusText(processingCount, queuedCount, estimatedMinutes),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Chevron
            Icon(
              Icons.chevron_right,
              color: Colors.blue.shade600,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _buildStatusText(int processing, int queued, int estimatedMinutes) {
    if (processing > 0 && queued > 0) {
      return '$processing processing, $queued queued · done in ~${estimatedMinutes}min';
    } else if (processing > 0) {
      return '$processing processing · done in ~${estimatedMinutes}min';
    } else if (queued > 0) {
      return '$queued queued · starting soon';
    }
    return 'No active jobs';
  }

  int _calculateEstimatedCompletion(List<AiJob> jobs) {
    // Simple estimation: 5 minutes per job in queue + processing time
    final queuedJobs = jobs.where((job) => job.status == AiJobStatus.queued).length;
    final processingJobs = jobs.where((job) => job.status == AiJobStatus.processing).length;
    
    // Processing jobs: assume 2-3 minutes remaining
    // Queued jobs: 5 minutes each
    return (processingJobs * 3) + (queuedJobs * 5);
  }
}
```

---

## 🚀 Priority 2: "Need it sooner?" Upgrade Button

### Implementation Steps

#### Step 1: Add Upgrade Functionality to JobQueueScreen

Update `lib/screens/job_queue_screen.dart`:

```dart
// Add these methods to JobQueueScreen class

Future<void> _showUpgradeDialog(BuildContext context, AiJob job) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.flash_on, color: Colors.orange),
          SizedBox(width: 8),
          Text('Upgrade to Instant'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upgrade this batch job to instant processing?'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Additional cost:'),
                    Text('4 ⚡ tokens', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Processing time:'),
                    Text('~30 seconds', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Upgrade'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await _upgradeBatchToInstant(job);
  }
}

Future<void> _upgradeBatchToInstant(AiJob job) async {
  try {
    final tokenService = ref.read(tokenServiceProvider);
    
    // Check if user can afford upgrade (4 additional tokens)
    if (!await tokenService.canSpendTokens(4)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insufficient tokens for upgrade'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // Spend tokens and update job priority
    await tokenService.spendTokens(4, 'batch_upgrade');
    
    // Update job in Firestore
    await FirebaseFirestore.instance
        .collection('ai_jobs')
        .doc(job.id)
        .update({
      'priority': true,
      'speed': 'instant',
      'upgradedAt': FieldValue.serverTimestamp(),
      'tokensSpent': job.tokensSpent + 4,
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job upgraded to instant processing!'),
          backgroundColor: Colors.green,
        ),
      );
    }
    
  } catch (e) {
    WasteAppLogger.severe('Failed to upgrade batch job', e, null, {
      'jobId': job.id,
      'service': 'job_queue',
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upgrade job: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

---

## 🚀 Priority 3: Dynamic Pricing Implementation

### Implementation Steps

#### Step 1: Create DynamicPricingService

Create `lib/services/dynamic_pricing_service.dart`:

```dart
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../utils/waste_app_logger.dart';

class DynamicPricingService {
  static DynamicPricingService? _instance;
  static DynamicPricingService get instance {
    _instance ??= DynamicPricingService._internal();
    return _instance!;
  }
  
  DynamicPricingService._internal();

  // Cache for prices to avoid frequent Remote Config calls
  Map<String, int>? _cachedPrices;
  DateTime? _lastFetch;
  static const Duration _cacheTimeout = Duration(minutes: 15);

  /// Get current token prices with caching
  Future<Map<String, int>> getCurrentPrices() async {
    // Return cached prices if still valid
    if (_cachedPrices != null && 
        _lastFetch != null && 
        DateTime.now().difference(_lastFetch!) < _cacheTimeout) {
      return _cachedPrices!;
    }

    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();
      
      final prices = {
        'batch': remoteConfig.getInt('batch_token_price'),
        'instant': remoteConfig.getInt('instant_token_price'),
        'conversion_rate': remoteConfig.getInt('points_to_token_rate'),
      };
      
      // Validate prices and apply fallbacks
      final validatedPrices = {
        'batch': _validatePrice(prices['batch'], 1),
        'instant': _validatePrice(prices['instant'], 5),
        'conversion_rate': _validatePrice(prices['conversion_rate'], 100),
      };
      
      _cachedPrices = validatedPrices;
      _lastFetch = DateTime.now();
      
      WasteAppLogger.info('Dynamic prices fetched successfully', null, null, {
        'prices': validatedPrices,
        'service': 'dynamic_pricing',
      });
      
      return validatedPrices;
      
    } catch (e) {
      WasteAppLogger.severe('Failed to fetch dynamic prices, using fallbacks', e, null, {
        'service': 'dynamic_pricing',
        'action': 'fallback_to_defaults',
      });
      
      // Return fallback prices
      final fallbackPrices = {
        'batch': 1,
        'instant': 5,
        'conversion_rate': 100,
      };
      
      _cachedPrices = fallbackPrices;
      _lastFetch = DateTime.now();
      
      return fallbackPrices;
    }
  }

  /// Validate price and apply fallback if invalid
  int _validatePrice(int? price, int fallback) {
    if (price == null || price <= 0 || price > 1000) {
      return fallback;
    }
    return price;
  }

  /// Clear cache to force refresh on next call
  void clearCache() {
    _cachedPrices = null;
    _lastFetch = null;
  }

  /// Get batch token price
  Future<int> getBatchPrice() async {
    final prices = await getCurrentPrices();
    return prices['batch']!;
  }

  /// Get instant token price
  Future<int> getInstantPrice() async {
    final prices = await getCurrentPrices();
    return prices['instant']!;
  }

  /// Get points to tokens conversion rate
  Future<int> getConversionRate() async {
    final prices = await getCurrentPrices();
    return prices['conversion_rate']!;
  }
}
```

---

## 📋 Deployment Checklist

### Pre-deployment
- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] Remote Config keys are set up in Firebase console
- [ ] Error handling is comprehensive
- [ ] Performance impact is minimal

### Post-deployment
- [ ] Monitor batch job completion rates
- [ ] Track upgrade button usage
- [ ] Monitor Remote Config fetch success rates
- [ ] Verify confetti animations work on different devices
- [ ] Check token balance updates correctly

---

**Next Steps**: Implement features in priority order, test thoroughly, and monitor user feedback for iterative improvements.
