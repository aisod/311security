import 'package:intl/intl.dart';
import 'package:security_311_admin/services/supabase_service.dart';
import 'package:security_311_admin/models/user_profile.dart';
import 'package:security_311_admin/models/crime_report.dart';
import 'package:security_311_admin/models/region.dart';
import 'package:security_311_admin/models/emergency_alert.dart';
import 'package:security_311_admin/core/logger.dart';

/// Service for admin operations and statistics
class AdminService {
  final SupabaseService _supabase = SupabaseService();

  /// Check if current user has admin privileges
  Future<bool> isUserAdmin() async {
    try {
      final user = _supabase.currentUser;
      if (user == null) {
        AppLogger.warning('isUserAdmin: No current user');
        return false;
      }

      AppLogger.info('isUserAdmin: Checking role for user ${user.id}');
      
      final response = await _supabase.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      final roleString = response['role'] as String? ?? 'user';
      AppLogger.info('isUserAdmin: Found role in database: "$roleString"');
      
      final role = UserRole.fromString(roleString);
      final isAdmin = role == UserRole.admin || role == UserRole.superAdmin;
      
      AppLogger.info('isUserAdmin: Parsed role: ${role.value}, isAdmin: $isAdmin');
      return isAdmin;
    } catch (e, stackTrace) {
      AppLogger.error('Error checking admin status', e, stackTrace);
      return false;
    }
  }

  /// Check if current user is super admin
  Future<bool> isUserSuperAdmin() async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return false;

