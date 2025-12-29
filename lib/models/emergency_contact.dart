/// Emergency contact model
class EmergencyContact {
  final String id;
  final String userId;
  final String name;
  final String phoneNumber;
  final String relationship; // 'family', 'friend', 'colleague', 'other'
  final int priority; // 1 = highest priority, 5 = lowest
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;

  EmergencyContact({
    required this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.priority = 3,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  /// Create EmergencyContact from JSON data
  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      relationship: json['relationship'] as String,
      priority: json['priority'] as int? ?? 3,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      notes: json['notes'] as String?,
    );
  }

  /// Convert EmergencyContact to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone_number': phoneNumber,
      'relationship': relationship,
      'priority': priority,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'notes': notes,
    };
  }

  /// Create a copy with updated fields
  EmergencyContact copyWith({
    String? name,
    String? phoneNumber,
    String? relationship,
    int? priority,
    bool? isActive,
    String? notes,
  }) {
    return EmergencyContact(
      id: id,
      userId: userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      notes: notes ?? this.notes,
    );
  }
}

/// Emergency contact relationship enum
enum ContactRelationship {
  family,
  friend,
  colleague,
  neighbor,
  other,
}

extension ContactRelationshipExtension on ContactRelationship {
  String get value {
    switch (this) {
      case ContactRelationship.family:
        return 'family';
      case ContactRelationship.friend:
        return 'friend';
      case ContactRelationship.colleague:
        return 'colleague';
      case ContactRelationship.neighbor:
        return 'neighbor';
      case ContactRelationship.other:
        return 'other';
    }
  }

  static ContactRelationship fromString(String value) {
    switch (value) {
      case 'family':
        return ContactRelationship.family;
      case 'friend':
        return ContactRelationship.friend;
      case 'colleague':
        return ContactRelationship.colleague;
      case 'neighbor':
        return ContactRelationship.neighbor;
      case 'other':
        return ContactRelationship.other;
      default:
        return ContactRelationship.other;
    }
  }

  String get displayName {
    switch (this) {
      case ContactRelationship.family:
        return 'Family';
      case ContactRelationship.friend:
        return 'Friend';
      case ContactRelationship.colleague:
        return 'Colleague';
      case ContactRelationship.neighbor:
        return 'Neighbor';
      case ContactRelationship.other:
        return 'Other';
    }
  }
}
