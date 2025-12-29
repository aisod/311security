import 'package:flutter/foundation.dart';
import 'package:security_311_super_admin/models/crime_report.dart';
import 'package:security_311_super_admin/services/crime_report_service.dart';
import 'package:security_311_super_admin/services/offline_service.dart';
import 'package:security_311_super_admin/core/logger.dart';

/// Crime reports state provider with offline support
///
/// Manages crime reports state, offline submission queue, and caching
class CrimeReportsProvider extends ChangeNotifier {
  final CrimeReportService _reportService = CrimeReportService();
  final OfflineService _offlineService = OfflineService();

  // Private state
  List<CrimeReport> _reports = [];
  List<CrimeReport> _filteredReports = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  String? _selectedStatus;
  String? _selectedType;
  bool _isInitialized = false;

  // Cache keys
  static const String _reportsCacheKey = 'crime_reports';
  static const String _userReportsCacheKey = 'user_crime_reports';

  // Public getters
  List<CrimeReport> get reports => _filteredReports;
  List<CrimeReport> get allReports => _reports;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  String? get selectedStatus => _selectedStatus;
  String? get selectedType => _selectedType;
  bool get isInitialized => _isInitialized;
  bool get hasReports => _reports.isNotEmpty;
  int get reportsCount => _reports.length;
  int get pendingOperationsCount => _offlineService.pendingOperationsCount;

  /// Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    AppLogger.info('Initializing CrimeReportsProvider...');

