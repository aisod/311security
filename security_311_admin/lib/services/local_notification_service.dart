import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:security_311_admin/core/logger.dart';
import 'package:security_311_admin/models/notification.dart';
import 'package:security_311_admin/services/notification_image_helper.dart';

/// Local Notification Service for showing notifications
/// Works with Supabase Realtime to show notifications when they arrive
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();

  factory LocalNotificationService() => _instance;

  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final NotificationImageHelper _imageHelper = NotificationImageHelper();

  bool _isInitialized = false;
  Function(String?)? onNotificationTapped;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Initialize local notifications
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.info('LocalNotificationService already initialized');
      return;
    }

    try {
      AppLogger.info('Initializing LocalNotificationService...');

      if (kIsWeb) {
        AppLogger.warning(
            'flutter_local_notifications is not supported on web. '
            'Notifications will be handled via in-app banners only.');
        _isInitialized = true;
        return;
      }

      // Android initialization settings
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android
      if (!kIsWeb) {
        await _createNotificationChannels();
      }

      _isInitialized = true;
      AppLogger.info('LocalNotificationService initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to initialize LocalNotificationService', e, stackTrace);
    }
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    if (kIsWeb) return;

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Emergency channel
    final emergencyChannel = AndroidNotificationChannel(
      'emergency',
      'Emergency Alerts',
      description: 'Critical security emergencies and panic alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: const Color(0xFFFF0000),
    );

    // Crime alerts channel
    final crimeChannel = AndroidNotificationChannel(
      'crime',
      'Crime Alerts',
      description: 'Crime reports and warnings in your area',
      importance: Importance.high,
      playSound: true,
      enableVibration: false,
    );

    // Safety alerts channel
    final safetyChannel = AndroidNotificationChannel(
      'safety',
      'Safety Alerts',
      description: 'Safety updates and weather alerts',
      importance: Importance.high,
      playSound: true,
      enableVibration: false,
    );

    // Report updates channel
    final reportChannel = AndroidNotificationChannel(
      'report',
      'Report Updates',
      description: 'Your crime report status updates',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: false,
    );

    // General channel
    final generalChannel = AndroidNotificationChannel(
      'general',
      'General Notifications',
      description: 'App updates and general information',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: false,
    );

    // Create all channels
    await androidPlugin.createNotificationChannel(emergencyChannel);
    await androidPlugin.createNotificationChannel(crimeChannel);
    await androidPlugin.createNotificationChannel(safetyChannel);
    await androidPlugin.createNotificationChannel(reportChannel);
    await androidPlugin.createNotificationChannel(generalChannel);

    AppLogger.info('Created 5 notification channels');
  }

  /// Show notification from UserNotification model
  Future<void> showNotificationFromModel(UserNotification notification) async {
    if (!_isInitialized) {
      AppLogger.warning('Cannot show notification: Service not initialized');
      return;
    }

    // Extract image URL from metadata if available
    String? imageUrl;
    if (notification.metadata != null &&
        notification.metadata!['image_url'] != null) {
      imageUrl = notification.metadata!['image_url'] as String;
    }

    await showNotification(
      id: notification.id.hashCode,
      title: notification.title,
      body: notification.message,
      type: notification.type,
      payload: notification.id,
      imageUrl: imageUrl,
    );
  }

  /// Show notification with optional image
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String type = 'general',
    String? payload,
    String? imageUrl,
  }) async {
    if (!_isInitialized) {
      AppLogger.warning('Cannot show notification: Service not initialized');
      return;
    }

    if (kIsWeb) {
      AppLogger.info(
          'Web build detected — skipping native notification for "$title"');
      return;
    }

    try {
      final channelId = _getChannelId(type);
      final channelName = _getChannelName(type);
      final importance = _getImportance(type);
      final priority = _getPriority(type);

      // Prepare style information with image if available
      StyleInformation? styleInformation;
      String? localImagePath;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        // Download and cache image
        localImagePath = await _imageHelper.downloadAndCacheImage(imageUrl);

        final imagePath = localImagePath;
        if (imagePath != null) {
          // For Android, use BigPictureStyleInformation with local file
          try {
            styleInformation = BigPictureStyleInformation(
              FilePathAndroidBitmap(imagePath),
              largeIcon: FilePathAndroidBitmap(imagePath),
              contentTitle: title,
              summaryText: body,
              htmlFormatContentTitle: true,
              htmlFormatSummaryText: true,
            );
            AppLogger.info('Notification will show with image: $imagePath');
          } catch (e) {
            AppLogger.warning('Could not use image for notification: $e');
            styleInformation = BigTextStyleInformation(body);
          }
        } else {
          styleInformation = BigTextStyleInformation(body);
        }
      } else {
        // No image, use big text style
        styleInformation = BigTextStyleInformation(body);
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: _getChannelDescription(type),
        importance: importance,
        priority: priority,
        showWhen: true,
        enableVibration: type == 'emergency' || type == 'panic',
        playSound: true,
        icon: '@mipmap/ic_launcher',
        color: _getNotificationColor(type),
        styleInformation: styleInformation,
        largeIcon: () {
          final iconPath = localImagePath;
          return iconPath != null ? FilePathAndroidBitmap(iconPath) : null;
        }(),
      );

      // iOS supports attachments differently (requires local file path)
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        attachments: localImagePath != null
            ? [DarwinNotificationAttachment(localImagePath)]
            : null,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      AppLogger.info(
          'Notification shown: $title${imageUrl != null ? " (with image)" : ""}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to show notification', e, stackTrace);
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.info('Notification tapped: ${response.payload}');
    if (onNotificationTapped != null) {
      onNotificationTapped!(response.payload);
    }
  }

  /// Get channel ID from notification type
  String _getChannelId(String type) {
    switch (type) {
      case 'emergency':
      case 'panic':
        return 'emergency';
      case 'crime_warning':
      case 'crime_alert':
      case 'crime':
        return 'crime';
      case 'safety_alert':
      case 'weather_alert':
      case 'public_safety':
      case 'safety':
        return 'safety';
      case 'crime_report_status':
      case 'verification_update':
      case 'report':
        return 'report';
      default:
        return 'general';
    }
  }

  /// Get channel name
  String _getChannelName(String type) {
    switch (_getChannelId(type)) {
      case 'emergency':
        return 'Emergency Alerts';
      case 'crime':
        return 'Crime Alerts';
      case 'safety':
        return 'Safety Alerts';
      case 'report':
        return 'Report Updates';
      default:
        return 'General Notifications';
    }
  }

  /// Get channel description
  String _getChannelDescription(String type) {
    switch (_getChannelId(type)) {
      case 'emergency':
        return 'Critical security emergencies and panic alerts';
      case 'crime':
        return 'Crime reports and warnings in your area';
      case 'safety':
        return 'Safety updates and weather alerts';
      case 'report':
        return 'Your crime report status updates';
      default:
        return 'App updates and general information';
    }
  }

  /// Get importance level
  Importance _getImportance(String type) {
    switch (_getChannelId(type)) {
      case 'emergency':
        return Importance.max;
      case 'crime':
      case 'safety':
        return Importance.high;
      default:
        return Importance.defaultImportance;
    }
  }

  /// Get priority level
  Priority _getPriority(String type) {
    switch (_getChannelId(type)) {
      case 'emergency':
        return Priority.max;
      case 'crime':
      case 'safety':
        return Priority.high;
      default:
        return Priority.defaultPriority;
    }
  }

  /// Get notification color
  Color _getNotificationColor(String type) {
    switch (_getChannelId(type)) {
      case 'emergency':
        return const Color(0xFFFF0000); // Red
      case 'crime':
        return const Color(0xFFFF6B00); // Orange
      case 'safety':
        return const Color(0xFF0066FF); // Blue
      case 'report':
        return const Color(0xFF9C27B0); // Purple
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  /// Cancel notification
  Future<void> cancelNotification(int id) async {
    if (kIsWeb) {
      AppLogger.info('Web build detected — skipping cancelNotification');
      return;
    }
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) {
      AppLogger.info('Web build detected — skipping cancelAllNotifications');
      return;
    }
    await _notifications.cancelAll();
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    if (kIsWeb) {
      return 0;
    }
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }

  /// Request permissions (iOS)
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;

    try {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      // Android permissions are granted at install time
      return true;
    } catch (e) {
      AppLogger.error('Failed to request permissions', e);
      return false;
    }
  }
}
