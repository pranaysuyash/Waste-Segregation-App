# API Key Management and Security

## Overview
This document outlines the strategies and best practices for managing API keys and ensuring security when interacting with external services like Gemini, OpenAI, and other third-party APIs used in the Waste Segregation App.

## Current Implementation Status (May 2025)

The app currently uses the following external API services:
- **Gemini Vision API**: For primary image classification
- **OpenAI API**: As a fallback for classification when needed
- **Firebase Authentication**: For user authentication (Google Sign-In)

Based on the video demo review, API key security considerations need to be strengthened as the app moves toward production.

## API Key Storage

### Development Environment
- API keys should never be hardcoded in source code
- Use `.env` files with gitignore protection
- Use Flutter's `--dart-define` for CI/CD environments

```bash
# Example development command with secure API key passing
flutter run --dart-define=GEMINI_API_KEY=your_api_key_here --dart-define=OPENAI_API_KEY=your_openai_key_here
```

### Production Environment
- Keys should not be stored in client-side code
- Flutter environment variables are NOT secure for production
- Use the strategies described in the "Security Architecture" section

## Security Architecture

### Backend Proxy Approach

The recommended approach for securing API keys in production is to route all requests through a secure backend service that holds the actual API keys.

#### Implementation Architecture
```
Mobile App → Our Backend → External AI API
```

#### Firebase Cloud Functions Implementation

```javascript
// Example Cloud Function for Gemini image classification
const functions = require('firebase-functions');
const axios = require('axios');

exports.classifyImage = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to use this function'
    );
  }
  
  // Rate limiting check
  const userRateLimit = await checkUserRateLimit(context.auth.uid);
  if (!userRateLimit.allowed) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      'Rate limit exceeded. Try again later.',
      { resetTime: userRateLimit.resetTime }
    );
  }
  
  try {
    // API keys stored securely in Cloud Function environment
    const apiKey = process.env.GEMINI_API_KEY;
    
    // Forward request to Gemini API
    const response = await axios.post(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent',
      {
        contents: [
          {
            parts: [
              { text: "Classify this waste item with detailed information about disposal." },
              { inlineData: { mimeType: "image/jpeg", data: data.imageBase64 } }
            ]
          }
        ],
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey
        }
      }
    );
    
    // Record usage for rate limiting
    await recordApiUsage(context.auth.uid);
    
    // Return result to client
    return response.data;
  } catch (error) {
    console.error('Error calling Gemini API:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error processing image classification',
      { message: error.message }
    );
  }
});

// Helper functions for rate limiting
async function checkUserRateLimit(userId) {
  // Implementation of rate limiting using Firestore or Redis
}

async function recordApiUsage(userId) {
  // Record the usage in Firestore or Redis
}
```

#### Flutter Client Implementation

```dart
Future<ClassificationResult> classifyImage(File imageFile) async {
  try {
    // Convert image to base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    
    // Call the Firebase Function instead of direct API
    final callable = FirebaseFunctions.instance.httpsCallable('classifyImage');
    final result = await callable.call({
      'imageBase64': base64Image,
    });
    
    // Process and return the result
    return ClassificationResult.fromJson(result.data);
  } catch (e) {
    // Handle errors
    _logService.logError('Classification failed', e);
    throw ClassificationException(
      'Failed to classify image: ${e.toString()}',
    );
  }
}
```

### Firebase Remote Config

For non-sensitive configuration data that may need to be updated without app releases, use Firebase Remote Config.

```dart
class ConfigService {
  final FirebaseRemoteConfig _remoteConfig;
  
  ConfigService(this._remoteConfig);
  
  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    
    await _remoteConfig.setDefaults({
      'max_classifications_per_day': 20,
      'enable_offline_classification': true,
      'classification_cache_days': 30,
      'gemini_model_version': 'gemini-pro-vision-1.0',
      'fallback_strategy': 'openai',
    });
    
    await _remoteConfig.fetchAndActivate();
  }
  
  int get maxClassificationsPerDay => 
    _remoteConfig.getInt('max_classifications_per_day');
    
  bool get enableOfflineClassification =>
    _remoteConfig.getBool('enable_offline_classification');
    
  int get classificationCacheDays =>
    _remoteConfig.getInt('classification_cache_days');
    
  String get geminiModelVersion =>
    _remoteConfig.getString('gemini_model_version');
    
  String get fallbackStrategy =>
    _remoteConfig.getString('fallback_strategy');
}
```

