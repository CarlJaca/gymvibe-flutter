import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import 'owner_gym_profile_screen.dart';

class OwnerSettingsScreen extends StatelessWidget {
  const OwnerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final gymName = auth.currentUser?.gymName ?? 'Iron Core Gym';
            final email = auth.userEmail.isEmpty ? 'ironcoreg@email.com' : auth.userEmail;
            
            return ListView(
              padding: const EdgeInsets.all(AppPadding.md),
              children: [
            const SizedBox(height: AppPadding.sm),
            const Text('Business Settings',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppPadding.lg),

            // ── Business Information ──────────────────────────────
            _sectionHeader('Business Information'),
            const SizedBox(height: 8),
            Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _infoTileRow(Icons.storefront_rounded, gymName, isEdit: true, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerGymProfileScreen()));
                  }),
                  const Divider(color: AppColors.divider, height: 1, indent: 52),
                  _infoTileRow(Icons.email_outlined, email),
                  const Divider(color: AppColors.divider, height: 1, indent: 52),
                  _infoTileRow(Icons.phone_outlined, '+63 912 345 6789'),
                  const Divider(color: AppColors.divider, height: 1, indent: 52),
                  _infoTileRow(Icons.location_on_outlined, 'Davao City, Philippines'),
                ],
              ),
            ),
            const SizedBox(height: AppPadding.lg),

            // ── Account ───────────────────────────────────────────
            _sectionHeader('Account'),
            const SizedBox(height: 8),
            Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _navTile(context, Icons.lock_outline_rounded,
                      'Change Password'),
                  const Divider(
                      color: AppColors.divider, height: 1, indent: 52),
                  _navTile(context, Icons.notifications_none_rounded,
                      'Notification Settings', onTap: () => Navigator.pushNamed(context, AppRoutes.ownerNotifications)),
                  const Divider(
                      color: AppColors.divider, height: 1, indent: 52),
                  _navTile(context, Icons.work_outline_rounded,
                      'Job Postings', onTap: () => Navigator.pushNamed(context, AppRoutes.ownerJobs)),
                  const Divider(
                      color: AppColors.divider, height: 1, indent: 52),
                  _navTile(context, Icons.storefront_rounded,
                      'Gym Profile', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerGymProfileScreen()));
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppPadding.lg),

            // ── Support ───────────────────────────────────────────
            _sectionHeader('Support'),
            const SizedBox(height: 8),
            Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _navTile(context, Icons.help_outline_rounded, 'Help Center'),
                  const Divider(
                      color: AppColors.divider, height: 1, indent: 52),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded,
                        color: Colors.deepOrangeAccent, size: 22),
                    title: const Text(
                      'Log Out',
                      style: TextStyle(
                          color: Colors.deepOrangeAccent,
                          fontWeight: FontWeight.w500,
                          fontSize: 14),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary),
                    onTap: () {
                      final provider = Provider.of<AuthProvider>(context, listen: false);
                      provider.signOut();
                      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppPadding.xl),
          ],
        );
      }),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary));
  }

  Widget _infoTileRow(IconData icon, String value, {bool isEdit = false, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(value,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      trailing: Icon(
        isEdit ? Icons.edit_outlined : Icons.chevron_right_rounded,
        size: isEdit ? 18 : 24,
        color: AppColors.textSecondary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
      onTap: onTap ?? () {},
    );
  }

  Widget _navTile(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
      onTap: onTap ?? () {},
    );
  }


}
