import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../models/job_posting_model.dart';
import '../../models/job_application_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_application_provider.dart';

class JobApplicationScreen extends StatefulWidget {
  final JobPostingModel job;
  const JobApplicationScreen({super.key, required this.job});

  @override
  State<JobApplicationScreen> createState() => _JobApplicationScreenState();
}

class _JobApplicationScreenState extends State<JobApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coverController = TextEditingController();
  final _experienceController = TextEditingController();
  final _educationController = TextEditingController();
  final _skillsController = TextEditingController();
  final _availabilityController = TextEditingController();
  final _expectedSalaryController = TextEditingController();

  String? _resumePath;
  String? _resumeFileName;
  String? _supportDocPath;
  String? _supportDocName;
  bool _consentChecked = false;
  bool _showPreview = false;

  @override
  void dispose() {
    _coverController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _skillsController.dispose();
    _availabilityController.dispose();
    _expectedSalaryController.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must not exceed 10 MB.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
        setState(() {
          _resumePath = file.path;
          _resumeFileName = file.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking resume: $e');
    }
  }

  Future<void> _pickSupportingDoc() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must not exceed 10 MB.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
        setState(() {
          _supportDocPath = file.path;
          _supportDocName = file.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking supporting document: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_consentChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm that the information is accurate.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_resumePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your resume.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final appProv = context.read<JobApplicationProvider>();
    final user = auth.currentUser!;
    final job = widget.job;

    // Build skills list
    final skills = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final application = JobApplicationModel(
      applicationId: '',
      jobId: job.jobId,
      jobTitle: job.jobTitle,
      gymId: job.gymId,
      gymName: job.gymName,
      ownerId: job.ownerId,
      applicantId: user.id,
      applicantName: user.name,
      applicantEmail: user.email,
      applicantPhone: user.contactNumber ?? '',
      applicantProfileImageUrl: user.avatarUrl,
      coverMessage: _coverController.text.trim(),
      experience: _experienceController.text.trim(),
      education: _educationController.text.trim(),
      skills: skills,
      availability: _availabilityController.text.trim(),
      expectedSalary: double.tryParse(_expectedSalaryController.text.trim()),
      resumeFileName: _resumeFileName,
    );

    final success = await appProv.submitApplication(application);

    if (success && mounted) {
      // Upload resume after application is created
      try {
        final appId = appProv.allApplications
            .firstWhere((a) => a.jobId == job.jobId)
            .applicationId;
        await appProv.uploadResume(
          applicantId: user.id,
          applicationId: appId,
          filePath: _resumePath!,
          fileName: _resumeFileName!,
        );
        if (_supportDocPath != null) {
          await appProv.uploadSupportingDocument(
            applicantId: user.id,
            applicationId: appId,
            filePath: _supportDocPath!,
            fileName: _supportDocName!,
          );
        }
      } catch (e) {
        debugPrint('File upload error: $e');
      }

      if (mounted) {
        _showSuccessDialog();
      }
    } else if (mounted && appProv.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appProv.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Application Submitted!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your application for ${widget.job.jobTitle} at ${widget.job.gymName} has been submitted.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // close dialog
                  Navigator.pop(context, true); // return success
                },
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final appProv = context.watch<JobApplicationProvider>();

    if (_showPreview) {
      return _buildPreview();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Job'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppPadding.md),
          children: [
            // Job info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.work_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.job.jobTitle,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary)),
                        Text(widget.job.gymName,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Pre-filled info ──────────────────────────────────────
            _label('Full Name'),
            _readOnlyField(user?.name ?? ''),
            const SizedBox(height: 12),
            _label('Email'),
            _readOnlyField(user?.email ?? ''),
            const SizedBox(height: 12),
            _label('Contact Number'),
            _readOnlyField(user?.contactNumber ?? 'Not set'),
            const SizedBox(height: 20),

            // ── Editable fields ──────────────────────────────────────
            _label('Cover Message *'),
            TextFormField(
              controller: _coverController,
              maxLines: 4,
              decoration: const InputDecoration(
                  hintText: 'Write a short introduction...'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Cover message is required' : null,
            ),
            const SizedBox(height: 14),

            _label('Relevant Experience'),
            TextFormField(
              controller: _experienceController,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Describe your relevant experience...'),
            ),
            const SizedBox(height: 14),

            _label('Education / Certification'),
            TextFormField(
              controller: _educationController,
              maxLines: 2,
              decoration: const InputDecoration(
                  hintText: 'e.g. BS Physical Education, NASM CPT...'),
            ),
            const SizedBox(height: 14),

            _label('Skills (comma-separated)'),
            TextFormField(
              controller: _skillsController,
              decoration: const InputDecoration(
                  hintText: 'e.g. Personal Training, First Aid, Nutrition'),
            ),
            const SizedBox(height: 14),

            _label('Availability'),
            TextFormField(
              controller: _availabilityController,
              decoration: const InputDecoration(
                  hintText: 'e.g. Weekdays, Morning shift'),
            ),
            const SizedBox(height: 14),

            _label('Expected Salary'),
            TextFormField(
              controller: _expectedSalaryController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  hintText: 'e.g. 15000', prefixText: '₱ '),
            ),
            const SizedBox(height: 20),

            // ── File uploads ─────────────────────────────────────────
            _label('Resume *'),
            _fileUploadButton(
              fileName: _resumeFileName,
              onTap: _pickResume,
              hint: 'Upload PDF or DOCX (max 10 MB)',
            ),
            const SizedBox(height: 14),

            _label('Supporting Document (optional)'),
            _fileUploadButton(
              fileName: _supportDocName,
              onTap: _pickSupportingDoc,
              hint: 'Upload PDF, DOCX, JPG, or PNG',
            ),
            const SizedBox(height: 20),

            // ── Consent ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _consentChecked,
                  onChanged: (v) =>
                      setState(() => _consentChecked = v ?? false),
                  activeColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _consentChecked = !_consentChecked),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'I confirm that the information provided is accurate and complete.',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Actions ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showPreview = true),
                    child: const Text('Preview'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: appProv.isSubmitting ? null : _submit,
                    child: appProv.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit Application'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppPadding.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final user = context.read<AuthProvider>().currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Application'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() => _showPreview = false),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppPadding.md),
        children: [
          _previewRow('Job', widget.job.jobTitle),
          _previewRow('Gym', widget.job.gymName),
          const Divider(color: AppColors.divider, height: 24),
          _previewRow('Name', user?.name ?? ''),
          _previewRow('Email', user?.email ?? ''),
          _previewRow('Phone', user?.contactNumber ?? 'Not set'),
          const Divider(color: AppColors.divider, height: 24),
          _previewRow('Cover Message', _coverController.text),
          _previewRow('Experience', _experienceController.text),
          _previewRow('Education', _educationController.text),
          _previewRow('Skills', _skillsController.text),
          _previewRow('Availability', _availabilityController.text),
          _previewRow(
              'Expected Salary',
              _expectedSalaryController.text.isNotEmpty
                  ? '₱${_expectedSalaryController.text}'
                  : 'Not specified'),
          _previewRow('Resume', _resumeFileName ?? 'Not uploaded'),
          _previewRow(
              'Supporting Doc', _supportDocName ?? 'None'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() => _showPreview = false),
            child: const Text('Edit Application'),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary)),
    );
  }

  Widget _readOnlyField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(value,
          style: const TextStyle(
              fontSize: 14, color: AppColors.textSecondary)),
    );
  }

  Widget _fileUploadButton({
    String? fileName,
    required VoidCallback onTap,
    required String hint,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: fileName != null ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              fileName != null
                  ? Icons.insert_drive_file_rounded
                  : Icons.upload_file_rounded,
              color: fileName != null
                  ? AppColors.primary
                  : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fileName ?? hint,
                style: TextStyle(
                  fontSize: 13,
                  color: fileName != null
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (fileName != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (fileName == _resumeFileName) {
                      _resumePath = null;
                      _resumeFileName = null;
                    } else {
                      _supportDocPath = null;
                      _supportDocName = null;
                    }
                  });
                },
                child: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}
