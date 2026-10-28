import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/super_admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class SuperAdminUserDetailsSheet extends StatelessWidget {
  final UserModel user;

  const SuperAdminUserDetailsSheet({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // ── Handle ─────────────────────────────────────────
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // ── Title ──────────────────────────────────────────
                const Text(
                  'User Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // ── Avatar & Name ──────────────────────────────────
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.surfaceElevated,
                  backgroundImage: NetworkImage(user.avatarUrl),
                  onBackgroundImageError: (_, __) {},
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),

                // ── Badges ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBadge(user.role == 'gym_seeker' ? 'Gym Seeker' : user.role == 'gym_owner' ? 'Gym Owner' : 'Super Admin',
                      user.role == 'gym_seeker' ? const Color(0xFF4FC3F7) : user.role == 'gym_owner' ? const Color(0xFFBA68C8) : AppColors.primary),
                    const SizedBox(width: 8),
                    _buildBadge(
                      user.accountStatus[0].toUpperCase() + user.accountStatus.substring(1),
                      user.accountStatus == 'active' ? AppColors.success
                          : user.accountStatus == 'suspended' ? AppColors.error
                          : user.accountStatus == 'pending' ? AppColors.accentOrange
                          : AppColors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Details ────────────────────────────────────────
                _buildDetailRow(Icons.badge_outlined, 'User ID', user.id),
                _buildDetailRow(Icons.phone_outlined, 'Phone Number', user.contactNumber ?? 'Not provided'),
                _buildDetailRow(Icons.calendar_today_outlined, 'Joined Date',
                    user.createdAt != null ? DateFormat('MMM d, yyyy hh:mm a').format(user.createdAt!) : 'Unknown'),
                _buildDetailRow(Icons.access_time, 'Last Login',
                    user.lastLogin != null ? DateFormat('MMM d, yyyy hh:mm a').format(user.lastLogin!) : 'Unknown'),
                _buildDetailRow(Icons.info_outline, 'Account Status',
                    user.accountStatus[0].toUpperCase() + user.accountStatus.substring(1)),

                const SizedBox(height: 24),

                // ── Quick action icons ─────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionIcon(
                      context,
                      Icons.calendar_today_rounded,
                      'View\nBookings',
                      () => _viewBookings(context),
                    ),
                    _buildActionIcon(
                      context,
                      Icons.star_rounded,
                      'View\nReviews',
                      () => _viewReviews(context),
                    ),
                    _buildActionIcon(
                      context,
                      Icons.emoji_events_rounded,
                      'View\nPRs',
                      () => _viewPRs(context),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Action buttons ─────────────────────────────────
                if (!user.isSuperAdmin) ...[
                  Row(
                    children: [
                      if (user.accountStatus != 'suspended')
                        Expanded(
                          child: _buildActionButton(
                            context,
                            'Suspend User',
                            AppColors.accentOrange,
                            () => _showSuspendDialog(context, authProvider),
                          ),
                        ),
                      if (user.accountStatus == 'suspended')
                        Expanded(
                          child: _buildActionButton(
                            context,
                            'Reactivate',
                            AppColors.success,
                            () => _reactivateUser(context, authProvider),
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (user.accountStatus != 'deactivated')
                        Expanded(
                          child: _buildActionButton(
                            context,
                            'Deactivate User',
                            AppColors.error,
                            () => _showDeactivateDialog(context, authProvider),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          'Edit Role',
                          const Color(0xFF4FC3F7),
                          () => _showRoleDialog(context, authProvider),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ─── Dialog actions ────────────────────────────────────────────────

  void _showSuspendDialog(BuildContext context, AuthProvider authProvider) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Suspend User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Suspend ${user.name}?', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Reason for suspension (required)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              context.read<SuperAdminProvider>().suspendUser(
                userId: user.id,
                reason: reasonCtrl.text.trim(),
                adminId: authProvider.currentUser!.id,
                adminName: authProvider.userName,
              );
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User suspended'), backgroundColor: AppColors.accentOrange),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentOrange),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog(BuildContext context, AuthProvider authProvider) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Deactivate User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deactivate ${user.name}?', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Reason for deactivation (required)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              context.read<SuperAdminProvider>().deactivateUser(
                userId: user.id,
                reason: reasonCtrl.text.trim(),
                adminId: authProvider.currentUser!.id,
                adminName: authProvider.userName,
              );
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User deactivated'), backgroundColor: AppColors.error),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _reactivateUser(BuildContext context, AuthProvider authProvider) {
    context.read<SuperAdminProvider>().reactivateUser(
      userId: user.id,
      adminId: authProvider.currentUser!.id,
      adminName: authProvider.userName,
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User reactivated'), backgroundColor: AppColors.success),
    );
  }

  void _showRoleDialog(BuildContext context, AuthProvider authProvider) {
    String? selectedRole = user.role;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Edit Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Change role for ${user.name}', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                dropdownColor: AppColors.surfaceElevated,
                items: const [
                  DropdownMenuItem(value: 'gym_seeker', child: Text('Gym User')),
                  DropdownMenuItem(value: 'gym_owner', child: Text('Gym Owner')),
                ],
                onChanged: (v) => setDialogState(() => selectedRole = v),
                decoration: const InputDecoration(labelText: 'Role'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (selectedRole == null || selectedRole == user.role) return;
                context.read<SuperAdminProvider>().changeUserRole(
                  userId: user.id,
                  newRole: selectedRole!,
                  adminId: authProvider.currentUser!.id,
                  adminName: authProvider.userName,
                );
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Role changed to $selectedRole'), backgroundColor: AppColors.primary),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _viewBookings(BuildContext context) async {
    final bookings = await context.read<SuperAdminProvider>().getUserBookings(user.id);
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('${user.name}\'s Bookings'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: bookings.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 48, color: AppColors.textMuted),
                      SizedBox(height: 16),
                      Text('No bookings found', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (_, i) {
                    final b = bookings[i];
                    return ListTile(
                      dense: true,
                      title: Text(b['gymName'] ?? 'Gym', style: const TextStyle(fontSize: 13)),
                      subtitle: Text('${b['dateStr'] ?? ''} - ${b['status'] ?? ''}', style: const TextStyle(fontSize: 11)),
                      trailing: Text(b['status'] ?? '', style: TextStyle(
                        fontSize: 11,
                        color: b['status'] == 'Confirmed' ? AppColors.success : AppColors.textMuted,
                      )),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _viewReviews(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('${user.name}\'s Reviews'),
        content: const SizedBox(
          height: 200,
          child: Center(child: Text('Reviews are stored within gym documents.\nUse Content Moderation to manage.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary))),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _viewPRs(BuildContext context) async {
    final prs = await context.read<SuperAdminProvider>().getUserPRs(user.id);
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('${user.name}\'s Personal Records'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: prs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events_rounded, size: 48, color: AppColors.textMuted),
                      SizedBox(height: 16),
                      Text('No records found', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: prs.length,
                  itemBuilder: (_, i) {
                    final pr = prs[i];
                    return ListTile(
                      dense: true,
                      title: Text('${pr.category.displayName} - ${pr.weight} kg', style: const TextStyle(fontSize: 13)),
                      subtitle: Text(pr.date, style: const TextStyle(fontSize: 11)),
                      trailing: Text(pr.status.displayName, style: TextStyle(fontSize: 11, color: pr.status.color)),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }
}
