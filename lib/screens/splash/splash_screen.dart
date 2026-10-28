import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../services/auth_service.dart';
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

    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) {
        final isLoggedIn = AuthService.instance.isLoggedIn;
        final isOwner = AuthService.instance.currentUser?.isOwner ?? false;

        String nextRoute = AppRoutes.onboarding;
        if (isLoggedIn) {
          final user = AuthService.instance.currentUser;
          if (user != null && user.isSuperAdmin) {
            nextRoute = AppRoutes.superAdminPortal;
          } else if (isOwner) {
            if (user != null) {
              context
                  .read<GymProvider>()
                  .setCurrentOwner(user.id, gymName: user.gymName);
            }
            nextRoute = AppRoutes.ownerPortal;
          } else {
            nextRoute = AppRoutes.main;
          }
        }

        Navigator.pushReplacementNamed(
          context,
          nextRoute,
        );
      }
    });
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
