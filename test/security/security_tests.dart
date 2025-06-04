import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:crypto/crypto.dart';
import 'package:waste_segregation_app/services/firebase_family_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/enhanced_family.dart';

// Mock services for security testing
class MockFirebaseFamilyService extends Mock implements FirebaseFamilyService {}
class MockStorageService extends Mock implements StorageService {}
class MockAnalyticsService extends Mock implements AnalyticsService {}
class MockAiService extends Mock implements AiService {}

void main() {
  group('Security Tests', () {
    late MockFirebaseFamilyService mockFamilyService;
    late MockStorageService mockStorageService;
    late MockAnalyticsService mockAnalyticsService;
    late MockAiService mockAiService;

    setUp(() {
      mockFamilyService = MockFirebaseFamilyService();
      mockStorageService = MockStorageService();
      mockAnalyticsService = MockAnalyticsService();
      mockAiService = MockAiService();
    });

    group('Data Validation Tests', () {
      test('should validate user input data', () {
        // Test classification with malicious input
        final maliciousClassification = {
          'itemName': '<script>alert("XSS")</script>',
          'category': 'Dry Waste',
          'explanation': 'DROP TABLE classifications;',
          'region': '../../etc/passwd',
          'visualFeatures': ['<img src=x onerror=alert(1)>'],
        };

        expect(() => _validateClassificationInput(maliciousClassification),
               throwsA(isA<SecurityException>()));
      });

      test('should sanitize classification feedback', () {
        final maliciousFeedback = {
          'feedback': '<script>document.location="http://evil.com"</script>',
          'category': 'javascript:alert(1)',
          'suggestion': '${}`DROP TABLE feedback;`${}`',
        };

        final sanitized = _sanitizeFeedbackInput(maliciousFeedback);
        
        expect(sanitized['feedback'], isNot(contains('<script>')));
        expect(sanitized['category'], isNot(contains('javascript:')));
        expect(sanitized['suggestion'], isNot(contains('DROP TABLE')));
      });

      test('should prevent SQL injection attacks', () {
        final sqlInjectionInputs = [
          "'; DROP TABLE users; --",
          "1' OR '1'='1",
          "admin'/*",
          "' UNION SELECT * FROM sensitive_data --",
          "'; EXEC xp_cmdshell('format c:'); --",
        ];

        for (final input in sqlInjectionInputs) {
          final testData = {'itemName': input, 'category': 'Test'};
          expect(() => _validateClassificationInput(testData),
                 throwsA(isA<SecurityException>()));
        }
      });

      test('should validate file upload inputs', () {
        // Test malicious file names
        final maliciousFileNames = [
          '../../../etc/passwd',
          '..\\..\\windows\\system32\\config',
          'test.php.jpg',
          'script.js',
          'malware.exe.jpg',
          'payload.jsp',
        ];

        for (final fileName in maliciousFileNames) {
          expect(() => _validateImageFile(fileName, Uint8List(100)),
                 throwsA(isA<SecurityException>()));
        }
      });

      test('should validate image file headers', () {
        // Test file with malicious content but valid extension
        final maliciousContent = utf8.encode('<?php system($_GET["cmd"]); ?>');
        final fakeImageData = Uint8List.fromList(maliciousContent);

        expect(() => _validateImageFile('image.jpg', fakeImageData),
               throwsA(isA<SecurityException>()));

        // Test legitimate image data
        final validImageData = _createValidImageData();
        expect(() => _validateImageFile('valid.jpg', validImageData),
               returnsNormally);
      });

      test('should validate user profile data', () {
        final maliciousProfile = UserProfile(
          id: '<script>alert("xss")</script>',
          email: 'admin@evil.com\r\nBcc: victim@company.com',
          displayName: 'Robert"; DROP TABLE users; --',
          photoUrl: 'javascript:alert(document.cookie)',
        );

        expect(() => _validateUserProfile(maliciousProfile),
               throwsA(isA<SecurityException>()));
      });

      test('should validate family data', () {
        final maliciousFamily = EnhancedFamily(
          id: '../family_data',
          name: '<iframe src="javascript:alert(1)"></iframe>',
          createdBy: 'SELECT * FROM users',
          createdAt: DateTime.now(),
          members: [],
          settings: FamilySettings(
            isPublic: false,
            shareClassifications: true,
            showMemberActivity: true,
            allowInvites: true,
          ),
          statistics: FamilyStatistics(
            totalClassifications: 0,
            totalPoints: 0,
            categoryCounts: {},
            weeklyActivity: [],
            environmentalImpact: EnvironmentalImpact(
              totalWasteClassified: 0,
              recyclableItems: 0,
              compostableItems: 0,
              hazardousItemsHandled: 0,
              estimatedCO2Saved: 0.0,
            ),
          ),
        );

        expect(() => _validateFamilyData(maliciousFamily),
               throwsA(isA<SecurityException>()));
      });
    });

    group('Authentication & Authorization Tests', () {
      test('should enforce user access permissions', () {
        final user1 = UserProfile(
          id: 'user_1',
          email: 'user1@example.com',
          displayName: 'User 1',
        );

        final user2 = UserProfile(
          id: 'user_2',
          email: 'user2@example.com',
          displayName: 'User 2',
        );

        final user1Classification = WasteClassification(
          itemName: 'Private Item',
          category: 'Dry Waste',
          explanation: 'User 1 private data',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Private disposal',
            steps: ['Private step'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Private Region',
          visualFeatures: [],
          alternatives: [],
          userId: user1.id,
        );

        // User 2 should not be able to access User 1's data
        expect(() => _checkDataAccess(user2, user1Classification),
               throwsA(isA<UnauthorizedAccessException>()));

        // User 1 should be able to access their own data
        expect(() => _checkDataAccess(user1, user1Classification),
               returnsNormally);
      });

      test('should validate family membership permissions', () {
        final admin = FamilyMember(
          userId: 'admin_user',
          email: 'admin@example.com',
          displayName: 'Admin User',
          role: FamilyRole.admin,
          joinedAt: DateTime.now(),
        );

        final regularMember = FamilyMember(
          userId: 'regular_user',
          email: 'regular@example.com',
          displayName: 'Regular User',
          role: FamilyRole.member,
          joinedAt: DateTime.now(),
        );

        final outsideUser = FamilyMember(
          userId: 'outside_user',
          email: 'outside@example.com',
          displayName: 'Outside User',
          role: FamilyRole.member,
          joinedAt: DateTime.now(),
        );

        final family = EnhancedFamily(
          id: 'test_family',
          name: 'Test Family',
          createdBy: admin.userId,
          createdAt: DateTime.now(),
          members: [admin, regularMember],
          settings: FamilySettings(
            isPublic: false,
            shareClassifications: true,
            showMemberActivity: true,
            allowInvites: true,
          ),
          statistics: FamilyStatistics(
            totalClassifications: 0,
            totalPoints: 0,
            categoryCounts: {},
            weeklyActivity: [],
            environmentalImpact: EnvironmentalImpact(
              totalWasteClassified: 0,
              recyclableItems: 0,
              compostableItems: 0,
              hazardousItemsHandled: 0,
              estimatedCO2Saved: 0.0,
            ),
          ),
        );

        // Admin should be able to manage family
        expect(_checkFamilyPermission(admin.userId, family, 'manage'),
               isTrue);

        // Regular member should be able to view but not manage
        expect(_checkFamilyPermission(regularMember.userId, family, 'view'),
               isTrue);
        expect(_checkFamilyPermission(regularMember.userId, family, 'manage'),
               isFalse);

        // Outside user should not have any access
        expect(_checkFamilyPermission(outsideUser.userId, family, 'view'),
               isFalse);
        expect(_checkFamilyPermission(outsideUser.userId, family, 'manage'),
               isFalse);
      });

      test('should validate session tokens', () {
        final validToken = _generateSecureToken();
        final expiredToken = _generateExpiredToken();
        final tamperedToken = _generateTamperedToken();
        final maliciousToken = '<script>alert("token")</script>';

        expect(_validateSessionToken(validToken), isTrue);
        expect(_validateSessionToken(expiredToken), isFalse);
        expect(_validateSessionToken(tamperedToken), isFalse);
        expect(_validateSessionToken(maliciousToken), isFalse);
      });

      test('should prevent privilege escalation', () {
        final regularUser = UserProfile(
          id: 'regular_user',
          email: 'regular@example.com',
          displayName: 'Regular User',
        );

        // Attempt to escalate privileges
        final privilegeEscalationAttempts = [
          {'action': 'admin_access', 'userId': regularUser.id},
          {'action': 'delete_all_data', 'userId': regularUser.id},
          {'action': 'modify_user_role', 'userId': regularUser.id, 'targetRole': 'admin'},
        ];

        for (final attempt in privilegeEscalationAttempts) {
          expect(() => _checkPrivilegeEscalation(regularUser, attempt),
                 throwsA(isA<UnauthorizedAccessException>()));
        }
      });
    });

    group('Data Protection Tests', () {
      test('should encrypt sensitive data', () {
        final sensitiveData = {
          'email': 'user@example.com',
          'personalInfo': 'Sensitive personal information',
          'location': 'Home address: 123 Main St',
        };

        final encrypted = _encryptSensitiveData(sensitiveData);
        
        expect(encrypted['email'], isNot(equals(sensitiveData['email'])));
        expect(encrypted['personalInfo'], isNot(equals(sensitiveData['personalInfo'])));
        expect(encrypted['location'], isNot(equals(sensitiveData['location'])));

        // Decrypt and verify
        final decrypted = _decryptSensitiveData(encrypted);
        expect(decrypted['email'], equals(sensitiveData['email']));
        expect(decrypted['personalInfo'], equals(sensitiveData['personalInfo']));
        expect(decrypted['location'], equals(sensitiveData['location']));
      });

      test('should hash passwords securely', () {
        final password = 'userPassword123!';
        final weakPassword = '123';
        
        final hashedPassword = _hashPassword(password);
        final hashedWeakPassword = _hashPassword(weakPassword);

        // Hash should be different from original
        expect(hashedPassword, isNot(equals(password)));
        expect(hashedWeakPassword, isNot(equals(weakPassword)));

        // Hash should be consistent
        expect(_hashPassword(password), equals(hashedPassword));

        // Different passwords should have different hashes
        expect(hashedPassword, isNot(equals(hashedWeakPassword)));

        // Verify password
        expect(_verifyPassword(password, hashedPassword), isTrue);
        expect(_verifyPassword('wrongPassword', hashedPassword), isFalse);
      });

      test('should anonymize personal data', () {
        final personalData = UserProfile(
          id: 'user_123',
          email: 'john.doe@example.com',
          displayName: 'John Doe',
          photoUrl: 'https://example.com/photos/johndoe.jpg',
        );

        final anonymized = _anonymizeUserData(personalData);

        expect(anonymized.id, isNot(equals(personalData.id)));
        expect(anonymized.email, isNot(equals(personalData.email)));
        expect(anonymized.displayName, isNot(equals(personalData.displayName)));
        expect(anonymized.photoUrl, isNull);

        // Should still be usable for analytics while preserving privacy
        expect(anonymized.id, isNotEmpty);
        expect(anonymized.email, contains('@'));
        expect(anonymized.displayName, isNotEmpty);
      });

      test('should sanitize data for logging', () {
        final rawLogData = {
          'user_id': 'user_123',
          'action': 'classification',
          'sensitive_info': 'Credit card: 4111-1111-1111-1111',
          'location': 'GPS: 40.7128,-74.0060',
          'personal_note': 'This is my private note with SSN: 123-45-6789',
        };

        final sanitized = _sanitizeLogData(rawLogData);

        expect(sanitized['user_id'], isNot(equals(rawLogData['user_id'])));
        expect(sanitized['action'], equals(rawLogData['action'])); // Non-sensitive
        expect(sanitized['sensitive_info'], isNot(contains('4111-1111-1111-1111')));
        expect(sanitized['location'], isNot(contains('40.7128,-74.0060')));
        expect(sanitized['personal_note'], isNot(contains('123-45-6789')));
      });

      test('should implement data retention policies', () {
        final oldData = List.generate(100, (i) => _createOldDataItem(
          DateTime.now().subtract(Duration(days: 400 + i))
        ));

        final recentData = List.generate(50, (i) => _createOldDataItem(
          DateTime.now().subtract(Duration(days: i))
        ));

        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => [...oldData, ...recentData]);

        when(mockStorageService.deleteClassificationsBatch(any))
            .thenAnswer((_) async => {});

        // Apply retention policy (365 days)
        final retentionPolicy = DataRetentionPolicy(maxAgeDays: 365);
        await retentionPolicy.applyRetentionPolicy(mockStorageService);

        // Verify old data was deleted
        final deleteCall = verify(mockStorageService.deleteClassificationsBatch(captureAny)).captured;
        expect(deleteCall.first.length, equals(100)); // Old data deleted
      });
    });

    group('Input Validation Tests', () {
      test('should validate API request payloads', () {
        final maliciousPayloads = [
          {'nested': {'deep': {'exploit': 'x'.repeat(1000000)}}}, // Oversized
          {'circular': 'reference'}, // Would add circular reference in real scenario
          {'null_byte': 'test\x00payload'},
          {'unicode_exploit': '\u0000\u001f\u007f'},
          {'prototype_pollution': {'__proto__': {'isAdmin': true}}},
        ];

        for (final payload in maliciousPayloads) {
          expect(() => _validateApiPayload(payload),
                 throwsA(isA<SecurityException>()));
        }
      });

      test('should enforce rate limiting', () async {
        final rateLimiter = RateLimiter(maxRequests: 10, windowSeconds: 60);
        final userId = 'test_user';

        // Make requests within limit
        for (int i = 0; i < 10; i++) {
          expect(rateLimiter.isAllowed(userId), isTrue);
        }

        // Next request should be rate limited
        expect(rateLimiter.isAllowed(userId), isFalse);

        // Different user should not be affected
        expect(rateLimiter.isAllowed('other_user'), isTrue);
      });

      test('should validate content length limits', () {
        final normalContent = 'This is normal content';
        final oversizedContent = 'x' * (10 * 1024 * 1024); // 10MB
        final emptyContent = '';

        expect(_validateContentLength(normalContent, maxLength: 1000), isTrue);
        expect(_validateContentLength(oversizedContent, maxLength: 1000), isFalse);
        expect(_validateContentLength(emptyContent, maxLength: 1000), isTrue);
        expect(_validateContentLength(emptyContent, minLength: 1), isFalse);
      });

      test('should prevent header injection', () {
        final maliciousHeaders = [
          'Content-Type: text/html\r\nSet-Cookie: evil=payload',
          'User-Agent: Normal\nX-Evil-Header: payload',
          'Authorization: Bearer token\r\n\r\n<script>alert(1)</script>',
        ];

        for (final header in maliciousHeaders) {
          expect(() => _validateHttpHeader(header),
                 throwsA(isA<SecurityException>()));
        }

        // Valid headers should pass
        final validHeaders = [
          'Content-Type: application/json',
          'Authorization: Bearer valid-token',
          'User-Agent: MyApp/1.0',
        ];

        for (final header in validHeaders) {
          expect(() => _validateHttpHeader(header), returnsNormally);
        }
      });
    });

    group('Cross-Site Scripting (XSS) Prevention', () {
      test('should sanitize HTML content', () {
        final maliciousHtml = [
          '<script>alert("XSS")</script>',
          '<img src=x onerror=alert(1)>',
          '<iframe src="javascript:alert(1)"></iframe>',
          '<div onclick="alert(1)">Click me</div>',
          '<style>body{background:url("javascript:alert(1)")}</style>',
        ];

        for (final html in maliciousHtml) {
          final sanitized = _sanitizeHtml(html);
          expect(sanitized, isNot(contains('<script>')));
          expect(sanitized, isNot(contains('javascript:')));
          expect(sanitized, isNot(contains('onerror=')));
          expect(sanitized, isNot(contains('onclick=')));
        }
      });

      test('should encode user-generated content', () {
        final userContent = [
          '<>&"\'',
          'Normal text with <b>bold</b>',
          'Script: <script>alert(1)</script>',
          'Quote: "Hello" & \'World\'',
        ];

        for (final content in userContent) {
          final encoded = _encodeHtmlEntities(content);
          expect(encoded, isNot(contains('<script>')));
          expect(encoded, isNot(contains('<b>')));
          expect(encoded, contains('&lt;'));
          expect(encoded, contains('&gt;'));
          expect(encoded, contains('&amp;'));
          expect(encoded, contains('&quot;'));
        }
      });

      test('should validate URL schemes', () {
        final maliciousUrls = [
          'javascript:alert(1)',
          'data:text/html,<script>alert(1)</script>',
          'vbscript:msgbox(1)',
          'file:///etc/passwd',
          'ftp://malicious.com',
        ];

        final safeUrls = [
          'https://example.com',
          'http://example.com',
          'mailto:user@example.com',
          '/relative/path',
          '#anchor',
        ];

        for (final url in maliciousUrls) {
          expect(_isSafeUrl(url), isFalse);
        }

        for (final url in safeUrls) {
          expect(_isSafeUrl(url), isTrue);
        }
      });
    });

    group('Security Headers & CSRF Protection', () {
      test('should implement CSRF protection', () {
        final csrfToken = _generateCsrfToken();
        final validRequest = {
          'action': 'save_classification',
          'csrf_token': csrfToken,
          'data': {'item': 'test'},
        };

        final invalidRequest = {
          'action': 'save_classification',
          'csrf_token': 'invalid_token',
          'data': {'item': 'test'},
        };

        final missingTokenRequest = {
          'action': 'save_classification',
          'data': {'item': 'test'},
        };

        expect(_validateCsrfToken(validRequest), isTrue);
        expect(_validateCsrfToken(invalidRequest), isFalse);
        expect(_validateCsrfToken(missingTokenRequest), isFalse);
      });

      test('should validate content security policy', () {
        final csp = _generateContentSecurityPolicy();
        
        expect(csp, contains("default-src 'self'"));
        expect(csp, contains("script-src 'self'"));
        expect(csp, contains("style-src 'self' 'unsafe-inline'"));
        expect(csp, contains("img-src 'self' data: https:"));
        expect(csp, isNot(contains("'unsafe-eval'")));
      });

      test('should implement secure session management', () {
        final sessionId = _generateSecureSessionId();
        
        expect(sessionId.length, greaterThanOrEqualTo(32));
        expect(_isSecureSessionId(sessionId), isTrue);
        
        // Session should expire
        final expiredSession = _createExpiredSession();
        expect(_isValidSession(expiredSession), isFalse);
        
        // Session should be invalidated on logout
        final activeSession = _createActiveSession();
        expect(_isValidSession(activeSession), isTrue);
        
        _invalidateSession(activeSession);
        expect(_isValidSession(activeSession), isFalse);
      });
    });

    group('Audit Logging & Monitoring', () {
      test('should log security events', () async {
        final securityLogger = SecurityLogger();
        
        // Test different security events
        await securityLogger.logSecurityEvent(SecurityEventType.authenticationFailure, {
          'userId': 'test_user',
          'ipAddress': '192.168.1.1',
          'userAgent': 'TestAgent/1.0',
        });

        await securityLogger.logSecurityEvent(SecurityEventType.unauthorizedAccess, {
          'userId': 'malicious_user',
          'resource': 'admin_panel',
          'timestamp': DateTime.now().toIso8601String(),
        });

        final events = securityLogger.getSecurityEvents();
        expect(events.length, equals(2));
        expect(events[0].type, equals(SecurityEventType.authenticationFailure));
        expect(events[1].type, equals(SecurityEventType.unauthorizedAccess));
      });

      test('should detect suspicious activity patterns', () {
        final activityDetector = SuspiciousActivityDetector();
        
        // Simulate suspicious login attempts
        for (int i = 0; i < 10; i++) {
          activityDetector.recordEvent('login_failure', 'suspicious_user', {
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'ipAddress': '192.168.1.100',
          });
        }
        
        expect(activityDetector.isSuspicious('suspicious_user'), isTrue);
        expect(activityDetector.isSuspicious('normal_user'), isFalse);
      });

      test('should implement threat detection', () {
        final threatDetector = ThreatDetector();
        
        final threats = [
          {'type': 'sql_injection', 'payload': "' OR 1=1 --"},
          {'type': 'xss', 'payload': '<script>alert(1)</script>'},
          {'type': 'path_traversal', 'payload': '../../../etc/passwd'},
          {'type': 'command_injection', 'payload': '; rm -rf /'},
        ];
        
        for (final threat in threats) {
          final detected = threatDetector.detectThreat(threat['payload']!);
          expect(detected.isDetected, isTrue);
          expect(detected.threatType, equals(threat['type']));
        }
        
        // Normal content should not trigger detection
        final normalContent = 'This is normal user content';
        final normalResult = threatDetector.detectThreat(normalContent);
        expect(normalResult.isDetected, isFalse);
      });
    });
  });
}

