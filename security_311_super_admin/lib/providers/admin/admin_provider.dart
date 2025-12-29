import 'package:flutter/foundation.dart';
import 'package:security_311_super_admin/services/admin_service.dart';
import 'package:security_311_super_admin/models/user_profile.dart';
import 'package:security_311_super_admin/models/crime_report.dart';
import 'package:security_311_super_admin/models/missing_report.dart';
import 'package:security_311_super_admin/models/region.dart';
import 'package:security_311_super_admin/models/dashboard_trend_point.dart';
import 'package:security_311_super_admin/core/logger.dart';
import 'package:security_311_super_admin/services/missing_report_service.dart';

/// Provider for managing admin functionality and state
class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();
  final MissingReportService _missingReportService = MissingReportService();

  // User permissions
  bool _isAdmin = false;
  bool _isSuperAdmin = false;
  bool _isCheckingPermissions = false;

  // System statistics
  Map<String, dynamic> _systemStats = {};
  bool _isLoadingStats = false;
  String? _statsError;

  // Recent activity
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoadingActivity = false;
  String? _activityError;

  // User management
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoadingUsers = false;
  String? _usersError;

  List<Region> _regions = [];
  bool _isLoadingRegions = false;
  String? _regionsError;

  List<Map<String, dynamic>> _safetyAlerts = [];
  bool _isLoadingAlerts = false;
  String? _alertsError;

  // Crime reports
  List<CrimeReport> _crimeReports = [];
  bool _isLoadingReports = false;
  String? _reportsError;
  String? _lastReportStatus;
  String? _lastReportSeverity;
  String? _lastReportRegion;

  List<MissingReport> _missingReports = [];
  bool _isLoadingMissingReports = false;
  String? _missingReportsError;
  String? _lastMissingStatus;
  String? _lastMissingType;

  // Charts
  List<DashboardTrendPoint> _reportTrend = [];
  Map<String, int> _alertSeverityBreakdown = {};
  Map<String, int> _crimeTypeDistribution = {};
  bool _isLoadingCharts = false;
  String? _chartsError;

  // Broadcasting
  bool _isBroadcasting = false;
  String? _broadcastError;

  // Getters
  bool get isAdmin => _isAdmin;
  bool get isSuperAdmin => _isSuperAdmin;
  bool get isCheckingPermissions => _isCheckingPermissions;

  Map<String, dynamic> get systemStats => _systemStats;
  bool get isLoadingStats => _isLoadingStats;
  String? get statsError => _statsError;

  List<Map<String, dynamic>> get recentActivity => _recentActivity;
  bool get isLoadingActivity => _isLoadingActivity;
  String? get activityError => _activityError;

  List<Map<String, dynamic>> get allUsers => _allUsers;
  bool get isLoadingUsers => _isLoadingUsers;
  String? get usersError => _usersError;

  List<CrimeReport> get crimeReports => _crimeReports;
  bool get isLoadingCrimeReports => _isLoadingReports;
  String? get crimeReportsError => _reportsError;

  List<MissingReport> get missingReports => _missingReports;
  bool get isLoadingMissingReports => _isLoadingMissingReports;
  String? get missingReportsError => _missingReportsError;

  List<DashboardTrendPoint> get reportTrend => _reportTrend;
  Map<String, int> get alertSeverityBreakdown => _alertSeverityBreakdown;
  Map<String, int> get crimeTypeDistribution => _crimeTypeDistribution;
  bool get isLoadingCharts => _isLoadingCharts;
  String? get chartsError => _chartsError;

  List<Region> get regions => _regions;
  bool get isLoadingRegions => _isLoadingRegions;
  String? get regionsError => _regionsError;

  List<Map<String, dynamic>> get safetyAlerts => _safetyAlerts;
  bool get isLoadingAlerts => _isLoadingAlerts;
  String? get alertsError => _alertsError;

  bool get isBroadcasting => _isBroadcasting;
  String? get broadcastError => _broadcastError;

  /// Initialize admin provider
  Future<void> initialize() async {
    AppLogger.info('Initializing AdminProvider');
    await checkPermissions();
  }

  /// Check user permissions
  Future<void> checkPermissions() async {
    _setCheckingPermissions(true);

    try {
      _isAdmin = await _adminService.isUserAdmin();
      _isSuperAdmin = await _adminService.isUserSuperAdmin();

      AppLogger.info(
          'Admin permissions: admin=$_isAdmin, superAdmin=$_isSuperAdmin');

      // Load initial data if user has admin permissions
      if (_isAdmin) {
        await Future.wait([
          loadSystemStatistics(),
          loadRecentActivity(),
          loadCrimeReports(),
          loadMissingReports(),
          loadRegions(),
          loadSafetyAlerts(),
          loadDashboardCharts(),
        ]);

        if (_isSuperAdmin) {
          await loadAllUsers();
        }
      }
    } catch (e) {
      AppLogger.error('Error checking admin permissions: $e');
    } finally {
      _setCheckingPermissions(false);
    }
  }

  /// Load system statistics
  Future<void> loadSystemStatistics() async {
    if (!_isAdmin) return;

    _setLoadingStats(true);
    _clearStatsError();

    try {
      _systemStats = await _adminService.getSystemStatistics();
      AppLogger.info(
          'Loaded system statistics: ${_systemStats.keys.length} metrics');
    } catch (e) {
      _setStatsError('Failed to load system statistics: ${e.toString()}');
      AppLogger.error('Error loading system statistics: $e');
    } finally {
      _setLoadingStats(false);
    }
  }

  /// Load recent activity
  Future<void> loadRecentActivity({int limit = 20}) async {
    if (!_isAdmin) return;

    _setLoadingActivity(true);
    _clearActivityError();

    try {
      _recentActivity = await _adminService.getRecentActivity(limit: limit);
      AppLogger.info('Loaded ${_recentActivity.length} recent activities');
    } catch (e) {
      _setActivityError('Failed to load recent activity: ${e.toString()}');
      AppLogger.error('Error loading recent activity: $e');
    } finally {
      _setLoadingActivity(false);
    }
  }

  /// Load all users (super admin only)
  Future<void> loadAllUsers() async {
    if (!_isSuperAdmin) return;

    _setLoadingUsers(true);
    _clearUsersError();

    try {
      _allUsers = await _adminService.getAllUsers();
      AppLogger.info('Loaded ${_allUsers.length} users');
    } catch (e) {
      _setUsersError('Failed to load users: ${e.toString()}');
      AppLogger.error('Error loading users: $e');
    } finally {
      _setLoadingUsers(false);
    }
  }

  /// Load crime reports for review
  Future<void> loadCrimeReports({
    String? status,
    String? severity,
    String? region,
  }) async {
    if (!_isAdmin) return;

    _setLoadingReports(true);
    _clearReportsError();

    _lastReportStatus = status;
    _lastReportSeverity = severity;
    _lastReportRegion = region;

    try {
      _crimeReports = await _adminService.getCrimeReports(
        status: status,
        severity: severity,
        region: region,
      );
      AppLogger.info('Loaded ${_crimeReports.length} crime reports');
    } catch (e) {
      _setReportsError('Failed to load reports: ${e.toString()}');
    } finally {
      _setLoadingReports(false);
    }
  }

  /// Update report status/resolution
  Future<bool> updateCrimeReportStatus(
    String reportId,
    String status, {
    String? resolutionNotes,
  }) async {
    if (!_isAdmin) return false;

    try {
      final success = await _adminService.updateCrimeReportStatus(
        reportId,
        status: status,
        resolutionNotes: resolutionNotes,
      );

      if (success) {
        await loadCrimeReports(
          status: _lastReportStatus,
          severity: _lastReportSeverity,
          region: _lastReportRegion,
        );
      }

      return success;
    } catch (e) {
      AppLogger.error('Error updating crime report status: $e');
      return false;
    }
  }

  /// Missing reports approval
  Future<void> loadMissingReports({
    String? status,
    String? reportType,
  }) async {
    if (!_isAdmin) return;

    _setLoadingMissingReports(true);
    _clearMissingReportsError();

    _lastMissingStatus = status;
    _lastMissingType = reportType;

    try {
      _missingReports = await _missingReportService.getAdminMissingReports(
        status: status,
        reportType: reportType,
      );
      AppLogger.info('Loaded ${_missingReports.length} missing reports');
    } catch (e) {
      _setMissingReportsError('Failed to load missing reports: ${e.toString()}');
    } finally {
      _setLoadingMissingReports(false);
    }
  }

  Future<bool> updateMissingReportStatus(
    String reportId,
    MissingReportStatus status, {
    String? adminNotes,
  }) async {
    if (!_isAdmin) return false;

    final success = await _missingReportService.updateMissingReportStatus(
      reportId,
      status,
      adminNotes: adminNotes,
    );
    if (success) {
      await loadMissingReports(
        status: _lastMissingStatus,
        reportType: _lastMissingType,
      );
    }
    return success;
  }

  /// Regions
  Future<void> loadRegions() async {
    if (!_isAdmin) return;

    _setLoadingRegions(true);
    _clearRegionsError();

    try {
      _regions = await _adminService.getRegions();
      AppLogger.info('Loaded ${_regions.length} regions');
    } catch (e) {
      _setRegionsError('Failed to load regions: ${e.toString()}');
    } finally {
      _setLoadingRegions(false);
    }
  }

  Future<bool> createRegion({
    required String name,
    String? description,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? metadata,
  }) async {
    final success = await _adminService.createRegion(
      name: name,
      description: description,
      latitude: latitude,
      longitude: longitude,
      metadata: metadata,
    );
    if (success) {
      await loadRegions();
    }
    return success;
  }

  Future<bool> deleteRegion(String regionId) async {
    final success = await _adminService.deleteRegion(regionId);
    if (success) {
      await loadRegions();
    }
    return success;
  }

  /// Alerts
  Future<void> loadSafetyAlerts() async {
    if (!_isAdmin) return;

    _setLoadingAlerts(true);
    _clearAlertsError();

    try {
      _safetyAlerts = await _adminService.getSafetyAlerts();
    } catch (e) {
      _setAlertsError('Failed to load alerts: ${e.toString()}');
    } finally {
      _setLoadingAlerts(false);
    }
  }

  Future<bool> createSafetyAlert({
    required String title,
    required String message,
    required String type,
    required String severity,
    required String priority,
    String? regionId,
    double? latitude,
    double? longitude,
    String? locationDescription,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) async {
    final success = await _adminService.createSafetyAlert(
      title: title,
      message: message,
      type: type,
      severity: severity,
      priority: priority,
      regionId: regionId,
      latitude: latitude,
      longitude: longitude,
      locationDescription: locationDescription,
      expiresAt: expiresAt,
      metadata: metadata,
    );
    if (success) {
      await loadSafetyAlerts();
    }
    return success;
  }

  Future<bool> updateSafetyAlertStatus(String alertId, bool isActive) async {
    final success =
        await _adminService.updateSafetyAlertStatus(alertId, isActive);
    if (success) {
      await loadSafetyAlerts();
    }
    return success;
  }

  Future<bool> deleteSafetyAlert(String alertId) async {
    final success = await _adminService.deleteSafetyAlert(alertId);
    if (success) {
      await loadSafetyAlerts();
    }
    return success;
  }

  /// Update user role (super admin only)
  Future<bool> updateUserRole(String userId, UserRole newRole) async {
    if (!_isSuperAdmin) {
      AppLogger.error('Insufficient permissions to update user role');
      return false;
    }

    try {
      final success = await _adminService.updateUserRole(userId, newRole);
      if (success) {
        // Refresh users list
        await loadAllUsers();
        AppLogger.info('Updated user role: $userId -> ${newRole.value}');
      }
      return success;
    } catch (e) {
      AppLogger.error('Error updating user role: $e');
      return false;
    }
  }

  /// Delete user (super admin only)
  Future<bool> deleteUser(String userId) async {
    if (!_isSuperAdmin) {
      AppLogger.error('Insufficient permissions to delete user');
      return false;
    }

    try {
      final success = await _adminService.deleteUser(userId);
      if (success) {
        // Refresh users list
        await loadAllUsers();
        AppLogger.info('Deleted user: $userId');
      }
      return success;
    } catch (e) {
      AppLogger.error('Error deleting user: $e');
      return false;
    }
  }

  /// Broadcast message to all users
  Future<bool> broadcastMessage(String title, String message,
      {String? type}) async {
    if (!_isAdmin) {
      AppLogger.error('Insufficient permissions to broadcast message');
      return false;
    }

    _setBroadcasting(true);
    _clearBroadcastError();

    try {
      final success =
          await _adminService.broadcastMessage(title, message, type: type);
      if (success) {
        AppLogger.info('Broadcast message sent: $title');
      }
      return success;
    } catch (e) {
      _setBroadcastError('Failed to broadcast message: ${e.toString()}');
      AppLogger.error('Error broadcasting message: $e');
      return false;
    } finally {
      _setBroadcasting(false);
    }
  }

  /// Refresh all admin data
  Future<void> refreshAll() async {
    if (!_isAdmin) return;

    await Future.wait([
      loadSystemStatistics(),
      loadRecentActivity(),
      loadCrimeReports(
        status: _lastReportStatus,
        severity: _lastReportSeverity,
        region: _lastReportRegion,
      ),
      loadMissingReports(
        status: _lastMissingStatus,
        reportType: _lastMissingType,
      ),
      loadRegions(),
      loadSafetyAlerts(),
      loadDashboardCharts(),
      if (_isSuperAdmin) loadAllUsers(),
    ]);
  }

  // Private helper methods
  void _setCheckingPermissions(bool checking) {
    _isCheckingPermissions = checking;
    notifyListeners();
  }

  void _setLoadingStats(bool loading) {
    _isLoadingStats = loading;
    notifyListeners();
  }

  void _setStatsError(String error) {
    _statsError = error;
    notifyListeners();
  }

  void _clearStatsError() {
    _statsError = null;
    notifyListeners();
  }

  void _setLoadingActivity(bool loading) {
    _isLoadingActivity = loading;
    notifyListeners();
  }

  void _setActivityError(String error) {
    _activityError = error;
    notifyListeners();
  }

  void _clearActivityError() {
    _activityError = null;
    notifyListeners();
  }

  void _setLoadingUsers(bool loading) {
    _isLoadingUsers = loading;
    notifyListeners();
  }

  void _setUsersError(String error) {
    _usersError = error;
    notifyListeners();
  }

  void _clearUsersError() {
    _usersError = null;
    notifyListeners();
  }

  void _setLoadingRegions(bool loading) {
    _isLoadingRegions = loading;
    notifyListeners();
  }

  void _setRegionsError(String error) {
    _regionsError = error;
    notifyListeners();
  }

  void _clearRegionsError() {
    _regionsError = null;
    notifyListeners();
  }

  void _setLoadingAlerts(bool loading) {
    _isLoadingAlerts = loading;
    notifyListeners();
  }

  void _setAlertsError(String error) {
    _alertsError = error;
    notifyListeners();
  }

  void _clearAlertsError() {
    _alertsError = null;
    notifyListeners();
  }

  void _setLoadingMissingReports(bool value) {
    _isLoadingMissingReports = value;
    notifyListeners();
  }

  void _setMissingReportsError(String error) {
    _missingReportsError = error;
    notifyListeners();
  }

  void _clearMissingReportsError() {
    _missingReportsError = null;
    notifyListeners();
  }

  Future<void> loadDashboardCharts() async {
    if (!_isAdmin) return;

    _setLoadingCharts(true);
    _clearChartsError();

    try {
      final trendData = await _adminService.getReportTrend();
      _reportTrend = trendData
          .map((entry) => DashboardTrendPoint(
                label: entry['label'] as String,
                value: entry['value'] as int,
              ))
          .toList();
      _alertSeverityBreakdown =
          await _adminService.getAlertSeverityBreakdown();
      _crimeTypeDistribution =
          await _adminService.getCrimeTypeDistribution();
    } catch (e) {
      _setChartsError('Failed to load charts: ${e.toString()}');
    } finally {
      _setLoadingCharts(false);
    }
  }

  void _setLoadingCharts(bool loading) {
    _isLoadingCharts = loading;
    notifyListeners();
  }

  void _setChartsError(String error) {
    _chartsError = error;
    notifyListeners();
  }

  void _clearChartsError() {
    _chartsError = null;
    notifyListeners();
  }

  void _setLoadingReports(bool loading) {
    _isLoadingReports = loading;
    notifyListeners();
  }

  void _setReportsError(String error) {
    _reportsError = error;
    notifyListeners();
  }

  void _clearReportsError() {
    _reportsError = null;
    notifyListeners();
  }

  void _setBroadcasting(bool broadcasting) {
    _isBroadcasting = broadcasting;
    notifyListeners();
  }

  void _setBroadcastError(String error) {
    _broadcastError = error;
    notifyListeners();
  }

  void _clearBroadcastError() {
    _broadcastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    AppLogger.info('AdminProvider disposed');
    super.dispose();
  }
}

