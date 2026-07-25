import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/super_admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class SuperAdminOwnerApprovalDetailScreen extends StatelessWidget {
  final UserModel owner;

  const SuperAdminOwnerApprovalDetailScreen({super.key, required this.owner});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Owner Approval Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    owner.gymName ?? 'Gym Application',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                _buildStatusBadge(owner.accountStatus),
              ],
            ),
            const SizedBox(height: 24),

            // ── Owner Info ─────────────────────────────────────
            _buildSection('Owner Information', [
              _buildInfoRow('Name', owner.name),
              _buildInfoRow('Email', owner.email),
              _buildInfoRow('Phone', owner.contactNumber ?? 'Not provided'),
              _buildInfoRow('City', owner.location),
            ]),
            const SizedBox(height: 24),

            // ── Application Info ───────────────────────────────
            _buildSection('Application Information', [
              _buildInfoRow('Gym Name', owner.gymName ?? 'Not specified'),
              _buildInfoRow('Gym Address', owner.location),
              _buildInfoRow('Submitted Date',
                  owner.createdAt != null ? DateFormat('MMM d, yyyy hh:mm a').format(owner.createdAt!) : 'Unknown'),
            ]),
            const SizedBox(height: 24),

            // ── Documents ──────────────────────────────────────
            _buildSection('Documents', [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    _DocumentPlaceholder(label: 'Business\nPermit'),
                    SizedBox(width: 12),
                    _DocumentPlaceholder(label: 'ID Front'),
                    SizedBox(width: 12),
                    _DocumentPlaceholder(label: 'ID Back'),
                    SizedBox(width: 12),
                    _DocumentPlaceholder(label: 'Photo'),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 40),

            // ── Action Buttons ─────────────────────────────────
            if (owner.accountStatus == 'pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _requestInfo(context, authProvider),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: const Text('Request Info'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approve(context, authProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _reject(context, authProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'pending': color = AppColors.accentOrange; break;
      case 'active': color = AppColors.success; break;
      case 'rejected': color = AppColors.error; break;
      default: color = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  void _approve(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Approve Owner'),
        content: Text('Approve ${owner.name} as a Gym Owner for ${owner.gymName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<SuperAdminProvider>().approveOwner(
                userId: owner.id,
                adminId: authProvider.currentUser!.id,
                adminName: authProvider.userName,
              );
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Owner approved'), backgroundColor: AppColors.success),
              );
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _reject(BuildContext context, AuthProvider authProvider) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reject Owner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: reasonCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Rejection reason (required)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              context.read<SuperAdminProvider>().rejectOwner(
                userId: owner.id,
                reason: reasonCtrl.text.trim(),
                adminId: authProvider.currentUser!.id,
                adminName: authProvider.userName,
              );
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _requestInfo(BuildContext context, AuthProvider authProvider) {
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Request Information'),
        content: TextField(controller: msgCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'What information is needed?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (msgCtrl.text.trim().isEmpty) return;
              context.read<SuperAdminProvider>().requestOwnerInfo(
                userId: owner.id,
                message: msgCtrl.text.trim(),
                adminId: authProvider.currentUser!.id,
                adminName: authProvider.userName,
              );
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }
}

class _DocumentPlaceholder extends StatelessWidget {
  final String label;
  const _DocumentPlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.description_outlined, size: 24, color: AppColors.textMuted),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
