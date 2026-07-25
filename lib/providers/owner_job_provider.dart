import 'package:flutter/material.dart';
import '../models/job_posting_model.dart';
import '../models/job_application_model.dart';
import '../services/job_service.dart';
import '../services/job_application_service.dart';

/// Provider for Gym Owner's job management and applicant review.
class OwnerJobProvider extends ChangeNotifier {
  final JobService _jobService = JobService.instance;
  final JobApplicationService _appService = JobApplicationService.instance;

  List<JobPostingModel> _ownerJobs = [];
  List<JobApplicationModel> _applicants = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Analytics
  Map<String, int> _jobAnalytics = {};
  Map<String, int> _applicantAnalytics = {};

  // ── Getters ──────────────────────────────────────────────────────────────────

  List<JobPostingModel> get ownerJobs => _ownerJobs;
  List<JobPostingModel> get draftJobs =>
      _ownerJobs.where((j) => j.status == JobStatus.draft).toList();
  List<JobPostingModel> get activeJobs =>
      _ownerJobs.where((j) => j.status == JobStatus.active).toList();
  List<JobPostingModel> get closedJobs =>
      _ownerJobs.where((j) => j.status == JobStatus.closed).toList();
  List<JobPostingModel> get filledJobs =>
      _ownerJobs.where((j) => j.status == JobStatus.filled).toList();
  List<JobPostingModel> get archivedJobs =>
      _ownerJobs.where((j) => j.status == JobStatus.archived).toList();

  List<JobApplicationModel> get applicants => _applicants;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  Map<String, int> get jobAnalytics => _jobAnalytics;
  Map<String, int> get applicantAnalytics => _applicantAnalytics;

  // ── Load owner jobs ─────────────────────────────────────────────────────────

  Future<void> loadOwnerJobs(String ownerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _ownerJobs = await _jobService.fetchOwnerJobs(ownerId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Create job ──────────────────────────────────────────────────────────────

  Future<String?> createJobPosting(JobPostingModel job) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final id = await _jobService.createJobPosting(job);
      await loadOwnerJobs(job.ownerId);
      _isSubmitting = false;
      notifyListeners();
      return id;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return null;
    }
  }

  // ── Update job ──────────────────────────────────────────────────────────────

  Future<bool> updateJobPosting(
      String jobId, Map<String, dynamic> data, String ownerId) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _jobService.updateJobPosting(jobId, data);
      await loadOwnerJobs(ownerId);
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

  // ── Status actions ──────────────────────────────────────────────────────────

  Future<bool> publishJob(String jobId, String ownerId) async {
    try {
      await _jobService.publishJob(jobId);
      await loadOwnerJobs(ownerId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> closeJob(String jobId, String ownerId) async {
    try {
      await _jobService.closeJob(jobId);
      await loadOwnerJobs(ownerId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> reopenJob(String jobId, String ownerId) async {
    try {
      await _jobService.reopenJob(jobId);
      await loadOwnerJobs(ownerId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> markJobFilled(String jobId, String ownerId) async {
    try {
      await _jobService.markJobFilled(jobId);
      await loadOwnerJobs(ownerId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> archiveJob(String jobId, String ownerId) async {
    try {
      await _jobService.archiveJob(jobId);
      await loadOwnerJobs(ownerId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<String?> duplicateJob(JobPostingModel job) async {
    try {
      final id = await _jobService.duplicateJob(job);
      await loadOwnerJobs(job.ownerId);
      return id;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // ── Applicants ──────────────────────────────────────────────────────────────

  Future<void> loadApplicants(String jobId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _applicants = await _appService.fetchJobApplicants(jobId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateApplicantStatus({
    required String applicationId,
    required ApplicationStatus newStatus,
    required String changedBy,
    required String jobId,
    String? message,
    String? rejectionReason,
    String? applicantMessage,
    DateTime? interviewDate,
    String? interviewLocation,
    String? interviewInstructions,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      await _appService.updateApplicationStatus(
        applicationId: applicationId,
        newStatus: newStatus,
        changedBy: changedBy,
        message: message,
        rejectionReason: rejectionReason,
        applicantMessage: applicantMessage,
        interviewDate: interviewDate,
        interviewLocation: interviewLocation,
        interviewInstructions: interviewInstructions,
      );
      await loadApplicants(jobId);
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

  Future<bool> updateOwnerNote(String applicationId, String note) async {
    try {
      await _appService.updateOwnerNote(applicationId, note);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Analytics ───────────────────────────────────────────────────────────────

  Future<void> loadAnalytics(String ownerId) async {
    try {
      _jobAnalytics = await _jobService.getOwnerJobAnalytics(ownerId);
      _applicantAnalytics =
          await _appService.getOwnerApplicantAnalytics(ownerId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
