/// User notification model
class UserNotification {
  final String id;
  final String userId;
  final String type; // 'welcome', 'crime_report_status', 'verification_update', etc.
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? relatedEntityId; // ID of related crime report, alert, etc.
  final String? relatedEntityType; // 'crime_report', 'alert', 'emergency', etc.
  final Map<String, dynamic>? metadata;
  final String? actionUrl; // URL for deep linking

  UserNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.createdAt,
    this.relatedEntityId,
    this.relatedEntityType,
    this.metadata,
    this.actionUrl,
  });

  /// Create UserNotification from JSON data
  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      relatedEntityId: json['related_entity_id'] as String?,
      relatedEntityType: json['related_entity_type'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      actionUrl: json['action_url'] as String?,
    );
  }

  /// Convert UserNotification to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'related_entity_id': relatedEntityId,
      'related_entity_type': relatedEntityType,
      'metadata': metadata,
      'action_url': actionUrl,
    };
  }

  /// Create a copy with updated fields
  UserNotification copyWith({
    bool? isRead,
  }) {
    return UserNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      relatedEntityId: relatedEntityId,
      relatedEntityType: relatedEntityType,
      metadata: metadata,
      actionUrl: actionUrl,
    );
  }
}

/// Notification type enum
enum NotificationType {
  welcome,
  crimeReportStatus,
  verificationUpdate,
  systemUpdate,
  emergencyResponse,
  safetyAlert,
  reminder,
  general,
  proximityAlert,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.welcome:
        return 'welcome';
      case NotificationType.crimeReportStatus:
        return 'crime_report_status';
      case NotificationType.verificationUpdate:
        return 'verification_update';
      case NotificationType.systemUpdate:
        return 'system_update';
      case NotificationType.emergencyResponse:
        return 'emergency_response';
      case NotificationType.safetyAlert:
        return 'safety_alert';
      case NotificationType.reminder:
        return 'reminder';
      case NotificationType.general:
        return 'general';
      case NotificationType.proximityAlert:
        return 'proximity_alert';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'welcome':
        return NotificationType.welcome;
      case 'crime_report_status':
        return NotificationType.crimeReportStatus;
      case 'verification_update':
        return NotificationType.verificationUpdate;
      case 'system_update':
        return NotificationType.systemUpdate;
      case 'emergency_response':
        return NotificationType.emergencyResponse;
      case 'safety_alert':
        return NotificationType.safetyAlert;
      case 'reminder':
        return NotificationType.reminder;
      case 'general':
        return NotificationType.general;
      case 'proximity_alert':
        return NotificationType.proximityAlert;
      default:
        return NotificationType.general;
    }
  }
}
