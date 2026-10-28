import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationModel {
  final String id;
  final String title;
  final String message;
  final String targetAudience; // 'all', 'gym_seekers', 'gym_owners', 'user:{userId}', 'gym:{gymId}'
  final String? linkedScreen;
  final String? imageUrl;
  final DateTime? scheduledDate;
  final DateTime? sentDate;
  final String status; // 'pending', 'sent', 'scheduled'
  final String senderId;
  final String senderName;

  const AdminNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.targetAudience,
    this.linkedScreen,
    this.imageUrl,
    this.scheduledDate,
    this.sentDate,
    this.status = 'pending',
    required this.senderId,
    required this.senderName,
  });

  factory AdminNotificationModel.fromJson(Map<String, dynamic> json, String documentId) {
    DateTime? scheduledDate;
    if (json['scheduledDate'] is Timestamp) {
      scheduledDate = (json['scheduledDate'] as Timestamp).toDate();
    }

    DateTime? sentDate;
    if (json['sentDate'] is Timestamp) {
      sentDate = (json['sentDate'] as Timestamp).toDate();
    }

    return AdminNotificationModel(
      id: documentId,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      targetAudience: json['targetAudience'] ?? 'all',
      linkedScreen: json['linkedScreen'],
      imageUrl: json['imageUrl'],
      scheduledDate: scheduledDate,
      sentDate: sentDate,
      status: json['status'] ?? 'pending',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'targetAudience': targetAudience,
      'linkedScreen': linkedScreen,
      'imageUrl': imageUrl,
      'scheduledDate': scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
      'sentDate': sentDate != null ? Timestamp.fromDate(sentDate!) : null,
      'status': status,
      'senderId': senderId,
      'senderName': senderName,
    };
  }
}
