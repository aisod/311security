import 'dart:async';
import 'dart:js_interop';

import 'package:logger/logger.dart';
import 'package:web/web.dart' as web;

/// Web-specific location service using the browser's Geolocation API
class WebLocationService {
  final Logger _logger = Logger();

  /// Get current position using browser's geolocation API
  Future<Map<String, double>> getCurrentPosition({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      _logger.i('WebLocationService: Requesting location from browser...');
      
      final geolocation = web.window.navigator.geolocation;

      final position = await _getPosition(geolocation, timeout);
        final coords = position.coords;
        
      _logger.i(
        'WebLocationService: Got position - ${coords.latitude}, ${coords.longitude}',
      );
        
        return {
        'latitude': coords.latitude,
        'longitude': coords.longitude,
        'accuracy': coords.accuracy,
        };
    } on web.GeolocationPositionError catch (error) {
        _logger.e('WebLocationService: Error - ${error.message}');
      throw Exception(_resolveErrorMessage(error));
    } catch (e) {
      _logger.e('WebLocationService: Exception - $e');
      rethrow;
    }
  }

  Future<web.GeolocationPosition> _getPosition(
    web.Geolocation geolocation,
    Duration timeout,
  ) {
    final completer = Completer<web.GeolocationPosition>();

    void handleSuccess(web.GeolocationPosition position) {
      if (!completer.isCompleted) {
        completer.complete(position);
      }
    }

    void handleError(web.GeolocationPositionError error) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }

    geolocation.getCurrentPosition(
      handleSuccess.toJS,
      handleError.toJS,
      web.PositionOptions(
        enableHighAccuracy: true,
        timeout: timeout.inMilliseconds,
        maximumAge: 0,
      ),
    );

    return completer.future.timeout(timeout);
  }

  String _resolveErrorMessage(web.GeolocationPositionError error) {
    switch (error.code) {
      case web.GeolocationPositionError.PERMISSION_DENIED:
        return 'Location permission denied. Please allow location access in your browser.';
      case web.GeolocationPositionError.POSITION_UNAVAILABLE:
        return 'Location information unavailable. Please check your connection.';
      case web.GeolocationPositionError.TIMEOUT:
        return 'Location request timed out. Please try again.';
      default:
        return 'Failed to get location: ${error.message}';
    }
  }

  /// Check if geolocation is supported
  bool isSupported() {
    try {
      web.window.navigator.geolocation;
      return true;
    } catch (_) {
      return false;
  }
}
}