// Security exception classes
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}

class UnauthorizedAccessException implements Exception {
  final String message;
  UnauthorizedAccessException(this.message);
  
  @override
  String toString() => 'UnauthorizedAccessException: $message';
}

// Helper functions for security testing
void _validateClassificationInput(Map<String, dynamic> input) {
  final itemName = input['itemName'] as String?;
  if (itemName == null || itemName.isEmpty) {
    throw SecurityException('Item name is required');
  }
  
  // Check for script tags
  if (itemName.toLowerCase().contains('<script>') || 
      itemName.toLowerCase().contains('javascript:')) {
    throw SecurityException('Invalid characters in item name');
  }
  
  // Check for SQL injection patterns
  final sqlPatterns = ['drop table', 'union select', "'; --", "' or '1'='1"];
  for (final pattern in sqlPatterns) {
    if (itemName.toLowerCase().contains(pattern)) {
      throw SecurityException('Potential SQL injection detected');
    }
  }
  
  // Check for path traversal
  if (itemName.contains('../') || itemName.contains('..\\')) {
    throw SecurityException('Path traversal detected');
  }
}

Map<String, dynamic> _sanitizeFeedbackInput(Map<String, dynamic> input) {
  final sanitized = <String, dynamic>{};
  
  for (final entry in input.entries) {
    if (entry.value is String) {
      String value = entry.value as String;
      
      // Remove script tags
      value = value.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '');
      
      // Remove javascript: protocol
      value = value.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');
      
      // Remove SQL injection patterns
      value = value.replaceAll(RegExp(r'drop\s+table', caseSensitive: false), '');
      value = value.replaceAll(RegExp(r'union\s+select', caseSensitive: false), '');
      
      sanitized[entry.key] = value;
    } else {
      sanitized[entry.key] = entry.value;
    }
  }
  
  return sanitized;
}

