import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:security_311_super_admin/constants/app_constants.dart';

/// Supabase service for managing database operations and authentication
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() => _instance;

  SupabaseService._internal();

  /// Get the Supabase client instance
  SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase with the provided configuration
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
      debug: kDebugMode, // Only debug in development builds
    );
  }

  /// Get the current user
  User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get current session
  Session? get currentSession => client.auth.currentSession;

  /// Sign out the current user
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Listen to authentication state changes
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Test Supabase connection and basic functionality
  Future<Map<String, dynamic>> testConnection() async {
    final results = <String, dynamic>{};

    try {
      // Test 1: Basic connection
      await client.from('profiles').select('count').limit(1);
      results['connection'] = {
        'status': 'success',
        'message': 'Connected to Supabase'
      };

      // Test 2: Check if tables exist by trying to select from them
      final tables = [
        'profiles',
        'crime_reports',
        'safety_alerts',
        'user_notifications',
        'user_locations',
        'proximity_alerts',
        'emergency_contacts',
        'emergency_alerts'
      ];

      for (final table in tables) {
        try {
          await client.from(table).select('count').limit(1);
          results[table] = {'status': 'exists', 'message': 'Table accessible'};
        } catch (e) {
          results[table] = {
            'status': 'error',
            'message': 'Table may not exist or not accessible: $e'
          };
        }
      }

      // Test 3: Check authentication status
      final currentUser = client.auth.currentUser;
      results['auth'] = {
        'status': currentUser != null ? 'authenticated' : 'not_authenticated',
        'user': currentUser?.email ?? 'No user logged in'
      };

      results['overall_status'] = 'success';
    } catch (e) {
      results['overall_status'] = 'error';
      results['error'] = e.toString();
    }

    return results;
  }
}
