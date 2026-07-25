import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/notification_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/gym_provider.dart';

class OwnerCreateEventScreen extends StatefulWidget {
  const OwnerCreateEventScreen({super.key});

  @override
  State<OwnerCreateEventScreen> createState() => _OwnerCreateEventScreenState();
}

class _OwnerCreateEventScreenState extends State<OwnerCreateEventScreen> {
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _limitCtrl    = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedCategory;

  final List<String> _categories = [
    'Zumba', 'HIIT', 'Strength', 'Yoga', 'Cardio', 'CrossFit', 'Running', 'Pilates'
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _selectedTime = t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.sm, vertical: AppPadding.xs),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Create New Event',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppPadding.md),
              child: Text(
                'Fill in the details of your event',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

            // ── Form ────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppPadding.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppPadding.sm),

                    // ── Cover Image Upload ─────────────────────────
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                              color: AppColors.border,
                              style: BorderStyle.solid),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_photo_alternate_rounded,
                                  color: AppColors.primary, size: 26),
                            ),
                            const SizedBox(height: 10),
                            const Text('Add Event Image',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppPadding.md),

                    // ── Event Title ────────────────────────────────
                    _label('Event Title'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                          hintText: 'Enter event title'),
                    ),
                    const SizedBox(height: AppPadding.md),

                    // ── Description ────────────────────────────────
                    _label('Event Description'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          hintText: 'Describe your event'),
                    ),
                    const SizedBox(height: AppPadding.md),

                    // ── Date ──────────────────────────────────────
                    _label('Event Date'),
                    const SizedBox(height: 8),
                    _buildTappableField(
                      hint: _selectedDate == null
                          ? 'Select date'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      icon: Icons.calendar_today_rounded,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: AppPadding.md),

                    // ── Time ──────────────────────────────────────
                    _label('Event Time'),
                    const SizedBox(height: 8),
                    _buildTappableField(
                      hint: _selectedTime == null
                          ? 'Select time'
                          : _selectedTime!.format(context),
                      icon: Icons.access_time_rounded,
                      onTap: _pickTime,
                    ),
                    const SizedBox(height: AppPadding.md),

                    // ── Location ──────────────────────────────────
                    _label('Location (in your gym)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Enter location',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: AppPadding.md),

                    // ── Participant Limit ──────────────────────────
                    _label('Participant Limit'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _limitCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 50',
                        prefixIcon: Icon(Icons.people_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: AppPadding.md),

                    // ── Category ──────────────────────────────────
                    _label('Event Category'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          hint: const Text('Select category',
                              style: TextStyle(color: AppColors.textMuted)),
                          isExpanded: true,
                          dropdownColor: AppColors.surfaceElevated,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary),
                          items: _categories
                              .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary))))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCategory = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppPadding.xl),
                  ],
                ),
              ),
            ),

            // ── CTA ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppPadding.md),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final notifProv = context.read<NotificationProvider>();
                    notifProv.addNotification(NotificationItem(
                      icon: Icons.event_rounded,
                      title: 'New Event: ${_titleCtrl.text.isEmpty ? 'Upcoming Event' : _titleCtrl.text}',
                      subtitle: _descCtrl.text.isEmpty ? 'Check out our new event!' : _descCtrl.text,
                      time: 'Just now',
                    ));

                    final eventsProv = context.read<EventsProvider>();
                    final gymProv = context.read<GymProvider>();
                    eventsProv.addEvent({
                      'id': 'e_${DateTime.now().millisecondsSinceEpoch}',
                      'gymId': gymProv.ownerGym.id,
                      'title': _titleCtrl.text.isEmpty ? 'Upcoming Event' : _titleCtrl.text,
                      'date': _selectedDate != null ? '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}' : 'TBA',
                      'time': _selectedTime != null ? _selectedTime!.format(context) : 'TBA',
                      'location': _locationCtrl.text.isEmpty ? 'TBA' : _locationCtrl.text,
                      'category': _selectedCategory ?? 'Workout',
                      'distance': '0.0 km away',
                      'instructor': 'Gym Staff',
                      'difficulty': 'All Levels',
                      'duration': '60 Minutes',
                      'maxSlots': int.tryParse(_limitCtrl.text) ?? 50,
                      'registeredCount': 0,
                      'description': _descCtrl.text.isEmpty ? 'Join our new event at the gym.' : _descCtrl.text,
                      'whatToBring': ['Water bottle', 'Towel'],
                      'image': 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400&q=80',
                      'isFeatured': false,
                      'isSaved': false,
                      'hasReminder': false,
                      'status': 'Upcoming',
                      'attendees': [],
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Event published successfully!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Publish Event'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary));

  Widget _buildTappableField({
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 12),
            Text(hint,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
