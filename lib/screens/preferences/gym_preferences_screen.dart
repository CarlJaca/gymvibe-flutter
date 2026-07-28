// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';

class GymPreferencesScreen extends StatefulWidget {
  /// If true, user arrived from login (first-time). If false, editing existing prefs.
  final bool isFirstTime;

  const GymPreferencesScreen({super.key, this.isFirstTime = true});

  @override
  State<GymPreferencesScreen> createState() => _GymPreferencesScreenState();
}

class _GymPreferencesScreenState extends State<GymPreferencesScreen> {
  // ── Location / Distance ──────────────────────────────────────────────
  double _distanceValue = 5.0; // km

  // ── Budget Range ─────────────────────────────────────────────────────
  String? _selectedBudget;
  static const List<String> _budgetOptions = [
    '₱0 – ₱500',
    '₱501 – ₱1,000',
    '₱1,001 – ₱1,500',
    '₱1,501 – ₱2,000',
    '₱2,001 – ₱3,000',
    '₱3,000+',
  ];

  // ── Facilities ───────────────────────────────────────────────────────
  final Set<String> _selectedFacilities = {};
  static const List<Map<String, dynamic>> _facilityOptions = [
    {'label': 'Free Weights', 'icon': Icons.fitness_center_rounded},
    {'label': 'Cardio Equipment', 'icon': Icons.directions_run_rounded},
    {'label': 'Machines', 'icon': Icons.precision_manufacturing_rounded},
    {'label': 'Group Classes', 'icon': Icons.groups_rounded},
    {'label': 'Locker Room', 'icon': Icons.lock_rounded},
    {'label': 'Shower', 'icon': Icons.shower_rounded},
    {'label': 'Parking', 'icon': Icons.local_parking_rounded},
    {'label': 'Swimming Pool', 'icon': Icons.pool_rounded},
    {'label': 'Sauna / Steam', 'icon': Icons.hot_tub_rounded},
    {'label': 'Functional Training Area', 'icon': Icons.sports_gymnastics_rounded},
    {'label': 'Boxing Area', 'icon': Icons.sports_mma_rounded},
  ];

  // ── Fitness Goals ────────────────────────────────────────────────────
  final Set<String> _selectedGoals = {};
  static const List<String> _goalOptions = [
    'Weight Loss',
    'Muscle Gain',
    'Strength',
    'General Fitness',
    'Rehabilitation',
    'Sports Performance',
  ];

  // ── Gym Type ─────────────────────────────────────────────────────────
  String _selectedGymType = 'Any';
  static const List<String> _gymTypeOptions = [
    'Any',
    'Commercial Gym',
    'Boutique / Specialty',
    'Private / Studio',
  ];

  // ── Trainer Availability ─────────────────────────────────────────────
  String _trainerPref = 'No Preference';
  static const List<String> _trainerOptions = [
    'Trainer Available',
    'No Preference',
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingPreferences();
  }

  void _loadExistingPreferences() {
    final auth = context.read<AuthProvider>();
    if (auth.currentUser == null) return;
    final prefs = auth.currentUser!.fitnessPreferences;
    if (prefs.isEmpty) return;

    for (final p in prefs) {
      if (p.startsWith('distance:')) {
        final distStr = p.substring(9).trim().toLowerCase();
        if (distStr.contains('5')) {
          _distanceValue = 5.0;
        } else if (distStr.contains('10')) {
          _distanceValue = 10.0;
        } else if (distStr.contains('any') || distStr.contains('20')) {
          _distanceValue = 20.0;
        }
      } else if (p.startsWith('budget:')) {
        _selectedBudget = p.substring(7).trim();
        // Match exact option
        for (final opt in _budgetOptions) {
          if (opt.toLowerCase() == _selectedBudget!.toLowerCase()) {
            _selectedBudget = opt;
            break;
          }
        }
      } else if (p.startsWith('facility:')) {
        final facility = p.substring(9).trim();
        // Find matching option (case-insensitive)
        for (final opt in _facilityOptions) {
          if ((opt['label'] as String).toLowerCase() == facility.toLowerCase()) {
            _selectedFacilities.add(opt['label'] as String);
            break;
          }
        }
      } else if (p.startsWith('goal:')) {
        final goal = p.substring(5).trim();
        for (final opt in _goalOptions) {
          if (opt.toLowerCase() == goal.toLowerCase()) {
            _selectedGoals.add(opt);
            break;
          }
        }
      } else if (p.startsWith('gymtype:')) {
        final type = p.substring(8).trim();
        for (final opt in _gymTypeOptions) {
          if (opt.toLowerCase() == type.toLowerCase()) {
            _selectedGymType = opt;
            break;
          }
        }
      } else if (p.startsWith('trainer:')) {
        final trainer = p.substring(8).trim();
        if (trainer.toLowerCase().contains('available')) {
          _trainerPref = 'Trainer Available';
        } else {
          _trainerPref = 'No Preference';
        }
      }
    }
  }

