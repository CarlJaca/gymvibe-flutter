import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../core/utils/rate_limiter.dart';
import '../core/utils/secure_logger.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  final RateLimiter _rateLimiter = RateLimiter.instance;
  final SessionManager _sessionManager = SessionManager.instance;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  /// Callback to be set by the app for handling session expiry navigation.
  void Function()? onSessionExpiredNavigation;

  // ─── Rate Limiter Keys ────────────────────────────────────────────────────
  static const String _loginKey = 'login';
  static const String _ownerLoginKey = 'owner_login';

  // ─── Getters ────────────────────────────────────────────────────────────────
  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isSuperAdmin => _currentUser?.isSuperAdmin ?? false;
  String? get errorMessage => _errorMessage;

  String get userName => _currentUser?.name ?? 'Guest';
  String get userEmail => _currentUser?.email ?? '';
  String get userAvatar => _currentUser?.avatarUrl ?? 'https://i.pravatar.cc/150?img=15';
  String get userLocation => _currentUser?.location ?? 'Davao City';
  String get membershipType => _currentUser?.membershipType ?? 'Free';

  /// Returns true if the login action is currently rate-limited.
  bool get isLoginRateLimited => !_rateLimiter.canAttempt(_loginKey);

  /// Returns true if the owner login action is currently rate-limited.
  bool get isOwnerLoginRateLimited => !_rateLimiter.canAttempt(_ownerLoginKey);

  /// Returns a human-readable lockout time for the login action.
  String get loginLockoutTime => _rateLimiter.formatRemainingTime(_loginKey);

  /// Returns a human-readable lockout time for the owner login action.
  String get ownerLoginLockoutTime => _rateLimiter.formatRemainingTime(_ownerLoginKey);

  // ─── Sign In ─────────────────────────────────────────────────────────────────
  Future<bool> signIn({
    required String email,
    required String password,
    bool isOwnerLogin = false,
  }) async {
    final actionKey = isOwnerLogin ? _ownerLoginKey : _loginKey;

    // Rate limiting check
    if (!_rateLimiter.canAttempt(actionKey)) {
      _status = AuthStatus.error;
      final remaining = _rateLimiter.formatRemainingTime(actionKey);
      _errorMessage = 'Too many login attempts. Try again in $remaining.';
      notifyListeners();
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.signIn(
        email: email, 
        password: password, 
        isOwnerLogin: isOwnerLogin,
      );
      
      if (result is UserModel) {
        _currentUser = result;
        _status = AuthStatus.authenticated;
        _rateLimiter.recordSuccess(actionKey);
        _startSessionMonitoring();
        notifyListeners();
        return true;
      } else if (result is String) {
        _status = AuthStatus.error;
        _errorMessage = result;
        _rateLimiter.recordFailure(actionKey);

        // Show remaining attempts warning
        final remaining = _rateLimiter.remainingAttempts(actionKey);
        if (remaining > 0 && remaining <= 3) {
          _errorMessage = '$result ($remaining attempts remaining)';
        }

        notifyListeners();
        return false;
      }
      
      _status = AuthStatus.error;
      _errorMessage = 'An unknown error occurred.';
      _rateLimiter.recordFailure(actionKey);
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _rateLimiter.recordFailure(actionKey);
      notifyListeners();
      return false;
    }
  }

  // ─── Google Sign In ──────────────────────────────────────────────────────────
  Future<bool> signInWithGoogle({bool isOwnerLogin = false}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signInWithGoogle(isOwnerLogin: isOwnerLogin);
      _status = AuthStatus.authenticated;
      _startSessionMonitoring();
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ─── Facebook Sign In ────────────────────────────────────────────────────────
  Future<bool> signInWithFacebook({bool isOwnerLogin = false}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signInWithFacebook(isOwnerLogin: isOwnerLogin);
      _status = AuthStatus.authenticated;
      _startSessionMonitoring();
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ─── Register ────────────────────────────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    bool isOwner = false,
    String? gymName,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser =
          await _authService.register(
            name: name, 
            email: email, 
            password: password,
            isOwner: isOwner,
            gymName: gymName,
          );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ─── Sign Out ────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    _sessionManager.stopSession();
    await _authService.signOut();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Reset Password ──────────────────────────────────────────────────────────
  Future<bool> resetPassword(String email) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _status = AuthStatus.initial;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ─── Update Profile ──────────────────────────────────────────────────────────
  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return false;
    try {
      await _authService.updateUserProfile(_currentUser!.id, data);
      _currentUser = _authService.currentUser; // Get updated model
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Delete Account ──────────────────────────────────────────────────────────
  Future<void> deleteAccount() async {
    try {
      await _authService.deleteAccount();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ─── Session Management ───────────────────────────────────────────────────

  /// Starts session monitoring with inactivity timeout and auth state listening.
  void _startSessionMonitoring() {
    _sessionManager.startSession(
      onExpired: _handleSessionExpired,
    );
  }

  /// Resets the inactivity timer — called from UI on user interaction.
  void resetInactivityTimer() {
    _sessionManager.resetInactivityTimer();
  }

  /// Handles session expiry by clearing state and notifying the app.
  void _handleSessionExpired() {
    SecureLogger.log('Session expired — signing out');
    _authService.signOut();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = 'Session expired. Please sign in again.';
    notifyListeners();

    // Trigger navigation callback if set
    onSessionExpiredNavigation?.call();
  }
}
