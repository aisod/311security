import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:security_311_user/services/location_service.dart';
import 'package:security_311_user/services/user_location_service.dart';
import 'package:security_311_user/core/logger.dart';

/// Provider for managing location state and operations
class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final UserLocationService _userLocationService = UserLocationService();

  LocationData? _currentLocation;
  bool _isLoadingLocation = false;
  String? _locationError;
  List<LocationData> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;

  // Getters
  LocationData? get currentLocation => _currentLocation;
  bool get isLoadingLocation => _isLoadingLocation;
  String? get locationError => _locationError;
  List<LocationData> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;
  bool get hasLocation => _currentLocation != null;
  bool get hasCachedLocation => _locationService.hasCachedLocation;

  /// Initialize the location provider
  Future<void> initialize() async {
    AppLogger.info('Initializing LocationProvider');

    // Try to get cached location if available
    if (_locationService.lastKnownLocation != null) {
      _currentLocation = _locationService.lastKnownLocation;
      notifyListeners();
      AppLogger.info('Loaded cached location');
    }
  }

  /// Get current location with automatic address lookup
  Future<void> getCurrentLocation({bool forceRefresh = false}) async {
    if (_isLoadingLocation) return;

    AppLogger.info('Getting current location...');
    _setLoadingLocation(true);
    _clearLocationError();

    try {
      final location = await _locationService.getCurrentLocation(
        forceRefresh: forceRefresh,
      );

      if (location != null) {
        _currentLocation = location;
        AppLogger.info(
            'Current location obtained: ${location.formattedAddress}');
        unawaited(_syncLocation(location));
      } else {
        _setLocationError(
            'Unable to get current location. Please check your location permissions.');
      }
    } on LocationServiceException catch (e) {
      _setLocationError(e.message);
      AppLogger.error('Location service error: ${e.message}');
    } catch (e) {
      _setLocationError('Failed to get location: ${e.toString()}');
      AppLogger.error('Unexpected location error: $e');
    } finally {
      _setLoadingLocation(false);
    }
  }

  /// Search for addresses
  Future<void> searchAddresses(String query) async {
    if (_isSearching) return;

    AppLogger.info('Searching addresses for: $query');
    _setSearching(true);
    _clearSearchError();

    try {
      if (query.trim().isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = await _locationService.searchAddresses(query);
        AppLogger.info('Found ${_searchResults.length} address results');
      }
    } on LocationServiceException catch (e) {
      _setSearchError(e.message);
      AppLogger.error('Address search error: ${e.message}');
    } catch (e) {
      _setSearchError('Failed to search addresses: ${e.toString()}');
      AppLogger.error('Unexpected search error: $e');
    } finally {
      _setSearching(false);
    }
  }

  /// Select a location from search results or set manually
  void selectLocation(LocationData location) {
    _currentLocation = location;
    _clearLocationError();
    notifyListeners();
    AppLogger.info('Location selected: ${location.formattedAddress}');
  }

  /// Clear search results
  void clearSearchResults() {
    _searchResults = [];
    _clearSearchError();
    notifyListeners();
  }

  /// Clear current location
  void clearLocation() {
    _currentLocation = null;
    _clearLocationError();
    notifyListeners();
    AppLogger.info('Location cleared');
  }

  /// Get distance between current location and another point
  double? getDistanceToLocation(double latitude, double longitude) {
    if (_currentLocation == null) return null;

    return _locationService.getDistanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      latitude,
      longitude,
    );
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await _locationService.isLocationServiceEnabled();
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }

  /// Refresh location cache
  Future<void> refreshLocation() async {
    await getCurrentLocation(forceRefresh: true);
  }

  /// Clear location cache
  void clearCache() {
    _locationService.clearCache();
    _currentLocation = null;
    _clearLocationError();
    notifyListeners();
    AppLogger.info('Location cache cleared');
  }

  Future<void> _syncLocation(LocationData location) async {
    try {
      await _userLocationService.syncCurrentUserLocation(location);
    } catch (e, stackTrace) {
      AppLogger.warning('Failed to sync location: $e');
      AppLogger.debug('Location sync stacktrace: $stackTrace');
    }
  }

  // Private helper methods
  void _setLoadingLocation(bool loading) {
    _isLoadingLocation = loading;
    notifyListeners();
  }

  void _setLocationError(String error) {
    _locationError = error;
    notifyListeners();
  }

  void _clearLocationError() {
    _locationError = null;
    notifyListeners();
  }

  void _setSearching(bool searching) {
    _isSearching = searching;
    notifyListeners();
  }

  void _setSearchError(String error) {
    _searchError = error;
    notifyListeners();
  }

  void _clearSearchError() {
    _searchError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    AppLogger.info('LocationProvider disposed');
    super.dispose();
  }
}
