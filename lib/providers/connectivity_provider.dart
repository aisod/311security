import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:security_311_user/services/offline_service.dart';
import 'package:security_311_user/core/logger.dart';

/// Connectivity state provider
///
/// Monitors network connectivity and manages offline/online state
class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  final OfflineService _offlineService = OfflineService();

  // Private state
  List<ConnectivityResult> _connectivityResults = [];
  bool _isOnline = false;
  bool _wasOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;

  // Public getters
  List<ConnectivityResult> get connectivityResults => _connectivityResults;
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get hasWifi => _connectivityResults.contains(ConnectivityResult.wifi);
  bool get hasMobile =>
      _connectivityResults.contains(ConnectivityResult.mobile);
  bool get hasEthernet =>
      _connectivityResults.contains(ConnectivityResult.ethernet);
  String get connectionType {
    if (hasWifi) return 'WiFi';
    if (hasMobile) return 'Mobile';
    if (hasEthernet) return 'Ethernet';
    return 'None';
  }

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    AppLogger.info('Initializing ConnectivityProvider...');

    try {
      // Ensure offline service is initialized
      if (!_offlineService.isInitialized) {
        await _offlineService.initialize();
      }

      // Check initial connectivity
      await _checkConnectivity();

      // Start listening to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          AppLogger.error('Connectivity stream error', error);
        },
      );

      AppLogger.info('ConnectivityProvider initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to initialize ConnectivityProvider', e, stackTrace);
    }
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(results);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check connectivity', e, stackTrace);
      _updateConnectivityStatus([ConnectivityResult.none]);
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    AppLogger.info('Connectivity changed: $results');
    _updateConnectivityStatus(results);
  }

  /// Update connectivity status and trigger appropriate actions
  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _connectivityResults = results;

    // Determine if we're online
    _isOnline = results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.ethernet);

    // Handle state changes
    if (!wasOnline && _isOnline) {
      _onConnectionRestored();
    } else if (wasOnline && !_isOnline) {
      _onConnectionLost();
    }

    notifyListeners();
  }

  /// Handle connection restored
  void _onConnectionRestored() {
    AppLogger.info('Internet connection restored');
    _wasOffline = false;

    // Start periodic sync when connection is restored
    _startPeriodicSync();

    // Trigger immediate sync after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      _syncPendingOperations();
    });
  }

  /// Handle connection lost
  void _onConnectionLost() {
    AppLogger.info('Internet connection lost - entering offline mode');
    _wasOffline = true;

    // Stop periodic sync when offline
    _stopPeriodicSync();
  }

  /// Start periodic sync when online
  void _startPeriodicSync() {
    _stopPeriodicSync(); // Stop any existing timer

    if (_isOnline) {
      _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        if (_isOnline) {
          _syncPendingOperations();
        } else {
          timer.cancel();
        }
      });

      AppLogger.info('Started periodic sync (every 5 minutes)');
    }
  }

  /// Stop periodic sync
  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Sync pending operations
  Future<void> _syncPendingOperations() async {
    if (!_isOnline || !_offlineService.isInitialized) return;

    try {
      AppLogger.info('Syncing pending operations...');
      await _offlineService.syncPendingOperations();
      AppLogger.info('Sync completed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sync pending operations', e, stackTrace);
    }
  }

  /// Force sync pending operations
  Future<void> forcSync() async {
    if (_isOnline) {
      await _syncPendingOperations();
    } else {
      AppLogger.warning('Cannot sync: device is offline');
    }
  }

  /// Get pending operations count
  int get pendingOperationsCount {
    if (_offlineService.isInitialized) {
      return _offlineService.pendingOperationsCount;
    }
    return 0;
  }

  /// Check if device was offline and is now online
  bool get wasOfflineAndNowOnline => _wasOffline && _isOnline;

  /// Get connection quality indicator
  String get connectionQuality {
    if (!_isOnline) return 'No Connection';
    if (hasWifi) return 'Excellent';
    if (hasMobile) return 'Good';
    if (hasEthernet) return 'Excellent';
    return 'Unknown';
  }

  /// Get connection icon
  String get connectionIcon {
    if (!_isOnline) return '❌';
    if (hasWifi) return '📶';
    if (hasMobile) return '📱';
    if (hasEthernet) return '🌐';
    return '❓';
  }

  /// Refresh connectivity status
  Future<void> refresh() async {
    await _checkConnectivity();
  }

  @override
  void dispose() {
    AppLogger.info('Disposing ConnectivityProvider');
    _connectivitySubscription?.cancel();
    _stopPeriodicSync();
    super.dispose();
  }
}
