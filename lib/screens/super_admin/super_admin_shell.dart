import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/super_admin_provider.dart';
import '../../core/routes/app_router.dart';
import 'super_admin_dashboard_screen.dart';
import 'super_admin_users_screen.dart';
import 'super_admin_owner_approvals_screen.dart';
import 'super_admin_gyms_screen.dart';
import 'super_admin_bookings_screen.dart';
import 'super_admin_leaderboard_screen.dart';
import 'super_admin_moderation_screen.dart';
import 'super_admin_reports_screen.dart';
import 'super_admin_notifications_screen.dart';
import 'super_admin_settings_screen.dart';

class SuperAdminShell extends StatefulWidget {
  const SuperAdminShell({super.key});

  @override
  State<SuperAdminShell> createState() => _SuperAdminShellState();
}

class _SuperAdminShellState extends State<SuperAdminShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.people_rounded, label: 'Users'),
    _NavItem(icon: Icons.verified_user_rounded, label: 'Owner Approvals'),
    _NavItem(icon: Icons.fitness_center_rounded, label: 'Gyms'),
    _NavItem(icon: Icons.calendar_today_rounded, label: 'Bookings'),
    _NavItem(icon: Icons.leaderboard_rounded, label: 'Leaderboards'),
    _NavItem(icon: Icons.shield_rounded, label: 'Content Moderation'),
    _NavItem(icon: Icons.description_rounded, label: 'Reports & Audit Logs'),
    _NavItem(icon: Icons.notifications_rounded, label: 'Notifications'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const SuperAdminDashboardScreen();
      case 1:
        return const SuperAdminUsersScreen();
      case 2:
        return const SuperAdminOwnerApprovalsScreen();
      case 3:
        return const SuperAdminGymsScreen();
      case 4:
        return const SuperAdminBookingsScreen();
      case 5:
        return const SuperAdminLeaderboardScreen();
      case 6:
        return const SuperAdminModerationScreen();
      case 7:
        return const SuperAdminReportsScreen();
      case 8:
        return const SuperAdminNotificationsScreen();
      case 9:
        return const SuperAdminSettingsScreen();
      default:
        return const SuperAdminDashboardScreen();
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
      // Let the routing animation start, then clear the state
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        context.read<AuthProvider>().signOut();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<SuperAdminProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentIndex = adminProvider.currentNavIndex;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context, currentIndex, authProvider, adminProvider),
      body: Row(
        children: [
          // Desktop/tablet: persistent sidebar
          if (MediaQuery.of(context).size.width >= 768)
            _buildSidebar(context, currentIndex, authProvider, adminProvider),
          // Content area
          Expanded(
            child: Column(
              children: [
                // Mobile: show app bar with menu button
                if (MediaQuery.of(context).size.width < 768)
                  _buildMobileAppBar(context, currentIndex),
                Expanded(child: _buildScreen(currentIndex)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAppBar(BuildContext context, int currentIndex) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 16,
        bottom: 8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 8),
          Text(
            _navItems[currentIndex].label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, int currentIndex,
      AuthProvider authProvider, SuperAdminProvider adminProvider) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: _buildNavContent(context, currentIndex, authProvider, adminProvider, isSidebar: true),
    );
  }

  Widget _buildDrawer(BuildContext context, int currentIndex,
      AuthProvider authProvider, SuperAdminProvider adminProvider) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: _buildNavContent(context, currentIndex, authProvider, adminProvider, isSidebar: false),
    );
  }

  Widget _buildNavContent(BuildContext context, int currentIndex,
      AuthProvider authProvider, SuperAdminProvider adminProvider,
      {required bool isSidebar}) {
    final pendingCount = adminProvider.pendingOwners.length;
    final reportCount = adminProvider.reports.where((r) => r.status == 'pending').length;

    return SafeArea(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 28),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GYMVIBE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'DAVAO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(left: 38),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'SUPER ADMIN',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Admin profile card ──────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    (authProvider.userName.isNotEmpty
                        ? authProvider.userName[0]
                        : 'A'),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authProvider.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        authProvider.userEmail,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Super Admin',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),

          // ── Navigation items ────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (int i = 0; i < _navItems.length; i++)
                  _buildNavTile(
                    context,
                    index: i,
                    item: _navItems[i],
                    isSelected: currentIndex == i,
                    badge: i == 2 && pendingCount > 0
                        ? pendingCount
                        : i == 6 && reportCount > 0
                            ? reportCount
                            : null,
                    onTap: () {
                      adminProvider.setNavIndex(i);
                      if (!isSidebar) Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),

          // ── Logout ──────────────────────────────────────────────
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: _buildNavTile(
              context,
              index: -1,
              item: const _NavItem(icon: Icons.logout_rounded, label: 'Logout'),
              isSelected: false,
              isLogout: true,
              onTap: _handleLogout,
            ),
          ),

          // ── Version footer ──────────────────────────────────────
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'GymVibe Davao v1.0.0',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(
    BuildContext context, {
    required int index,
    required _NavItem item,
    required bool isSelected,
    required VoidCallback onTap,
    int? badge,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isLogout
                      ? AppColors.error
                      : isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isLogout
                          ? AppColors.error
                          : isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