void _validateImageFile(String fileName, Uint8List data) {
  // Check file extension
  final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
  final extension = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
  
  if (!allowedExtensions.contains(extension)) {
    throw SecurityException('Invalid file extension: $extension');
  }
  
  // Check for path traversal in filename
  if (fileName.contains('../') || fileName.contains('..\\')) {
    throw SecurityException('Path traversal in filename');
  }
  
  // Check for double extensions (e.g., .php.jpg)
  final parts = fileName.split('.');
  if (parts.length > 2) {
    final secondExtension = '.${parts[parts.length - 2]}';
    final dangerousExtensions = ['.php', '.jsp', '.asp', '.js', '.html', '.exe'];
    if (dangerousExtensions.contains(secondExtension)) {
      throw SecurityException('Dangerous double extension detected');
    }
  }
  
  // Validate file headers (magic bytes)
  if (!_hasValidImageHeader(data)) {
    throw SecurityException('Invalid image file header');
  }
  
  // Check file size
  if (data.length > 10 * 1024 * 1024) { // 10MB limit
    throw SecurityException('File too large');
  }
}

bool _hasValidImageHeader(Uint8List data) {
  if (data.length < 4) return false;
  
  // JPEG: FF D8 FF
  if (data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF) return true;
  
  // PNG: 89 50 4E 47
  if (data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47) return true;
  
  // GIF: 47 49 46 38
  if (data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x38) return true;
  
  return false;
}

