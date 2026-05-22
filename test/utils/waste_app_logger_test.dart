import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

void main() {
  group('WasteAppLogger', () {
    late List<LogRecord> capturedRecords;
    StreamSubscription<LogRecord>? subscription;

    Stream<LogRecord> recordStream() => Logger.root.onRecord;

    setUp(() async {
      await WasteAppLogger.resetForTests();
      capturedRecords = [];
      Logger.root.level = Level.ALL;
      subscription = recordStream().listen(capturedRecords.add);
    });

    tearDown(() async {
      await subscription?.cancel();
      subscription = null;
      await WasteAppLogger.resetForTests();
    });

    test('initialize sets session ID and marks initialized', () async {
      await WasteAppLogger.initialize();

      final initRecord = capturedRecords.firstWhere(
        (r) => r.message.contains('WasteAppLogger initialized'),
      );
      expect(initRecord, isNotNull);
    });

    test('info logs at INFO level', () {
      WasteAppLogger.info('test info message');

      expect(capturedRecords, isNotEmpty);
      final record = capturedRecords.last;
      expect(record.level, equals(Level.INFO));
      expect(record.message, contains('test info message'));
    });

    test('warning logs at WARNING level', () {
      WasteAppLogger.warning('test warning');

      final record = capturedRecords.last;
      expect(record.level, equals(Level.WARNING));
      expect(record.message, contains('test warning'));
    });

    test('severe logs at SEVERE level', () {
      WasteAppLogger.severe('test error', error: Exception('boom'));

      final record = capturedRecords.last;
      expect(record.level, equals(Level.SEVERE));
      expect(record.message, contains('test error'));
      expect(record.error, isNotNull);
    });

    test('debug alias logs at INFO level', () {
      WasteAppLogger.debug('debug msg');

      final record = capturedRecords.last;
      expect(record.level, equals(Level.INFO));
      expect(record.message, contains('debug msg'));
    });

    test('fine alias logs at INFO level', () {
      WasteAppLogger.fine('fine msg');

      final record = capturedRecords.last;
      expect(record.level, equals(Level.INFO));
      expect(record.message, contains('fine msg'));
    });

    test('aiEvent includes AI prefix', () {
      WasteAppLogger.aiEvent('classification', model: 'gpt-4o');

      final record = capturedRecords.last;
      expect(record.message, contains('AI:'));
      expect(record.message, contains('classification'));
      expect(record.message, contains('gpt-4o'));
    });

    test('userAction prefixes message', () {
      WasteAppLogger.userAction('tapped_scan');

      final record = capturedRecords.last;
      expect(record.message, contains('Action: tapped_scan'));
    });

    test('wasteEvent prefixes message', () {
      WasteAppLogger.wasteEvent('classified', 'plastic');

      final record = capturedRecords.last;
      expect(record.message, contains('Waste: classified - plastic'));
    });

    test('performanceLog formats timing', () {
      WasteAppLogger.performanceLog('classification', 150);

      final record = capturedRecords.last;
      expect(record.message, contains('Perf: classification 150ms'));
    });

    test('cacheEvent logs info and warning on error', () {
      WasteAppLogger.cacheEvent(
        'lookup',
        'classification',
        hit: true,
        key: 'abc123',
        error: Exception('cache miss'),
      );

      expect(
        capturedRecords.where((r) => r.message.contains('Cache: lookup')),
        hasLength(2),
      );
      final warnRecord = capturedRecords.last;
      expect(warnRecord.level, equals(Level.WARNING));
    });

    test('navigationEvent formats from -> to', () {
      WasteAppLogger.navigationEvent('push', 'Home', 'Result');

      final record = capturedRecords.last;
      expect(record.message, contains('Nav: push Home -> Result'));
    });

    test('gamificationEvent logs game prefix', () {
      WasteAppLogger.gamificationEvent(
        'points_earned',
        points: 50,
        pointsEarned: 25,
        achievementId: 'first_classify',
      );

      final record = capturedRecords.last;
      expect(record.message, contains('Game: points_earned'));
    });

    test('setCurrentAction enriches context', () {
      WasteAppLogger.setCurrentAction('classify');
      WasteAppLogger.info('test with action');

      final record = capturedRecords.last;
      expect(record.message, contains('action'));
    });

    test('setCurrentScreen enriches context', () {
      WasteAppLogger.setCurrentScreen('ResultScreen');
      WasteAppLogger.info('test with screen');

      final record = capturedRecords.last;
      expect(record.message, contains('screen'));
    });

    test('context map is included in message', () {
      WasteAppLogger.info('with context', context: {'key': 'value'});

      final record = capturedRecords.last;
      expect(record.message, contains('key'));
      expect(record.message, contains('value'));
    });

    test('severe with error and stackTrace', () {
      final error = StateError('bad state');
      final stack = StackTrace.current;

      WasteAppLogger.severe(
        'critical failure',
        error: error,
        stackTrace: stack,
      );

      final record = capturedRecords.last;
      expect(record.level, equals(Level.SEVERE));
      expect(record.error, equals(error));
      expect(record.stackTrace, equals(stack));
    });

    test('gamificationEvent logs warning on error', () {
      WasteAppLogger.gamificationEvent(
        'streak_broken',
        error: Exception('network'),
      );

      final warnRecord = capturedRecords.last;
      expect(warnRecord.level, equals(Level.WARNING));
      expect(warnRecord.message, contains('Game: streak_broken error'));
    });
  });
}
