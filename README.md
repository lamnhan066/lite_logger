# LiteLogger

A fast, lightweight, and customizable logging utility for Dart & Flutter — with colored output, emoji icons, log filtering, and powerful formatting.

---

## Features

* **Log Level Filtering**: Control output visibility (`error`, `warning`, `success`, `info`, `step`, `debug`)
* **Colorized Output**: ANSI terminal colors for instant visual clarity
* **Emoji Indicators**: Makes reading console logs effortless
* **Lazy Message Evaluation**: Prevents unnecessary computation
* **Custom Formatting**: Fully configurable message templates
* **Callback Support**: Redirect logs to file, cloud, or analytics
* **Global Enable/Disable Switch**

---

## Getting Started

```dart
final logger = LiteLogger(
    enabled: true,
    minLevel: LogLevel.debug, // show all levels
);

logger.info('Application started');
logger.step('Loading configuration...');
logger.debug(() => 'Debug timestamp: ${DateTime.now().millisecondsSinceEpoch}');
logger.success('Configuration loaded');
logger.warning('Low disk space');
logger.error('Unable to access database');
```

---

## Advanced Configuration

```dart
final logger = LiteLogger(
  enabled: true,
  minLevel: LogLevel.debug,
  timestamp: (dt) => '[${dt.toIso8601String()}]',
  format: '@{color}@{timestamp} @{icon} [@{level}] @{message}',
  callback: (raw, colored, level) {
    // Save logs to file or send to a remote endpoint
  },
);
```

### Supported Format Tokens

| Token          | Description         |
| -------------- | ------------------- |
| `@{color}`     | ANSI color escape   |
| `@{timestamp}` | Formatted timestamp |
| `@{icon}`      | Emoji per LogLevel  |
| `@{level}`     | Short log label     |
| `@{message}`   | Content of the log  |

---

## Log Filtering Example

```dart
const logger = LiteLogger(minLevel: LogLevel.warning);

logger.log('This is info', LogLevel.info);     // ❌ Not logged
logger.log('This is warning', LogLevel.warning); // ✅ Logged
logger.log('This is error', LogLevel.error);     // ✅ Logged
```

---

## Using Callback for Custom Output

```dart
const logger = LiteLogger(
  callback: (raw, colored, level) {
    sendToServer({'level': level.text, 'message': raw});
  },
);
```

---

## License

Licensed under the **MIT License** — free for personal and commercial use.

---

## Contributing

Contributions, bug reports, and ideas are always welcome!