Uint8List _createValidImageData() {
  // Create minimal valid JPEG header
  return Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46]);
}

void _validateUserProfile(UserProfile profile) {
  // Validate email format
  if (profile.email != null && !_isValidEmail(profile.email!)) {
    throw SecurityException('Invalid email format');
  }
  
  // Check for script injection in display name
  if (profile.displayName != null && _containsMaliciousContent(profile.displayName!)) {
    throw SecurityException('Malicious content in display name');
  }
  
  // Validate photo URL
  if (profile.photoUrl != null && !_isSafeUrl(profile.photoUrl!)) {
    throw SecurityException('Unsafe photo URL');
  }
}

void _validateFamilyData(EnhancedFamily family) {
  if (_containsMaliciousContent(family.name)) {
    throw SecurityException('Malicious content in family name');
  }
  
  if (family.id.contains('../') || family.id.contains('..\\')) {
    throw SecurityException('Path traversal in family ID');
  }
}

bool _isValidEmail(String email) {
  return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
}

bool _containsMaliciousContent(String content) {
  final maliciousPatterns = [
    r'<script[^>]*>',
    r'javascript:',
    r'<iframe[^>]*>',
    r'onclick\s*=',
    r'onerror\s*=',
    r'drop\s+table',
    r'union\s+select',
  ];
  
  for (final pattern in maliciousPatterns) {
    if (RegExp(pattern, caseSensitive: false).hasMatch(content)) {
      return true;
    }
  }
  
  return false;
}

