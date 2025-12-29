import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:security_311_super_admin/core/logger.dart';
import 'package:security_311_super_admin/services/supabase_service.dart';
import 'package:security_311_super_admin/models/offline_operation.dart';

// Re-export the model so other files don't break
export 'package:security_311_super_admin/models/offline_operation.dart';

/// Service for managing offline operations and data caching using Hive
///
/// Handles local storage, offline queue management, and automatic sync
/// when connectivity is restored.
class OfflineService {
  static const String _offlineQueueBoxName = 'offline_queue_v2';
  static const String _cacheBoxName = 'cache_v2';
  static const String _settingsBoxName = 'settings_v2';

  static const int maxRetryCount = 3;
  static const Duration retryDelay = Duration(seconds: 30);
  
  final SupabaseService _supabase = SupabaseService();

  // Typed boxes
  late Box<OfflineOperation> _offlineQueue;
  late Box<String> _cache;
  late Box<dynamic> _settings;

  bool _isInitialized = false;
  bool _isSyncing = false;

  // Singleton instance
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  /// Initialize Hive and open boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    AppLogger.info('Initializing OfflineService (Hive)...');

    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Register Adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(OfflineOperationTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(OfflineOperationAdapter());
      }

      // Open boxes
      _offlineQueue = await Hive.openBox<OfflineOperation>(_offlineQueueBoxName);
      _cache = await Hive.openBox<String>(_cacheBoxName);
      _settings = await Hive.openBox<dynamic>(_settingsBoxName);

      _isInitialized = true;
      AppLogger.info('OfflineService initialized successfully');

      // Start connectivity monitoring
      _startConnectivityMonitoring();
      
