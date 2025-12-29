import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:security_311_user/theme.dart';
import 'package:security_311_user/screens/dashboard_screen.dart';
import 'package:security_311_user/screens/auth/login_screen.dart';
import 'package:security_311_user/screens/auth/splash_screen.dart';
import 'package:security_311_user/screens/auth/reset_password_screen.dart';
import 'package:security_311_user/services/supabase_service.dart';
import 'package:security_311_user/services/offline_service.dart';
import 'package:security_311_user/core/logger.dart';
import 'package:security_311_user/providers/auth_provider.dart';
import 'package:security_311_user/providers/safety_alerts_provider.dart';
import 'package:security_311_user/providers/crime_reports_provider.dart';
import 'package:security_311_user/providers/notifications_provider.dart';
import 'package:security_311_user/providers/connectivity_provider.dart';
import 'package:security_311_user/providers/location_provider.dart';
import 'package:security_311_user/providers/missing_reports_provider.dart';
import 'package:security_311_user/providers/danger_zone_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables before initializing services
  try {
    await dotenv.load(fileName: ".env");
    AppLogger.info('Environment variables loaded successfully');
  } catch (e) {
    AppLogger.warning('Failed to load .env file: $e');
  }

  final sentryDsn = dotenv.isInitialized ? dotenv.maybeGet('SENTRY_DSN') : null;
  final hasSentryDsn = sentryDsn != null && sentryDsn.isNotEmpty;

  if (!hasSentryDsn) {
    AppLogger.warning(
      'SENTRY_DSN not configured. Running without Sentry (no crash reporting).',
    );
    await _bootstrapApp(enableSentry: false);
    return;
  }

  // Initialize Sentry for error tracking only when DSN is configured
  await SentryFlutter.init(
    (options) {
      options.dsn = sentryDsn;
      options.environment = kDebugMode ? 'development' : 'production';
      options.release = 'security_311_user@1.0.0+1';
      options.tracesSampleRate = kDebugMode ? 1.0 : 0.1;
      options.debug = kDebugMode;
      options.enableAutoSessionTracking = true;
      options.attachStacktrace = true;
      options.attachThreads = true;
    },
    appRunner: () async => _bootstrapApp(enableSentry: true),
  );
}

Future<void> _bootstrapApp({required bool enableSentry}) async {
  // Set up Flutter error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.fatal('Flutter error', details.exception, details.stack);

    if (enableSentry && !kDebugMode) {
      Sentry.captureException(
        details.exception,
        stackTrace: details.stack,
      );
    }

    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.fatal('Platform error', error, stack);

    if (enableSentry && !kDebugMode) {
      Sentry.captureException(error, stackTrace: stack);
    }

    return true;
  };

  try {
    // Initialize Supabase
    AppLogger.info('Initializing Supabase...');
    await SupabaseService.initialize();
    AppLogger.info('Supabase initialized successfully');

    // Validate storage buckets
    AppLogger.info('Validating storage buckets...');
    await _validateStorageBuckets();
    AppLogger.info('Storage buckets validated successfully');

    // Initialize offline service
    AppLogger.info('Initializing offline service...');
    final offlineService = OfflineService();
    await offlineService.initialize();
    AppLogger.info('Offline service initialized successfully');

    runApp(const SecurityApp());
  } catch (e, stackTrace) {
    AppLogger.fatal('Failed to initialize app', e, stackTrace);

    if (enableSentry && !kDebugMode) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }

    runApp(const ErrorApp());
  }
}

/// Validate that required storage buckets exist
Future<void> _validateStorageBuckets() async {
  final supabase = SupabaseService();
  final requiredBuckets = [
    'avatars',
    'crime-evidence',
    'notification-images',
    'missing-reports',
  ];

  for (final bucket in requiredBuckets) {
    try {
      await supabase.client.storage.from(bucket).list(
            path: '',
          );
      AppLogger.info('Storage bucket validated: $bucket');
    } catch (e) {
      AppLogger.fatal('Storage bucket missing or inaccessible: $bucket', e);
      throw Exception(
        'Storage configuration error: Bucket "$bucket" is not available. '
        'Please ensure all storage buckets are created in Supabase Dashboard.',
      );
    }
  }
}

class SecurityApp extends StatelessWidget {
  const SecurityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider(
            create: (_) => ConnectivityProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => LocationProvider()..initialize()),

        // Feature providers
        ChangeNotifierProvider(
            create: (_) => SafetyAlertsProvider()..initialize()),
        ChangeNotifierProvider(
            create: (_) => CrimeReportsProvider()..initialize()),
        ChangeNotifierProvider(
            create: (_) => NotificationsProvider()..initialize()),
        ChangeNotifierProvider(
            create: (_) => MissingReportsProvider()..initialize()),
        ChangeNotifierProvider(
            create: (_) => DangerZoneProvider()..initialize()),
      ],
      child: MaterialApp(
        title: '3:11 Security',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthenticationWrapper(),
      ),
    );
  }
}

/// Wrapper widget that handles authentication state
///
/// Shows splash screen while checking auth state,
/// then navigates to either login or dashboard based on authentication.
/// Also handles password reset URL tokens.
class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  bool _checkedPasswordReset = false;
  Widget? _passwordResetScreen;

  @override
  void initState() {
    super.initState();
    _checkPasswordResetUrl();
  }

  /// Check if the current URL contains password reset tokens
  void _checkPasswordResetUrl() {
    if (kIsWeb) {
      try {
        final uri = Uri.base;
        final hash = uri.fragment;

        // Supabase password reset links contain access_token and type=recovery in the hash
        if (hash.contains('access_token=') && hash.contains('type=recovery')) {
          AppLogger.info('Password reset URL detected');

          // Extract tokens from hash
          final params = Uri.splitQueryString(hash);
          final accessToken = params['access_token'];
          final refreshToken = params['refresh_token'];

          if (accessToken != null) {
            // Supabase will automatically handle the session when the URL is processed
            // We just need to show the reset password screen
            setState(() {
              _passwordResetScreen = ResetPasswordScreen(
                accessToken: accessToken,
                refreshToken: refreshToken,
              );
              _checkedPasswordReset = true;
            });
            return;
          }
        }
      } catch (e, stackTrace) {
        AppLogger.error('Error checking password reset URL', e, stackTrace);
      }
    }

    setState(() {
      _checkedPasswordReset = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show password reset screen if URL contains reset tokens
    if (_passwordResetScreen != null) {
      return _passwordResetScreen!;
    }

    // Wait for password reset check to complete
    if (!_checkedPasswordReset) {
      return const SplashScreen();
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show splash screen while initializing
        if (!authProvider.isInitialized || authProvider.isLoading) {
          return const SplashScreen();
        }

        // Check if user is authenticated
        if (authProvider.isAuthenticated) {
          AppLogger.info('User authenticated, showing dashboard');
          return const DashboardScreen();
        }

        // User not authenticated, show login screen
        AppLogger.info('User not authenticated, showing login screen');
        return const LoginScreen();
      },
    );
  }
}

/// Error app shown when initialization fails
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '3:11 Security - Error',
      theme: lightTheme,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Failed to Initialize App',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please check your internet connection and try again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Restart app
                    runApp(const MaterialApp(home: SplashScreen()));
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
