import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class EventsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _eventsSubscription;

  // ─── State ────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _allEvents = [];
  final List<Map<String, dynamic>> _myRegisteredEvents = [];
  bool _isLoading = false;

  // ─── Getters ────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get allEvents => _allEvents;
  List<Map<String, dynamic>> get activeEvents => _allEvents.where((e) => (e['status'] ?? 'Active') == 'Active').toList();
  List<Map<String, dynamic>> get upcomingEvents => _allEvents.where((e) => (e['status'] ?? 'Upcoming') == 'Upcoming').toList();
  List<Map<String, dynamic>> get inactiveEvents => _allEvents.where((e) => e['status'] == 'Inactive').toList();
  List<Map<String, dynamic>> get pastEvents => _allEvents.where((e) => e['status'] == 'Past' || e['status'] == 'Inactive').toList();
  
  List<Map<String, dynamic>> get featuredEvents => _allEvents.where((e) => (e['isFeatured'] ?? false) == true).toList();
  List<Map<String, dynamic>> get myRegisteredEvents => _myRegisteredEvents;
  List<Map<String, dynamic>> get savedEvents => _allEvents.where((e) => (e['isSaved'] ?? false) == true).toList();
  List<Map<String, dynamic>> get eventsWithReminders => _allEvents.where((e) => (e['hasReminder'] ?? false) == true).toList();

  // ─── Init (Firestore) ──────────────────────────────────────────────
  Future<void> loadEvents() async {
    if (_eventsSubscription != null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      _eventsSubscription = _firestore.collection('events').snapshots().listen(
        (snapshot) {
          try {
            _allEvents.clear();
            _allEvents.addAll(snapshot.docs
                .map((doc) => Map<String, dynamic>.from(doc.data()))
                .toList());
          } catch (e, stack) {
            debugPrint('Error processing events snapshot: $e');
            debugPrint(stack.toString());
          }

          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Error loading events: $e');
          _isLoading = false;
          notifyListeners();
        }
      );
    } catch (e) {
      debugPrint('Sync Error loading events stream: $e. Attempting fallback fetch.');
      
      try {
        final snapshot = await _firestore.collection('events').get(const GetOptions(source: Source.cache));
        _allEvents.clear();
        _allEvents.addAll(snapshot.docs.map((doc) => Map<String, dynamic>.from(doc.data())).toList());
      } catch (inner) {
        debugPrint('Fallback events cache get() also failed: $inner');
      }

      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Methods ────────────────────────────────────────────────────────
  void toggleEventSave(String id) {
    final index = _allEvents.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      final newValue = !(_allEvents[index]['isSaved'] as bool);
      _allEvents[index]['isSaved'] = newValue;
      notifyListeners();
      
      _firestore.collection('events').doc(id).update({'isSaved': newValue}).catchError((e) => debugPrint('Error: $e'));
    }
  }

  void toggleReminder(String id) {
    final index = _allEvents.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      final newValue = !(_allEvents[index]['hasReminder'] as bool);
      _allEvents[index]['hasReminder'] = newValue;
      notifyListeners();
      
      _firestore.collection('events').doc(id).update({'hasReminder': newValue}).catchError((e) => debugPrint('Error: $e'));
    }
  }

  void registerForEvent(String id, Map<String, dynamic> userInfo) {
    final index = _allEvents.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      final registeredEvent = Map<String, dynamic>.from(_allEvents[index]);
      _myRegisteredEvents.insert(0, registeredEvent);
      
      _firestore.collection('events').doc(id).update({
        'registeredCount': FieldValue.increment(1)
      }).catchError((e) => debugPrint('Error: $e'));
    }
  }

  void markInterested(String id) {
    final index = _allEvents.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      _firestore.collection('events').doc(id).update({
        'interested': FieldValue.increment(1)
      }).catchError((e) => debugPrint('Error: $e'));
    }
  }

  // Owner Method: Mark Attendance
  void markAttendance(String eventId, String userId) {
    final eventIndex = _allEvents.indexWhere((e) => e['id'] == eventId);
    if (eventIndex != -1) {
      final attendees = List<Map<String, dynamic>>.from(_allEvents[eventIndex]['attendees'] ?? []);
      final userIndex = attendees.indexWhere((u) => u['id'] == userId);
      if (userIndex != -1) {
        attendees[userIndex]['attended'] = true;
        _allEvents[eventIndex]['attendees'] = attendees;
        notifyListeners();
        
        _firestore.collection('events').doc(eventId).update({'attendees': attendees}).catchError((e) => debugPrint('Error: $e'));
      }
    }
  }

  // Generic admin methods
  Future<void> addEvent(Map<String, dynamic> event) async {
    // The event Map should include 'gymId' added by the UI
    event['registeredCount'] = 0;
    event['interested'] = 0;
    
    // Optimistic update
    _allEvents.insert(0, event);
    notifyListeners();

    try {
      await _firestore.collection('events').doc(event['id']).set(event);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }
  
  Future<void> updateEvent(Map<String, dynamic> oldEvent, Map<String, dynamic> newEvent) async {
    // Optimistic update
    final index = _allEvents.indexWhere((e) => e['id'] == newEvent['id']);
    if (index != -1) {
      _allEvents[index] = newEvent;
      notifyListeners();
    }

    try {
      await _firestore.collection('events').doc(newEvent['id']).update(newEvent);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }
  
  Future<void> removeEvent(Map<String, dynamic> event) async {
    // Optimistic update
    _allEvents.removeWhere((e) => e['id'] == event['id']);
    notifyListeners();

    try {
      await _firestore.collection('events').doc(event['id']).delete();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }
  
  Future<void> duplicateEvent(Map<String, dynamic> event) async {
    final newEvent = Map<String, dynamic>.from(event);
    newEvent['id'] = 'e_${DateTime.now().millisecondsSinceEpoch}';
    newEvent['title'] = '${newEvent['title']} (Copy)';
    newEvent['registeredCount'] = 0;
    newEvent['interested'] = 0;
    
    // Optimistic update
    _allEvents.insert(0, newEvent);
    notifyListeners();

    try {
      await _firestore.collection('events').doc(newEvent['id']).set(newEvent);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }
}
