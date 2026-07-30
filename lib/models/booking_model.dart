import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String userId;
  final String gymId;
  final String gymName;
  final String gymImageUrl;
  final String bookingDate; // yyyy-MM-dd
  final String timeSlotStart; // e.g. "06:00"
  final String timeSlotEnd;   // e.g. "07:00"
  final String status; // Confirmed, Cancelled, Completed
  final String price;
  final String refNo;
  final DateTime? createdAt;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.gymId,
    required this.gymName,
    this.gymImageUrl = '',
    required this.bookingDate,
    required this.timeSlotStart,
    required this.timeSlotEnd,
    this.status = 'Confirmed',
    this.price = '',
    this.refNo = '',
    this.createdAt,
  });

  /// Display-friendly time slot string, e.g. "6:00 AM – 7:00 AM"
  String get timeSlotDisplay {
    return '${_formatTime(timeSlotStart)} – ${_formatTime(timeSlotEnd)}';
  }

  static String _formatTime(String time24) {
    final parts = time24.split(':');
    if (parts.length != 2) return time24;
    int hour = int.tryParse(parts[0]) ?? 0;
    final min = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    return '$hour:$min $period';
  }

  /// Generate a reference number from date and a counter
  static String generateRefNo(String bookingDate, int counter) {
    final datePart = bookingDate.replaceAll('-', '').substring(2); // e.g. 250625
    return 'GVB-$datePart-${counter.toString().padLeft(4, '0')}';
  }

  BookingModel copyWith({
    String? id,
    String? userId,
    String? gymId,
    String? gymName,
    String? gymImageUrl,
    String? bookingDate,
    String? timeSlotStart,
    String? timeSlotEnd,
    String? status,
    String? price,
    String? refNo,
    DateTime? createdAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gymId: gymId ?? this.gymId,
      gymName: gymName ?? this.gymName,
      gymImageUrl: gymImageUrl ?? this.gymImageUrl,
      bookingDate: bookingDate ?? this.bookingDate,
      timeSlotStart: timeSlotStart ?? this.timeSlotStart,
      timeSlotEnd: timeSlotEnd ?? this.timeSlotEnd,
      status: status ?? this.status,
      price: price ?? this.price,
      refNo: refNo ?? this.refNo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'gymId': gymId,
      'gymName': gymName,
      'gymImageUrl': gymImageUrl,
      'bookingDate': bookingDate,
      'timeSlotStart': timeSlotStart,
      'timeSlotEnd': timeSlotEnd,
      'status': status,
      'price': price,
      'refNo': refNo,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory BookingModel.fromJson(Map<String, dynamic> json, String documentId) {
    return BookingModel(
      id: documentId,
      userId: json['userId'] ?? '',
      gymId: json['gymId'] ?? '',
      gymName: json['gymName'] ?? '',
      gymImageUrl: json['gymImageUrl'] ?? '',
      bookingDate: json['bookingDate'] ?? '',
      timeSlotStart: json['timeSlotStart'] ?? '',
      timeSlotEnd: json['timeSlotEnd'] ?? '',
      status: json['status'] ?? 'Confirmed',
      price: json['price'] ?? '',
      refNo: json['refNo'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(json['createdAt'].toString()))
          : null,
    );
  }
}
