/// Crime location marker data model
///
/// Represents a crime incident location on the map
/// with associated metadata and visualization
class CrimeLocation {
  final String id;
  final double latitude;
  final double longitude;
  final String crimeType;
  final String? title;
  final String? description;
  final DateTime reportedAt;
  final String severity;
  final bool isVerified;

  CrimeLocation({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.crimeType,
    this.title,
    this.description,
    required this.reportedAt,
    required this.severity,
    this.isVerified = false,
  });

  /// Create CrimeLocation from JSON data
  factory CrimeLocation.fromJson(Map<String, dynamic> json) {
    return CrimeLocation(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      crimeType: json['crime_type'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      reportedAt: DateTime.parse(json['reported_at'] as String),
      severity: json['severity'] as String,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  /// Convert CrimeLocation to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'crime_type': crimeType,
      'title': title,
      'description': description,
      'reported_at': reportedAt.toIso8601String(),
      'severity': severity,
      'is_verified': isVerified,
    };
  }
}

/// Crime type icons and colors mapping
class CrimeTypeConfig {
  final String iconPath;
  final int color;

  const CrimeTypeConfig({
    required this.iconPath,
    required this.color,
  });
}

/// Maps crime types to their visual configurations
class CrimeTypeVisuals {
  static const Map<String, CrimeTypeConfig> configs = {
    'theft': CrimeTypeConfig(
      iconPath: 'assets/images/theft_icon.png',
      color: 0xFFFF6B6B, // Red
    ),
    'robbery': CrimeTypeConfig(
      iconPath: 'assets/images/robbery_icon.png',
      color: 0xFFDC3545, // Dark Red
    ),
    'assault': CrimeTypeConfig(
      iconPath: 'assets/images/assault_icon.png',
      color: 0xFFE91E63, // Pink
    ),
    'vandalism': CrimeTypeConfig(
      iconPath: 'assets/images/vandalism_icon.png',
      color: 0xFFFF9800, // Orange
    ),
    'fraud': CrimeTypeConfig(
      iconPath: 'assets/images/fraud_icon.png',
      color: 0xFF9C27B0, // Purple
    ),
    'domestic_violence': CrimeTypeConfig(
      iconPath: 'assets/images/domestic_icon.png',
      color: 0xFF8E24AA, // Deep Purple
    ),
    'drug_related': CrimeTypeConfig(
      iconPath: 'assets/images/drug_icon.png',
      color: 0xFF4CAF50, // Green
    ),
    'corruption': CrimeTypeConfig(
      iconPath: 'assets/images/corruption_icon.png',
      color: 0xFF607D8B, // Blue Grey
    ),
    'other': CrimeTypeConfig(
      iconPath: 'assets/images/generic_icon.png',
      color: 0xFF9E9E9E, // Grey
    ),
  };

  static CrimeTypeConfig getConfig(String crimeType) {
    return configs[crimeType.toLowerCase()] ?? configs['other']!;
  }

  static int getColor(String crimeType) {
    return getConfig(crimeType).color;
  }

  static String getIconPath(String crimeType) {
    return getConfig(crimeType).iconPath;
  }
}
