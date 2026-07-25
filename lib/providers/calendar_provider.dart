import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of workout activities a user can plan.
enum WorkoutType {
  chestDay,
  backDay,
  legDay,
  cardioDay,
  strengthTraining,
  gymSession,
  restDay;

  String get displayName {
    switch (this) {
      case WorkoutType.chestDay:
        return 'Chest Day';
      case WorkoutType.backDay:
        return 'Back Day';
      case WorkoutType.legDay:
        return 'Leg Day';
      case WorkoutType.cardioDay:
        return 'Cardio Day';
      case WorkoutType.strengthTraining:
        return 'Strength Training';
      case WorkoutType.gymSession:
        return 'Gym Session';
      case WorkoutType.restDay:
        return 'Rest Day';
    }
  }

  IconData get icon {
    switch (this) {
      case WorkoutType.chestDay:
        return Icons.fitness_center;
      case WorkoutType.backDay:
        return Icons.accessibility_new;
      case WorkoutType.legDay:
        return Icons.directions_walk;
      case WorkoutType.cardioDay:
        return Icons.directions_run;
      case WorkoutType.strengthTraining:
        return Icons.sports_gymnastics;
      case WorkoutType.gymSession:
        return Icons.sports_mma;
      case WorkoutType.restDay:
        return Icons.hotel;
    }
  }

  Color get color {
    switch (this) {
      case WorkoutType.chestDay:
        return const Color(0xFFEF4444); // Red
      case WorkoutType.backDay:
        return const Color(0xFF3B82F6); // Blue
      case WorkoutType.legDay:
        return const Color(0xFF22C55E); // Green
      case WorkoutType.cardioDay:
        return const Color(0xFFEAB308); // Yellow
      case WorkoutType.strengthTraining:
        return const Color(0xFFA855F7); // Purple
      case WorkoutType.gymSession:
        return const Color(0xFFF97316); // Orange
      case WorkoutType.restDay:
        return const Color(0xFF6B7280); // Gray
    }
  }

  static WorkoutType fromString(String value) {
    return WorkoutType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => WorkoutType.restDay,
    );
  }
}

/// A single workout activity planned for a date.
class WorkoutActivity {
  final String id;
  final WorkoutType type;
  final String notes;

  const WorkoutActivity({
    required this.id,
    required this.type,
    this.notes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'notes': notes,
    };
  }

  factory WorkoutActivity.fromJson(Map<String, dynamic> json) {
    return WorkoutActivity(
      id: json['id'] ?? '',
      type: WorkoutType.fromString(json['type'] ?? 'restDay'),
      notes: json['notes'] ?? '',
    );
  }

  WorkoutActivity copyWith({
    String? id,
    WorkoutType? type,
    String? notes,
  }) {
    return WorkoutActivity(
      id: id ?? this.id,
      type: type ?? this.type,
      notes: notes ?? this.notes,
    );
  }
}

/// Provider managing workout calendar state with Firestore persistence.
/// Firestore path: users/{userId}/workoutCalendar/{dateKey}
class CalendarProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Map of date keys (yyyy-MM-dd) to lists of activities.
  final Map<String, List<WorkoutActivity>> _activities = {};
  bool _isLoading = false;
  String? _userId;

  // ─── Getters ────────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;

  /// Set the current user ID for Firestore paths.
  void setUserId(String userId) {
    _userId = userId;
  }

  /// Get activities for a specific date.
  List<WorkoutActivity> getActivitiesForDate(DateTime date) {
    final key = _dateKey(date);
    return _activities[key] ?? [];
  }

  /// Check if a date has activities.
  bool hasActivities(DateTime date) {
    final key = _dateKey(date);
    return _activities.containsKey(key) && _activities[key]!.isNotEmpty;
  }

  /// Get the primary workout type for a date (for color-coding).
  WorkoutType? getPrimaryTypeForDate(DateTime date) {
    final activities = getActivitiesForDate(date);
    return activities.isNotEmpty ? activities.first.type : null;
  }

  // ─── Load Activities for a Month ────────────────────────────────────────────
  Future<void> loadMonth(int year, int month) async {
    if (_userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Generate all date keys for the month
      final daysInMonth = DateTime(year, month + 1, 0).day;
      
      for (int day = 1; day <= daysInMonth; day++) {
        final key = _dateKey(DateTime(year, month, day));
        
        final doc = await _firestore
            .collection('users')
            .doc(_userId)
            .collection('workoutCalendar')
            .doc(key)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final activitiesList = (data['activities'] as List<dynamic>?)
              ?.map((a) => WorkoutActivity.fromJson(a as Map<String, dynamic>))
              .toList() ?? [];
          _activities[key] = activitiesList;
        } else {
          _activities.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error loading calendar month: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Add Activity ───────────────────────────────────────────────────────────
  Future<void> addActivity(DateTime date, WorkoutActivity activity) async {
    if (_userId == null) return;

    final key = _dateKey(date);
    final current = List<WorkoutActivity>.from(_activities[key] ?? []);
    current.add(activity);
    _activities[key] = current;
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('workoutCalendar')
          .doc(key)
          .set({
        'activities': current.map((a) => a.toJson()).toList(),
      });
    } catch (e) {
      debugPrint('Error adding activity: $e');
    }
  }

  // ─── Update Activity ────────────────────────────────────────────────────────
  Future<void> updateActivity(DateTime date, String activityId, WorkoutActivity updated) async {
    if (_userId == null) return;

    final key = _dateKey(date);
    final current = List<WorkoutActivity>.from(_activities[key] ?? []);
    final index = current.indexWhere((a) => a.id == activityId);
    if (index == -1) return;

    current[index] = updated;
    _activities[key] = current;
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('workoutCalendar')
          .doc(key)
          .set({
        'activities': current.map((a) => a.toJson()).toList(),
      });
    } catch (e) {
      debugPrint('Error updating activity: $e');
    }
  }

  // ─── Remove Activity ────────────────────────────────────────────────────────
  Future<void> removeActivity(DateTime date, String activityId) async {
    if (_userId == null) return;

    final key = _dateKey(date);
    final current = List<WorkoutActivity>.from(_activities[key] ?? []);
    current.removeWhere((a) => a.id == activityId);

    if (current.isEmpty) {
      _activities.remove(key);
    } else {
      _activities[key] = current;
    }
    notifyListeners();

    try {
      if (current.isEmpty) {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('workoutCalendar')
            .doc(key)
            .delete();
      } else {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('workoutCalendar')
            .doc(key)
            .set({
          'activities': current.map((a) => a.toJson()).toList(),
        });
      }
    } catch (e) {
      debugPrint('Error removing activity: $e');
    }
  }

  // ─── Helper ─────────────────────────────────────────────────────────────────
  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