      // Attempt initial sync if online
      if (await isOnline) {
        _syncPendingOperations();
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize OfflineService', e, stackTrace);
      // Don't rethrow, allow app to run without offline support if needed
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get current connectivity status
  Future<bool> get isOnline async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet);
    } catch (e) {
      AppLogger.warning('Failed to check connectivity', e);
      return false;
    }
  }

  /// Queue an operation for offline execution
  Future<void> queueOperation(OfflineOperation operation) async {
    _ensureInitialized();

    try {
      await _offlineQueue.put(operation.id, operation);
      AppLogger.info('Queued offline operation: ${operation.type.name} (ID: ${operation.id})');

      // Try to sync immediately if online
      if (await isOnline) {
        _syncPendingOperations();
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to queue offline operation', e, stackTrace);
      rethrow;
    }
  }

  /// Get all pending operations sorted by timestamp
  List<OfflineOperation> getPendingOperations() {
    _ensureInitialized();

    final operations = _offlineQueue.values.toList();
    operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return operations;
  }

  /// Get count of pending operations
  int get pendingOperationsCount {
    if (!_isInitialized) return 0;
    return _offlineQueue.length;
  }

  /// Cache data for offline access (stores as JSON string)
  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    _ensureInitialized();

    try {
      final cacheEntry = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _cache.put(key, jsonEncode(cacheEntry));
      AppLogger.debug('Cached data for key: $key');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache data', e, stackTrace);
    }
  }

  /// Get cached data
  Map<String, dynamic>? getCachedData(String key) {
    _ensureInitialized();

    try {
      final cachedJson = _cache.get(key);
      if (cachedJson != null) {
        final cacheEntry = jsonDecode(cachedJson);
        return Map<String, dynamic>.from(cacheEntry['data']);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cached data', e, stackTrace);
    }

    return null;
  }

  /// Check if data is cached and not expired
  bool isCached(String key, {Duration maxAge = const Duration(hours: 1)}) {
    _ensureInitialized();

    try {
      final cachedJson = _cache.get(key);
      if (cachedJson != null) {
        final cacheEntry = jsonDecode(cachedJson);
        final timestamp = DateTime.parse(cacheEntry['timestamp']);
        final age = DateTime.now().difference(timestamp);
        return age <= maxAge;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check cache status', e, stackTrace);
    }

    return false;
  }

  /// Clear cached data
  Future<void> clearCache() async {
    _ensureInitialized();
    await _cache.clear();
    AppLogger.info('Cache cleared');
  }

  /// Sync pending operations when online
  Future<void> syncPendingOperations() async {
    if (_isSyncing || !(await isOnline)) return;
    await _syncPendingOperations();
  }

  /// Internal sync method
  Future<void> _syncPendingOperations() async {
    if (_isSyncing) return;

    _isSyncing = true;
    AppLogger.info('Starting sync of pending operations...');

    try {
      final operations = getPendingOperations();

      if (operations.isEmpty) {
        AppLogger.info('No pending operations to sync');
        return;
      }

      AppLogger.info('Syncing ${operations.length} pending operations');

      for (final operation in operations) {
        try {
          final success = await _executeOperation(operation);

          if (success) {
            // Success: Remove from queue
            await _offlineQueue.delete(operation.id);
            AppLogger.info('Successfully synced operation: ${operation.type.name}');
          } else {
            // Failure: Increment retry count or delete if max retries reached
            final newRetryCount = operation.retryCount + 1;
            
            if (newRetryCount >= maxRetryCount) {
              await _offlineQueue.delete(operation.id);
              AppLogger.warning('Max retries reached for operation: ${operation.type.name}. Dropped.');
            } else {
              final updatedOp = operation.copyWith(retryCount: newRetryCount);
              await _offlineQueue.put(operation.id, updatedOp);
              AppLogger.info('Retry $newRetryCount for operation: ${operation.type.name}');
            }
          }
        } catch (e, stackTrace) {
          AppLogger.error('Failed to sync operation: ${operation.type.name}', e, stackTrace);
        }
      }

      AppLogger.info('Sync cycle completed');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sync pending operations', e, stackTrace);
    } finally {
      _isSyncing = false;
    }
  }

  /// Execute a specific operation
  Future<bool> _executeOperation(OfflineOperation operation) async {
    try {
      AppLogger.info('Executing offline operation: ${operation.type.name}');

      switch (operation.type) {
        case OfflineOperationType.createCrimeReport:
          return await _executeCrimeReport(operation);
        
        case OfflineOperationType.updateCrimeReport:
          return await _executeUpdateCrimeReport(operation);
        
        case OfflineOperationType.createEmergencyAlert:
          return await _executeEmergencyAlert(operation);
        
        case OfflineOperationType.updateProfile:
          return await _executeProfileUpdate(operation);
        
        case OfflineOperationType.markNotificationRead:
          return await _executeMarkNotificationRead(operation);
        
        case OfflineOperationType.createEmergencyContact:
          return await _executeCreateEmergencyContact(operation);
        
        case OfflineOperationType.updateEmergencyContact:
          return await _executeUpdateEmergencyContact(operation);
        
        case OfflineOperationType.deleteEmergencyContact:
          return await _executeDeleteEmergencyContact(operation);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to execute operation: ${operation.type.name}', e, stackTrace);
      return false;
    }
  }

  // --- Operation Executors (Same logic as before, but using the operation object directly) ---

  Future<bool> _executeCrimeReport(OfflineOperation operation) async {
    try {
      final data = operation.data;
      final userId = operation.userId ?? _supabase.currentUser?.id;
      if (userId == null) return false;

      await _supabase.client.from('crime_reports').insert({
        'user_id': userId,
        'crime_type': data['crime_type'] ?? data['type'], // Handle both key names
        'title': data['title'] ?? 'Report',
        'description': data['description'],
        'region': data['region'],
        'city': data['city'],
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'location_description': data['location_description'] ?? data['location_address'],
        'incident_date': data['incident_date'],
        'severity': data['severity'],
        'evidence_urls': data['evidence_urls'] ?? [],
        'is_anonymous': data['is_anonymous'] ?? false,
        'status': 'pending', // Default to pending
        'created_at': data['created_at'],
        'updated_at': data['updated_at'] ?? DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      AppLogger.error('Execution error (createCrimeReport): $e');
      return false;
    }
  }

  Future<bool> _executeUpdateCrimeReport(OfflineOperation operation) async {
    try {
      final data = operation.data;
      final reportId = data['report_id'];
      if (reportId == null) return false;

      // Remove report_id from update data
      final updateData = Map<String, dynamic>.from(data);
      updateData.remove('report_id');
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.client.from('crime_reports').update(updateData).eq('id', reportId);
      return true;
    } catch (e) {
      AppLogger.error('Execution error (updateCrimeReport): $e');
      return false;
    }
  }

  Future<bool> _executeEmergencyAlert(OfflineOperation operation) async {
    try {
      final data = operation.data;
      final userId = operation.userId ?? _supabase.currentUser?.id;
      if (userId == null) return false;

      await _supabase.client.from('emergency_alerts').insert({
        'user_id': userId,
        'type': data['type'],
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'address': data['address'],
        'message': data['message'],
        'status': 'active',
        'created_at': data['created_at'],
      });
      return true;
    } catch (e) {
      AppLogger.error('Execution error (createEmergencyAlert): $e');
      return false;
    }
  }

  Future<bool> _executeProfileUpdate(OfflineOperation operation) async {
    try {
      final data = operation.data;
      final userId = operation.userId ?? _supabase.currentUser?.id;
      if (userId == null) return false;

      await _supabase.client.from('profiles').update({
        if (data['full_name'] != null) 'full_name': data['full_name'],
        if (data['phone_number'] != null) 'phone_number': data['phone_number'],
        if (data['region'] != null) 'region': data['region'],
        if (data['profile_image_url'] != null)
          'profile_image_url': data['profile_image_url'],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      return true;
    } catch (e) {
      AppLogger.error('Execution error (updateProfile): $e');
      return false;
    }
  }

  Future<bool> _executeMarkNotificationRead(OfflineOperation operation) async {
    try {
      final data = operation.data;
      final notificationId = data['notification_id'];
      if (notificationId == null) return false;

      await _supabase.client.from('user_notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);
      return true;
    } catch (e) {
      AppLogger.error('Execution error (markNotificationRead): $e');
      return false;
    }
  }

  Future<bool> _executeCreateEmergencyContact(OfflineOperation operation) async {
    try {
      final data = operation.data;
      final userId = operation.userId ?? _supabase.currentUser?.id;
      if (userId == null) return false;

      await _supabase.client.from('emergency_contacts').insert({
        'user_id': userId,
        'name': data['name'],
        'phone_number': data['phone_number'],
        'relationship': data['relationship'],
        'is_primary': data['is_primary'] ?? false,
        'created_at': data['created_at'],
      });
      return true;
    } catch (e) {
      AppLogger.error('Execution error (createEmergencyContact): $e');
      return false;
    }
  }

  Future<bool> _executeUpdateEmergencyContact(OfflineOperation operation) async {
    try {
      final data = operation.data;
      final contactId = data['contact_id'];
      if (contactId == null) return false;

      await _supabase.client.from('emergency_contacts').update({
        'name': data['name'],
        'phone_number': data['phone_number'],
        'relationship': data['relationship'],
        'is_primary': data['is_primary'],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', contactId);
      return true;
    } catch (e) {
      AppLogger.error('Execution error (updateEmergencyContact): $e');
      return false;
    }
  }

  Future<bool> _executeDeleteEmergencyContact(OfflineOperation operation) async {
    try {
      final data = operation.data;
      final contactId = data['contact_id'];
      if (contactId == null) return false;

      await _supabase.client.from('emergency_contacts').delete().eq('id', contactId);
      return true;
    } catch (e) {
      AppLogger.error('Execution error (deleteEmergencyContact): $e');
      return false;
    }
  }

  /// Start monitoring connectivity changes
  void _startConnectivityMonitoring() {
    Connectivity().onConnectivityChanged.listen((connectivityResults) {
      final isConnected =
          connectivityResults.contains(ConnectivityResult.mobile) ||
              connectivityResults.contains(ConnectivityResult.wifi) ||
              connectivityResults.contains(ConnectivityResult.ethernet);

      if (isConnected) {
        AppLogger.info('Connectivity restored, starting sync...');
        Future.delayed(const Duration(seconds: 2), () {
          _syncPendingOperations();
        });
      }
    });
  }

  /// Ensure service is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'OfflineService not initialized. Call initialize() first.');
    }
  }

  /// Close all boxes and cleanup
  Future<void> dispose() async {
    if (_isInitialized) {
      await _offlineQueue.close();
      await _cache.close();
      await _settings.close();
      _isInitialized = false;
      AppLogger.info('OfflineService disposed');
    }
  }
}
