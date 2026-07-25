import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/job_application_model.dart';
import '../../models/application_status_history_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_application_provider.dart';

class ApplicationDetailsScreen extends StatefulWidget {
  final JobApplicationModel application;
  const ApplicationDetailsScreen({super.key, required this.application});

  @override
  State<ApplicationDetailsScreen> createState() =>
      _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {
  List<ApplicationStatusHistoryModel> _statusHistory = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prov = context.read<JobApplicationProvider>();
    _statusHistory =
        await prov.getStatusHistory(widget.application.applicationId);
    if (mounted) setState(() => _loadingHistory = false);
  }

  Future<void> _confirmWithdraw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Withdraw Application?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to withdraw this application? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final auth = context.read<AuthProvider>();
      final prov = context.read<JobApplicationProvider>();
      final success = await prov.withdrawApplication(
        applicationId: widget.application.applicationId,
        applicantId: auth.currentUser!.id,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application withdrawn successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else if (mounted && prov.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(prov.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    final showWithdraw = canWithdraw(app.status);

    return Scaffold(
      appBar: AppBar(title: const Text('Application Details')),
      body: ListView(
        padding: const EdgeInsets.all(AppPadding.md),
        children: [
          // ── Job info ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.jobTitle,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(app.gymName,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.primary)),
                const SizedBox(height: 10),
                _statusBadgeLarge(app.status),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Status Timeline ─────────────────────────────────────────
          _sectionTitle('Status Timeline'),
          const SizedBox(height: 8),
          _loadingHistory
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  ),
                )
              : _buildTimeline(),
          const SizedBox(height: 16),

          // ── Interview details ────────────────────────────────────────
          if (app.status == ApplicationStatus.interview &&
              app.interviewDate != null) ...[
            _sectionTitle('Interview Details'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: Colors.purple.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow(Icons.calendar_today_rounded, 'Date',
                      _formatDate(app.interviewDate!)),
                  if (app.interviewLocation != null) ...[
                    const SizedBox(height: 8),
                    _detailRow(Icons.location_on_outlined, 'Location',
                        app.interviewLocation!),
                  ],
                  if (app.interviewInstructions != null) ...[
                    const SizedBox(height: 8),
                    _detailRow(Icons.info_outline_rounded,
                        'Instructions', app.interviewInstructions!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Message from owner ──────────────────────────────────────
          if (app.applicantMessage != null &&
              app.applicantMessage!.isNotEmpty) ...[
            _sectionTitle('Message from Employer'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(app.applicantMessage!,
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.4)),
            ),
            const SizedBox(height: 16),
          ],

          // ── Rejection reason ────────────────────────────────────────
          if (app.status == ApplicationStatus.rejected &&
              app.rejectionReason != null) ...[
            _sectionTitle('Rejection Reason'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Text(app.rejectionReason!,
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.4)),
            ),
            const SizedBox(height: 16),
          ],

          // ── Submitted info ──────────────────────────────────────────
          _sectionTitle('Submitted Information'),
          const SizedBox(height: 8),
          _infoRow('Cover Message', app.coverMessage),
          if (app.experience.isNotEmpty)
            _infoRow('Experience', app.experience),
          if (app.education.isNotEmpty)
            _infoRow('Education', app.education),
          if (app.skills.isNotEmpty)
            _infoRow('Skills', app.skills.join(', ')),
          if (app.availability.isNotEmpty)
            _infoRow('Availability', app.availability),
          if (app.expectedSalary != null)
            _infoRow('Expected Salary',
                '₱${app.expectedSalary!.toStringAsFixed(0)}'),
          if (app.resumeFileName != null)
            _infoRow('Resume', app.resumeFileName!),
          const SizedBox(height: 24),

          // ── Withdraw button ─────────────────────────────────────────
          if (showWithdraw)
            OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined,
                  color: AppColors.error),
              label: const Text('Withdraw Application'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              onPressed: _confirmWithdraw,
            ),
          const SizedBox(height: AppPadding.xl),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (_statusHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text('No status history available.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: _statusHistory.asMap().entries.map((entry) {
          final i = entry.key;
          final h = entry.value;
          final isLast = i == _statusHistory.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color:
                          isLast ? AppColors.primary : AppColors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 36,
                      color: AppColors.border,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicationStatusLabel(
                            stringToApplicationStatus(h.newStatus)),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isLast
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (h.message != null && h.message!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(h.message!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ),
                      if (h.createdAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _formatDate(h.createdAt!),
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.purple),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBadgeLarge(ApplicationStatus status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        applicationStatusLabel(status),
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
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
