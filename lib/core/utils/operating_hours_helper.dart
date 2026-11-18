// Utility to determine if a gym is currently open based on its operating hours.
//
// Uses Asia/Manila timezone (UTC+8) for all Davao City gyms.
// Handles: 24-hour gyms, overnight schedules, closed days, missing hours.

class OperatingHoursStatus {
  final bool isOpen;
  final String label; // 'Open', 'Closed', 'Hours unavailable'

  const OperatingHoursStatus({required this.isOpen, required this.label});

  static const OperatingHoursStatus open =
      OperatingHoursStatus(isOpen: true, label: 'Open');
  static const OperatingHoursStatus closed =
      OperatingHoursStatus(isOpen: false, label: 'Closed');
  static const OperatingHoursStatus unavailable =
      OperatingHoursStatus(isOpen: false, label: 'Hours unavailable');
}

class OperatingHoursHelper {
  OperatingHoursHelper._();

  /// Get the current time in Asia/Manila (UTC+8).
  static DateTime _nowManila() {
    final utcNow = DateTime.now().toUtc();
    return utcNow.add(const Duration(hours: 8));
  }

  /// Main entry: determine if a gym is currently open.
  ///
  /// [operatingHours] — the raw string from the dataset, e.g.:
  ///   "Daily 24 hours"
  ///   "Mon-Sat 06:00-22:00; Sunday closed"
  ///   "Mon-Fri 07:00-21:00; Sat 07:00-19:00; Sun closed"
  ///   "Mon-Sat 06:00-13:00 and 13:30-20:30; Sun 13:00-17:00"
  /// [dailySchedule] — optional per-day override map from GymModel.
  static OperatingHoursStatus getStatus({
    required String operatingHours,
    Map<String, String> dailySchedule = const {},
  }) {
    if (operatingHours.isEmpty && dailySchedule.isEmpty) {
      return OperatingHoursStatus.unavailable;
    }

    final now = _nowManila();
    final currentDay = _dayName(now.weekday); // e.g. 'monday'

    // ── Check dailySchedule map first (from Firestore-registered gyms) ──
    if (dailySchedule.isNotEmpty) {
      final todaySchedule = _findInDailySchedule(dailySchedule, currentDay);
      if (todaySchedule != null) {
        return _evaluateScheduleString(todaySchedule, now);
      }
    }

    // ── Parse operatingHours string ──
    if (operatingHours.isEmpty) {
      return OperatingHoursStatus.unavailable;
    }

    // Normalize
    final normalized = operatingHours.toLowerCase().trim();

    // Check for 24-hour patterns
    if (_is24Hours(normalized)) {
      return OperatingHoursStatus.open;
    }

    // Parse semicolon-separated rules
    final todayRange = _findTodayRange(normalized, currentDay);
    if (todayRange == null) {
      // Could not find a matching rule for today
      return OperatingHoursStatus.unavailable;
    }

    if (_isClosed(todayRange)) {
      return OperatingHoursStatus.closed;
    }

    if (_is24Hours(todayRange)) {
      return OperatingHoursStatus.open;
    }

    return _evaluateScheduleString(todayRange, now);
  }

  /// Evaluate a time-range string (e.g. "06:00-22:00" or "05:00-13:00 and 13:30-20:30")
  /// against the current time.
  static OperatingHoursStatus _evaluateScheduleString(
      String schedule, DateTime now) {
    final lower = schedule.toLowerCase().trim();

    if (_isClosed(lower)) return OperatingHoursStatus.closed;
    if (_is24Hours(lower)) return OperatingHoursStatus.open;

    // Handle "and" for split schedules: "06:00-13:00 and 13:30-20:30"
    final parts = lower.split(RegExp(r'\s+and\s+'));

    for (final part in parts) {
      final range = _parseTimeRange(part.trim());
      if (range != null) {
        if (_isWithinRange(now, range.$1, range.$2)) {
          return OperatingHoursStatus.open;
        }
      }
    }

    return OperatingHoursStatus.closed;
  }

  /// Find the schedule string for today from a semicolon-separated operating hours string.
  static String? _findTodayRange(String normalized, String currentDay) {
    // Split on semicolons
    final segments = normalized.split(';').map((s) => s.trim()).toList();

    for (final segment in segments) {
      if (_segmentMatchesDay(segment, currentDay)) {
        // Extract the time part (after the day specification)
        return _extractTimePart(segment);
      }
    }

    // If no specific match, check for "daily" segments
    for (final segment in segments) {
      if (segment.contains('daily')) {
        return _extractTimePart(segment);
      }
    }

    return null;
  }

