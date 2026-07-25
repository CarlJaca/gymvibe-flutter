
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/gym_model.dart';
import '../models/audit_log_model.dart';
import '../models/content_report_model.dart';
import '../models/admin_notification_model.dart';
import '../models/app_settings_model.dart';
import '../models/leaderboard_model.dart';
import '../services/super_admin_service.dart';
import '../services/audit_log_service.dart';

class SuperAdminProvider extends ChangeNotifier {
  final SuperAdminService _service = SuperAdminService.instance;
  final AuditLogService _auditLogService = AuditLogService.instance;

  // ─── Navigation state ───────────────────────────────────────────────
  int _currentNavIndex = 0;
  int get currentNavIndex => _currentNavIndex;

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  // ─── Loading / Error states ─────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ═══════════════════════════════════════════════════════════════════

  Map<String, int> _dashboardStats = {};
  List<AuditLogModel> _recentActivity = [];

  Map<String, int> get dashboardStats => _dashboardStats;
  List<AuditLogModel> get recentActivity => _recentActivity;

  Future<void> loadDashboard() async {
    _setLoading(true);
    _setError(null);
    try {
      final results = await Future.wait([
        _service.getDashboardStats(),
        _auditLogService.getRecentActivity(limit: 10),
      ]);
      _dashboardStats = results[0] as Map<String, int>;
      _recentActivity = results[1] as List<AuditLogModel>;
    } catch (e) {
      _setError('Failed to load dashboard: $e');
    }
    _setLoading(false);
  }

  // ═══════════════════════════════════════════════════════════════════
  // USERS
  // ═══════════════════════════════════════════════════════════════════

  List<UserModel> _users = [];
  int _totalUserCount = 0;
  int _seekerCount = 0;
  int _ownerCount = 0;

  List<UserModel> get users => _users;
  int get totalUserCount => _totalUserCount;
  int get seekerCount => _seekerCount;
  int get ownerCount => _ownerCount;