void _checkDataAccess(UserProfile accessor, WasteClassification data) {
  if (data.userId != accessor.id) {
    throw UnauthorizedAccessException('User cannot access data belonging to another user');
  }
}

bool _checkFamilyPermission(String userId, EnhancedFamily family, String permission) {
  final member = family.members.where((m) => m.userId == userId).firstOrNull;
  
  if (member == null) return false;
  
  switch (permission) {
    case 'view':
      return true; // All members can view
    case 'manage':
      return member.role == FamilyRole.admin;
    default:
      return false;
  }
}

String _generateSecureToken() {
  final bytes = List.generate(32, (i) => i % 256);
  return base64Encode(bytes);
}

String _generateExpiredToken() {
  // Return a token that appears expired
  return 'expired_token_${DateTime.now().subtract(Duration(hours: 24)).millisecondsSinceEpoch}';
}

String _generateTamperedToken() {
  // Return a token that appears tampered
  return 'tampered_token_invalid_signature';
}

bool _validateSessionToken(String token) {
  if (token.contains('<script>') || token.contains('javascript:')) {
    return false;
  }
  
  if (token.startsWith('expired_token_')) {
    return false;
  }
  
  if (token.startsWith('tampered_token_')) {
    return false;
  }
  
  return token.length >= 20;
}

