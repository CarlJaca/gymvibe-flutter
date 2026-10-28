import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/constants/app_constants.dart';
import '../../models/gym_model.dart';
import '../../providers/crowd_status_provider.dart';
import '../../services/crowd_service.dart';
import 'booking_screen.dart';

class BusyDayCalendarScreen extends StatefulWidget {
  final GymModel gym;

  const BusyDayCalendarScreen({super.key, required this.gym});

  @override
  State<BusyDayCalendarScreen> createState() => _BusyDayCalendarScreenState();
}

class _BusyDayCalendarScreenState extends State<BusyDayCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadMonthData(_focusedDay);
  }

  void _loadMonthData(DateTime date) {
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 0);
    final provider = context.read<CrowdStatusProvider>();
    provider.loadBookingCountsForRange(
      widget.gym.id,
      _formatDateStr(start),
      _formatDateStr(end),
    );
  }

  String _formatDateStr(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isDateBlocked(DateTime date) {
    return widget.gym.blockedDates.contains(_formatDateStr(date));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Busy Day Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Tip Banner ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.all(AppPadding.md),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Book on Low or Moderate days for a better workout experience.',
                      style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Calendar ────────────────────────────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppPadding.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Consumer<CrowdStatusProvider>(
                  builder: (context, crowdProv, _) {
                    return TableCalendar(
                      firstDay: DateTime.now().subtract(const Duration(days: 30)),
                      lastDay: DateTime.now().add(const Duration(days: 90)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        if (!_isDateBlocked(selectedDay)) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        }
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                        _loadMonthData(focusedDay);
                      },
                      calendarFormat: CalendarFormat.month,
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        leftChevronIcon: Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary),
                        rightChevronIcon: Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        weekendStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) => _buildCalendarCell(day, crowdProv),
                        selectedBuilder: (context, day, focusedDay) => _buildCalendarCell(day, crowdProv, isSelected: true),
                        todayBuilder: (context, day, focusedDay) => _buildCalendarCell(day, crowdProv, isToday: true),
                        disabledBuilder: (context, day, focusedDay) => _buildCalendarCell(day, crowdProv, isDisabled: true),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // ─── Legend ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem(CrowdLevel.low),
                  _buildLegendItem(CrowdLevel.moderate),
                  _buildLegendItem(CrowdLevel.busy),
                  _buildLegendItem(CrowdLevel.veryBusy),
                ],
              ),
            ),

            // ─── Book Now Button ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppPadding.md),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedDay != null && !_isDateBlocked(_selectedDay!)
                      ? () {
                          // Navigate to booking screen, could pass the selected date if needed,
                          // but the booking screen has its own date picker. It's better to just navigate.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingScreen(gym: widget.gym),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Book Selected Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCell(DateTime day, CrowdStatusProvider crowdProv, {
    bool isSelected = false,
    bool isToday = false,
    bool isDisabled = false,
  }) {
    final dateStr = _formatDateStr(day);
    final count = crowdProv.getBookingCount(dateStr);
    final level = CrowdService.calculateCrowdLevel(count, widget.gym.capacity);
    final isBlocked = _isDateBlocked(day);

    Color textColor = AppColors.textPrimary;
    if (isDisabled || isBlocked) textColor = AppColors.textMuted;
    if (isSelected) textColor = Colors.white;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isToday && !isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(color: textColor, fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal),
          ),
          if (!isBlocked && !isDisabled)
            Positioned(
              bottom: 4,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _crowdLevelColor(level),
                ),
              ),
            ),
          if (isBlocked)
            const Positioned(
              bottom: 4,
              child: Icon(Icons.block, size: 8, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(CrowdLevel level) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _crowdLevelColor(level),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          CrowdService.crowdLevelLabel(level),
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Color _crowdLevelColor(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low:
        return const Color(0xFF4CAF50);
      case CrowdLevel.moderate:
        return const Color(0xFFFFCA28);
      case CrowdLevel.busy:
        return const Color(0xFFFF9800);
      case CrowdLevel.veryBusy:
        return const Color(0xFFF44336);
    }
  }
}
