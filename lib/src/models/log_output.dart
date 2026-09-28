/// Selects which output method a `LiteLogger` uses to emit log messages.
enum LogOutput {
  /// Automatically selects the output method (default).
  ///
  /// Prefers `developer.log()` from `dart:developer`, which preserves ANSI
  /// colors. `print()` output from a Flutter app is forwarded through
  /// `logcat`/syslog, which escapes the ESC byte (`\x1B` → `^[`) and destroys
  /// colors. The single exception is release/product builds, where
  /// `developer.log()` output is not surfaced — there `print()` is used so
  /// logs remain visible.
  auto,

  /// Always uses `print()` for output.
  ///
  /// The most compatible option with standard console output, but in Flutter
  /// debug mode it may include prefixes like `I/flutter (7004)`, and on
  /// Flutter mobile ANSI colors are escaped by `logcat`.
  print,

  /// Always uses `developer.log()` from `dart:developer` for output.
  ///
  /// Cleaner output with less platform noise and better tooling integration,
  /// but only visible when a debugger or DevTools is attached. Plain
  /// `dart run` terminals without a debugger will show nothing.
  developerLog,
}