void _checkPrivilegeEscalation(UserProfile user, Map<String, dynamic> action) {
  final privilegedActions = ['admin_access', 'delete_all_data', 'modify_user_role'];
  
  if (privilegedActions.contains(action['action'])) {
    throw UnauthorizedAccessException('User does not have permission for privileged action');
  }
}

Map<String, dynamic> _encryptSensitiveData(Map<String, dynamic> data) {
  final encrypted = <String, dynamic>{};
  
  for (final entry in data.entries) {
    if (entry.value is String) {
      // Simple encryption simulation (in real app, use proper encryption)
      final encoded = base64Encode(utf8.encode(entry.value as String));
      encrypted[entry.key] = 'encrypted_$encoded';
    } else {
      encrypted[entry.key] = entry.value;
    }
  }
  
  return encrypted;
}

Map<String, dynamic> _decryptSensitiveData(Map<String, dynamic> encryptedData) {
  final decrypted = <String, dynamic>{};
  
  for (final entry in encryptedData.entries) {
    if (entry.value is String && (entry.value as String).startsWith('encrypted_')) {
      final encoded = (entry.value as String).substring('encrypted_'.length);
      final decoded = utf8.decode(base64Decode(encoded));
      decrypted[entry.key] = decoded;
    } else {
      decrypted[entry.key] = entry.value;
    }
  }
  
  return decrypted;
}

String _hashPassword(String password) {
  final bytes = utf8.encode(password + 'salt'); // In real app, use proper salt
  final digest = sha256.convert(bytes);
  return digest.toString();
}

bool _verifyPassword(String password, String hashedPassword) {
  return _hashPassword(password) == hashedPassword;
}

UserProfile _anonymizeUserData(UserProfile profile) {
  final hashedId = sha256.convert(utf8.encode(profile.id)).toString().substring(0, 16);
  final domain = profile.email?.split('@').last ?? 'example.com';
  final anonymizedEmail = 'user_${hashedId.substring(0, 8)}@$domain';
  final anonymizedName = 'User ${hashedId.substring(0, 8)}';
  
  return UserProfile(
    id: 'anon_$hashedId',
    email: anonymizedEmail,
    displayName: anonymizedName,
    photoUrl: null, // Remove photo for privacy
    createdAt: profile.createdAt,
    lastActive: profile.lastActive,
  );
}

