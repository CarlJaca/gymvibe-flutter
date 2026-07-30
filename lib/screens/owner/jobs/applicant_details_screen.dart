import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/job_application_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/owner_job_provider.dart';

class ApplicantDetailsScreen extends StatefulWidget {
  final JobApplicationModel application;
  const ApplicantDetailsScreen({super.key, required this.application});

  @override
  State<ApplicantDetailsScreen> createState() => _ApplicantDetailsScreenState();
}

class _ApplicantDetailsScreenState extends State<ApplicantDetailsScreen> {
  final _noteController = TextEditingController();
  bool _isSavingNote = false;

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.application.ownerNote ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    setState(() => _isSavingNote = true);
    final prov = context.read<OwnerJobProvider>();
    final success = await prov.updateOwnerNote(
        widget.application.applicationId, _noteController.text.trim());
    setState(() => _isSavingNote = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note saved'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _updateStatus(ApplicationStatus newStatus) async {
    // If scheduling an interview, show a dialog to get date/time/location
    if (newStatus == ApplicationStatus.interview) {
      final data = await _showInterviewDialog();
      if (data == null) return; // cancelled
      await _doUpdateStatus(newStatus,
          message: 'Interview Scheduled',
          interviewDate: data['date'],
          interviewLocation: data['location'],
          interviewInstructions: data['instructions']);
      return;
    }

    // If rejecting, optionally get a reason
    if (newStatus == ApplicationStatus.rejected) {
      final reason = await _showRejectionDialog();
      if (reason == null) return; // cancelled
      await _doUpdateStatus(newStatus,
          message: 'Application rejected', rejectionReason: reason);
      return;
    }

    // Otherwise, generic update
    final actionLabel = applicationStatusLabel(newStatus);
    final confirmed = await _confirmAction('Mark as $actionLabel?');
    if (confirmed) {
      await _doUpdateStatus(newStatus, message: 'Status updated to $actionLabel');
    }
  }

