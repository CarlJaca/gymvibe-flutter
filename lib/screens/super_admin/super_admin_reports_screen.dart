import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/super_admin_provider.dart';
import '../../models/audit_log_model.dart';

class SuperAdminReportsScreen extends StatefulWidget {
  const SuperAdminReportsScreen({super.key});

  @override
  State<SuperAdminReportsScreen> createState() => _SuperAdminReportsScreenState();
}

class _SuperAdminReportsScreenState extends State<SuperAdminReportsScreen> {
  final _searchCtrl = TextEditingController();
  String? _actionFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuperAdminProvider>().loadAuditLogs();
    });
  }

  void _onSearch(String query) {
    context.read<SuperAdminProvider>().loadAuditLogs(
      searchQuery: query.isNotEmpty ? query : null,
      actionFilter: _actionFilter,
    );
  }

  void _setActionFilter(String? action) {
    setState(() => _actionFilter = action);
    context.read<SuperAdminProvider>().loadAuditLogs(
      searchQuery: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
      actionFilter: action,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SuperAdminProvider>();

    return Padding(
      padding: const EdgeInsets.all(AppPadding.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reports & Audit Logs', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  decoration: const InputDecoration(
                    hintText: 'Search logs...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _actionFilter,
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceElevated,
                      hint: const Text('All Actions', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Actions')),
                        ...provider.actionTypes.map((act) => DropdownMenuItem(value: act, child: Text(act))),
                      ],
                      onChanged: _setActionFilter,
                    ),
                  ),
                ),
              ),
            ],
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
    if (provider.isLoading && provider.auditLogs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.auditLogs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_rounded, size: 48, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('No audit logs found', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            SizedBox(height: 8),
            Text('Admin actions and reports will be logged here.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: provider.auditLogs.length,
      itemBuilder: (context, index) {
        final log = provider.auditLogs[index];
        return _buildLogCard(log);
      },
    );
  }

  Widget _buildLogCard(AuditLogModel log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(log.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          'By ${log.actorName} • ${DateFormat('MMM d, yyyy hh:mm a').format(log.createdAt)}',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        trailing: _buildActionBadge(log.action),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 16, color: AppColors.border),
          _buildDetailRow('Log ID', log.id),
          _buildDetailRow('Actor ID', log.actorId),
          _buildDetailRow('Target Type', log.targetType),
          _buildDetailRow('Target ID', log.targetId),
          if (log.reason.isNotEmpty)
            _buildDetailRow('Reason', log.reason),
        ],
      ),
    );
  }

  Widget _buildActionBadge(String action) {
    Color color = AppColors.primary;
    if (action.contains('suspended') || action.contains('removed') || action.contains('deactivated') || action.contains('rejected')) {
      color = AppColors.error;
    } else if (action.contains('flagged') || action.contains('disputed')) {
      color = AppColors.accentOrange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        action.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
        ],
      ),
    );
  }
}
