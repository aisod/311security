import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:security_311_user/models/danger_zone.dart';
import 'package:security_311_user/services/danger_zone_service.dart';
import 'package:security_311_user/core/logger.dart';

/// Provider for managing danger zones state
class DangerZoneProvider extends ChangeNotifier {
  final DangerZoneService _service = DangerZoneService();
  
  // State
  List<DangerZone> _dangerZones = [];
  List<DangerZone> _userCurrentZones = []; // Zones the user is currently inside
  bool _isLoading = false;
  String? _error;
  
  // User location tracking for zone alerts
  double? _lastCheckedLatitude;
  double? _lastCheckedLongitude;
  DateTime? _lastCheckTime;
  
  // Debounce timer for location checks
  Timer? _checkDebounceTimer;
  static const Duration _checkDebounceDelay = Duration(seconds: 5);
  
  // Callbacks
  Function(DangerZone)? onEnteredDangerZone;
  Function(DangerZone)? onExitedDangerZone;
  
  // Getters
  List<DangerZone> get dangerZones => _dangerZones;
  List<DangerZone> get activeDangerZones => 
      _dangerZones.where((z) => z.isActive).toList();
  List<DangerZone> get userCurrentZones => _userCurrentZones;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasDangerZones => _dangerZones.isNotEmpty;
  bool get isUserInDangerZone => _userCurrentZones.isNotEmpty;
  
  /// Get the highest risk zone the user is in
  DangerZone? get highestRiskZone {
    if (_userCurrentZones.isEmpty) return null;
    
    // Already sorted by risk level in service
    return _userCurrentZones.first;
  }
  
  /// Initialize provider
  Future<void> initialize() async {
    AppLogger.info('Initializing DangerZoneProvider');
    await loadDangerZones();
  }
  
  /// Load all danger zones
  Future<void> loadDangerZones() async {
    _setLoading(true);
    _clearError();
    
    try {
      _dangerZones = await _service.getActiveDangerZones();
      AppLogger.info('Loaded ${_dangerZones.length} danger zones');
    } catch (e, stackTrace) {
      _setError('Failed to load danger zones: $e');
      AppLogger.error('Error loading danger zones', e, stackTrace);
    } finally {
      _setLoading(false);
    }
  }
  
  /// Load danger zones for admin (all, including inactive)
  Future<void> loadAllDangerZones() async {
    _setLoading(true);
    _clearError();
    
    try {
      _dangerZones = await _service.getAllDangerZones();
      AppLogger.info('Loaded ${_dangerZones.length} danger zones (admin)');
    } catch (e, stackTrace) {
      _setError('Failed to load danger zones: $e');
      AppLogger.error('Error loading danger zones', e, stackTrace);
    } finally {
      _setLoading(false);
    }
  }
  
  /// Check if user is in any danger zones and trigger callbacks
  Future<void> checkUserLocation(double latitude, double longitude) async {
    // Debounce rapid location updates
    _checkDebounceTimer?.cancel();
    _checkDebounceTimer = Timer(_checkDebounceDelay, () async {
      await _performLocationCheck(latitude, longitude);
    });
  }
  
  /// Perform immediate location check (bypasses debounce)
  Future<void> checkUserLocationImmediate(double latitude, double longitude) async {
    _checkDebounceTimer?.cancel();
    await _performLocationCheck(latitude, longitude);
  }
  
  Future<void> _performLocationCheck(double latitude, double longitude) async {
    try {
      // Get zones containing the user
      final zonesContainingUser = await _service.checkUserInDangerZones(
        latitude,
        longitude,
      );
      
      // Check for newly entered zones
      for (final zone in zonesContainingUser) {
        final wasInZone = _userCurrentZones.any((z) => z.id == zone.id);
        if (!wasInZone) {
          // User just entered this zone
          AppLogger.info('User entered danger zone: ${zone.name}');
          onEnteredDangerZone?.call(zone);
        }
      }
      
      // Check for exited zones
      for (final zone in _userCurrentZones) {
        final stillInZone = zonesContainingUser.any((z) => z.id == zone.id);
        if (!stillInZone) {
          // User just exited this zone
          AppLogger.info('User exited danger zone: ${zone.name}');
          onExitedDangerZone?.call(zone);
        }
      }
      
      // Update current zones
      _userCurrentZones = zonesContainingUser;
      _lastCheckedLatitude = latitude;
      _lastCheckedLongitude = longitude;
      _lastCheckTime = DateTime.now();
      
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error('Error checking user location against danger zones', e, stackTrace);
    }
  }
  
  /// Get danger zones near a location
  Future<List<DangerZone>> getDangerZonesNearLocation(
    double latitude,
    double longitude, {
    double radiusKm = 5.0,
  }) async {
    return await _service.getDangerZonesNearLocation(
      latitude,
      longitude,
      radiusKm: radiusKm,
    );
  }
  
