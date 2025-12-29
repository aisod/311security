import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:security_311_super_admin/models/notification.dart';
import 'package:security_311_super_admin/services/notification_service.dart';
import 'package:security_311_super_admin/services/offline_service.dart';
import 'package:security_311_super_admin/services/local_notification_service.dart';
import 'package:security_311_super_admin/core/logger.dart';

/// Notifications state provider with offline support
///
/// Manages notifications state, read status, and offline operations
class NotificationsProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final OfflineService _offlineService = OfflineService();
  final LocalNotificationService _localNotifications = LocalNotificationService();

  // Private state
  List<UserNotification> _notifications = [];
  List<UserNotification> _filteredNotifications = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedType;
  bool _showUnreadOnly = false;
  bool _isInitialized = false;
  StreamSubscription<List<UserNotification>>? _notificationStream;

  // Cache keys
  static const String _notificationsCacheKey = 'user_notifications';

  // Public getters
  List<UserNotification> get notifications => _filteredNotifications;
  List<UserNotification> get allNotifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedType => _selectedType;
  bool get showUnreadOnly => _showUnreadOnly;
  bool get isInitialized => _isInitialized;
  bool get hasNotifications => _notifications.isNotEmpty;
  int get notificationsCount => _notifications.length;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    AppLogger.info('Initializing NotificationsProvider...');

    try {
      // Ensure offline service is initialized
      if (!_offlineService.isInitialized) {
        await _offlineService.initialize();
      }

      // Initialize local notifications
      if (!_localNotifications.isInitialized) {
        await _localNotifications.initialize();
      }

      // Load cached notifications first for immediate display
      await _loadCachedNotifications();

      // Then fetch fresh data if online
      if (await _offlineService.isOnline) {
        await loadNotifications();
        
        // Start listening to realtime notifications
        _startRealtimeListener();
      } else {
        AppLogger.info('Offline mode: Using cached notifications');
      }

      _isInitialized = true;
      AppLogger.info('NotificationsProvider initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to initialize NotificationsProvider', e, stackTrace);
      _setError('Failed to initialize notifications');
    }
  }

  /// Start listening to realtime notifications from Supabase
  void _startRealtimeListener() {
    try {
      AppLogger.info('Starting realtime notification listener...');
      
      _notificationStream = _notificationService.watchUserNotifications().listen(
        (newNotifications) {
          AppLogger.info('Received ${newNotifications.length} notifications from realtime');
          
          // Check for new notifications (not in current list)
          for (final notification in newNotifications) {
            final isNew = !_notifications.any((n) => n.id == notification.id);
            
            if (isNew && !notification.isRead) {
              // Show local notification for new unread notifications
              _localNotifications.showNotificationFromModel(notification);
              AppLogger.info('Showed local notification: ${notification.title}');
            }
          }
          
          // Update notifications list
          _notifications = newNotifications;
          _applyFilters();
          
          // Cache the updated list
          _cacheNotifications(_notifications);
        },
        onError: (error) {
          AppLogger.error('Realtime notification error', error);
        },
      );
      
      AppLogger.info('Realtime notification listener started');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to start realtime listener', e, stackTrace);
    }
  }

  /// Load user notifications with caching
  Future<void> loadNotifications({int limit = 50}) async {
    AppLogger.info('Loading user notifications...');

    _setLoading(true);
    _clearError();

    try {
      List<UserNotification> notifications;

      if (await _offlineService.isOnline) {
        // Fetch from server
        notifications =
            await _notificationService.getUserNotifications(limit: limit);

        // Cache the results
        await _cacheNotifications(notifications);

        AppLogger.info(
            'Loaded ${notifications.length} notifications from server');
      } else {
        // Load from cache
        notifications = await _loadCachedNotifications() ?? [];
        AppLogger.info(
            'Loaded ${notifications.length} notifications from cache (offline)');
      }

      _notifications = notifications;
      _applyFilters();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load notifications', e, stackTrace);
      _setError('Failed to load notifications');

      // Try to load from cache as fallback
      final cachedNotifications = await _loadCachedNotifications();
      if (cachedNotifications != null && cachedNotifications.isNotEmpty) {
        _notifications = cachedNotifications;
        _applyFilters();
        AppLogger.info(
            'Loaded ${cachedNotifications.length} notifications from cache as fallback');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Mark notification as read (with offline support)
  Future<bool> markAsRead(String notificationId) async {
    AppLogger.info('Marking notification as read: $notificationId');

    try {
      if (await _offlineService.isOnline) {
        // Update on server
        final success =
            await _notificationService.markNotificationAsRead(notificationId);

        if (success) {
          // Update local state
          _updateNotificationReadStatus(notificationId, true);

          // Update cache
          await _cacheNotifications(_notifications);

          AppLogger.info('Notification marked as read successfully');
          return true;
        } else {
          _setError('Failed to mark notification as read');
          return false;
        }
      } else {
        // Queue for offline operation
        final operation = OfflineOperation(
          id: '${notificationId}_read_${DateTime.now().millisecondsSinceEpoch}',
          type: OfflineOperationType.markNotificationRead,
          data: {'notification_id': notificationId},
          timestamp: DateTime.now(),
        );

        await _offlineService.queueOperation(operation);

        // Update local state immediately for user feedback
        _updateNotificationReadStatus(notificationId, true);

        AppLogger.info('Notification read status queued for offline update');
        return true;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to mark notification as read', e, stackTrace);
      _setError('Failed to update notification');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    AppLogger.info('Marking all notifications as read');

    try {
      final unreadNotifications =
          _notifications.where((n) => !n.isRead).toList();

      if (unreadNotifications.isEmpty) {
        return true; // Nothing to do
      }

      if (await _offlineService.isOnline) {
        // Update on server
        final success = await _notificationService.markAllNotificationsAsRead();

        if (success) {
          // Update local state
          for (final notification in unreadNotifications) {
            _updateNotificationReadStatus(notification.id, true);
          }

          // Update cache
          await _cacheNotifications(_notifications);

          AppLogger.info('All notifications marked as read successfully');
          return true;
        } else {
          _setError('Failed to mark all notifications as read');
          return false;
        }
      } else {
        // Queue operations for each unread notification
        for (final notification in unreadNotifications) {
          final operation = OfflineOperation(
            id: '${notification.id}_read_${DateTime.now().millisecondsSinceEpoch}',
            type: OfflineOperationType.markNotificationRead,
            data: {'notification_id': notification.id},
            timestamp: DateTime.now(),
          );

          await _offlineService.queueOperation(operation);

          // Update local state immediately
          _updateNotificationReadStatus(notification.id, true);
        }

        AppLogger.info(
            'All notification read statuses queued for offline update');
        return true;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to mark all notifications as read', e, stackTrace);
      _setError('Failed to update notifications');
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    AppLogger.info('Deleting notification: $notificationId');

    try {
      if (await _offlineService.isOnline) {
        // Delete on server
        final success =
            await _notificationService.deleteNotification(notificationId);

        if (success) {
          // Remove from local state
          _notifications.removeWhere((n) => n.id == notificationId);
          _applyFilters();

          // Update cache
          await _cacheNotifications(_notifications);

          AppLogger.info('Notification deleted successfully');
          return true;
        } else {
          _setError('Failed to delete notification');
          return false;
        }
      } else {
        // For offline mode, just remove locally
        // Note: This won't sync to server, but provides immediate feedback
        _notifications.removeWhere((n) => n.id == notificationId);
        _applyFilters();

        AppLogger.info('Notification removed locally (offline mode)');
        return true;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete notification', e, stackTrace);
      _setError('Failed to delete notification');
      return false;
    }
  }

  /// Filter notifications by type
  void filterByType(String? type) {
    _selectedType = type;
    _applyFilters();
    AppLogger.info('Filtered notifications by type: $type');
  }

  /// Toggle show unread only
  void toggleShowUnreadOnly() {
    _showUnreadOnly = !_showUnreadOnly;
    _applyFilters();
    AppLogger.info('Toggle show unread only: $_showUnreadOnly');
  }

  /// Clear all filters
  void clearFilters() {
    _selectedType = null;
    _showUnreadOnly = false;
    _applyFilters();
    AppLogger.info('Cleared all notification filters');
  }

  /// Refresh notifications
  Future<void> refresh() async {
    await loadNotifications();
  }

  /// Get notification by ID
  UserNotification? getNotificationById(String notificationId) {
    try {
      return _notifications
          .firstWhere((notification) => notification.id == notificationId);
    } catch (e) {
      return null;
    }
  }

  /// Get notifications by type
  List<UserNotification> getNotificationsByType(String type) {
    return _notifications
        .where((notification) => notification.type == type)
        .toList();
  }

  /// Get unread notifications
  List<UserNotification> get unreadNotifications {
    return _notifications
        .where((notification) => !notification.isRead)
        .toList();
  }

  /// Update notification read status locally
  void _updateNotificationReadStatus(String notificationId, bool isRead) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final notification = _notifications[index];
      _notifications[index] = UserNotification(
        id: notification.id,
        userId: notification.userId,
        type: notification.type,
        title: notification.title,
        message: notification.message,
        isRead: isRead,
        relatedEntityId: notification.relatedEntityId,
        relatedEntityType: notification.relatedEntityType,
        metadata: notification.metadata,
        actionUrl: notification.actionUrl,
        createdAt: notification.createdAt,
      );

      _applyFilters();
    }
  }

  /// Cache notifications
  Future<void> _cacheNotifications(List<UserNotification> notifications) async {
    try {
      final notificationsData =
          notifications.map((notification) => notification.toJson()).toList();

      await _offlineService.cacheData(_notificationsCacheKey, {
        'notifications': notificationsData,
      });

      AppLogger.debug('Cached ${notifications.length} notifications');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache notifications', e, stackTrace);
    }
  }

  /// Load cached notifications
  Future<List<UserNotification>?> _loadCachedNotifications() async {
    try {
      final cachedData = _offlineService.getCachedData(_notificationsCacheKey);

      if (cachedData != null && cachedData['notifications'] != null) {
        final notificationsJson =
            List<Map<String, dynamic>>.from(cachedData['notifications']);
        final notifications = notificationsJson
            .map((json) => UserNotification.fromJson(json))
            .toList();

        AppLogger.debug(
            'Loaded ${notifications.length} notifications from cache');
        return notifications;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load cached notifications', e, stackTrace);
    }

    return null;
  }

  /// Apply current filters to notifications
  void _applyFilters() {
    _filteredNotifications = _notifications.where((notification) {
      // Filter by type
      if (_selectedType != null && notification.type != _selectedType) {
        return false;
      }

      // Filter by read status
      if (_showUnreadOnly && notification.isRead) {
        return false;
      }

      return true;
    }).toList();

    // Sort by creation date (newest first)
    _filteredNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    notifyListeners();
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
    AppLogger.info('Disposing NotificationsProvider');
    _notificationStream?.cancel();
    super.dispose();
  }
}
