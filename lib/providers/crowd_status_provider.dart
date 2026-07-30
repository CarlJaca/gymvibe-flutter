import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/crowd_service.dart';

class CrowdStatusProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CrowdService _crowdService = CrowdService.instance;

  // ─── State ────────────────────────────────────────────────────────────
  Map<String, int> _dailyBookingCounts = {}; // date -> count
  Map<String, Map<String, int>> _slotBookingCounts = {}; // date -> {slot -> count}
  bool _isLoading = false;

  Map<String, int> get dailyBookingCounts => _dailyBookingCounts;
  bool get isLoading => _isLoading;

  // ─── Load Crowd Data ──────────────────────────────────────────────────

  /// Load booking count for a single date.
  Future<int> loadBookingCountForDate(String gymId, String date) async {
    if (_dailyBookingCounts.containsKey(date)) {
      return _dailyBookingCounts[date]!;
    }
    final count = await _crowdService.getBookingsCountForDate(gymId, date);
    _dailyBookingCounts[date] = count;
    notifyListeners();
    return count;
  }

  /// Load booking counts for a date range (for calendar view).
  Future<void> loadBookingCountsForRange(
    String gymId,
    String startDate,
    String endDate,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final counts = await _crowdService.getBookingsForDateRange(
        gymId,
        startDate,
        endDate,
      );
      _dailyBookingCounts.addAll(counts);
    } catch (e) {
      debugPrint('Error loading crowd data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load booking counts per time slot for a specific date.
  Future<Map<String, int>> loadSlotCounts(String gymId, String date) async {
    if (_slotBookingCounts.containsKey(date)) {
      return _slotBookingCounts[date]!;
    }

    try {
      final counts = await _crowdService.getBookingsCountsBySlot(gymId, date);
      _slotBookingCounts[date] = counts;
      notifyListeners();
      return counts;
    } catch (e) {
      debugPrint('Error loading slot counts: $e');
      return {};
    }
  }

  /// Get cached booking count for a date, or 0 if not loaded.
  int getBookingCount(String date) {
    return _dailyBookingCounts[date] ?? 0;
  }

  /// Get crowd level for a date given capacity.
  CrowdLevel getCrowdLevelForDate(String date, int capacity) {
    final count = _dailyBookingCounts[date] ?? 0;
    return CrowdService.calculateCrowdLevel(count, capacity);
  }

  /// Get crowd level for a specific time slot.
  CrowdLevel getCrowdLevelForSlot(String date, String slotKey, int slotCapacity) {
    final slotCounts = _slotBookingCounts[date] ?? {};
    final count = slotCounts[slotKey] ?? 0;
    return CrowdService.calculateCrowdLevel(count, slotCapacity);
  }

  /// Get slot count from cache.
  int getSlotBookingCount(String date, String slotKey) {
    return _slotBookingCounts[date]?[slotKey] ?? 0;
  }

  // ─── Owner: Update Live Status ────────────────────────────────────────

  /// Update the gym's live crowd status (owner only).
  Future<bool> updateLiveStatus(String gymId, String status) async {
    try {
      await _firestore.collection('gyms').doc(gymId).update({
        'currentLiveStatus': status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating live status: $e');
      return false;
    }
  }

  /// Update gym capacity (owner only).
  Future<bool> updateCapacity(String gymId, int capacity) async {
    try {
      await _firestore.collection('gyms').doc(gymId).update({
        'capacity': capacity,
      });
      return true;
    } catch (e) {
      debugPrint('Error updating capacity: $e');
      return false;
    }
  }

  /// Update available time slots (owner only).
  Future<bool> updateTimeSlots(
    String gymId,
    List<Map<String, String>> slots,
  ) async {
    try {
      await _firestore.collection('gyms').doc(gymId).update({
        'availableTimeSlots': slots,
      });
      return true;
    } catch (e) {
      debugPrint('Error updating time slots: $e');
      return false;
    }
  }

  /// Block or unblock a date (owner only).
  Future<bool> toggleBlockedDate(
    String gymId,
    String date,
    List<String> currentBlockedDates,
  ) async {
    try {
      final updated = List<String>.from(currentBlockedDates);
      if (updated.contains(date)) {
        updated.remove(date);
      } else {
        updated.add(date);
      }
      await _firestore.collection('gyms').doc(gymId).update({
        'blockedDates': updated,
      });
      return true;
    } catch (e) {
      debugPrint('Error toggling blocked date: $e');
      return false;
    }
  }

  // ─── Cache Invalidation ───────────────────────────────────────────────

  /// Clear cached data (e.g. when switching gyms).
  void clearCache() {
    _dailyBookingCounts.clear();
    _slotBookingCounts.clear();
    notifyListeners();
  }

  /// Invalidate cache for a specific date (after booking created/cancelled).
  void invalidateDate(String date) {
    _dailyBookingCounts.remove(date);
    _slotBookingCounts.remove(date);
    notifyListeners();
  }
}
