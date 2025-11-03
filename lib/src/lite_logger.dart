import 'dart:developer' as dev;

import 'package:lite_logger/src/models/log_color.dart';
import 'package:lite_logger/src/models/log_level.dart';

/// A function type used to intercept formatted and raw log messages.
///
/// Useful for writing logs to a file, sending to external systems,
/// or integrating with custom log handlers.
///
/// - [raw]     Unformatted, plain message string.
/// - [colored] The final formatted output including ANSI color codes.
/// - [level]   The log level that was emitted.
typedef LogCallback = void Function(String raw, String colored, LogLevel level);

/// Default color mapping for each log level when none is provided.
const Map<LogLevel, LogColor> _defaultColors = {
  LogLevel.info: LogColor.blue,
  LogLevel.warning: LogColor.yellow,
  LogLevel.error: LogColor.red,
  LogLevel.debug: LogColor.gray,
  LogLevel.success: LogColor.green,
  LogLevel.step: LogColor.cyan,
};

/// Default emoji/icon mapping for each log level.
///
/// Icons enhance readability and quickly convey log intent.
const Map<LogLevel, String> _defaultEmojis = {
  LogLevel.info: '💡',
  LogLevel.warning: '⚠️',
  LogLevel.error: '❌',
  LogLevel.debug: '🧠',
  LogLevel.success: '✅',
  LogLevel.step: '🔄',
};

/// Default label text (fixed-width) for each log level.
///
/// Ensures consistent alignment in formatted output.
const Map<LogLevel, String> _defaultLevelTexts = {
  LogLevel.error: 'ERRR',
  LogLevel.warning: 'WARN',
  LogLevel.success: 'SUCC',
  LogLevel.info: 'INFO',
  LogLevel.step: 'STEP',
  LogLevel.debug: 'DBUG',
};

/// Default timestamp formatter for log output.
///
/// Produces time in `[HH:MM:SS]` format using 24-hour clock.
String _defaultTimestamp(DateTime date) {
  return '[${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}:'
      '${date.second.toString().padLeft(2, '0')}]';
}

/// A lightweight, flexible logger designed for developers.
///
/// Supports:
/// - Named loggers for identifying different components in your application.
/// - Customizable colors, icons, timestamps, and formatting tokens.
/// - Lazy evaluation for log messages (functions are only executed
/// if the log is emitted).
/// - Optional callback for custom integration such as writing to file
/// or remote service.
/// - Choice between `print()` and `developer.log()` output methods.
///
/// ### Format Placeholders
/// The `format` string supports these dynamic tokens:
/// - `@{color}`   → ANSI color code
/// - `@{timestamp}` → Formatted timestamp
/// - `@{icon}`    → Emoji or icon for the level
/// - `@{level}`   → Short text label
/// - `@{message}` → The actual log message
///
/// ### Example
/// ```dart
/// final logger = LiteLogger(name: 'App', minLevel: LogLevel.warning);
/// logger.log('This is visible', LogLevel.error); // Logged
/// logger.log('This is hidden', LogLevel.info);  // Not logged
/// ```
class LiteLogger {
  /// Creates a [LiteLogger] instance.
  ///
  /// - [name]      Optional identifier for the logger. When provided, appears
  ///               in the output as `[name]:` prefix. Useful for distinguishing
  ///               multiple loggers in the same application.
  /// - [enabled]   Enables or disables output globally.
  /// - [minLevel]  Filters out messages below this log level.
  /// - [callback]  If provided, receives raw and formatted log strings instead
  ///               of writing to console.
  /// - [colors]    Mapping of log levels to ANSI color codes.
  /// - [emojis]    Mapping of log levels to icons or emojis.
  /// - [levelTexts] Text labels used for each log level.
  /// - [timestamp] Function to format timestamps.
  /// - [format]    Template for the final log output. Supports: `@{color}`,
  ///               `@{timestamp}`, `@{icon}`, `@{level}`, `@{message}`.
  /// - [usePrint]  If `true`, uses `print()` for output. If `false` (default),
  ///               uses `developer.log()` from `dart:developer` for cleaner
  ///               output with better tooling integration.
  const LiteLogger({
    String name = '',
    bool enabled = true,
    LogLevel minLevel = LogLevel.info,
    LogCallback? callback,
    Map<LogLevel, LogColor> colors = _defaultColors,
    Map<LogLevel, String> emojis = _defaultEmojis,
    Map<LogLevel, String> levelTexts = _defaultLevelTexts,
    String Function(DateTime) timestamp = _defaultTimestamp,
    String format = '@{color}@{timestamp} @{icon} [@{level}] @{message}',
    bool usePrint = false,
  }) : _name = name,
       _enabled = enabled,
       _callback = callback,
       _minLevel = minLevel,
       _colors = colors,
       _emojis = emojis,
       _levelText = levelTexts,
       _timestamp = timestamp,
       _format = format,
       _usePrint = usePrint;

  /// The name of the logger.
  ///
  /// This is used to identify the logger in the output.
  final String _name;

  /// Whether logging is globally enabled.
  ///
  /// When `false`, all calls to [log] are ignored.
  final bool _enabled;

  /// Minimum log level that will be output.
  ///
  /// Messages with lower priority are not logged.
  final LogLevel _minLevel;

  /// Optional user-defined handler for processed log output.
  final LogCallback? _callback;

  /// Mapping between log levels and terminal colors.
  final Map<LogLevel, LogColor> _colors;

