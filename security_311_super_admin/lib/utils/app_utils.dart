import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:security_311_super_admin/constants/app_constants.dart';

/// Utility functions for the 3:11 Security App
class AppUtils {
  /// Format phone numbers for display
  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-numeric characters except +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // If it starts with +264, format as +264 XX XXX XXXX
    if (cleaned.startsWith('+264') && cleaned.length == 12) {
      return '+264 ${cleaned.substring(4, 6)} ${cleaned.substring(6, 9)} ${cleaned.substring(9)}';
    }
    
    // If it starts with 264, add + and format
    if (cleaned.startsWith('264') && cleaned.length == 12) {
      return '+264 ${cleaned.substring(3, 5)} ${cleaned.substring(5, 8)} ${cleaned.substring(8)}';
    }
    
    // Return original if not a valid Namibian number
    return phoneNumber;
  }

  /// Validate Namibian phone number
  static bool isValidNamibianPhone(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    return AppConstants.namibianPhoneRegex.hasMatch(cleaned) ||
           (cleaned.startsWith('264') && cleaned.length == 12);
  }

  /// Validate Namibian ID number
  static bool isValidNamibianId(String idNumber) {
    String cleaned = idNumber.replaceAll(RegExp(r'[^0-9]'), '');
    return AppConstants.namibianIdRegex.hasMatch(cleaned);
  }

  /// Format date for display
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format date and time for display
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  /// Format relative time (e.g., "2 hours ago")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Generate a unique reference number
  static String generateReferenceNumber(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$prefix$timestamp';
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Check if file size is acceptable
  static bool isFileSizeAcceptable(int bytes) {
    return bytes <= AppConstants.maxFileSize;
  }

  /// Get file extension from filename
  static String getFileExtension(String filename) {
    return filename.split('.').last.toLowerCase();
  }

  /// Check if file type is supported for images
  static bool isSupportedImageType(String filename) {
    final extension = getFileExtension(filename);
    return AppConstants.supportedImageTypes.contains(extension);
  }

  /// Check if file type is supported for videos
  static bool isSupportedVideoType(String filename) {
    final extension = getFileExtension(filename);
    return AppConstants.supportedVideoTypes.contains(extension);
  }

  /// Check if file type is supported for documents
  static bool isSupportedDocumentType(String filename) {
    final extension = getFileExtension(filename);
    return AppConstants.supportedDocumentTypes.contains(extension);
  }

  /// Calculate distance between two coordinates in kilometers
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = 
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_degreesToRadians(lat1)) * 
         math.cos(_degreesToRadians(lat2)) * 
         math.sin(dLon / 2) * math.sin(dLon / 2));
    
    final double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show info snackbar
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show confirmation dialog
  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: confirmColor != null
                ? FilledButton.styleFrom(backgroundColor: confirmColor)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Vibrate device for feedback
  static void vibrate() {
    HapticFeedback.mediumImpact();
  }

  /// Copy text to clipboard
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Capitalize first letter of each word
  static String capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Get initials from name
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Check if email is valid
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Get color for severity level
  static Color getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Get color for priority level
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Get icon for crime type
  static IconData getCrimeTypeIcon(String crimeType) {
    switch (crimeType.toLowerCase()) {
      case 'theft':
      case 'robbery':
        return Icons.security;
      case 'assault':
        return Icons.warning;
      case 'vandalism':
        return Icons.broken_image;
      case 'fraud':
        return Icons.account_balance_wallet;
      case 'domestic_violence':
        return Icons.home;
      case 'drug_related':
        return Icons.medication;
      case 'corruption':
        return Icons.gavel;
      default:
        return Icons.report;
    }
  }

  /// Format crime type for display
  static String formatCrimeType(String crimeType) {
    switch (crimeType.toLowerCase()) {
      case 'domestic_violence':
        return 'Domestic Violence';
      case 'drug_related':
        return 'Drug Related';
      default:
        return capitalizeWords(crimeType.replaceAll('_', ' '));
    }
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return isTablet(context)
        ? const EdgeInsets.all(32.0)
        : const EdgeInsets.all(16.0);
  }

  /// Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    return isTablet(context) ? baseSize * 1.2 : baseSize;
  }
}


