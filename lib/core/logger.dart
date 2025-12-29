import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Centralized logging utility for the 3:11 Security app
///
/// Provides consistent logging across the application with proper
/// formatting and log levels. In production, logs can be sent to
/// external services like Sentry or Firebase Crashlytics.
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // Number of method calls to show
      errorMethodCount: 8, // Number of method calls for errors
      lineLength: 120, // Width of output
      colors: true, // Colorful log messages
      printEmojis: true, // Print emojis
      dateTimeFormat:
          DateTimeFormat.onlyTimeAndSinceStart, // Updated from printTime
    ),
    level: kDebugMode ? Level.debug : Level.warning,
  );

  /// Log debug message (development only)
  ///
  /// Use for detailed information useful during development
  /// Example: AppLogger.debug('User tapped on crime report button');
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  ///
  /// Use for general information about app state
  /// Example: AppLogger.info('User logged in successfully');
  static void info(String message) {
    _logger.i(message);
  }

  /// Log warning message
  ///
  /// Use for potentially harmful situations
  /// Example: AppLogger.warning('Location permission denied');
  static void warning(String message, [dynamic error]) {
    _logger.w(message, error: error);
  }

  /// Log error message
  ///
  /// Use for errors that might still allow the app to continue running
  /// Example: AppLogger.error('Failed to load notifications', error, stackTrace);
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    
    // Send to Sentry in production
    if (!kDebugMode && error != null) {
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({'message': message}),
      );
    }
  }

  /// Log fatal error
  ///
  /// Use for very severe errors that might crash the app
  /// Example: AppLogger.fatal('Critical database corruption detected');
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
    
    // Always send fatal errors to Sentry
    if (error != null) {
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({'level': 'fatal', 'message': message}),
      );
    }
  }

  /// Log HTTP request/response (for API debugging)
  static void http(String method, String url, {int? statusCode, dynamic body}) {
    _logger.d('$method $url ${statusCode != null ? '[$statusCode]' : ''}',
        error: body != null ? 'Body: $body' : null);
  }
}