## Key Rotation Policies

### Schedule
- Regular rotation schedule (quarterly)
- Emergency rotation procedures for suspected key compromise

### Implementation
- Zero-downtime rotation strategy using Firebase Function updates
- Handling in-flight requests during rotation with grace periods

### Emergency Rotation Procedure
1. Generate new API keys from the Gemini/OpenAI dashboards
2. Update the backend environment variables/secrets
3. Deploy the updated backend service
4. Monitor for any errors during transition
5. Revoke the old API keys after confirmation of successful transition

## Request Quotas and Rate Limiting

### Client-Side Throttling
- Implement a token bucket algorithm for fair client-side throttling
- Cache successful classifications to reduce redundant API calls
- Provide clear user feedback when approaching rate limits

```dart
class RateLimitService {
  final StorageService _storageService;
  
  RateLimitService(this._storageService);
  
  // Check if the user can make a classification
  Future<bool> canClassify() async {
    final usage = await _storageService.getApiUsage();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    // Reset count if it's a new day
    if (usage.date != today) {
      await _storageService.saveApiUsage(ApiUsage(
        date: today,
        count: 0,
        lastRequest: DateTime.now(),
      ));
      return true;
    }
    
    // Check if count exceeds daily limit
    final configService = GetIt.I<ConfigService>();
    if (usage.count >= configService.maxClassificationsPerDay) {
      return false;
    }
    
    // Check for rate limiting (prevent too many requests in short period)
    final lastRequest = usage.lastRequest;
    final now = DateTime.now();
    if (now.difference(lastRequest).inSeconds < 5) {
      return false;
    }
    
    return true;
  }
  
  // Update usage after a successful classification
  Future<void> recordClassification() async {
    final usage = await _storageService.getApiUsage();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    if (usage.date != today) {
      await _storageService.saveApiUsage(ApiUsage(
        date: today,
        count: 1,
        lastRequest: DateTime.now(),
      ));
    } else {
      await _storageService.saveApiUsage(ApiUsage(
        date: today,
        count: usage.count + 1,
        lastRequest: DateTime.now(),
      ));
    }
  }
  
  // Get user's remaining quota
  Future<int> getRemainingQuota() async {
    final usage = await _storageService.getApiUsage();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    if (usage.date != today) {
      return GetIt.I<ConfigService>().maxClassificationsPerDay;
    }
    
    return GetIt.I<ConfigService>().maxClassificationsPerDay - usage.count;
  }
}
```

### Server-Side Protection
- Implement per-user quotas in Firebase Functions
- Use Firebase Authentication to identify users for quotas
- Implement global rate limiting to prevent abuse

