import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/gym_model.dart';
import '../models/leaderboard_model.dart';
import '../models/content_report_model.dart';
import '../models/admin_notification_model.dart';
import '../models/app_settings_model.dart';
import 'audit_log_service.dart';

class SuperAdminService {
  SuperAdminService._();
  static final SuperAdminService instance = SuperAdminService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditLogService _auditLog = AuditLogService.instance;

  // ═══════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ═══════════════════════════════════════════════════════════════════

  /// Get aggregated dashboard statistics from live Firestore data.
  Future<Map<String, int>> getDashboardStats() async {
    final results = await Future.wait([
      _firestore.collection('users').count().get(),
      _firestore.collection('users').where('role', isEqualTo: 'gym_seeker').count().get(),
      _firestore.collection('users').where('role', isEqualTo: 'gym_owner').count().get(),
      _firestore.collection('users').where('role', isEqualTo: 'gym_owner').where('accountStatus', isEqualTo: 'pending').count().get(),
      _firestore.collection('gyms').count().get(),
      _firestore.collection('bookings').count().get(),
      _firestore.collection('events').count().get(),
      _firestore.collection('promotions').count().get(),
      _firestore.collection('users').where('accountStatus', isEqualTo: 'suspended').count().get(),
      _firestore.collection('contentReports').where('status', isEqualTo: 'pending').count().get(),
    ]);

    // Personal records require collection group queries
    int verifiedPRs = 0;
    int pendingPRs = 0;
    try {
      final verifiedSnap = await _firestore.collectionGroup('personalRecords').where('status', isEqualTo: 'verified').count().get();
      verifiedPRs = verifiedSnap.count ?? 0;
      final pendingSnap = await _firestore.collectionGroup('personalRecords').where('status', isEqualTo: 'pending').count().get();
      pendingPRs = pendingSnap.count ?? 0;
    } catch (_) {
      // Collection group index might not exist yet
    }

    return {
      'totalUsers': results[0].count ?? 0,
      'gymSeekers': results[1].count ?? 0,
      'gymOwners': results[2].count ?? 0,
      'pendingOwners': results[3].count ?? 0,
      'approvedGyms': results[4].count ?? 0,
      'totalBookings': results[5].count ?? 0,
      'activeEvents': results[6].count ?? 0,
      'activePromotions': results[7].count ?? 0,
      'suspendedUsers': results[8].count ?? 0,
      'reportedContent': results[9].count ?? 0,
      'verifiedPRs': verifiedPRs,
      'pendingPRs': pendingPRs,
    };
  }

  // ═══════════════════════════════════════════════════════════════════
  // USER MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════

