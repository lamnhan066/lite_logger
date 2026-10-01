import 'dart:developer' as dev;

import 'package:lite_logger/src/models/log_color.dart';
import 'package:lite_logger/src/models/log_level.dart';
import 'package:lite_logger/src/models/log_output.dart';

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

/// Builds a log line from `format` by substituting all placeholders.
///
/// When [color] is empty, the `@{color}` token is removed and no ANSI codes
/// are emitted — used for `print()` output where color escapes would be
/// mangled (e.g. Flutter `logcat` shows `^[[36m`). When [color] is non-empty
/// a trailing [reset] code is appended to avoid leaking color to later output.
String _buildMessage({
  required String format,
  required String color,
  required String reset,
  required String timestamp,
  required String icon,
  required String levelText,
  required String textMessage,
}) {
  final body = format
      .replaceAll('@{color}', color)
      .replaceAll('@{timestamp}', timestamp)
      .replaceAll('@{icon}', icon)
      .replaceAll('@{level}', levelText)
      .replaceAll('@{message}', textMessage);
  return color.isEmpty ? body : '$body$reset';
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
  /// - [output]    Selects the output method via [LogOutput]. Defaults to
  ///               [LogOutput.auto], which prefers `developer.log()` (preserves
  ///               ANSI colors, avoids the `flutter:`/`logcat` escaping that
  ///               turns `\x1B[36m` into `^[[36m`), except in release/product
  ///               builds where `developer.log()` output is not surfaced —
  ///               then `print()` is used.
  /// - [usePrint]  Deprecated: use [output] instead. `true` maps to
  ///               [LogOutput.print], `false` to [LogOutput.developerLog].
  ///               When explicitly passed, it takes precedence over [output]
  ///               so existing code keeps working unchanged.
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
    LogOutput output = LogOutput.auto,
    @Deprecated(
      'Use output instead. '
      'true maps to LogOutput.print, false to LogOutput.developerLog.',
    )
    bool? usePrint,
  }) : _name = name,
       _enabled = enabled,
       _callback = callback,
       _minLevel = minLevel,
       _colors = colors,
       _emojis = emojis,
       _levelText = levelTexts,
       _timestamp = timestamp,
       _format = format,
       _output = output,
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
  /// Controlled by the `output` constructor parameter:
  /// - [LogOutput.print] → always `print()`.
  /// - [LogOutput.developerLog] → always `developer.log()`.
  /// - [LogOutput.auto] (default) → automatic (see [_effectiveUsePrint]).
  ///
  /// The deprecated `usePrint` constructor parameter is still honored when
  /// explicitly passed (`true` → `print()`, `false` → `developer.log()`) and
  /// takes precedence over `output`, so existing code keeps compiling and
  /// behaving exactly as before.
  ///
  /// If `developer.log()` is the resolved method, logs are written using
  /// `developer.log()` from `dart:developer`. This reduces the Flutter prefix
  /// noise and provides richer metadata (such as log level and category),
  /// though some environments may still display a lightweight "[]" prefix.
  ///
  /// If `print()` is the resolved method, logs are written using `print()`.
  /// This is the most compatible option and produces standard console output,
  /// but in Flutter debug mode it may include prefixes like:
  ///
  ///   I/flutter (7004):
  ///
  /// ┌────────────────────┬─────────────────────────────┬─────────────────────┐
  /// │ Option             │ Output Source               │ Typical Prefix      │
  /// ├────────────────────┼─────────────────────────────┼─────────────────────┤
  /// │ developerLog       │ developer.log()             │ [] or minimal       │
  /// │ print              │ print()                     │ I/flutter (...)     │
  /// │ auto (default)     │ automatic                   │ depends on build    │
  /// └────────────────────┴─────────────────────────────┴─────────────────────┘
  final LogOutput _output;

  /// Deprecated: use [_output] instead.
  ///
  /// Kept so existing code keeps compiling and behaving as before. When
  /// explicitly passed (non-null), takes precedence over [_output] in
  /// [_effectiveUsePrint].
  final bool? _usePrint;

  /// Resolves the effective output method.
  ///
  /// An explicitly passed (deprecated) `usePrint` value is always respected
  /// first. Otherwise explicit [LogOutput.print] / [LogOutput.developerLog]
  /// are used as-is, while [LogOutput.auto] prefers `developer.log()`
  /// because `print()` output from a Flutter app is forwarded through `logcat`/syslog, which
  /// escapes the ESC byte (`\x1B` → `^[`) and destroys ANSI colors. The
  /// single exception is release/product builds (`dart.vm.product`), where
  /// `developer.log()` output is not surfaced anywhere — there `print()` is
  /// used so logs remain visible.
  ///
  /// NOTE for pure Dart CLI usage: `developer.log()` is only visible when a
  /// VM-service client (IDE debugger, DevTools) is attached. Running
  /// `dart run` from a plain terminal with the default (auto) logger will
  /// therefore show nothing — pass `output: LogOutput.print` explicitly in
  /// that case.
  bool get _effectiveUsePrint {
    if (_usePrint != null) return _usePrint;
    switch (_output) {
      case LogOutput.print:
        return true;
      case LogOutput.developerLog:
        return false;
      case LogOutput.auto:
        // `bool.fromEnvironment` is compile-time constant friendly, works on
        // all platforms (including web), and needs no Flutter or dart:io
        // dependency.
        const isProduct = bool.fromEnvironment('dart.vm.product');
        return isProduct;
    }
  }

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
    final icon = (_emojis[level] ?? _defaultEmojis[level])!;
    final levelText = (_levelText[level] ?? _defaultLevelTexts[level])!;

    // Evaluate lazy message only when needed
    final textMessage =
        message is Function ? '${(message as Function)()}' : '$message';

    // Lazily build formatted output. `colored()` keeps ANSI codes for
    // `developer.log()` and the callback. `plain()` strips them for `print()`,
    // where color escapes are mangled (e.g. Flutter `logcat` renders
    // `\x1B[36m` as `^[[36m`). Only the variant actually emitted is built.
    String colored() => _buildMessage(
      format: _format,
      color: color,
      reset: reset,
      timestamp: timestamp,
      icon: icon,
      levelText: levelText,
      textMessage: textMessage,
    );
    // Lazily build the plain variant only when it will actually be printed.
    String plain() => _buildMessage(
      format: _format,
      color: '',
      reset: '',
      timestamp: timestamp,
      icon: icon,
      levelText: levelText,
      textMessage: textMessage,
    );

    if (_callback != null) {
      _callback(textMessage, colored(), level);
    } else {
      if (_effectiveUsePrint) {
        // Plain output: no ANSI codes, plain `[name]` prefix.
        final plained = plain();
        final output = _name.isEmpty ? plained : '[$_name] $plained';
        // `print` is one of this logger's two intentional output methods.
        // ignore: avoid_print
        print(output);
      } else {
        dev.log(colored(), name: _name, level: level.index);
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
