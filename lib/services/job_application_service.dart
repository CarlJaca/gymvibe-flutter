import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/job_application_model.dart';
import '../models/application_status_history_model.dart';

/// Handles all Firestore / Storage operations for job applications.
class JobApplicationService {
  JobApplicationService._();
  static final JobApplicationService instance = JobApplicationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final CollectionReference _applicationsRef =
      FirebaseFirestore.instance.collection('jobApplications');

  // ── File upload ─────────────────────────────────────────────────────────────

  /// Allowed file extensions for resume.
  static const List<String> allowedResumeExtensions = ['pdf', 'docx'];

  /// Allowed file extensions for supporting documents.
  static const List<String> allowedSupportExtensions = ['pdf', 'docx', 'jpg', 'jpeg', 'png'];

  /// Max file size in bytes (10 MB).
  static const int maxFileSize = 10 * 1024 * 1024;

  /// Upload a file to Firebase Storage and return the download URL.
  Future<String> uploadFile({
    required String applicantId,
    required String applicationId,
    required String filePath,
    required String fileName,
    bool isSupporting = false,
  }) async {
    final file = File(filePath);

    // Validate file size
    final sizeBytes = await file.length();
    if (sizeBytes > maxFileSize) {
      throw Exception('File size exceeds 10 MB limit.');
    }

    // Validate extension
    final ext = fileName.split('.').last.toLowerCase();
    final allowed = isSupporting ? allowedSupportExtensions : allowedResumeExtensions;
    if (!allowed.contains(ext)) {
      throw Exception('File type .$ext is not allowed. Allowed: ${allowed.join(', ')}');
    }

    final storagePath = isSupporting
        ? 'jobApplications/$applicantId/$applicationId/supporting/$fileName'
        : 'jobApplications/$applicantId/$applicationId/$fileName';

    final ref = _storage.ref().child(storagePath);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // ── Submit application ──────────────────────────────────────────────────────

  /// Submit a job application using a batch write.
  /// Creates the application document AND increments the job's applicationCount.
  Future<String> submitApplication(JobApplicationModel application) async {
    // Check for duplicate application
    final existing = await _applicationsRef
        .where('jobId', isEqualTo: application.jobId)
        .where('applicantId', isEqualTo: application.applicantId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('You have already applied for this job.');
    }

    // Verify job is still active and not expired
    final jobDoc = await _firestore
        .collection('jobPostings')
        .doc(application.jobId)
        .get();
    if (!jobDoc.exists) throw Exception('This job posting no longer exists.');
    final jobData = jobDoc.data()!;
    if (jobData['status'] != 'active') {
      throw Exception('This job is no longer accepting applications.');
    }
    final deadline = jobData['applicationDeadline'];
    if (deadline != null) {
      final deadlineDate = (deadline as Timestamp).toDate();
      if (deadlineDate.isBefore(DateTime.now())) {
        throw Exception('The application deadline has passed.');
      }
    }

    // Use a batch write for atomicity
    final batch = _firestore.batch();

    // Create application document
    final docRef = _applicationsRef.doc();
    final data = application.copyWith(applicationId: docRef.id).toJson();
    data['applicationId'] = docRef.id;
    batch.set(docRef, data);

    // Increment applicationCount on the job posting
    batch.update(
      _firestore.collection('jobPostings').doc(application.jobId),
      {'applicationCount': FieldValue.increment(1)},
    );

    // Add initial status history entry
    final historyRef = docRef.collection('statusHistory').doc();
    final historyEntry = ApplicationStatusHistoryModel(
      historyId: historyRef.id,
      previousStatus: '',
      newStatus: 'submitted',
      changedBy: application.applicantId,
      changedByRole: 'gym_seeker',
      message: 'Application submitted',
    );
    batch.set(historyRef, historyEntry.toJson());

    await batch.commit();
    return docRef.id;
  }

  // ── Withdraw ────────────────────────────────────────────────────────────────

  /// Withdraw an application (only if submitted or under_review).
  Future<void> withdrawApplication({
    required String applicationId,
    required String applicantId,
  }) async {
    final doc = await _applicationsRef.doc(applicationId).get();
    if (!doc.exists) throw Exception('Application not found.');

    final app = JobApplicationModel.fromJson(
        doc.data()! as Map<String, dynamic>, doc.id);

    if (app.applicantId != applicantId) {
      throw Exception('Unauthorized: you can only withdraw your own application.');
    }

    if (!canWithdraw(app.status)) {
      throw Exception(
          'Cannot withdraw application in ${applicationStatusLabel(app.status)} status.');
    }

    final batch = _firestore.batch();

    // Update application status
    batch.update(_applicationsRef.doc(applicationId), {
      'status': 'withdrawn',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Add status history
    final historyRef =
        _applicationsRef.doc(applicationId).collection('statusHistory').doc();
    batch.set(historyRef, ApplicationStatusHistoryModel(
      historyId: historyRef.id,
      previousStatus: applicationStatusToString(app.status),
      newStatus: 'withdrawn',
      changedBy: applicantId,
      changedByRole: 'gym_seeker',
      message: 'Application withdrawn by applicant',
    ).toJson());

    await batch.commit();
  }

  // ── Status update (owner) ───────────────────────────────────────────────────

  /// Update application status with validation and history tracking.
  Future<void> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus newStatus,
    required String changedBy,
    String? message,
    String? rejectionReason,
    String? applicantMessage,
    DateTime? interviewDate,
    String? interviewLocation,
    String? interviewInstructions,
  }) async {
    final doc = await _applicationsRef.doc(applicationId).get();
    if (!doc.exists) throw Exception('Application not found.');

    final app = JobApplicationModel.fromJson(
        doc.data()! as Map<String, dynamic>, doc.id);

    if (!isValidStatusTransition(app.status, newStatus)) {
      throw Exception(
          'Invalid transition: ${applicationStatusLabel(app.status)} → ${applicationStatusLabel(newStatus)}');
    }

    final batch = _firestore.batch();

    // Build update data
    final updateData = <String, dynamic>{
      'status': applicationStatusToString(newStatus),
      'updatedAt': FieldValue.serverTimestamp(),
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': changedBy,
    };

    if (rejectionReason != null) updateData['rejectionReason'] = rejectionReason;
    if (applicantMessage != null) updateData['applicantMessage'] = applicantMessage;
    if (interviewDate != null) {
      updateData['interviewDate'] = Timestamp.fromDate(interviewDate);
    }
    if (interviewLocation != null) updateData['interviewLocation'] = interviewLocation;
    if (interviewInstructions != null) {
      updateData['interviewInstructions'] = interviewInstructions;
    }

    batch.update(_applicationsRef.doc(applicationId), updateData);

    // Add status history
    final historyRef =
        _applicationsRef.doc(applicationId).collection('statusHistory').doc();
    batch.set(historyRef, ApplicationStatusHistoryModel(
      historyId: historyRef.id,
      previousStatus: applicationStatusToString(app.status),
      newStatus: applicationStatusToString(newStatus),
      changedBy: changedBy,
      changedByRole: 'gym_owner',
      message: message,
    ).toJson());

    await batch.commit();
  }

  /// Update the owner's private note.
  Future<void> updateOwnerNote(String applicationId, String note) async {
    await _applicationsRef.doc(applicationId).update({
      'ownerNote': note,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Read (applicant's own applications) ─────────────────────────────────────

  /// Fetch all applications for the current user.
  Future<List<JobApplicationModel>> fetchMyApplications(
      String applicantId) async {
    final snapshot = await _applicationsRef
        .where('applicantId', isEqualTo: applicantId)
        .get();

    final apps = snapshot.docs
        .map((doc) => JobApplicationModel.fromJson(
            doc.data()! as Map<String, dynamic>, doc.id))
        .toList();
        
    apps.sort((a, b) {
      if (a.submittedAt == null && b.submittedAt == null) return 0;
      if (a.submittedAt == null) return 1;
      if (b.submittedAt == null) return -1;
      return b.submittedAt!.compareTo(a.submittedAt!);
    });
    
    return apps;
  }

  /// Check if a user has already applied to a specific job.
  Future<bool> hasApplied(String jobId, String applicantId) async {
    final snapshot = await _applicationsRef
        .where('jobId', isEqualTo: jobId)
        .where('applicantId', isEqualTo: applicantId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // ── Read (owner — applicants for a job) ─────────────────────────────────────

  /// Fetch all applications for a specific job posting.
  Future<List<JobApplicationModel>> fetchJobApplicants(String jobId) async {
    final snapshot = await _applicationsRef
        .where('jobId', isEqualTo: jobId)
        .get();

    final apps = snapshot.docs
        .map((doc) => JobApplicationModel.fromJson(
            doc.data()! as Map<String, dynamic>, doc.id))
        .toList();
        
    apps.sort((a, b) {
      if (a.submittedAt == null && b.submittedAt == null) return 0;
      if (a.submittedAt == null) return 1;
      if (b.submittedAt == null) return -1;
      return b.submittedAt!.compareTo(a.submittedAt!);
    });
    
    return apps;
  }

  /// Fetch a single application by ID.
  Future<JobApplicationModel?> fetchApplicationById(
      String applicationId) async {
    try {
      final doc = await _applicationsRef.doc(applicationId).get();
      if (!doc.exists) return null;
      return JobApplicationModel.fromJson(
          doc.data()! as Map<String, dynamic>, doc.id);
    } catch (e) {
      debugPrint('Error fetching application $applicationId: $e');
      return null;
    }
  }

  // ── Status history ──────────────────────────────────────────────────────────

  /// Fetch the status history for an application.
  Future<List<ApplicationStatusHistoryModel>> fetchStatusHistory(
      String applicationId) async {
    final snapshot = await _applicationsRef
        .doc(applicationId)
        .collection('statusHistory')
        .orderBy('createdAt', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => ApplicationStatusHistoryModel.fromJson(
            doc.data(), doc.id))
        .toList();
  }

  // ── Analytics ───────────────────────────────────────────────────────────────

  /// Get applicant counters for a specific job posting.
  Future<Map<String, int>> getApplicantCounters(String jobId) async {
    final apps = await fetchJobApplicants(jobId);
    final counters = <String, int>{
      'total': apps.length,
      'submitted': 0,
      'under_review': 0,
      'shortlisted': 0,
      'interview': 0,
      'accepted': 0,
      'rejected': 0,
      'withdrawn': 0,
    };
    for (final a in apps) {
      final key = applicationStatusToString(a.status);
      counters[key] = (counters[key] ?? 0) + 1;
    }
    return counters;
  }

  /// Get aggregate applicant analytics across all of an owner's jobs.
  Future<Map<String, int>> getOwnerApplicantAnalytics(String ownerId) async {
    final snapshot = await _applicationsRef
        .where('ownerId', isEqualTo: ownerId)
        .get();

    final counters = <String, int>{
      'total': snapshot.docs.length,
      'submitted': 0,
      'under_review': 0,
      'shortlisted': 0,
      'interview': 0,
      'accepted': 0,
      'rejected': 0,
    };

    for (final doc in snapshot.docs) {
      final data = doc.data()! as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'submitted';
      counters[status] = (counters[status] ?? 0) + 1;
    }
    return counters;
  }
}
