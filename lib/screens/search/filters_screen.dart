import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/gym_provider.dart';
import '../../widgets/filter_chip_widget.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  RangeValues _budgetRange = const RangeValues(0, 2000);
  String? _selectedLocation;
  String? _selectedGoal;
  String? _selectedTrainer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GymProvider>();
      setState(() {
        _budgetRange = provider.advancedBudgetRange ?? const RangeValues(0, 2000);
        
        if (provider.selectedCity != null && _locations.contains(provider.selectedCity)) {
          _selectedLocation = provider.selectedCity;
        } else if (provider.selectedCity == null) {
          _selectedLocation = 'Current Location';
        }
        
        _selectedGoal = provider.advancedFitnessGoal;
        _selectedTrainer = provider.advancedTrainerAvailability;
      });
    });
  }

  final List<String> _locations = [
    'Current Location',
    'Davao City Proper',
    'Buhangin',
    'Toril',
    'Matina',
  ];

  final List<String> _goals = [
    'Weight Loss',
    'Muscle Gain',
    'Strength Training',
    'Cardio & Endurance',
    'Flexibility',
    'General Fitness',
  ];

  final List<String> _trainerOptions = [
    'With Trainer',
    'Without Trainer',
    'Any',
  ];

  final List<String> _membershipTypes = [
    'Daily',
    'Monthly',
    'Quarterly',
    'Annual',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GymProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.sm, vertical: AppPadding.sm),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text(
                    'Find Your Gym',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Filter Content ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppPadding.sm),

                    // ── Location ─────────────────────────────────────
                    _buildSectionTitle('Location'),
                    const SizedBox(height: AppPadding.sm),
                    _buildDropdown(
                      hint: 'Select Location',
                      icon: Icons.location_on_outlined,
                      value: _selectedLocation,
                      items: _locations,
                      onChanged: (val) =>
                          setState(() => _selectedLocation = val),
                    ),
                    const SizedBox(height: AppPadding.lg),

                    // ── Fitness Goal ──────────────────────────────────
                    _buildSectionTitle('Fitness Goal'),
                    const SizedBox(height: AppPadding.sm),
                    _buildDropdown(
                      hint: 'Select Goal',
                      icon: Icons.flag_outlined,
                      value: _selectedGoal,
                      items: _goals,
                      onChanged: (val) =>
                          setState(() => _selectedGoal = val),
                    ),
                    const SizedBox(height: AppPadding.lg),

                    // ── Budget Range ──────────────────────────────────
                    _buildSectionTitle('Budget Range'),
                    const SizedBox(height: AppPadding.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₱${_budgetRange.start.toInt()}',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '₱${_budgetRange.end.toInt()}${_budgetRange.end >= 2000 ? '+' : ''}',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: _budgetRange,
                      min: 0,
                      max: 2000,
                      divisions: 20,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.border,
                      onChanged: (vals) =>
                          setState(() => _budgetRange = vals),
                    ),
                    const SizedBox(height: AppPadding.md),

                    // ── Available Facilities ──────────────────────────
                    _buildSectionTitle('Available Facilities'),
                    const SizedBox(height: AppPadding.sm),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        'Free Weights',
                        'Cardio Area',
                        'Locker Room',
                        'Shower',
                        'Sauna',
                        'Swimming Pool',
                        'Group Classes',
                        'Parking',
                      ].map((facility) {
                        return FilterChipWidget(
                          label: facility,
                          isSelected:
                              provider.activeFilters.contains(facility),
                          onTap: () => provider.toggleFilter(facility),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppPadding.lg),

                    // ── Trainer Availability ──────────────────────────
                    _buildSectionTitle('Trainer Availability'),
                    const SizedBox(height: AppPadding.sm),
                    _buildDropdown(
                      hint: 'Select Availability',
                      icon: Icons.person_outline_rounded,
                      value: _selectedTrainer,
                      items: _trainerOptions,
                      onChanged: (val) =>
                          setState(() => _selectedTrainer = val),
                    ),
                    const SizedBox(height: AppPadding.lg),

                    // ── Membership Type ───────────────────────────────
                    _buildSectionTitle('Membership Type'),
                    const SizedBox(height: AppPadding.sm),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _membershipTypes.map((type) {
                        return FilterChipWidget(
                          label: type,
                          isSelected:
                              provider.activeFilters.contains(type),
                          onTap: () => provider.toggleFilter(type),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppPadding.lg),

                    // ── Operating Hours ───────────────────────────────
                    _buildSectionTitle('Operating Hours'),
                    const SizedBox(height: AppPadding.sm),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        'Open 24 Hours',
                        'Morning (5AM–12PM)',
                        'Afternoon (12PM–6PM)',
                        'Evening (6PM–10PM)',
                      ].map((hour) {
                        return FilterChipWidget(
                          label: hour,
                          isSelected:
                              provider.activeFilters.contains(hour),
                          onTap: () => provider.toggleFilter(hour),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppPadding.xl),
                  ],
                ),
              ),
            ),

            // ── Footer CTA ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppPadding.md),
              child: Row(
                children: [
                  // Reset
                  OutlinedButton(
                    onPressed: () {
                      provider.clearAdvancedFilters();
                      setState(() {
                        _budgetRange = const RangeValues(0, 2000);
                        _selectedLocation = null;
                        _selectedGoal = null;
                        _selectedTrainer = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    child: const Text('Reset'),
                  ),
                  const SizedBox(width: 12),
                  // Apply Filters
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        provider.setAdvancedFilters(
                          budgetRange: _budgetRange,
                          trainer: _selectedTrainer,
                          goal: _selectedGoal,
                          location: _selectedLocation,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Text(hint,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 14)),
            ],
          ),
          isExpanded: true,
          dropdownColor: AppColors.surfaceElevated,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item,
                  style: const TextStyle(color: AppColors.textPrimary)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
