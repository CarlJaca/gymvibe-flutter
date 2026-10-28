import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/super_admin_provider.dart';
import '../../providers/auth_provider.dart';

class SuperAdminLeaderboardScreen extends StatefulWidget {
  const SuperAdminLeaderboardScreen({super.key});

  @override
  State<SuperAdminLeaderboardScreen> createState() => _SuperAdminLeaderboardScreenState();
}

class _SuperAdminLeaderboardScreenState extends State<SuperAdminLeaderboardScreen> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuperAdminProvider>().loadPersonalRecords();
    });
  }

  void _setStatusFilter(String? status) {
    setState(() => _statusFilter = status);
    context.read<SuperAdminProvider>().loadPersonalRecords(statusFilter: status);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SuperAdminProvider>();

    return Padding(
      padding: const EdgeInsets.all(AppPadding.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Leaderboards', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Status', _statusFilter == null, () => _setStatusFilter(null)),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', _statusFilter == 'pending', () => _setStatusFilter('pending')),
                const SizedBox(width: 8),
                _buildFilterChip('Verified', _statusFilter == 'verified', () => _setStatusFilter('verified')),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', _statusFilter == 'rejected', () => _setStatusFilter('rejected')),
                const SizedBox(width: 8),
                _buildFilterChip('Disputed', _statusFilter == 'disputed', () => _setStatusFilter('disputed')),
                const SizedBox(width: 8),
                _buildFilterChip('Removed', _statusFilter == 'removed', () => _setStatusFilter('removed')),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _buildContent(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SuperAdminProvider provider) {
    if (provider.isLoading && provider.personalRecords.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.personalRecords.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_rounded, size: 48, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('No records found', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            SizedBox(height: 8),
            Text('Personal records uploaded by users will appear here.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: provider.personalRecords.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final record = provider.personalRecords[index];
        return _buildRecordTile(record);
      },
    );
  }

  Widget _buildRecordTile(Map<String, dynamic> record) {
    final authProvider = context.read<AuthProvider>();
    final status = record['status'] ?? 'pending';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      title: Text('${record['category']} - ${record['weight']} kg', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User: ${record['userName'] ?? 'Unknown'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text('Gym: ${record['gymId'] ?? 'Unknown'}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          Text('Date: ${record['date'] ?? ''}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusBadge(status),
          PopupMenuButton<String>(
            color: AppColors.surfaceElevated,
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (val) => _handleAction(val, record, authProvider),
            itemBuilder: (context) => [
              if (status == 'verified')
                const PopupMenuItem(value: 'dispute', child: Text('Dispute Record')),
              if (status != 'removed')
                const PopupMenuItem(value: 'remove', child: Text('Remove Record')),
              if (status == 'removed' || status == 'disputed')
                const PopupMenuItem(value: 'restore', child: Text('Restore Record')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppColors.textSecondary;
    if (status == 'pending') color = AppColors.accentOrange;
    if (status == 'verified') color = AppColors.primary;
    if (status == 'rejected') color = AppColors.error;
    if (status == 'disputed') color = Colors.orangeAccent;
    if (status == 'removed') color = AppColors.error;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  void _handleAction(String action, Map<String, dynamic> record, AuthProvider authProvider) {
    if (action == 'restore') {
      context.read<SuperAdminProvider>().restoreRecord(
        gymId: record['gymId'],
        recordId: record['id'],
        adminId: authProvider.currentUser!.id,
        adminName: authProvider.userName,
      );
      return;
    }

    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(action == 'dispute' ? 'Dispute Record' : 'Remove Record'),
        content: TextField(controller: reasonCtrl, decoration: InputDecoration(hintText: 'Reason for ${action}ing (required)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              if (action == 'dispute') {
                context.read<SuperAdminProvider>().disputeRecord(
                  gymId: record['gymId'],
                  recordId: record['id'],
                  reason: reasonCtrl.text,
                  adminId: authProvider.currentUser!.id,
                  adminName: authProvider.userName,
                );
              } else {
                context.read<SuperAdminProvider>().removeRecord(
                  gymId: record['gymId'],
                  recordId: record['id'],
                  reason: reasonCtrl.text,
                  adminId: authProvider.currentUser!.id,
                  adminName: authProvider.userName,
                );
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: action == 'dispute' ? AppColors.accentOrange : AppColors.error),
            child: Text(action == 'dispute' ? 'Dispute' : 'Remove'),
          ),
        ],
      ),
    );
  }
}
