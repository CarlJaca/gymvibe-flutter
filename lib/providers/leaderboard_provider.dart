import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_model.dart';

class LeaderboardProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<PersonalRecord> _records = [];
  List<PersonalRecord> _pendingRecords = [];
  bool _isLoading = false;
  String? _errorMessage;
  LeaderboardCategory? _selectedCategory; // null means 'All'

  // ─── Getters ────────────────────────────────────────────────────────────────
  List<PersonalRecord> get records => _records;
  List<PersonalRecord> get pendingRecords => _pendingRecords;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LeaderboardCategory? get selectedCategory => _selectedCategory;

  /// Returns verified records for the selected category, sorted by weight descending.
  List<PersonalRecord> get leaderboard {
    final verified = _records
        .where((r) =>
            r.status == RecordStatus.verified &&
            r.category == _selectedCategory)
        .toList();
    verified.sort((a, b) => b.weight.compareTo(a.weight));
    return verified;
  }

  /// Returns the top 3 entries for the podium display.
  List<PersonalRecord> get podium => leaderboard.take(3).toList();

  /// Returns entries below the top 3.
  List<PersonalRecord> get remainingEntries =>
      leaderboard.length > 3 ? leaderboard.sublist(3) : [];

  /// Returns top 3 records for every category
  Map<LeaderboardCategory, List<PersonalRecord>> get allLeaderboards {
    final Map<LeaderboardCategory, List<PersonalRecord>> result = {};
    for (final category in LeaderboardCategory.values) {
      final verified = _records
          .where((r) =>
              r.status == RecordStatus.verified && r.category == category)
          .toList();
      verified.sort((a, b) => b.weight.compareTo(a.weight));
      result[category] = verified.take(3).toList();
    }
    return result;
  }

  // ─── Category Selection ─────────────────────────────────────────────────────
  void setCategory(LeaderboardCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // ─── Load Records for a Gym ─────────────────────────────────────────────────
  Future<void> loadRecords(String gymId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('personalRecords')
          .get();

      _records = snapshot.docs
          .map((doc) => PersonalRecord.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error loading leaderboard records: $e');
      _errorMessage = 'Failed to load leaderboard.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Load Pending Records for Owner ─────────────────────────────────────────
  Future<void> loadPendingRecords(String gymId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('personalRecords')
          .where('status', isEqualTo: 'pending')
          .get();

      _pendingRecords = snapshot.docs
          .map((doc) => PersonalRecord.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error loading pending records: $e');
      _errorMessage = 'Failed to load pending records.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Submit a New PR ────────────────────────────────────────────────────────
  Future<void> submitRecord({
    required String gymId,
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required LeaderboardCategory category,
    required double weight,
  }) async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final docRef = _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('personalRecords')
          .doc();

      final record = PersonalRecord(
        id: docRef.id,
        userId: userId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        gymId: gymId,
        category: category,
        weight: weight,
        date: dateStr,
        status: RecordStatus.pending,
      );

      await docRef.set(record.toJson());

      // Add to local list
      _records.add(record);
      notifyListeners();
    } catch (e) {
      debugPrint('Error submitting record: $e');
      rethrow;
    }
  }

  // ─── Verify a Record (Owner action) ─────────────────────────────────────────
  Future<void> verifyRecord(String gymId, String recordId) async {
    try {
      await _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('personalRecords')
          .doc(recordId)
          .update({'status': 'verified'});

      // Update local lists
      final recordIndex = _records.indexWhere((r) => r.id == recordId);
      if (recordIndex != -1) {
        _records[recordIndex] =
            _records[recordIndex].copyWith(status: RecordStatus.verified);
      }
      _pendingRecords.removeWhere((r) => r.id == recordId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error verifying record: $e');
      rethrow;
    }
  }

  // ─── Reject a Record (Owner action) ─────────────────────────────────────────
  Future<void> rejectRecord(String gymId, String recordId) async {
    try {
      await _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('personalRecords')
          .doc(recordId)
          .update({'status': 'rejected'});

      // Update local lists
      final recordIndex = _records.indexWhere((r) => r.id == recordId);
      if (recordIndex != -1) {
        _records[recordIndex] =
            _records[recordIndex].copyWith(status: RecordStatus.rejected);
      }
      _pendingRecords.removeWhere((r) => r.id == recordId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error rejecting record: $e');
      rethrow;
    }
  }

  // ─── Get User's Own Records for a Gym ───────────────────────────────────────
  List<PersonalRecord> getUserRecords(String userId) {
    return _records.where((r) => r.userId == userId).toList();
  }

  /// Count of pending records for a gym (used for badge display).
  int get pendingCount => _pendingRecords.length;
}
