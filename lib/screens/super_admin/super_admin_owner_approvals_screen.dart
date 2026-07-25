import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/super_admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import 'super_admin_owner_approval_detail_screen.dart';

class SuperAdminOwnerApprovalsScreen extends StatefulWidget {
  const SuperAdminOwnerApprovalsScreen({super.key});

  @override
  State<SuperAdminOwnerApprovalsScreen> createState() => _SuperAdminOwnerApprovalsScreenState();
}

class _SuperAdminOwnerApprovalsScreenState extends State<SuperAdminOwnerApprovalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuperAdminProvider>().loadOwnerApprovals();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SuperAdminProvider>();

    return Padding(
      padding: const EdgeInsets.all(AppPadding.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Owner Approvals', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Pending (${provider.pendingOwners.length})'),
              const Tab(text: 'Approved'),
              const Tab(text: 'Rejected'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(provider.pendingOwners, 'pending', provider),
                _buildList(provider.approvedOwners, 'approved', provider),
                _buildList(provider.rejectedOwners, 'rejected', provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<UserModel> owners, String tab, SuperAdminProvider provider) {
    if (provider.isLoading && owners.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (owners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('No $tab applications', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Owner applications will appear here.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => provider.loadOwnerApprovals(),
      child: ListView.builder(
        itemCount: owners.length,
        itemBuilder: (context, index) => _buildOwnerCard(owners[index], tab),
      ),
    );
  }

  Widget _buildOwnerCard(UserModel owner, String tab) {
    final authProvider = context.read<AuthProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceElevated,
                backgroundImage: NetworkImage(owner.avatarUrl),
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(owner.gymName ?? 'Gym', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text('Owner: ${owner.name}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(owner.email, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text(owner.location, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              _buildStatusBadge(owner.accountStatus),
            ],
          ),
          if (owner.createdAt != null) ...[
            const SizedBox(height: 8),
            Text('Submitted: ${DateFormat('MMM d, yyyy').format(owner.createdAt!)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SuperAdminOwnerApprovalDetailScreen(owner: owner),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Text('View', style: TextStyle(fontSize: 13)),
                ),
              ),
              if (tab == 'pending') ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveOwner(owner, authProvider),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Approve', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _rejectOwner(owner, authProvider),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                    child: const Text('Reject', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  void _approveOwner(UserModel owner, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Approve Owner'),
        content: Text('Approve ${owner.name} as a Gym Owner?'),
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

  void _rejectOwner(UserModel owner, AuthProvider authProvider) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reject Owner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject ${owner.name}\'s application?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Reason for rejection (required)'),
            ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Owner rejected'), backgroundColor: AppColors.error),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
