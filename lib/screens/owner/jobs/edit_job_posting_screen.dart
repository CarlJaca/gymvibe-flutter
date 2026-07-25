import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/job_posting_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/owner_job_provider.dart';

class EditJobPostingScreen extends StatefulWidget {
  final JobPostingModel job;
  const EditJobPostingScreen({super.key, required this.job});

  @override
  State<EditJobPostingScreen> createState() => _EditJobPostingScreenState();
}

class _EditJobPostingScreenState extends State<EditJobPostingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _minSalaryController;
  late final TextEditingController _maxSalaryController;
  late final TextEditingController _openingsController;

  final _responsibilityController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _skillController = TextEditingController();
  final _benefitController = TextEditingController();

  late String _selectedCategory;
  late EmploymentType _employmentType;
  late WorkSetup _workSetup;
  late SalaryType _salaryType;
  late SalaryPeriod _salaryPeriod;
  DateTime? _deadline;

  late List<String> _responsibilities;
  late List<String> _qualifications;
  late List<String> _skills;
  late List<String> _benefits;

  @override
  void initState() {
    super.initState();
    final j = widget.job;
    _titleController = TextEditingController(text: j.jobTitle);
    _descriptionController = TextEditingController(text: j.description);
    _locationController = TextEditingController(text: j.location);
    _minSalaryController =
        TextEditingController(text: j.minimumSalary?.toStringAsFixed(0) ?? '');
    _maxSalaryController =
        TextEditingController(text: j.maximumSalary?.toStringAsFixed(0) ?? '');
    _openingsController =
        TextEditingController(text: j.numberOfOpenings.toString());
    _selectedCategory = j.jobCategory;
    _employmentType = j.employmentType;
    _workSetup = j.workSetup;
    _salaryType = j.salaryType;
    _salaryPeriod = j.salaryPeriod ?? SalaryPeriod.monthly;
    _deadline = j.applicationDeadline;
    _responsibilities = List<String>.from(j.responsibilities);
    _qualifications = List<String>.from(j.qualifications);
    _skills = List<String>.from(j.requiredSkills);
    _benefits = List<String>.from(j.benefits);
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final prov = context.read<OwnerJobProvider>();

    final data = <String, dynamic>{
      'jobTitle': _titleController.text.trim(),
      'jobCategory': _selectedCategory,
      'employmentType': employmentTypeToString(_employmentType),
      'workSetup': workSetupToString(_workSetup),
      'location': _locationController.text.trim(),
      'description': _descriptionController.text.trim(),
      'responsibilities': _responsibilities,
      'qualifications': _qualifications,
      'requiredSkills': _skills,
      'salaryType': salaryTypeToString(_salaryType),
      'benefits': _benefits,
      'numberOfOpenings': int.tryParse(_openingsController.text.trim()) ?? 1,
    };

    if (_salaryType == SalaryType.fixed || _salaryType == SalaryType.range) {
      data['minimumSalary'] = double.tryParse(_minSalaryController.text.trim());
      data['salaryPeriod'] = salaryPeriodToString(_salaryPeriod);
      if (_salaryType == SalaryType.range) {
        data['maximumSalary'] = double.tryParse(_maxSalaryController.text.trim());
      }
    }

    if (_deadline != null) {
      data['applicationDeadline'] = _deadline;
    }

    final success =
        await prov.updateJobPosting(widget.job.jobId, data, auth.currentUser!.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Job updated successfully.'),
            backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } else if (mounted && prov.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(prov.errorMessage!),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OwnerJobProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Job Posting')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppPadding.md),
          children: [
            _label('Job Title *'),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'e.g. Fitness Trainer'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            _label('Job Category'),
            _buildDropdown<String>(
              value: _selectedCategory,
              items: jobCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 14),

            _label('Employment Type'),
            _buildDropdown<EmploymentType>(
              value: _employmentType,
              items: EmploymentType.values
                  .map((e) => DropdownMenuItem(
                      value: e, child: Text(employmentTypeLabel(e))))
                  .toList(),
              onChanged: (v) => setState(() => _employmentType = v!),
            ),
            const SizedBox(height: 14),

            _label('Work Setup'),
            _buildDropdown<WorkSetup>(
              value: _workSetup,
              items: WorkSetup.values
                  .map((e) => DropdownMenuItem(
                      value: e, child: Text(workSetupLabel(e))))
                  .toList(),
              onChanged: (v) => setState(() => _workSetup = v!),
            ),
            const SizedBox(height: 14),

            _label('Location'),
            TextFormField(
              controller: _locationController,
              decoration:
                  const InputDecoration(hintText: 'e.g. Davao City'),
            ),
            const SizedBox(height: 14),

            _label('Job Description *'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration:
                  const InputDecoration(hintText: 'Describe the role...'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            _listSection('Responsibilities', _responsibilities,
                _responsibilityController),
            const SizedBox(height: 14),
            _listSection('Qualifications', _qualifications,
                _qualificationController),
            const SizedBox(height: 14),
            _listSection('Required Skills', _skills, _skillController),
            const SizedBox(height: 14),

            _label('Salary Type'),
            _buildDropdown<SalaryType>(
              value: _salaryType,
              items: const [
                DropdownMenuItem(
                    value: SalaryType.fixed, child: Text('Fixed')),
                DropdownMenuItem(
                    value: SalaryType.range, child: Text('Range')),
                DropdownMenuItem(
                    value: SalaryType.negotiable,
                    child: Text('Negotiable')),
                DropdownMenuItem(
                    value: SalaryType.notDisclosed,
                    child: Text('Not Disclosed')),
              ],
              onChanged: (v) => setState(() => _salaryType = v!),
            ),
            if (_salaryType == SalaryType.fixed ||
                _salaryType == SalaryType.range) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minSalaryController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText:
                            _salaryType == SalaryType.fixed ? 'Amount' : 'Min',
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
                        decoration: const InputDecoration(
                            hintText: 'Max', prefixText: '₱ '),
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
                        child: Text(
                            e.name[0].toUpperCase() + e.name.substring(1))))
                    .toList(),
                onChanged: (v) => setState(() => _salaryPeriod = v!),
              ),
            ],
            const SizedBox(height: 14),

            _listSection('Benefits', _benefits, _benefitController),
            const SizedBox(height: 14),

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

            _label('Application Deadline'),
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      _deadline != null
                          ? _formatDate(_deadline!)
                          : 'Select deadline',
                      style: TextStyle(
                        fontSize: 14,
                        color: _deadline != null
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: prov.isSubmitting ? null : _save,
                child: prov.isSubmitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: AppPadding.xl),
          ],
        ),
      ),
    );
  }

  Widget _listSection(
      String title, List<String> items, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(title),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                    hintText: 'Add ${title.toLowerCase()}...'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_rounded,
                  color: AppColors.primary),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(e.value,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary)),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () =>
                          setState(() => items.removeAt(e.key)),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: AppColors.textMuted),
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
          style: const TextStyle(
              fontSize: 14, color: AppColors.textPrimary),
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary)),
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