  Future<void> _doUpdateStatus(ApplicationStatus newStatus,
      {String? message,
      String? rejectionReason,
      DateTime? interviewDate,
      String? interviewLocation,
      String? interviewInstructions}) async {
    final prov = context.read<OwnerJobProvider>();
    final auth = context.read<AuthProvider>();

    final success = await prov.updateApplicantStatus(
      applicationId: widget.application.applicationId,
      newStatus: newStatus,
      changedBy: auth.currentUser!.id,
      jobId: widget.application.jobId,
      message: message,
      rejectionReason: rejectionReason,
      interviewDate: interviewDate,
      interviewLocation: interviewLocation,
      interviewInstructions: interviewInstructions,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context); // Go back to applicants list
    }
  }

  Future<bool> _confirmAction(String title) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    return res ?? false;
  }

  Future<Map<String, dynamic>?> _showInterviewDialog() async {
    final locController = TextEditingController();
    final instController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              title: const Text('Schedule Interview', style: TextStyle(color: AppColors.textPrimary)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(const Duration(days: 1)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                              );
                              if (d != null) setState(() => selectedDate = d);
                            },
                            child: Text(selectedDate != null
                                ? '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}'
                                : 'Select Date'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(hour: 10, minute: 0),
                              );
                              if (t != null) setState(() => selectedTime = t);
                            },
                            child: Text(selectedTime != null
                                ? selectedTime!.format(context)
                                : 'Select Time'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locController,
                      decoration: const InputDecoration(
                        hintText: 'Location (e.g. Gym branch or Zoom link)',
                        labelText: 'Location',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: instController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Any special instructions?',
                        labelText: 'Instructions (optional)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (selectedDate == null || selectedTime == null || locController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill date, time, and location')));
                      return;
                    }
                    final combinedDate = DateTime(
                      selectedDate!.year, selectedDate!.month, selectedDate!.day,
                      selectedTime!.hour, selectedTime!.minute,
                    );
                    Navigator.pop(ctx, {
                      'date': combinedDate,
                      'location': locController.text.trim(),
                      'instructions': instController.text.trim(),
                    });
                  },
                  child: const Text('Schedule'),
                ),
              ],
            );
          },
        );
      },
    );
    return result;
  }

  Future<String?> _showRejectionDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Reject Application', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection (optional, visible to applicant)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    final prov = context.watch<OwnerJobProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Applicant Review')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(AppPadding.md),
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.surfaceElevated,
                    backgroundImage: app.applicantProfileImageUrl.isNotEmpty
                        ? NetworkImage(app.applicantProfileImageUrl)
                        : null,
                    child: app.applicantProfileImageUrl.isEmpty
                        ? const Icon(Icons.person, color: AppColors.textMuted, size: 32)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.applicantName,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(app.applicantEmail,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ],
                        ),
                        if (app.applicantPhone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(app.applicantPhone,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Status and Actions
              _sectionTitle('Application Status'),
              const SizedBox(height: 8),
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
                    Row(
                      children: [
                        _appStatusBadge(app.status),
                        const Spacer(),
                        if (app.submittedAt != null)
                          Text('Applied ${_formatDate(app.submittedAt!)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Actions based on valid transitions
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _buildActionButtons(app.status),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Private Note
              _sectionTitle('Private Note (Visible to you only)'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add private notes about this applicant...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: IconButton(
                      icon: _isSavingNote
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_rounded, color: AppColors.primary),
                      onPressed: _isSavingNote ? null : _saveNote,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Application Content
              _sectionTitle('Cover Message'),
              const SizedBox(height: 8),
              _contentBox(app.coverMessage),
              const SizedBox(height: 16),

              if (app.experience.isNotEmpty) ...[
                _sectionTitle('Experience'),
                const SizedBox(height: 8),
                _contentBox(app.experience),
                const SizedBox(height: 16),
              ],

              if (app.education.isNotEmpty) ...[
                _sectionTitle('Education'),
                const SizedBox(height: 8),
                _contentBox(app.education),
                const SizedBox(height: 16),
              ],

              if (app.skills.isNotEmpty) ...[
                _sectionTitle('Skills'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: app.skills.map((s) => _chip(s)).toList(),
                ),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Availability'),
                        const SizedBox(height: 4),
                        Text(app.availability.isNotEmpty ? app.availability : 'Not specified',
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Expected Salary'),
                        const SizedBox(height: 4),
                        Text(app.expectedSalary != null ? '₱${app.expectedSalary!.toStringAsFixed(0)}' : 'Not specified',
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Documents
              _sectionTitle('Documents'),
              const SizedBox(height: 8),
              if (app.resumeUrl != null && app.resumeUrl!.isNotEmpty)
                _documentTile(app.resumeFileName ?? 'Resume', app.resumeUrl!),
              if (app.supportingDocumentUrl != null && app.supportingDocumentUrl!.isNotEmpty)
                _documentTile('Supporting Document', app.supportingDocumentUrl!),

              const SizedBox(height: AppPadding.xl),
            ],
          ),
          if (prov.isSubmitting)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(ApplicationStatus currentStatus) {
    if (currentStatus == ApplicationStatus.withdrawn) {
      return [const Text('Applicant withdrew this application.', style: TextStyle(color: AppColors.textMuted))];
    }
    if (currentStatus == ApplicationStatus.accepted) {
      return [const Text('Applicant accepted!', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold))];
    }
    if (currentStatus == ApplicationStatus.rejected) {
      return [const Text('Application rejected.', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))];
    }

    final buttons = <Widget>[];

    if (isValidStatusTransition(currentStatus, ApplicationStatus.underReview)) {
      buttons.add(_actionBtn('Mark Under Review', Colors.orange, () => _updateStatus(ApplicationStatus.underReview)));
    }
    if (isValidStatusTransition(currentStatus, ApplicationStatus.shortlisted)) {
      buttons.add(_actionBtn('Shortlist', AppColors.primary, () => _updateStatus(ApplicationStatus.shortlisted)));
    }
    if (isValidStatusTransition(currentStatus, ApplicationStatus.interview)) {
      buttons.add(_actionBtn('Schedule Interview', Colors.purple, () => _updateStatus(ApplicationStatus.interview)));
    }
    if (isValidStatusTransition(currentStatus, ApplicationStatus.accepted)) {
      buttons.add(_actionBtn('Accept Applicant', AppColors.success, () => _updateStatus(ApplicationStatus.accepted)));
    }
    if (isValidStatusTransition(currentStatus, ApplicationStatus.rejected)) {
      buttons.add(_actionBtn('Reject', AppColors.error, () => _updateStatus(ApplicationStatus.rejected)));
    }

    return buttons;
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted));

  Widget _contentBox(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4)),
      );

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
      );

  Widget _documentTile(String name, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: AppColors.border)),
        tileColor: AppColors.surface,
        leading: const Icon(Icons.file_present_rounded, color: AppColors.primary),
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.textSecondary),
        onTap: () => _launchUrl(url),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Text(applicationStatusLabel(status),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}
