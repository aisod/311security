import 'package:flutter/foundation.dart';
import 'package:security_311_user/core/logger.dart';
import 'package:security_311_user/models/missing_report.dart';
import 'package:security_311_user/services/missing_report_service.dart';

class MissingReportsProvider extends ChangeNotifier {
  final MissingReportService _missingReportService = MissingReportService();

  final List<MissingReport> _approvedReports = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get hasReports => _approvedReports.isNotEmpty;
  List<MissingReport> get approvedReports =>
      List.unmodifiable(_approvedReports);

  Future<void> initialize() async {
    if (_isInitialized) return;
    await loadApprovedReports();
    _isInitialized = true;
  }

  Future<void> loadApprovedReports() async {
    _setLoading(true);
    _clearError();

    try {
      final reports = await _missingReportService.getApprovedMissingReports();
      _approvedReports
        ..clear()
        ..addAll(reports);
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load approved missing reports',
        e,
        stackTrace,
      );
      _errorMessage = 'Unable to load approved reports right now.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  List<MissingReport> reportsForType(MissingReportType type) {
    return _approvedReports
        .where((report) => report.reportType == type)
        .toList(growable: false);
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
  }
}

