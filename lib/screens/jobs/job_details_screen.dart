import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/job_posting_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/job_application_provider.dart';
import 'job_application_screen.dart';
import 'my_applications_screen.dart';

class JobDetailsScreen extends StatefulWidget {
  final JobPostingModel job;
  const JobDetailsScreen({super.key, required this.job});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _checkingApplied = true;
  bool _hasApplied = false;

  @override
  void initState() {
    super.initState();
    _checkIfApplied();
  }

  Future<void> _checkIfApplied() async {
    final auth = context.read<AuthProvider>();
    final appProv = context.read<JobApplicationProvider>();
    if (auth.currentUser != null) {
      _hasApplied =
          await appProv.checkHasApplied(widget.job.jobId, auth.currentUser!.id);
    }
    if (mounted) setState(() => _checkingApplied = false);
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final auth = context.watch<AuthProvider>();
    final isSeeker = auth.currentUser?.isGymSeeker ?? false;
    final isClosed = job.status == JobStatus.closed ||
        job.status == JobStatus.filled ||
        job.isExpired;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: [
          Consumer<JobProvider>(
            builder: (context, prov, _) {
              final isSaved = prov.isJobSaved(job.jobId);
              return IconButton(
                icon: Icon(
                  isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: isSaved ? AppColors.primary : AppColors.textSecondary,
                ),
                onPressed: () => prov.toggleSaveJob(job.jobId),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: AppColors.surfaceElevated,
                    child: job.gymLogoUrl.isNotEmpty
                        ? Image.network(job.gymLogoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.fitness_center_rounded,
                                color: AppColors.primary,
                                size: 28))
                        : const Icon(Icons.fitness_center_rounded,
                            color: AppColors.primary, size: 28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.jobTitle,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(job.gymName,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Info row ────────────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(Icons.schedule_rounded,
                    employmentTypeLabel(job.employmentType)),
                _chip(Icons.laptop_mac_rounded,
                    workSetupLabel(job.workSetup)),
                _chip(Icons.location_on_outlined, job.location),
                _chip(Icons.payments_outlined, job.salaryDisplay),
                _chip(Icons.people_outline_rounded,
                    '${job.numberOfOpenings} opening${job.numberOfOpenings > 1 ? 's' : ''}'),
              ],
            ),

            if (job.applicationDeadline != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: job.isExpired
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color:
                          job.isExpired ? AppColors.error : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      job.isExpired
                          ? 'Deadline passed'
                          : 'Apply by ${_formatDate(job.applicationDeadline!)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: job.isExpired
                            ? AppColors.error
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 16),

            // ── Description ─────────────────────────────────────────
            _sectionTitle('Description'),
            const SizedBox(height: 8),
            Text(job.description,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5)),

            if (job.responsibilities.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionTitle('Responsibilities'),
              const SizedBox(height: 8),
              ...job.responsibilities
                  .map((r) => _bulletPoint(r)),
            ],

            if (job.qualifications.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionTitle('Qualifications'),
              const SizedBox(height: 8),
              ...job.qualifications
                  .map((q) => _bulletPoint(q)),
            ],

            if (job.requiredSkills.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionTitle('Required Skills'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: job.requiredSkills
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                                color: AppColors.primary
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Text(s,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500)),
                        ))
                    .toList(),
              ),
            ],

            if (job.benefits.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionTitle('Benefits'),
              const SizedBox(height: 8),
              ...job.benefits.map((b) => _bulletPoint(b)),
            ],

            // ── Salary details ──────────────────────────────────────
            if (job.salaryType != SalaryType.notDisclosed) ...[
              const SizedBox(height: 20),
              _sectionTitle('Compensation'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.salaryDisplay,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    if (job.salaryPeriod != null)
                      Text(
                        'Paid ${job.salaryPeriod == SalaryPeriod.hourly ? 'hourly' : job.salaryPeriod == SalaryPeriod.daily ? 'daily' : 'monthly'}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ],

            if (job.createdAt != null) ...[
              const SizedBox(height: 20),
              Text(
                'Posted on ${_formatDate(job.createdAt!)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
              ),
            ],

            const SizedBox(height: 100), // space for bottom button
          ],
        ),
      ),

      // ── Bottom action button ──────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppPadding.md),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: _buildActionButton(isSeeker, isClosed),
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isSeeker, bool isClosed) {
    if (_checkingApplied) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2),
        ),
      );
    }

    if (_hasApplied) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.check_circle_rounded,
              color: AppColors.success),
          label: const Text('Application Submitted'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.success,
            side: const BorderSide(color: AppColors.success),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const MyApplicationsScreen()),
            );
          },
        ),
      );
    }

    if (isClosed) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceElevated,
            disabledBackgroundColor: AppColors.surfaceElevated,
          ),
          child: const Text('No Longer Accepting Applications',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    if (!isSeeker) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => JobApplicationScreen(job: widget.job),
            ),
          );
          if (result == true && mounted) {
            setState(() => _hasApplied = true);
          }
        },
        child: const Text('Apply Now',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary));
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textPrimary)),
        ],
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
