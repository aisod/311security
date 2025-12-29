import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:security_311_admin/services/supabase_service.dart';
import 'package:security_311_admin/core/logger.dart';

/// Service for managing danger zones in Supabase
class DangerZoneService {
  final SupabaseService _supabase = SupabaseService();
  
  /// Table name in Supabase
  static const String _tableName = 'danger_zones';
  
  /// Get all active danger zones
  Future<List<Map<String, dynamic>>> getActiveDangerZones({
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
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      AppLogger.error('Error getting active danger zones', e, stackTrace);
      return [];
    }
  }
  
  /// Get all danger zones (for admin)
  Future<List<Map<String, dynamic>>> getAllDangerZones() async {
    try {
      final response = await _supabase.client
          .from(_tableName)
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      AppLogger.error('Error getting all danger zones', e, stackTrace);
      return [];
    }
  }
  
  /// Create a new danger zone (admin only)
  Future<Map<String, dynamic>?> createDangerZone({
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
      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Error creating danger zone', e, stackTrace);
      return null;
    }
  }
  
  /// Update a danger zone (admin only)
  Future<Map<String, dynamic>?> updateDangerZone(
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
      return response;
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
  
  /// Get statistics about danger zones
  Future<Map<String, dynamic>> getDangerZoneStatistics() async {
    try {
      final zones = await getAllDangerZones();
      
      final stats = <String, dynamic>{
        'total_zones': zones.length,
        'active_zones': zones.where((z) => z['is_active'] == true).length,
        'by_risk_level': <String, int>{},
        'total_incidents': 0,
        'crime_type_distribution': <String, int>{},
      };
      
      for (final zone in zones) {
        // Count by risk level
        final riskKey = zone['risk_level'] as String? ?? 'medium';
        stats['by_risk_level'][riskKey] = 
            ((stats['by_risk_level'] as Map)[riskKey] ?? 0) + 1;
        
        // Sum incidents
        stats['total_incidents'] = 
            (stats['total_incidents'] as int) + (zone['incident_count'] as int? ?? 0);
        
        // Crime type distribution
        final crimeTypes = zone['crime_types'] as List? ?? [];
        for (final crimeType in crimeTypes) {
          final typeKey = crimeType.toString();
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
  
  /// Check if a point is inside a circle
  bool isPointInCircle(
    double pointLat, 
    double pointLng, 
    double centerLat, 
    double centerLng, 
    double radiusMeters,
  ) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(pointLat - centerLat);
    final dLng = _toRadians(pointLng - centerLng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(centerLat)) *
            math.cos(_toRadians(pointLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = earthRadius * c;
    
    return distance <= radiusMeters;
  }
  
  /// Check if a point is inside a polygon
  bool isPointInPolygon(double lat, double lng, List<LatLng> polygonPoints) {
    if (polygonPoints.length < 3) return false;
    
    bool inside = false;
    int j = polygonPoints.length - 1;
    
    for (int i = 0; i < polygonPoints.length; i++) {
      final xi = polygonPoints[i].latitude;
      final yi = polygonPoints[i].longitude;
      final xj = polygonPoints[j].latitude;
      final yj = polygonPoints[j].longitude;
      
      if (((yi > lng) != (yj > lng)) &&
          (lat < (xj - xi) * (lng - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }
    
    return inside;
  }
  
  double _toRadians(double degrees) => degrees * math.pi / 180;
}





