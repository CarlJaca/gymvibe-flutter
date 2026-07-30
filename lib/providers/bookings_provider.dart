import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';

class BookingsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<BookingModel> _upcomingBookings = [];
  List<BookingModel> _completedBookings = [];
  List<BookingModel> _cancelledBookings = [];
  StreamSubscription<QuerySnapshot>? _bookingsSubscription;
  String? _currentUserId;

  List<BookingModel> get upcomingBookings => List.unmodifiable(_upcomingBookings);
  List<BookingModel> get completedBookings => List.unmodifiable(_completedBookings);
  List<BookingModel> get cancelledBookings => List.unmodifiable(_cancelledBookings);
  String? get currentUserId => _currentUserId;

  BookingsProvider() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _currentUserId = user.uid;
        _listenToBookings();
      } else {
        _currentUserId = null;
        _bookingsSubscription?.cancel();
        _upcomingBookings.clear();
        _completedBookings.clear();
        _cancelledBookings.clear();
        notifyListeners();
      }
    });
  }

  void _listenToBookings() {
    if (_currentUserId == null) return;

    _bookingsSubscription?.cancel();
    _bookingsSubscription = _firestore
        .collection('bookings')
        .where('userId', isEqualTo: _currentUserId)
        .snapshots()
        .listen((snapshot) {
      final List<BookingModel> upcoming = [];
      final List<BookingModel> completed = [];
      final List<BookingModel> cancelled = [];
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      for (var doc in snapshot.docs) {
        final booking = BookingModel.fromJson(
          doc.data(),
          doc.id,
        );

        if (booking.status == 'Cancelled') {
          cancelled.add(booking);
        } else if (booking.status == 'Completed' || booking.bookingDate.compareTo(todayStr) < 0) {
          completed.add(booking);
        } else {
          upcoming.add(booking);
        }
      }

      // Sort upcoming by date (nearest first)
      upcoming.sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
      // Sort completed by date (most recent first)
      completed.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
      // Sort cancelled by date (most recent first)
      cancelled.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

      _upcomingBookings = upcoming;
      _completedBookings = completed;
      _cancelledBookings = cancelled;
      notifyListeners();
    });
  }

  /// Add a new one-day booking to Firestore.
  Future<bool> addBooking({
    required String gymId,
    required String gymName,
    required String gymImageUrl,
    required String bookingDate,
    required String timeSlotStart,
    required String timeSlotEnd,
    required String price,
  }) async {
    if (_currentUserId == null) return false;

    try {
      // Count existing bookings for this date to generate ref number
      final existingSnap = await _firestore
          .collection('bookings')
          .where('gymId', isEqualTo: gymId)
          .where('bookingDate', isEqualTo: bookingDate)
          .get();

      final refNo = BookingModel.generateRefNo(
        bookingDate,
        existingSnap.docs.length + 1,
      );

      final bookingData = {
        'userId': _currentUserId,
        'gymId': gymId,
        'gymName': gymName,
        'gymImageUrl': gymImageUrl,
        'bookingDate': bookingDate,
        'timeSlotStart': timeSlotStart,
        'timeSlotEnd': timeSlotEnd,
        'status': 'Confirmed',
        'price': price,
        'refNo': refNo,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('bookings').add(bookingData);
      return true;
    } catch (e) {
      debugPrint('Error adding booking: $e');
      return false;
    }
  }

  /// Cancel a booking (sets status to Cancelled instead of deleting).
  Future<void> cancelBooking(String id) async {
    try {
      await _firestore.collection('bookings').doc(id).update({
        'status': 'Cancelled',
      });
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
    }
  }

  /// Mark a booking as completed.
  Future<void> markAsCompleted(String id) async {
    await _firestore.collection('bookings').doc(id).update({
      'status': 'Completed',
    });
  }

  /// Check if user already has a booking for this gym/date/slot.
  Future<bool> hasExistingBooking(
    String gymId,
    String date,
    String timeSlotStart,
    String timeSlotEnd,
  ) async {
    if (_currentUserId == null) return false;

    final snapshot = await _firestore
        .collection('bookings')
        .where('userId', isEqualTo: _currentUserId)
        .where('gymId', isEqualTo: gymId)
        .where('bookingDate', isEqualTo: date)
        .where('timeSlotStart', isEqualTo: timeSlotStart)
        .where('timeSlotEnd', isEqualTo: timeSlotEnd)
        .where('status', isEqualTo: 'Confirmed')
        .get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    super.dispose();
  }
}
