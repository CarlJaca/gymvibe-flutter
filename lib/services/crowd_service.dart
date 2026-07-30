import 'package:cloud_firestore/cloud_firestore.dart';

/// Crowd level thresholds based on booking percentage of capacity.
/// Low: 0–25%, Moderate: 26–50%, Busy: 51–75%, Very Busy: 76–100%
enum CrowdLevel { low, moderate, busy, veryBusy }

class CrowdService {
  CrowdService._();
  static final CrowdService instance = CrowdService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Crowd Level Calculation ─────────────────────────────────────────────

  /// Calculate crowd level from booking count and gym capacity.
  static CrowdLevel calculateCrowdLevel(int bookingCount, int capacity) {
    if (capacity <= 0) return CrowdLevel.low;
    final percentage = (bookingCount / capacity) * 100;
    if (percentage <= 25) return CrowdLevel.low;
    if (percentage <= 50) return CrowdLevel.moderate;
    if (percentage <= 75) return CrowdLevel.busy;
    return CrowdLevel.veryBusy;
  }

  /// Human-readable label for a crowd level.
  static String crowdLevelLabel(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low:
        return 'Low';
      case CrowdLevel.moderate:
        return 'Moderate';
      case CrowdLevel.busy:
        return 'Busy';
      case CrowdLevel.veryBusy:
        return 'Very Busy';
    }
  }

  /// Emoji dot for a crowd level.
  static String crowdLevelEmoji(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low:
        return '🟢';
      case CrowdLevel.moderate:
        return '🟡';
      case CrowdLevel.busy:
        return '🟠';
      case CrowdLevel.veryBusy:
        return '🔴';
    }
  }

  /// Map a live status string to a CrowdLevel enum.
  static CrowdLevel? liveStatusToCrowdLevel(String? status) {
    switch (status) {
      case 'notBusy':
        return CrowdLevel.low;
      case 'moderatelyBusy':
        return CrowdLevel.moderate;
      case 'busy':
        return CrowdLevel.busy;
      case 'veryBusy':
        return CrowdLevel.veryBusy;
      default:
        return null;
    }
  }

  /// Human label for a live status string.
  static String liveStatusLabel(String? status) {
    final level = liveStatusToCrowdLevel(status);
    if (level == null) return 'Not Set';
    return crowdLevelLabel(level);
  }

  /// Availability text based on crowd level.
  static String availabilityText(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low:
        return 'Available';
      case CrowdLevel.moderate:
        return 'Available';
      case CrowdLevel.busy:
        return 'Few Slots Left';
      case CrowdLevel.veryBusy:
        return 'Almost Full';
    }
  }

  // ─── Firestore Queries ──────────────────────────────────────────────────

  /// Get the count of confirmed bookings for a gym on a specific date.
  Future<int> getBookingsCountForDate(String gymId, String date) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('gymId', isEqualTo: gymId)
        .where('bookingDate', isEqualTo: date)
        .where('status', isEqualTo: 'Confirmed')
        .get();
    return snapshot.docs.length;
  }

  /// Get the count of confirmed bookings for a specific time slot.
  Future<int> getBookingsCountForTimeSlot(
    String gymId,
    String date,
    String timeSlotStart,
    String timeSlotEnd,
  ) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('gymId', isEqualTo: gymId)
        .where('bookingDate', isEqualTo: date)
        .where('timeSlotStart', isEqualTo: timeSlotStart)
        .where('timeSlotEnd', isEqualTo: timeSlotEnd)
        .where('status', isEqualTo: 'Confirmed')
        .get();
    return snapshot.docs.length;
  }

  /// Get booking counts for each date in a range (for calendar view).
  /// Returns a map of date string -> count.
  Future<Map<String, int>> getBookingsForDateRange(
    String gymId,
    String startDate,
    String endDate,
  ) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('gymId', isEqualTo: gymId)
        .where('bookingDate', isGreaterThanOrEqualTo: startDate)
        .where('bookingDate', isLessThanOrEqualTo: endDate)
        .where('status', isEqualTo: 'Confirmed')
        .get();

    final Map<String, int> counts = {};
    for (var doc in snapshot.docs) {
      final date = doc.data()['bookingDate'] as String? ?? '';
      counts[date] = (counts[date] ?? 0) + 1;
    }
    return counts;
  }

  /// Get booking counts per time slot for a specific date.
  /// Returns a map of "startTime-endTime" -> count.
  Future<Map<String, int>> getBookingsCountsBySlot(
    String gymId,
    String date,
  ) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('gymId', isEqualTo: gymId)
        .where('bookingDate', isEqualTo: date)
        .where('status', isEqualTo: 'Confirmed')
        .get();

    final Map<String, int> counts = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final key = '${data['timeSlotStart']}-${data['timeSlotEnd']}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  /// Stream confirmed bookings for a gym on a specific date (real-time).
  Stream<QuerySnapshot> streamBookingsForDate(String gymId, String date) {
    return _firestore
        .collection('bookings')
        .where('gymId', isEqualTo: gymId)
        .where('bookingDate', isEqualTo: date)
        .where('status', isEqualTo: 'Confirmed')
        .snapshots();
  }
}
