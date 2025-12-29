import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Types of geometry for danger zones
enum DangerZoneGeometryType {
  circle,
  polygon,
}

/// Crime types that can be associated with a danger zone
enum DangerZoneCrimeType {
  theft,
  robbery,
  assault,
  carjacking,
  mugging,
  burglary,
  vandalism,
  drugActivity,
  gangActivity,
  fraud,
  kidnapping,
  general,
}

extension DangerZoneCrimeTypeExtension on DangerZoneCrimeType {
  String get value {
    switch (this) {
      case DangerZoneCrimeType.theft:
        return 'theft';
      case DangerZoneCrimeType.robbery:
        return 'robbery';
      case DangerZoneCrimeType.assault:
        return 'assault';
      case DangerZoneCrimeType.carjacking:
        return 'carjacking';
      case DangerZoneCrimeType.mugging:
        return 'mugging';
      case DangerZoneCrimeType.burglary:
        return 'burglary';
      case DangerZoneCrimeType.vandalism:
        return 'vandalism';
      case DangerZoneCrimeType.drugActivity:
        return 'drug_activity';
      case DangerZoneCrimeType.gangActivity:
        return 'gang_activity';
      case DangerZoneCrimeType.fraud:
        return 'fraud';
      case DangerZoneCrimeType.kidnapping:
        return 'kidnapping';
      case DangerZoneCrimeType.general:
        return 'general';
    }
  }

  String get displayName {
    switch (this) {
      case DangerZoneCrimeType.theft:
        return 'Theft';
      case DangerZoneCrimeType.robbery:
        return 'Robbery';
      case DangerZoneCrimeType.assault:
        return 'Assault';
      case DangerZoneCrimeType.carjacking:
        return 'Carjacking';
      case DangerZoneCrimeType.mugging:
        return 'Mugging';
      case DangerZoneCrimeType.burglary:
        return 'Burglary';
      case DangerZoneCrimeType.vandalism:
        return 'Vandalism';
      case DangerZoneCrimeType.drugActivity:
        return 'Drug Activity';
      case DangerZoneCrimeType.gangActivity:
        return 'Gang Activity';
      case DangerZoneCrimeType.fraud:
        return 'Fraud';
      case DangerZoneCrimeType.kidnapping:
        return 'Kidnapping';
      case DangerZoneCrimeType.general:
        return 'General Crime';
    }
  }

  static DangerZoneCrimeType fromString(String value) {
    switch (value) {
      case 'theft':
        return DangerZoneCrimeType.theft;
      case 'robbery':
        return DangerZoneCrimeType.robbery;
      case 'assault':
        return DangerZoneCrimeType.assault;
      case 'carjacking':
        return DangerZoneCrimeType.carjacking;
      case 'mugging':
        return DangerZoneCrimeType.mugging;
      case 'burglary':
        return DangerZoneCrimeType.burglary;
      case 'vandalism':
        return DangerZoneCrimeType.vandalism;
      case 'drug_activity':
        return DangerZoneCrimeType.drugActivity;
      case 'gang_activity':
        return DangerZoneCrimeType.gangActivity;
      case 'fraud':
        return DangerZoneCrimeType.fraud;
      case 'kidnapping':
        return DangerZoneCrimeType.kidnapping;
      default:
        return DangerZoneCrimeType.general;
    }
  }
}

/// Risk level for danger zones
enum DangerZoneRiskLevel {
  low,
  medium,
  high,
  critical,
}

extension DangerZoneRiskLevelExtension on DangerZoneRiskLevel {
  String get value {
    switch (this) {
      case DangerZoneRiskLevel.low:
        return 'low';
      case DangerZoneRiskLevel.medium:
        return 'medium';
      case DangerZoneRiskLevel.high:
        return 'high';
      case DangerZoneRiskLevel.critical:
        return 'critical';
    }
  }

  String get displayName {
    switch (this) {
      case DangerZoneRiskLevel.low:
        return 'Low Risk';
      case DangerZoneRiskLevel.medium:
        return 'Medium Risk';
      case DangerZoneRiskLevel.high:
        return 'High Risk';
      case DangerZoneRiskLevel.critical:
        return 'Critical Risk';
    }
  }

