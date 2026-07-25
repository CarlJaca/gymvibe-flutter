import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/gym_provider.dart';

class OwnerEditProfileScreen extends StatefulWidget {
  const OwnerEditProfileScreen({super.key});

  @override
  State<OwnerEditProfileScreen> createState() => _OwnerEditProfileScreenState();
}

class _OwnerEditProfileScreenState extends State<OwnerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _imageUrlCtrl;
  late TextEditingController _descriptionCtrl;
  late TextEditingController _facilityInputCtrl;
  List<String> _facilitiesList = [];
  late TextEditingController _categoryInputCtrl;
  List<String> _categoriesList = [];
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _hoursCtrl;
  late TextEditingController _monthlyPriceCtrl;
  late TextEditingController _sessionPriceCtrl;
  late TextEditingController _facebookCtrl;
  late TextEditingController _emailCtrl;

  // Schedule controllers
  late TextEditingController _monCtrl;
  late TextEditingController _tueCtrl;
  late TextEditingController _wedCtrl;
  late TextEditingController _thuCtrl;
  late TextEditingController _friCtrl;
  late TextEditingController _satCtrl;
  late TextEditingController _sunCtrl;

  @override
  void initState() {
    super.initState();
    final gym = context.read<GymProvider>().ownerGym;

    _nameCtrl = TextEditingController(text: gym.name);
    _imageUrlCtrl = TextEditingController(text: gym.imageUrl);
    _descriptionCtrl = TextEditingController(text: gym.description);
    
    _facilitiesList = List<String>.from(gym.facilities);
    _facilityInputCtrl = TextEditingController();

    _categoriesList = List<String>.from(gym.categories);
    _categoryInputCtrl = TextEditingController();

    _addressCtrl = TextEditingController(text: gym.address);
    _cityCtrl = TextEditingController(text: gym.city);
    _hoursCtrl = TextEditingController(text: gym.hours);
    _monthlyPriceCtrl = TextEditingController(text: gym.monthlyPrice);
    _sessionPriceCtrl = TextEditingController(text: gym.sessionPrice);
    _facebookCtrl = TextEditingController(text: gym.socials['Facebook'] ?? '');
    _emailCtrl = TextEditingController(text: gym.socials['Email'] ?? '');

    _monCtrl = TextEditingController(text: gym.dailySchedule['Monday'] ?? '');
    _tueCtrl = TextEditingController(text: gym.dailySchedule['Tuesday'] ?? '');
    _wedCtrl = TextEditingController(text: gym.dailySchedule['Wednesday'] ?? '');
    _thuCtrl = TextEditingController(text: gym.dailySchedule['Thursday'] ?? '');
    _friCtrl = TextEditingController(text: gym.dailySchedule['Friday'] ?? '');
    _satCtrl = TextEditingController(text: gym.dailySchedule['Saturday'] ?? '');
    _sunCtrl = TextEditingController(text: gym.dailySchedule['Sunday'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _imageUrlCtrl.dispose();
    _descriptionCtrl.dispose();
    _facilityInputCtrl.dispose();
    _categoryInputCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _hoursCtrl.dispose();
    _monthlyPriceCtrl.dispose();
    _sessionPriceCtrl.dispose();
    _facebookCtrl.dispose();
    _emailCtrl.dispose();
    _monCtrl.dispose();
    _tueCtrl.dispose();
    _wedCtrl.dispose();
    _thuCtrl.dispose();
    _friCtrl.dispose();
    _satCtrl.dispose();
    _sunCtrl.dispose();
    super.dispose();
  }

  void _showMultiSelectSheet(String title, List<String> options, Set<String> currentValues, Function(Set<String>) onUpdate) {
    Set<String> tempValues = Set.from(currentValues);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select $title',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: options.map((option) {
                          final isSelected = tempValues.contains(option);
                          return CheckboxListTile(
                            title: Text(option, style: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            )),
                            value: isSelected,
                            activeColor: AppColors.primary,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  tempValues.add(option);
                                } else {
                                  tempValues.remove(option);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            onUpdate(tempValues);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Save Selection', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<GymProvider>();
    final gym = provider.ownerGym;

    final schedule = <String, String>{};
    if (_monCtrl.text.trim().isNotEmpty) schedule['Monday'] = _monCtrl.text.trim();
    if (_tueCtrl.text.trim().isNotEmpty) schedule['Tuesday'] = _tueCtrl.text.trim();
    if (_wedCtrl.text.trim().isNotEmpty) schedule['Wednesday'] = _wedCtrl.text.trim();
    if (_thuCtrl.text.trim().isNotEmpty) schedule['Thursday'] = _thuCtrl.text.trim();
    if (_friCtrl.text.trim().isNotEmpty) schedule['Friday'] = _friCtrl.text.trim();
    if (_satCtrl.text.trim().isNotEmpty) schedule['Saturday'] = _satCtrl.text.trim();
    if (_sunCtrl.text.trim().isNotEmpty) schedule['Sunday'] = _sunCtrl.text.trim();

    final socials = <String, String>{};
    if (_facebookCtrl.text.trim().isNotEmpty) socials['Facebook'] = _facebookCtrl.text.trim();
    if (_emailCtrl.text.trim().isNotEmpty) socials['Email'] = _emailCtrl.text.trim();

    final updatedGym = gym.copyWith(
      name: _nameCtrl.text.trim(),
      imageUrl: _imageUrlCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      categories: _categoriesList,
      facilities: _facilitiesList,
      address: _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      hours: _hoursCtrl.text.trim(),
      monthlyPrice: _monthlyPriceCtrl.text.trim(),
      sessionPrice: _sessionPriceCtrl.text.trim(),
      dailySchedule: schedule,
      socials: socials,
    );

    provider.updateOwnerGym(updatedGym);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppColors.success),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Gym Profile'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Consumer<GymProvider>(
        builder: (context, gymProv, _) {
          if (gymProv.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppPadding.md),
              children: [
            // ── Basic Info ────────────────────────────────────
            _sectionHeader('Basic Information'),
            const SizedBox(height: AppPadding.sm),
            _buildTextField(
              controller: _nameCtrl,
              label: 'Gym Name',
              icon: Icons.storefront_rounded,
              validator: (v) => v!.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _imageUrlCtrl,
              label: 'Cover Image URL',
              icon: Icons.image_outlined,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _descriptionCtrl,
              label: 'About Description',
              icon: Icons.description_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: AppPadding.lg),

            // ── Location ──────────────────────────────────────
            _sectionHeader('Location'),
            const SizedBox(height: AppPadding.sm),
            _buildTextField(
              controller: _addressCtrl,
              label: 'Full Address',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _cityCtrl,
              label: 'City',
              icon: Icons.location_city_outlined,
            ),
            const SizedBox(height: AppPadding.lg),

            // ── Price ─────────────────────────────────────────
            _sectionHeader('Pricing'),
            const SizedBox(height: AppPadding.sm),
            _buildTextField(
              controller: _monthlyPriceCtrl,
              label: 'Monthly Price',
              icon: Icons.payments_outlined,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _sessionPriceCtrl,
              label: 'Session Price',
              icon: Icons.attach_money_rounded,
            ),
            const SizedBox(height: AppPadding.lg),

            // ── Categories ───────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionHeader('Categories'),
                TextButton.icon(
                  onPressed: () => _showMultiSelectSheet(
                    'Categories',
                    ['Gym', 'Yoga', 'CrossFit', 'Boxing', 'Martial Arts', 'Cardio', 'Strength Training', 'Pilates', 'Zumba'],
                    _categoriesList.toSet(),
                    (val) {
                      setState(() {
                        _categoriesList = val.toList();
                      });
                    },
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Select'),
                ),
              ],
            ),
            if (_categoriesList.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categoriesList.map((c) {
                  return Chip(
                    label: Text(c, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                  );
                }).toList(),
              ),
            if (_categoriesList.isEmpty)
              const Text('No categories selected.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: AppPadding.lg),

            // ── Facilities ───────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionHeader('Facilities'),
                TextButton.icon(
                  onPressed: () => _showMultiSelectSheet(
                    'Facilities',
                    ['Cardio', 'Free Weights', 'Machines', 'Locker Room', 'Shower Area', 'Sauna', 'Pool', 'Personal Trainers', 'Yoga Studio', 'Boxing', 'Parking', 'WiFi', 'AC', 'Group Classes', 'Kids Area', 'Nutrition Bar'],
                    _facilitiesList.toSet(),
                    (val) {
                      setState(() {
                        _facilitiesList = val.toList();
                      });
                    },
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Select'),
                ),
              ],
            ),
            if (_facilitiesList.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _facilitiesList.map((f) {
                  return Chip(
                    label: Text(f, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                  );
                }).toList(),
              ),
            if (_facilitiesList.isEmpty)
              const Text('No facilities selected.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: AppPadding.lg),

            // ── Schedule ──────────────────────────────────────
            _sectionHeader('Operating Schedule'),
            const SizedBox(height: AppPadding.sm),
            _scheduleRow('Monday', _monCtrl),
            _scheduleRow('Tuesday', _tueCtrl),
            _scheduleRow('Wednesday', _wedCtrl),
            _scheduleRow('Thursday', _thuCtrl),
            _scheduleRow('Friday', _friCtrl),
            _scheduleRow('Saturday', _satCtrl),
            _scheduleRow('Sunday', _sunCtrl),
            const SizedBox(height: AppPadding.lg),

            // ── Socials ───────────────────────────────────────
            _sectionHeader('Socials'),
            const SizedBox(height: AppPadding.sm),
            _buildTextField(
              controller: _facebookCtrl,
              label: 'Facebook',
              icon: Icons.facebook_rounded,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _emailCtrl,
              label: 'Email',
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: AppPadding.xl),

            // ── Save Button ─────────────────────────────────
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Changes', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: AppPadding.xl),
          ],
        ),
      );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _scheduleRow(String day, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(day,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: TextFormField(
              controller: ctrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. 5 AM–12 AM',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: maxLines == 1 ? Icon(icon) : null,
        alignLabelWithHint: true,
      ),
    );
  }
}
