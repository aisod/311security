import 'dart:async';

import 'package:security_311_user/services/supabase_service.dart';
import 'package:security_311_user/services/proximity_alert_service.dart';
import 'package:security_311_user/models/crime_report.dart';
import 'package:security_311_user/core/logger.dart';

/// Service for managing crime reports
class CrimeReportService {
  final SupabaseService _supabase = SupabaseService();
  final ProximityAlertService _proximityAlertService =
      ProximityAlertService();

  /// Create a new crime report
  Future<CrimeReport?> createCrimeReport({
    required String crimeType,
    required String title,
    required String description,
    required String region,
    required String city,
    double? latitude,
    double? longitude,
    String? locationDescription,
    required DateTime incidentDate,
    required String severity,
    List<String>? evidenceUrls,
    bool isAnonymous = false,
  }) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return null;

      final data = {
        'user_id': user.id,
        'crime_type': crimeType,
        'title': title,
        'description': description,
        'region': region,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'location_description': locationDescription,
        'incident_date': incidentDate.toIso8601String(),
        'severity': severity,
        'evidence_urls': evidenceUrls,
        'is_anonymous': isAnonymous,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase.client
          .from('crime_reports')
          .insert(data)
          .select()
          .single();

      final report = CrimeReport.fromJson(response);
      unawaited(_proximityAlertService.notifyUsersNearReport(report));
      return report;
    } catch (e, stackTrace) {
      AppLogger.error('Error creating crime report', e, stackTrace);
      return null;
    }
  }

  /// Get all crime reports for the current user
  Future<List<CrimeReport>> getUserCrimeReports() async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return [];

      final response = await _supabase.client
          .from('crime_reports')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return response.map((json) => CrimeReport.fromJson(json)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error getting user crime reports', e, stackTrace);
      return [];
    }
  }

  /// Get recent crime reports
  Future<List<CrimeReport>> getRecentReports({int limit = 20}) async {
    try {
      final response = await _supabase.client
          .from('crime_reports')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((json) => CrimeReport.fromJson(json)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error getting recent reports', e, stackTrace);
      return [];
    }
  }

  /// Get crime reports by region (for public viewing)
  Future<List<CrimeReport>> getCrimeReportsByRegion(String region,
      {int limit = 50}) async {
    try {
      final response = await _supabase.client
          .from('crime_reports')
          .select()
          .eq('region', region)
          .eq('is_anonymous', false) // Only show non-anonymous reports
          .or('status.eq.approved,user_id.eq.${_supabase.currentUser?.id}') // Approved OR My Reports
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((json) => CrimeReport.fromJson(json)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error getting crime reports by region', e, stackTrace);
      return [];
    }
  }

  /// Get a specific crime report by ID
  Future<CrimeReport?> getCrimeReport(String reportId) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return null;

      final response = await _supabase.client
          .from('crime_reports')
          .select()
          .eq('id', reportId)
          .eq('user_id',
              user.id) // Ensure user can only access their own reports
          .single();

      return CrimeReport.fromJson(response);
    } catch (e, stackTrace) {
      AppLogger.error('Error getting crime report', e, stackTrace);
      return null;
    }
  }

  /// Update a crime report
  Future<CrimeReport?> updateCrimeReport(
    String reportId, {
    String? title,
    String? description,
    String? status,
    List<String>? evidenceUrls,
  }) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return null;

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (status != null) updates['status'] = status;
      if (evidenceUrls != null) updates['evidence_urls'] = evidenceUrls;

      final response = await _supabase.client
          .from('crime_reports')
          .update(updates)
          .eq('id', reportId)
          .eq('user_id', user.id)
          .select()
          .single();

      return CrimeReport.fromJson(response);
    } catch (e, stackTrace) {
      AppLogger.error('Error updating crime report', e, stackTrace);
      return null;
    }
  }

  /// Delete a crime report
  Future<bool> deleteCrimeReport(String reportId) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return false;

      await _supabase.client
          .from('crime_reports')
          .delete()
          .eq('id', reportId)
          .eq('user_id', user.id);

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting crime report', e, stackTrace);
      return false;
    }
  }

  /// Get crime reports statistics for the current user
  Future<Map<String, int>> getUserCrimeReportStats() async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return {};

      final response = await _supabase.client
          .from('crime_reports')
          .select('status')
          .eq('user_id', user.id);

      final stats = <String, int>{};
      for (final report in response) {
        final status = report['status'] as String? ?? 'pending';
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting crime report stats', e, stackTrace);
      return {};
    }
  }

  /// Listen to changes in user's crime reports
  Stream<List<CrimeReport>> watchUserCrimeReports() {
    final user = _supabase.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase.client
        .from('crime_reports')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => CrimeReport.fromJson(json)).toList());
  }
}
