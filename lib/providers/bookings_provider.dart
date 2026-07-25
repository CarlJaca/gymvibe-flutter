import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _upcomingBookings = [];
  List<Map<String, dynamic>> _pastBookings = [];
  StreamSubscription<QuerySnapshot>? _bookingsSubscription;
  String? _currentUserId;

  List<Map<String, dynamic>> get upcomingBookings => List.unmodifiable(_upcomingBookings);
  List<Map<String, dynamic>> get pastBookings => List.unmodifiable(_pastBookings);
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
        _pastBookings.clear();
        notifyListeners();
      }
    });
  }

  void _listenToBookings() {
    if (_currentUserId == null) return;
    
    _bookingsSubscription?.cancel();
    _bookingsSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: _currentUserId)
        .snapshots()
        .listen((snapshot) {
      final List<Map<String, dynamic>> upcoming = [];
      final List<Map<String, dynamic>> past = [];

      for (var doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id; // Use Firestore document ID
        
        if (data['status'] == 'Completed' || data['status'] == 'Cancelled') {
          past.add(data);
        } else {
          upcoming.add(data);
        }
      }
      
      _upcomingBookings = upcoming;
      _pastBookings = past;
      notifyListeners();
    });
  }

  Future<bool> addBooking(Map<String, dynamic> booking) async {
    if (_currentUserId == null) return false;
    
    booking['userId'] = _currentUserId;
    booking['status'] ??= 'Confirmed';
    booking['createdAt'] = FieldValue.serverTimestamp();

    try {
      await FirebaseFirestore.instance.collection('bookings').add(booking);
      return true;
    } catch (e) {
      debugPrint('Error adding booking: $e');
      return false;
    }
  }

  Future<void> cancelBooking(String id) async {
    await FirebaseFirestore.instance.collection('bookings').doc(id).delete();
  }

  Future<void> rescheduleBooking(String id, String newDate, String newTime) async {
    await FirebaseFirestore.instance.collection('bookings').doc(id).update({
      'dateStr': newDate,
      'time': newTime,
    });
  }

  Future<void> markAsCompleted(String id) async {
    await FirebaseFirestore.instance.collection('bookings').doc(id).update({
      'status': 'Completed',
    });
  }

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    super.dispose();
  }
}