  /// Create a new danger zone (admin)
  Future<DangerZone?> createDangerZone({
    required String name,
    String? description,
    required String geometryType,
    double? centerLatitude,
    double? centerLongitude,
    double? radiusMeters,
    List<Map<String, double>>? polygonPoints,
    required List<String> crimeTypes,
    required String riskLevel,
    String? warningMessage,
    String? safetyTips,
    List<String>? activeHours,
    bool isAlwaysActive = true,
    String? region,
    String? city,
  }) async {
    try {
      final zone = await _service.createDangerZone(
        name: name,
        description: description,
        geometryType: geometryType,
        centerLatitude: centerLatitude,
        centerLongitude: centerLongitude,
        radiusMeters: radiusMeters,
        polygonPoints: polygonPoints,
        crimeTypes: crimeTypes,
        riskLevel: riskLevel,
        warningMessage: warningMessage,
        safetyTips: safetyTips,
        activeHours: activeHours,
        isAlwaysActive: isAlwaysActive,
        region: region,
        city: city,
      );
      
      if (zone != null) {
        _dangerZones.insert(0, zone);
        notifyListeners();
        AppLogger.info('Created danger zone: ${zone.name}');
      }
      
      return zone;
    } catch (e, stackTrace) {
      AppLogger.error('Error creating danger zone', e, stackTrace);
      return null;
    }
  }
  
  /// Update a danger zone (admin)
  Future<DangerZone?> updateDangerZone(
    String id, {
    String? name,
    String? description,
    String? geometryType,
    double? centerLatitude,
    double? centerLongitude,
    double? radiusMeters,
    List<Map<String, double>>? polygonPoints,
    List<String>? crimeTypes,
    String? riskLevel,
    String? warningMessage,
    String? safetyTips,
    List<String>? activeHours,
    bool? isAlwaysActive,
    String? region,
    String? city,
    bool? isActive,
  }) async {
    try {
      final zone = await _service.updateDangerZone(
        id,
        name: name,
        description: description,
        geometryType: geometryType,
        centerLatitude: centerLatitude,
        centerLongitude: centerLongitude,
        radiusMeters: radiusMeters,
        polygonPoints: polygonPoints,
        crimeTypes: crimeTypes,
        riskLevel: riskLevel,
        warningMessage: warningMessage,
        safetyTips: safetyTips,
        activeHours: activeHours,
        isAlwaysActive: isAlwaysActive,
        region: region,
        city: city,
        isActive: isActive,
      );
      
      if (zone != null) {
        final index = _dangerZones.indexWhere((z) => z.id == id);
        if (index >= 0) {
          _dangerZones[index] = zone;
          notifyListeners();
        }
        AppLogger.info('Updated danger zone: ${zone.name}');
      }
      
      return zone;
    } catch (e, stackTrace) {
      AppLogger.error('Error updating danger zone', e, stackTrace);
      return null;
    }
  }
  
  /// Delete a danger zone (admin)
  Future<bool> deleteDangerZone(String id) async {
    try {
      final success = await _service.deleteDangerZone(id);
      
      if (success) {
        _dangerZones.removeWhere((z) => z.id == id);
        notifyListeners();
        AppLogger.info('Deleted danger zone: $id');
      }
      
      return success;
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting danger zone', e, stackTrace);
      return false;
    }
  }
  
  /// Toggle danger zone status (admin)
  Future<bool> toggleDangerZoneStatus(String id, bool isActive) async {
    try {
      final success = await _service.toggleDangerZoneStatus(id, isActive);
      
      if (success) {
        final index = _dangerZones.indexWhere((z) => z.id == id);
        if (index >= 0) {
          // Reload to get updated zone
          await loadAllDangerZones();
        }
        AppLogger.info('Toggled danger zone $id to ${isActive ? 'active' : 'inactive'}');
      }
      
      return success;
    } catch (e, stackTrace) {
      AppLogger.error('Error toggling danger zone status', e, stackTrace);
      return false;
    }
  }
  
  /// Get statistics about danger zones
  Future<Map<String, dynamic>> getStatistics() async {
    return await _service.getDangerZoneStatistics();
  }
  
  /// Report an incident in a zone (increments count)
  Future<bool> reportIncident(String zoneId) async {
    return await _service.incrementIncidentCount(zoneId);
  }
  
  /// Clear user's current zone status
  void clearUserZoneStatus() {
    _userCurrentZones = [];
    _lastCheckedLatitude = null;
    _lastCheckedLongitude = null;
    _lastCheckTime = null;
    notifyListeners();
  }
  
  // Private helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
  }
  
  @override
  void dispose() {
    _checkDebounceTimer?.cancel();
    super.dispose();
  }
}





