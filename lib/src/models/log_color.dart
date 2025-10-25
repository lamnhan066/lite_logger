/// Defines terminal colors using ANSI escape codes for styling log output.
///
/// Colors are typically used to visually distinguish log levels.
enum LogColor {
  /// Blue text — commonly used for informational messages.
  blue,

  /// Yellow text — commonly used for warnings.
  yellow,

  /// Red text — commonly used for errors.
  red,

  /// Gray text — commonly used for debug-level output.
  gray,

  /// Green text — commonly used for success messages.
  green,

  /// Cyan text — commonly used for progress or step messages.
  cyan;

  /// ANSI escape code representing the terminal color for this value.
  String get color => switch (this) {
    blue => '\x1B[34m',
    yellow => '\x1B[33m',
    red => '\x1B[31m',
    gray => '\x1B[90m',
    green => '\x1B[32m',
    cyan => '\x1B[36m',
  };
}
