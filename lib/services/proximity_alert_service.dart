import 'dart:async';

import 'package:security_311_user/core/logger.dart';
import 'package:security_311_user/models/crime_report.dart';
import 'package:security_311_user/models/notification.dart';
import 'package:security_311_user/services/location_service.dart';
import 'package:security_311_user/services/supabase_service.dart';

/// Generates proximity-based alerts for nearby users when incidents occur.
class ProximityAlertService {
  ProximityAlertService();

  static const double defaultRadiusMeters = 2000; // 2km
  static const Duration _locationFreshness = Duration(hours: 12);

  final SupabaseService _supabase = SupabaseService();
  final LocationService _locationService = LocationService();

  Future<void> notifyUsersNearReport(
    CrimeReport report, {
    double radiusMeters = defaultRadiusMeters,
  }) async {
    if (report.latitude == null ||
        report.longitude == null ||
        report.latitude!.isNaN ||
        report.longitude!.isNaN) {
      AppLogger.warning(
          'Skipping proximity alerts: report ${report.id} missing coordinates');
      return;
    }

    try {
      final since = DateTime.now().subtract(_locationFreshness).toIso8601String();
      final locations = await _supabase.client
          .from('user_locations')
          .select('user_id, latitude, longitude, updated_at')
          .gte('updated_at', since);

      if (locations.isEmpty) {
        AppLogger.info('No user locations available for proximity alerts');
        return;
      }

      final List<Map<String, dynamic>> proximityRows = [];
      final List<Map<String, dynamic>> notificationRows = [];
      final Set<String> targetedUsers = {};

      for (final location in locations) {
        final userId = location['user_id'] as String?;
        if (userId == null || userId == report.userId) {
          continue; // Skip anonymous or reporting user
        }

        final lat = (location['latitude'] as num?)?.toDouble();
        final lng = (location['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;

        final distanceKm = _locationService.getDistanceBetween(
          report.latitude!,
          report.longitude!,
          lat,
          lng,
        );
        final distanceMeters = distanceKm * 1000;

        if (distanceMeters > radiusMeters) continue;
        if (targetedUsers.contains(userId)) continue;
        targetedUsers.add(userId);

        proximityRows.add({
          'crime_report_id': report.id,
          'target_user_id': userId,
          'distance_meters': distanceMeters,
          'radius_meters': radiusMeters,
          'metadata': {
            'crime_type': report.crimeType,
            'region': report.region,
            'city': report.city,
            'severity': report.severity,
          },
        });

        notificationRows.add({
          'user_id': userId,
          'type': NotificationType.proximityAlert.value,
          'title': 'Incident reported near you',
          'message':
              'A ${report.crimeType.toLowerCase()} was reported ${_formatDistance(distanceMeters)} away in ${report.city}. Stay alert and report suspicious activity.',
          'related_entity_id': report.id,
          'related_entity_type': 'crime_report',
          'metadata': {
            'distance_meters': distanceMeters,
            'crime_type': report.crimeType,
            'severity': report.severity,
            'latitude': report.latitude,
            'longitude': report.longitude,
            'region': report.region,
          },
        });
      }

      if (proximityRows.isEmpty) {
        AppLogger.info('No nearby users to notify for report ${report.id}');
        return;
      }

      await Future.wait([
        _supabase.client.from('proximity_alerts').upsert(
              proximityRows,
              onConflict: 'crime_report_id,target_user_id',
            ),
        _supabase.client.from('user_notifications').insert(notificationRows),
      ]);

      AppLogger.info(
          'Created ${proximityRows.length} proximity alerts for report ${report.id}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create proximity alerts', e, stackTrace);
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

