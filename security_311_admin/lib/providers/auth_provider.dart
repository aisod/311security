import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:security_311_admin/services/auth_service.dart';
import 'package:security_311_admin/core/logger.dart';

/// Authentication state provider
///
/// Manages user authentication state, login/logout operations,
/// and user profile information using Provider state management.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // Private state
  User? _user;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Public getters
  User? get user => _user;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  /// Initialize the auth provider
  ///
  /// Sets up auth state listener and loads current user if authenticated
  Future<void> initialize() async {
    if (_isInitialized) return;

    AppLogger.info('Initializing AuthProvider...');

    try {
      // Listen to auth state changes
      _authService.authStateChanges.listen((authState) {
        _handleAuthStateChange(authState);
      });

      // Get current user if already authenticated
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _user = currentUser;
        await _loadUserProfile();
      }

      _isInitialized = true;
      AppLogger.info('AuthProvider initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize AuthProvider', e, stackTrace);
      _error = 'Failed to initialize authentication';
    }

    notifyListeners();
  }

  /// Handle authentication state changes
  void _handleAuthStateChange(AuthState authState) {
    AppLogger.info('Auth state changed: ${authState.event}');

    final newUser = authState.session?.user;

    if (newUser != _user) {
      _user = newUser;

      if (_user != null) {
        // User signed in
        AppLogger.info('User signed in: ${_user!.email}');
        _loadUserProfile();
      } else {
        // User signed out
        AppLogger.info('User signed out');
        _userProfile = null;
      }

      _clearError();
      notifyListeners();
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    AppLogger.info('Attempting sign in for: $email');

    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signIn(
        email: email,
        password: password,
      );

      if (result.success) {
        AppLogger.info('Sign in successful');
        // Auth state change will be handled by the listener
        return true;
      } else {
        _setError(result.error ?? 'Sign in failed');
        AppLogger.warning('Sign in failed: ${result.error}');
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Sign in error', e, stackTrace);
      _setError('An unexpected error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign up with user details
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    String? region,
    String? idNumber,
    String? idType,
  }) async {
    AppLogger.info('Attempting sign up for: $email');

    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        region: region,
        idNumber: idNumber,
        idType: idType,
      );

      if (result.success) {
        AppLogger.info('Sign up successful');
        // Auth state change will be handled by the listener
        return true;
      } else {
        _setError(result.error ?? 'Sign up failed');
        AppLogger.warning('Sign up failed: ${result.error}');
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Sign up error', e, stackTrace);
      _setError('An unexpected error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out the current user
  Future<bool> signOut() async {
    AppLogger.info('Attempting sign out');

    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signOut();

      if (result.success) {
        AppLogger.info('Sign out successful');
        // Auth state change will be handled by the listener
        return true;
      } else {
        _setError(result.error ?? 'Sign out failed');
        AppLogger.warning('Sign out failed: ${result.error}');
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Sign out error', e, stackTrace);
      _setError('An unexpected error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset password for email
  Future<bool> resetPassword(String email) async {
    AppLogger.info('Attempting password reset for: $email');

    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.resetPassword(email);

      if (result.success) {
        AppLogger.info('Password reset email sent');
        return true;
      } else {
        _setError(result.error ?? 'Password reset failed');
        AppLogger.warning('Password reset failed: ${result.error}');
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Password reset error', e, stackTrace);
      _setError('An unexpected error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update user password
  Future<bool> updatePassword(String newPassword) async {
    if (!isAuthenticated) {
      _setError('User not authenticated');
      return false;
    }

    AppLogger.info('Updating user password');

    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.updatePassword(newPassword);

      if (result.success) {
        AppLogger.info('Password updated successfully');
        return true;
      } else {
        _setError(result.error ?? 'Password update failed');
        AppLogger.warning('Password update failed: ${result.error}');
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Password update error', e, stackTrace);
      _setError('An unexpected error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? region,
  }) async {
    if (!isAuthenticated) {
      _setError('User not authenticated');
      return false;
    }

    AppLogger.info('Updating user profile');

    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        region: region,
      );

      if (result.success) {
        AppLogger.info('Profile updated successfully');
        await _loadUserProfile(); // Reload profile
        return true;
      } else {
        _setError(result.error ?? 'Profile update failed');
        AppLogger.warning('Profile update failed: ${result.error}');
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Profile update error', e, stackTrace);
      _setError('An unexpected error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load user profile from database
  /// Creates profile if it doesn't exist
  Future<void> _loadUserProfile() async {
    if (_user == null) return;

    try {
      AppLogger.info('Loading user profile for ${_user!.id}');
      final profile = await _authService.getCurrentUserProfile();

      if (profile != null) {
        // Validate profile has required fields
        try {
          // Ensure all required fields exist
          final validatedProfile = Map<String, dynamic>.from(profile);
          validatedProfile['id'] = validatedProfile['id'] ?? _user!.id;
          validatedProfile['email'] = validatedProfile['email'] ?? _user!.email ?? '';
          validatedProfile['full_name'] = validatedProfile['full_name'] ?? 'User';
          validatedProfile['phone_number'] = validatedProfile['phone_number'] ?? '';
          validatedProfile['role'] = validatedProfile['role'] ?? 'user';
          
          _userProfile = validatedProfile;
          AppLogger.info(
              'User profile loaded successfully: ${validatedProfile['full_name']}');
        } catch (e, stackTrace) {
          AppLogger.error('Error validating profile data', e, stackTrace);
          // Create a minimal valid profile
          _userProfile = {
            'id': _user!.id,
            'email': _user!.email ?? '',
            'full_name': _user!.userMetadata?['full_name'] ?? 
                _user!.email?.split('@').first ?? 
                'User',
            'phone_number': _user!.userMetadata?['phone_number'] ?? '',
            'role': 'user',
            'is_verified': false,
            'is_active': true,
          };
        }
      } else {
        AppLogger.warning('No user profile found for ${_user!.id}');
        // Create a minimal profile from auth user data
        _userProfile = {
          'id': _user!.id,
          'email': _user!.email ?? '',
          'full_name': _user!.userMetadata?['full_name'] ?? 
              _user!.email?.split('@').first ?? 
              'User',
          'phone_number': _user!.userMetadata?['phone_number'] ?? '',
          'role': 'user',
          'is_verified': false,
          'is_active': true,
        };
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load user profile', e, stackTrace);
      // Create fallback profile to prevent null errors
      if (_user != null) {
        _userProfile = {
          'id': _user!.id,
          'email': _user!.email ?? '',
          'full_name': _user!.userMetadata?['full_name'] ?? 
              _user!.email?.split('@').first ?? 
              'User',
          'phone_number': _user!.userMetadata?['phone_number'] ?? '',
          'role': 'user',
          'is_verified': false,
          'is_active': true,
        };
      } else {
        _userProfile = null;
      }
    }

    notifyListeners();
  }

  /// Refresh user profile
  Future<void> refreshProfile() async {
    await _loadUserProfile();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Clear error manually (for UI)
  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    AppLogger.info('Disposing AuthProvider');
    super.dispose();
  }
}
