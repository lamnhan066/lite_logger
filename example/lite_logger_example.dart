import 'package:lite_logger/lite_logger.dart';

void main() {
  print('=== Basic Usage ===');
  const LiteLogger(
    name: 'App',
    minLevel: LogLevel.debug,
  )
    ..info('Application started')
    ..step('Loading configuration...')
    ..debug(() => 'Debug timestamp: ${DateTime.now().millisecondsSinceEpoch}')
    ..success('Configuration loaded')
    ..warning('Low disk space')
    ..error('Unable to access database');

  print('\n=== Multiple Named Loggers ===');
  final apiLogger = LiteLogger(name: 'API');
  final dbLogger = LiteLogger(name: 'Database');
  final authLogger = LiteLogger(name: 'Auth');

  apiLogger.info('Fetching user data');
  dbLogger.debug('Executing query...');
  authLogger.warning('Token expiring soon');

  print('\n=== Using Callback ===');
  LiteLogger(
    name: 'Service',
    minLevel: LogLevel.debug,
    callback: (raw, colored, level) {
      // Example: You could send to a file or remote service here
      // ignore: avoid_print
      print('Callback - Raw: $raw, Level: ${level.name}');
    },
  )
    ..info('Application started')
    ..step('Loading configuration...')
    ..debug(() => 'Debug timestamp: ${DateTime.now().millisecondsSinceEpoch}')
    ..success('Configuration loaded')
    ..warning('Low disk space')
    ..error('Unable to access database');

  print('\n=== Using developer.log() (default) ===');
  LiteLogger(
    name: 'DevLogger',
    // usePrint defaults to false (developer.log())
    minLevel: LogLevel.debug,
  )
    ..info('This uses developer.log()')
    ..warning('Less platform noise')
    ..error('Better for development tools');

  print('\n=== Using print() instead of developer.log() ===');
  LiteLogger(
    name: 'PrintLogger',
    usePrint: true, // Explicitly use print() instead of default
    minLevel: LogLevel.debug,
  )
    ..info('This uses print()')
    ..warning('May include platform prefixes')
    ..error('Maximum compatibility');

  print('\n=== Custom Format with Named Logger ===');
  LiteLogger(
    name: 'Custom',
    format: '@{icon} @{level}: @{message}',
  )
    ..info('Custom format example')
    ..success('With logger name prefix');

  print('\n=== Lazy Evaluation Example ===');
  final logger = LiteLogger(name: 'Lazy');
  var expensiveCallCount = 0;

  logger.debug(() {
    expensiveCallCount++;
    // This function is only called if debug level is enabled
    return 'Expensive computation result: ${DateTime.now().millisecondsSinceEpoch}';
  });
  // ignore: avoid_print
  print('Expensive function was called $expensiveCallCount time(s)');

  // With minLevel above debug, the function won't be called
  const LiteLogger(minLevel: LogLevel.warning).debug(() {
    // This will never execute
    return 'This is expensive and will not run';
  });
}
