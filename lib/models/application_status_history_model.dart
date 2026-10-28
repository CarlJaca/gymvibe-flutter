import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks every status change for an application.
/// Stored at: jobApplications/{applicationId}/statusHistory/{historyId}
class ApplicationStatusHistoryModel {
  final String historyId;
  final String previousStatus;
  final String newStatus;
  final String changedBy;
  final String changedByRole; // 'gym_seeker' | 'gym_owner'
  final String? message;
  final DateTime? createdAt;

  const ApplicationStatusHistoryModel({
    required this.historyId,
    required this.previousStatus,
    required this.newStatus,
    required this.changedBy,
    required this.changedByRole,
    this.message,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'previousStatus': previousStatus,
      'newStatus': newStatus,
      'changedBy': changedBy,
      'changedByRole': changedByRole,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory ApplicationStatusHistoryModel.fromJson(
      Map<String, dynamic> json, String documentId) {
    return ApplicationStatusHistoryModel(
      historyId: documentId,
      previousStatus: json['previousStatus'] ?? '',
      newStatus: json['newStatus'] ?? '',
      changedBy: json['changedBy'] ?? '',
      changedByRole: json['changedByRole'] ?? '',
      message: json['message'],
      createdAt: _parseTimestamp(json['createdAt']),
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