  Future<void> loadUsers({
    String? searchQuery,
    String? roleFilter,
    String? statusFilter,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final results = await Future.wait([
        _service.getAllUsers(
          searchQuery: searchQuery,
          roleFilter: roleFilter,
          statusFilter: statusFilter,
        ),
        _service.getUserCount(),
        _service.getUserCount(roleFilter: 'gym_seeker'),
        _service.getUserCount(roleFilter: 'gym_owner'),
      ]);
      _users = results[0] as List<UserModel>;
      _totalUserCount = results[1] as int;
      _seekerCount = results[2] as int;
      _ownerCount = results[3] as int;
    } catch (e) {
      _setError('Failed to load users: $e');
    }
    _setLoading(false);
  }

  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    return _service.getUserBookings(userId);
  }

  Future<List<PersonalRecord>> getUserPRs(String userId) async {
    return _service.getUserPRs(userId);
  }

  Future<void> suspendUser({
    required String userId,
    required String reason,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _service.suspendUser(
        userId: userId,
        reason: reason,
        adminId: adminId,
        adminName: adminName,
      );
      // Refresh users list
      await loadUsers();
    } catch (e) {
      _setError('Failed to suspend user: $e');
    }
  }

  Future<void> reactivateUser({
    required String userId,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _service.reactivateUser(
        userId: userId,
        adminId: adminId,
        adminName: adminName,
      );
      await loadUsers();
    } catch (e) {
      _setError('Failed to reactivate user: $e');
    }
  }

  Future<void> deactivateUser({
    required String userId,
    required String reason,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _service.deactivateUser(
        userId: userId,
        reason: reason,
        adminId: adminId,
        adminName: adminName,
      );
      await loadUsers();
    } catch (e) {
      _setError('Failed to deactivate user: $e');
    }
  }

  Future<void> changeUserRole({
    required String userId,
    required String newRole,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _service.changeUserRole(
        userId: userId,
        newRole: newRole,
        adminId: adminId,
        adminName: adminName,
      );
      await loadUsers();
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // OWNER APPROVALS
  // ═══════════════════════════════════════════════════════════════════

  List<UserModel> _pendingOwners = [];
  List<UserModel> _approvedOwners = [];
  List<UserModel> _rejectedOwners = [];

  List<UserModel> get pendingOwners => _pendingOwners;
  List<UserModel> get approvedOwners => _approvedOwners;
  List<UserModel> get rejectedOwners => _rejectedOwners;

  Future<void> loadOwnerApprovals() async {
    _setLoading(true);
    _setError(null);
    try {
      final results = await Future.wait([
        _service.getPendingOwnerApplications(),
        _service.getApprovedOwnerApplications(),
        _service.getRejectedOwnerApplications(),
      ]);
      _pendingOwners = results[0];
      _approvedOwners = results[1];
      _rejectedOwners = results[2];
    } catch (e) {
      _setError('Failed to load owner approvals: $e');
    }
    _setLoading(false);
  }

  Future<void> approveOwner({
    required String userId,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _service.approveOwner(
        userId: userId,
        adminId: adminId,
        adminName: adminName,
      );
      await loadOwnerApprovals();
    } catch (e) {
      _setError('Failed to approve owner: $e');
    }
  }

  Future<void> rejectOwner({
    required String userId,
    required String reason,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _service.rejectOwner(
        userId: userId,
        reason: reason,
        adminId: adminId,
        adminName: adminName,
      );
      await loadOwnerApprovals();
    } catch (e) {
      _setError('Failed to reject owner: $e');
    }
  }

  Future<void> requestOwnerInfo({
    required String userId,
    required String message,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _service.requestOwnerInfo(
        userId: userId,
        message: message,
        adminId: adminId,
        adminName: adminName,
      );
      await loadOwnerApprovals();
    } catch (e) {
      _setError('Failed to request info: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // GYMS
  // ═══════════════════════════════════════════════════════════════════

  List<GymModel> _gyms = [];
  List<GymModel> get gyms => _gyms;

  Future<void> loadGyms({String? searchQuery, String? statusFilter}) async {
    _setLoading(true);
    _setError(null);
    try {
      _gyms = await _service.getAllGyms(
        searchQuery: searchQuery,
        statusFilter: statusFilter,
      );
    } catch (e) {
      _setError('Failed to load gyms: $e');
    }
    _setLoading(false);
  }

  final Map<String, UserModel?> _ownerCache = {};

  Future<UserModel?> getGymOwner(String? ownerId) async {
    if (ownerId == null || ownerId.isEmpty) return null;
    if (_ownerCache.containsKey(ownerId)) {
      return _ownerCache[ownerId];
    }
    try {
      final owner = await _service.getGymOwner(ownerId);
      _ownerCache[ownerId] = owner;
      return owner;
    } catch (e) {
      return null;
    }
  }

  Future<void> suspendGym({
    required String gymId,
    required String reason,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _service.suspendGym(
        gymId: gymId,
        reason: reason,
        adminId: adminId,
        adminName: adminName,
      );
      await loadGyms();
    } catch (e) {
      _setError('Failed to suspend gym: $e');
    }
  }

  Future<void> reactivateGym({
    required String gymId,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _service.reactivateGym(
        gymId: gymId,
        adminId: adminId,
        adminName: adminName,
      );
      await loadGyms();
    } catch (e) {
      _setError('Failed to reactivate gym: $e');
    }
  }

  Future<void> flagGym({
    required String gymId,
    required String reason,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _service.flagGym(
        gymId: gymId,
        reason: reason,
        adminId: adminId,
        adminName: adminName,
      );
      await loadGyms();
    } catch (e) {
      _setError('Failed to flag gym: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // BOOKINGS
  // ═══════════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> get bookings => _bookings;

  Future<void> loadBookings({String? searchQuery, String? statusFilter}) async {
    _setLoading(true);
    _setError(null);
    try {
      _bookings = await _service.getAllBookings(
        searchQuery: searchQuery,
        statusFilter: statusFilter,
      );
    } catch (e) {
      _setError('Failed to load bookings: $e');
    }
    _setLoading(false);
  }

  Future<void> flagBooking({
    required String bookingId,
    required String notes,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _service.flagBooking(
        bookingId: bookingId,
        notes: notes,
        adminId: adminId,
        adminName: adminName,
      );
      await loadBookings();
    } catch (e) {
      _setError('Failed to flag booking: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // CONTENT MODERATION
  // ═══════════════════════════════════════════════════════════════════

  List<ContentReportModel> _reports = [];
  List<ContentReportModel> get reports => _reports;

  Future<void> loadReports({String? contentTypeFilter, String? statusFilter}) async {
    _setLoading(true);
    _setError(null);
    try {
      _reports = await _service.getReportedContent(
        contentTypeFilter: contentTypeFilter,
        statusFilter: statusFilter,
      );
    } catch (e) {
      _setError('Failed to load reports: $e');
    }
    _setLoading(false);
  }

  Future<void> hideContent({
    required String reportId,
    required String contentType,
    required String contentId,
    required String notes,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _service.hideContent(
        reportId: reportId,
        contentType: contentType,
        contentId: contentId,
        notes: notes,
        adminId: adminId,
        adminName: adminName,
      );
      await loadReports();
    } catch (e) {
      _setError('Failed to hide content: $e');
    }
  }

  Future<void> removeContent({
    required String reportId,
    required String contentType,
    required String contentId,
    required String reason,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _service.removeContent(
        reportId: reportId,
        contentType: contentType,
        contentId: contentId,
        reason: reason,
        adminId: adminId,
        adminName: adminName,
      );
      await loadReports();
    } catch (e) {
      _setError('Failed to remove content: $e');
    }
  }

  Future<void> restoreContent({
    required String reportId,
    required String contentType,
    required String contentId,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _service.restoreContent(
        reportId: reportId,
        contentType: contentType,
        contentId: contentId,
        adminId: adminId,
        adminName: adminName,
      );
      await loadReports();
    } catch (e) {
      _setError('Failed to restore content: $e');
    }
  }

  Future<void> dismissReport({
    required String reportId,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _service.dismissReport(
        reportId: reportId,
        adminId: adminId,
        adminName: adminName,
      );
      await loadReports();
    } catch (e) {
      _setError('Failed to dismiss report: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // LEADERBOARD
  // ═══════════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _personalRecords = [];
  List<Map<String, dynamic>> get personalRecords => _personalRecords;

  Future<void> loadPersonalRecords({
    String? searchQuery,
    String? statusFilter,
    String? categoryFilter,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      _personalRecords = await _service.getAllPersonalRecords(
        searchQuery: searchQuery,
        statusFilter: statusFilter,
        categoryFilter: categoryFilter,
      );
    } catch (e) {
      _setError('Failed to load personal records: $e');
    }
    _setLoading(false);
  }

  Future<void> disputeRecord({
    required String gymId,
    required String recordId,
    required String reason,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _service.disputeRecord(
        gymId: gymId,
        recordId: recordId,
        reason: reason,
        adminId: adminId,
        adminName: adminName,
      );
      await loadPersonalRecords();
    } catch (e) {
      _setError('Failed to dispute record: $e');
    }
  }

  Future<void> removeRecord({
    required String gymId,
    required String recordId,
    required String reason,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _service.removeRecord(
        gymId: gymId,
        recordId: recordId,
        reason: reason,
        adminId: adminId,
        adminName: adminName,
      );
      await loadPersonalRecords();
    } catch (e) {
      _setError('Failed to remove record: $e');
    }
  }

  Future<void> restoreRecord({
    required String gymId,
    required String recordId,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _service.restoreRecord(
        gymId: gymId,
        recordId: recordId,
        adminId: adminId,
        adminName: adminName,
      );
      await loadPersonalRecords();
    } catch (e) {
      _setError('Failed to restore record: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // AUDIT LOGS
  // ═══════════════════════════════════════════════════════════════════

  List<AuditLogModel> _auditLogs = [];
  List<String> _actionTypes = [];

  List<AuditLogModel> get auditLogs => _auditLogs;
  List<String> get actionTypes => _actionTypes;

  Future<void> loadAuditLogs({
    String? searchQuery,
    String? actionFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final results = await Future.wait([
        _auditLogService.getAuditLogs(
          searchQuery: searchQuery,
          actionFilter: actionFilter,
          startDate: startDate,
          endDate: endDate,
        ),
        _auditLogService.getActionTypes(),
      ]);
      _auditLogs = results[0] as List<AuditLogModel>;
      _actionTypes = results[1] as List<String>;
    } catch (e) {
      _setError('Failed to load audit logs: $e');
    }
    _setLoading(false);
  }

  // ═══════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════

  List<AdminNotificationModel> _notifications = [];
  List<AdminNotificationModel> get notifications => _notifications;

  Future<void> loadNotifications() async {
    _setLoading(true);
    _setError(null);
    try {
      _notifications = await _service.getNotificationHistory();
    } catch (e) {
      _setError('Failed to load notifications: $e');
    }
    _setLoading(false);
  }

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
    try {
      await _service.sendNotification(
        title: title,
        message: message,
        targetAudience: targetAudience,
        linkedScreen: linkedScreen,
        imageUrl: imageUrl,
        scheduledDate: scheduledDate,
        senderId: senderId,
        senderName: senderName,
      );
      await loadNotifications();
    } catch (e) {
      _setError('Failed to send notification: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════════════

  AppSettingsModel _settings = const AppSettingsModel();
  AppSettingsModel get settings => _settings;

  Future<void> loadSettings() async {
    _setLoading(true);
    _setError(null);
    try {
      _settings = await _service.getAppSettings();
    } catch (e) {
      _setError('Failed to load settings: $e');
    }
    _setLoading(false);
  }

  Future<void> updateSettings({
    required AppSettingsModel settings,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _service.updateAppSettings(
        settings: settings,
        adminId: adminId,
        adminName: adminName,
      );
      _settings = settings;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update settings: $e');
    }
  }
}
