/// User roles for access control
enum UserRole {
  user('user'),
  admin('admin'),
  superAdmin('super_admin');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.user,
    );
  }
}

/// User profile model
class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String? region;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  final String? profileImageUrl;
  final UserRole role;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    this.region,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.profileImageUrl,
    this.role = UserRole.user,
  });

  /// Create UserProfile from JSON data
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String,
      region: json['region'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isVerified: json['is_verified'] as bool? ?? false,
      profileImageUrl: json['profile_image_url'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'user'),
    );
  }

  /// Convert UserProfile to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'region': region,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_verified': isVerified,
      'profile_image_url': profileImageUrl,
      'role': role.value,
    };
  }

  /// Create a copy with updated fields
  UserProfile copyWith({
    String? fullName,
    String? phoneNumber,
    String? region,
    bool? isVerified,
    String? profileImageUrl,
    UserRole? role,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      region: region ?? this.region,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isVerified: isVerified ?? this.isVerified,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
    );
  }
}
