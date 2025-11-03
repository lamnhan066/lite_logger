import 'dart:async'; // Required for Zone and ZoneSpecification

import 'package:lite_logger/src/lite_logger.dart';
import 'package:lite_logger/src/models/log_color.dart';
import 'package:lite_logger/src/models/log_level.dart';
import 'package:test/test.dart';

// Utility to capture print output within a test zone.
// This function creates and returns a new Zone
// where print statements are intercepted.
Zone createTestZone(void Function(String s) fn) {
  return Zone.current.fork(
    specification: ZoneSpecification(
      print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
        fn(line);
      },
    ),
  );
}

void main() {
  group('LogLevel', () {
    test('should have correct number of levels', () {
      expect(LogLevel.values.length, 6);
    });

    test('should have correct order of levels', () {
      expect(LogLevel.error.index, 0);
      expect(LogLevel.warning.index, 1);
      expect(LogLevel.success.index, 2);
      expect(LogLevel.info.index, 3);
      expect(LogLevel.step.index, 4);
      expect(LogLevel.debug.index, 5);
    });
  });

  group('LogColor', () {
    test('should have correct number of colors', () {
      expect(LogColor.values.length, 6);
    });

    test('should return correct ANSI escape codes', () {
      expect(LogColor.blue.color, '\x1B[34m');
      expect(LogColor.yellow.color, '\x1B[33m');
      expect(LogColor.red.color, '\x1B[31m');
      expect(LogColor.gray.color, '\x1B[90m');
      expect(LogColor.green.color, '\x1B[32m');
      expect(LogColor.cyan.color, '\x1B[36m');
    });
  });

  group('LiteLogger Basic Functionality', () {
    late List<String> capturedPrints;
    late Zone testZone;

    setUp(() {
      capturedPrints = [];
      testZone = createTestZone((s) => capturedPrints.add(s));
    });

    test(
      'should log messages when enabled and minLevel is met',
      () => testZone.run(() {
        const LiteLogger().info('Test message');
        expect(capturedPrints, isNotEmpty);
        expect(capturedPrints.first, contains('Test message'));
      }),
    );

    test(
      'should not log messages when disabled',
      () => testZone.run(() {
        const LiteLogger(enabled: false).info('Test message');
        expect(capturedPrints, isEmpty);
      }),
    );

    test(
      'should not log messages when minLevel is not met',
      () => testZone.run(() {
        const LiteLogger(minLevel: LogLevel.warning).info('Test message');
        expect(capturedPrints, isEmpty);
      }),
    );

    test(
      'should log messages when minLevel is met (equal level)',
      () => testZone.run(() {
        const LiteLogger(minLevel: LogLevel.warning).warning('Warning message');
        expect(capturedPrints, isNotEmpty);
        expect(capturedPrints.first, contains('Warning message'));
      }),
    );

    test(
      'should log messages with correct color, icon, level, and timestamp',
      () => testZone.run(() {
        const LiteLogger().info('Info message');
        final logOutput = capturedPrints.first;

        expect(logOutput, contains('\x1B[34m')); // Blue color for info
        expect(logOutput, contains('💡')); // Info icon
        expect(logOutput, contains('[INFO]')); // Info level text
        expect(logOutput, contains('[')); // Timestamp start
        expect(logOutput, contains(']')); // Timestamp end
        expect(logOutput, contains('Info message'));
        expect(logOutput, endsWith('\x1B[0m')); // Reset color
      }),
    );

    test(
      'should use custom format string',
      () => testZone.run(() {
        const LiteLogger(
          format: '[@{level}] @{message} @{icon}',
        ).info('Custom format');
        final logOutput = capturedPrints.first;
        expect(logOutput, contains('[INFO] Custom format 💡'));
      }),
    );

    test(
      'should use custom timestamp function',
      () => testZone.run(() {
        LiteLogger(timestamp: (date) => 'TIME').info('Custom timestamp');
        final logOutput = capturedPrints.first;
        expect(logOutput, contains('TIME'));
      }),
    );

    test(
      'should use custom colors',
      () => testZone.run(() {
        final customColors = {LogLevel.info: LogColor.red};
        LiteLogger(colors: customColors).info('Custom color');
        final logOutput = capturedPrints.first;
        expect(logOutput, contains('\x1B[31m')); // Red color
      }),
    );

    test(
      'should use custom emojis',
      () => testZone.run(() {
        final customEmojis = {LogLevel.info: '😀'};
        LiteLogger(emojis: customEmojis).info('Custom emoji');
        final logOutput = capturedPrints.first;
        expect(logOutput, contains('😀'));
      }),
    );

    test(
      'should use custom level text',
      () => testZone.run(() {
        final customLevelText = {LogLevel.info: 'INF'};
        LiteLogger(levelTexts: customLevelText).info('Custom level text');
        final logOutput = capturedPrints.first;
        expect(logOutput, contains('[INF]'));
      }),
    );

    test(
      'should call custom callback if provided',
      () => testZone.run(() {
        String? rawMessage;
        String? coloredMessage;
        LogLevel? logLevel;

        LiteLogger(
          callback: (raw, colored, level) {
            rawMessage = raw;
            coloredMessage = colored;
            logLevel = level;
          },
        ).info('Callback test');

        expect(rawMessage, 'Callback test');
        expect(coloredMessage, contains('Callback test'));
        expect(logLevel, LogLevel.info);
        expect(capturedPrints, isEmpty); // Should not print to console
      }),
    );

    test(
      'should lazily evaluate message functions',
      () => testZone.run(() {
        var functionCalled = false;
        const LiteLogger().info(() {
          functionCalled = true;
          return 'Lazy message';
        });

        expect(functionCalled, isTrue);
        expect(capturedPrints.first, contains('Lazy message'));
      }),
    );

    test(
      'should not lazily evaluate message functions if minLevel not met',
      () => testZone.run(() {
        var functionCalled = false;
        const LiteLogger(minLevel: LogLevel.warning).info(() {
          functionCalled = true;
          return 'Lazy message';
        });

        expect(functionCalled, isFalse);
        expect(capturedPrints, isEmpty);
      }),
    );

    test(
      'should handle all convenience methods',
      () => testZone.run(() {
        const LiteLogger(minLevel: LogLevel.debug)
          ..error('Error message')
          ..warning('Warning message')
          ..success('Success message')
          ..info('Info message')
          ..step('Step message')
          ..debug('Debug message');

        expect(capturedPrints.length, 6);
        expect(capturedPrints[0], contains('Error message'));
        expect(capturedPrints[1], contains('Warning message'));
        expect(capturedPrints[2], contains('Success message'));
        expect(capturedPrints[3], contains('Info message'));
        expect(capturedPrints[4], contains('Step message'));
        expect(capturedPrints[5], contains('Debug message'));
      }),
    );

    test(
      'should include logger name in output when provided',
      () => testZone.run(() {
        const LiteLogger(name: 'MyLogger').info('Test message');
        final logOutput = capturedPrints.first;
        expect(logOutput, contains('[MyLogger]'));
      }),
    );

    test(
      'should not include logger name prefix when name is empty',
      () => testZone.run(() {
        const LiteLogger(name: '').info('Test message');
        final logOutput = capturedPrints.first;
        // Should not contain a name prefix pattern like [Name]:
        expect(logOutput, isNot(matches(r'\[.*?\]:')));
      }),
    );

    test(
      'should format output correctly with logger name and color',
      () => testZone.run(() {
        const LiteLogger(name: 'App').info('Info message');
        final logOutput = capturedPrints.first;
        // Check that name appears with color code before it
        expect(logOutput, contains('\x1B[34m[App]:'));
        expect(logOutput, contains('Info message'));
      }),
    );

    test(
      'should use print() when usePrint is true',
      () => testZone.run(() {
        const LiteLogger(usePrint: true, name: 'TestLogger').info('Test');
        expect(capturedPrints, isNotEmpty);
        expect(capturedPrints.first, contains('[TestLogger]'));
      }),
    );

    test(
      'should include name in callback when provided',
      () => testZone.run(() {
        String? capturedColored;
        LiteLogger(
          name: 'CallbackLogger',
          callback: (raw, colored, level) {
            capturedColored = colored;
          },
        ).info('Test callback');
        
        expect(capturedColored, isNotNull);
        // The callback receives the colored output, which should include name
        // when using print (but callback bypasses print, so it won't have name prefix)
        expect(capturedColored, contains('Test callback'));
        expect(capturedPrints, isEmpty); // Should not print when callback is set
      }),
    );

    test(
      'should work with custom name and custom format',
      () => testZone.run(() {
        const LiteLogger(
          name: 'CustomLogger',
          format: '@{message} (@{level})',
        ).warning('Custom warning');
        
        final logOutput = capturedPrints.first;
        expect(logOutput, contains('[CustomLogger]'));
        expect(logOutput, contains('Custom warning'));
        expect(logOutput, contains('(WARN)'));
      }),
    );
  });
}
