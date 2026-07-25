import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log_model.dart';

class AuditLogService {
  AuditLogService._();
  static final AuditLogService instance = AuditLogService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'auditLogs';

  /// Log an admin action to the auditLogs collection.
  Future<void> logAction({
    required String actorId,
    required String actorName,
    required String action,
    required String targetType,
    required String targetId,
    required String description,
    String reason = '',
  }) async {
    await _firestore.collection(_collection).add({
      'actorId': actorId,
      'actorName': actorName,
      'actorRole': 'super_admin',
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get audit logs with optional filters and pagination.
  Future<List<AuditLogModel>> getAuditLogs({
    String? searchQuery,
    String? actionFilter,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true);

    if (actionFilter != null && actionFilter.isNotEmpty) {
      query = query.where('action', isEqualTo: actionFilter);
    }

    if (startDate != null) {
      query = query.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    final logs = snapshot.docs.map((doc) {
      return AuditLogModel.fromJson(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();

    // Client-side search filter (Firestore doesn't support full-text search)
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      return logs.where((log) {
        return log.actorName.toLowerCase().contains(lowerQuery) ||
            log.description.toLowerCase().contains(lowerQuery) ||
            log.action.toLowerCase().contains(lowerQuery) ||
            log.targetId.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    return logs;
  }

  /// Get recent activity for dashboard (latest N entries).
  Future<List<AuditLogModel>> getRecentActivity({int limit = 10}) async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      return AuditLogModel.fromJson(
        doc.data(),
        doc.id,
      );
    }).toList();
  }

  /// Get all unique action types for filter dropdown.
  Future<List<String>> getActionTypes() async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();

    final actions = snapshot.docs
        .map((doc) => doc.data()['action'] as String? ?? '')
        .where((a) => a.isNotEmpty)
        .toSet()
        .toList();
    actions.sort();
    return actions;
  }
}