```javascript
// Server-side rate limiting in Firestore
async function checkUserRateLimit(userId) {
  const db = admin.firestore();
  const userRef = db.collection('userApiUsage').doc(userId);
  
  // Get user usage document
  const userDoc = await userRef.get();
  const today = new Date().toISOString().slice(0, 10);
  
  // If no document or different day, create new usage record
  if (!userDoc.exists || userDoc.data().date !== today) {
    await userRef.set({
      date: today,
      count: 1,
      lastRequest: admin.firestore.FieldValue.serverTimestamp()
    });
    return { allowed: true };
  }
  
  const userData = userDoc.data();
  
  // Check daily quota
  const MAX_DAILY_REQUESTS = 50; // Can be adjusted per user tier
  if (userData.count >= MAX_DAILY_REQUESTS) {
    return { 
      allowed: false,
      resetTime: getNextDayTimestamp()
    };
  }
  
  // Check rate limiting (max 10 requests per minute)
  const lastRequest = userData.lastRequest.toDate();
  const now = new Date();
  const requestsInLastMinute = userData.requestsInLastMinute || 0;
  
  if (requestsInLastMinute >= 10 && 
      now.getTime() - lastRequest.getTime() < 60000) {
    return {
      allowed: false,
      resetTime: new Date(lastRequest.getTime() + 60000)
    };
  }
  
  // Update usage count
  if (now.getTime() - lastRequest.getTime() < 60000) {
    await userRef.update({
      count: admin.firestore.FieldValue.increment(1),
      lastRequest: admin.firestore.FieldValue.serverTimestamp(),
      requestsInLastMinute: admin.firestore.FieldValue.increment(1)
    });
  } else {
    await userRef.update({
      count: admin.firestore.FieldValue.increment(1),
      lastRequest: admin.firestore.FieldValue.serverTimestamp(),
      requestsInLastMinute: 1
    });
  }
  
  return { allowed: true };
}

function getNextDayTimestamp() {
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(0, 0, 0, 0);
  return tomorrow;
}
```

## Monitoring and Alerting

### Usage Monitoring
- Track API call volume by service
- Monitor costs in real-time
- Set up anomaly detection for unusual usage patterns

### Implementation
```javascript
// Cloud Function to track API usage metrics
exports.trackApiUsage = functions.firestore
  .document('userApiUsage/{userId}')
  .onUpdate(async (change, context) => {
    const after = change.after.data();
    const before = change.before.data();
    
    // Only track if this is a count increment
    if (after.count <= before.count) {
      return null;
    }
    
    // Record to daily metrics collection
    const today = new Date().toISOString().slice(0, 10);
    const metricsRef = admin.firestore().collection('apiMetrics').doc(today);
    
    // Update metrics with service usage
    await metricsRef.set({
      totalCalls: admin.firestore.FieldValue.increment(1),
      uniqueUsers: admin.firestore.FieldValue.increment(0), // Will be updated in a transaction if needed
      geminiCalls: admin.firestore.FieldValue.increment(after.service === 'gemini' ? 1 : 0),
      openaiCalls: admin.firestore.FieldValue.increment(after.service === 'openai' ? 1 : 0),
      peakHourCalls: admin.firestore.FieldValue.increment(isInPeakHours() ? 1 : 0),
    }, { merge: true });
    
    // Check for anomalies
    await checkForAnomalies(metricsRef);
    
    return null;
  });

// Check for unusual usage patterns
async function checkForAnomalies(metricsRef) {
  const doc = await metricsRef.get();
  if (!doc.exists) return;
  
  const metrics = doc.data();
  const hourOfDay = new Date().getHours();
  
  // Get average for this hour from historical data
  const averageForHour = await getAverageCallsForHour(hourOfDay);
  
  // If current usage is 50% higher than average, trigger alert
  if (metrics.totalCalls > averageForHour * 1.5) {
    await sendAlertToAdmins('Unusual API usage detected', {
      currentCalls: metrics.totalCalls,
      averageCalls: averageForHour,
      timestamp: new Date().toISOString()
    });
  }
}
```

### Security Alerts
- Implement alerts for potential key compromise indicators
- Monitor for unusual geographic access patterns
- Set up notifications for API error spikes

## Development Guidelines

### Working with Keys in Development
- Use environment variables with a .env.template file (without actual keys)
- Set up a secure way to share development keys with the team (e.g., password manager)
- Implement key rotation even for development environments

### Code Review Requirements
- Use automated checks to prevent key leakage
- Implement pre-commit hooks to scan for potential key exposures
- Define a security review checklist for code that interacts with external APIs

