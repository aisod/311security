import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 3:11 Security App Constants
class AppConstants {
  // App Information
  static const String appName = '3:11 Security';
  static const String appTagline = 'Your Safety, Our Priority';
  static const String appVersion = '1.0.0';

  // Emergency Contact Numbers
  static const Map<String, String> emergencyNumbers = {
    'police': '10111',
    'windhoek_police': '061290-2888',
    'medical': '2032276',
    'fire': '061290111',
    'security_311': '311',
  };

  // Namibian Regions
  static const List<String> namibianRegions = [
    'Khomas',
    'Erongo',
    'Oshana',
    'Ohangwena',
    'Kavango East',
    'Kavango West',
    'Zambezi',
    'Kunene',
    'Otjozondjupa',
    'Omaheke',
    'Hardap',
    'Karas',
    'Omusati',
    'Oshikoto',
  ];

  // Major Cities
  static const Map<String, String> majorCities = {
    'Windhoek': 'Khomas',
    'Swakopmund': 'Erongo',
    'Walvis Bay': 'Erongo',
    'Oshakati': 'Oshana',
    'Rundu': 'Kavango East',
    'Katima Mulilo': 'Zambezi',
    'Otjiwarongo': 'Otjozondjupa',
    'Gobabis': 'Omaheke',
    'Keetmanshoop': 'Karas',
    'Mariental': 'Hardap',
    'Outapi': 'Omusati',
    'Tsumeb': 'Oshikoto',
    'Eenhana': 'Ohangwena',
    'Opuwo': 'Kunene',
    'Nkurenkuru': 'Kavango West',
  };

  // Crime Types
  static const List<String> crimeTypes = [
    'theft',
    'robbery',
    'assault',
    'vandalism',
    'fraud',
    'domestic_violence',
    'drug_related',
    'corruption',
    'other',
  ];

  // Alert Types
  static const List<String> alertTypes = [
    'crime_warning',
    'weather_alert',
    'road_closure',
    'public_safety',
    'health_alert',
    'security_update',
    'community_notice',
  ];

  // Severity Levels
  static const List<String> severityLevels = [
    'info',
    'warning',
    'critical',
  ];

  // Priority Levels
  static const List<String> priorityLevels = [
    'low',
    'medium',
    'high',
    'critical',
  ];

  // Emergency Alert Types
  static const List<String> emergencyAlertTypes = [
    'panic',
    'medical',
    'fire',
    'crime_in_progress',
  ];

  // Notification Types
  static const List<String> notificationTypes = [
    'welcome',
    'crime_report_status',
    'verification_update',
    'system_update',
    'emergency_response',
    'safety_alert',
    'reminder',
    'general',
  ];

  // App Settings
  static const Duration locationTimeout = Duration(seconds: 10);
  static const Duration emergencyCountdown = Duration(seconds: 3);
  static const double cityRadiusKm = 50.0;
  static const int maxNotificationCount = 99;

  // Default Values
  static const String defaultRegion = 'Khomas';
  static const String defaultCity = 'Windhoek';
  static const double defaultLatitude = -22.5609;
  static const double defaultLongitude = 17.0658;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 8.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 3.0;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxDescriptionLength = 1000;
  static const int maxTitleLength = 100;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB

  // Phone Number Formats
  static const String namibianPhonePrefix = '+264';
  static final RegExp namibianPhoneRegex = RegExp(r'^\+264[0-9]{9}$');
  static final RegExp namibianIdRegex = RegExp(r'^[0-9]{11}$');

  // Supported File Types
  static const List<String> supportedImageTypes = [
    'jpg',
    'jpeg',
    'png',
    'gif',
  ];

  static const List<String> supportedVideoTypes = [
    'mp4',
    'mov',
    'avi',
  ];

  static const List<String> supportedDocumentTypes = [
    'pdf',
    'doc',
    'docx',
    'txt',
  ];

  // Supabase Configuration
  // These are now loaded from environment variables for security
  // See .env file for actual values
  static String get supabaseUrl {
    try {
      return const String.fromEnvironment('SUPABASE_URL',
          defaultValue: 'https://aivxbtpeybyxaaokyxrh.supabase.co');
    } catch (e) {
      // Fallback for development
      return 'https://aivxbtpeybyxaaokyxrh.supabase.co';
    }
  }

