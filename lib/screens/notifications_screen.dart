import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_311_user/providers/notifications_provider.dart';
import 'package:security_311_user/models/notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Convert UserNotification from provider to NotificationItem for UI
  List<NotificationItem> _convertNotifications(List<UserNotification> notifications) {
    return notifications.map((notification) {
      String type = 'info';
      if (notification.type == 'alert' || notification.type == 'emergency') {
        type = 'warning';
      } else if (notification.type == 'success') {
        type = 'success';
      }
      
      return NotificationItem(
        id: notification.id,
        title: notification.title,
        message: notification.message,
        timestamp: notification.createdAt,
        type: type,
        isRead: notification.isRead,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<NotificationsProvider>(
      builder: (context, notificationsProvider, child) {
        final notifications = _convertNotifications(notificationsProvider.allNotifications);
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: () {
                  _showNotificationSettings(context);
                },
                icon: const Icon(Icons.settings),
                tooltip: 'Notification Settings',
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'mark_all_read') {
                    _markAllAsRead(notificationsProvider);
                  } else if (value == 'clear_all') {
                    _clearAllNotifications(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.done_all, size: 20),
                        SizedBox(width: 8),
                        Text('Mark all as read'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, size: 20),
                        SizedBox(width: 8),
                        Text('Clear all'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: notificationsProvider.isLoading && notifications.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : notifications.isEmpty 
                  ? _EmptyNotificationsView()
                  : RefreshIndicator(
                      onRefresh: () => notificationsProvider.loadNotifications(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: NotificationCard(
                              notification: notification,
                              onTap: () {
                                _markAsRead(notificationsProvider, notification.id);
                              },
                            ),
                          );
                        },
                      ),
                    ),
        );
      },
    );
  }

  void _markAsRead(NotificationsProvider provider, String? notificationId) {
    if (notificationId != null) {
      provider.markAsRead(notificationId);
    }
  }

  void _markAllAsRead(NotificationsProvider provider) {
    provider.markAllAsRead();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: Color(0xFF388E3C),
      ),
    );
  }

  void _clearAllNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear All Notifications'),
          content: const Text('Are you sure you want to clear all notifications? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // Mark all as read instead of deleting
                final provider = context.read<NotificationsProvider>();
                provider.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    backgroundColor: Color(0xFFF57C00),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _NotificationSettingsSheet(),
    );
  }
}

class _EmptyNotificationsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "No Notifications",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You're all caught up! We'll notify you when there's something new.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSettingsSheet extends StatefulWidget {
  const _NotificationSettingsSheet();

  @override
  State<_NotificationSettingsSheet> createState() => _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<_NotificationSettingsSheet> {
  bool _crimeUpdates = true;
  bool _systemNotifications = true;
  bool _accountUpdates = true;
  bool _appUpdates = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Notification Settings',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Types',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Crime Report Updates'),
                    subtitle: const Text('Updates on your submitted reports'),
                    value: _crimeUpdates,
                    onChanged: (value) => setState(() => _crimeUpdates = value),
                  ),
                  SwitchListTile(
                    title: const Text('System Notifications'),
                    subtitle: const Text('Important system messages'),
                    value: _systemNotifications,
                    onChanged: (value) => setState(() => _systemNotifications = value),
                  ),
                  SwitchListTile(
                    title: const Text('Account Updates'),
                    subtitle: const Text('Changes to your account'),
                    value: _accountUpdates,
                    onChanged: (value) => setState(() => _accountUpdates = value),
                  ),
                  SwitchListTile(
                    title: const Text('App Updates'),
                    subtitle: const Text('New features and improvements'),
                    value: _appUpdates,
                    onChanged: (value) => setState(() => _appUpdates = value),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification settings saved'),
                            backgroundColor: Color(0xFF388E3C),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Data Models
class NotificationItem {
  final String? id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type;
  final bool isRead;

  NotificationItem({
    this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.isRead,
  });
}

// UI Components
class NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      color: notification.isRead 
        ? null 
        : theme.colorScheme.primary.withValues(alpha: 0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getTypeColor(notification.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(notification.type),
                  color: _getTypeColor(notification.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: notification.isRead 
                          ? FontWeight.w500 
                          : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'success':
        return const Color(0xFF388E3C);
      case 'warning':
        return const Color(0xFFF57C00);
      case 'error':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF1976D2);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