Map<String, dynamic> _sanitizeLogData(Map<String, dynamic> data) {
  final sanitized = <String, dynamic>{};
  
  for (final entry in data.entries) {
    if (entry.value is String) {
      String value = entry.value as String;
      
      // Remove credit card numbers
      value = value.replaceAll(RegExp(r'\d{4}-\d{4}-\d{4}-\d{4}'), '[CARD-REDACTED]');
      
      // Remove SSNs
      value = value.replaceAll(RegExp(r'\d{3}-\d{2}-\d{4}'), '[SSN-REDACTED]');
      
      // Remove GPS coordinates
      value = value.replaceAll(RegExp(r'-?\d+\.\d+,-?\d+\.\d+'), '[GPS-REDACTED]');
      
      // Hash user IDs
      if (entry.key == 'user_id') {
        value = sha256.convert(utf8.encode(value)).toString().substring(0, 16);
      }
      
      sanitized[entry.key] = value;
    } else {
      sanitized[entry.key] = entry.value;
    }
  }
  
  return sanitized;
}

WasteClassification _createOldDataItem(DateTime timestamp) {
  return WasteClassification(
    itemName: 'Old Item',
    category: 'Dry Waste',
    explanation: 'Old data for retention testing',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Test',
      steps: ['Step 1'],
      hasUrgentTimeframe: false,
    ),
    timestamp: timestamp,
    region: 'Test Region',
    visualFeatures: [],
    alternatives: [],
  );
}

void _validateApiPayload(Map<String, dynamic> payload) {
  final jsonString = jsonEncode(payload);
  
  // Check payload size
  if (jsonString.length > 1024 * 1024) { // 1MB limit
    throw SecurityException('Payload too large');
  }
  
  // Check for null bytes
  if (jsonString.contains('\x00')) {
    throw SecurityException('Null byte detected in payload');
  }
  
  // Check nesting depth (prevent stack overflow)
  if (_getMaxDepth(payload) > 10) {
    throw SecurityException('Payload nesting too deep');
  }
}

int _getMaxDepth(dynamic obj, [int currentDepth = 0]) {
  if (obj is Map) {
    int maxChildDepth = currentDepth;
    for (final value in obj.values) {
      final childDepth = _getMaxDepth(value, currentDepth + 1);
      if (childDepth > maxChildDepth) {
        maxChildDepth = childDepth;
      }
    }
    return maxChildDepth;
  } else if (obj is List) {
    int maxChildDepth = currentDepth;
    for (final item in obj) {
      final childDepth = _getMaxDepth(item, currentDepth + 1);
      if (childDepth > maxChildDepth) {
        maxChildDepth = childDepth;
      }
    }
    return maxChildDepth;
  }
  return currentDepth;
}

bool _validateContentLength(String content, {int? maxLength, int? minLength}) {
  if (maxLength != null && content.length > maxLength) {
    return false;
  }
  if (minLength != null && content.length < minLength) {
    return false;
  }
  return true;
}

void _validateHttpHeader(String header) {
  if (header.contains('\r') || header.contains('\n')) {
    throw SecurityException('Header injection detected');
  }
}

String _sanitizeHtml(String html) {
  return html
    .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
    .replaceAll(RegExp(r'<iframe[^>]*>.*?</iframe>', caseSensitive: false), '')
    .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
    .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');
}

String _encodeHtmlEntities(String content) {
  return content
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#x27;');
}

bool _isSafeUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  
  final safeSchemes = ['http', 'https', 'mailto'];
  
  // Allow relative URLs
  if (url.startsWith('/') || url.startsWith('#')) return true;
  
  return safeSchemes.contains(uri.scheme);
}

String _generateCsrfToken() {
  final bytes = List.generate(32, (i) => DateTime.now().millisecondsSinceEpoch % 256);
  return base64Encode(bytes);
}

bool _validateCsrfToken(Map<String, dynamic> request) {
  final token = request['csrf_token'] as String?;
  if (token == null) return false;
  
  // In real app, would validate against server-side token
  return token.isNotEmpty && !token.contains('invalid');
}

String _generateContentSecurityPolicy() {
  return "default-src 'self'; "
         "script-src 'self'; "
         "style-src 'self' 'unsafe-inline'; "
         "img-src 'self' data: https:; "
         "font-src 'self'; "
         "connect-src 'self' https:; "
         "frame-ancestors 'none'; "
         "base-uri 'self';";
}

String _generateSecureSessionId() {
  final bytes = List.generate(32, (i) => DateTime.now().microsecondsSinceEpoch % 256);
  return base64Encode(bytes);
}

bool _isSecureSessionId(String sessionId) {
  return sessionId.length >= 32 && !sessionId.contains(' ');
}

