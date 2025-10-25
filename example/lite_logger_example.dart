import 'package:lite_logger/lite_logger.dart';

void main() {
  const LiteLogger(minLevel: LogLevel.debug)
    ..info('Application started')
    ..step('Loading configuration...')
    ..debug(
      () => 'Debug timestamp: ${DateTime.now().millisecondsSinceEpoch}',
    )
    ..success('Configuration loaded')
    ..warning('Low disk space')
    ..error('Unable to access database');

  LiteLogger(
      minLevel: LogLevel.debug,
      callback: (raw, colored, level) {
        // Example
        // ignore: avoid_print
        print('Raw: $raw');
      },
    )
    ..info('Application started')
    ..step('Loading configuration...')
    ..debug(
      () => 'Debug timestamp: ${DateTime.now().millisecondsSinceEpoch}',
    )
    ..success('Configuration loaded')
    ..warning('Low disk space')
    ..error('Unable to access database');
}
