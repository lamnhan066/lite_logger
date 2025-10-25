import 'package:lite_logger/lite_logger.dart';

void main() {
  final logger1 = LiteLogger(
    enabled: true,
    minLevel: LogLevel.debug, // show all levels
  );

  logger1.info('Application started');
  logger1.step('Loading configuration...');
  logger1.debug(
    () => 'Debug timestamp: ${DateTime.now().millisecondsSinceEpoch}',
  );
  logger1.success('Configuration loaded');
  logger1.warning('Low disk space');
  logger1.error('Unable to access database');

  final logger2 = LiteLogger(
    enabled: true,
    minLevel: LogLevel.debug, // show all levels
    callback: (raw, colored, level) {
      print('Raw: $raw');
    },
  );

  logger2.info('Application started');
  logger2.step('Loading configuration...');
  logger2.debug(
    () => 'Debug timestamp: ${DateTime.now().millisecondsSinceEpoch}',
  );
  logger2.success('Configuration loaded');
  logger2.warning('Low disk space');
  logger2.error('Unable to access database');
}
