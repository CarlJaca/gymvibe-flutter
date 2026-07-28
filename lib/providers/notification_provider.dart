import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String time;
  bool isRead;
  final DateTime? createdAt;
  final bool isForOwner;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isRead = false,
    this.createdAt,
    this.isForOwner = false,
  });

  IconData get icon {
    switch (type) {
      case 'promo': return Icons.local_offer_rounded;
      case 'event': return Icons.event_rounded;
      case 'review': return Icons.star_rounded;
      case 'membership': return Icons.card_membership_rounded;
      case 'gym': return Icons.fitness_center_rounded;
      case 'follower': return Icons.person_add_rounded;
      case 'registration': return Icons.event_available_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'time': time,
      'isRead': isRead,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'isForOwner': isForOwner,
    };
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json, String documentId) {
    return NotificationItem(
      id: documentId,
      type: json['type'] ?? 'info',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      time: json['time'] ?? 'Just now',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      isForOwner: json['isForOwner'] ?? false,
    );
  }
}

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _subscription;
  
  List<NotificationItem> _customerNotifications = [];
  List<NotificationItem> _ownerNotifications = [];
  
  bool _isLoading = false;
  String? _userId;

  List<NotificationItem> get customerNotifications => _customerNotifications;
  List<NotificationItem> get ownerNotifications => _ownerNotifications;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications(String userId) async {
    if (_userId == userId && _subscription != null) return; // Already loaded
    
    _userId = userId;
    _isLoading = true;
    notifyListeners();
    
    _subscription?.cancel();
    
    try {
      _subscription = _firestore
          .collection('users')
          .doc(_userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) async {
            
        if (snapshot.docs.isEmpty) {
          await _seedInitialNotifications(userId);
          return; // Let the next snapshot trigger the UI update
        }

        final allNotifs = snapshot.docs
            .map((doc) => NotificationItem.fromJson(doc.data(), doc.id))
            .toList();
            
        _customerNotifications = allNotifs.where((n) => !n.isForOwner).toList();
        _ownerNotifications = allNotifs.where((n) => n.isForOwner).toList();
        
        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        debugPrint('Error loading notifications: $e');
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Sync Error loading notifications stream: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllCustomerRead() async {
    if (_userId == null) return;
    
    try {
      final batch = _firestore.batch();
      for (var n in _customerNotifications) {
        if (!n.isRead) {
          final docRef = _firestore.collection('users').doc(_userId).collection('notifications').doc(n.id);
          batch.update(docRef, {'isRead': true});
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> markAllOwnerRead() async {
    if (_userId == null) return;
    
    try {
      final batch = _firestore.batch();
      for (var n in _ownerNotifications) {
        if (!n.isRead) {
          final docRef = _firestore.collection('users').doc(_userId).collection('notifications').doc(n.id);
          batch.update(docRef, {'isRead': true});
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking owner notifications as read: $e');
    }
  }

  Future<void> markCustomerAsRead(int index) async {
    if (_userId == null || index < 0 || index >= _customerNotifications.length) return;
    
    final id = _customerNotifications[index].id;
    try {
      await _firestore.collection('users').doc(_userId).collection('notifications').doc(id).update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markOwnerAsRead(int index) async {
    if (_userId == null || index < 0 || index >= _ownerNotifications.length) return;
    
    final id = _ownerNotifications[index].id;
    try {
      await _firestore.collection('users').doc(_userId).collection('notifications').doc(id).update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking owner notification as read: $e');
    }
  }

  Future<void> addNotification(NotificationItem item) async {
    if (_userId == null) return;
    
    try {
      await _firestore.collection('users').doc(_userId).collection('notifications').add(item.toJson());
      
      // Also add owner equivalent
      final ownerItem = NotificationItem(
        id: '', // Firestore generates
        type: item.type,
        title: 'You created: ${item.title}',
        subtitle: item.subtitle,
        time: item.time,
        isForOwner: true,
      );
      await _firestore.collection('users').doc(_userId).collection('notifications').add(ownerItem.toJson());
    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }
  
  Future<void> _seedInitialNotifications(String userId) async {
    final batch = _firestore.batch();
    final now = DateTime.now();
    
    final mockNotifs = [
      {
        'type': 'promo',
        'title': 'New Promotion Available',
        'subtitle': '20% off at Iron Core Gym this weekend!',
        'time': '2h ago',
        'isRead': false,
        'createdAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'isForOwner': false,
      },
      {
        'type': 'event',
        'title': 'Upcoming Event',
        'subtitle': 'HIIT Challenge starts tomorrow at 6 AM',
        'time': '5h ago',
        'isRead': false,
        'createdAt': now.subtract(const Duration(hours: 5)).toIso8601String(),
        'isForOwner': false,
      },
      {
        'type': 'review',
        'title': 'New Review',
        'subtitle': '5 stars from John D.',
        'time': '3h ago',
        'isRead': false,
        'createdAt': now.subtract(const Duration(hours: 3)).toIso8601String(),
        'isForOwner': true,
      },
      {
        'type': 'follower',
        'title': 'New Follower',
        'subtitle': 'Sarah M. started following you',
        'time': '5h ago',
        'isRead': false,
        'createdAt': now.subtract(const Duration(hours: 5)).toIso8601String(),
        'isForOwner': true,
      }
    ];

    for (var notif in mockNotifs) {
      final docRef = _firestore.collection('users').doc(userId).collection('notifications').doc();
      batch.set(docRef, notif);
    }
    
    try {
      await batch.commit();
      debugPrint('Seeded initial notifications for user: $userId');
    } catch (e) {
      debugPrint('Error seeding notifications: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
