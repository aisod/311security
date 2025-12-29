import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:security_311_user/models/alert.dart';
import 'package:security_311_user/services/safety_alert_service.dart';
import 'package:security_311_user/services/offline_service.dart';
import 'package:security_311_user/core/logger.dart';

/// Safety alerts state provider with offline support
///
/// Manages safety alerts state, caching, and offline operations
class SafetyAlertsProvider extends ChangeNotifier {
  final SafetyAlertService _alertService = SafetyAlertService();
  final OfflineService _offlineService = OfflineService();

  // Private state
  List<SafetyAlert> _alerts = [];
  List<SafetyAlert> _filteredAlerts = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedRegion;
  String? _selectedType;
  bool _isInitialized = false;

  // Cache keys
  static const String _alertsCacheKey = 'safety_alerts';
  static const String _regionAlertsCacheKey = 'region_alerts_';

  // Public getters
  List<SafetyAlert> get alerts => _filteredAlerts;
  List<SafetyAlert> get allAlerts => _alerts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedRegion => _selectedRegion;
  String? get selectedType => _selectedType;
  bool get isInitialized => _isInitialized;
  bool get hasAlerts => _alerts.isNotEmpty;
  int get alertsCount => _alerts.length;

  /// Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    AppLogger.info('Initializing SafetyAlertsProvider...');

