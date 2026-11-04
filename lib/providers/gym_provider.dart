import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gym_model.dart';
import '../data/gym_repository.dart';
import '../services/recommendation_service.dart';

class GymProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<GymModel> _allGyms = [];
  List<GymModel> _filteredGyms = [];
  GymModel? _selectedGym;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  String? _selectedCity;
  final Set<String> _activeFilters = {};
  final List<String> _searchHistory = [
    'Dstars Fitness Gym',
    'Anytime Fitness',
    'CrossFit Madayaw'
  ];

  // Advanced Filters
  RangeValues? _advancedBudgetRange;
  String? _advancedTrainerAvailability;
  String? _advancedFitnessGoal;

  // Currently logged-in owner's user ID and fallback name
  String? _currentOwnerId;
  String? _fallbackGymName;

  // User fitness preferences for Jaccard recommendations
  List<String> _userPreferences = [];

  // Jaccard match results with scores
  List<GymMatchResult> _matchResults = [];

  bool _datasetLoaded = false;

  // ─── Getters ────────────────────────────────────────────────────────────────
  /// Returns the gym belonging to the currently logged-in owner.
  /// Looks up by ownerId from the full gym list.
  GymModel get ownerGym {
    if (_currentOwnerId != null) {
      final match = _allGyms.where((g) => g.ownerId == _currentOwnerId);
      if (match.isNotEmpty) return match.first;
    }
    // Fallback: return a placeholder with the registered gym name if available
    return GymModel(
      id: _currentOwnerId != null ? 'gym_$_currentOwnerId' : 'placeholder',
      ownerId: _currentOwnerId,
      name: _fallbackGymName ?? 'No Gym Registered',
      imageUrl:
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80',
      address: 'Please complete your gym profile in settings.',
      city: 'Unknown',
      hours: 'N/A',
      rating: 0.0,
      reviewCount: 0,
      isOpen: false,
    );
  }

  List<GymModel> get gyms => _filteredGyms;
  List<GymModel> get allGyms => _allGyms;
  List<GymModel> get topRatedGyms => List<GymModel>.from(_allGyms)
    ..sort((a, b) => b.rating.compareTo(a.rating));
  List<GymModel> get favoriteGyms =>
      _allGyms.where((g) => g.isFavorite).toList();
  List<GymModel> get savedGyms => _allGyms.where((g) => g.isSaved).toList();

  /// Returns gyms ranked by Jaccard similarity to the user's preferences.
  /// Delegates to matchResults for consistency.
  List<GymModel> get recommendedGyms {
    if (_matchResults.isNotEmpty) {
      return _matchResults.map((r) => r.gym).toList();
    }
    if (_userPreferences.isEmpty) {
      // Fallback: show top gyms for new users before preferences are configured
      return _allGyms.take(5).toList();
    }
    return RecommendationService.getRecommendedGyms(
      userPreferences: _userPreferences,
      allGyms: _allGyms,
      limit: 10,
    );
  }

  /// Returns full Jaccard match results with scores and matched attributes.
  List<GymMatchResult> get matchResults => _matchResults;

  List<String> get userPreferences => _userPreferences;
  GymModel? get selectedGym => _selectedGym;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCity => _selectedCity;
  Set<String> get activeFilters => _activeFilters;
  List<String> get searchHistory => _searchHistory;
  String? get currentOwnerId => _currentOwnerId;

  RangeValues? get advancedBudgetRange => _advancedBudgetRange;
  String? get advancedTrainerAvailability => _advancedTrainerAvailability;
  String? get advancedFitnessGoal => _advancedFitnessGoal;

  /// Set the current owner info (called on login)
  void setCurrentOwner(String? ownerId, {String? gymName}) {
    _currentOwnerId = ownerId;
    if (gymName != null && gymName.isNotEmpty) {
      _fallbackGymName = gymName;
    }
    notifyListeners();
  }

  /// Update user preferences and refresh recommendations.
  /// Called from the Profile preferences screen.
  void setUserPreferences(List<String> preferences) {
    _userPreferences = List<String>.from(preferences);
    calculateMatches();
    notifyListeners();
  }

  /// Recalculates Jaccard similarity matches using current preferences.
  void calculateMatches() {
    if (_userPreferences.isEmpty || _allGyms.isEmpty) {
      _matchResults = [];
      return;
    }
    _matchResults = RecommendationService.getRecommendedGymsWithScores(
      userPreferences: _userPreferences,
      allGyms: _allGyms,
      limit: 15,
    );
  }

  // ─── Init (Dataset + Firestore for owner gyms) ─────────────────────────────
  Future<void> loadGyms() async {
    if (_datasetLoaded) return; // Already loaded

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Primary source: bundled JSON dataset (15 real Davao gyms)
      final datasetGyms = await GymRepository.instance.loadAll();
      _allGyms = List<GymModel>.from(datasetGyms);

      // Also load any owner-registered gyms from Firestore (supplementary)
      try {
        final snapshot = await _firestore.collection('gyms').get();
        for (final doc in snapshot.docs) {
          final firestoreGym = GymModel.fromJson(
            Map<String, dynamic>.from(doc.data()),
            doc.id,
          );
          // Only add if not already in dataset (avoid duplicates)
          if (!_allGyms.any((g) => g.id == firestoreGym.id)) {
            _allGyms.add(firestoreGym);
          }
        }
      } catch (e) {
        debugPrint('Firestore supplementary load skipped: $e');
        // Non-fatal — dataset gyms are still loaded
      }

      _datasetLoaded = true;
      _applyFilter();
      calculateMatches();
    } catch (e) {
      debugPrint('Error loading gyms from dataset: $e');
      _errorMessage = 'Failed to load gym data.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Select Gym ─────────────────────────────────────────────────────────────
  void selectGym(GymModel gym) {
    _selectedGym = gym;
    notifyListeners();
  }

  void clearSelectedGym() {
    _selectedGym = null;
    notifyListeners();
  }

  // ─── Toggle Favorite & Saved ────────────────────────────────────────────────
  void toggleFavorite(String gymId) {
    final index = _allGyms.indexWhere((g) => g.id == gymId);
    if (index != -1) {
      _allGyms[index].isFavorite = !_allGyms[index].isFavorite;
      _applyFilter();
      notifyListeners();
    }
  }

  bool isFavorite(String gymId) {
    final gym = _allGyms.firstWhere(
      (g) => g.id == gymId,
      orElse: () => GymModel(
        id: '',
        name: '',
        imageUrl: '',
        address: '',
        city: '',
        hours: '',
        rating: 0,
        reviewCount: 0,
        isOpen: false,
      ),
    );
    return gym.isFavorite;
  }

  void toggleSaved(String gymId) {
    final index = _allGyms.indexWhere((g) => g.id == gymId);
    if (index != -1) {
      _allGyms[index].isSaved = !_allGyms[index].isSaved;
      _applyFilter();
      notifyListeners();
    }
  }

  bool isSaved(String gymId) {
    final gym = _allGyms.firstWhere(
      (g) => g.id == gymId,
      orElse: () => GymModel(
        id: '',
        name: '',
        imageUrl: '',
        address: '',
        city: '',
        hours: '',
        rating: 0,
        reviewCount: 0,
        isOpen: false,
      ),
    );
    return gym.isSaved;
  }

  // ─── Search & Filters ────────────────────────────────────────────────────────
  void setCity(String? city) {
    _selectedCity = city;
    _applyFilter();
    notifyListeners();
  }

  void toggleFilter(String filter) {
    if (_activeFilters.contains(filter)) {
      _activeFilters.remove(filter);
    } else {
      _activeFilters.add(filter);
    }
    _applyFilter();
    notifyListeners();
  }

  void clearFilters() {
    _activeFilters.clear();
    _applyFilter();
    notifyListeners();
  }

  void addSearchHistory(String term) {
    if (term.trim().isEmpty) return;
    _searchHistory.remove(term);
    _searchHistory.insert(0, term);
    if (_searchHistory.length > 10) _searchHistory.removeLast();
    notifyListeners();
  }

  void removeSearchHistory(String term) {
    _searchHistory.remove(term);
    notifyListeners();
  }

  void clearSearchHistory() {
    _searchHistory.clear();
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilter();
    notifyListeners();
  }

  void setAdvancedFilters({
    RangeValues? budgetRange,
    String? trainer,
    String? goal,
    String? location,
  }) {
    _advancedBudgetRange = budgetRange;
    _advancedTrainerAvailability = trainer;
    _advancedFitnessGoal = goal;

    // Map advanced filter location to existing city filter if necessary
    if (location != null && location != 'Current Location') {
      _selectedCity = location;
    } else if (location == 'Current Location') {
      _selectedCity = null; // Maybe handle GPS locally in the future
    }

    _applyFilter();
    notifyListeners();
  }

  void clearAdvancedFilters() {
    _advancedBudgetRange = null;
    _advancedTrainerAvailability = null;
    _advancedFitnessGoal = null;
    _selectedCity = null;
    _activeFilters.clear();
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    var tempList = List<GymModel>.from(_allGyms);

    if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      tempList = tempList
          .where((g) => g.city.toLowerCase() == _selectedCity!.toLowerCase())
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      // Filter: name/branch starts with query, OR address/city/branch contains query
      tempList = tempList
          .where((g) =>
              g.name.toLowerCase().startsWith(q) ||
              g.branch.toLowerCase().contains(q) ||
              g.address.toLowerCase().contains(q) ||
              g.city.toLowerCase().contains(q))
          .toList();

      // Sort: name-starts-with matches come first, then others
      tempList.sort((a, b) {
        final aStarts = a.name.toLowerCase().startsWith(q) ? 0 : 1;
        final bStarts = b.name.toLowerCase().startsWith(q) ? 0 : 1;
        return aStarts.compareTo(bStarts);
      });
    }

    if (_activeFilters.isNotEmpty) {
      for (final filter in _activeFilters) {
        final f = filter.toLowerCase();
        tempList = tempList.where((g) {
          if (f.contains('24 hour') &&
              g.hours.toLowerCase().contains('24 hour')) return true;
          if (f.contains('budget') && g.monthlyPrice == '₱') return true;
          if (f.contains('premium') &&
              (g.monthlyPrice == '₱₱₱' || g.monthlyPrice == '₱₱')) return true;
          return g.facilities.any((fac) => fac.toLowerCase().contains(f)) ||
              g.description.toLowerCase().contains(f);
        }).toList();
      }
    }

    // Apply Advanced Filters
    if (_advancedBudgetRange != null) {
      tempList = tempList.where((g) {
        // Use sessionPricePhp if available, else parse from string
        final price = g.sessionPricePhp > 0
            ? g.sessionPricePhp.toDouble()
            : (() {
                final match = RegExp(r'[\d,]+').firstMatch(g.sessionPrice);
                return match != null
                    ? (double.tryParse(match.group(0)!.replaceAll(',', '')) ??
                        0.0)
                    : 0.0;
              })();
        return price >= _advancedBudgetRange!.start &&
            price <= _advancedBudgetRange!.end;
      }).toList();
    }

    if (_advancedTrainerAvailability != null) {
      if (_advancedTrainerAvailability == 'With Trainer') {
        tempList = tempList
            .where((g) =>
                g.trainerAvailability.isNotEmpty ||
                g.description.toLowerCase().contains('trainer') ||
                g.description.toLowerCase().contains('coach') ||
                g.facilities.any((f) => f.toLowerCase().contains('trainer')))
            .toList();
      } else if (_advancedTrainerAvailability == 'Without Trainer') {
        tempList = tempList
            .where((g) =>
                g.trainerAvailability.isEmpty &&
                !g.description.toLowerCase().contains('trainer') &&
                !g.description.toLowerCase().contains('coach'))
            .toList();
      }
    }

    if (_advancedFitnessGoal != null && _advancedFitnessGoal!.isNotEmpty) {
      final goal = _advancedFitnessGoal!.toLowerCase();
      tempList = tempList
          .where((g) =>
              g.description.toLowerCase().contains(goal) ||
              g.categories.any((c) => c.toLowerCase().contains(goal)))
          .toList();
    }

    _filteredGyms = tempList;
  }

  Future<void> addGym(GymModel newGym) async {
    // Save to Firestore
    try {
      await _firestore.collection('gyms').doc(newGym.id).set(newGym.toJson());
    } catch (e) {
      debugPrint('Error adding gym: $e');
    }
    _allGyms.add(newGym);
    _applyFilter();
    notifyListeners();
  }

  Future<void> updateOwnerGym(GymModel updatedGym) async {
    // Save to Firestore (use set with merge to create if it doesn't exist)
    try {
      await _firestore
          .collection('gyms')
          .doc(updatedGym.id)
          .set(updatedGym.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating gym: $e');
    }
    // Optimistic update
    final index = _allGyms.indexWhere((g) => g.id == updatedGym.id);
    if (index != -1) {
      _allGyms[index] = updatedGym;
    } else {
      _allGyms.add(updatedGym);
    }

    _applyFilter();
    notifyListeners();
  }

  // ─── Analytics Updates ───────────────────────────────────────────────────────
  Future<void> joinGym(String gymId) async {
    try {
      final gymRef = _firestore.collection('gyms').doc(gymId);
      await gymRef.update({'memberCount': FieldValue.increment(1)});
    } catch (e) {
      debugPrint('Error joining gym: $e');
    }
  }

  Future<void> addBooking(String gymId) async {
    try {
      final gymRef = _firestore.collection('gyms').doc(gymId);
      await gymRef.update({'bookingsCount': FieldValue.increment(1)});
    } catch (e) {
      debugPrint('Error adding booking: $e');
    }
  }

  Future<void> addReview(String gymId, ReviewModel review) async {
    final index = _allGyms.indexWhere((g) => g.id == gymId);
    if (index == -1) return;

    final gym = _allGyms[index];
    final newReviews = List<ReviewModel>.from(gym.reviews)..insert(0, review);

    // Recalculate rating
    double totalRating = 0.0;
    for (var r in newReviews) {
      totalRating += r.rating;
    }
    final newRating =
        newReviews.isEmpty ? 0.0 : totalRating / newReviews.length;
    final newReviewCount = newReviews.length;

    final updatedGym = gym.copyWith(
      reviews: newReviews,
      rating: newRating,
      reviewCount: newReviewCount,
    );

    _allGyms[index] = updatedGym;
    if (_selectedGym?.id == gymId) {
      _selectedGym = updatedGym;
    }
    _applyFilter();
    notifyListeners();

    try {
      await _firestore.collection('gyms').doc(gymId).update({
        'reviews': newReviews.map((r) => r.toJson()).toList(),
        'rating': newRating,
        'reviewCount': newReviewCount,
      });
    } catch (e) {
      debugPrint('Error adding review: $e');
    }
  }
}
