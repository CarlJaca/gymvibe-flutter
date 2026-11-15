import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );
    _progressController.forward();

    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Wait for the splash animation to show for at least 2.4 seconds
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    // Try to restore previous session (checks explicit logout flag internally)
    final sessionRestored = await authProvider.tryRestoreSession();

    if (!mounted) return;

    if (sessionRestored && authProvider.currentUser != null) {
      final user = authProvider.currentUser!;

      // Set owner context if needed
      if (user.isOwner) {
        context
            .read<GymProvider>()
            .setCurrentOwner(user.id, gymName: user.gymName);
      }

      // Route based on role
      String nextRoute;
      if (user.isSuperAdmin) {
        nextRoute = AppRoutes.superAdminPortal;
      } else if (user.isOwner) {
        nextRoute = AppRoutes.ownerPortal;
      } else {
        nextRoute = AppRoutes.main;
      }

      Navigator.pushReplacementNamed(context, nextRoute);
    } else {
      // No valid session or user explicitly logged out — show onboarding/login
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // ── Logo & Brand ────────────────────────────────────────
            Center(
              child: Image.asset(
                'assets/images/gymvibe_logo.png',
                height: 220,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.fitness_center_rounded,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
            ),

            const Spacer(),

            // ── Animated Progress Bar ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.xl, vertical: AppPadding.xl),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: LinearProgressIndicator(
                          value: _progressAnimation.value,
                          minHeight: 3,
                          backgroundColor: AppColors.surface,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