  /// Get all users with optional search, filter, and pagination.
  Future<List<UserModel>> getAllUsers({
    String? searchQuery,
    String? roleFilter,
    String? statusFilter,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore.collection('users').orderBy('name');

    if (roleFilter != null && roleFilter.isNotEmpty) {
      query = query.where('role', isEqualTo: roleFilter);
    }

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('accountStatus', isEqualTo: statusFilter);
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    List<UserModel> users = snapshot.docs.map((doc) {
      return UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();

    // Client-side search (Firestore lacks full-text search)
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      users = users.where((u) {
        return u.name.toLowerCase().contains(lowerQuery) ||
            u.email.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    return users;
  }

  /// Get total user count with optional role filter.
  Future<int> getUserCount({String? roleFilter}) async {
    Query query = _firestore.collection('users');
    if (roleFilter != null && roleFilter.isNotEmpty) {
      query = query.where('role', isEqualTo: roleFilter);
    }
    final result = await query.count().get();
    return result.count ?? 0;
  }

  /// Get a single user's details.
  Future<UserModel?> getUserDetails(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  /// Get bookings for a specific user.
  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Get personal records for a specific user across all gyms.
  Future<List<PersonalRecord>> getUserPRs(String userId) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('personalRecords')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) {
        return PersonalRecord.fromJson(doc.data(), doc.id);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Suspend a user account.
  Future<void> suspendUser({
    required String userId,
    required String reason,
    required String adminId,
    required String adminName,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'accountStatus': 'suspended',
    });

    await _auditLog.logAction(
      actorId: adminId,
      actorName: adminName,
      action: 'user_suspended',
      targetType: 'user',
      targetId: userId,
      reason: reason,
      description: 'Suspended user account',
    );
  }

  /// Reactivate a suspended user.
  Future<void> reactivateUser({
    required String userId,
    required String adminId,
    required String adminName,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'accountStatus': 'active',
    });

    await _auditLog.logAction(
      actorId: adminId,
      actorName: adminName,
      action: 'user_reactivated',
      targetType: 'user',
      targetId: userId,
      description: 'Reactivated user account',
    );
  }

  /// Deactivate a user account (soft delete).
  Future<void> deactivateUser({
    required String userId,
    required String reason,
    required String adminId,
    required String adminName,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'accountStatus': 'deactivated',
    });

    await _auditLog.logAction(
      actorId: adminId,
      actorName: adminName,
      action: 'user_deactivated',
      targetType: 'user',
      targetId: userId,
      reason: reason,
      description: 'Deactivated user account',
    );
  }

  /// Change a user's role (with validation).
  Future<void> changeUserRole({
    required String userId,
    required String newRole,
    required String adminId,
    required String adminName,
  }) async {
    // Prevent assigning super_admin role
    if (newRole == 'super_admin') {
      throw Exception('Cannot assign Super Admin role through this interface.');
    }

    // Prevent changing own role
    if (userId == adminId) {
      throw Exception('Cannot change your own role.');
    }

    final validRoles = ['gym_seeker', 'gym_owner'];
    if (!validRoles.contains(newRole)) {
      throw Exception('Invalid role: $newRole');
    }

    await _firestore.collection('users').doc(userId).update({
      'role': newRole,
      'isOwner': newRole == 'gym_owner',
    });

    await _auditLog.logAction(
      actorId: adminId,
      actorName: adminName,
      action: 'role_changed',
      targetType: 'user',
      targetId: userId,
      description: 'Changed user role to $newRole',
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // GYM OWNER APPROVALS
  // ═══════════════════════════════════════════════════════════════════

  /// Get pending gym owner applications.
  Future<List<UserModel>> getPendingOwnerApplications() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'gym_owner')
        .where('accountStatus', isEqualTo: 'pending')
        .get();

    return snapshot.docs.map((doc) {
      return UserModel.fromJson(doc.data(), doc.id);
    }).toList();
  }

  /// Get approved owner applications.
  Future<List<UserModel>> getApprovedOwnerApplications() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'gym_owner')
        .where('accountStatus', isEqualTo: 'active')
        .get();

    return snapshot.docs.map((doc) {
      return UserModel.fromJson(doc.data(), doc.id);
    }).toList();
  }

  /// Get rejected owner applications.
  Future<List<UserModel>> getRejectedOwnerApplications() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'gym_owner')
        .where('accountStatus', isEqualTo: 'rejected')
        .get();

