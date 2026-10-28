import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/job_posting_model.dart';
import '../../../models/job_application_model.dart';
import '../../../providers/owner_job_provider.dart';
import '../../../widgets/filter_chip_widget.dart';
import 'applicant_details_screen.dart';

class JobApplicantsScreen extends StatefulWidget {
  final JobPostingModel job;
  const JobApplicantsScreen({super.key, required this.job});

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  String? _statusFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerJobProvider>().loadApplicants(widget.job.jobId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Applicants')),
      body: SafeArea(
        child: Column(
          children: [
            // ── Job info banner ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppPadding.md),
              color: AppColors.surfaceElevated,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.job.jobTitle,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.job.numberOfOpenings} opening(s)',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _statusChip(widget.job.status),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // ── Search & Filter ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppPadding.md),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search applicant name...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
                children: [
                  'all',
                  'submitted',
                  'under_review',
                  'shortlisted',
                  'interview',
                  'accepted',
                  'rejected',
                  'withdrawn',
                ].map((f) {
                  final label = f == 'all'
                      ? 'All'
                      : f == 'under_review'
                          ? 'Under Review'
                          : '${f[0].toUpperCase()}${f.substring(1)}';
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChipWidget(
                      label: label,
                      isSelected: (_statusFilter ?? 'all') == f,
                      onTap: () => setState(() => _statusFilter = f == 'all' ? null : f),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppPadding.sm),

            // ── Applicants list ───────────────────────────────────────
            Expanded(
              child: Consumer<OwnerJobProvider>(
                builder: (context, prov, _) {
                  if (prov.isLoading) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary));
                  }

                  // Apply filters
                  var apps = prov.applicants;
                  if (_statusFilter != null) {
                    final s = stringToApplicationStatus(_statusFilter!);
                    apps = apps.where((a) => a.status == s).toList();
                  }
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    apps = apps.where((a) => a.applicantName.toLowerCase().contains(q)).toList();
                  }

                  if (apps.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline_rounded,
                              size: 56,
                              color: AppColors.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          const Text('No applicants found',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 15)),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surfaceElevated,
                    onRefresh: () => prov.loadApplicants(widget.job.jobId),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.md),
                      itemCount: apps.length,
                      itemBuilder: (context, index) =>
                          _buildApplicantCard(context, apps[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantCard(BuildContext context, JobApplicationModel app) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ApplicantDetailsScreen(application: app)));
      },
      child: Container(
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surfaceElevated,
                  backgroundImage: app.applicantProfileImageUrl.isNotEmpty
                      ? NetworkImage(app.applicantProfileImageUrl)
                      : null,
                  child: app.applicantProfileImageUrl.isEmpty
                      ? const Icon(Icons.person,
                          color: AppColors.textMuted, size: 24)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.applicantName,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      Text(app.applicantEmail,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                _appStatusBadge(app.status),
              ],
            ),
            const SizedBox(height: 12),
            if (app.experience.isNotEmpty) ...[
              Text(app.experience,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  app.submittedAt != null
                      ? _formatDate(app.submittedAt!)
                      : 'Unknown date',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
                if (app.status == ApplicationStatus.interview &&
                    app.interviewDate != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.event_rounded,
                      size: 14, color: Colors.purple),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(app.interviewDate!),
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.purple,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _appStatusBadge(ApplicationStatus status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case ApplicationStatus.submitted:
        bgColor = Colors.blue.withValues(alpha: 0.12);
        textColor = Colors.blue;
        break;
      case ApplicationStatus.underReview:
        bgColor = Colors.orange.withValues(alpha: 0.12);
        textColor = Colors.orange;
        break;
      case ApplicationStatus.shortlisted:
        bgColor = AppColors.primary.withValues(alpha: 0.12);
        textColor = AppColors.primary;
        break;
      case ApplicationStatus.interview:
        bgColor = Colors.purple.withValues(alpha: 0.12);
        textColor = Colors.purple;
        break;
      case ApplicationStatus.accepted:
        bgColor = AppColors.success.withValues(alpha: 0.12);
        textColor = AppColors.success;
        break;
      case ApplicationStatus.rejected:
        bgColor = AppColors.error.withValues(alpha: 0.12);
        textColor = AppColors.error;
        break;
      case ApplicationStatus.withdrawn:
        bgColor = AppColors.textMuted.withValues(alpha: 0.12);
        textColor = AppColors.textMuted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        applicationStatusLabel(status),
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        jobStatusLabel(status),
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
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