  static DangerZoneRiskLevel fromString(String value) {
    switch (value) {
      case 'low':
        return DangerZoneRiskLevel.low;
      case 'medium':
        return DangerZoneRiskLevel.medium;
      case 'high':
        return DangerZoneRiskLevel.high;
      case 'critical':
        return DangerZoneRiskLevel.critical;
      default:
        return DangerZoneRiskLevel.medium;
    }
  }
}

/// Model representing a dangerous area on the map
class DangerZone {
  final String id;
  final String name;
  final String? description;
  final DangerZoneGeometryType geometryType;
  
  // For circle geometry
  final double? centerLatitude;
  final double? centerLongitude;
  final double? radiusMeters;
  
  // For polygon geometry - stored as JSON array of {lat, lng} objects
  final List<LatLng>? polygonPoints;
  
  // Crime information
  final List<DangerZoneCrimeType> crimeTypes;
  final DangerZoneRiskLevel riskLevel;
  final String? warningMessage;
  final String? safetyTips;
  
  // Time-based activity (when is this area most dangerous)
  final List<String>? activeHours; // e.g., ["18:00-06:00", "weekends"]
  final bool isAlwaysActive;
  
  // Statistics
  final int? incidentCount;
  final DateTime? lastIncidentDate;
  
  // Metadata
  final String? region;
  final String? city;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  
  DangerZone({
    required this.id,
    required this.name,
    this.description,
    required this.geometryType,
    this.centerLatitude,
    this.centerLongitude,
    this.radiusMeters,
    this.polygonPoints,
    required this.crimeTypes,
    required this.riskLevel,
    this.warningMessage,
    this.safetyTips,
    this.activeHours,
    this.isAlwaysActive = true,
    this.incidentCount,
    this.lastIncidentDate,
    this.region,
    this.city,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });
  
