import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:security_311_admin/core/logger.dart';

/// Helper service to download and cache images for notifications
class NotificationImageHelper {
  static final NotificationImageHelper _instance =
      NotificationImageHelper._internal();

  factory NotificationImageHelper() => _instance;

  NotificationImageHelper._internal();

  /// Download image from URL and save to temporary directory
  /// Returns local file path for use in notifications
  Future<String?> downloadAndCacheImage(String imageUrl) async {
    if (kIsWeb) {
      // Web doesn't support file paths, return URL directly
      return imageUrl;
    }

    try {
      AppLogger.info('Downloading notification image: $imageUrl');

      // Create cache directory
      final tempDir = await getTemporaryDirectory();
      final notificationImagesDir =
          Directory('${tempDir.path}/notification_images');
      
      if (!await notificationImagesDir.exists()) {
        await notificationImagesDir.create(recursive: true);
      }

      // Generate filename from URL
      final fileName = _generateFileName(imageUrl);
      final filePath = path.join(notificationImagesDir.path, fileName);
      final file = File(filePath);

      // Check if already cached
      if (await file.exists()) {
        AppLogger.info('Using cached notification image: $filePath');
        return filePath;
      }

      // Download image
      final response = await http.get(Uri.parse(imageUrl)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        // Save to file
        await file.writeAsBytes(response.bodyBytes);
        AppLogger.info('Notification image saved: $filePath');
        return filePath;
      } else {
        AppLogger.error(
          'Failed to download notification image: ${response.statusCode}',
        );
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error downloading notification image', e, stackTrace);
      return null;
    }
  }

  /// Download image and return as bytes (for web)
  Future<Uint8List?> downloadImageBytes(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Error downloading image bytes', e, stackTrace);
      return null;
    }
  }

  /// Generate unique filename from URL
  String _generateFileName(String url) {
    final uri = Uri.parse(url);
    final extension = path.extension(uri.path).isNotEmpty
        ? path.extension(uri.path)
        : '.jpg';
    
    // Use hash of URL as filename to avoid duplicates
    final hash = url.hashCode.abs().toString();
    return 'notif_$hash$extension';
  }

  /// Clear cached notification images
  Future<void> clearCache() async {
    if (kIsWeb) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final notificationImagesDir =
          Directory('${tempDir.path}/notification_images');

      if (await notificationImagesDir.exists()) {
        await notificationImagesDir.delete(recursive: true);
        AppLogger.info('Notification image cache cleared');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error clearing notification image cache', e, stackTrace);
    }
  }

  /// Clear old cached images (older than 7 days)
  Future<void> clearOldCache({int daysToKeep = 7}) async {
    if (kIsWeb) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final notificationImagesDir =
          Directory('${tempDir.path}/notification_images');

      if (!await notificationImagesDir.exists()) return;

      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: daysToKeep));

      await for (final entity in notificationImagesDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
            AppLogger.info('Deleted old notification image: ${entity.path}');
          }
        }
      }

      AppLogger.info('Old notification images cleared (older than $daysToKeep days)');
    } catch (e, stackTrace) {
      AppLogger.error('Error clearing old notification images', e, stackTrace);
    }
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    if (kIsWeb) return 0;

    try {
      final tempDir = await getTemporaryDirectory();
      final notificationImagesDir =
          Directory('${tempDir.path}/notification_images');

      if (!await notificationImagesDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in notificationImagesDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }

      return totalSize;
    } catch (e) {
      AppLogger.error('Error getting cache size', e);
      return 0;
    }
  }

  /// Get human-readable cache size
  Future<String> getCacheSizeFormatted() async {
    final bytes = await getCacheSize();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

