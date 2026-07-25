import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/super_admin_provider.dart';
import '../../models/audit_log_model.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuperAdminProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SuperAdminProvider>();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => provider.loadDashboard(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ────────────────────────────────────────
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 24),

            // ── Loading state ───────────────────────────────────
            if (provider.isLoading && provider.dashboardStats.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            // ── Error state ─────────────────────────────────────
            else if (provider.errorMessage != null && provider.dashboardStats.isEmpty)
              _buildErrorState(provider)
            else ...[
              // ── Stat cards grid ─────────────────────────────────
              _buildStatsGrid(provider.dashboardStats),

              const SizedBox(height: 32),

              // ── Recent Activity ─────────────────────────────────
              _buildRecentActivity(provider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(SuperAdminProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadDashboard(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, int> stats) {
    final items = [
      _StatData('Total Users', stats['totalUsers'] ?? 0, Icons.people_rounded, const Color(0xFF4FC3F7)),
      _StatData('Gym Seekers', stats['gymSeekers'] ?? 0, Icons.person_search_rounded, const Color(0xFF81C784)),
      _StatData('Gym Owners', stats['gymOwners'] ?? 0, Icons.store_rounded, const Color(0xFFBA68C8)),
      _StatData('Pending Owners', stats['pendingOwners'] ?? 0, Icons.pending_rounded, const Color(0xFFFFB74D)),
      _StatData('Approved Gyms', stats['approvedGyms'] ?? 0, Icons.verified_rounded, AppColors.primary),
      _StatData('Total Bookings', stats['totalBookings'] ?? 0, Icons.calendar_month_rounded, const Color(0xFF4DD0E1)),
      _StatData('Active Events', stats['activeEvents'] ?? 0, Icons.event_rounded, const Color(0xFFF06292)),
      _StatData('Active Promotions', stats['activePromotions'] ?? 0, Icons.local_offer_rounded, const Color(0xFFFFD54F)),
      _StatData('Verified PRs', stats['verifiedPRs'] ?? 0, Icons.emoji_events_rounded, AppColors.primary),
      _StatData('Pending PRs', stats['pendingPRs'] ?? 0, Icons.hourglass_top_rounded, const Color(0xFFFFB74D)),
      _StatData('Reported Content', stats['reportedContent'] ?? 0, Icons.flag_rounded, const Color(0xFFE57373)),
      _StatData('Suspended Users', stats['suspendedUsers'] ?? 0, Icons.block_rounded, const Color(0xFFEF5350)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildStatCard(items[index]),
    );
  }

  Widget _buildStatCard(_StatData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(data.icon, size: 18, color: data.color),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, size: 16, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatNumber(data.value),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(SuperAdminProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => provider.setNavIndex(7), // Reports & Audit Logs
              child: const Text(
                'View all',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (provider.recentActivity.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.history_rounded, size: 40, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text(
                    'No recent activity',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.recentActivity.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: AppColors.border,
              ),
              itemBuilder: (context, index) {
                final log = provider.recentActivity[index];
                return _buildActivityTile(log);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildActivityTile(AuditLogModel log) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getActionColor(log.action),
        ),
      ),
      title: Text(
        log.description,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        '${log.actorName} - ${log.targetId}',
        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
      ),
      trailing: Text(
        _formatTime(log.createdAt),
        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
      ),
    );
  }

  Color _getActionColor(String action) {
    if (action.contains('approved') || action.contains('reactivated') || action.contains('restored')) {
      return AppColors.primary;
    }
    if (action.contains('suspended') || action.contains('removed') || action.contains('rejected')) {
      return AppColors.error;
    }
    if (action.contains('disputed') || action.contains('flagged')) {
      return AppColors.accentOrange;
    }
    return AppColors.primary;
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return NumberFormat.compact().format(number);
    }
    return number.toString();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dateTime);
  }
}

class _StatData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatData(this.label, this.value, this.icon, this.color);
}
