import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_311_super_admin/theme.dart';
import 'package:security_311_super_admin/screens/dashboard/super_admin_dashboard_screen.dart';
import 'package:security_311_super_admin/screens/login_screen.dart';
import 'package:security_311_super_admin/screens/splash_screen.dart';
import 'package:security_311_super_admin/services/supabase_service.dart';
import 'package:security_311_super_admin/services/offline_service.dart';
import 'package:security_311_super_admin/core/logger.dart';
import 'package:security_311_super_admin/providers/auth_provider.dart';
import 'package:security_311_super_admin/providers/safety_alerts_provider.dart';
import 'package:security_311_super_admin/providers/crime_reports_provider.dart';
import 'package:security_311_super_admin/providers/notifications_provider.dart';
import 'package:security_311_super_admin/providers/connectivity_provider.dart';
import 'package:security_311_super_admin/providers/admin/admin_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    AppLogger.info('Environment variables loaded successfully');
  } catch (e) {
    AppLogger.warning('Failed to load .env file: $e');
  }

  await _bootstrapApp();
}

Future<void> _bootstrapApp() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.fatal('Flutter error', details.exception, details.stack);
    FlutterError.presentError(details);
  };

  try {
    AppLogger.info('Initializing Supabase...');
    await SupabaseService.initialize();
    AppLogger.info('Supabase initialized successfully');

    AppLogger.info('Initializing offline service...');
    final offlineService = OfflineService();
    await offlineService.initialize();
    AppLogger.info('Offline service initialized successfully');

    runApp(const SuperAdminApp());
  } catch (e, stackTrace) {
    AppLogger.fatal('Failed to initialize app', e, stackTrace);
    runApp(const ErrorApp());
  }
}

class SuperAdminApp extends StatelessWidget {
  const SuperAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => ConnectivityProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(
            create: (_) => SafetyAlertsProvider()..initialize()),
        ChangeNotifierProvider(
            create: (_) => CrimeReportsProvider()..initialize()),
        ChangeNotifierProvider(
            create: (_) => NotificationsProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => AdminProvider()..initialize()),
      ],
      child: MaterialApp(
        title: '3:11 Security Super Admin',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthenticationWrapper(),
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isInitialized || authProvider.isLoading) {
          return const SplashScreen();
        }

        if (authProvider.isAuthenticated) {
          // TODO: Check if user has super_admin role
          return const SuperAdminDashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              const Text('Failed to Initialize App'),
              ElevatedButton(
                onPressed: () => main(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
