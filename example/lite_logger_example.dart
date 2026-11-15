// Example prints output by design.
// ignore_for_file: avoid_print

import 'package:lite_logger/lite_logger.dart';

void main() {
  print('=== Basic Usage (auto output) ===');
  const LiteLogger(name: 'App', minLevel: LogLevel.debug)
    ..info('Application started')
    ..step('Loading configuration...')
    ..debug(() => 'Debug timestamp: ${DateTime.now().millisecondsSinceEpoch}')
    ..success('Configuration loaded')
    ..warning('Low disk space')
    ..error('Unable to access database');

  print('\n=== Multiple Named Loggers ===');
  const apiLogger = LiteLogger(name: 'API');
  const dbLogger = LiteLogger(name: 'Database');
  const authLogger = LiteLogger(name: 'Auth');

  apiLogger.info('Fetching user data');
  dbLogger.debug('Executing query...');
  authLogger.warning('Token expiring soon');

  print('\n=== Using Callback ===');
  LiteLogger(
      name: 'Service',
      minLevel: LogLevel.debug,
      callback: (raw, colored, level) {
        print('Callback - Raw: $raw, Level: ${level.name}');
      },
    )
    ..info('Application started')
    ..step('Loading configuration...')
    ..debug(() => 'Debug timestamp: ${DateTime.now().millisecondsSinceEpoch}')
    ..success('Configuration loaded')
    ..warning('Low disk space')
    ..error('Unable to access database');

  print('\n=== Using print() explicitly ===');
  const LiteLogger(
      name: 'DevLogger',
      minLevel: LogLevel.debug,
      output: LogOutput.print,
    )
    ..info('This uses print() explicitly')
    ..warning('Use this for plain `dart run` terminals without a debugger')
    ..error('Explicit print() is still available');

  print('\n=== Using developer.log() explicitly ===');
  const LiteLogger(
      name: 'PrintLogger',
      output: LogOutput.developerLog,
      minLevel: LogLevel.debug,
    )
    ..info('This uses developer.log()')
    ..warning('Cleaner output for tooling')
    ..error('Explicitly opt out of print()');

  print('\n=== Custom Format with Named Logger ===');
  const LiteLogger(name: 'Custom', format: '@{icon} @{level}: @{message}')
    ..info('Custom format example')
    ..success('With logger name prefix');

  print('\n=== Lazy Evaluation Example ===');
  const logger = LiteLogger(name: 'Lazy');
  var expensiveCallCount = 0;

  logger.debug(() {
    expensiveCallCount++;
    return 'Expensive computation result: '
        '${DateTime.now().millisecondsSinceEpoch}';
  });
  print('Expensive function was called $expensiveCallCount time(s)');

  const LiteLogger(minLevel: LogLevel.warning).debug(() {
    return 'This is expensive and will not run';
  });
}