    return snapshot.docs.map((doc) {
      return UserModel.fromJson(doc.data(), doc.id);
    }).toList();
  }

  /// Approve a gym owner application (batch write to user + gym).
  Future<void> approveOwner({
    required String userId,
    required String adminId,
    required String adminName,
  }) async {
    final batch = _firestore.batch();

    // Update user status
    batch.update(_firestore.collection('users').doc(userId), {
      'accountStatus': 'active',
      'approvedBy': adminId,
      'approvedAt': FieldValue.serverTimestamp(),
    });

    // Find and update associated gym
    final gymSnapshot = await _firestore
        .collection('gyms')
        .where('ownerId', isEqualTo: userId)
        .limit(1)
        .get();

    if (gymSnapshot.docs.isNotEmpty) {
      batch.update(gymSnapshot.docs.first.reference, {
        'isVerified': true,
        'verifiedBy': adminId,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    await _auditLog.logAction(
      actorId: adminId,
      actorName: adminName,
      action: 'owner_approved',
      targetType: 'user',
      targetId: userId,
      description: 'Approved gym owner application',
    );
  }

  /// Reject a gym owner application.
  Future<void> rejectOwner({
    required String userId,
    required String reason,
    required String adminId,
    required String adminName,
  }) async {
    final batch = _firestore.batch();

    batch.update(_firestore.collection('users').doc(userId), {
      'accountStatus': 'rejected',
      'rejectionReason': reason,
      'rejectedBy': adminId,
      'rejectedAt': FieldValue.serverTimestamp(),
    });

    // Also update gym if exists
    final gymSnapshot = await _firestore
        .collection('gyms')
        .where('ownerId', isEqualTo: userId)
        .limit(1)
        .get();

    if (gymSnapshot.docs.isNotEmpty) {
      batch.update(gymSnapshot.docs.first.reference, {
        'isVerified': false,
        'status': 'rejected',
      });
    }

    await batch.commit();

    await _auditLog.logAction(
      actorId: adminId,
      actorName: adminName,
      action: 'owner_rejected',
      targetType: 'user',
      targetId: userId,
      reason: reason,
      description: 'Rejected gym owner application',
    );
  }

  /// Request additional information from owner applicant.
  Future<void> requestOwnerInfo({
    required String userId,
    required String message,
    required String adminId,
    required String adminName,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'accountStatus': 'info_requested',
      'infoRequestMessage': message,
      'infoRequestedBy': adminId,
      'infoRequestedAt': FieldValue.serverTimestamp(),
    });

    await _auditLog.logAction(
      actorId: adminId,
      actorName: adminName,
      action: 'owner_info_requested',
      targetType: 'user',
      targetId: userId,
      description: 'Requested additional information from gym owner applicant',
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // GYM OVERSIGHT
  // ═══════════════════════════════════════════════════════════════════

  /// Get all gyms with optional search and filter.
  Future<List<GymModel>> getAllGyms({
    String? searchQuery,
    String? statusFilter,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore.collection('gyms').orderBy('name');

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    List<GymModel> gyms = snapshot.docs.map((doc) {
      return GymModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      gyms = gyms.where((g) {
        return g.name.toLowerCase().contains(lowerQuery) ||
            g.address.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    return gyms;
  }

  /// Get gym owner details for a gym.
  Future<UserModel?> getGymOwner(String ownerId) async {
    return getUserDetails(ownerId);
  }

  /// Suspend a gym.
  Future<void> suspendGym({
    required String gymId,
    required String reason,
    required String adminId,
    required String adminName,
  }) async {
    await _firestore.collection('gyms').doc(gymId).update({
      'status': 'suspended',
      'isOpen': false,
    });

    await _auditLog.logAction(
      actorId: adminId,
      actorName: adminName,
      action: 'gym_suspended',
      targetType: 'gym',
      targetId: gymId,
      reason: reason,
      description: 'Suspended gym',
    );
  }

  /// Reactivate a gym.
  Future<void> reactivateGym({
    required String gymId,
    required String adminId,
    required String adminName,
  }) async {
    await _firestore.collection('gyms').doc(gymId).update({
      'status': 'active',
      'isOpen': true,
    });

    await _auditLog.logAction(
      actorId: adminId,
      actorName: adminName,
      action: 'gym_reactivated',
      targetType: 'gym',
      targetId: gymId,
      description: 'Reactivated gym',
    );
  }

  /// Flag a gym for review.
  Future<void> flagGym({
    required String gymId,
    required String reason,
    required String adminId,
    required String adminName,
  }) async {
    await _firestore.collection('gyms').doc(gymId).update({
      'status': 'flagged',
      'flagReason': reason,
    });

    await _auditLog.logAction(
      actorId: adminId,
      actorName: adminName,
      action: 'gym_flagged',
      targetType: 'gym',
      targetId: gymId,
      reason: reason,
      description: 'Flagged gym for review',
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // BOOKING OVERSIGHT
  // ═══════════════════════════════════════════════════════════════════

  /// Get all bookings with search and filters.
  Future<List<Map<String, dynamic>>> getAllBookings({
    String? searchQuery,
    String? statusFilter,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true);

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    List<Map<String, dynamic>> bookings = snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
      data['id'] = doc.id;
      return data;
    }).toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      bookings = bookings.where((b) {
        return (b['gymName'] ?? '').toString().toLowerCase().contains(lowerQuery) ||
            (b['userName'] ?? '').toString().toLowerCase().contains(lowerQuery) ||
            (b['id'] ?? '').toString().toLowerCase().contains(lowerQuery) ||
            (b['userId'] ?? '').toString().toLowerCase().contains(lowerQuery);
      }).toList();
    }

    return bookings;
  }

  /// Flag a booking as suspicious.
  Future<void> flagBooking({
    required String bookingId,
    required String notes,
    required String adminId,
    required String adminName,
  }) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'flagged': true,
      'flagNotes': notes,
      'flaggedBy': adminId,
      'flaggedAt': FieldValue.serverTimestamp(),
    });

    await _auditLog.logAction(
      actorId: adminId,
      actorName: adminName,
      action: 'booking_flagged',
      targetType: 'booking',
      targetId: bookingId,
      description: 'Flagged booking as suspicious',
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CONTENT MODERATION
  // ═══════════════════════════════════════════════════════════════════

  /// Get reported content with optional filters.
  Future<List<ContentReportModel>> getReportedContent({
    String? contentTypeFilter,
    String? statusFilter,
    int limit = 20,
  }) async {
    Query query = _firestore
        .collection('contentReports')
        .orderBy('createdAt', descending: true);

    if (contentTypeFilter != null && contentTypeFilter.isNotEmpty) {
      query = query.where('contentType', isEqualTo: contentTypeFilter);
    }

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      return ContentReportModel.fromJson(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }

  /// Hide reported content.
  Future<void> hideContent({
    required String reportId,
    required String contentType,
    required String contentId,
    required String notes,
    required String adminId,
    required String adminName,
  }) async {
    final batch = _firestore.batch();

    // Update report
    batch.update(_firestore.collection('contentReports').doc(reportId), {
      'status': 'resolved',
      'contentStatus': 'hidden',
      'moderationNotes': notes,
      'moderatedBy': adminId,
      'moderatorName': adminName,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update source content
    final collectionName = _getCollectionForContentType(contentType);
    if (collectionName != null) {
      batch.update(_firestore.collection(collectionName).doc(contentId), {
        'contentStatus': 'hidden',
      });
    }

    await batch.commit();

    await _auditLog.logAction(
      actorId: adminId,
      actorName: adminName,
      action: 'content_hidden',
      targetType: contentType,
      targetId: contentId,
      description: 'Hidden $contentType content',
    );
  }

  /// Remove reported content.
  Future<void> removeContent({
    required String reportId,
    required String contentType,
    required String contentId,
    required String reason,
    required String adminId,
    required String adminName,
  }) async {
    final batch = _firestore.batch();

    batch.update(_firestore.collection('contentReports').doc(reportId), {
      'status': 'resolved',
      'contentStatus': 'removed',
      'moderationNotes': reason,
      'moderatedBy': adminId,
      'moderatorName': adminName,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final collectionName = _getCollectionForContentType(contentType);
    if (collectionName != null) {
      batch.update(_firestore.collection(collectionName).doc(contentId), {
        'contentStatus': 'removed',
      });
    }

    await batch.commit();

    await _auditLog.logAction(
      actorId: adminId,
      actorName: adminName,
      action: 'content_removed',
      targetType: contentType,
      targetId: contentId,
      reason: reason,
      description: 'Removed $contentType content',
    );
  }

  /// Restore previously hidden/removed content.
  Future<void> restoreContent({
    required String reportId,
    required String contentType,
    required String contentId,
    required String adminId,
    required String adminName,
  }) async {
    final batch = _firestore.batch();

    batch.update(_firestore.collection('contentReports').doc(reportId), {
      'contentStatus': 'active',
      'status': 'dismissed',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final collectionName = _getCollectionForContentType(contentType);
    if (collectionName != null) {
      batch.update(_firestore.collection(collectionName).doc(contentId), {
        'contentStatus': 'active',
      });
    }

    await batch.commit();

    await _auditLog.logAction(
      actorId: adminId,
      actorName: adminName,
      action: 'content_restored',
      targetType: contentType,
      targetId: contentId,
      description: 'Restored $contentType content',
    );
  }

  /// Dismiss a report.
  Future<void> dismissReport({
    required String reportId,
    required String adminId,
    required String adminName,
  }) async {
    await _firestore.collection('contentReports').doc(reportId).update({
      'status': 'dismissed',
      'moderatedBy': adminId,
      'moderatorName': adminName,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _auditLog.logAction(
      actorId: adminId,
      actorName: adminName,
      action: 'report_dismissed',
      targetType: 'content_report',
      targetId: reportId,
      description: 'Dismissed content report',
    );
  }

  String? _getCollectionForContentType(String contentType) {
    switch (contentType) {
      case 'review':
        return 'reviews';
      case 'event':
        return 'events';
      case 'promotion':
        return 'promotions';
      case 'announcement':
        return 'announcements';
      case 'job_posting':
        return 'jobPostings';
      default:
        return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // LEADERBOARD OVERSIGHT
  // ═══════════════════════════════════════════════════════════════════

  /// Get all personal records across all gyms.
  Future<List<Map<String, dynamic>>> getAllPersonalRecords({
    String? searchQuery,
    String? statusFilter,
    String? categoryFilter,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collectionGroup('personalRecords');

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.where('status', isEqualTo: statusFilter);
      }

      if (categoryFilter != null && categoryFilter.isNotEmpty) {
        query = query.where('category', isEqualTo: categoryFilter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      List<Map<String, dynamic>> records = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        // Extract gymId from the document path
        data['gymId'] = doc.reference.parent.parent?.id ?? '';
        return data;
      }).toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        records = records.where((r) {
          return (r['userName'] ?? '').toString().toLowerCase().contains(lowerQuery) ||
              (r['gymId'] ?? '').toString().toLowerCase().contains(lowerQuery);
        }).toList();
      }

      return records;
    } catch (_) {
      return [];
    }
  }

  /// Dispute a leaderboard record.
  Future<void> disputeRecord({
    required String gymId,
    required String recordId,
    required String reason,
    required String adminId,
    required String adminName,
  }) async {
    await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('personalRecords')
        .doc(recordId)
        .update({
      'status': 'disputed',
      'disputeReason': reason,
      'disputedBy': adminId,
      'disputedAt': FieldValue.serverTimestamp(),
    });

    await _auditLog.logAction(
      actorId: adminId,
      actorName: adminName,
      action: 'record_disputed',
      targetType: 'leaderboard',
      targetId: recordId,
      reason: reason,
      description: 'Disputed leaderboard record',
    );
  }

  /// Remove a fraudulent leaderboard record.
  Future<void> removeRecord({
    required String gymId,
    required String recordId,
    required String reason,
    required String adminId,
    required String adminName,
  }) async {
    await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('personalRecords')
        .doc(recordId)
        .update({
      'status': 'removed',
      'removalReason': reason,
      'removedBy': adminId,
      'removedAt': FieldValue.serverTimestamp(),
    });

    await _auditLog.logAction(
      actorId: adminId,
      actorName: adminName,
      action: 'record_removed',
      targetType: 'leaderboard',
      targetId: recordId,
      reason: reason,
      description: 'Removed fraudulent leaderboard record',
    );
  }

  /// Restore a mistakenly removed record.
  Future<void> restoreRecord({
    required String gymId,
    required String recordId,
    required String adminId,
    required String adminName,
  }) async {
    await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('personalRecords')
        .doc(recordId)
        .update({
      'status': 'verified',
    });

    await _auditLog.logAction(
      actorId: adminId,
      actorName: adminName,
      action: 'record_restored',
      targetType: 'leaderboard',
      targetId: recordId,
      description: 'Restored leaderboard record',
    );
  }

  /// Add an admin note to a record (not publicly readable).
  Future<void> addAdminNote({
    required String gymId,
    required String recordId,
    required String note,
    required String adminId,
    required String adminName,
  }) async {
    await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('personalRecords')
        .doc(recordId)
        .update({
      'adminNotes': FieldValue.arrayUnion([
        {
          'note': note,
          'addedBy': adminId,
          'addedByName': adminName,
          'addedAt': Timestamp.now(),
        }
      ]),
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════

  /// Send or schedule a notification/announcement.
  Future<void> sendNotification({
    required String title,
    required String message,
    required String targetAudience,
    String? linkedScreen,
    String? imageUrl,
    DateTime? scheduledDate,
    required String senderId,
    required String senderName,
  }) async {
    final isScheduled = scheduledDate != null && scheduledDate.isAfter(DateTime.now());

    final notif = AdminNotificationModel(
      id: '',
      title: title,
      message: message,
      targetAudience: targetAudience,
      linkedScreen: linkedScreen,
      imageUrl: imageUrl,
      scheduledDate: isScheduled ? scheduledDate : null,
      sentDate: isScheduled ? null : DateTime.now(),
      status: isScheduled ? 'scheduled' : 'sent',
      senderId: senderId,
      senderName: senderName,
    );

    await _firestore.collection('adminNotifications').add(notif.toJson());

    await _auditLog.logAction(
      actorId: senderId,
      actorName: senderName,
      action: isScheduled ? 'notification_scheduled' : 'notification_sent',
      targetType: 'notification',
      targetId: targetAudience,
      description: isScheduled
          ? 'Scheduled announcement: $title'
          : 'Sent announcement: $title',
    );
  }

  /// Get notification history.
  Future<List<AdminNotificationModel>> getNotificationHistory({
    int limit = 20,
  }) async {
    final snapshot = await _firestore
        .collection('adminNotifications')
        .orderBy('sentDate', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      return AdminNotificationModel.fromJson(doc.data(), doc.id);
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════════════

  /// Get application settings.
  Future<AppSettingsModel> getAppSettings() async {
    final doc = await _firestore.collection('appSettings').doc('config').get();
    if (doc.exists && doc.data() != null) {
      return AppSettingsModel.fromJson(doc.data()!);
    }
    return const AppSettingsModel();
  }

  /// Update application settings.
  Future<void> updateAppSettings({
    required AppSettingsModel settings,
    required String adminId,
    required String adminName,
  }) async {
    await _firestore
        .collection('appSettings')
        .doc('config')
        .set(settings.toJson());

    await _auditLog.logAction(
      actorId: adminId,
      actorName: adminName,
      action: 'settings_changed',
      targetType: 'settings',
      targetId: 'config',
      description: 'Updated application settings',
    );
  }
}
