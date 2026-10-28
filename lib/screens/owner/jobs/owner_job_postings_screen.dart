import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/job_posting_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/owner_job_provider.dart';
import 'create_job_posting_screen.dart';
import 'edit_job_posting_screen.dart';
import 'owner_job_details_screen.dart';
import 'job_applicants_screen.dart';

class OwnerJobPostingsScreen extends StatefulWidget {
  const OwnerJobPostingsScreen({super.key});

  @override
  State<OwnerJobPostingsScreen> createState() => _OwnerJobPostingsScreenState();
}

class _OwnerJobPostingsScreenState extends State<OwnerJobPostingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<OwnerJobProvider>().loadOwnerJobs(auth.currentUser!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Postings'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Draft'),
            Tab(text: 'Active'),
            Tab(text: 'Closed'),
            Tab(text: 'Filled'),
            Tab(text: 'Archived'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateJobPostingScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<OwnerJobProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildJobList(prov.draftJobs, 'No draft postings'),
              _buildJobList(prov.activeJobs, 'No active postings'),
              _buildJobList(prov.closedJobs, 'No closed postings'),
              _buildJobList(prov.filledJobs, 'No filled postings'),
              _buildJobList(prov.archivedJobs, 'No archived postings'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateJobPostingScreen()),
          );
        },
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildJobList(List<JobPostingModel> jobs, String emptyMessage) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_off_outlined,
                size: 56, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(emptyMessage,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 15)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      onRefresh: () {
        final auth = context.read<AuthProvider>();
        return context.read<OwnerJobProvider>().loadOwnerJobs(auth.currentUser!.id);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppPadding.md),
        itemCount: jobs.length,
        itemBuilder: (context, index) => _buildJobCard(jobs[index]),
      ),
    );
  }

  Widget _buildJobCard(JobPostingModel job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Text(job.jobTitle,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
              ),
              _statusChip(job.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(employmentTypeLabel(job.employmentType),
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              _infoIcon(Icons.people_outline_rounded,
                  '${job.applicationCount} applicant${job.applicationCount != 1 ? 's' : ''}'),
              const SizedBox(width: 16),
              _infoIcon(Icons.person_add_outlined,
                  '${job.numberOfOpenings} opening${job.numberOfOpenings != 1 ? 's' : ''}'),
              const Spacer(),
              if (job.createdAt != null)
                Text(_formatDate(job.createdAt!),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          if (job.applicationDeadline != null) ...[
            const SizedBox(height: 4),
            Text(
              'Deadline: ${_formatDate(job.applicationDeadline!)}',
              style: TextStyle(
                fontSize: 11,
                color: job.isExpired ? AppColors.error : AppColors.textMuted,
                fontWeight: job.isExpired ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 4),
          // Actions row
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _buildActions(job),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(JobPostingModel job) {
    final auth = context.read<AuthProvider>();
    final prov = context.read<OwnerJobProvider>();
    final ownerId = auth.currentUser!.id;
    final actions = <Widget>[];

    actions.add(_actionButton('View', Icons.visibility_outlined, () {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => OwnerJobDetailsScreen(job: job)));
    }));

    if (job.status == JobStatus.draft) {
      actions.add(_actionButton('Edit', Icons.edit_outlined, () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => EditJobPostingScreen(job: job)));
      }));
      actions.add(_actionButton('Publish', Icons.publish_rounded, () async {
        await prov.publishJob(job.jobId, ownerId);
      }));
    }

    if (job.status == JobStatus.active) {
      actions.add(_actionButton('Edit', Icons.edit_outlined, () {
        if (job.applicationCount > 0) {
          _showEditWarning(job);
        } else {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => EditJobPostingScreen(job: job)));
        }
      }));
      actions.add(_actionButton('Applicants', Icons.people_rounded, () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => JobApplicantsScreen(job: job)));
      }));
      actions.add(_actionButton('Close', Icons.close_rounded, () async {
        await prov.closeJob(job.jobId, ownerId);
      }));
      actions.add(_actionButton('Filled', Icons.check_circle_outline, () async {
        await prov.markJobFilled(job.jobId, ownerId);
      }));
    }

    if (job.status == JobStatus.closed) {
      actions.add(_actionButton('Applicants', Icons.people_rounded, () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => JobApplicantsScreen(job: job)));
      }));
      if (!job.isExpired) {
        actions.add(_actionButton('Reopen', Icons.refresh_rounded, () async {
          await prov.reopenJob(job.jobId, ownerId);
        }));
      }
      actions.add(_actionButton('Archive', Icons.archive_outlined, () async {
        await prov.archiveJob(job.jobId, ownerId);
      }));
    }

    if (job.status == JobStatus.filled) {
      actions.add(_actionButton('Applicants', Icons.people_rounded, () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => JobApplicantsScreen(job: job)));
      }));
      actions.add(_actionButton('Archive', Icons.archive_outlined, () async {
        await prov.archiveJob(job.jobId, ownerId);
      }));
    }

    actions.add(_actionButton('Duplicate', Icons.copy_rounded, () async {
      await prov.duplicateJob(job);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job duplicated as draft.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }));

    return actions;
  }

  void _showEditWarning(JobPostingModel job) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Warning',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '${job.applicationCount} applicant(s) have already applied. Editing major details may affect existing applications.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => EditJobPostingScreen(job: job)));
            },
            child: const Text('Edit Anyway'),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return TextButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onTap,
    );
  }

  Widget _statusChip(JobStatus status) {
    Color color;
    switch (status) {
      case JobStatus.draft:
        color = AppColors.textMuted;
        break;
      case JobStatus.active:
        color = AppColors.success;
        break;
      case JobStatus.closed:
        color = Colors.orange;
        break;
      case JobStatus.filled:
        color = AppColors.primary;
        break;
      case JobStatus.archived:
        color = AppColors.textMuted;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        jobStatusLabel(status),
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _infoIcon(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}
