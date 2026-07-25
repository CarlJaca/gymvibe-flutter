import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import 'owner_reviews_screen.dart';
import 'owner_gym_profile_screen.dart';

class OwnerMoreScreen extends StatelessWidget {
  const OwnerMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppPadding.md),
          children: [
            const SizedBox(height: AppPadding.sm),
            // ── More header ───────────────────────────────────────
            const Text('More',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppPadding.lg),

            _buildSection('Gym Management', [
              _item(context, Icons.work_outline_rounded, 'Job Postings',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.ownerJobs)),
              _item(context, Icons.reviews_rounded, 'Reviews Management',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const OwnerReviewsScreen()))),
              _item(context, Icons.account_circle_rounded, 'Public Gym Profile',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const OwnerGymProfileScreen()))),
            ]),

            const SizedBox(height: AppPadding.lg),

            _buildSection('Account', [
              _item(context, Icons.settings_rounded, 'Business Settings',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.ownerPortal)),
              _item(context, Icons.notifications_none_rounded, 'Notifications',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.ownerNotifications)),
              _item(context, Icons.help_outline_rounded, 'Help & Support',
                  onTap: () {}),
            ]),

            const SizedBox(height: AppPadding.lg),

            _buildSection('Switch', [
              _item(
                context,
                Icons.storefront_rounded,
                'Gym Profile',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const OwnerGymProfileScreen())),
              ),
            ]),

            const SizedBox(height: AppPadding.lg),

            // Logout
            Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(Icons.logout_rounded,
                    color: AppColors.error),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  final provider = Provider.of<AuthProvider>(context, listen: false);
                  provider.signOut();
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                },
              ),
            ),
            const SizedBox(height: AppPadding.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
