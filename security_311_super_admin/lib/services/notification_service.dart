import 'package:security_311_super_admin/services/supabase_service.dart';
import 'package:security_311_super_admin/models/notification.dart';
import 'package:security_311_super_admin/core/logger.dart';

/// Service for managing user notifications
class NotificationService {
  final SupabaseService _supabase = SupabaseService();

  /// Get notifications for the current user
  Future<List<UserNotification>> getUserNotifications({
    bool? isRead,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return [];

      var query = _supabase.client
          .from('user_notifications')
          .select()
          .eq('user_id', user.id);

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => UserNotification.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting user notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return 0;

      final response = await _supabase.client
          .from('user_notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      AppLogger.error('Error getting unread notification count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return false;

      await _supabase.client
          .from('user_notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      AppLogger.error('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllNotificationsAsRead() async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return false;

      await _supabase.client
          .from('user_notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);

      return true;
    } catch (e) {
      AppLogger.error('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Delete a notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return false;

      await _supabase.client
          .from('user_notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      AppLogger.error('Error deleting notification: $e');
      return false;
    }
  }

  /// Create a notification (internal use, usually called by other services)
  Future<UserNotification?> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? relatedEntityId,
    String? relatedEntityType,
    Map<String, dynamic>? metadata,
    String? actionUrl,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'type': type,
        'title': title,
        'message': message,
        'related_entity_id': relatedEntityId,
        'related_entity_type': relatedEntityType,
        'metadata': metadata,
        'action_url': actionUrl,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase.client
          .from('user_notifications')
          .insert(data)
          .select()
          .single();

      return UserNotification.fromJson(response);
    } catch (e) {
      AppLogger.error('Error creating notification: $e');
      return null;
    }
  }

  /// Get notifications by type
  Future<List<UserNotification>> getNotificationsByType(String type,
      {int limit = 20}) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return [];

      final response = await _supabase.client
          .from('user_notifications')
          .select()
          .eq('user_id', user.id)
          .eq('type', type)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((json) => UserNotification.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Error getting notifications by type: $e');
      return [];
    }
  }

  /// Listen to changes in user's notifications
  Stream<List<UserNotification>> watchUserNotifications() {
    final user = _supabase.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase.client
        .from('user_notifications')
        .stream(primaryKey: ['id']).map((data) {
      // Filter notifications for current user
      final filteredData =
          data.where((json) => json['user_id'] == user.id).toList();

      // Sort by created_at descending
      filteredData.sort((a, b) {
        final aTime = DateTime.parse(a['created_at'] as String);
        final bTime = DateTime.parse(b['created_at'] as String);
        return bTime.compareTo(aTime);
      });

      return filteredData
          .map((json) => UserNotification.fromJson(json))
          .toList();
    });
  }

  /// Get notification statistics
  Future<Map<String, int>> getNotificationStats() async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return {};

      final response = await _supabase.client
          .from('user_notifications')
          .select('type, is_read')
          .eq('user_id', user.id);

      final stats = <String, int>{};
      for (final notification in response) {
        final type = notification['type'] as String;
        final isRead = notification['is_read'] as bool? ?? false;

        stats['total'] = (stats['total'] ?? 0) + 1;
        stats['type_$type'] = (stats['type_$type'] ?? 0) + 1;

        if (!isRead) {
          stats['unread'] = (stats['unread'] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      AppLogger.error('Error getting notification stats: $e');
      return {};
    }
  }
}
