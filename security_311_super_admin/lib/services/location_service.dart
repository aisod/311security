import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:security_311_user/constants/app_constants.dart';
import 'package:security_311_user/services/web_location_service.dart' if (dart.library.io) 'package:security_311_user/services/web_location_service_stub.dart';

/// Location data model
class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? region;
  final String? country;
  final String? postalCode;
  final String? street;
  final String? subLocality;
  final double? accuracy;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.region,
    this.country,
    this.postalCode,
    this.street,
    this.subLocality,
    this.accuracy,
  });

  /// Get formatted address string
  String get formattedAddress {
    if (address != null && address!.isNotEmpty) {
      return address!;
    }

    List<String> parts = [];
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (subLocality != null && subLocality!.isNotEmpty) parts.add(subLocality!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (region != null && region!.isNotEmpty) parts.add(region!);
    if (country != null && country!.isNotEmpty) parts.add(country!);

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    // Provide city/region fallback when available
    if (city != null && city!.isNotEmpty) {
      return city!;
    }
    if (region != null && region!.isNotEmpty) {
      return region!;
    }

    // Provide coordinate-based fallback
    return 'Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  /// Get short address (street and city)
  String get shortAddress {
    List<String> parts = [];
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (city != null && city!.isNotEmpty) {
      parts.add(city!);
    } else if (region != null && region!.isNotEmpty) {
      parts.add(region!);
    }

    return parts.isNotEmpty ? parts.join(', ') : formattedAddress;
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'region': region,
      'country': country,
      'postalCode': postalCode,
      'street': street,
      'subLocality': subLocality,
      'accuracy': accuracy,
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      address: json['address'],
      city: json['city'],
      region: json['region'],
      country: json['country'],
      postalCode: json['postalCode'],
      street: json['street'],
      subLocality: json['subLocality'],
      accuracy: json['accuracy']?.toDouble(),
    );
  }
}

