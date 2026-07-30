import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';

import 'dart:io';
import '../../providers/events_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/routes/app_router.dart';
import '../../services/storage_service.dart';
import 'package:file_picker/file_picker.dart';
import '../promotions/rewards_loyalty_screen.dart';
import 'personal_information_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploadingAvatar = false;

  Future<void> _uploadAvatar() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isUploadingAvatar = true);
        
        final file = File(result.files.single.path!);
        if (!mounted) return;
        final auth = context.read<AuthProvider>();
        
        if (auth.currentUser == null) return;
        
        final newUrl = await storageService.uploadUserAvatar(auth.currentUser!.id, file);
        
        await auth.updateUserProfile({'avatarUrl': newUrl});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated!'), backgroundColor: AppColors.success),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }



  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            return ListView(
              padding: const EdgeInsets.all(AppPadding.md),
              children: [
                const SizedBox(height: 16),

                // ── Profile Header ──────────────────────────────────────
                Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: AppSizes.avatarXL / 2,
                          backgroundColor: AppColors.surfaceElevated,
                          backgroundImage: NetworkImage(auth.userAvatar),
                        ),
                        if (_isUploadingAvatar)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isUploadingAvatar ? null : _uploadAvatar,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.background, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      auth.userName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Fitness Enthusiast',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Edit Profile button
                    OutlinedButton(
                      onPressed: () => _showComingSoon('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: const Text('Edit Profile'),
                    ),
                  ],
                ),
                const SizedBox(height: AppPadding.xl),

                // ── Customer Dashboard ───────────────────────────────────
                _buildSectionTitle('My Dashboard'),
                const SizedBox(height: AppPadding.sm),
                Consumer2<EventsProvider, NotificationProvider>(
                  builder: (context, eventsProv, notifProv, _) {
                    final eventsJoined = eventsProv.myRegisteredEvents.length;
                    final notificationsCount = notifProv.customerNotifications.length;
                    const activeMemberships = 0; // Replace with actual logic when available
                    const bookings = 0;          // Replace with actual logic when available

                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.5,
                      children: [
                        _buildDashboardMetric('Memberships', activeMemberships.toString(), Icons.card_membership_rounded),
                        _buildDashboardMetric('Bookings', bookings.toString(), Icons.book_online_rounded),
                        _buildDashboardMetric('Events Joined', eventsJoined.toString(), Icons.event_available_rounded),
                        _buildDashboardMetric('Notifications', notificationsCount.toString(), Icons.notifications_active_rounded),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppPadding.xl),



                // ── My Activity ─────────────────────────────────────────
                _buildSectionTitle('My Activity'),
                const SizedBox(height: AppPadding.sm),
                _buildMenuItem(
                    Icons.calendar_today_rounded, 'My Bookings',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.myBookings)),
                _buildMenuItem(
                    Icons.star_outline_rounded, 'Reviews', 
                    onTap: () => Navigator.pushNamed(context, AppRoutes.myReviews)),
                _buildMenuItem(
                    Icons.favorite_border_rounded, 'Saved Gyms/Events',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.favorites)),
                _buildMenuItem(
                    Icons.event_outlined, 'Event Registrations',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.myEvents)),
                _buildMenuItem(
                    Icons.work_outline_rounded, 'Job Opportunities',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.jobs)),
                _buildMenuItem(
                    Icons.assignment_outlined, 'My Applications',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.myApplications)),
                _buildMenuItem(
                    Icons.card_membership_rounded, 'Membership History',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.membershipHistory)),
                const SizedBox(height: AppPadding.lg),

                // ── Account Settings ────────────────────────────────────
                _buildSectionTitle('Account Settings'),
                const SizedBox(height: AppPadding.sm),
                _buildMenuItem(Icons.person_outline_rounded, 'Personal Information',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInformationScreen()))),
                _buildMenuItem(Icons.payment_rounded, 'Payment Methods',
                    onTap: () => _showComingSoon('Payment Methods')),
                _buildMenuItem(Icons.card_giftcard_rounded, 'Rewards & Loyalty',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsLoyaltyScreen()))),
                _buildMenuItem(Icons.settings_outlined, 'Settings',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                _buildMenuItem(Icons.help_outline_rounded, 'Help & Support',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()))),
                const SizedBox(height: AppPadding.lg),


                // ── Logout ──────────────────────────────────────────────
                ListTile(
                  leading:
                      const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    auth.signOut();
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                  },
                ),
                const SizedBox(height: AppPadding.xl),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildDashboardMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildMenuItem(IconData icon, String title,
      {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title,
            style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.textSecondary),
        onTap: onTap,
      ),
      ),
    );
  }
}
