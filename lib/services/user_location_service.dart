import 'package:security_311_user/services/supabase_service.dart';
import 'package:security_311_user/services/location_service.dart';
import 'package:security_311_user/core/logger.dart';

/// Synchronizes the current user's location with Supabase.
class UserLocationService {
  UserLocationService();

  final SupabaseService _supabase = SupabaseService();

  /// Upsert the current user's latest location for proximity alerts.
  Future<void> syncCurrentUserLocation(LocationData location) async {
    final user = _supabase.currentUser;
    if (user == null) {
      AppLogger.warning('Cannot sync location: no authenticated user');
      return;
    }

    final payload = {
      'user_id': user.id,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'accuracy': location.accuracy,
      'source': 'device',
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await _supabase.client.from('user_locations').upsert(
            payload,
            onConflict: 'user_id',
            ignoreDuplicates: false,
          );
      AppLogger.debug('Synced user location for ${user.email}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sync user location', e, stackTrace);
    }
  }

  /// Fetch recent user locations for monitoring (used by admin features).
  Future<List<Map<String, dynamic>>> getRecentUserLocations({
    Duration maxAge = const Duration(hours: 12),
  }) async {
    final since = DateTime.now().subtract(maxAge).toIso8601String();
    try {
      final rows = await _supabase.client
          .from('user_locations')
          .select('user_id, latitude, longitude, accuracy, updated_at')
          .gte('updated_at', since);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch user locations', e, stackTrace);
      return [];
    }
  }
}

