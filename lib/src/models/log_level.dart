/// Represents the severity or importance of a log message.
enum LogLevel {
  /// Critical failures that require immediate attention and
  /// typically stop the process.
  error,

  /// Recoverable issues that may degrade the application or
  /// indicate potential problems.
  warning,

  /// Successful operations indicating that a task completed as expected.
  success,

  /// General informational messages about routine operations.
  info,

  /// Operational progress updates, often used in multi-step processes.
  step,

  /// Detailed diagnostic output, usually enabled only during development.
  debug,
}
