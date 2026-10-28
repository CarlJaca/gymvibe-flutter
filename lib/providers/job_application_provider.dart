import 'package:flutter/material.dart';
import '../models/job_application_model.dart';
import '../models/application_status_history_model.dart';
import '../services/job_application_service.dart';

/// Provider for Gym Seeker's job applications.
class JobApplicationProvider extends ChangeNotifier {
  final JobApplicationService _service = JobApplicationService.instance;

  List<JobApplicationModel> _myApplications = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _statusFilter;

  // Applied job IDs cache for quick lookup
  final Set<String> _appliedJobIds = {};

  // ── Getters ──────────────────────────────────────────────────────────────────

  List<JobApplicationModel> get myApplications {
    if (_statusFilter == null || _statusFilter == 'all') return _myApplications;
    final filterStatus = stringToApplicationStatus(_statusFilter);
    return _myApplications.where((a) => a.status == filterStatus).toList();
  }

  List<JobApplicationModel> get allApplications => _myApplications;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get statusFilter => _statusFilter;
  Set<String> get appliedJobIds => _appliedJobIds;

  bool hasAppliedTo(String jobId) => _appliedJobIds.contains(jobId);

  // ── Load applications ───────────────────────────────────────────────────────

  Future<void> loadMyApplications(String applicantId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myApplications = await _service.fetchMyApplications(applicantId);
      _appliedJobIds.clear();
      for (final app in _myApplications) {
        _appliedJobIds.add(app.jobId);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Submit application ──────────────────────────────────────────────────────

  Future<bool> submitApplication(JobApplicationModel application) async {
    if (_isSubmitting) return false; // prevent double-tap
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.submitApplication(application);
      _appliedJobIds.add(application.jobId);
      // Refresh list
      await loadMyApplications(application.applicantId);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ── Withdraw ────────────────────────────────────────────────────────────────

  Future<bool> withdrawApplication({
    required String applicationId,
    required String applicantId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.withdrawApplication(
        applicationId: applicationId,
        applicantId: applicantId,
      );
      await loadMyApplications(applicantId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Check if already applied ────────────────────────────────────────────────

  Future<bool> checkHasApplied(String jobId, String applicantId) async {
    final result = await _service.hasApplied(jobId, applicantId);
    if (result) _appliedJobIds.add(jobId);
    return result;
  }

  // ── Status history ──────────────────────────────────────────────────────────

  Future<List<ApplicationStatusHistoryModel>> getStatusHistory(
      String applicationId) async {
    return _service.fetchStatusHistory(applicationId);
  }

  // ── Filter ──────────────────────────────────────────────────────────────────

  void setStatusFilter(String? filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  // ── File upload ─────────────────────────────────────────────────────────────

  Future<String> uploadResume({
    required String applicantId,
    required String applicationId,
    required String filePath,
    required String fileName,
  }) async {
    return _service.uploadFile(
      applicantId: applicantId,
      applicationId: applicationId,
      filePath: filePath,
      fileName: fileName,
    );
  }

  Future<String> uploadSupportingDocument({
    required String applicantId,
    required String applicationId,
    required String filePath,
    required String fileName,
  }) async {
    return _service.uploadFile(
      applicantId: applicantId,
      applicationId: applicationId,
      filePath: filePath,
      fileName: fileName,
      isSupporting: true,
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