    try {
      // Ensure offline service is initialized
      if (!_offlineService.isInitialized) {
        await _offlineService.initialize();
      }

      // Load cached reports first for immediate display
      await _loadCachedReports();

      // Then fetch fresh data if online
      if (await _offlineService.isOnline) {
        await loadUserReports();
      } else {
        AppLogger.info('Offline mode: Using cached reports');
      }

      _isInitialized = true;
      AppLogger.info('CrimeReportsProvider initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to initialize CrimeReportsProvider', e, stackTrace);
      _setError('Failed to initialize reports');
    }
  }

  /// Load user's crime reports with caching
  Future<void> loadUserReports() async {
    AppLogger.info('Loading user crime reports...');

    _setLoading(true);
    _clearError();

    try {
      List<CrimeReport> reports;

      if (await _offlineService.isOnline) {
        // Fetch from server
        reports = await _reportService.getUserCrimeReports();

        // Cache the results
        await _cacheReports(reports, isUserReports: true);

        AppLogger.info('Loaded ${reports.length} user reports from server');
      } else {
        // Load from cache
        reports = await _loadCachedReports(isUserReports: true) ?? [];
        AppLogger.info(
            'Loaded ${reports.length} user reports from cache (offline)');
      }

      _reports = reports;
      _applyFilters();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load user reports', e, stackTrace);
      _setError('Failed to load reports');

      // Try to load from cache as fallback
      final cachedReports = await _loadCachedReports(isUserReports: true);
      if (cachedReports != null && cachedReports.isNotEmpty) {
        _reports = cachedReports;
        _applyFilters();
        AppLogger.info(
            'Loaded ${cachedReports.length} reports from cache as fallback');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Submit a crime report (with offline support)
  Future<bool> submitReport({
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
    AppLogger.info('Submitting crime report: $title');

    _setSubmitting(true);
    _clearError();

    try {
      final reportData = {
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
      };

      if (await _offlineService.isOnline) {
        // Submit directly to server
        final report = await _reportService.createCrimeReport(
          crimeType: crimeType,
          title: title,
          description: description,
          region: region,
          city: city,
          latitude: latitude,
          longitude: longitude,
          locationDescription: locationDescription,
          incidentDate: incidentDate,
          severity: severity,
          evidenceUrls: evidenceUrls,
          isAnonymous: isAnonymous,
        );

        if (report != null) {
          // Add to local list
          _reports.insert(0, report);
          _applyFilters();

          // Update cache
          await _cacheReports(_reports, isUserReports: true);

          AppLogger.info('Crime report submitted successfully');
          return true;
        } else {
          _setError('Failed to submit report');
          return false;
        }
      } else {
        // Queue for offline submission
        final operation = OfflineOperation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: OfflineOperationType.createCrimeReport,
          data: reportData,
          timestamp: DateTime.now(),
        );

        await _offlineService.queueOperation(operation);

        // Create a temporary local report for immediate feedback
        final tempReport = CrimeReport(
          id: 'temp_${operation.id}',
          userId: 'current_user', // This should be actual user ID
          crimeType: crimeType,
          title: title,
          description: description,
          region: region,
          city: city,
          latitude: latitude,
          longitude: longitude,
          locationDescription: locationDescription,
          incidentDate: incidentDate,
          severity: severity,
          status: 'pending', // Will be updated when synced
          evidenceUrls: evidenceUrls ?? [],
          isAnonymous: isAnonymous,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Add to local list
        _reports.insert(0, tempReport);
        _applyFilters();

        AppLogger.info('Crime report queued for offline submission');
        return true;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to submit crime report', e, stackTrace);
      _setError('Failed to submit report');
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  /// Update a crime report
  Future<bool> updateReport(
    String reportId, {
    String? title,
    String? description,
    String? severity,
    List<String>? evidenceUrls,
  }) async {
    AppLogger.info('Updating crime report: $reportId');

    _setLoading(true);
    _clearError();

    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (severity != null) updateData['severity'] = severity;
      if (evidenceUrls != null) updateData['evidence_urls'] = evidenceUrls;

      if (await _offlineService.isOnline) {
        // Update on server
        final updatedReport = await _reportService.updateCrimeReport(
          reportId,
          title: title,
          description: description,
          evidenceUrls: evidenceUrls,
        );

        if (updatedReport != null) {
          // Update local list
          final index = _reports.indexWhere((r) => r.id == reportId);
          if (index != -1) {
            _reports[index] = updatedReport;
            _applyFilters();

            // Update cache
            await _cacheReports(_reports, isUserReports: true);
          }

          AppLogger.info('Crime report updated successfully');
          return true;
        } else {
          _setError('Failed to update report');
          return false;
        }
      } else {
        // Queue for offline update
        final operation = OfflineOperation(
          id: '${reportId}_update_${DateTime.now().millisecondsSinceEpoch}',
          type: OfflineOperationType.updateCrimeReport,
          data: {'report_id': reportId, ...updateData},
          timestamp: DateTime.now(),
        );

        await _offlineService.queueOperation(operation);

        // Update local copy immediately for user feedback
        final index = _reports.indexWhere((r) => r.id == reportId);
        if (index != -1) {
          final currentReport = _reports[index];
          final updatedReport = CrimeReport(
            id: currentReport.id,
            userId: currentReport.userId,
            crimeType: currentReport.crimeType,
            title: title ?? currentReport.title,
            description: description ?? currentReport.description,
            region: currentReport.region,
            city: currentReport.city,
            latitude: currentReport.latitude,
            longitude: currentReport.longitude,
            locationDescription: currentReport.locationDescription,
            incidentDate: currentReport.incidentDate,
            severity: severity ?? currentReport.severity,
            status: currentReport.status,
            evidenceUrls: evidenceUrls ?? currentReport.evidenceUrls,
            isAnonymous: currentReport.isAnonymous,
            assignedOfficer: currentReport.assignedOfficer,
            resolutionNotes: currentReport.resolutionNotes,
            createdAt: currentReport.createdAt,
            updatedAt: DateTime.now(),
          );

          _reports[index] = updatedReport;
          _applyFilters();
        }

        AppLogger.info('Crime report update queued for offline submission');
        return true;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update crime report', e, stackTrace);
      _setError('Failed to update report');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Filter reports by status
  void filterByStatus(String? status) {
    _selectedStatus = status;
    _applyFilters();
    AppLogger.info('Filtered reports by status: $status');
  }

  /// Filter reports by type
  void filterByType(String? type) {
    _selectedType = type;
    _applyFilters();
    AppLogger.info('Filtered reports by type: $type');
  }

  /// Clear all filters
  void clearFilters() {
    _selectedStatus = null;
    _selectedType = null;
    _applyFilters();
    AppLogger.info('Cleared all report filters');
  }

  /// Refresh reports
  Future<void> refresh() async {
    await loadUserReports();
  }

  /// Get report by ID
  CrimeReport? getReportById(String reportId) {
    try {
      return _reports.firstWhere((report) => report.id == reportId);
    } catch (e) {
      return null;
    }
  }

  /// Get reports by status
  List<CrimeReport> getReportsByStatus(String status) {
    return _reports.where((report) => report.status == status).toList();
  }

  /// Get pending reports
  List<CrimeReport> get pendingReports {
    return getReportsByStatus('pending');
  }

  /// Sync pending operations
  Future<void> syncPendingOperations() async {
    await _offlineService.syncPendingOperations();
    // Refresh reports after sync
    if (await _offlineService.isOnline) {
      await loadUserReports();
    }
  }

  /// Cache reports
  Future<void> _cacheReports(List<CrimeReport> reports,
      {bool isUserReports = false}) async {
    try {
      final reportsData = reports.map((report) => report.toJson()).toList();

      final cacheKey = isUserReports ? _userReportsCacheKey : _reportsCacheKey;
      await _offlineService.cacheData(cacheKey, {
        'reports': reportsData,
        'isUserReports': isUserReports,
      });

      AppLogger.debug('Cached ${reports.length} reports');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache reports', e, stackTrace);
    }
  }

  /// Load cached reports
  Future<List<CrimeReport>?> _loadCachedReports(
      {bool isUserReports = false}) async {
    try {
      final cacheKey = isUserReports ? _userReportsCacheKey : _reportsCacheKey;
      final cachedData = _offlineService.getCachedData(cacheKey);

      if (cachedData != null && cachedData['reports'] != null) {
        final reportsJson =
            List<Map<String, dynamic>>.from(cachedData['reports']);
        final reports =
            reportsJson.map((json) => CrimeReport.fromJson(json)).toList();

        AppLogger.debug('Loaded ${reports.length} reports from cache');
        return reports;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load cached reports', e, stackTrace);
    }

    return null;
  }

  /// Apply current filters to reports
  void _applyFilters() {
    _filteredReports = _reports.where((report) {
      // Filter by status
      if (_selectedStatus != null && report.status != _selectedStatus) {
        return false;
      }

      // Filter by type
      if (_selectedType != null && report.crimeType != _selectedType) {
        return false;
      }

      return true;
    }).toList();

    // Sort by creation date (newest first)
    _filteredReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set submitting state
  void _setSubmitting(bool submitting) {
    if (_isSubmitting != submitting) {
      _isSubmitting = submitting;
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
    AppLogger.info('Disposing CrimeReportsProvider');
    super.dispose();
  }
}
