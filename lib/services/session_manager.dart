import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/utils/secure_logger.dart';

/// Manages user session lifecycle including auth state monitoring
/// and inactivity-based automatic sign-out.
class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  /// Default inactivity timeout: 30 minutes.
  static const Duration defaultInactivityTimeout = Duration(minutes: 30);

  Timer? _inactivityTimer;
  StreamSubscription<User?>? _authStateSubscription;

  /// Callback invoked when the session expires (either by inactivity
  /// or external auth state change like account deletion/disabling).
  void Function()? onSessionExpired;

  /// The currently configured inactivity timeout.
  Duration _inactivityTimeout = defaultInactivityTimeout;

  /// Whether session monitoring is currently active.
  bool _isActive = false;
  bool get isActive => _isActive;

  /// Starts session monitoring.
  ///
  /// - Listens to [FirebaseAuth.authStateChanges] for external invalidation.
  /// - Starts an inactivity timer that triggers [onSessionExpired] if the
  ///   user doesn't interact within [timeout].
  void startSession({
    required void Function() onExpired,
    Duration? timeout,
  }) {
    // Prevent duplicate listeners
    stopSession();

    onSessionExpired = onExpired;
    _inactivityTimeout = timeout ?? defaultInactivityTimeout;
    _isActive = true;

    // Listen for external auth state changes (e.g., account disabled, token revoked)
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        if (user == null && _isActive) {
          SecureLogger.log('Auth state changed: user signed out externally');
          _handleSessionExpired();
        }
      },
      onError: (error) {
        SecureLogger.logError('Auth state stream error', error);
      },
    );

    // Start inactivity timer
    _startInactivityTimer();

    SecureLogger.log('Session monitoring started (timeout: ${_inactivityTimeout.inMinutes}min)');
  }

  /// Resets the inactivity timer.
  ///
  /// Call this whenever the user interacts with the app (tap, scroll, etc.)
  /// to prevent the automatic sign-out from triggering.
  void resetInactivityTimer() {
    if (!_isActive) return;
    _inactivityTimer?.cancel();
    _startInactivityTimer();
  }

  /// Stops all session monitoring and cancels timers.
  void stopSession() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;

    _authStateSubscription?.cancel();
    _authStateSubscription = null;

    _isActive = false;
    onSessionExpired = null;

    SecureLogger.log('Session monitoring stopped');
  }

  /// Starts (or restarts) the inactivity timer.
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityTimeout, () {
      SecureLogger.log('Inactivity timeout reached');
      _handleSessionExpired();
    });
  }

  /// Called when the session should be considered expired.
  void _handleSessionExpired() {
    final callback = onSessionExpired;
    stopSession();
    callback?.call();
  }
}
