import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../models/gym_model.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/crowd_status_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/crowd_service.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingScreen extends StatefulWidget {
  final GymModel gym;

  const BookingScreen({super.key, required this.gym});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, String>? _selectedSlot;
  bool _showSummary = false;
  bool _isLoading = true;
  Map<String, int> _slotCounts = {};

  late List<Map<String, String>> _timeSlots;

  @override
  void initState() {
    super.initState();
    _timeSlots = widget.gym.availableTimeSlots.isNotEmpty
        ? widget.gym.availableTimeSlots
        : _generateDefaultTimeSlots();
    _loadCrowdData();
  }

  List<Map<String, String>> _generateDefaultTimeSlots() {
    return [
      {'start': '06:00', 'end': '07:00'},
      {'start': '07:00', 'end': '08:00'},
      {'start': '08:00', 'end': '09:00'},
      {'start': '09:00', 'end': '10:00'},
      {'start': '10:00', 'end': '11:00'},
      {'start': '11:00', 'end': '12:00'},
      {'start': '13:00', 'end': '14:00'},
      {'start': '14:00', 'end': '15:00'},
      {'start': '15:00', 'end': '16:00'},
      {'start': '16:00', 'end': '17:00'},
      {'start': '17:00', 'end': '18:00'},
      {'start': '18:00', 'end': '19:00'},
      {'start': '19:00', 'end': '20:00'},
      {'start': '20:00', 'end': '21:00'},
    ];
  }

  Future<void> _loadCrowdData() async {
    setState(() => _isLoading = true);
    final dateStr = _formatDateStr(_selectedDate);
    final provider = context.read<CrowdStatusProvider>();

    await provider.loadBookingCountForDate(widget.gym.id, dateStr);
    final slotCounts = await provider.loadSlotCounts(widget.gym.id, dateStr);

    if (mounted) {
      setState(() {
        _slotCounts = slotCounts;
        _isLoading = false;
      });
    }
  }

  String _formatDateStr(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isDateBlocked(DateTime date) {
    return widget.gym.blockedDates.contains(_formatDateStr(date));
  }

  int get _slotCapacity {
    final totalSlots = _timeSlots.isEmpty ? 1 : _timeSlots.length;
    return (widget.gym.capacity / totalSlots).ceil().clamp(1, widget.gym.capacity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (_showSummary) {
              setState(() => _showSummary = false);
            } else {
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textPrimary,
        ),
        title: Text(
          _showSummary ? 'Booking Summary' : 'Select Date & Time',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _showSummary ? _buildSummaryView() : _buildBookingView(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 1: Date & Time Selection
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBookingView() {
    return Consumer<CrowdStatusProvider>(
      builder: (context, crowdProv, _) {
        final dateStr = _formatDateStr(_selectedDate);
        final dayCount = crowdProv.getBookingCount(dateStr);
        final dayCrowdLevel = CrowdService.calculateCrowdLevel(dayCount, widget.gym.capacity);
        final isBlocked = _isDateBlocked(_selectedDate);

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── One-Day Booking Badge ─────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'One-day booking only',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Selected Date Display ─────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.calendar_today_rounded,
                                color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selected Date',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDisplayDate(_selectedDate),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildCrowdBadge(dayCrowdLevel, compact: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── Date Selector (Scrollable Week) ───────────────
                    _buildDateSelector(crowdProv),
                    const SizedBox(height: 24),

                    // ─── Crowd Overview for this day ───────────────────
                    _buildCrowdOverviewCard(dayCount, dayCrowdLevel),
                    const SizedBox(height: 24),

                    // ─── Time Slots ───────────────────────────────────
                    if (!isBlocked) ...[
                      const Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Select Time Slot',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        )
                      else
                        ..._timeSlots.map((slot) => _buildTimeSlotCard(slot)),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.block_rounded, color: AppColors.error, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'This date is blocked by the gym owner.\nPlease select another date.',
                                style: TextStyle(color: AppColors.error, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ─── Tip ──────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded,
                              color: AppColors.star, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tip: Book on Low or Moderate days for a better workout experience.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ─── Continue Button ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedSlot != null && !isBlocked)
                      ? () => setState(() => _showSummary = true)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: AppColors.surfaceElevated,
                    disabledForegroundColor: AppColors.textMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Date Selector (TableCalendar Week View) ──────────────────────────

  Widget _buildDateSelector(CrowdStatusProvider crowdProv) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.only(bottom: 8),
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 90)),
        focusedDay: _selectedDate,
        selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
        calendarFormat: CalendarFormat.week,
        availableCalendarFormats: const {
          CalendarFormat.week: 'Week',
          CalendarFormat.month: 'Month',
        },
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: true,
          formatButtonTextStyle: TextStyle(color: AppColors.primary, fontSize: 13),
          formatButtonDecoration: BoxDecoration(
            border: Border.fromBorderSide(BorderSide(color: AppColors.primary)),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          leftChevronIcon: Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary),
          rightChevronIcon: Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
          titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          weekendStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          if (!_isDateBlocked(selectedDay)) {
            setState(() {
              _selectedDate = selectedDay;
              _selectedSlot = null;
            });
            _loadCrowdData();
          }
        },
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) => _buildCalendarCell(day, crowdProv),
          selectedBuilder: (context, day, focusedDay) => _buildCalendarCell(day, crowdProv, isSelected: true),
          todayBuilder: (context, day, focusedDay) => _buildCalendarCell(day, crowdProv, isToday: true),
          disabledBuilder: (context, day, focusedDay) => _buildCalendarCell(day, crowdProv, isDisabled: true),
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

  // ─── Crowd Overview Card ─────────────────────────────────────────────────

  Widget _buildCrowdOverviewCard(int dayCount, CrowdLevel dayCrowdLevel) {
    final liveStatus = widget.gym.currentLiveStatus;
    final liveLevel = CrowdService.liveStatusToCrowdLevel(liveStatus);
    final updatedAt = widget.gym.statusUpdatedAt;
    final timeAgo = updatedAt != null ? _timeAgoStr(updatedAt) : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.people_outline_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Crowd Overview for this day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Estimated from bookings
          Row(
            children: [
              const Text('Estimated from bookings', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const Spacer(),
              _buildCrowdBadge(dayCrowdLevel, compact: true),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$dayCount / ${widget.gym.capacity} bookings',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          if (liveLevel != null) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Live status (by owner)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const Spacer(),
                _buildCrowdBadge(liveLevel, compact: true),
              ],
            ),
            if (timeAgo != null) ...[
              const SizedBox(height: 4),
              Text(
                'Updated $timeAgo',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estimated crowd is based on GymVibe bookings. Live status is updated by the gym owner and may include walk-ins and regular members.',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Time Slot Card ──────────────────────────────────────────────────────

  Widget _buildTimeSlotCard(Map<String, String> slot) {
    final start = slot['start'] ?? '';
    final end = slot['end'] ?? '';
    final slotKey = '$start-$end';
    final isSelected = _selectedSlot == slot;
    final count = _slotCounts[slotKey] ?? 0;
    final level = CrowdService.calculateCrowdLevel(count, _slotCapacity);
    final availText = CrowdService.availabilityText(level);

    return GestureDetector(
      onTap: () => setState(() => _selectedSlot = slot),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(right: 12),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              )
            else
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
              ),
            Expanded(
              child: Text(
                '${_formatTime24to12(start)} – ${_formatTime24to12(end)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            _buildCrowdBadge(level, compact: true),
            const SizedBox(width: 10),
            Text(
              availText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _crowdLevelColor(level),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 2: Booking Summary
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSummaryView() {
    final dateStr = _formatDateStr(_selectedDate);
    final crowdProv = context.watch<CrowdStatusProvider>();
    final dayCount = crowdProv.getBookingCount(dateStr);
    final dayCrowdLevel = CrowdService.calculateCrowdLevel(dayCount, widget.gym.capacity);
    final liveStatus = widget.gym.currentLiveStatus;
    final liveLevel = CrowdService.liveStatusToCrowdLevel(liveStatus);
    final updatedAt = widget.gym.statusUpdatedAt;
    final timeAgo = updatedAt != null ? _timeAgoStr(updatedAt) : null;

    final priceStr = widget.gym.sessionPrice.isNotEmpty
        ? widget.gym.sessionPrice
        : '₱200.00';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── One-Day Badge ─────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.event_available_rounded, color: AppColors.primary, size: 28),
                      SizedBox(height: 8),
                      Text(
                        'One-Day Booking Only',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your booking is valid for the selected date and time only.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Booking Details ───────────────────────────────
                _buildSummaryRow(Icons.fitness_center_rounded, 'Gym', widget.gym.name),
                const SizedBox(height: 16),
                _buildSummaryRow(Icons.calendar_today_rounded, 'Date', _formatDisplayDate(_selectedDate)),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  Icons.access_time_rounded,
                  'Time',
                  '${_formatTime24to12(_selectedSlot!['start']!)} – ${_formatTime24to12(_selectedSlot!['end']!)}',
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(Icons.receipt_long_rounded, 'Rate', '$priceStr (1 Day)'),
                const SizedBox(height: 24),

                // ─── Today's Crowd Section ─────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.people_outline_rounded, size: 16, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            "Today's Crowd",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Estimated from bookings',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(height: 6),
                                _buildCrowdBadge(dayCrowdLevel),
                              ],
                            ),
                          ),
                          if (liveLevel != null)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Live status (by owner)',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  const SizedBox(height: 6),
                                  _buildCrowdBadge(liveLevel),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$dayCount / ${widget.gym.capacity} bookings',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      if (timeAgo != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Updated $timeAgo',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Total ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      priceStr,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ─── Confirm Button ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Confirm Booking',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
                  SizedBox(width: 4),
                  Text(
                    'All bookings are for one day only.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Confirm Booking Action
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _confirmBooking() async {
    final authProv = context.read<AuthProvider>();
    if (!authProv.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to book a session.'),
          backgroundColor: AppColors.error,
        ),
      );
      Navigator.pushNamed(context, AppRoutes.login);
      return;
    }

    final dateStr = _formatDateStr(_selectedDate);
    final bookingsProv = context.read<BookingsProvider>();

    // Check for duplicate
    final exists = await bookingsProv.hasExistingBooking(
      widget.gym.id,
      dateStr,
      _selectedSlot!['start']!,
      _selectedSlot!['end']!,
    );
    if (exists && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already have a booking for this time slot.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final priceStr = widget.gym.sessionPrice.isNotEmpty
        ? widget.gym.sessionPrice
        : '₱200.00';

    final success = await bookingsProv.addBooking(
      gymId: widget.gym.id,
      gymName: widget.gym.name,
      gymImageUrl: widget.gym.imageUrl,
      bookingDate: dateStr,
      timeSlotStart: _selectedSlot!['start']!,
      timeSlotEnd: _selectedSlot!['end']!,
      price: priceStr,
    );

    if (!mounted) return;

    // Invalidate crowd cache
    context.read<CrowdStatusProvider>().invalidateDate(dateStr);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking Confirmed! 🎉'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.myBookings);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to book. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Helper Widgets & Methods
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildCrowdBadge(CrowdLevel level, {bool compact = false}) {
    final color = _crowdLevelColor(level);
    final label = CrowdService.crowdLevelLabel(level);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 8 : 10,
            height: compact ? 8 : 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          SizedBox(width: compact ? 6 : 8),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
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

  String _formatDisplayDate(DateTime date) {
    final weekday = _getFullWeekday(date.weekday);
    final month = _getFullMonth(date.month);
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  String _formatTime24to12(String time24) {
    final parts = time24.split(':');
    if (parts.length != 2) return time24;
    int hour = int.tryParse(parts[0]) ?? 0;
    final min = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    return '$hour:$min $period';
  }

  String _timeAgoStr(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }


  String _getFullWeekday(int day) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[day - 1];
  }

  String _getFullMonth(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }
}
