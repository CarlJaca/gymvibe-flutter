import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/job_posting_model.dart';

/// Read-only detail view for the owner to see their own job posting.
class OwnerJobDetailsScreen extends StatelessWidget {
  final JobPostingModel job;
  const OwnerJobDetailsScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: ListView(
        padding: const EdgeInsets.all(AppPadding.md),
        children: [
          // Header
          Text(job.jobTitle,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(job.gymName,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(jobStatusLabel(job.status)),
              _chip(employmentTypeLabel(job.employmentType)),
              _chip(workSetupLabel(job.workSetup)),
              _chip(job.location),
            ],
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              _statCard('Applicants', '${job.applicationCount}',
                  Icons.people_rounded),
              const SizedBox(width: 10),
              _statCard('Openings', '${job.numberOfOpenings}',
                  Icons.person_add_rounded),
              const SizedBox(width: 10),
              _statCard('Salary', job.salaryDisplay,
                  Icons.payments_rounded),
            ],
          ),

          if (job.applicationDeadline != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: job.isExpired
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                job.isExpired
                    ? 'Deadline passed: ${_formatDate(job.applicationDeadline!)}'
                    : 'Deadline: ${_formatDate(job.applicationDeadline!)}',
                style: TextStyle(
                  fontSize: 13,
                  color: job.isExpired ? AppColors.error : AppColors.textSecondary,
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),

          _sectionTitle('Description'),
          const SizedBox(height: 6),
          Text(job.description,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5)),

          if (job.responsibilities.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle('Responsibilities'),
            const SizedBox(height: 6),
            ...job.responsibilities.map((r) => _bullet(r)),
          ],

          if (job.qualifications.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle('Qualifications'),
            const SizedBox(height: 6),
            ...job.qualifications.map((q) => _bullet(q)),
          ],

          if (job.requiredSkills.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle('Required Skills'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: job.requiredSkills
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primary.withValues(alpha: 0.08),
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
            const SizedBox(height: 16),
            _sectionTitle('Benefits'),
            const SizedBox(height: 6),
            ...job.benefits.map((b) => _bullet(b)),
          ],

          if (job.createdAt != null) ...[
            const SizedBox(height: 20),
            Text('Created: ${_formatDate(job.createdAt!)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
          ],
          const SizedBox(height: AppPadding.xl),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary));

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 7),
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4))),
          ],
        ),
      );

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
      );

  Widget _statCard(String label, String value, IconData icon) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
      );

  String _formatDate(DateTime date) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}
