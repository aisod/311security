import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:security_311_admin/services/supabase_service.dart';
import 'package:security_311_admin/core/logger.dart';

/// Result class for authentication operations
class AuthResult {
  final bool success;
  final String? error;
  final User? user;

  AuthResult({
    required this.success,
    this.error,
    this.user,
  });

  factory AuthResult.success(User user) {
    return AuthResult(success: true, user: user);
  }

  factory AuthResult.error(String error) {
    return AuthResult(success: false, error: error);
  }
}

/// Authentication service for managing user authentication
class AuthService {
  final SupabaseService _supabase = SupabaseService();

  /// Sign up with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    String? firstName,
    String? lastName,
    String? region,
    String? idNumber,
    String? idType,
  }) async {
    try {
      AppLogger.info('Attempting signup for $email');

      final response = await _supabase.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
          'region': region,
          'id_number': idNumber,
          'id_type': idType,
        }..removeWhere((key, value) => value == null),
      );

      if (response.user != null) {
        AppLogger.info('Signup successful for $email');

        // Create profile explicitly to ensure it exists
        try {
          final profileData = {
            'id': response.user!.id,
            'email': email,
            'full_name': fullName,
            'phone_number': phoneNumber,
            'region': region,
            'id_number': idNumber,
            'id_type': idType,
            'role': 'user',
            'is_active': true,
            'is_verified': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'metadata': {
              'first_name': firstName,
              'last_name': lastName,
              'id_number': idNumber,
              'id_type': idType,
              'phone_number': phoneNumber,
              'region': region,
            }..removeWhere((key, value) => value == null),
          }..removeWhere((key, value) => value == null);

          await _supabase.client.from('profiles').insert(profileData);

          AppLogger.info('Profile created successfully during signup');
        } catch (e) {
          // Profile might already exist or trigger might have created it
          AppLogger.warning('Profile creation during signup: $e');
          // Try to get existing profile
          await getCurrentUserProfile();
        }

        return AuthResult.success(response.user!);
      } else {
        AppLogger.warning('Signup failed: No user returned');
        return AuthResult.error('Failed to create account');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Signup error for $email', e, stackTrace);
      return AuthResult.error(e.toString());
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('Attempting sign in for $email');

      final response = await _supabase.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        AppLogger.info('Sign in successful for $email');

        // Ensure profile exists after sign in
        // This will create profile if it doesn't exist
        await getCurrentUserProfile();

        return AuthResult.success(response.user!);
      } else {
        return AuthResult.error('Invalid email or password');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Sign in error for $email', e, stackTrace);
      return AuthResult.error(e.toString());
    }
  }

  /// Sign out the current user
  Future<AuthResult> signOut() async {
    try {
      await _supabase.signOut();
      return AuthResult(success: true);
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  /// Reset password for the given email
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _supabase.client.auth.resetPasswordForEmail(email);
      return AuthResult(success: true);
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  /// Update user password
  Future<AuthResult> updatePassword(String newPassword) async {
    try {
      await _supabase.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return AuthResult(success: true);
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  /// Update user profile information
  Future<AuthResult> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? region,
    String? profileImageUrl,
  }) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) {
        return AuthResult.error('User not authenticated');
      }

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (region != null) updates['region'] = region;
      if (profileImageUrl != null) {
        updates['profile_image_url'] = profileImageUrl;
      }
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.client.from('profiles').update(updates).eq('id', user.id);

      AppLogger.info('Profile updated successfully for user ${user.id}');
      return AuthResult(success: true);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update profile', e, stackTrace);
      return AuthResult.error(e.toString());
    }
  }

  /// Get current user profile
  /// Creates profile if it doesn't exist using auth user metadata
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return null;

      // Try to get existing profile
      try {
        final response = await _supabase.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        return response;
      } catch (e) {
        // Profile doesn't exist, create it from auth user metadata
        AppLogger.info(
            'Profile not found, creating new profile for user ${user.id}');

        // Extract user data from auth metadata or use defaults
        final userMetadata = user.userMetadata ?? {};
        final fullName = userMetadata['full_name'] ??
            userMetadata['name'] ??
            user.email?.split('@').first ??
            'User';
        final phoneNumber =
            userMetadata['phone_number'] ?? userMetadata['phone'] ?? '';
        final region = userMetadata['region'];

        // Create profile in database
        final profileData = {
          'id': user.id,
          'email': user.email ?? '',
          'full_name': fullName,
          'phone_number': phoneNumber,
          'region': region,
          'role': 'user',
          'is_active': true,
          'is_verified': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await _supabase.client.from('profiles').insert(profileData);

        AppLogger.info('Profile created successfully for user ${user.id}');

        // Fetch and return the newly created profile
        final newProfile = await _supabase.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        return newProfile;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get or create user profile', e, stackTrace);
      return null;
    }
  }

  /// Listen to authentication state changes
  Stream<AuthState> get authStateChanges => _supabase.authStateChanges;

  /// Get current user
  User? get currentUser => _supabase.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _supabase.isAuthenticated;
}
