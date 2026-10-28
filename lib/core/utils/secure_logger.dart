import 'package:flutter/foundation.dart';

/// Production-safe logging utility.
///
/// Wraps `debugPrint` with `kDebugMode` checks so that log statements
/// are automatically silenced in release/profile builds. Also provides
/// PII sanitization for error messages.
class SecureLogger {
  SecureLogger._();

  /// Regex to detect email addresses in log output.
  static final RegExp _emailPattern = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  /// Logs a message only when running in debug mode.
  ///
  /// Use this as a drop-in replacement for `debugPrint`.
  static void log(String message) {
    if (kDebugMode) {
      debugPrint('[GymVibe] $message');
    }
  }

  /// Logs an error message with PII sanitization.
  ///
  /// Email addresses in the message are redacted to `[REDACTED_EMAIL]`.
  /// In release mode, nothing is logged.
  static void logError(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      final sanitized = _sanitize(message);
      debugPrint('[GymVibe ERROR] $sanitized');
      if (error != null) {
        debugPrint('[GymVibe ERROR] ${_sanitize(error.toString())}');
      }
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
  }

  /// Sanitizes a log message by redacting PII patterns.
  static String _sanitize(String message) {
    return message.replaceAll(_emailPattern, '[REDACTED_EMAIL]');
  }
}
