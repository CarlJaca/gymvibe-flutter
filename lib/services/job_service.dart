import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/job_posting_model.dart';

/// Handles all Firestore operations for the `jobPostings` collection.
class JobService {
  JobService._();
  static final JobService instance = JobService._();

  final CollectionReference _jobsRef =
      FirebaseFirestore.instance.collection('jobPostings');

  // ── Create ──────────────────────────────────────────────────────────────────

  /// Create a new job posting (draft or active).
  Future<String> createJobPosting(JobPostingModel job) async {
    final docRef = _jobsRef.doc();
    final data = job.copyWith(jobId: docRef.id).toJson();
    data['jobId'] = docRef.id;
    await docRef.set(data);
    return docRef.id;
  }

  // ── Update ──────────────────────────────────────────────────────────────────

  /// Update an existing job posting.
  Future<void> updateJobPosting(String jobId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _jobsRef.doc(jobId).update(data);
  }

  /// Publish a draft job (set status to active).
  Future<void> publishJob(String jobId) async {
    await _jobsRef.doc(jobId).update({
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Close applications for a job.
  Future<void> closeJob(String jobId) async {
    await _jobsRef.doc(jobId).update({
      'status': 'closed',
      'closedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reopen a closed job (only if deadline hasn't passed).
  Future<void> reopenJob(String jobId) async {
    final doc = await _jobsRef.doc(jobId).get();
    if (!doc.exists) throw Exception('Job not found');
    final job = JobPostingModel.fromJson(
        doc.data()! as Map<String, dynamic>, doc.id);
    if (job.isExpired) throw Exception('Cannot reopen — deadline has passed');
    await _jobsRef.doc(jobId).update({
      'status': 'active',
      'closedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark job as filled.
  Future<void> markJobFilled(String jobId) async {
    await _jobsRef.doc(jobId).update({
      'status': 'filled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Archive a job.
  Future<void> archiveJob(String jobId) async {
    await _jobsRef.doc(jobId).update({
      'status': 'archived',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Duplicate ───────────────────────────────────────────────────────────────

  /// Duplicate a job posting as a new draft.
  Future<String> duplicateJob(JobPostingModel original) async {
    final duplicate = original.copyWith(
      jobId: '',
      status: JobStatus.draft,
      applicationCount: 0,
      createdAt: null,
      updatedAt: null,
      closedAt: null,
    );
    return createJobPosting(duplicate);
  }

  // ── Read (Gym Seeker — active jobs only) ────────────────────────────────────

  /// Fetch active, non-expired job postings with pagination.
  Future<List<JobPostingModel>> fetchActiveJobs({
    DocumentSnapshot? startAfter,
    int limit = 10,
    String? searchQuery,
    String? categoryFilter,
    String? employmentTypeFilter,
    String? locationFilter,
  }) async {
    // Increase limit to ensure we get enough jobs after client-side filtering
    Query query = _jobsRef
        .orderBy('createdAt', descending: true)
        .limit(limit * 3);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final now = DateTime.now();

    final jobs = snapshot.docs.map((doc) {
      return JobPostingModel.fromJson(
          doc.data()! as Map<String, dynamic>, doc.id);
    }).where((job) {
      // Must be active
      if (job.status.name != 'active') return false;

      // Exclude expired jobs client-side
      if (job.applicationDeadline != null &&
          job.applicationDeadline!.isBefore(now)) {
        return false;
      }
      
      // Client-side category filter
      if (categoryFilter != null && categoryFilter.isNotEmpty) {
        if (job.jobCategory != categoryFilter) return false;
      }
      
      // Client-side employment type filter
      if (employmentTypeFilter != null && employmentTypeFilter.isNotEmpty) {
        if (job.employmentType.name != employmentTypeFilter) return false;
      }

      // Client-side search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        if (!job.jobTitle.toLowerCase().contains(q) &&
            !job.gymName.toLowerCase().contains(q)) {
          return false;
        }
      }
      // Client-side location filter
      if (locationFilter != null && locationFilter.isNotEmpty) {
        if (!job.location.toLowerCase().contains(locationFilter.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();

    // Take only up to the requested limit
    return jobs.take(limit).toList();
  }

  /// Get the last document snapshot for pagination cursors.
  Future<DocumentSnapshot?> getLastDocumentSnapshot({
    int limit = 10,
    String? categoryFilter,
    String? employmentTypeFilter,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _jobsRef
        .orderBy('createdAt', descending: true)
        .limit(limit * 3);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.last;
    }
    return null;
  }

  // ── Read (Gym Owner — own jobs) ─────────────────────────────────────────────

  /// Fetch all job postings belonging to a specific owner.
  Future<List<JobPostingModel>> fetchOwnerJobs(String ownerId) async {
    final snapshot = await _jobsRef
        .where('ownerId', isEqualTo: ownerId)
        .get();

    final jobs = snapshot.docs.map((doc) {
      return JobPostingModel.fromJson(
          doc.data()! as Map<String, dynamic>, doc.id);
    }).toList();
    
    jobs.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    
    return jobs;
  }

  /// Fetch a single job posting by ID.
  Future<JobPostingModel?> fetchJobById(String jobId) async {
    try {
      final doc = await _jobsRef.doc(jobId).get();
      if (!doc.exists) return null;
      return JobPostingModel.fromJson(
          doc.data()! as Map<String, dynamic>, doc.id);
    } catch (e) {
      debugPrint('Error fetching job $jobId: $e');
      return null;
    }
  }

  // ── Analytics ───────────────────────────────────────────────────────────────

  /// Get simple analytics for a gym owner.
  Future<Map<String, int>> getOwnerJobAnalytics(String ownerId) async {
    final jobs = await fetchOwnerJobs(ownerId);

    int totalActive = 0;
    int totalApplicants = 0;

    for (final job in jobs) {
      if (job.status == JobStatus.active) totalActive++;
      totalApplicants += job.applicationCount;
    }

    return {
      'totalActive': totalActive,
      'totalApplicants': totalApplicants,
      'totalJobs': jobs.length,
    };
  }
}
