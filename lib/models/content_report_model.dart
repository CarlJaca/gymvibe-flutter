import 'package:cloud_firestore/cloud_firestore.dart';

class ContentReportModel {
  final String id;
  final String contentType; // 'review', 'event', 'promotion', 'announcement', 'job_posting', 'profile', 'leaderboard'
  final String contentId;
  final String reportedBy;
  final String reporterName;
  final String reason;
  final String status; // 'pending', 'under_review', 'resolved', 'dismissed'
  final String contentStatus; // 'active', 'hidden', 'removed', 'under_review'
  final String? moderationNotes;
  final String? moderatedBy;
  final String? moderatorName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Extra context
  final String? contentTitle;
  final String? contentPreview;
  final String? contentOwnerName;

  const ContentReportModel({
    required this.id,
    required this.contentType,
    required this.contentId,
    required this.reportedBy,
    this.reporterName = '',
    required this.reason,
    this.status = 'pending',
    this.contentStatus = 'active',
    this.moderationNotes,
    this.moderatedBy,
    this.moderatorName,
    required this.createdAt,
    this.updatedAt,
    this.contentTitle,
    this.contentPreview,
    this.contentOwnerName,
  });

  factory ContentReportModel.fromJson(Map<String, dynamic> json, String documentId) {
    DateTime createdAt = DateTime.now();
    if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    }

    DateTime? updatedAt;
    if (json['updatedAt'] is Timestamp) {
      updatedAt = (json['updatedAt'] as Timestamp).toDate();
    }

    return ContentReportModel(
      id: documentId,
      contentType: json['contentType'] ?? '',
      contentId: json['contentId'] ?? '',
      reportedBy: json['reportedBy'] ?? '',
      reporterName: json['reporterName'] ?? '',
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      contentStatus: json['contentStatus'] ?? 'active',
      moderationNotes: json['moderationNotes'],
      moderatedBy: json['moderatedBy'],
      moderatorName: json['moderatorName'],
      createdAt: createdAt,
      updatedAt: updatedAt,
      contentTitle: json['contentTitle'],
      contentPreview: json['contentPreview'],
      contentOwnerName: json['contentOwnerName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contentType': contentType,
      'contentId': contentId,
      'reportedBy': reportedBy,
      'reporterName': reporterName,
      'reason': reason,
      'status': status,
      'contentStatus': contentStatus,
      'moderationNotes': moderationNotes,
      'moderatedBy': moderatedBy,
      'moderatorName': moderatorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'contentTitle': contentTitle,
      'contentPreview': contentPreview,
      'contentOwnerName': contentOwnerName,
    };
  }
}
