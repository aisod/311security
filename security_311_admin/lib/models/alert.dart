/// Safety alert model
class SafetyAlert {
  final String id;
  final String type; // 'crime_warning', 'weather_alert', 'road_closure', etc.
  final String title;
  final String message;
  final String? region;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? locationDescription;
  final List<String>? imageUrls; // Photo URLs for the alert
  final String severity; // 'info', 'warning', 'critical'
  final String priority; // 'low', 'medium', 'high', 'critical'
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy; // Admin user ID
  final Map<String, dynamic>? metadata;

  SafetyAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.region,
    this.city,
    this.latitude,
    this.longitude,
    this.locationDescription,
    this.imageUrls,
    required this.severity,
    required this.priority,
    this.isActive = true,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.metadata,
  });

  /// Create SafetyAlert from JSON data
  factory SafetyAlert.fromJson(Map<String, dynamic> json) {
    return SafetyAlert(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      region: json['region'] as String?,
      city: json['city'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      locationDescription: json['location_description'] as String?,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : null,
      severity: json['severity'] as String,
      priority: json['priority'] as String,
      isActive: json['is_active'] as bool? ?? true,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert SafetyAlert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'region': region,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'location_description': locationDescription,
      'image_urls': imageUrls,
      'severity': severity,
      'priority': priority,
      'is_active': isActive,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  SafetyAlert copyWith({
    bool? isActive,
    DateTime? expiresAt,
  }) {
    return SafetyAlert(
      id: id,
      type: type,
      title: title,
      message: message,
      region: region,
      city: city,
      latitude: latitude,
      longitude: longitude,
      locationDescription: locationDescription,
      imageUrls: imageUrls,
      severity: severity,
      priority: priority,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      createdBy: createdBy,
      metadata: metadata,
    );
  }

  /// Check if alert is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Get display color based on severity
  String get severityColor {
    switch (severity) {
      case 'critical':
        return 'red';
      case 'warning':
        return 'orange';
      case 'info':
      default:
        return 'blue';
    }
  }
}

/// Alert type enum
enum AlertType {
  wantedPerson,
  vehicleAlert,
  lostItems,
  foundItems,
  crimeWarning,
  weatherAlert,
  roadClosure,
  publicSafety,
  healthAlert,
  securityUpdate,
  communityNotice,
}

extension AlertTypeExtension on AlertType {
  String get value {
    switch (this) {
      case AlertType.wantedPerson:
        return 'wanted_person';
      case AlertType.vehicleAlert:
        return 'vehicle_alert';
      case AlertType.lostItems:
        return 'lost_items';
      case AlertType.foundItems:
        return 'found_items';
      case AlertType.crimeWarning:
        return 'crime_warning';
      case AlertType.weatherAlert:
        return 'weather_alert';
      case AlertType.roadClosure:
        return 'road_closure';
      case AlertType.publicSafety:
        return 'public_safety';
      case AlertType.healthAlert:
        return 'health_alert';
      case AlertType.securityUpdate:
        return 'security_update';
      case AlertType.communityNotice:
        return 'community_notice';
    }
  }

  static AlertType fromString(String value) {
    switch (value) {
      case 'wanted_person':
        return AlertType.wantedPerson;
      case 'vehicle_alert':
        return AlertType.vehicleAlert;
      case 'lost_items':
        return AlertType.lostItems;
      case 'found_items':
        return AlertType.foundItems;
      case 'crime_warning':
        return AlertType.crimeWarning;
      case 'weather_alert':
        return AlertType.weatherAlert;
      case 'road_closure':
        return AlertType.roadClosure;
      case 'public_safety':
        return AlertType.publicSafety;
      case 'health_alert':
        return AlertType.healthAlert;
      case 'security_update':
        return AlertType.securityUpdate;
      case 'community_notice':
        return AlertType.communityNotice;
      default:
        return AlertType.publicSafety;
    }
  }
}