  /// Check if a segment's day specification matches the current day.
  static bool _segmentMatchesDay(String segment, String currentDay) {
    final lower = segment.trim();

    // "daily" matches all days
    if (lower.startsWith('daily')) return true;

    // Check for day ranges like "mon-sat", "mon-fri"
    final dayRangeMatch =
        RegExp(r'(mon|tue|wed|thu|fri|sat|sun)\s*-\s*(mon|tue|wed|thu|fri|sat|sun)',
                caseSensitive: false)
            .firstMatch(lower);
    if (dayRangeMatch != null) {
      final startDay = _dayIndex(dayRangeMatch.group(1)!);
      final endDay = _dayIndex(dayRangeMatch.group(2)!);
      final todayIdx = _dayIndex(currentDay);
      if (startDay != null && endDay != null && todayIdx != null) {
        if (startDay <= endDay) {
          if (todayIdx >= startDay && todayIdx <= endDay) return true;
        } else {
          // Wraps around (e.g., fri-mon)
          if (todayIdx >= startDay || todayIdx <= endDay) return true;
        }
      }
    }

    // Check for single day names
    final singleDayMatch =
        RegExp(r'^(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun)\b',
                caseSensitive: false)
            .firstMatch(lower);
    if (singleDayMatch != null) {
      // Make sure it's not a range (already handled above)
      if (dayRangeMatch == null) {
        final dayStr = singleDayMatch.group(1)!;
        return _dayIndex(dayStr) == _dayIndex(currentDay);
      }
    }

    return false;
  }

  /// Extract the time portion from a segment like "Mon-Sat 06:00-22:00"
  static String _extractTimePart(String segment) {
    // Remove day specifications
    var result = segment
        .replaceAll(
            RegExp(
                r'(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun)(\s*-\s*(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun))?',
                caseSensitive: false),
            '')
        .replaceAll(RegExp(r'^daily\s*', caseSensitive: false), '')
        .trim();

    return result;
  }

  /// Parse a time range string like "06:00-22:00" or "05:00-00:00".
  /// Returns (open, close) as minutes-from-midnight, or null.
  static (int, int)? _parseTimeRange(String rangeStr) {
    // Match patterns like "06:00-22:00", "5:00-23:00", "05:00-00:00"
    final match =
        RegExp(r'(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})').firstMatch(rangeStr);
    if (match == null) {
      // Try AM/PM format: "6AM-10PM"
      final ampmMatch = RegExp(
              r'(\d{1,2})\s*(am|pm)\s*-\s*(\d{1,2})\s*(am|pm)',
              caseSensitive: false)
          .firstMatch(rangeStr);
      if (ampmMatch != null) {
        final openMinutes = _ampmToMinutes(
            int.parse(ampmMatch.group(1)!), ampmMatch.group(2)!);
        final closeMinutes = _ampmToMinutes(
            int.parse(ampmMatch.group(3)!), ampmMatch.group(4)!);
        if (openMinutes != null && closeMinutes != null) {
          return (openMinutes, closeMinutes);
        }
      }
      return null;
    }

    final openHour = int.parse(match.group(1)!);
    final openMin = int.parse(match.group(2)!);
    final closeHour = int.parse(match.group(3)!);
    final closeMin = int.parse(match.group(4)!);

    final openMinutes = openHour * 60 + openMin;
    var closeMinutes = closeHour * 60 + closeMin;

    // Handle midnight: 00:00 as close means end of day (1440)
    if (closeMinutes == 0) closeMinutes = 1440;

    return (openMinutes, closeMinutes);
  }

  /// Check if [now] is within [openMinutes]..[closeMinutes].
  /// Handles overnight ranges (close < open means wraps past midnight).
  static bool _isWithinRange(DateTime now, int openMinutes, int closeMinutes) {
    final currentMinutes = now.hour * 60 + now.minute;

    if (closeMinutes > openMinutes) {
      // Normal range (e.g., 06:00-22:00)
      return currentMinutes >= openMinutes && currentMinutes < closeMinutes;
    } else {
      // Overnight range (e.g., 22:00-06:00)
      return currentMinutes >= openMinutes || currentMinutes < closeMinutes;
    }
  }

  /// Check if a string indicates "closed".
  static bool _isClosed(String s) {
    final lower = s.toLowerCase().trim();
    return lower == 'closed' ||
        lower.contains('closed') && !lower.contains(':');
  }

  /// Check if a string indicates 24-hour operation.
  static bool _is24Hours(String s) {
    final lower = s.toLowerCase();
    return lower.contains('24 hours') ||
        lower.contains('24/7') ||
        lower.contains('24hrs') ||
        lower.contains('24hours');
  }

  /// Convert AM/PM hour to minutes from midnight.
  static int? _ampmToMinutes(int hour, String period) {
    final isPm = period.toLowerCase() == 'pm';
    if (hour < 1 || hour > 12) return null;
    int h = hour;
    if (isPm && h != 12) h += 12;
    if (!isPm && h == 12) h = 0;
    return h * 60;
  }

  /// Map of day name abbreviations to index (1 = Monday, 7 = Sunday).
  static int? _dayIndex(String day) {
    switch (day.toLowerCase().substring(0, 3)) {
      case 'mon':
        return 1;
      case 'tue':
        return 2;
      case 'wed':
        return 3;
      case 'thu':
        return 4;
      case 'fri':
        return 5;
      case 'sat':
        return 6;
      case 'sun':
        return 7;
      default:
        return null;
    }
  }

  /// Convert DateTime.weekday (1=Mon, 7=Sun) to lowercase day name.
  static String _dayName(int weekday) {
    const names = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return names[weekday - 1];
  }

  /// Look up today's schedule from a dailySchedule map.
  /// Keys might be "Monday", "monday", "Mon", etc.
  static String? _findInDailySchedule(
      Map<String, String> schedule, String currentDay) {
    for (final entry in schedule.entries) {
      final key = entry.key.toLowerCase().trim();
      if (key == currentDay || currentDay.startsWith(key.substring(0, 3))) {
        return entry.value;
      }
    }
    return null;
  }
}