      final response = await _supabase.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      final role = UserRole.fromString(response['role'] ?? 'user');
      return role == UserRole.superAdmin;
    } catch (e) {
      AppLogger.error('Error checking super admin status', e);
      return false;
    }
  }

  /// Get emergency alerts
  Future<List<EmergencyAlert>> getEmergencyAlerts({
    bool? activeOnly,
    int limit = 50,
  }) async {
    try {
      var query = _supabase.client
          .from('emergency_alerts')
          .select('*, user:profiles!emergency_alerts_user_id_fkey(id, full_name, phone_number)');
      
      if (activeOnly == true) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('created_at', ascending: false).limit(limit);

      return response.map<EmergencyAlert>((json) => EmergencyAlert.fromJson(json)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error getting emergency alerts', e, stackTrace);
      return [];
    }
  }

  /// Update emergency alert status
  Future<bool> updateEmergencyAlertStatus(
    String alertId, {
    required String status,
    bool isActive = false,
  }) async {
    try {
      final updates = {
        'status': status,
        'is_active': isActive,
        'resolved_at': status == 'resolved' || status == 'false_alarm' 
            ? DateTime.now().toIso8601String() 
            : null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.client
          .from('emergency_alerts')
          .update(updates)
          .eq('id', alertId);

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error updating emergency alert status', e, stackTrace);
      return false;
    }
  }

  /// Get comprehensive system statistics
  Future<Map<String, dynamic>> getSystemStatistics() async {
    final stats = <String, dynamic>{};

    try {
      // User statistics
      final userStats = await _getUserStatistics();
      stats.addAll(userStats);

      // Safety alerts statistics
      final alertStats = await _getAlertStatistics();
      stats.addAll(alertStats);

      // Crime reports statistics
      final reportStats = await _getReportStatistics();
      stats.addAll(reportStats);

      // Emergency alerts statistics
      final emergencyStats = await _getEmergencyStatistics();
      stats.addAll(emergencyStats);

      // System health
      stats['system_health'] = await _getSystemHealth();
    } catch (e) {
      AppLogger.error('Error getting system statistics: $e');
    }

    return stats;
  }

  Future<Map<String, dynamic>> _getUserStatistics() async {
    final stats = <String, dynamic>{};

    try {
      final response = await _supabase.client
          .from('profiles')
          .select('role, is_verified, created_at');

      stats['total_users'] = response.length;
      stats['verified_users'] =
          response.where((user) => user['is_verified'] == true).length;
      stats['admin_users'] =
          response.where((user) => user['role'] == 'admin').length;
      stats['super_admin_users'] =
          response.where((user) => user['role'] == 'super_admin').length;

      // Calculate new users this week
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      stats['new_users_week'] = response.where((user) {
        final createdAt = DateTime.parse(user['created_at']);
        return createdAt.isAfter(weekAgo);
      }).length;
    } catch (e) {
      AppLogger.error('Error getting user statistics', e);
    }

    return stats;
  }

  Future<Map<String, dynamic>> _getAlertStatistics() async {
    final stats = <String, dynamic>{};

    try {
      final response = await _supabase.client
          .from('safety_alerts')
          .select('type, severity, is_active, created_at');

      stats['total_alerts'] = response.length;
      stats['active_alerts'] =
          response.where((alert) => alert['is_active'] == true).length;

      // Alert types distribution
      final typeCounts = <String, int>{};
      for (final alert in response) {
        final type = alert['type'] as String;
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }
      stats['alert_types'] = typeCounts;

      // Severity distribution
      final severityCounts = <String, int>{};
      for (final alert in response) {
        final severity = alert['severity'] as String;
        severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
      }
      stats['alert_severities'] = severityCounts;

      // Recent alerts (last 24 hours)
      final now = DateTime.now();
      final dayAgo = now.subtract(const Duration(hours: 24));
      stats['alerts_last_24h'] = response.where((alert) {
        final createdAt = DateTime.parse(alert['created_at']);
        return createdAt.isAfter(dayAgo);
      }).length;
    } catch (e) {
      AppLogger.error('Error getting alert statistics: $e');
    }

    return stats;
  }

  Future<Map<String, dynamic>> _getReportStatistics() async {
    final stats = <String, dynamic>{};

    try {
      final response = await _supabase.client
          .from('crime_reports')
          .select('status, crime_type, created_at');

      stats['total_reports'] = response.length;

      // Status distribution
      final statusCounts = <String, int>{};
      for (final report in response) {
        final status = report['status'] as String;
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }
      stats['report_statuses'] = statusCounts;

      // Crime type distribution
      final typeCounts = <String, int>{};
      for (final report in response) {
        final type = report['crime_type'] as String;
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }
      stats['crime_types'] = typeCounts;

      // Recent reports (last 24 hours)
      final now = DateTime.now();
      final dayAgo = now.subtract(const Duration(hours: 24));
      stats['reports_last_24h'] = response.where((report) {
        final createdAt = DateTime.parse(report['created_at']);
        return createdAt.isAfter(dayAgo);
      }).length;

      final missingResponse = await _supabase.client
          .from('missing_reports')
          .select('status, report_type, created_at');
      stats['missing_reports_total'] = missingResponse.length;
      stats['missing_reports_pending'] = missingResponse
          .where((report) => report['status'] == 'pending')
          .length;
      stats['missing_reports_approved'] = missingResponse
          .where((report) => report['status'] == 'approved')
          .length;
    } catch (e) {
      AppLogger.error('Error getting report statistics: $e');
    }

    return stats;
  }

  Future<Map<String, dynamic>> _getEmergencyStatistics() async {
    final stats = <String, dynamic>{};

    try {
      final response = await _supabase.client
          .from('emergency_alerts')
          .select('type, status, is_active, created_at');

      stats['total_emergencies'] = response.length;
      stats['active_emergencies'] =
          response.where((alert) => alert['is_active'] == true).length;

      // Status distribution
      final statusCounts = <String, int>{};
      for (final alert in response) {
        final status = alert['status'] as String;
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }
      stats['emergency_statuses'] = statusCounts;

      // Type distribution
      final typeCounts = <String, int>{};
      for (final alert in response) {
        final type = alert['type'] as String;
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }
      stats['emergency_types'] = typeCounts;

      // Recent emergencies (last 24 hours)
      final now = DateTime.now();
      final dayAgo = now.subtract(const Duration(hours: 24));
      stats['emergencies_last_24h'] = response.where((alert) {
        final createdAt = DateTime.parse(alert['created_at']);
        return createdAt.isAfter(dayAgo);
      }).length;
    } catch (e) {
      AppLogger.error('Error getting emergency statistics: $e');
    }

    return stats;
  }

  Future<Map<String, dynamic>> _getSystemHealth() async {
    return {
      'database_status': 'operational',
      'api_status': 'operational',
      'notification_service': 'operational',
      'location_service': 'operational',
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  /// Get recent activity for admin overview
  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 20}) async {
    final activities = <Map<String, dynamic>>[];

    try {
      // Recent safety alerts
      final alerts = await _supabase.client
          .from('safety_alerts')
          .select('title, type, created_at')
          .order('created_at', ascending: false)
          .limit(limit ~/ 4);

      for (final alert in alerts) {
        activities.add({
          'type': 'alert',
          'title': 'Safety Alert: ${alert['title']}',
          'description': alert['type'],
          'timestamp': alert['created_at'],
          'icon': 'warning',
        });
      }

      // Recent crime reports
      final reports = await _supabase.client
          .from('crime_reports')
          .select('title, crime_type, created_at')
          .order('created_at', ascending: false)
          .limit(limit ~/ 4);

      for (final report in reports) {
        activities.add({
          'type': 'report',
          'title': 'Crime Report: ${report['title']}',
          'description': report['crime_type'],
          'timestamp': report['created_at'],
          'icon': 'gavel',
        });
      }

      // Recent emergency alerts
      final emergencies = await _supabase.client
          .from('emergency_alerts')
          .select('type, created_at')
          .order('created_at', ascending: false)
          .limit(limit ~/ 4);

      for (final emergency in emergencies) {
        activities.add({
          'type': 'emergency',
          'title': 'Emergency Alert',
          'description': emergency['type'],
          'timestamp': emergency['created_at'],
          'icon': 'emergency',
        });
      }

      // Recent user registrations
      final users = await _supabase.client
          .from('profiles')
          .select('full_name, created_at')
          .order('created_at', ascending: false)
          .limit(limit ~/ 4);

      for (final user in users) {
        activities.add({
          'type': 'user',
          'title': 'New User: ${user['full_name']}',
          'description': 'User registration',
          'timestamp': user['created_at'],
          'icon': 'person',
        });
      }

      // Sort all activities by timestamp
      activities.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp']);
        final bTime = DateTime.parse(b['timestamp']);
        return bTime.compareTo(aTime);
      });

      // Return only the requested limit
      return activities.take(limit).toList();
    } catch (e) {
      AppLogger.error('Error getting recent activity: $e');
      return [];
    }
  }

  /// Fetch crime reports for admin review
  Future<List<CrimeReport>> getCrimeReports({
    String? status,
    String? severity,
    String? region,
  }) async {
    try {
      var query = _supabase.client.from('crime_reports').select(
          '*, reporter:profiles!crime_reports_user_id_fkey(full_name, phone_number, email), assigned:profiles!crime_reports_assigned_officer_fkey(full_name)');

      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }
      if (severity != null && severity.isNotEmpty) {
        query = query.eq('severity', severity);
      }
      if (region != null && region.isNotEmpty) {
        query = query.eq('region', region);
      }

      final response = await query.order('created_at', ascending: false);

      return response.map<CrimeReport>((json) {
        return CrimeReport.fromJson(json);
      }).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching crime reports', e, stackTrace);
      return [];
    }
  }

  /// Update crime report status/notes
  Future<bool> updateCrimeReportStatus(
    String reportId, {
    required String status,
    String? resolutionNotes,
  }) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return false;

      final updates = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
        'assigned_officer': user.id,
      };

      if (resolutionNotes != null && resolutionNotes.isNotEmpty) {
        updates['resolution_notes'] = resolutionNotes;
      }

      await _supabase.client
          .from('crime_reports')
          .update(updates)
          .eq('id', reportId);

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error updating crime report status', e, stackTrace);
      return false;
    }
  }

  /// Regions
  Future<List<Region>> getRegions() async {
    try {
      final response = await _supabase.client
          .from('regions')
          .select()
          .order('name', ascending: true);

      return response
          .map<Region>((json) => Region.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching regions', e, stackTrace);
      return [];
    }
  }

  Future<bool> createRegion({
    required String name,
    String? description,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return false;

      final data = {
        'name': name,
        'description': description,
        'center_latitude': latitude,
        'center_longitude': longitude,
        'metadata': metadata,
        'created_by': user.id,
      }..removeWhere((key, value) => value == null);

      await _supabase.client.from('regions').insert(data);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error creating region', e, stackTrace);
      return false;
    }
  }

  Future<bool> updateRegion(
    String regionId, {
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updates = <String, dynamic>{
        'name': name,
        'description': description,
        'center_latitude': latitude,
        'center_longitude': longitude,
        'metadata': metadata,
        'updated_at': DateTime.now().toIso8601String(),
      }..removeWhere((key, value) => value == null);

      await _supabase.client
          .from('regions')
          .update(updates)
          .eq('id', regionId);

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error updating region', e, stackTrace);
      return false;
    }
  }

  Future<bool> deleteRegion(String regionId) async {
    try {
      await _supabase.client.from('regions').delete().eq('id', regionId);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting region', e, stackTrace);
      return false;
    }
  }

  /// Safety alerts
  Future<List<Map<String, dynamic>>> getSafetyAlerts() async {
    try {
      final response = await _supabase.client
          .from('safety_alerts')
          .select('*, region:regions(*)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      AppLogger.error('Error loading safety alerts', e, stackTrace);
      return [];
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
    try {
      final user = _supabase.currentUser;
      if (user == null) return false;

      final data = {
        'title': title,
        'message': message,
        'type': type,
        'severity': severity,
        'priority': priority,
        'region_id': regionId,
        'latitude': latitude,
        'longitude': longitude,
        'location_description': locationDescription,
        'expires_at': expiresAt?.toIso8601String(),
        'metadata': metadata,
        'created_by': user.id,
      }..removeWhere((key, value) => value == null);

      await _supabase.client.from('safety_alerts').insert(data);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error creating safety alert', e, stackTrace);
      return false;
    }
  }

  Future<bool> updateSafetyAlertStatus(String alertId, bool isActive) async {
    try {
      await _supabase.client
          .from('safety_alerts')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', alertId);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error updating safety alert', e, stackTrace);
      return false;
    }
  }

  Future<bool> deleteSafetyAlert(String alertId) async {
    try {
      await _supabase.client.from('safety_alerts').delete().eq('id', alertId);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting safety alert', e, stackTrace);
      return false;
    }
  }

  /// Dashboard chart helpers
  Future<List<Map<String, dynamic>>> getReportTrend({int days = 7}) async {
    try {
      final since =
          DateTime.now().subtract(Duration(days: days - 1)).toUtc();
      final response = await _supabase.client
          .from('crime_reports')
          .select('created_at')
          .gte('created_at', since.toIso8601String());

      final counts = <String, int>{};
      for (final entry in response) {
        final created = DateTime.parse(entry['created_at'] as String);
        final dateKey = DateFormat('yyyy-MM-dd').format(created);
        counts[dateKey] = (counts[dateKey] ?? 0) + 1;
      }

      final results = <Map<String, dynamic>>[];
      for (var i = 0; i < days; i++) {
        final date = since.add(Duration(days: i));
        final key = DateFormat('yyyy-MM-dd').format(date);
        results.add({
          'label': DateFormat('MMM d').format(date),
          'value': counts[key] ?? 0,
        });
      }

      return results;
    } catch (e, stackTrace) {
      AppLogger.error('Error building report trend', e, stackTrace);
      return [];
    }
  }

  Future<Map<String, int>> getAlertSeverityBreakdown() async {
    try {
      final response =
          await _supabase.client.from('safety_alerts').select('severity');
      final result = <String, int>{};
      for (final alert in response) {
        final severity = alert['severity'] as String? ?? 'info';
        result[severity] = (result[severity] ?? 0) + 1;
      }
      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Error loading alert severity breakdown', e, stackTrace);
      return {};
    }
  }

  Future<Map<String, int>> getCrimeTypeDistribution() async {
    try {
      final response =
          await _supabase.client.from('crime_reports').select('crime_type');
      final result = <String, int>{};
      for (final report in response) {
        final type = report['crime_type'] as String? ?? 'unknown';
        result[type] = (result[type] ?? 0) + 1;
      }
      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Error loading crime type distribution', e, stackTrace);
      return {};
    }
  }

  /// Update user role (admin only)
  Future<bool> updateUserRole(String userId, UserRole newRole) async {
    try {
      if (!await isUserSuperAdmin()) {
        throw Exception('Insufficient permissions');
      }

      await _supabase.client
          .from('profiles')
          .update({'role': newRole.value}).eq('id', userId);

      return true;
    } catch (e) {
      AppLogger.error('Error updating user role: $e');
      return false;
    }
  }

  /// Get all users for admin management
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      if (!await isUserAdmin()) {
        throw Exception('Insufficient permissions');
      }

      final response = await _supabase.client
          .from('profiles')
          .select(
              'id, email, full_name, phone_number, region, role, is_verified, created_at, metadata, id_number, id_type, avatar_url, profile_image_url')
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      AppLogger.error('Error getting all users: $e');
      return [];
    }
  }

  /// Get user's emergency contacts
  Future<List<Map<String, dynamic>>> getUserEmergencyContacts(String userId) async {
    try {
      if (!await isUserAdmin()) {
        throw Exception('Insufficient permissions');
      }

      final response = await _supabase.client
          .from('emergency_contacts')
          .select()
          .eq('user_id', userId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.error('Error getting emergency contacts for user $userId: $e');
      return [];
    }
  }

  /// Delete user (super admin only)
  Future<bool> deleteUser(String userId) async {
    try {
      if (!await isUserSuperAdmin()) {
        throw Exception('Insufficient permissions');
      }

      await _supabase.client.from('profiles').delete().eq('id', userId);

      return true;
    } catch (e) {
      AppLogger.error('Error deleting user: $e');
      return false;
    }
  }

  /// Broadcast message to all users
  Future<bool> broadcastMessage(String title, String message,
      {String? type}) async {
    try {
      if (!await isUserAdmin()) {
        throw Exception('Insufficient permissions');
      }

      // Get all user IDs
      final users = await _supabase.client.from('profiles').select('id');

      // Create notifications for all users
      final notifications = users
          .map((user) => {
                'user_id': user['id'],
                'type': type ?? 'broadcast',
                'title': title,
                'message': message,
                'created_at': DateTime.now().toIso8601String(),
              })
          .toList();

      await _supabase.client.from('user_notifications').insert(notifications);

      return true;
    } catch (e) {
      AppLogger.error('Error broadcasting message: $e');
      return false;
    }
  }
}
