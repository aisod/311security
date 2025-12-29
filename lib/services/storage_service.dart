import 'dart:typed_data';
import 'dart:async';
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:security_311_user/services/supabase_service.dart';
import 'package:security_311_user/core/logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

/// Service for managing file uploads to Supabase Storage
class StorageService {
  final SupabaseService _supabase = SupabaseService();

  /// Upload profile image to Supabase Storage from XFile
  ///
  /// Returns the public URL of the uploaded image or null if upload fails
  Future<String?> uploadProfileImage(XFile imageFile, String userId) async {
    try {
      AppLogger.info('Uploading profile image for user $userId');

      // Read file as bytes
      final Uint8List originalBytes = await imageFile.readAsBytes();
      
      // Validate and compress image
      final Uint8List processedBytes = await _validateAndCompressImage(
        originalBytes,
        maxSizeMB: 5,
        maxDimension: 1024,
        quality: 85,
      );

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_${userId}_$timestamp.jpg';
      final filePath = 'profiles/$fileName';

      // Upload to Supabase Storage with timeout
      await _supabase.client.storage
          .from('avatars')
          .uploadBinary(
            filePath,
            processedBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: 'image/jpeg',
            ),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Upload timed out after 30 seconds');
            },
          );

      // Get public URL
      final String publicUrl =
          _supabase.client.storage.from('avatars').getPublicUrl(filePath);

      AppLogger.info('Profile image uploaded successfully: $publicUrl');
      return publicUrl;
    } on TimeoutException catch (e) {
      AppLogger.error('Profile image upload timed out', e);
      throw Exception('Upload timed out. Please try a smaller image.');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload profile image', e, stackTrace);
      return null;
    }
  }

  /// Delete profile image from Supabase Storage
  Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Find the path after 'avatars'
      final avatarsIndex = pathSegments.indexOf('avatars');
      if (avatarsIndex == -1 || avatarsIndex == pathSegments.length - 1) {
        AppLogger.warning('Invalid image URL format: $imageUrl');
        return false;
      }

      final filePath = pathSegments.sublist(avatarsIndex + 1).join('/');

      await _supabase.client.storage.from('avatars').remove([filePath]);

      AppLogger.info('Profile image deleted successfully: $filePath');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete profile image', e, stackTrace);
      return false;
    }
  }

  /// Upload crime report evidence image (reusable for other buckets)
  Future<String?> uploadEvidenceImage(
    XFile imageFile,
    String userId, {
    String bucketName = 'crime-evidence',
    String folderPrefix = 'evidence',
  }) async {
    try {
      AppLogger.info('Uploading evidence image for user $userId');

      // Read file as bytes
      final Uint8List originalBytes = await imageFile.readAsBytes();
      
      // Validate and compress image (higher quality for evidence)
      final Uint8List processedBytes = await _validateAndCompressImage(
        originalBytes,
        maxSizeMB: 10,
        maxDimension: 1920,
        quality: 90,
      );

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'evidence_${userId}_$timestamp.jpg';
      final filePath = '$folderPrefix/$userId/$fileName';

      // Upload to Supabase Storage with timeout
      await _supabase.client.storage
          .from(bucketName)
          .uploadBinary(
            filePath,
            processedBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: 'image/jpeg',
            ),
          )
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              throw TimeoutException('Upload timed out after 45 seconds');
            },
          );

      // Get public URL
      final String publicUrl =
          _supabase.client.storage.from(bucketName).getPublicUrl(filePath);

      AppLogger.info('Evidence image uploaded successfully: $publicUrl');
      return publicUrl;
    } on TimeoutException catch (e) {
      AppLogger.error('Evidence image upload timed out', e);
      throw Exception('Upload timed out. Please try a smaller image.');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload evidence image', e, stackTrace);
      return null;
    }
  }

  /// Upload multiple evidence images
  Future<List<String>> uploadMultipleEvidenceImages({
    required String userId,
    required List<XFile> images,
    String bucketName = 'crime-evidence',
    String folderPrefix = 'evidence',
  }) async {
    final urls = <String>[];

    for (final imageFile in images) {
      final url = await uploadEvidenceImage(
        imageFile,
        userId,
        bucketName: bucketName,
        folderPrefix: folderPrefix,
      );
      if (url != null) {
        urls.add(url);
      }
    }

    return urls;
  }

  Future<Uint8List> _validateAndCompressImage(
    Uint8List originalBytes, {
    required int maxSizeMB,
    required int maxDimension,
    required int quality,
  }) async {
    final int maxBytes = maxSizeMB * 1024 * 1024;

    try {
      final decoded = img.decodeImage(originalBytes);
      if (decoded == null) {
        throw Exception('Unsupported image format.');
      }

      img.Image processed = decoded;
      final int longestSide = math.max(decoded.width, decoded.height);

      if (longestSide > maxDimension) {
        final double scale = maxDimension / longestSide;
        final int newWidth = (decoded.width * scale).round();
        final int newHeight = (decoded.height * scale).round();
        processed = img.copyResize(
          decoded,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      var currentQuality = quality.clamp(40, 95).toInt();
      Uint8List encodedBytes = Uint8List.fromList(
        img.encodeJpg(
          processed,
          quality: currentQuality,
        ),
      );

      while (encodedBytes.lengthInBytes > maxBytes && currentQuality > 40) {
        currentQuality -= 5;
        encodedBytes = Uint8List.fromList(
          img.encodeJpg(
            processed,
            quality: currentQuality,
          ),
        );
      }

      if (encodedBytes.lengthInBytes > maxBytes) {
        throw Exception(
          'Image exceeds maximum size of ${maxSizeMB}MB even after compression. '
          'Please select a smaller image.',
        );
      }

      return encodedBytes;
    } catch (e, stackTrace) {
      AppLogger.error('Image validation/compression failed', e, stackTrace);
      rethrow;
    }
  }
}