```bash
# Example pre-commit hook to check for hardcoded API keys
#!/bin/bash

# Patterns to check
patterns=(
  "AIza[0-9A-Za-z\-_]{35}"  # Google API Key
  "sk-[0-9A-Za-z]{48}"      # OpenAI API Key
  "key-[0-9a-zA-Z]{24}"     # Generic API Key pattern
)

# Files to check (only certain extensions)
files=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(dart|js|ts|json|yaml|yml)$')

if [ -z "$files" ]; then
  exit 0
fi

for pattern in "${patterns[@]}"; do
  for file in $files; do
    if grep -q "$pattern" "$file"; then
      echo "ERROR: Potential API key found in $file"
      echo "Please remove API keys from the code before committing."
      exit 1
    fi
  done
done

exit 0
```

## Emergency Response Plan

### Key Compromise
1. **Immediate Actions**
   - Revoke the compromised API key immediately
   - Generate new API keys
   - Update backend services with new keys
   - Assess the scope of the compromise

2. **Communication Plan**
   - Notify security team and stakeholders
   - Prepare user communication if service disruption is expected
   - Document the incident and response

3. **Post-Mortem Analysis**
   - Investigate how the key was compromised
   - Implement additional security measures
   - Update key management procedures

### Service Disruption
1. **Fallback Services**
   - Implement automatic fallback to alternative providers
   - Use cached responses for common classifications when possible
   - Enable offline mode for basic functionality

2. **Degraded Mode Operation**
   - Limit classification requests to priority users
   - Use simplified models with lower API costs
   - Show clear messaging about limited functionality

3. **User Communication**
   - Display in-app notifications about service status
   - Provide estimated restoration time
   - Offer alternatives during outage

## Compliance Considerations

### GDPR Implications
- Ensure API services used comply with GDPR requirements
- Implement data minimization in API requests (only send necessary data)
- Document data processing activities involving third-party APIs

### App Store Requirements
- Comply with Apple App Store guidelines on API usage and data sharing
- Address Google Play Store policies on user data handling
- Regularly review platform requirements for updates

## Cost Management

### API Usage Optimization
- Implement caching to reduce redundant API calls
- Use perceptual hashing to identify similar images
- Optimize image size before sending to AI services

### Budget Monitoring
- Set up budget alerts for API costs
- Implement automatic throttling when approaching budget limits
- Track cost per user for business model planning

```dart
class ApiCostManager {
  // Average cost per API call
  static const double _geminiCostPerCall = 0.0025; // $0.0025 per image classification
  static const double _openaiCostPerCall = 0.0080; // $0.0080 per fallback call
  
  // Track estimated costs
  Future<void> trackApiCost(String service) async {
    final cost = service == 'gemini' ? _geminiCostPerCall : _openaiCostPerCall;
    
    // Record to analytics
    AnalyticsService.trackEvent('api_cost', {
      'service': service,
      'cost': cost,
      'user_tier': await _getUserTier(),
    });
    
    // Update monthly cost tracking
    final currentMonth = DateTime.now().toIso8601String().substring(0, 7); // YYYY-MM
    final costRef = await _firestore.collection('apiCosts').doc(currentMonth);
    
    await costRef.set({
      'totalCost': FieldValue.increment(cost),
      'geminiCost': FieldValue.increment(service == 'gemini' ? cost : 0),
      'openaiCost': FieldValue.increment(service == 'openai' ? cost : 0),
    }, SetOptions(merge: true));
    
    // Check if approaching budget limit
    final doc = await costRef.get();
    if (doc.exists) {
      final data = doc.data()!;
      final totalCost = data['totalCost'] as double;
      
      // If at 80% of monthly budget, enable cost-saving measures
      if (totalCost > _currentMonthlyBudget * 0.8) {
        await _enableCostSavingMeasures();
      }
    }
  }
  
  // Enable cost-saving measures when approaching budget
  Future<void> _enableCostSavingMeasures() async {
    await FirebaseRemoteConfig.instance.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: Duration(minutes: 1),
      minimumFetchInterval: Duration(minutes: 30),
    ));
    
    await FirebaseRemoteConfig.instance.fetchAndActivate();
    
    // Reduce free tier limits
    // Increase cache duration
    // Use more aggressive compression
    // etc.
  }
}
```

