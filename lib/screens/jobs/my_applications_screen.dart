import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/job_application_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_application_provider.dart';
import '../../widgets/filter_chip_widget.dart';
import 'application_details_screen.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context
            .read<JobApplicationProvider>()
            .loadMyApplications(auth.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Filter chips ──────────────────────────────────────────
            SizedBox(
              height: 44,
              child: Consumer<JobApplicationProvider>(
                builder: (context, prov, _) {
                  final filters = [
                    'all',
                    'submitted',
                    'under_review',
                    'shortlisted',
                    'interview',
                    'accepted',
                    'rejected',
                    'withdrawn',
                  ];
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.md),
                    children: filters.map((f) {
                      final label = f == 'all'
                          ? 'All'
                          : f == 'under_review'
                              ? 'Under Review'
                              : '${f[0].toUpperCase()}${f.substring(1)}';
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChipWidget(
                          label: label,
                          isSelected: (prov.statusFilter ?? 'all') == f,
                          onTap: () => prov.setStatusFilter(
                              f == 'all' ? null : f),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: AppPadding.sm),

            // ── Applications list ─────────────────────────────────────
            Expanded(
              child: Consumer<JobApplicationProvider>(
                builder: (context, prov, _) {
                  if (prov.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    );
                  }

                  final apps = prov.myApplications;

                  if (apps.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.description_outlined,
                              size: 64,
                              color: AppColors.textMuted
                                  .withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          const Text('No applications yet',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16)),
                          const SizedBox(height: 4),
                          const Text(
                              'Browse job postings and submit your first application',
                              style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surfaceElevated,
                    onRefresh: () {
                      final auth = context.read<AuthProvider>();
                      return prov
                          .loadMyApplications(auth.currentUser!.id);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.md),
                      itemCount: apps.length,
                      itemBuilder: (context, index) =>
                          _buildApplicationCard(context, apps[index]),
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

  Widget _buildApplicationCard(
      BuildContext context, JobApplicationModel app) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ApplicationDetailsScreen(application: app),
          ),
        );
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.jobTitle,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(app.gymName,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                _statusBadge(app.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  app.submittedAt != null
                      ? 'Submitted ${_formatDate(app.submittedAt!)}'
                      : 'Date unknown',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
                if (app.interviewDate != null &&
                    app.status == ApplicationStatus.interview) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.event_rounded,
                      size: 13, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Interview ${_formatDate(app.interviewDate!)}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
            if (app.updatedAt != null &&
                app.updatedAt != app.submittedAt) ...[
              const SizedBox(height: 4),
              Text(
                'Updated ${_formatDate(app.updatedAt!)}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(ApplicationStatus status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        applicationStatusLabel(status),
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
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