  static String get supabaseAnonKey {
    try {
      return const String.fromEnvironment('SUPABASE_ANON_KEY',
          defaultValue:
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFpdnhidHBleWJ5eGFhb2t5eHJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MzUzNTksImV4cCI6MjA3NDExMTM1OX0.YEgLlBiiwFL8Rf6oVzDuW0aD_kPigyelxdtCsHY36x8');
    } catch (e) {
      // Fallback for development
      return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFpdnhidHBleWJ5eGFhb2t5eHJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MzUzNTksImV4cCI6MjA3NDExMTM1OX0.YEgLlBiiwFL8Rf6oVzDuW0aD_kPigyelxdtCsHY36x8';
    }
  }

  // Google Maps Configuration
  static String get googleMapsApiKey {
    // Try environment variable first
    final envKey = dotenv.isInitialized
        ? dotenv.maybeGet('GOOGLE_MAPS_API_KEY')
        : null;
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }

    // Try dart-define
    const dartDefineKey =
        String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
    if (dartDefineKey.isNotEmpty) {
      return dartDefineKey;
    }

    // Development fallback - MUST be restricted in Google Cloud Console
    // Production builds should ALWAYS use environment variables
    // Using hardcoded key as fallback for now if env variable fails
    if (kReleaseMode) {
      // Try to use env key if available, otherwise fallback
      if (envKey != null && envKey.isNotEmpty) return envKey;
      // For now, fallback to hardcoded key even in release mode
      // This should be replaced with proper env management in CI/CD
      return 'AIzaSyCO0kKndUNlmQi3B5mxy4dblg_8WYcuKuk';
    }
    
    // Development only - Key restricted to localhost
    return 'AIzaSyCO0kKndUNlmQi3B5mxy4dblg_8WYcuKuk';
  }

  // API Endpoints (if needed)
  static const String baseApiUrl = 'https://api.311security.na';
  static const String emergencyEndpoint = '/emergency';
  static const String crimeReportEndpoint = '/crime-reports';
  static const String alertsEndpoint = '/alerts';

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String lastLocationKey = 'last_location';
  static const String appSettingsKey = 'app_settings';
  static const String emergencyContactsKey = 'emergency_contacts';

  // Error Messages
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String locationErrorMessage =
      'Unable to get your location. Please check permissions.';
  static const String authErrorMessage =
      'Authentication failed. Please try again.';
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';

  // Success Messages
  static const String reportSubmittedMessage = 'Report submitted successfully.';
  static const String emergencyAlertSentMessage =
      'Emergency alert sent successfully.';
  static const String profileUpdatedMessage = 'Profile updated successfully.';

  // Feature Flags
  static const bool enableLocationServices = true;
  static const bool enablePushNotifications = true;
  static const bool enableOfflineMode = false;
  static const bool enableDarkMode = true;
  static const bool enableBiometricAuth = false;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 800);
}

/// Emergency Service Information
class EmergencyService {
  final String name;
  final String number;
  final String description;
  final String icon;
  final String color;
  final bool isNational;
  final String? region;

  const EmergencyService({
    required this.name,
    required this.number,
    required this.description,
    required this.icon,
    required this.color,
    this.isNational = true,
    this.region,
  });
}

/// Pre-defined Emergency Services
class EmergencyServices {
  static const List<EmergencyService> services = [
    EmergencyService(
      name: 'Namibian Police',
      number: '10111',
      description: 'General police emergency',
      icon: 'police',
      color: 'blue',
      isNational: true,
    ),
    EmergencyService(
      name: 'Windhoek City Police',
      number: '061290-2888',
      description: 'City police services',
      icon: 'shield',
      color: 'indigo',
      isNational: false,
      region: 'Khomas',
    ),
    EmergencyService(
      name: 'Emergency Medical',
      number: '2032276',
      description: 'Ambulance & medical emergency',
      icon: 'medical',
      color: 'red',
      isNational: true,
    ),
    EmergencyService(
      name: 'Fire Department',
      number: '061290111',
      description: 'Fire emergency services',
      icon: 'fire',
      color: 'orange',
      isNational: true,
    ),
    EmergencyService(
      name: '3:11 Emergency',
      number: '311',
      description: '24/7 security assistance',
      icon: 'security',
      color: 'primary',
      isNational: true,
    ),
  ];

  /// Get emergency services for a specific region
  static List<EmergencyService> getServicesForRegion(String region) {
    return services
        .where((service) => service.isNational || service.region == region)
        .toList();
  }
}