## Implementation Examples

### Main AIService Implementation
```dart
class AIService {
  final ConfigService _configService;
  final StorageService _storageService;
  final RateLimitService _rateLimitService;
  final ApiCostManager _costManager;
  final LogService _logService;
  
  AIService({
    required ConfigService configService,
    required StorageService storageService,
    required RateLimitService rateLimitService,
    required ApiCostManager costManager,
    required LogService logService,
  }) : 
    _configService = configService,
    _storageService = storageService,
    _rateLimitService = rateLimitService,
    _costManager = costManager,
    _logService = logService;

  Future<ClassificationResult> classifyImage(File imageFile) async {
    // Check rate limits
    final canClassify = await _rateLimitService.canClassify();
    if (!canClassify) {
      final remainingQuota = await _rateLimitService.getRemainingQuota();
      if (remainingQuota <= 0) {
        throw ClassificationException(
          'Daily classification limit reached. Please try again tomorrow.',
        );
      } else {
        throw ClassificationException(
          'Too many requests. Please wait a moment before trying again.',
        );
      }
    }
    
    // Check cache first
    final imageHash = await ImageUtils.generateImageHash(imageFile);
    final cachedResult = await _storageService.getCachedClassification(imageHash);
    
    if (cachedResult != null) {
      _logService.log('Using cached classification result');
      return cachedResult;
    }
    
    // Try primary API (Gemini)
    try {
      final result = await _classifyWithGemini(imageFile);
      
      // Cache successful result
      await _storageService.cacheClassification(imageHash, result);
      
      // Record usage and cost
      await _rateLimitService.recordClassification();
      await _costManager.trackApiCost('gemini');
      
      return result;
    } catch (e) {
      _logService.logError('Gemini classification failed', e);
      
      // Fall back to OpenAI if enabled
      if (_configService.fallbackStrategy == 'openai') {
        try {
          final result = await _classifyWithOpenAI(imageFile);
          
          // Cache successful result
          await _storageService.cacheClassification(imageHash, result);
          
          // Record usage and cost
          await _rateLimitService.recordClassification();
          await _costManager.trackApiCost('openai');
          
          return result;
        } catch (e) {
          _logService.logError('OpenAI fallback failed', e);
          throw ClassificationException(
            'Classification failed. Please try again later.',
          );
        }
      } else {
        throw ClassificationException(
          'Classification failed. Please try again later.',
        );
      }
    }
  }

  // Use Firebase Functions to call Gemini API securely
  Future<ClassificationResult> _classifyWithGemini(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    
    final callable = FirebaseFunctions.instance.httpsCallable('classifyImage');
    final result = await callable.call({
      'imageBase64': base64Image,
      'modelVersion': _configService.geminiModelVersion,
    });
    
    return ClassificationResult.fromJson(result.data);
  }

  // Use Firebase Functions to call OpenAI API securely
  Future<ClassificationResult> _classifyWithOpenAI(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    
    final callable = FirebaseFunctions.instance.httpsCallable('classifyImageOpenAI');
    final result = await callable.call({
      'imageBase64': base64Image,
    });
    
    return ClassificationResult.fromJson(result.data);
  }
}
```

## Conclusion

Proper API key management and security are critical for the Waste Segregation App, especially as it prepares for production deployment. By implementing a backend proxy approach using Firebase Cloud Functions, the app can keep API keys secure while still leveraging powerful AI services.

The strategies outlined in this document ensure:

1. **API Key Security**: Keys are never exposed in client-side code
2. **Cost Control**: Usage is monitored and optimized to manage expenses
3. **Rate Limiting**: Both client and server-side measures prevent abuse
4. **Reliability**: Fallback mechanisms handle service disruptions
5. **Compliance**: App meets platform and regulatory requirements

As the app expands to include more third-party services, following these practices will help maintain a secure and stable experience for users while protecting sensitive credentials.
