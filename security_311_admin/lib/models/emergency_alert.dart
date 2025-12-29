/// Emergency alert model for panic button activations
class EmergencyAlert {
  final String id;
  final String userId;
  final String type; // 'panic', 'medical', 'fire', 'crime_in_progress'
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? locationDescription;
  final bool isActive;
  final DateTime triggeredAt;
  final DateTime? resolvedAt;
  final String status; // 'active', 'responding', 'resolved', 'false_alarm'
  final List<String>? notifiedContacts;
  final List<String>? notifiedServices;
  final DateTime createdAt;
  final DateTime updatedAt;
  // User details
  final String? userFullName;
  final String? userPhoneNumber;

  EmergencyAlert({
    required this.id,
    required this.userId,
    required this.type,
    this.description,
    this.latitude,
    this.longitude,
    this.locationDescription,
    this.isActive = true,
    required this.triggeredAt,
    this.resolvedAt,
    this.status = 'active',
    this.notifiedContacts,
    this.notifiedServices,
    required this.createdAt,
    required this.updatedAt,
    this.userFullName,
    this.userPhoneNumber,
  });

  /// Create EmergencyAlert from JSON data
  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    // Parse nested user data if available
    Map<String, dynamic>? userData;
    if (json['user'] != null) {
      if (json['user'] is Map<String, dynamic>) {
        userData = json['user'] as Map<String, dynamic>;
      } else if (json['user'] is List && (json['user'] as List).isNotEmpty) {
        userData = (json['user'] as List).first as Map<String, dynamic>?;
      }
    }

    return EmergencyAlert(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      description: json['description'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      locationDescription: json['location_description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      triggeredAt: DateTime.parse(json['triggered_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      status: json['status'] as String? ?? 'active',
      notifiedContacts: json['notified_contacts'] != null
          ? List<String>.from(json['notified_contacts'] as List)
          : null,
      notifiedServices: json['notified_services'] != null
          ? List<String>.from(json['notified_services'] as List)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userFullName: userData?['full_name'] as String?,
      userPhoneNumber: userData?['phone_number'] as String?,
    );
  }

  /// Convert EmergencyAlert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'location_description': locationDescription,
      'is_active': isActive,
      'triggered_at': triggeredAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'status': status,
      'notified_contacts': notifiedContacts,
      'notified_services': notifiedServices,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_full_name': userFullName,
      'user_phone_number': userPhoneNumber,
    };
  }

  /// Create a copy with updated fields
  EmergencyAlert copyWith({
    bool? isActive,
    DateTime? resolvedAt,
    String? status,
    String? userFullName,
    String? userPhoneNumber,
  }) {
    return EmergencyAlert(
      id: id,
      userId: userId,
      type: type,
      description: description,
      latitude: latitude,
      longitude: longitude,
      locationDescription: locationDescription,
      isActive: isActive ?? this.isActive,
      triggeredAt: triggeredAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      status: status ?? this.status,
      notifiedContacts: notifiedContacts,
      notifiedServices: notifiedServices,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      userFullName: userFullName ?? this.userFullName,
      userPhoneNumber: userPhoneNumber ?? this.userPhoneNumber,
    );
  }

  /// Get duration since alert was triggered
  Duration get durationSinceTriggered {
    return DateTime.now().difference(triggeredAt);
  }

  /// Check if alert is resolved
  bool get isResolved {
    return status == 'resolved' || status == 'false_alarm';
  }
}

/// Emergency alert type enum
enum EmergencyAlertType {
  panic,
  medical,
  fire,
  crimeInProgress,
}

extension EmergencyAlertTypeExtension on EmergencyAlertType {
  String get value {
    switch (this) {
      case EmergencyAlertType.panic:
        return 'panic';
      case EmergencyAlertType.medical:
        return 'medical';
      case EmergencyAlertType.fire:
        return 'fire';
      case EmergencyAlertType.crimeInProgress:
        return 'crime_in_progress';
    }
  }

  static EmergencyAlertType fromString(String value) {
    switch (value) {
      case 'panic':
        return EmergencyAlertType.panic;
      case 'medical':
        return EmergencyAlertType.medical;
      case 'fire':
        return EmergencyAlertType.fire;
      case 'crime_in_progress':
        return EmergencyAlertType.crimeInProgress;
      default:
        return EmergencyAlertType.panic;
    }
  }

  String get displayName {
    switch (this) {
      case EmergencyAlertType.panic:
        return 'Panic Alert';
      case EmergencyAlertType.medical:
        return 'Medical Emergency';
      case EmergencyAlertType.fire:
        return 'Fire Emergency';
      case EmergencyAlertType.crimeInProgress:
        return 'Crime in Progress';
    }
  }

  String get description {
    switch (this) {
      case EmergencyAlertType.panic:
        return 'Immediate danger - send help now';
      case EmergencyAlertType.medical:
        return 'Medical assistance required';
      case EmergencyAlertType.fire:
        return 'Fire emergency - evacuate area';
      case EmergencyAlertType.crimeInProgress:
        return 'Crime happening right now';
    }
  }
}

/// Emergency alert status enum
enum EmergencyAlertStatus {
  active,
  responding,
  resolved,
  falseAlarm,
}

extension EmergencyAlertStatusExtension on EmergencyAlertStatus {
  String get value {
    switch (this) {
      case EmergencyAlertStatus.active:
        return 'active';
      case EmergencyAlertStatus.responding:
        return 'responding';
      case EmergencyAlertStatus.resolved:
        return 'resolved';
      case EmergencyAlertStatus.falseAlarm:
        return 'false_alarm';
    }
  }

  static EmergencyAlertStatus fromString(String value) {
    switch (value) {
      case 'active':
        return EmergencyAlertStatus.active;
      case 'responding':
        return EmergencyAlertStatus.responding;
      case 'resolved':
        return EmergencyAlertStatus.resolved;
      case 'false_alarm':
        return EmergencyAlertStatus.falseAlarm;
      default:
        return EmergencyAlertStatus.active;
    }
  }
}
