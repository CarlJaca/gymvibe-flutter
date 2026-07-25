import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../core/utils/input_validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscureText = true;
  bool _isOwnerLogin = false; // Toggle state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = InputValidators.sanitize(_emailCtrl.text);
    final pass = _passCtrl.text.trim();

    final provider = context.read<AuthProvider>();
    final success = await provider.signIn(
        email: email, password: pass, isOwnerLogin: _isOwnerLogin);

    if (success && mounted) {
      if (_isOwnerLogin && provider.currentUser != null) {
        context.read<GymProvider>().setCurrentOwner(provider.currentUser!.id,
            gymName: provider.currentUser!.gymName);
      }
      if (provider.isSuperAdmin) {
        Navigator.pushReplacementNamed(context, AppRoutes.superAdminPortal);
      } else {
        Navigator.pushReplacementNamed(
            context, _isOwnerLogin ? AppRoutes.ownerPortal : AppRoutes.main);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    final provider = context.read<AuthProvider>();
    final success =
        await provider.signInWithGoogle(isOwnerLogin: _isOwnerLogin);

    if (success && mounted) {
      if (_isOwnerLogin && provider.currentUser != null) {
        context.read<GymProvider>().setCurrentOwner(provider.currentUser!.id,
            gymName: provider.currentUser!.gymName);
      }
      if (provider.isSuperAdmin) {
        Navigator.pushReplacementNamed(context, AppRoutes.superAdminPortal);
      } else {
        Navigator.pushReplacementNamed(
            context, _isOwnerLogin ? AppRoutes.ownerPortal : AppRoutes.main);
      }
    }
  }

  Future<void> _handleFacebookLogin() async {
    final provider = context.read<AuthProvider>();
    final success =
        await provider.signInWithFacebook(isOwnerLogin: _isOwnerLogin);

    if (success && mounted) {
      if (_isOwnerLogin && provider.currentUser != null) {
        context.read<GymProvider>().setCurrentOwner(provider.currentUser!.id,
            gymName: provider.currentUser!.gymName);
      }
      if (provider.isSuperAdmin) {
        Navigator.pushReplacementNamed(context, AppRoutes.superAdminPortal);
      } else {
        Navigator.pushReplacementNamed(
            context, _isOwnerLogin ? AppRoutes.ownerPortal : AppRoutes.main);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(text: _emailCtrl.text);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Reset Password',
              style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your email to receive a password reset link.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailCtrl.text.trim();
                if (email.isEmpty) return;

                final provider = context.read<AuthProvider>();
                final success = await provider.resetPassword(email);

                if (!context.mounted) return;
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset link sent!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(provider.errorMessage ??
                            'Failed to reset password')),
                  );
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background Image & Overlay ─────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/gym_background.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF1A1A2E)),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    AppColors.primary.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top Section (Logo)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                  child: Center(
                    child: Image.asset(
                      'assets/images/gymvibe_logo.png',
                      height: 200,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.fitness_center_rounded,
                        size: 56,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                // Login Card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Bottom Decoration
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Opacity(
                            opacity: 1.0,
                            child: Image.asset(
                              'assets/images/davao_skyline.png',
                              fit: BoxFit.fitWidth,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),

                        // Scrollable Form
                        SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Login as',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87),
                                ),
                                const SizedBox(height: 12),

                                // ── Role Selection ─────────────────────────────
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => _isOwnerLogin = false),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: !_isOwnerLogin
                                                ? AppColors.primary
                                                    .withValues(alpha: 0.1)
                                                : Colors.grey[100],
                                            border: Border.all(
                                              color: !_isOwnerLogin
                                                  ? AppColors.primary
                                                  : Colors.transparent,
                                              width: 1.5,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.person_rounded,
                                                  size: 20,
                                                  color: !_isOwnerLogin
                                                      ? AppColors.primary
                                                      : Colors.black87),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Gym User',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: !_isOwnerLogin
                                                      ? AppColors.primary
                                                      : Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => _isOwnerLogin = true),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: _isOwnerLogin
                                                ? AppColors.primary
                                                    .withValues(alpha: 0.1)
                                                : Colors.grey[100],
                                            border: Border.all(
                                              color: _isOwnerLogin
                                                  ? AppColors.primary
                                                  : Colors.transparent,
                                              width: 1.5,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.storefront_rounded,
                                                  size: 20,
                                                  color: _isOwnerLogin
                                                      ? AppColors.primary
                                                      : Colors.black87),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Gym Owner',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: _isOwnerLogin
                                                      ? AppColors.primary
                                                      : Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // ── Email ──────────────────────────────────────
                                const Text('Email',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: InputValidators.validateEmail,
                                  style: const TextStyle(color: Colors.black87),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    hintText: 'Enter your email',
                                    hintStyle:
                                        TextStyle(color: Colors.grey[400]),
                                    prefixIcon: const Icon(Icons.email_outlined,
                                        color: Colors.grey),
                                    filled: true,
                                    fillColor: Colors.white,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppColors.primary, width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppColors.error),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppColors.error, width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // ── Password ───────────────────────────────────
                                const Text('Password',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _obscureText,
                                  validator: (value) =>
                                      InputValidators.validateRequired(value,
                                          fieldName: 'Password'),
                                  style: const TextStyle(color: Colors.black87),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    hintText: 'Enter your password',
                                    hintStyle:
                                        TextStyle(color: Colors.grey[400]),
                                    prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                        color: Colors.grey),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                          _obscureText
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.grey),
                                      onPressed: () => setState(
                                          () => _obscureText = !_obscureText),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppColors.primary, width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppColors.error),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppColors.error, width: 2),
                                    ),
                                  ),
                                ),

                                // ── Forgot Password ────────────────────────────
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 0, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('Forgot Password?',
                                        style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // ── Error Message ──────────────────────────────
                                Consumer<AuthProvider>(
                                  builder: (context, auth, _) {
                                    if (auth.errorMessage != null) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: AppColors.error
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: AppColors.error,
                                                  size: 18),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  auth.errorMessage!,
                                                  style: const TextStyle(
                                                      color: AppColors.error,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),

                                // ── Login Button ───────────────────────────────
                                Consumer<AuthProvider>(
                                  builder: (context, auth, _) {
                                    final isRateLimited =
                                        auth.isLoginRateLimited;
                                    return Container(
                                      width: double.infinity,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed:
                                            (auth.isLoading || isRateLimited)
                                                ? null
                                                : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ),
                                        child: auth.isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2.5))
                                            : Text(
                                                isRateLimited
                                                    ? 'Locked (${auth.loginLockoutTime})'
                                                    : 'Log In',
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white),
                                              ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),

                                // ── Divider ────────────────────────────────────
                                Row(
                                  children: [
                                    Expanded(
                                        child:
                                            Divider(color: Colors.grey[300])),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Text('or continue with',
                                          style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12)),
                                    ),
                                    Expanded(
                                        child:
                                            Divider(color: Colors.grey[300])),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // ── Social Login ───────────────────────────────
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: context
                                                .watch<AuthProvider>()
                                                .isLoading
                                            ? null
                                            : _handleGoogleLogin,
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          side: BorderSide(
                                              color: Colors.grey[300]!),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.network(
                                                'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                                height: 18,
                                                width: 18,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(
                                                        Icons.g_mobiledata,
                                                        color: Colors.black87)),
                                            const SizedBox(width: 8),
                                            const Text('Google',
                                                style: TextStyle(
                                                    color: Colors.black87,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: context
                                                .watch<AuthProvider>()
                                                .isLoading
                                            ? null
                                            : _handleFacebookLogin,
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          side: BorderSide(
                                              color: Colors.grey[300]!),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.facebook_rounded,
                                                color: Color(0xFF1877F2),
                                                size: 20),
                                            SizedBox(width: 8),
                                            Text('Facebook',
                                                style: TextStyle(
                                                    color: Colors.black87,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // ── Sign Up ────────────────────────────────────
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Don't have an account? ",
                                        style: TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13)),
                                    GestureDetector(
                                      onTap: () =>
                                          Navigator.pushReplacementNamed(
                                              context,
                                              _isOwnerLogin
                                                  ? AppRoutes.ownerRegister
                                                  : AppRoutes.register),
                                      child: const Text('Sign Up',
                                          style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                    height: 16), // Extra padding for safety
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
