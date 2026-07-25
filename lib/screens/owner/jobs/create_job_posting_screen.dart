import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/job_posting_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/gym_provider.dart';
import '../../../providers/owner_job_provider.dart';

class CreateJobPostingScreen extends StatefulWidget {
  const CreateJobPostingScreen({super.key});

  @override
  State<CreateJobPostingScreen> createState() => _CreateJobPostingScreenState();
}

class _CreateJobPostingScreenState extends State<CreateJobPostingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _minSalaryController = TextEditingController();
  final _maxSalaryController = TextEditingController();
  final _openingsController = TextEditingController(text: '1');

  // List controllers
  final _responsibilityController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _skillController = TextEditingController();
  final _benefitController = TextEditingController();

  String _selectedCategory = jobCategories.first;
  EmploymentType _employmentType = EmploymentType.fullTime;
  WorkSetup _workSetup = WorkSetup.onsite;
  SalaryType _salaryType = SalaryType.negotiable;
  SalaryPeriod _salaryPeriod = SalaryPeriod.monthly;
  DateTime? _deadline;

  final List<String> _responsibilities = [];
  final List<String> _qualifications = [];
  final List<String> _skills = [];
  final List<String> _benefits = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gym = context.read<GymProvider>().ownerGym;
      _locationController.text = gym.address;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    _openingsController.dispose();
    _responsibilityController.dispose();
    _qualificationController.dispose();
    _skillController.dispose();
    _benefitController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surfaceElevated,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  JobPostingModel _buildJob(JobStatus status) {
    final auth = context.read<AuthProvider>();
    final gym = context.read<GymProvider>().ownerGym;

    return JobPostingModel(
      jobId: '',
      gymId: gym.id,
      ownerId: auth.currentUser!.id,
      gymName: gym.name,
      gymLogoUrl: gym.imageUrl,
      jobTitle: _titleController.text.trim(),
      jobCategory: _selectedCategory,
      employmentType: _employmentType,
      workSetup: _workSetup,
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      responsibilities: _responsibilities,
      qualifications: _qualifications,
      requiredSkills: _skills,
      salaryType: _salaryType,
      minimumSalary: double.tryParse(_minSalaryController.text.trim()),
      maximumSalary: double.tryParse(_maxSalaryController.text.trim()),
      salaryPeriod: _salaryPeriod,
      benefits: _benefits,
      numberOfOpenings: int.tryParse(_openingsController.text.trim()) ?? 1,
      applicationDeadline: _deadline,
      status: status,
    );
  }

  Future<void> _saveAsDraft() async {
    final prov = context.read<OwnerJobProvider>();
    final job = _buildJob(JobStatus.draft);
    final id = await prov.createJobPosting(job);
    if (id != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved as draft'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_qualifications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one qualification.'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_deadline != null && _deadline!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deadline must be in the future.'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_salaryType == SalaryType.range) {
      final min = double.tryParse(_minSalaryController.text.trim()) ?? 0;
      final max = double.tryParse(_maxSalaryController.text.trim()) ?? 0;
      if (min > max) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Minimum salary cannot exceed maximum.'), backgroundColor: AppColors.error),
        );
        return;
      }
    }

    final prov = context.read<OwnerJobProvider>();
    final job = _buildJob(JobStatus.active);
    final id = await prov.createJobPosting(job);
    if (id != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job published successfully!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } else if (mounted && prov.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(prov.errorMessage!), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OwnerJobProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Job Posting'),
        actions: [
          TextButton(
            onPressed: prov.isSubmitting ? null : _saveAsDraft,
            child: const Text('Save Draft'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppPadding.md),
          children: [
            // Job Title
            _label('Job Title *'),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'e.g. Fitness Trainer'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Job title is required' : null,
            ),
            const SizedBox(height: 14),

            // Category
            _label('Job Category'),
            _buildDropdown<String>(
              value: _selectedCategory,
              items: jobCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 14),

            // Employment type
            _label('Employment Type'),
            _buildDropdown<EmploymentType>(
              value: _employmentType,
              items: EmploymentType.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(employmentTypeLabel(e))))
                  .toList(),
              onChanged: (v) => setState(() => _employmentType = v!),
            ),
            const SizedBox(height: 14),

            // Work setup
            _label('Work Setup'),
            _buildDropdown<WorkSetup>(
              value: _workSetup,
              items: WorkSetup.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(workSetupLabel(e))))
                  .toList(),
              onChanged: (v) => setState(() => _workSetup = v!),
            ),
            const SizedBox(height: 14),

            // Location
            _label('Location'),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(hintText: 'e.g. Davao City'),
            ),
            const SizedBox(height: 14),

            // Description
            _label('Job Description *'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'Describe the role...'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
            ),
            const SizedBox(height: 14),

            // Responsibilities
            _listSection('Responsibilities', _responsibilities, _responsibilityController),
            const SizedBox(height: 14),

            // Qualifications
            _listSection('Qualifications *', _qualifications, _qualificationController),
            const SizedBox(height: 14),

            // Skills
            _listSection('Required Skills', _skills, _skillController),
            const SizedBox(height: 14),

            // Salary
            _label('Salary Type'),
            _buildDropdown<SalaryType>(
              value: _salaryType,
              items: const [
                DropdownMenuItem(value: SalaryType.fixed, child: Text('Fixed')),
                DropdownMenuItem(value: SalaryType.range, child: Text('Range')),
                DropdownMenuItem(value: SalaryType.negotiable, child: Text('Negotiable')),
                DropdownMenuItem(value: SalaryType.notDisclosed, child: Text('Not Disclosed')),
              ],
              onChanged: (v) => setState(() => _salaryType = v!),
            ),
            if (_salaryType == SalaryType.fixed || _salaryType == SalaryType.range) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minSalaryController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: _salaryType == SalaryType.fixed ? 'Amount' : 'Min',
                        prefixText: '₱ ',
                      ),
                    ),
                  ),
                  if (_salaryType == SalaryType.range) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _maxSalaryController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'Max', prefixText: '₱ '),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              _label('Salary Period'),
              _buildDropdown<SalaryPeriod>(
                value: _salaryPeriod,
                items: SalaryPeriod.values
                    .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.name[0].toUpperCase() + e.name.substring(1))))
                    .toList(),
                onChanged: (v) => setState(() => _salaryPeriod = v!),
              ),
            ],
            const SizedBox(height: 14),

            // Benefits
            _listSection('Benefits', _benefits, _benefitController),
            const SizedBox(height: 14),

            // Openings
            _label('Number of Openings'),
            TextFormField(
              controller: _openingsController,
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1) return 'Must be at least 1';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Deadline
            _label('Application Deadline'),
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      _deadline != null ? _formatDate(_deadline!) : 'Select deadline',
                      style: TextStyle(
                        fontSize: 14,
                        color: _deadline != null ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Publish button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: prov.isSubmitting ? null : _publish,
                child: prov.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Publish Job', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: AppPadding.xl),
          ],
        ),
      ),
    );
  }

  Widget _listSection(String title, List<String> items, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(title),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(hintText: 'Add ${title.replaceAll(' *', '').toLowerCase()}...'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  setState(() => items.add(text));
                  controller.clear();
                }
              },
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.asMap().entries.map((e) {
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
                    Text(e.value,
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() => items.removeAt(e.key)),
                      child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textMuted),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surfaceElevated,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}
