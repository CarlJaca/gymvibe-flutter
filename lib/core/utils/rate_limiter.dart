/// Client-side rate limiter for brute-force protection.
///
/// Tracks failed attempts per action key and enforces configurable
/// lockout periods with exponential backoff.
class RateLimiter {
  RateLimiter._();
  static final RateLimiter instance = RateLimiter._();

  /// Maximum allowed failed attempts before lockout.
  static const int maxAttempts = 5;

  /// Base lockout duration in seconds (doubles each cycle).
  static const int baseLockoutSeconds = 300; // 5 minutes

  /// Tracks failed attempt counts per action key.
  final Map<String, int> _failedAttempts = {};

  /// Tracks the timestamp when lockout started per action key.
  final Map<String, DateTime> _lockoutStartTimes = {};

  /// Tracks consecutive lockout cycles for exponential backoff.
  final Map<String, int> _lockoutCycles = {};

  /// Returns `true` if the given [actionKey] is currently allowed to attempt.
  bool canAttempt(String actionKey) {
    final lockoutStart = _lockoutStartTimes[actionKey];
    if (lockoutStart == null) return true;

    final lockoutDuration = _getLockoutDuration(actionKey);
    final elapsed = DateTime.now().difference(lockoutStart);

    if (elapsed >= lockoutDuration) {
      // Lockout has expired — reset attempts but keep the cycle count
      _failedAttempts.remove(actionKey);
      _lockoutStartTimes.remove(actionKey);
      return true;
    }

    return false;
  }

  /// Records a failed attempt for the given [actionKey].
  ///
  /// If the number of failed attempts reaches [maxAttempts], a lockout is
  /// triggered. Returns `true` if a lockout was triggered by this call.
  bool recordFailure(String actionKey) {
    final count = (_failedAttempts[actionKey] ?? 0) + 1;
    _failedAttempts[actionKey] = count;

    if (count >= maxAttempts) {
      _lockoutStartTimes[actionKey] = DateTime.now();
      _lockoutCycles[actionKey] = (_lockoutCycles[actionKey] ?? 0) + 1;
      return true; // Lockout triggered
    }
    return false;
  }

  /// Records a successful attempt, resetting all tracking for [actionKey].
  void recordSuccess(String actionKey) {
    _failedAttempts.remove(actionKey);
    _lockoutStartTimes.remove(actionKey);
    _lockoutCycles.remove(actionKey);
  }

  /// Returns the number of remaining seconds in the current lockout period.
  /// Returns `0` if there is no active lockout.
  int remainingLockoutSeconds(String actionKey) {
    final lockoutStart = _lockoutStartTimes[actionKey];
    if (lockoutStart == null) return 0;

    final lockoutDuration = _getLockoutDuration(actionKey);
    final elapsed = DateTime.now().difference(lockoutStart);
    final remaining = lockoutDuration - elapsed;

    if (remaining.isNegative) return 0;
    return remaining.inSeconds;
  }

  /// Returns the number of failed attempts so far for [actionKey].
  int failedAttemptCount(String actionKey) {
    return _failedAttempts[actionKey] ?? 0;
  }

  /// Returns the number of remaining attempts before lockout.
  int remainingAttempts(String actionKey) {
    final used = _failedAttempts[actionKey] ?? 0;
    return (maxAttempts - used).clamp(0, maxAttempts);
  }

  /// Computes the lockout duration with exponential backoff.
  Duration _getLockoutDuration(String actionKey) {
    final cycle = _lockoutCycles[actionKey] ?? 1;
    // Exponential backoff: 5min, 10min, 20min, capped at 60min
    final seconds = baseLockoutSeconds * (1 << (cycle - 1));
    return Duration(seconds: seconds.clamp(baseLockoutSeconds, 3600));
  }

  /// Formats the remaining lockout time as a human-readable string.
  String formatRemainingTime(String actionKey) {
    final seconds = remainingLockoutSeconds(actionKey);
    if (seconds <= 0) return '';

    final minutes = seconds ~/ 60;
    final remainingSecs = seconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${remainingSecs}s';
    }
    return '${seconds}s';
  }
}
