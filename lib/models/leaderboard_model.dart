import 'package:flutter/material.dart';

/// Categories of exercises available for personal records.
enum LeaderboardCategory {
  deadlift,
  benchPress,
  squat,
  dumbbellCurl,
  overheadPress;

  String get displayName {
    switch (this) {
      case LeaderboardCategory.deadlift:
        return 'Deadlift';
      case LeaderboardCategory.benchPress:
        return 'Bench Press';
      case LeaderboardCategory.squat:
        return 'Squat';
      case LeaderboardCategory.dumbbellCurl:
        return 'Dumbbell Curl';
      case LeaderboardCategory.overheadPress:
        return 'Overhead Press';
    }
  }

  IconData get icon {
    switch (this) {
      case LeaderboardCategory.deadlift:
        return Icons.fitness_center;
      case LeaderboardCategory.benchPress:
        return Icons.airline_seat_flat;
      case LeaderboardCategory.squat:
        return Icons.accessibility_new;
      case LeaderboardCategory.dumbbellCurl:
        return Icons.sports_gymnastics;
      case LeaderboardCategory.overheadPress:
        return Icons.arrow_upward_rounded;
    }
  }

  String get firestoreValue => name;

  static LeaderboardCategory fromString(String value) {
    return LeaderboardCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => LeaderboardCategory.deadlift,
    );
  }
}

/// Status of a submitted personal record.
enum RecordStatus {
  pending,
  verified,
  rejected;

  String get displayName {
    switch (this) {
      case RecordStatus.pending:
        return 'Pending Verification';
      case RecordStatus.verified:
        return 'Verified';
      case RecordStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case RecordStatus.pending:
        return Colors.orange;
      case RecordStatus.verified:
        return Colors.green;
      case RecordStatus.rejected:
        return Colors.red;
    }
  }

  static RecordStatus fromString(String value) {
    return RecordStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => RecordStatus.pending,
    );
  }
}

/// A personal record submitted by a gym member.
class PersonalRecord {
  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String gymId;
  final LeaderboardCategory category;
  final double weight; // in kg
  final String date;
  final RecordStatus status;

  const PersonalRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.gymId,
    required this.category,
    required this.weight,
    required this.date,
    this.status = RecordStatus.pending,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'gymId': gymId,
      'category': category.firestoreValue,
      'weight': weight,
      'date': date,
      'status': status.name,
    };
  }

  factory PersonalRecord.fromJson(Map<String, dynamic> json, String documentId) {
    return PersonalRecord(
      id: documentId,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userAvatarUrl: json['userAvatarUrl'] ?? '',
      gymId: json['gymId'] ?? '',
      category: LeaderboardCategory.fromString(json['category'] ?? 'deadlift'),
      weight: (json['weight'] ?? 0.0).toDouble(),
      date: json['date'] ?? '',
      status: RecordStatus.fromString(json['status'] ?? 'pending'),
    );
  }

  PersonalRecord copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? gymId,
    LeaderboardCategory? category,
    double? weight,
    String? date,
    RecordStatus? status,
  }) {
    return PersonalRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      gymId: gymId ?? this.gymId,
      category: category ?? this.category,
      weight: weight ?? this.weight,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }
}
