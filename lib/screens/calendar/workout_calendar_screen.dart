import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/auth_provider.dart';

class WorkoutCalendarScreen extends StatefulWidget {
  const WorkoutCalendarScreen({super.key});

  @override
  State<WorkoutCalendarScreen> createState() => _WorkoutCalendarScreenState();
}

class _WorkoutCalendarScreenState extends State<WorkoutCalendarScreen> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _selectedDate = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        final calendarProv = context.read<CalendarProvider>();
        calendarProv.setUserId(auth.currentUser!.id);
        calendarProv.loadMonth(_currentMonth.year, _currentMonth.month);
      }
    });
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    context.read<CalendarProvider>().loadMonth(_currentMonth.year, _currentMonth.month);
  }

  void _goToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    context.read<CalendarProvider>().loadMonth(_currentMonth.year, _currentMonth.month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Workout Calendar'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Consumer<CalendarProvider>(
        builder: (context, calendarProv, _) {
          return Column(
            children: [
              // ── Month Navigation ─────────────────────────────────
              _buildMonthNavigation(),
              const SizedBox(height: 8),

              // ── Day Labels ───────────────────────────────────────
              _buildDayLabels(),
              const SizedBox(height: 4),

              // ── Calendar Grid ────────────────────────────────────
              _buildCalendarGrid(calendarProv),
              const SizedBox(height: 16),

              // ── Legend ───────────────────────────────────────────
              _buildLegend(),
              const SizedBox(height: 16),

              // ── Selected Date Activities Preview ─────────────────
              Expanded(child: _buildSelectedDatePreview(calendarProv)),
            ],
          );
        },
      ),
    );
  }

  // ─── Month Navigation ───────────────────────────────────────────────────────
  Widget _buildMonthNavigation() {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _goToPreviousMonth,
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary),
          ),
          Text(
            '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            onPressed: _goToNextMonth,
            icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  // ─── Day Labels ─────────────────────────────────────────────────────────────
  Widget _buildDayLabels() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
      child: Row(
        children: days
            .map((d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ─── Calendar Grid ──────────────────────────────────────────────────────────
  Widget _buildCalendarGrid(CalendarProvider calendarProv) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    // Monday = 1, so offset is weekday - 1
    final startOffset = (firstDayOfMonth.weekday - 1) % 7;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNum = cellIndex - startOffset + 1;

              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 48));
              }

              final date = DateTime(_currentMonth.year, _currentMonth.month, dayNum);
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isSelected = _selectedDate != null &&
                  date.year == _selectedDate!.year &&
                  date.month == _selectedDate!.month &&
                  date.day == _selectedDate!.day;
              final workoutType = calendarProv.getPrimaryTypeForDate(date);
              final hasActivity = calendarProv.hasActivities(date);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = date);
                  },
                  onDoubleTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.workoutDay,
                      arguments: date,
                    ).then((_) {
                      // Reload when returning from day screen
                      calendarProv.loadMonth(_currentMonth.year, _currentMonth.month);
                    });
                  },
                  child: Container(
                    height: 48,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : isToday
                              ? AppColors.surfaceElevated
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: isSelected
                          ? Border.all(color: AppColors.primary, width: 1.5)
                          : isToday
                              ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
                              : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : isToday
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: isToday || isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (hasActivity) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: workoutType?.color ?? AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  // ─── Legend ──────────────────────────────────────────────────────────────────
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: WorkoutType.values.map((type) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: type.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                type.displayName,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─── Selected Date Preview ──────────────────────────────────────────────────
  Widget _buildSelectedDatePreview(CalendarProvider calendarProv) {
    if (_selectedDate == null) {
      return const Center(
        child: Text(
          'Select a date to see activities',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    final activities = calendarProv.getActivitiesForDate(_selectedDate!);
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dateStr = '${monthNames[_selectedDate!.month - 1]} ${_selectedDate!.day}, ${_selectedDate!.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.workoutDay,
                    arguments: _selectedDate!,
                  ).then((_) {
                    calendarProv.loadMonth(_currentMonth.year, _currentMonth.month);
                  });
                },
                icon: Icon(
                  activities.isEmpty ? Icons.add_rounded : Icons.edit_rounded,
                  size: 16,
                ),
                label: Text(activities.isEmpty ? 'Add Activity' : 'Edit'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (activities.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No activities planned.\nTap "Add Activity" or double-tap a date.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: activity.type.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: activity.type.color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: activity.type.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(activity.type.icon, color: activity.type.color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.type.displayName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (activity.notes.isNotEmpty)
                                Text(
                                  activity.notes,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
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
                },
              ),
            ),
        ],
      ),
    );
  }
}