    try {
      // Ensure offline service is initialized
      if (!_offlineService.isInitialized) {
        await _offlineService.initialize();
      }

      // Load cached alerts first for immediate display
      await _loadCachedAlerts();

      // Then fetch fresh data if online
      if (await _offlineService.isOnline) {
        await loadAlerts();
      } else {
        AppLogger.info('Offline mode: Using cached alerts');
      }

      _isInitialized = true;
      AppLogger.info('SafetyAlertsProvider initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to initialize SafetyAlertsProvider', e, stackTrace);
      _setError('Failed to initialize alerts');
    }
  }

  /// Load alerts from server with caching
  Future<void> loadAlerts({
    String? region,
    String? city,
    int limit = 50,
  }) async {
    AppLogger.info('Loading safety alerts...');

    _setLoading(true);
    _clearError();

    try {
      List<SafetyAlert> alerts;

      if (await _offlineService.isOnline) {
        // Fetch from server
        alerts = await _alertService.getActiveAlerts(
          region: region,
          city: city,
          limit: limit,
        );

        // Cache the results
        await _cacheAlerts(alerts, region: region);

        AppLogger.info('Loaded ${alerts.length} alerts from server');
      } else {
        // Load from cache
        alerts = await _loadCachedAlerts(region: region) ?? [];
        AppLogger.info('Loaded ${alerts.length} alerts from cache (offline)');
      }

      _alerts = alerts;
      _applyFilters();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load alerts', e, stackTrace);
      _setError('Failed to load alerts');

      // Try to load from cache as fallback
      final cachedAlerts = await _loadCachedAlerts(region: region);
      if (cachedAlerts != null && cachedAlerts.isNotEmpty) {
        _alerts = cachedAlerts;
        _applyFilters();
        AppLogger.info(
            'Loaded ${cachedAlerts.length} alerts from cache as fallback');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Get alerts by type with caching
  Future<void> loadAlertsByType(String type, {int limit = 20}) async {
    AppLogger.info('Loading alerts by type: $type');

    _setLoading(true);
    _clearError();

    try {
      List<SafetyAlert> alerts;

      if (await _offlineService.isOnline) {
        alerts = await _alertService.getAlertsByType(type, limit: limit);

        // Cache the results
        await _cacheAlerts(alerts, type: type);

        AppLogger.info(
            'Loaded ${alerts.length} alerts of type $type from server');
      } else {
        // Load from cache
        alerts = await _loadCachedAlerts(type: type) ?? [];
        AppLogger.info(
            'Loaded ${alerts.length} alerts of type $type from cache (offline)');
      }

      _alerts = alerts;
      _applyFilters();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load alerts by type', e, stackTrace);
      _setError('Failed to load alerts');
    } finally {
      _setLoading(false);
    }
  }

  /// Get alerts near location with caching
  Future<void> loadAlertsNearLocation(
    double latitude,
    double longitude,
    double radiusKm, {
    int limit = 20,
  }) async {
    AppLogger.info('Loading alerts near location: $latitude, $longitude');

    _setLoading(true);
    _clearError();

    try {
      List<SafetyAlert> alerts;

      if (await _offlineService.isOnline) {
        alerts = await _alertService.getAlertsNearLocation(
          latitude,
          longitude,
          radiusKm,
          limit: limit,
        );

        // Cache the results
        final locationKey =
            '${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}';
        await _cacheAlerts(alerts, location: locationKey);

        AppLogger.info(
            'Loaded ${alerts.length} alerts near location from server');
      } else {
        // For offline mode, we can't do precise location filtering
        // So we load all cached alerts and filter client-side
        alerts = await _loadCachedAlerts() ?? [];

        // Filter by distance client-side
        alerts = alerts
            .where((alert) {
              if (alert.latitude == null || alert.longitude == null) {
                return false;
              }

              final distance = _calculateDistance(
                latitude,
                longitude,
                alert.latitude!,
                alert.longitude!,
              );

              return distance <= radiusKm;
            })
            .take(limit)
            .toList();

        AppLogger.info(
            'Loaded ${alerts.length} alerts near location from cache (offline)');
      }

      _alerts = alerts;
      _applyFilters();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load alerts near location', e, stackTrace);
      _setError('Failed to load alerts');
    } finally {
      _setLoading(false);
    }
  }

  /// Filter alerts by region
  void filterByRegion(String? region) {
    _selectedRegion = region;
    _applyFilters();
    AppLogger.info('Filtered alerts by region: $region');
  }

  /// Filter alerts by type
  void filterByType(String? type) {
    _selectedType = type;
    _applyFilters();
    AppLogger.info('Filtered alerts by type: $type');
  }

  /// Clear all filters
  void clearFilters() {
    _selectedRegion = null;
    _selectedType = null;
    _applyFilters();
    AppLogger.info('Cleared all alert filters');
  }

  /// Refresh alerts
  Future<void> refresh() async {
    await loadAlerts(region: _selectedRegion);
  }

  /// Get alert by ID
  SafetyAlert? getAlertById(String alertId) {
    try {
      return _alerts.firstWhere((alert) => alert.id == alertId);
    } catch (e) {
      return null;
    }
  }

  /// Get alerts by severity
  List<SafetyAlert> getAlertsBySeverity(String severity) {
    return _alerts.where((alert) => alert.severity == severity).toList();
  }

  /// Get critical alerts
  List<SafetyAlert> get criticalAlerts {
    return getAlertsBySeverity('critical');
  }

  /// Cache alerts
  Future<void> _cacheAlerts(
    List<SafetyAlert> alerts, {
    String? region,
    String? type,
    String? location,
  }) async {
    try {
      final alertsData = alerts.map((alert) => alert.toJson()).toList();

      // Cache all alerts
      await _offlineService.cacheData(_alertsCacheKey, {
        'alerts': alertsData,
        'region': region,
        'type': type,
        'location': location,
      });

      // Cache by region if specified
      if (region != null) {
        await _offlineService.cacheData('$_regionAlertsCacheKey$region', {
          'alerts': alertsData,
        });
      }

      AppLogger.debug('Cached ${alerts.length} alerts');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache alerts', e, stackTrace);
    }
  }

  /// Load cached alerts
  Future<List<SafetyAlert>?> _loadCachedAlerts({
    String? region,
    String? type,
  }) async {
    try {
      String cacheKey = _alertsCacheKey;

      // Use region-specific cache if available
      if (region != null) {
        final regionCacheKey = '$_regionAlertsCacheKey$region';
        if (_offlineService.isCached(regionCacheKey)) {
          cacheKey = regionCacheKey;
        }
      }

      final cachedData = _offlineService.getCachedData(cacheKey);
      if (cachedData != null && cachedData['alerts'] != null) {
        final alertsJson =
            List<Map<String, dynamic>>.from(cachedData['alerts']);
        final alerts =
            alertsJson.map((json) => SafetyAlert.fromJson(json)).toList();

        AppLogger.debug('Loaded ${alerts.length} alerts from cache');
        return alerts;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load cached alerts', e, stackTrace);
    }

    return null;
  }

  /// Apply current filters to alerts
  void _applyFilters() {
    _filteredAlerts = _alerts.where((alert) {
      // Filter by region
      if (_selectedRegion != null && alert.region != _selectedRegion) {
        return false;
      }

      // Filter by type
      if (_selectedType != null && alert.type != _selectedType) {
        return false;
      }

      return true;
    }).toList();

    // Sort by priority and creation date
    _filteredAlerts.sort((a, b) {
      // First sort by priority
      const priorityOrder = ['critical', 'high', 'medium', 'low'];
      final aPriorityIndex = priorityOrder.indexOf(a.priority);
      final bPriorityIndex = priorityOrder.indexOf(b.priority);

      if (aPriorityIndex != bPriorityIndex) {
        return aPriorityIndex.compareTo(bPriorityIndex);
      }

      // Then by creation date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });

    notifyListeners();
  }

  /// Calculate distance between two points (Haversine formula)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = (lat2 - lat1) * (pi / 180);
    final double dLon = (lon2 - lon1) * (pi / 180);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
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
    AppLogger.info('Disposing SafetyAlertsProvider');
    super.dispose();
  }
}
