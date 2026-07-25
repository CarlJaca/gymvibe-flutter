import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String id;
  final String actorId;
  final String actorName;
  final String actorRole;
  final String action;
  final String targetType; // 'user', 'gym', 'booking', 'content', 'leaderboard', 'settings'
  final String targetId;
  final String reason;
  final String description;
  final DateTime createdAt;

  const AuditLogModel({
    required this.id,
    required this.actorId,
    required this.actorName,
    this.actorRole = 'super_admin',
    required this.action,
    required this.targetType,
    required this.targetId,
    this.reason = '',
    required this.description,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json, String documentId) {
    DateTime createdAt = DateTime.now();
    if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      createdAt = DateTime.tryParse(json['createdAt']) ?? DateTime.now();
    }

    return AuditLogModel(
      id: documentId,
      actorId: json['actorId'] ?? '',
      actorName: json['actorName'] ?? '',
      actorRole: json['actorRole'] ?? 'super_admin',
      action: json['action'] ?? '',
      targetType: json['targetType'] ?? '',
      targetId: json['targetId'] ?? '',
      reason: json['reason'] ?? '',
      description: json['description'] ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'actorId': actorId,
      'actorName': actorName,
      'actorRole': actorRole,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