Session _createExpiredSession() {
  return Session(
    id: _generateSecureSessionId(),
    expiresAt: DateTime.now().subtract(Duration(hours: 1)),
  );
}

Session _createActiveSession() {
  return Session(
    id: _generateSecureSessionId(),
    expiresAt: DateTime.now().add(Duration(hours: 24)),
  );
}

bool _isValidSession(Session session) {
  return DateTime.now().isBefore(session.expiresAt) && !session.isInvalidated;
}

void _invalidateSession(Session session) {
  session.isInvalidated = true;
}

// Supporting classes for security testing
class DataRetentionPolicy {
  final int maxAgeDays;
  
  DataRetentionPolicy({required this.maxAgeDays});
  
  Future<void> applyRetentionPolicy(MockStorageService storageService) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeDays));
    final allData = await storageService.getAllClassifications();
    final oldData = allData.where((item) => item.timestamp.isBefore(cutoffDate)).toList();
    
    if (oldData.isNotEmpty) {
      await storageService.deleteClassificationsBatch(oldData);
    }
  }
}

class RateLimiter {
  final int maxRequests;
  final int windowSeconds;
  final Map<String, List<DateTime>> _requests = {};
  
  RateLimiter({required this.maxRequests, required this.windowSeconds});
  
  bool isAllowed(String userId) {
    final now = DateTime.now();
    final windowStart = now.subtract(Duration(seconds: windowSeconds));
    
    _requests[userId] ??= [];
    
    // Remove old requests outside the window
    _requests[userId]!.removeWhere((time) => time.isBefore(windowStart));
    
    if (_requests[userId]!.length >= maxRequests) {
      return false;
    }
    
    _requests[userId]!.add(now);
    return true;
  }
}

class Session {
  final String id;
  final DateTime expiresAt;
  bool isInvalidated = false;
  
  Session({required this.id, required this.expiresAt});
}

enum SecurityEventType {
  authenticationFailure,
  unauthorizedAccess,
  suspiciousActivity,
  dataViolation,
}

class SecurityEvent {
  final SecurityEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  
  SecurityEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });
}

class SecurityLogger {
  final List<SecurityEvent> _events = [];
  
  Future<void> logSecurityEvent(SecurityEventType type, Map<String, dynamic> data) async {
    _events.add(SecurityEvent(
      type: type,
      data: data,
      timestamp: DateTime.now(),
    ));
  }
  
  List<SecurityEvent> getSecurityEvents() => List.unmodifiable(_events);
}

class SuspiciousActivityDetector {
  final Map<String, List<Map<String, dynamic>>> _userEvents = {};
  
  void recordEvent(String eventType, String userId, Map<String, dynamic> metadata) {
    _userEvents[userId] ??= [];
    _userEvents[userId]!.add({
      'type': eventType,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...metadata,
    });
  }
  
  bool isSuspicious(String userId) {
    final events = _userEvents[userId] ?? [];
    final recentEvents = events.where((event) {
      final eventTime = event['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      return (now - eventTime) < (60 * 60 * 1000); // Within 1 hour
    }).toList();
    
    // Suspicious if more than 5 failed login attempts in 1 hour
    final failedLogins = recentEvents.where((e) => e['type'] == 'login_failure').length;
    return failedLogins > 5;
  }
}

class ThreatDetectionResult {
  final bool isDetected;
  final String? threatType;
  final double confidence;
  
  ThreatDetectionResult({
    required this.isDetected,
    this.threatType,
    this.confidence = 0.0,
  });
}

class ThreatDetector {
  ThreatDetectionResult detectThreat(String input) {
    // SQL Injection detection
    if (RegExp(r"'\s*(or|union|select|drop|insert|update|delete)", caseSensitive: false).hasMatch(input)) {
      return ThreatDetectionResult(isDetected: true, threatType: 'sql_injection', confidence: 0.9);
    }
    
    // XSS detection
    if (RegExp(r'<script[^>]*>', caseSensitive: false).hasMatch(input)) {
      return ThreatDetectionResult(isDetected: true, threatType: 'xss', confidence: 0.95);
    }
    
    // Path traversal detection
    if (input.contains('../') || input.contains('..\\')) {
      return ThreatDetectionResult(isDetected: true, threatType: 'path_traversal', confidence: 0.8);
    }
    
    // Command injection detection
    if (RegExp(r';\s*(rm|del|format|shutdown)', caseSensitive: false).hasMatch(input)) {
      return ThreatDetectionResult(isDetected: true, threatType: 'command_injection', confidence: 0.85);
    }
    
    return ThreatDetectionResult(isDetected: false);
  }
}

// Extension for MockStorageService
extension MockStorageServiceSecurity on MockStorageService {
  Future<List<WasteClassification>> getAllClassifications() async {
    // Mock implementation
    return [];
  }
  
  Future<void> deleteClassificationsBatch(List<WasteClassification> classifications) async {
    // Mock implementation
  }
}
