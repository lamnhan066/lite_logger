/// Severity of a log message, ordered by priority.
///
/// Used with `minLevel` to filter: a message logs when
/// `level.index <= minLevel.index`.
enum LogLevel {
  /// Critical failures.
  error,

  /// Recoverable issues.
  warning,

  /// Successful operations.
  success,

  /// General information.
  info,

  /// Progress in multi-step flows.
  step,

  /// Diagnostic details for development.
  debug,
}