  List<String> _buildPreferencesList() {
    final prefs = <String>[];

    // Distance
    if (_distanceValue <= 5) {
      prefs.add('distance:Within 5 km');
    } else if (_distanceValue <= 10) {
      prefs.add('distance:Within 10 km');
    } else {
      prefs.add('distance:Any Distance');
    }

    // Budget
    if (_selectedBudget != null) {
      prefs.add('budget:$_selectedBudget');
    }

    // Facilities
    for (final f in _selectedFacilities) {
      prefs.add('facility:$f');
    }

    // Goals
    for (final g in _selectedGoals) {
      prefs.add('goal:$g');
    }

    // Gym type
    prefs.add('gymtype:$_selectedGymType');

    // Trainer
    if (_trainerPref == 'Trainer Available') {
      prefs.add('trainer:Available');
    } else {
      prefs.add('trainer:No Preference');
    }

    return prefs;
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    final prefs = _buildPreferencesList();

    // Save to auth provider / Firestore
    final auth = context.read<AuthProvider>();
    await auth.updateUserProfile({
      'fitnessPreferences': prefs,
      'hasCompletedPreferences': true,
    });

    // Update gym provider with new preferences
    if (mounted) {
      context.read<GymProvider>().setUserPreferences(prefs);
    }

    // Show calculating animation briefly
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (widget.isFirstTime) {
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: widget.isFirstTime
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'GYM VIBE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'DAVAO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              if (widget.isFirstTime)
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.main);
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title ──────────────────────────────────────────
                const Center(
                  child: Column(
                    children: [
                      Text(
                        'Your Gym Preferences',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tell us what matters most to you so we can\nfind the perfect gym.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── 1. Location / Distance ─────────────────────────
                _buildSectionHeader('1. Location', Icons.location_on_rounded),
                const SizedBox(height: 4),
                Text(
                  'How far are you willing to travel?',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _distanceValue >= 20
                          ? '20+ km'
                          : '${_distanceValue.toInt()} km',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.border,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withValues(alpha: 0.15),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _distanceValue,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    onChanged: (v) => setState(() => _distanceValue = v),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Near me', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text('10 km', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text('20+ km', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),

                const SizedBox(height: 28),

                // ── 2. Budget Range ────────────────────────────────
                _buildSectionHeader('2. Budget Range (Monthly)', Icons.account_balance_wallet_rounded),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _budgetOptions.map((opt) => _buildChip(
                    label: opt,
                    isSelected: _selectedBudget == opt,
                    onTap: () => setState(() => _selectedBudget = opt),
                  )).toList(),
                ),

                const SizedBox(height: 28),

                // ── 3. Facilities ──────────────────────────────────
                _buildSectionHeader('3. Facilities You Prefer', Icons.sports_gymnastics_rounded),
                const SizedBox(height: 4),
                Text(
                  'Select all that apply',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _facilityOptions.map((opt) {
                    final label = opt['label'] as String;
                    final icon = opt['icon'] as IconData;
                    final isSelected = _selectedFacilities.contains(label);
                    return _buildIconChip(
                      label: label,
                      icon: icon,
                      isSelected: isSelected,
                      onTap: () => setState(() {
                        if (isSelected) {
                          _selectedFacilities.remove(label);
                        } else {
                          _selectedFacilities.add(label);
                        }
                      }),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),

                // ── 4. Fitness Goals ───────────────────────────────
                _buildSectionHeader('4. Fitness Goals', Icons.flag_rounded),
                const SizedBox(height: 4),
                Text(
                  'Select up to 3',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _goalOptions.map((opt) {
                    final isSelected = _selectedGoals.contains(opt);
                    return _buildChip(
                      label: opt,
                      isSelected: isSelected,
                      onTap: () => setState(() {
                        if (isSelected) {
                          _selectedGoals.remove(opt);
                        } else if (_selectedGoals.length < 3) {
                          _selectedGoals.add(opt);
                        }
                      }),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),

                // ── 5. Preferred Gym Type ──────────────────────────
                _buildSectionHeader('5. Preferred Gym Type', Icons.store_rounded),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _gymTypeOptions.map((opt) => _buildChip(
                    label: opt,
                    isSelected: _selectedGymType == opt,
                    onTap: () => setState(() => _selectedGymType = opt),
                  )).toList(),
                ),

                const SizedBox(height: 28),

                // ── 6. Trainer Availability ────────────────────────
                _buildSectionHeader('6. Trainer Availability', Icons.person_rounded),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _trainerOptions.map((opt) => _buildChip(
                    label: opt,
                    isSelected: _trainerPref == opt,
                    onTap: () => setState(() => _trainerPref = opt),
                  )).toList(),
                ),

                const SizedBox(height: 32),

                // ── Footer note ────────────────────────────────────
                const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 14, color: AppColors.textMuted),
                      SizedBox(width: 6),
                      Text(
                        'Your preferences are saved securely',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom CTA ─────────────────────────────────────────────
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Save & Find My Match',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Calculating Overlay ────────────────────────────────────────
        if (_isSaving)
          Container(
            color: AppColors.background.withValues(alpha: 0.92),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Calculating your matches...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Finding gyms that match your preferences\nusing Jaccard Similarity Algorithm',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
            ],
          ],
        ),
      ),
    );
  }
}