  /// Mapping between log levels and icon characters.
  final Map<LogLevel, String> _emojis;

  /// Mapping between log levels and fixed-width label text.
  final Map<LogLevel, String> _levelText;

  /// A function that generates timestamp strings.
  final String Function(DateTime) _timestamp;

  /// The format template for composing each log entry.
  ///
  /// See the class documentation above for available placeholders.
  final String _format;

  /// Determines which output method is used for logging.
  ///
  /// If `false` (default), logs are written using `developer.log()` from
  /// `dart:developer`. This reduces the Flutter prefix noise and
  /// provides richer metadata(such as log level and category), though some
  /// environments may still display a lightweight "[]" prefix.
  ///
  /// If `true`, logs are written using `print()`. This is the most compatible
  /// option and produces standard console output, but in Flutter debug mode
  /// it may include prefixes like:
  ///
  ///   I/flutter (7004):
  ///
  /// ┌────────────────────┬─────────────────────────────┬─────────────────────┐
  /// │ Option             │ Output Source               │ Typical Prefix      │
  /// ├────────────────────┼─────────────────────────────┼─────────────────────┤
  /// │ false (default)    │ developer.log()             │ [] or minimal       │
  /// │ true               │ print()                     │ I/flutter (...)     │
  /// └────────────────────┴─────────────────────────────┴─────────────────────┘
  final bool _usePrint;

  /// Logs a message if logging is enabled and the severity meets the threshold.
  ///
  /// The [message] parameter may be:
  /// - A `String`, or
  /// - A function returning `String` (lazy evaluation to save computation).
  ///
  /// This allows:
  /// ```dart
  /// logger.log(() => expensiveComputation(), LogLevel.debug);
  /// ```
  void log(dynamic message, [LogLevel level = LogLevel.info]) {
    if (!_enabled) return;
    if (!_shouldLog(level)) return;

    final timestamp = _timestamp(DateTime.now());
    final color = _colors[level]?.color ?? _defaultColors[level]!.color;
    const reset = '\x1B[0m';
    final icon = _emojis[level] ?? _defaultEmojis[level];
    final levelText = _levelText[level] ?? _defaultLevelTexts[level];

    // Evaluate lazy message only when needed
    final textMessage =
        message is Function ? '${(message as Function)()}' : '$message';

    // Build formatted output
    final colored =
        _format
            .replaceAll('@{color}', color)
            .replaceAll('@{timestamp}', timestamp)
            .replaceAll('@{icon}', icon!)
            .replaceAll('@{level}', levelText!)
            .replaceAll('@{message}', textMessage) +
        reset;

    if (_callback != null) {
      _callback(textMessage, colored, level);
    } else {
      if (_usePrint) {
        // Output the log
        // ignore: avoid_print
        print(_name.isEmpty ? colored : '$color[$_name] $colored');
      } else {
        dev.log(
          colored,
          name: _name.isEmpty ? '\r' : _name,
          level: level.index,
        );
      }
    }
  }

  /// Logs a message with [LogLevel.error].
  ///
  /// Use this for critical failures or unexpected conditions that
  /// typically require immediate attention.
  ///
  /// Example:
  /// ```dart
  /// logger.error('Failed to connect to database');
  /// logger.error(() => 'Failed to connect to database');
  /// ```
  void error(dynamic message) => log(message, LogLevel.error);

  /// Logs a message with [LogLevel.warning].
  ///
  /// Use this when something is wrong or unexpected, but the system
  /// can still continue running.
  ///
  /// Example:
  /// ```dart
  /// logger.warning('API rate limit nearing threshold');
  /// logger.warning(() => 'API rate limit nearing threshold');
  /// ```
  void warning(dynamic message) => log(message, LogLevel.warning);

  /// Logs a message with [LogLevel.success].
  ///
  /// Use this for successful operations or completed tasks to
  /// communicate positive outcomes.
  ///
  /// Example:
  /// ```dart
  /// logger.success('User registration completed');
  /// logger.success(() => 'User registration completed');
  /// ```
  void success(dynamic message) => log(message, LogLevel.success);

  /// Logs a message with [LogLevel.info].
  ///
  /// Use this for general informational events that highlight the
  /// progress or state of the application.
  ///
  /// Example:
  /// ```dart
  /// logger.info('Service started on port 8080');
  /// logger.info(() => 'Service started on port 8080');
  /// ```
  void info(dynamic message) => log(message);

  /// Logs a message with [LogLevel.step].
  ///
  /// Use this for multi-step processes or workflows to indicate
  /// transition from one phase to another.
  ///
  /// Example:
  /// ```dart
  /// logger.step('Initializing cache layer...');
  /// logger.step(() => 'Initializing cache layer...');
  /// ```
  void step(dynamic message) => log(message, LogLevel.step);

  /// Logs a message with [LogLevel.debug].
  ///
  /// Use this for detailed diagnostic information helpful during
  /// development and debugging. These logs are typically hidden in
  /// production environments.
  ///
  /// Example:
  /// ```dart
  /// logger.debug('Cache size: ${cache.length}');
  /// logger.debug(() => 'Cache size: ${cache.length}');
  /// ```
  void debug(dynamic message) => log(message, LogLevel.debug);

  /// Determines whether this log level should be output when compared
  /// against `minLevel`.
  ///
  /// Returns `true` when this level's priority is **greater than or equal to**
  /// the provided `minLevel`.
  bool _shouldLog(LogLevel level) => level.index <= _minLevel.index;
}
