import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import 'dart:io';
import '../../providers/events_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/routes/app_router.dart';
import '../../services/storage_service.dart';
import 'package:file_picker/file_picker.dart';
import '../promotions/rewards_loyalty_screen.dart';
import 'personal_information_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Preference states — initialized from Firestore on first build
  Set<String> _fitnessGoals = {};
  String _budgetRange = '';
  String _trainerAvailability = '';
  Set<String> _preferredFacilities = {};
  bool _prefsInitialized = false;
  bool _isUploadingAvatar = false;

  Future<void> _uploadAvatar() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isUploadingAvatar = true);
        
        final file = File(result.files.single.path!);
        if (!mounted) return;
        final auth = context.read<AuthProvider>();
        
        if (auth.currentUser == null) return;
        
        final newUrl = await storageService.uploadUserAvatar(auth.currentUser!.id, file);
        
        await auth.updateUserProfile({'avatarUrl': newUrl});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated!'), backgroundColor: AppColors.success),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  /// Load saved preferences from the user's Firestore profile
  void _initPreferencesFromUser(AuthProvider auth) {
    if (_prefsInitialized || auth.currentUser == null) return;
    _prefsInitialized = true;

    final prefs = auth.currentUser!.fitnessPreferences;
    // Parse stored preferences back into categorized sets
    // We store all preferences in a single flat list with prefixes
    for (final p in prefs) {
      if (p.startsWith('goal:')) {
        _fitnessGoals.add(p.substring(5));
      } else if (p.startsWith('budget:')) {
        _budgetRange = p.substring(7);
      } else if (p.startsWith('trainer:')) {
        _trainerAvailability = p.substring(8);
      } else {
        // Facility/category preferences (no prefix) — these feed Jaccard
        _preferredFacilities.add(p);
      }
    }

    // Ensure sets are empty if nothing was saved
    if (_fitnessGoals.isEmpty) _fitnessGoals = {};
    if (_budgetRange.isEmpty) _budgetRange = '';
    if (_trainerAvailability.isEmpty) _trainerAvailability = '';
    if (_preferredFacilities.isEmpty) _preferredFacilities = {};
  }

  /// Save all preferences to Firestore and update GymProvider for Jaccard
  Future<void> _savePreferences() async {
    final auth = context.read<AuthProvider>();
    if (auth.currentUser == null) return;

    // Build flat list: facilities go unprefixed (for Jaccard), others prefixed
    final allPrefs = <String>[
      ..._fitnessGoals.map((g) => 'goal:$g'),
      'budget:$_budgetRange',
      'trainer:$_trainerAvailability',
      ..._preferredFacilities, // These are the Jaccard-comparable preferences
    ];

    // Save to Firestore
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(auth.currentUser!.id)
          .update({'fitnessPreferences': allPrefs});
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }

    // Update GymProvider so recommendations refresh immediately
    if (mounted) {
      final jaccardPrefs = [
        ..._fitnessGoals,
        ..._preferredFacilities,
      ];
      context.read<GymProvider>().setUserPreferences(jaccardPrefs);
    }
  }

  void _showPreferenceSheet(String title, List<String> options, String currentValue, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
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
              ...options.map((option) => ListTile(
                title: Text(
                  option,
                  style: TextStyle(
                    color: option == currentValue ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: option == currentValue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: option == currentValue
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  onSelect(option);
                  Navigator.pop(ctx);
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
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
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                            title: Text(
                              option,
                              style: TextStyle(
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            value: isSelected,
                            activeColor: AppColors.primary,
                            checkColor: Colors.white,
                            side: const BorderSide(color: AppColors.border),
                            onChanged: (bool? value) {
                              setModalState(() {
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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            _initPreferencesFromUser(auth);
            return ListView(
              padding: const EdgeInsets.all(AppPadding.md),
              children: [
                const SizedBox(height: 16),

                // ── Profile Header ──────────────────────────────────────
                Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: AppSizes.avatarXL / 2,
                          backgroundColor: AppColors.surfaceElevated,
                          backgroundImage: NetworkImage(auth.userAvatar),
                        ),
                        if (_isUploadingAvatar)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isUploadingAvatar ? null : _uploadAvatar,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.background, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      auth.userName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Fitness Enthusiast',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Edit Profile button
                    OutlinedButton(
                      onPressed: () => _showComingSoon('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: const Text('Edit Profile'),
                    ),
                  ],
                ),
                const SizedBox(height: AppPadding.xl),

                // ── Customer Dashboard ───────────────────────────────────
                _buildSectionTitle('My Dashboard'),
                const SizedBox(height: AppPadding.sm),
                Consumer2<EventsProvider, NotificationProvider>(
                  builder: (context, eventsProv, notifProv, _) {
                    final eventsJoined = eventsProv.myRegisteredEvents.length;
                    final notificationsCount = notifProv.customerNotifications.length;
                    const activeMemberships = 0; // Replace with actual logic when available
                    const bookings = 0;          // Replace with actual logic when available

                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.5,
                      children: [
                        _buildDashboardMetric('Memberships', activeMemberships.toString(), Icons.card_membership_rounded),
                        _buildDashboardMetric('Bookings', bookings.toString(), Icons.book_online_rounded),
                        _buildDashboardMetric('Events Joined', eventsJoined.toString(), Icons.event_available_rounded),
                        _buildDashboardMetric('Notifications', notificationsCount.toString(), Icons.notifications_active_rounded),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppPadding.xl),

                // ── My Preferences ──────────────────────────────────────
                _buildSectionTitle('My Preferences'),
                const SizedBox(height: AppPadding.sm),
                _buildPreferenceRow(
                    context, Icons.flag_outlined, 'Fitness Goal', _fitnessGoals.isEmpty ? 'Not Set' : '${_fitnessGoals.length} selected',
                     onTap: () => _showMultiSelectSheet(
                      'Fitness Goal',
                      ['Muscle Gain', 'Weight Loss', 'Endurance', 'Flexibility', 'General Fitness'],
                      _fitnessGoals,
                      (val) {
                        setState(() => _fitnessGoals = val);
                        _savePreferences();
                      },
                    )),
                _buildPreferenceRow(
                    context, Icons.payments_outlined, 'Budget Range', _budgetRange.isEmpty ? 'Not Set' : _budgetRange,
                    onTap: () => _showPreferenceSheet(
                      'Budget Range',
                      ['₱0 – ₱1,000', '₱1,000 – ₱2,000', '₱2,000 – ₱5,000', '₱5,000+'],
                      _budgetRange,
                      (val) {
                        setState(() => _budgetRange = val);
                        _savePreferences();
                      },
                    )),
                _buildPreferenceRow(
                    context, Icons.fitness_center_outlined, 'Preferred Facilities', _preferredFacilities.isEmpty ? 'Not Set' : '${_preferredFacilities.length} selected',
                    onTap: () => _showMultiSelectSheet(
                      'Preferred Facilities',
                      ['Cardio', 'Free Weights', 'Machines', 'Locker Room', 'Shower Area', 'Sauna', 'Pool', 'Personal Trainers', 'Yoga Studio', 'Boxing', 'Parking', 'WiFi', 'AC', 'Group Classes', 'Kids Area', 'Nutrition Bar'],
                      _preferredFacilities,
                      (val) {
                        setState(() => _preferredFacilities = val);
                        _savePreferences();
                      },
                    )),
                _buildPreferenceRow(
                    context, Icons.person_outline_rounded, 'Trainer Availability', _trainerAvailability.isEmpty ? 'Not Set' : _trainerAvailability,
                    onTap: () => _showPreferenceSheet(
                      'Trainer Availability',
                      ['Morning', 'Afternoon', 'Evening', 'Weekends Only', 'Anytime'],
                      _trainerAvailability,
                      (val) {
                        setState(() => _trainerAvailability = val);
                        _savePreferences();
                      },
                    )),
                const SizedBox(height: AppPadding.lg),

                // ── My Activity ─────────────────────────────────────────
                _buildSectionTitle('My Activity'),
                const SizedBox(height: AppPadding.sm),
                _buildMenuItem(
                    Icons.calendar_today_rounded, 'My Bookings',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.myBookings)),
                _buildMenuItem(
                    Icons.star_outline_rounded, 'Reviews', 
                    onTap: () => Navigator.pushNamed(context, AppRoutes.myReviews)),
                _buildMenuItem(
                    Icons.favorite_border_rounded, 'Saved Gyms/Events',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.favorites)),
                _buildMenuItem(
                    Icons.event_outlined, 'Event Registrations',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.myEvents)),
                _buildMenuItem(
                    Icons.work_outline_rounded, 'Job Opportunities',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.jobs)),
                _buildMenuItem(
                    Icons.assignment_outlined, 'My Applications',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.myApplications)),
                _buildMenuItem(
                    Icons.card_membership_rounded, 'Membership History',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.membershipHistory)),
                const SizedBox(height: AppPadding.lg),

                // ── Account Settings ────────────────────────────────────
                _buildSectionTitle('Account Settings'),
                const SizedBox(height: AppPadding.sm),
                _buildMenuItem(Icons.person_outline_rounded, 'Personal Information',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInformationScreen()))),
                _buildMenuItem(Icons.payment_rounded, 'Payment Methods',
                    onTap: () => _showComingSoon('Payment Methods')),
                _buildMenuItem(Icons.card_giftcard_rounded, 'Rewards & Loyalty',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsLoyaltyScreen()))),
                _buildMenuItem(Icons.settings_outlined, 'Settings',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                _buildMenuItem(Icons.help_outline_rounded, 'Help & Support',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()))),
                const SizedBox(height: AppPadding.lg),


                // ── Logout ──────────────────────────────────────────────
                ListTile(
                  leading:
                      const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    auth.signOut();
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                  },
                ),
                const SizedBox(height: AppPadding.xl),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildDashboardMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceRow(
      BuildContext context, IconData icon, String label, String value, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(label,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
        onTap: onTap,
      ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title,
      {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title,
            style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.textSecondary),
        onTap: onTap,
      ),
      ),
    );
  }
}