/// Service for handling location detection and address lookup
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final Logger _logger = Logger();
  LocationData? _lastKnownLocation;
  DateTime? _lastLocationUpdate;

  /// Cache duration for location data (5 minutes)
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Get current location with address lookup
  Future<LocationData?> getCurrentLocation({
    bool forceRefresh = false,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      _logger.i('Getting current location... (Web: $kIsWeb)');

      // Check if we have cached location data
      if (!forceRefresh &&
          _lastKnownLocation != null &&
          _lastLocationUpdate != null) {
        final timeSinceUpdate = DateTime.now().difference(_lastLocationUpdate!);
        if (timeSinceUpdate < _cacheTimeout) {
          _logger.i('Using cached location data');
          return _lastKnownLocation;
        }
      }

      // Check and request permissions
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        _logger.w('Location permission denied');
        throw LocationServiceException(
            'Location permission denied. Please allow location access in your browser.');
      }

      // Check if location services are enabled (skip on web as it's not reliable)
      if (!kIsWeb) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _logger.w('Location services are disabled');
          throw LocationServiceException(
              'Location services are disabled. Please enable location services in your device settings.');
        }
      }

      // Get current position with web-specific settings
      _logger.i('Fetching GPS coordinates...');
      
      double latitude, longitude, accuracy;
      
      if (kIsWeb) {
        // Use browser's native geolocation API for web
        try {
          final webLocationService = WebLocationService();
          final position = await webLocationService.getCurrentPosition(timeout: timeout);
          latitude = position['latitude']!;
          longitude = position['longitude']!;
          accuracy = position['accuracy']!;
          _logger.i('Web location obtained: $latitude, $longitude');
        } catch (e) {
          _logger.e('Web location failed, trying Geolocator fallback: $e');
          // Fallback to Geolocator if web service fails
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          ).timeout(
            timeout,
            onTimeout: () {
              throw LocationServiceException(
                  'Location request timed out. Please check your browser permissions and try again.');
            },
          );
          latitude = position.latitude;
          longitude = position.longitude;
          accuracy = position.accuracy;
        }
      } else {
        // Mobile location settings
        final position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: timeout,
          ),
        );
        latitude = position.latitude;
        longitude = position.longitude;
        accuracy = position.accuracy;
      }

      _logger.i('GPS coordinates obtained: $latitude, $longitude');

      // Get address from coordinates
      final locationData = await _getAddressFromCoordinates(
        latitude,
        longitude,
        accuracy: accuracy,
      );

      // Cache the result
      _lastKnownLocation = locationData;
      _lastLocationUpdate = DateTime.now();

      _logger.i(
          'Location obtained successfully: ${locationData.formattedAddress}');
      return locationData;
    } catch (e) {
      _logger.e('Error getting current location: $e');
      _logger.e('Error type: ${e.runtimeType}');
      
      if (e is LocationServiceException) {
        rethrow;
      }
      
      // Provide more specific error messages
      if (e.toString().contains('NotInitializedError')) {
        throw LocationServiceException(
            'Location services not initialized. Please refresh the page and allow location access.');
      } else if (e.toString().contains('PermissionDenied')) {
        throw LocationServiceException(
            'Location permission denied. Please allow location access in your browser settings.');
      } else if (e.toString().contains('timeout')) {
        throw LocationServiceException(
            'Location request timed out. Please try again.');
      }
      
      throw LocationServiceException(
          'Failed to get current location: ${e.toString()}');
    }
  }

  /// Get address from coordinates (reverse geocoding)
  Future<LocationData> _getAddressFromCoordinates(
    double latitude,
    double longitude, {
    double? accuracy,
  }) async {
    // Try Google Geocoding API first for higher accuracy (especially on web)
    final googleResult =
        await _fetchGoogleGeocode(latitude, longitude, accuracy: accuracy);
    if (googleResult != null) {
      return googleResult;
    }

    try {
      _logger.i('Performing reverse geocoding for: $latitude, $longitude');

      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 10));

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        _logger.i('Address found: ${placemark.toString()}');

        // Build a more comprehensive address
        String? street = placemark.street;
        String? locality =
            placemark.locality ?? placemark.subAdministrativeArea;
        String? region = placemark.administrativeArea;
        String? country = placemark.country;

        return LocationData(
          latitude: latitude,
          longitude: longitude,
          address: _buildFullAddress(placemark),
          city: locality,
          region: region,
          country: country,
          postalCode: placemark.postalCode,
          street: street,
          subLocality: placemark.subLocality,
          accuracy: accuracy,
        );
      } else {
        _logger.w('No address found for coordinates, using fallback');
        return LocationData(
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
        );
      }
    } catch (e) {
      _logger.e('Error in reverse geocoding: $e');
      // Return location data with coordinate fallback if geocoding fails
      return LocationData(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
      );
    }
  }

  Future<LocationData?> _fetchGoogleGeocode(
    double latitude,
    double longitude, {
    double? accuracy,
  }) async {
    final apiKey = AppConstants.googleMapsApiKey;
    if (apiKey.isEmpty) {
      _logger.w(
          'Google Maps API key not configured; skipping Google reverse geocoding');
      return null;
    }

    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '$latitude,$longitude',
      'key': apiKey,
    });

    try {
      _logger.i('Calling Google Geocoding API: $uri');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        _logger.w(
            'Google Geocoding API returned ${response.statusCode}: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;
      if (status != 'OK') {
        _logger
            .w('Google Geocoding API status $status: ${data['error_message']}');
        return null;
      }

      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        _logger.w('Google Geocoding API returned no results');
        return null;
      }

      final result = results.first as Map<String, dynamic>;
      final formattedAddress = result['formatted_address'] as String?;
      final components = result['address_components'] as List<dynamic>?;

      String? street;
      String? subLocality;
      String? city;
      String? region;
      String? country;
      String? postalCode;
      String? streetNumber;
      String? route;

      if (components != null) {
        for (final component in components) {
          final Map<String, dynamic> comp = component as Map<String, dynamic>;
          final types = List<String>.from(comp['types'] as List<dynamic>);
          final longName = comp['long_name'] as String?;

          if (longName == null || longName.isEmpty) {
            continue;
          }

          if (types.contains('street_number')) {
            streetNumber = longName;
          } else if (types.contains('route')) {
            route = longName;
          } else if (types.contains('sublocality') ||
              types.contains('sublocality_level_1') ||
              types.contains('neighborhood')) {
            subLocality ??= longName;
          } else if (types.contains('locality') ||
              types.contains('postal_town')) {
            city ??= longName;
          } else if (types.contains('administrative_area_level_2')) {
            // Use district as city fallback when locality missing
            city ??= longName;
          } else if (types.contains('administrative_area_level_1')) {
            region ??= longName;
          } else if (types.contains('country')) {
            country ??= longName;
          } else if (types.contains('postal_code')) {
            postalCode ??= longName;
          }
        }
      }

      if (streetNumber != null || route != null) {
        final combined = [streetNumber, route]
            .where((value) => value != null && value.trim().isNotEmpty)
            .join(' ');
        if (combined.isNotEmpty) {
          street = combined;
        }
      }

      return LocationData(
        latitude: latitude,
        longitude: longitude,
        address: formattedAddress,
        city: city,
        region: region,
        country: country,
        postalCode: postalCode,
        street: street,
        subLocality: subLocality,
        accuracy: accuracy,
      );
    } catch (e) {
      _logger.w('Google Geocoding lookup failed: $e');
      return null;
    }
  }

  /// Search for addresses based on query
  Future<List<LocationData>> searchAddresses(String query) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      _logger.i('Searching for addresses: $query');

      // On web or if Google API is available, use Google Places/Geocoding API
      final apiKey = AppConstants.googleMapsApiKey;
      if (apiKey.isNotEmpty && (kIsWeb || true)) {
        // Try Google Geocoding API first
        final googleResults = await _searchWithGoogleGeocoding(query);
        if (googleResults.isNotEmpty) {
          return googleResults;
        }
      }

      // Fallback to native geocoding
      // Add timeout and better error handling
      List<Location> locations = await locationFromAddress(query)
          .timeout(const Duration(seconds: 15))
          .catchError((error) {
        _logger.e('Geocoding service error: $error');
        return <Location>[]; // Return empty list on error
      });

      _logger.i('Raw locations found: ${locations.length}');

      if (locations.isEmpty) {
        _logger.w('No locations found for query: $query');

        // Try to provide some fallback results for common Namibian places
        if (query.toLowerCase().contains('windhoek')) {
          return [
            LocationData(
              latitude: -22.5609,
              longitude: 17.0658,
              city: 'Windhoek',
              region: 'Khomas Region',
              country: 'Namibia',
              address: 'Windhoek, Khomas Region, Namibia',
            ),
          ];
        }

        return [];
      }

      List<LocationData> results = [];

      for (Location location in locations.take(5)) {
        // Limit to 5 results
        try {
          final locationData = await _getAddressFromCoordinates(
            location.latitude,
            location.longitude,
          );
          results.add(locationData);
        } catch (e) {
          _logger.w('Error getting address for location: $e');
          // Add location with basic info if geocoding fails
          results.add(LocationData(
            latitude: location.latitude,
            longitude: location.longitude,
            address: query, // Use the search query as address
          ));
        }
      }

      _logger.i('Found ${results.length} address results');
      return results;
    } catch (e) {
      _logger.e('Error searching addresses: $e');
      _logger.e('Error type: ${e.runtimeType}');
      _logger.e('Error details: ${e.toString()}');

      // Provide more specific error messages
      if (e.toString().contains('timeout')) {
        throw LocationServiceException(
            'Address search timed out. Please check your internet connection.');
      } else if (e.toString().contains('network')) {
        throw LocationServiceException(
            'Network error during address search. Please check your internet connection.');
      } else if (e.toString().contains('PlatformException')) {
        throw LocationServiceException(
            'Location service unavailable. Please try again later.');
      } else {
        throw LocationServiceException(
            'Failed to search addresses. Please try a different search term.');
      }
    }
  }

  /// Search addresses using Google Geocoding API
  Future<List<LocationData>> _searchWithGoogleGeocoding(String query) async {
    final apiKey = AppConstants.googleMapsApiKey;
    if (apiKey.isEmpty) {
      return [];
    }

    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'address': query,
      'key': apiKey,
    });

    try {
      _logger.i('Searching with Google Geocoding API: $query');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        _logger.w('Google Geocoding API returned ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;
      
      if (status != 'OK') {
        _logger.w('Google Geocoding API status: $status');
        return [];
      }

      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        return [];
      }

      List<LocationData> locationResults = [];
      
      for (final result in results.take(5)) {
        final Map<String, dynamic> resultMap = result as Map<String, dynamic>;
        final geometry = resultMap['geometry'] as Map<String, dynamic>?;
        final location = geometry?['location'] as Map<String, dynamic>?;
        
        if (location == null) continue;
        
        final lat = location['lat'] as num?;
        final lng = location['lng'] as num?;
        
        if (lat == null || lng == null) continue;
        
        final formattedAddress = resultMap['formatted_address'] as String?;
        final components = resultMap['address_components'] as List<dynamic>?;

        String? street;
        String? subLocality;
        String? city;
        String? region;
        String? country;
        String? postalCode;

        if (components != null) {
          for (final component in components) {
            final Map<String, dynamic> comp = component as Map<String, dynamic>;
            final types = List<String>.from(comp['types'] as List<dynamic>);
            final longName = comp['long_name'] as String?;

            if (longName == null || longName.isEmpty) continue;

            if (types.contains('route')) {
              street ??= longName;
            } else if (types.contains('sublocality') || types.contains('neighborhood')) {
              subLocality ??= longName;
            } else if (types.contains('locality')) {
              city ??= longName;
            } else if (types.contains('administrative_area_level_1')) {
              region ??= longName;
            } else if (types.contains('country')) {
              country ??= longName;
            } else if (types.contains('postal_code')) {
              postalCode ??= longName;
            }
          }
        }

        locationResults.add(LocationData(
          latitude: lat.toDouble(),
          longitude: lng.toDouble(),
          address: formattedAddress,
          city: city,
          region: region,
          country: country,
          postalCode: postalCode,
          street: street,
          subLocality: subLocality,
        ));
      }

      _logger.i('Found ${locationResults.length} results from Google Geocoding API');
      return locationResults;
    } catch (e) {
      _logger.w('Google Geocoding search failed: $e');
      return [];
    }
  }

  /// Check and request location permissions
  Future<bool> _checkLocationPermission() async {
    try {
      // On web, use Geolocator's permission system
      if (kIsWeb) {
        LocationPermission permission = await Geolocator.checkPermission();
        
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        
        if (permission == LocationPermission.deniedForever) {
          _logger.w('Location permission permanently denied on web');
          return false;
        }
        
        return permission == LocationPermission.whileInUse || 
               permission == LocationPermission.always;
      }
      
      // On mobile, use permission_handler
      PermissionStatus permission = await Permission.location.status;

      if (permission.isGranted) {
        return true;
      }

      if (permission.isDenied) {
        // Request permission
        permission = await Permission.location.request();
        return permission.isGranted;
      }

      if (permission.isPermanentlyDenied) {
        // Open app settings
        _logger.w('Location permission permanently denied');
        return false;
      }

      return false;
    } catch (e) {
      _logger.e('Error checking location permission: $e');
      return false;
    }
  }

  /// Build full address string from placemark
  String _buildFullAddress(Placemark placemark) {
    List<String> parts = [];

    if (placemark.street != null && placemark.street!.isNotEmpty) {
      parts.add(placemark.street!);
    }

    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      parts.add(placemark.subLocality!);
    }

    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    } else if (placemark.subAdministrativeArea != null &&
        placemark.subAdministrativeArea!.isNotEmpty) {
      parts.add(placemark.subAdministrativeArea!);
    }

    if (placemark.administrativeArea != null &&
        placemark.administrativeArea!.isNotEmpty) {
      parts.add(placemark.administrativeArea!);
    }

    if (placemark.country != null && placemark.country!.isNotEmpty) {
      parts.add(placemark.country!);
    }

    String result = parts.join(', ');

    // If we still have an empty result, provide a fallback
    if (result.isEmpty) {
      if (placemark.name != null && placemark.name!.isNotEmpty) {
        result = placemark.name!;
      } else {
        result = 'Location Found';
      }
    }

    return result;
  }

  /// Get distance between two locations in kilometers
  double getDistanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
        ) /
        1000; // Convert to kilometers
  }

  /// Check if location services are available
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings for permissions
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Clear cached location data
  void clearCache() {
    _lastKnownLocation = null;
    _lastLocationUpdate = null;
    _logger.i('Location cache cleared');
  }

  /// Get last known location (cached)
  LocationData? get lastKnownLocation => _lastKnownLocation;

  /// Check if location data is cached and valid
  bool get hasCachedLocation {
    if (_lastKnownLocation == null || _lastLocationUpdate == null) {
      return false;
    }

    final timeSinceUpdate = DateTime.now().difference(_lastLocationUpdate!);
    return timeSinceUpdate < _cacheTimeout;
  }
}

/// Custom exception for location service errors
class LocationServiceException implements Exception {
  final String message;

  LocationServiceException(this.message);

  @override
  String toString() => 'LocationServiceException: $message';
}
