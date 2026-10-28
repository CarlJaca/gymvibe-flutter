import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class PromotionsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _promotionsSubscription;

  // ─── Loyalty & Rewards ───────────────────────────────────────
  int _loyaltyPoints = 1250;
  final String _loyaltyLevel = 'Gold'; // Bronze, Silver, Gold, Platinum

  int get loyaltyPoints => _loyaltyPoints;
  String get loyaltyLevel => _loyaltyLevel;

  Future<void> _seedInitialPromotions() async {
    final defaultPromotions = [
      {
        'id': 'p1',
        'gymId': 'gym1',
        'title': '50% Off Annual Membership',
        'description': 'Get 50% off on any annual membership plan. Perfect for long-term fitness commitment!',
        'dates': 'Valid until Aug 31',
        'type': 'discount',
        'value': 50,
        'reach': 1200,
        'redemptions': 45,
        'claimedCount': 45,
        'totalSlots': 100,
        'isSaved': false,
        'isClaimed': false,
        'claimedUsers': [],
        'terms': [
          'Valid for new annual memberships only',
          'Cannot be combined with other offers',
          'One claim per user',
        ],
        'color': const Color(0xFF00C853).toARGB32(),
        'status': 'Active',
      },
      {
        'id': 'p2',
        'gymId': 'gym1',
        'title': 'Free Personal Training Session',
        'description': 'Enjoy a complimentary personal training session with our certified trainers.',
        'dates': 'Valid until Sep 15',
        'type': 'freebie',
        'value': 0,
        'reach': 850,
        'redemptions': 12,
        'claimedCount': 12,
        'totalSlots': 50,
        'isSaved': false,
        'isClaimed': false,
        'claimedUsers': [],
        'terms': [
          'One free session per member',
          'Must be redeemed within validity period',
          'Subject to trainer availability',
        ],
        'color': const Color(0xFF2962FF).toARGB32(),
        'status': 'Active',
      },
    ];

    for (var p in defaultPromotions) {
      await _firestore.collection('promotions').doc(p['id'] as String).set(p);
    }
  }

  // ─── State ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _active = [];
  final List<Map<String, dynamic>> _myClaimed = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get allPromotions => _active;
  List<Map<String, dynamic>> get active => _active.where((p) => (p['status'] ?? 'Active') == 'Active').toList();
  List<Map<String, dynamic>> get myClaimed => _myClaimed;
  List<Map<String, dynamic>> get scheduled => _active.where((p) => p['status'] == 'Scheduled').toList();
  List<Map<String, dynamic>> get paused => _active.where((p) => p['status'] == 'Paused').toList();
  bool get isLoading => _isLoading;
  
  List<Map<String, dynamic>> get myActiveClaimed => 
      _myClaimed.where((p) => p['status'] == 'Active').toList();
      
  List<Map<String, dynamic>> get myExpiredClaimed => 
      _myClaimed.where((p) => p['status'] == 'Expired').toList();

  // ─── Init (Firestore) ──────────────────────────────────────────────────
  Future<void> loadPromotions() async {
    if (_promotionsSubscription != null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      _promotionsSubscription = _firestore.collection('promotions').snapshots().listen(
        (snapshot) {
          try {
            if (snapshot.docs.isEmpty) {
              _seedInitialPromotions();
            } else {
              _active = snapshot.docs.map((doc) {
                final safeData = Map<String, dynamic>.from(doc.data());
                if (safeData['color'] is int) {
                  safeData['color'] = Color(safeData['color'] as int);
                }
                // Ensure required fields have defaults
                safeData['description'] ??= '';
                safeData['isSaved'] ??= false;
                safeData['isClaimed'] ??= false;
                safeData['claimedCount'] ??= 0;
                safeData['totalSlots'] ??= 100;
                safeData['terms'] ??= <String>[];
                return safeData;
              }).toList();

              // Backfill missing fields in Firestore docs (one-time migration)
              for (var doc in snapshot.docs) {
                final data = doc.data();
                if (!data.containsKey('description') || !data.containsKey('totalSlots')) {
                  doc.reference.set({
                    'description': data['description'] ?? '',
                    'isSaved': data['isSaved'] ?? false,
                    'isClaimed': data['isClaimed'] ?? false,
                    'claimedCount': data['claimedCount'] ?? 0,
                    'totalSlots': data['totalSlots'] ?? 100,
                    'terms': data['terms'] ?? <String>[],
                  }, SetOptions(merge: true)).catchError((e) => debugPrint('Backfill error: $e'));
                }
              }
            }
          } catch (e, stack) {
            debugPrint('Error processing promotions snapshot: $e');
            debugPrint(stack.toString());
          }
          
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Error loading promotions: $e');
          _isLoading = false;
          notifyListeners();
        }
      );
    } catch (e) {
      debugPrint('Sync Error loading promotions stream: $e. Attempting fallback fetch.');
      
      try {
        final snapshot = await _firestore.collection('promotions').get(const GetOptions(source: Source.cache));
        _active = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          if (data['color'] is int) {
            data['color'] = Color(data['color'] as int);
          }
          data['description'] ??= '';
          data['isSaved'] ??= false;
          data['isClaimed'] ??= false;
          data['claimedCount'] ??= 0;
          data['totalSlots'] ??= 100;
          data['terms'] ??= <String>[];
          return data;
        }).toList();
      } catch (inner) {
        debugPrint('Fallback promos cache get() also failed: $inner');
      }

      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── User Actions ──────────────────────────────────────────────────────
  void claimOffer(String id) {
    final index = _active.indexWhere((p) => p['id'] == id);
    if (index != -1) {
      _active[index]['isClaimed'] = true;
      final newCount = ((_active[index]['claimedCount'] as num?) ?? 0).toInt() + 1;
      _active[index]['claimedCount'] = newCount;
      
      // Add to my claimed
      _myClaimed.insert(0, {
        'id': _active[index]['id'],
        'title': _active[index]['title'],
        'dates': _active[index]['dates'],
        'type': _active[index]['type'],
        'color': _active[index]['color'],
        'claimDate': 'Just now',
        'status': 'Active',
        'savings': _active[index]['value'] ?? 0.0, // extract the value
      });
      notifyListeners();

      _firestore.collection('promotions').doc(id).update({
        'claimedCount': newCount,
      }).catchError((e) => debugPrint('Error: $e'));
    }
  }

  void toggleSave(String id) {
    final index = _active.indexWhere((p) => p['id'] == id);
    if (index != -1) {
      final newValue = !((_active[index]['isSaved'] as bool?) ?? false);
      _active[index]['isSaved'] = newValue;
      notifyListeners();

      _firestore.collection('promotions').doc(id).update({
        'isSaved': newValue,
      }).catchError((e) => debugPrint('Error: $e'));
    }
  }

  void redeemPromoCode(String code) {
    // Mock redeem success
    _loyaltyPoints += 100;
    notifyListeners();
  }

  // ─── Owner Management Methods ─────────────────────────────────
  Future<void> addPromotion(Map<String, dynamic> promo) async {
    final newPromo = {
      ...promo,
      'id': 'p_${DateTime.now().millisecondsSinceEpoch}',
      'claimedCount': 0,
      'totalSlots': 100, // default
      'status': 'Active',
      'isSaved': false,
      'isClaimed': false,
      'claimedUsers': [],
    };
    
    // Optimistic update
    _active.insert(0, newPromo);
    notifyListeners();

    try {
      await _firestore.collection('promotions').doc(newPromo['id'] as String).set(newPromo);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> removePromotion(Map<String, dynamic> promo) async {
    // Optimistic update
    _active.removeWhere((p) => p['id'] == promo['id']);
    notifyListeners();

    try {
      await _firestore.collection('promotions').doc(promo['id'] as String).delete();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> duplicatePromotion(Map<String, dynamic> promo) async {
    final copy = Map<String, dynamic>.from(promo);
    copy['id'] = 'p_${DateTime.now().millisecondsSinceEpoch}';
    copy['title'] = '${copy['title']} (Copy)';
    
    // Optimistic update
    _active.insert(0, copy);
    notifyListeners();

    try {
      await _firestore.collection('promotions').doc(copy['id'] as String).set(copy);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> togglePause(Map<String, dynamic> promo) async {
    String newStatus = promo['status'] == 'Active' ? 'Paused' : 'Active';
    
    // Optimistic update
    final index = _active.indexWhere((p) => p['id'] == promo['id']);
    if (index != -1) {
      _active[index]['status'] = newStatus;
      notifyListeners();
    }

    try {
      await _firestore.collection('promotions').doc(promo['id'] as String).update({
        'status': newStatus,
      });
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> updatePromotion(Map<String, dynamic> oldPromo, Map<String, dynamic> newPromo) async {
    // Optimistic update
    final index = _active.indexWhere((p) => p['id'] == newPromo['id']);
    if (index != -1) {
      _active[index] = newPromo;
      notifyListeners();
    }

    try {
      await _firestore.collection('promotions').doc(newPromo['id'] as String).update(newPromo);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }
}
