import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/super_admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/content_report_model.dart';

class SuperAdminModerationScreen extends StatefulWidget {
  const SuperAdminModerationScreen({super.key});

  @override
  State<SuperAdminModerationScreen> createState() => _SuperAdminModerationScreenState();
}

class _SuperAdminModerationScreenState extends State<SuperAdminModerationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuperAdminProvider>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SuperAdminProvider>();

    return Padding(
      padding: const EdgeInsets.all(AppPadding.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Content Moderation', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'All Reports'),
              Tab(text: 'Reviews'),
              Tab(text: 'Events'),
              Tab(text: 'Promotions'),
              Tab(text: 'Announcements'),
              Tab(text: 'Job Postings'),
              Tab(text: 'Profiles'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(provider.reports),
                _buildList(provider.reports.where((r) => r.contentType == 'review').toList()),
                _buildList(provider.reports.where((r) => r.contentType == 'event').toList()),
                _buildList(provider.reports.where((r) => r.contentType == 'promotion').toList()),
                _buildList(provider.reports.where((r) => r.contentType == 'announcement').toList()),
                _buildList(provider.reports.where((r) => r.contentType == 'job_posting').toList()),
                _buildList(provider.reports.where((r) => r.contentType == 'profile').toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<ContentReportModel> reports) {
    if (reports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_rounded, size: 48, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('No reports found', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            SizedBox(height: 8),
            Text('Reported content will appear here for review.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return _buildReportCard(report);
      },
    );
  }

  Widget _buildReportCard(ContentReportModel report) {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: Text(report.contentType.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.primary)),
              ),
              const Spacer(),
              _buildStatusBadge(report.status),
            ],
          ),
          const SizedBox(height: 12),
          Text('Reason: ${report.reason}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          if (report.contentTitle != null)
            Text('Content Title: ${report.contentTitle}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          if (report.contentPreview != null)
            Text('Preview: "${report.contentPreview}"', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          Text('Reported by: ${report.reporterName} on ${DateFormat('MMM d, yyyy').format(report.createdAt)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          
          if (report.status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.read<SuperAdminProvider>().dismissReport(
                      reportId: report.id,
                      adminId: authProvider.currentUser!.id,
                      adminName: authProvider.userName,
                    ),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border)),
                    child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction('hide', report, authProvider),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentOrange),
                    child: const Text('Hide', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction('remove', report, authProvider),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                    child: const Text('Remove', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
          if (report.status != 'pending' && report.moderationNotes != null) ...[
            const Divider(color: AppColors.border, height: 24),
            Text('Moderated by ${report.moderatorName}: ${report.moderationNotes}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppColors.textSecondary;
    if (status == 'pending') color = AppColors.accentOrange;
    if (status == 'resolved') color = AppColors.success;
    if (status == 'dismissed') color = AppColors.textMuted;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  void _handleAction(String action, ContentReportModel report, AuthProvider authProvider) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('${action == 'hide' ? 'Hide' : 'Remove'} Content'),
        content: TextField(
          controller: noteCtrl,
          decoration: const InputDecoration(hintText: 'Moderation notes (required)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (noteCtrl.text.trim().isEmpty) return;
              if (action == 'hide') {
                context.read<SuperAdminProvider>().hideContent(
                  reportId: report.id,
                  contentType: report.contentType,
                  contentId: report.contentId,
                  notes: noteCtrl.text,
                  adminId: authProvider.currentUser!.id,
                  adminName: authProvider.userName,
                );
              } else {
                context.read<SuperAdminProvider>().removeContent(
                  reportId: report.id,
                  contentType: report.contentType,
                  contentId: report.contentId,
                  reason: noteCtrl.text,
                  adminId: authProvider.currentUser!.id,
                  adminName: authProvider.userName,
                );
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: action == 'hide' ? AppColors.accentOrange : AppColors.error),
            child: Text(action == 'hide' ? 'Hide' : 'Remove'),
          ),
        ],
      ),
    );
  }
}
