/// Output method used by the logger.
enum LogOutput {
  /// `developer.log()` in debug, `print()` in release.
  auto,

  /// Always `print()`.
  print,

  /// Always `developer.log()`.
  developerLog,
}
