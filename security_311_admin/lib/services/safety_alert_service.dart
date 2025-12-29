import 'dart:math';
import 'package:security_311_admin/services/supabase_service.dart';
import 'package:security_311_admin/models/alert.dart';
import 'package:security_311_admin/core/logger.dart';

/// Service for managing safety alerts
class SafetyAlertService {
  final SupabaseService _supabase = SupabaseService();

  /// Get active safety alerts (public access)
  Future<List<SafetyAlert>> getActiveAlerts({
    String? region,
    String? city,
    int limit = 50,
  }) async {
    try {
      var query =
          _supabase.client.from('safety_alerts').select().eq('is_active', true);

      if (region != null) {
        query = query.eq('region', region);
      }

      if (city != null) {
        query = query.eq('city', city);
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);

      return response.map((json) => SafetyAlert.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Error getting active alerts: $e');
      return [];
    }
  }

  /// Get alerts by type
  Future<List<SafetyAlert>> getAlertsByType(String type,
      {int limit = 20}) async {
    try {
      final response = await _supabase.client
          .from('safety_alerts')
          .select()
          .eq('type', type)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((json) => SafetyAlert.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Error getting alerts by type: $e');
      return [];
    }
  }

  /// Get a specific alert by ID
  Future<SafetyAlert?> getAlert(String alertId) async {
    try {
      final response = await _supabase.client
          .from('safety_alerts')
          .select()
          .eq('id', alertId)
          .single();

      return SafetyAlert.fromJson(response);
    } catch (e) {
      AppLogger.error('Error getting alert: $e');
      return null;
    }
  }

  /// Create a new safety alert (admin only)
  Future<SafetyAlert?> createAlert({
    required String type,
    required String title,
    required String message,
    String? region,
    String? city,
    double? latitude,
    double? longitude,
    required String severity,
    required String priority,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return null;

      final data = {
        'type': type,
        'title': title,
        'message': message,
        'region': region,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'severity': severity,
        'priority': priority,
        'expires_at': expiresAt?.toIso8601String(),
        'created_by': user.id,
        'metadata': metadata,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase.client
          .from('safety_alerts')
          .insert(data)
          .select()
          .single();

      return SafetyAlert.fromJson(response);
    } catch (e) {
      AppLogger.error('Error creating alert: $e');
      return null;
    }
  }

  /// Update an alert (admin only)
  Future<SafetyAlert?> updateAlert(
    String alertId, {
    bool? isActive,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (isActive != null) updates['is_active'] = isActive;
      if (expiresAt != null) {
        updates['expires_at'] = expiresAt.toIso8601String();
      }
      if (metadata != null) updates['metadata'] = metadata;

      final response = await _supabase.client
          .from('safety_alerts')
          .update(updates)
          .eq('id', alertId)
          .select()
          .single();

      return SafetyAlert.fromJson(response);
    } catch (e) {
      AppLogger.error('Error updating alert: $e');
      return null;
    }
  }

  /// Delete an alert (admin only)
  Future<bool> deleteAlert(String alertId) async {
    try {
      await _supabase.client.from('safety_alerts').delete().eq('id', alertId);

      return true;
    } catch (e) {
      AppLogger.error('Error deleting alert: $e');
      return false;
    }
  }

  /// Get alerts within a certain radius of coordinates
  Future<List<SafetyAlert>> getAlertsNearLocation(
    double latitude,
    double longitude,
    double radiusKm, {
    int limit = 20,
  }) async {
    try {
      // Note: This is a simplified distance calculation
      // In production, you'd want to use PostGIS or similar for accurate geospatial queries
      final response = await _supabase.client
          .from('safety_alerts')
          .select()
          .eq('is_active', true)
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
          .order('created_at', ascending: false)
          .limit(limit);

      // Filter by distance (rough approximation)
      final alerts =
          response.map((json) => SafetyAlert.fromJson(json)).toList();
      final filteredAlerts = <SafetyAlert>[];

      for (final alert in alerts) {
        if (alert.latitude != null && alert.longitude != null) {
          final distance = _calculateDistance(
            latitude,
            longitude,
            alert.latitude!,
            alert.longitude!,
          );

          if (distance <= radiusKm) {
            filteredAlerts.add(alert);
          }
        }
      }

      return filteredAlerts;
    } catch (e) {
      AppLogger.error('Error getting alerts near location: $e');
      return [];
    }
  }

  /// Listen to changes in active alerts
  Stream<List<SafetyAlert>> watchActiveAlerts({String? region}) {
    var query =
        _supabase.client.from('safety_alerts').stream(primaryKey: ['id']);

    return query.map((data) {
      // Filter active alerts and optionally by region
      var filteredData =
          data.where((json) => json['is_active'] == true).toList();

      if (region != null) {
        filteredData =
            filteredData.where((json) => json['region'] == region).toList();
      }

      // Sort by created_at descending
      filteredData.sort((a, b) {
        final aTime = DateTime.parse(a['created_at'] as String);
        final bTime = DateTime.parse(b['created_at'] as String);
        return bTime.compareTo(aTime);
      });

      return filteredData.map((json) => SafetyAlert.fromJson(json)).toList();
    });
  }

  /// Get alert statistics
  Future<Map<String, int>> getAlertStats() async {
    try {
      final response =
          await _supabase.client.from('safety_alerts').select('type, severity');

      final stats = <String, int>{};
      for (final alert in response) {
        final type = alert['type'] as String;
        final severity = alert['severity'] as String;

        stats['type_$type'] = (stats['type_$type'] ?? 0) + 1;
        stats['severity_$severity'] = (stats['severity_$severity'] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      AppLogger.error('Error getting alert stats: $e');
      return {};
    }
  }

  /// Simple distance calculation (Haversine formula approximation)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = (lat2 - lat1) * (3.141592653589793 / 180);
    final double dLon = (lon2 - lon1) * (3.141592653589793 / 180);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
}
