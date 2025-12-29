import 'package:security_311_user/services/supabase_service.dart';
import 'package:security_311_user/models/emergency_alert.dart';
import 'package:security_311_user/core/logger.dart';

/// Service for managing emergency alerts
class EmergencyAlertService {
  final SupabaseService _supabase = SupabaseService();

  /// Create a new emergency alert
  Future<EmergencyAlert?> createEmergencyAlert({
    required String type,
    String? description,
    double? latitude,
    double? longitude,
    String? locationDescription,
    List<String>? notifiedContacts,
    List<String>? notifiedServices,
  }) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return null;

      final data = {
        'user_id': user.id,
        'type': type,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'location_description': locationDescription,
        'notified_contacts': notifiedContacts,
        'notified_services': notifiedServices,
        'triggered_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase.client
          .from('emergency_alerts')
          .insert(data)
          .select()
          .single();

      return EmergencyAlert.fromJson(response);
    } catch (e) {
      AppLogger.error('Error creating emergency alert', e);
      return null;
    }
  }

  /// Get emergency alerts for the current user
  Future<List<EmergencyAlert>> getUserEmergencyAlerts({int limit = 50}) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return [];

      final response = await _supabase.client
          .from('emergency_alerts')
          .select()
          .eq('user_id', user.id)
          .order('triggered_at', ascending: false)
          .limit(limit);

      return response.map((json) => EmergencyAlert.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Error getting user emergency alerts', e);
      return [];
    }
  }

  /// Get a specific emergency alert
  Future<EmergencyAlert?> getEmergencyAlert(String alertId) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return null;

      final response = await _supabase.client
          .from('emergency_alerts')
          .select()
          .eq('id', alertId)
          .eq('user_id', user.id)
          .single();

      return EmergencyAlert.fromJson(response);
    } catch (e) {
      AppLogger.error('Error getting emergency alert', e);
      return null;
    }
  }

  /// Update an emergency alert status
  Future<EmergencyAlert?> updateEmergencyAlert(
    String alertId, {
    String? status,
    DateTime? resolvedAt,
    bool? isActive,
  }) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return null;

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status != null) updates['status'] = status;
      if (resolvedAt != null) {
        updates['resolved_at'] = resolvedAt.toIso8601String();
      }
      if (isActive != null) updates['is_active'] = isActive;

      final response = await _supabase.client
          .from('emergency_alerts')
          .update(updates)
          .eq('id', alertId)
          .eq('user_id', user.id)
          .select()
          .single();

      return EmergencyAlert.fromJson(response);
    } catch (e) {
      AppLogger.error('Error updating emergency alert', e);
      return null;
    }
  }

  /// Resolve an emergency alert
  Future<EmergencyAlert?> resolveEmergencyAlert(String alertId) async {
    return updateEmergencyAlert(
      alertId,
      status: 'resolved',
      resolvedAt: DateTime.now(),
      isActive: false,
    );
  }

  /// Mark emergency alert as false alarm
  Future<EmergencyAlert?> markAsFalseAlarm(String alertId) async {
    return updateEmergencyAlert(
      alertId,
      status: 'false_alarm',
      resolvedAt: DateTime.now(),
      isActive: false,
    );
  }

  /// Get active emergency alerts for the current user
  Future<List<EmergencyAlert>> getActiveEmergencyAlerts() async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return [];

      final response = await _supabase.client
          .from('emergency_alerts')
          .select()
          .eq('user_id', user.id)
          .eq('is_active', true)
          .order('triggered_at', ascending: false);

      return response.map((json) => EmergencyAlert.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Error getting active emergency alerts', e);
      return [];
    }
  }

  /// Get emergency alert statistics
  Future<Map<String, dynamic>> getEmergencyAlertStats() async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return {};

      final response = await _supabase.client
          .from('emergency_alerts')
          .select('type, status, is_active')
          .eq('user_id', user.id);

      final stats = <String, dynamic>{
        'total': response.length,
        'active': 0,
        'resolved': 0,
        'false_alarm': 0,
        'types': <String, int>{},
      };

      for (final alert in response) {
        final type = alert['type'] as String;
        final status = alert['status'] as String;
        final isActive = alert['is_active'] as bool? ?? true;

        if (isActive) {
          stats['active'] = (stats['active'] as int) + 1;
        }

        if (status == 'resolved') {
          stats['resolved'] = (stats['resolved'] as int) + 1;
        } else if (status == 'false_alarm') {
          stats['false_alarm'] = (stats['false_alarm'] as int) + 1;
        }

        final types = stats['types'] as Map<String, int>;
        types[type] = (types[type] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      AppLogger.error('Error getting emergency alert stats', e);
      return {};
    }
  }

  /// Listen to changes in user's emergency alerts
  Stream<List<EmergencyAlert>> watchUserEmergencyAlerts() {
    final user = _supabase.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase.client
        .from('emergency_alerts')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('triggered_at', ascending: false)
        .map((data) =>
            data.map((json) => EmergencyAlert.fromJson(json)).toList());
  }

  /// Get recent emergency alerts in a region (for public awareness)
  Future<List<EmergencyAlert>> getRecentEmergencyAlertsInRegion(
    String region, {
    int hoursBack = 24,
    int limit = 20,
  }) async {
    try {
      final cutoffTime = DateTime.now().subtract(Duration(hours: hoursBack));

      final response = await _supabase.client
          .from('emergency_alerts')
          .select()
          .eq('is_active', true)
          .gte('triggered_at', cutoffTime.toIso8601String())
          .order('triggered_at', ascending: false)
          .limit(limit);

      // Note: This query doesn't filter by region since emergency alerts don't have a region field
      // You might want to add region to the emergency_alerts table if needed

      return response.map((json) => EmergencyAlert.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Error getting recent emergency alerts', e);
      return [];
    }
  }
}
