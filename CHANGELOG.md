## 0.3.2

- `print()` output is now plain text: ANSI color escapes and the trailing
  reset code are stripped (they were mangled to `^[[36m` by `logcat` on
  Flutter mobile), while `developer.log()` and the `callback` still receive
  the fully colored message.
- Log lines are now built lazily — only the variant actually emitted
  (`colored` vs `plain`) is formatted.

## 0.3.1

- Add `LogOutput` enum (`auto`/`print`/`developerLog`) via the new `output`
  parameter to control the output method. `LogOutput.auto` (default) prefers
  `developer.log()` in debug builds so ANSI colors survive (fixes `^[[36m`
  output when `print()` is forwarded through `logcat` on Flutter mobile),
  while `print()` is used in release/product builds where `developer.log()`
  is not surfaced. Pass `output: LogOutput.print` explicitly for plain
  `dart run` terminals without a debugger.
- Deprecate the `usePrint` boolean in favor of `output`. This is
  non-breaking: an explicitly passed `usePrint` still works and takes
  precedence over `output`, so existing code keeps compiling and behaving as
  before. Optional migration: `usePrint: true` → `output: LogOutput.print`,
  `usePrint: false` → `output: LogOutput.developerLog`, omit both for the
  new automatic default (`LogOutput.auto`).
- Fix named loggers emitting the ANSI color escape twice
  (`<color>[Name] <color>...` → `<color>[Name] ...`).
- Remove the `'\r'` carriage-return hack for the `developer.log()` name of
  unnamed loggers (it could garble terminal lines); the name is now passed
  through as-is.

## 0.3.0

- `usePrint` is now `true` by default so log output uses `print()` unless explicitly disabled.

## 0.2.0

- `usePrint` was changed to false by default.

## 0.1.2

- Add `name` parameter to identify loggers in output.
- Improve output formatting to include logger name prefix when provided.
- Enhanced documentation with examples and usage patterns.

## 0.1.1

- Add `usePrint` to toggle print vs developer log output.

## 0.1.0

- TYPO: levelText -> levelTexts

## 0.0.1

- Initial version.
