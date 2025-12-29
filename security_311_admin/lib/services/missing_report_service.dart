import 'package:security_311_admin/core/logger.dart';
import 'package:security_311_admin/models/missing_report.dart';
import 'package:security_311_admin/services/supabase_service.dart';

class MissingReportService {
  final SupabaseService _supabase = SupabaseService();

  Future<bool> createMissingReport({
    required MissingReportType reportType,
    required String title,
    required String description,
    String? personName,
    int? age,
    String? lastSeenLocation,
    DateTime? lastSeenDate,
    String? contactPhone,
    String? contactEmail,
    List<String>? photoUrls,
  }) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final data = {
        'user_id': user.id,
        'report_type': reportType.value,
        'title': title,
        'description': description,
        'person_name': personName,
        'age': age,
        'last_seen_location': lastSeenLocation,
        'last_seen_date': lastSeenDate?.toIso8601String(),
        'contact_phone': contactPhone,
        'contact_email': contactEmail,
        'photo_urls': photoUrls,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }..removeWhere((key, value) => value == null);

      await _supabase.client.from('missing_reports').insert(data);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create missing report', e, stackTrace);
      return false;
    }
  }

  Future<List<MissingReport>> getUserMissingReports() async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return [];

      final response = await _supabase.client
          .from('missing_reports')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return response
          .map<MissingReport>((json) => MissingReport.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch user missing reports', e, stackTrace);
      return [];
    }
  }

  Future<List<MissingReport>> getAdminMissingReports({
    String? status,
    String? reportType,
  }) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return [];

      var query = _supabase.client.from('missing_reports').select(
          '*, reporter:profiles!missing_reports_user_id_fkey(full_name, phone_number, email)');

      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }
      if (reportType != null && reportType.isNotEmpty) {
        query = query.eq('report_type', reportType);
      }

      final response = await query.order('created_at', ascending: false);
      return response
          .map<MissingReport>((json) => MissingReport.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch admin missing reports', e, stackTrace);
      return [];
    }
  }

  Future<bool> updateMissingReportStatus(
    String reportId,
    MissingReportStatus status, {
    String? adminNotes,
  }) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) {
        throw Exception('Authentication required');
      }

      final updates = {
        'status': status.value,
        'admin_notes': adminNotes,
        'approved_by': status == MissingReportStatus.approved ? user.id : null,
        'published_at': status == MissingReportStatus.approved
            ? DateTime.now().toIso8601String()
            : null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.client
          .from('missing_reports')
          .update(updates)
          .eq('id', reportId);

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update missing report status', e, stackTrace);
      return false;
    }
  }

  Future<List<MissingReport>> getApprovedMissingReports({
    MissingReportType? reportType,
  }) async {
    try {
      var query = _supabase.client
          .from('missing_reports')
          .select()
          .eq('status', MissingReportStatus.approved.value);

      if (reportType != null) {
        query = query.eq('report_type', reportType.value);
      }

      final response = await query
          .order('published_at', ascending: false)
          .order('created_at', ascending: false);

      return response
          .map<MissingReport>((json) => MissingReport.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch approved missing reports', e, stackTrace);
      return [];
    }
  }
}

