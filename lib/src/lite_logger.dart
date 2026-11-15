import 'dart:developer' as dev;

import 'package:lite_logger/src/models/log_color.dart';
import 'package:lite_logger/src/models/log_level.dart';
import 'package:lite_logger/src/models/log_output.dart';

/// Receives the raw message, the formatted message, and the log level.
typedef LogCallback = void Function(String raw, String colored, LogLevel level);

const Map<LogLevel, LogColor> _defaultColors = {
  LogLevel.info: LogColor.blue,
  LogLevel.warning: LogColor.yellow,
  LogLevel.error: LogColor.red,
  LogLevel.debug: LogColor.gray,
  LogLevel.success: LogColor.green,
  LogLevel.step: LogColor.cyan,
};

const Map<LogLevel, String> _defaultEmojis = {
  LogLevel.info: '💡',
  LogLevel.warning: '⚠️',
  LogLevel.error: '❌',
  LogLevel.debug: '🧠',
  LogLevel.success: '✅',
  LogLevel.step: '🔄',
};

const Map<LogLevel, String> _defaultLevelTexts = {
  LogLevel.error: 'ERRR',
  LogLevel.warning: 'WARN',
  LogLevel.success: 'SUCC',
  LogLevel.info: 'INFO',
  LogLevel.step: 'STEP',
  LogLevel.debug: 'DBUG',
};

String _defaultTimestamp(DateTime date) {
  return '[${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}:'
      '${date.second.toString().padLeft(2, '0')}]';
}

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

/// Lightweight logger with colored output, filtering, and custom formatting.
///
/// Format tokens: `@{color}`, `@{timestamp}`, `@{icon}`, `@{level}`,
/// `@{message}`.
///
/// ```dart
/// final logger = LiteLogger(name: 'App', minLevel: LogLevel.warning);
/// logger.error('Visible');
/// logger.info('Hidden');
/// ```
class LiteLogger {
  /// Creates a logger.
  ///
  /// - [name] prefixes output as `[name]`.
  /// - [enabled] skips all output when false.
  /// - [minLevel] logs levels with `level.index <= minLevel.index`.
  /// - [callback] receives `(raw, colored, level)` instead of printing.
  ///   `colored` includes the `[name]` prefix when set; `raw` does not.
  /// - [colors], [emojis], [levelTexts], [timestamp], [format] customize
  ///   output.
  /// - [output] selects `print` vs `developer.log`; deprecated [usePrint]
  ///   overrides it when passed.
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

  final String _name;
  final bool _enabled;
  final LogLevel _minLevel;
  final LogCallback? _callback;
  final Map<LogLevel, LogColor> _colors;
  final Map<LogLevel, String> _emojis;
  final Map<LogLevel, String> _levelText;
  final String Function(DateTime) _timestamp;
  final String _format;
  final LogOutput _output;
  final bool? _usePrint;

  // Auto prefers `developer.log()` to keep ANSI colors, except in
  // release builds where it falls back to `print()`.
  // An explicit `usePrint` overrides `output` for backwards compatibility.
  bool get _effectiveUsePrint {
    if (_usePrint != null) return _usePrint;
    switch (_output) {
      case LogOutput.print:
        return true;
      case LogOutput.developerLog:
        return false;
      case LogOutput.auto:
        const isProduct = bool.fromEnvironment('dart.vm.product');
        return isProduct;
    }
  }

  /// Logs [message] at [level] if enabled and above minLevel.
  ///
  /// [message] can be a value or a zero-arg function for lazy evaluation:
  /// ```dart
  /// logger.log(() => expensiveComputation(), LogLevel.debug);
  /// ```
  void log(Object? message, [LogLevel level = LogLevel.info]) {
    if (!_enabled) return;
    if (!_shouldLog(level)) return;

    final timestamp = _timestamp(DateTime.now());
    final color = _colors[level]?.color ?? _defaultColors[level]!.color;
    const reset = '\x1B[0m';
    final icon = (_emojis[level] ?? _defaultEmojis[level])!;
    final levelText = (_levelText[level] ?? _defaultLevelTexts[level])!;
    final textMessage =
        message is Object? Function() ? '${message()}' : '$message';

    // Only the emitted variant is built: colored for developer.log/callback,
    // plain (no ANSI codes) for print().
    String colored() => _buildMessage(
      format: _format,
      color: color,
      reset: reset,
      timestamp: timestamp,
      icon: icon,
      levelText: levelText,
      textMessage: textMessage,
    );
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
      final coloredMessage = colored();
      _callback(
        textMessage,
        _name.isEmpty ? coloredMessage : '[$_name] $coloredMessage',
        level,
      );
    } else {
      if (_effectiveUsePrint) {
        final plained = plain();
        final output = _name.isEmpty ? plained : '[$_name] $plained';
        // Output method by design.
        // ignore: avoid_print
        print(output);
      } else {
        dev.log(colored(), name: _name, level: level.index);
      }
    }
  }

  /// Logs at [LogLevel.error].
  void error(Object? message) => log(message, LogLevel.error);

  /// Logs at [LogLevel.warning].
  void warning(Object? message) => log(message, LogLevel.warning);

  /// Logs at [LogLevel.success].
  void success(Object? message) => log(message, LogLevel.success);

  /// Logs at [LogLevel.info].
  void info(Object? message) => log(message);

  /// Logs at [LogLevel.step].
  void step(Object? message) => log(message, LogLevel.step);

  /// Logs at [LogLevel.debug].
  void debug(Object? message) => log(message, LogLevel.debug);

  bool _shouldLog(LogLevel level) => level.index <= _minLevel.index;
}
