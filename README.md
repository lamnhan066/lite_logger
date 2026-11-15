# LiteLogger

A lightweight logging utility for Dart & Flutter with colored output, log filtering, and custom formatting.

## Installation

```sh
dart pub add lite_logger
```

## Features

* Log level filtering (`error`, `warning`, `success`, `info`, `step`, `debug`)
* ANSI colors and emoji indicators
* Lazy message evaluation
* Custom format templates
* Callback support (file, cloud, analytics)
* Global enable/disable switch

## Getting Started

```dart
final logger = LiteLogger(
  name: 'MyApp',
  minLevel: LogLevel.debug,
);

logger.info('Application started');
logger.step('Loading configuration...');
logger.debug(() => 'Debug timestamp: ${DateTime.now().millisecondsSinceEpoch}');
logger.success('Configuration loaded');
logger.warning('Low disk space');
logger.error('Unable to access database');
```

## Advanced Configuration

```dart
final logger = LiteLogger(
  name: 'MyService',
  minLevel: LogLevel.debug,
  timestamp: (dt) => '[${dt.toIso8601String()}]',
  format: '@{color}@{timestamp} @{icon} [@{level}] @{message}',
  // output: LogOutput.auto (default) | LogOutput.print | LogOutput.developerLog
  callback: (raw, colored, level) {
    // Save logs to file or send to a remote endpoint
  },
);
```

### Format Tokens

| Token          | Description         |
| -------------- | ------------------- |
| `@{color}`     | ANSI color escape   |
| `@{timestamp}` | Formatted timestamp |
| `@{icon}`      | Emoji per LogLevel  |
| `@{level}`     | Short log label     |
| `@{message}`   | Content of the log  |

## Log Filtering

```dart
const logger = LiteLogger(minLevel: LogLevel.warning);

logger.log('This is info', LogLevel.info);       // skipped
logger.log('This is warning', LogLevel.warning); // logged
logger.log('This is error', LogLevel.error);     // logged
```

## Callback

```dart
const logger = LiteLogger(
  callback: (raw, colored, level) {
    sendToServer({'level': level.name, 'message': raw});
  },
);
```

## Logger Naming

```dart
final apiLogger = LiteLogger(name: 'API');
final dbLogger = LiteLogger(name: 'Database');
final authLogger = LiteLogger(name: 'Auth');

apiLogger.info('Fetching user data');
dbLogger.debug('Executing query...');
authLogger.warning('Token expiring soon');
```

Output:

```txt
[API] [12:34:56] 💡 [INFO] Fetching user data
[Database] [12:34:56] 🧠 [DBUG] Executing query...
[Auth] [12:34:57] ⚠️ [WARN] Token expiring soon
```

## Output Methods

The `output` parameter (`LogOutput`) selects the output method:

* **`LogOutput.auto`** (default): `developer.log()` in debug (keeps ANSI colors), `print()` in release. Needs a debugger/DevTools attached; for plain `dart run` terminals use `LogOutput.print`.
* **`LogOutput.print`**: Always `print()`. Most compatible; on Flutter mobile ANSI colors are stripped because `logcat` escapes them.
* **`LogOutput.developerLog`**: Always `developer.log()`.

```dart
final logger1 = LiteLogger(name: 'App');
final logger2 = LiteLogger(name: 'App', output: LogOutput.print);
final logger3 = LiteLogger(name: 'App', output: LogOutput.developerLog);
```

> `usePrint` is deprecated in favor of `output` but still works: `true` maps to `LogOutput.print`, `false` to `LogOutput.developerLog`. An explicit `usePrint` takes precedence over `output`.

## License

MIT License — see [LICENSE](LICENSE).
