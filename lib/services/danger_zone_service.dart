import 'dart:math' as math;
import 'package:security_311_user/models/danger_zone.dart';
import 'package:security_311_user/services/supabase_service.dart';
import 'package:security_311_user/core/logger.dart';

/// Service for managing danger zones in Supabase
class DangerZoneService {
  final SupabaseService _supabase = SupabaseService();
  
  /// Table name in Supabase
  static const String _tableName = 'danger_zones';
  
  /// Get all active danger zones
  Future<List<DangerZone>> getActiveDangerZones({
    String? region,
    String? city,
  }) async {
    try {
      var query = _supabase.client
          .from(_tableName)
          .select()
          .eq('is_active', true);
      
      if (region != null && region.isNotEmpty) {
        query = query.eq('region', region);
      }
      
      if (city != null && city.isNotEmpty) {
        query = query.eq('city', city);
      }
      
      final response = await query.order('risk_level', ascending: false);
      
      return response.map((json) => DangerZone.fromJson(json)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error getting active danger zones', e, stackTrace);
      return [];
    }
  }
  
  /// Get all danger zones (for admin)
  Future<List<DangerZone>> getAllDangerZones() async {
    try {
      final response = await _supabase.client
          .from(_tableName)
          .select()
          .order('created_at', ascending: false);
      
      return response.map((json) => DangerZone.fromJson(json)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error getting all danger zones', e, stackTrace);
      return [];
    }
  }
  
  /// Get danger zone by ID
  Future<DangerZone?> getDangerZone(String id) async {
    try {
      final response = await _supabase.client
          .from(_tableName)
          .select()
          .eq('id', id)
          .single();
      
      return DangerZone.fromJson(response);
    } catch (e, stackTrace) {
      AppLogger.error('Error getting danger zone $id', e, stackTrace);
      return null;
    }
  }
  
  /// Create a new danger zone (admin only)
  Future<DangerZone?> createDangerZone({
    required String name,
    String? description,
    required String geometryType, // 'circle' or 'polygon'
    double? centerLatitude,
    double? centerLongitude,
    double? radiusMeters,
    List<Map<String, double>>? polygonPoints,
    required List<String> crimeTypes,
    required String riskLevel,
    String? warningMessage,
    String? safetyTips,
    List<String>? activeHours,
    bool isAlwaysActive = true,
    String? region,
    String? city,
  }) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) {
        AppLogger.error('Cannot create danger zone: no authenticated user');
        return null;
      }
      
      final now = DateTime.now().toIso8601String();
      
      final data = {
        'name': name,
        'description': description,
        'geometry_type': geometryType,
        'center_latitude': centerLatitude,
        'center_longitude': centerLongitude,
        'radius_meters': radiusMeters,
        'polygon_points': polygonPoints,
        'crime_types': crimeTypes,
        'risk_level': riskLevel,
        'warning_message': warningMessage,
        'safety_tips': safetyTips,
        'active_hours': activeHours,
        'is_always_active': isAlwaysActive,
        'incident_count': 0,
        'region': region,
        'city': city,
        'is_active': true,
        'created_at': now,
        'updated_at': now,
        'created_by': user.id,
      };
      
      // Remove null values
      data.removeWhere((key, value) => value == null);
      
      final response = await _supabase.client
          .from(_tableName)
          .insert(data)
          .select()
          .single();
      
      AppLogger.info('Created danger zone: ${response['id']}');
      return DangerZone.fromJson(response);
    } catch (e, stackTrace) {
      AppLogger.error('Error creating danger zone', e, stackTrace);
      return null;
    }
  }
  
  /// Update a danger zone (admin only)
  Future<DangerZone?> updateDangerZone(
    String id, {
    String? name,
    String? description,
    String? geometryType,
    double? centerLatitude,
    double? centerLongitude,
    double? radiusMeters,
    List<Map<String, double>>? polygonPoints,
    List<String>? crimeTypes,
    String? riskLevel,
    String? warningMessage,
    String? safetyTips,
    List<String>? activeHours,
    bool? isAlwaysActive,
    int? incidentCount,
    DateTime? lastIncidentDate,
    String? region,
    String? city,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (geometryType != null) updates['geometry_type'] = geometryType;
      if (centerLatitude != null) updates['center_latitude'] = centerLatitude;
      if (centerLongitude != null) updates['center_longitude'] = centerLongitude;
      if (radiusMeters != null) updates['radius_meters'] = radiusMeters;
      if (polygonPoints != null) updates['polygon_points'] = polygonPoints;
      if (crimeTypes != null) updates['crime_types'] = crimeTypes;
      if (riskLevel != null) updates['risk_level'] = riskLevel;
      if (warningMessage != null) updates['warning_message'] = warningMessage;
      if (safetyTips != null) updates['safety_tips'] = safetyTips;
      if (activeHours != null) updates['active_hours'] = activeHours;
      if (isAlwaysActive != null) updates['is_always_active'] = isAlwaysActive;
      if (incidentCount != null) updates['incident_count'] = incidentCount;
      if (lastIncidentDate != null) {
        updates['last_incident_date'] = lastIncidentDate.toIso8601String();
      }
      if (region != null) updates['region'] = region;
      if (city != null) updates['city'] = city;
      if (isActive != null) updates['is_active'] = isActive;
      
      final response = await _supabase.client
          .from(_tableName)
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      
      AppLogger.info('Updated danger zone: $id');
      return DangerZone.fromJson(response);
    } catch (e, stackTrace) {
      AppLogger.error('Error updating danger zone $id', e, stackTrace);
      return null;
    }
  }
  
  /// Delete a danger zone (admin only)
  Future<bool> deleteDangerZone(String id) async {
    try {
      await _supabase.client
          .from(_tableName)
          .delete()
          .eq('id', id);
      
      AppLogger.info('Deleted danger zone: $id');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting danger zone $id', e, stackTrace);
      return false;
    }
  }
  
  /// Toggle danger zone active status
  Future<bool> toggleDangerZoneStatus(String id, bool isActive) async {
    try {
      await _supabase.client
          .from(_tableName)
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      
      AppLogger.info('Toggled danger zone $id active status to $isActive');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error toggling danger zone status', e, stackTrace);
      return false;
    }
  }
  
  /// Increment incident count for a danger zone
  Future<bool> incrementIncidentCount(String id) async {
    try {
      // Get current count
      final zone = await getDangerZone(id);
      if (zone == null) return false;
      
      final newCount = (zone.incidentCount ?? 0) + 1;
      
      await _supabase.client
          .from(_tableName)
          .update({
            'incident_count': newCount,
            'last_incident_date': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      
      AppLogger.info('Incremented incident count for danger zone $id to $newCount');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error incrementing incident count', e, stackTrace);
      return false;
    }
  }
  
  /// Get danger zones near a location
  Future<List<DangerZone>> getDangerZonesNearLocation(
    double latitude,
    double longitude, {
    double radiusKm = 5.0,
  }) async {
    try {
      // Get all active zones
      final zones = await getActiveDangerZones();
      
      // Filter by proximity
      final nearbyZones = <DangerZone>[];
      
      for (final zone in zones) {
        final center = zone.center;
        final distance = _calculateDistance(
          latitude,
          longitude,
          center.latitude,
          center.longitude,
        );
        
        if (distance <= radiusKm) {
          nearbyZones.add(zone);
        }
      }
      
      // Sort by risk level (critical first)
      nearbyZones.sort((a, b) {
        const riskOrder = {
          DangerZoneRiskLevel.critical: 0,
          DangerZoneRiskLevel.high: 1,
          DangerZoneRiskLevel.medium: 2,
          DangerZoneRiskLevel.low: 3,
        };
        return (riskOrder[a.riskLevel] ?? 4).compareTo(riskOrder[b.riskLevel] ?? 4);
      });
      
      return nearbyZones;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting danger zones near location', e, stackTrace);
      return [];
    }
  }
  
  /// Check if user is currently inside any danger zone
  Future<List<DangerZone>> checkUserInDangerZones(
    double latitude,
    double longitude,
  ) async {
    try {
      final zones = await getActiveDangerZones();
      final zonesContainingUser = <DangerZone>[];
      
      for (final zone in zones) {
        if (zone.containsPoint(latitude, longitude)) {
          zonesContainingUser.add(zone);
        }
      }
      
      // Sort by risk level (critical first)
      zonesContainingUser.sort((a, b) {
        const riskOrder = {
          DangerZoneRiskLevel.critical: 0,
          DangerZoneRiskLevel.high: 1,
          DangerZoneRiskLevel.medium: 2,
          DangerZoneRiskLevel.low: 3,
        };
        return (riskOrder[a.riskLevel] ?? 4).compareTo(riskOrder[b.riskLevel] ?? 4);
      });
      
      return zonesContainingUser;
    } catch (e, stackTrace) {
      AppLogger.error('Error checking user in danger zones', e, stackTrace);
      return [];
    }
  }
  
  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadiusKm * c;
  }
  
  double _toRadians(double degrees) => degrees * math.pi / 180;
  
  /// Get statistics about danger zones
  Future<Map<String, dynamic>> getDangerZoneStatistics() async {
    try {
      final zones = await getAllDangerZones();
      
      final stats = <String, dynamic>{
        'total_zones': zones.length,
        'active_zones': zones.where((z) => z.isActive).length,
        'by_risk_level': <String, int>{},
        'total_incidents': 0,
        'crime_type_distribution': <String, int>{},
      };
      
      for (final zone in zones) {
        // Count by risk level
        final riskKey = zone.riskLevel.value;
        stats['by_risk_level'][riskKey] = 
            ((stats['by_risk_level'] as Map)[riskKey] ?? 0) + 1;
        
        // Sum incidents
        stats['total_incidents'] = 
            (stats['total_incidents'] as int) + (zone.incidentCount ?? 0);
        
        // Crime type distribution
        for (final crimeType in zone.crimeTypes) {
          final typeKey = crimeType.value;
          stats['crime_type_distribution'][typeKey] = 
              ((stats['crime_type_distribution'] as Map)[typeKey] ?? 0) + 1;
        }
      }
      
      return stats;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting danger zone statistics', e, stackTrace);
      return {};
    }
  }
}