  /// Create from Supabase JSON
  factory DangerZone.fromJson(Map<String, dynamic> json) {
    // Parse polygon points from JSON
    List<LatLng>? polygonPoints;
    if (json['polygon_points'] != null) {
      final points = json['polygon_points'] as List;
      polygonPoints = points.map((point) {
        if (point is Map) {
          return LatLng(
            (point['lat'] as num).toDouble(),
            (point['lng'] as num).toDouble(),
          );
        }
        return const LatLng(0, 0);
      }).toList();
    }
    
    // Parse crime types
    List<DangerZoneCrimeType> crimeTypes = [];
    if (json['crime_types'] != null) {
      final types = json['crime_types'] as List;
      crimeTypes = types
          .map((t) => DangerZoneCrimeTypeExtension.fromString(t.toString()))
          .toList();
    }
    
    // Parse active hours
    List<String>? activeHours;
    if (json['active_hours'] != null) {
      activeHours = List<String>.from(json['active_hours'] as List);
    }
    
    return DangerZone(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      geometryType: json['geometry_type'] == 'polygon'
          ? DangerZoneGeometryType.polygon
          : DangerZoneGeometryType.circle,
      centerLatitude: (json['center_latitude'] as num?)?.toDouble(),
      centerLongitude: (json['center_longitude'] as num?)?.toDouble(),
      radiusMeters: (json['radius_meters'] as num?)?.toDouble(),
      polygonPoints: polygonPoints,
      crimeTypes: crimeTypes,
      riskLevel: DangerZoneRiskLevelExtension.fromString(
          json['risk_level'] as String? ?? 'medium'),
      warningMessage: json['warning_message'] as String?,
      safetyTips: json['safety_tips'] as String?,
      activeHours: activeHours,
      isAlwaysActive: json['is_always_active'] as bool? ?? true,
      incidentCount: json['incident_count'] as int?,
      lastIncidentDate: json['last_incident_date'] != null
          ? DateTime.parse(json['last_incident_date'] as String)
          : null,
      region: json['region'] as String?,
      city: json['city'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
    );
  }
  
  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    // Convert polygon points to JSON
    List<Map<String, double>>? polygonPointsJson;
    if (polygonPoints != null) {
      polygonPointsJson = polygonPoints!
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList();
    }
    
    return {
      'id': id,
      'name': name,
      'description': description,
      'geometry_type': geometryType == DangerZoneGeometryType.polygon
          ? 'polygon'
          : 'circle',
      'center_latitude': centerLatitude,
      'center_longitude': centerLongitude,
      'radius_meters': radiusMeters,
      'polygon_points': polygonPointsJson,
      'crime_types': crimeTypes.map((t) => t.value).toList(),
      'risk_level': riskLevel.value,
      'warning_message': warningMessage,
      'safety_tips': safetyTips,
      'active_hours': activeHours,
      'is_always_active': isAlwaysActive,
      'incident_count': incidentCount,
      'last_incident_date': lastIncidentDate?.toIso8601String(),
      'region': region,
      'city': city,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }
  
  /// Get the center point of this zone
  LatLng get center {
    if (geometryType == DangerZoneGeometryType.circle) {
      return LatLng(centerLatitude ?? 0, centerLongitude ?? 0);
    } else if (polygonPoints != null && polygonPoints!.isNotEmpty) {
      // Calculate centroid of polygon
      double latSum = 0;
      double lngSum = 0;
      for (final point in polygonPoints!) {
        latSum += point.latitude;
        lngSum += point.longitude;
      }
      return LatLng(
        latSum / polygonPoints!.length,
        lngSum / polygonPoints!.length,
      );
    }
    return const LatLng(0, 0);
  }
  
  /// Check if a point is inside this danger zone
  bool containsPoint(double latitude, double longitude) {
    if (!isActive) return false;
    
    if (geometryType == DangerZoneGeometryType.circle) {
      return _isPointInCircle(latitude, longitude);
    } else {
      return _isPointInPolygon(latitude, longitude);
    }
  }
  
  bool _isPointInCircle(double lat, double lng) {
    if (centerLatitude == null || centerLongitude == null || radiusMeters == null) {
      return false;
    }
    
    // Haversine formula for distance
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(lat - centerLatitude!);
    final dLng = _toRadians(lng - centerLongitude!);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(centerLatitude!)) *
            _cos(_toRadians(lat)) *
            _sin(dLng / 2) *
            _sin(dLng / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    final distance = earthRadius * c;
    
    return distance <= radiusMeters!;
  }
  
  bool _isPointInPolygon(double lat, double lng) {
    if (polygonPoints == null || polygonPoints!.length < 3) {
      return false;
    }
    
    // Ray casting algorithm
    bool inside = false;
    final points = polygonPoints!;
    int j = points.length - 1;
    
    for (int i = 0; i < points.length; i++) {
      final xi = points[i].latitude;
      final yi = points[i].longitude;
      final xj = points[j].latitude;
      final yj = points[j].longitude;
      
      if (((yi > lng) != (yj > lng)) &&
          (lat < (xj - xi) * (lng - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }
    
    return inside;
  }
  
  // Math helpers for geospatial calculations
  double _toRadians(double degrees) => degrees * 3.141592653589793 / 180;
  double _sin(double x) => _trigSin(x);
  double _cos(double x) => _trigCos(x);
  double _sqrt(double x) => _mathSqrt(x);
  double _atan2(double y, double x) => _mathAtan2(y, x);
  
  // Dart's math functions
  static double _trigSin(double x) {
    // Taylor series approximation for sin
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }
  
  static double _trigCos(double x) {
    // Taylor series approximation for cos
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }
  
  static double _mathSqrt(double x) {
    if (x < 0) return double.nan;
    if (x == 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
  
  static double _mathAtan2(double y, double x) {
    // Simplified atan2 implementation
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0;
  }
  
  static double _atan(double x) {
    // Taylor series approximation for atan
    if (x.abs() > 1) {
      return (x > 0 ? 1 : -1) * (3.141592653589793 / 2 - _atan(1 / x.abs()));
    }
    double result = x;
    double term = x;
    for (int i = 1; i <= 20; i++) {
      term *= -x * x;
      result += term / (2 * i + 1);
    }
    return result;
  }
  
  /// Get formatted crime types string
  String get formattedCrimeTypes {
    if (crimeTypes.isEmpty) return 'General';
    return crimeTypes.map((t) => t.displayName).join(', ');
  }
  
  /// Get the alert message for when user enters this zone
  String getEntryAlertMessage() {
    final message = StringBuffer();
    message.write('⚠️ You have entered a high-risk area: $name\n\n');
    
    if (warningMessage != null && warningMessage!.isNotEmpty) {
      message.write('$warningMessage\n\n');
    }
    
    message.write('Known crime types: $formattedCrimeTypes\n');
    message.write('Risk level: ${riskLevel.displayName}\n\n');
    
    if (safetyTips != null && safetyTips!.isNotEmpty) {
      message.write('Safety tips: $safetyTips');
    }
    
    return message.toString();
  }
}

