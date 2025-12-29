class Region {
  final String id;
  final String name;
  final String? description;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Region({
    required this.id,
    required this.name,
    this.description,
    this.latitude,
    this.longitude,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      latitude: (json['center_latitude'] as num?)?.toDouble(),
      longitude: (json['center_longitude'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'center_latitude': latitude,
      'center_longitude': longitude,
      'metadata': metadata,
      'updated_at': DateTime.now().toIso8601String(),
    }..removeWhere((key, value) => value == null);
  }
}

