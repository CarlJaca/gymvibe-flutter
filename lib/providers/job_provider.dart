import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/job_posting_model.dart';
import '../services/job_service.dart';

/// Provider for Gym Seeker job browsing.
class JobProvider extends ChangeNotifier {
  final JobService _jobService = JobService.instance;

  List<JobPostingModel> _jobs = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;
  DocumentSnapshot? _lastDocument;

  // Filters
  String _searchQuery = '';
  String? _categoryFilter;
  String? _employmentTypeFilter;
  String? _locationFilter;
  String _sortBy = 'newest'; // newest | deadline | salary

  // Saved / bookmarked jobs (local state)
  final Set<String> _savedJobIds = {};

  // ── Getters ──────────────────────────────────────────────────────────────────

  List<JobPostingModel> get jobs => _jobs;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get categoryFilter => _categoryFilter;
  String? get employmentTypeFilter => _employmentTypeFilter;
  String? get locationFilter => _locationFilter;
  String get sortBy => _sortBy;
  Set<String> get savedJobIds => _savedJobIds;

  bool isJobSaved(String jobId) => _savedJobIds.contains(jobId);

  // ── Load jobs ────────────────────────────────────────────────────────────────

  /// Initial load or refresh.
  Future<void> loadJobs() async {
    _isLoading = true;
    _hasMore = true;
    _lastDocument = null;
    _errorMessage = null;
    notifyListeners();

    try {
      _jobs = await _jobService.fetchActiveJobs(
        limit: 10,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryFilter: _categoryFilter,
        employmentTypeFilter: _employmentTypeFilter,
        locationFilter: _locationFilter,
      );
      _lastDocument = await _jobService.getLastDocumentSnapshot(
        limit: 10,
        categoryFilter: _categoryFilter,
        employmentTypeFilter: _employmentTypeFilter,
      );
      _hasMore = _jobs.length >= 10;
      _applySorting();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load next page.
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;
    notifyListeners();

    try {
      final moreJobs = await _jobService.fetchActiveJobs(
        limit: 10,
        startAfter: _lastDocument,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryFilter: _categoryFilter,
        employmentTypeFilter: _employmentTypeFilter,
        locationFilter: _locationFilter,
      );
      _lastDocument = await _jobService.getLastDocumentSnapshot(
        limit: 10,
        categoryFilter: _categoryFilter,
        employmentTypeFilter: _employmentTypeFilter,
        startAfter: _lastDocument,
      );
      _jobs.addAll(moreJobs);
      _hasMore = moreJobs.length >= 10;
      _applySorting();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Filter / Search / Sort ──────────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadJobs();
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    loadJobs();
  }

  void setEmploymentTypeFilter(String? type) {
    _employmentTypeFilter = type;
    loadJobs();
  }

  void setLocationFilter(String? location) {
    _locationFilter = location;
    loadJobs();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    _applySorting();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _categoryFilter = null;
    _employmentTypeFilter = null;
    _locationFilter = null;
    _sortBy = 'newest';
    loadJobs();
  }

  void _applySorting() {
    switch (_sortBy) {
      case 'deadline':
        _jobs.sort((a, b) {
          if (a.applicationDeadline == null) return 1;
          if (b.applicationDeadline == null) return -1;
          return a.applicationDeadline!.compareTo(b.applicationDeadline!);
        });
        break;
      case 'salary':
        _jobs.sort((a, b) {
          final aS = a.minimumSalary ?? 0;
          final bS = b.minimumSalary ?? 0;
          return bS.compareTo(aS);
        });
        break;
      case 'newest':
      default:
        _jobs.sort((a, b) {
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
    }
  }

  // ── Save / Bookmark ─────────────────────────────────────────────────────────

  void toggleSaveJob(String jobId) {
    if (_savedJobIds.contains(jobId)) {
      _savedJobIds.remove(jobId);
    } else {
      _savedJobIds.add(jobId);
    }
    notifyListeners();
  }
}
