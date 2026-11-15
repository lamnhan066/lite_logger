/// Terminal color as an ANSI escape code.
enum LogColor {
  /// Blue, default for info.
  blue,

  /// Yellow, default for warning.
  yellow,

  /// Red, default for error.
  red,

  /// Gray, default for debug.
  gray,

  /// Green, default for success.
  green,

  /// Cyan, default for step.
  cyan;

  /// ANSI escape code for this color.
  String get color => switch (this) {
    blue => '\x1B[34m',
    yellow => '\x1B[33m',
    red => '\x1B[31m',
    gray => '\x1B[90m',
    green => '\x1B[32m',
    cyan => '\x1B[36m',
  };
}
