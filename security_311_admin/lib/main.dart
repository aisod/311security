import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_311_admin/theme.dart';
import 'package:security_311_admin/screens/dashboard/admin_dashboard_screen.dart';
import 'package:security_311_admin/screens/login_screen.dart';
import 'package:security_311_admin/screens/splash_screen.dart';
import 'package:security_311_admin/services/supabase_service.dart';
import 'package:security_311_admin/services/offline_service.dart';
import 'package:security_311_admin/core/logger.dart';
import 'package:security_311_admin/providers/auth_provider.dart';
import 'package:security_311_admin/providers/safety_alerts_provider.dart';
import 'package:security_311_admin/providers/crime_reports_provider.dart';
import 'package:security_311_admin/providers/notifications_provider.dart';
import 'package:security_311_admin/providers/connectivity_provider.dart';
import 'package:security_311_admin/providers/admin/admin_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    AppLogger.info('Environment variables loaded successfully');
  } catch (e) {
    AppLogger.warning('Failed to load .env file: $e');
  }

  await _bootstrapApp();
}

Future<void> _bootstrapApp() async {
  // Set up Flutter error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.fatal('Flutter error', details.exception, details.stack);
    FlutterError.presentError(details);
  };

  try {
    // Initialize Supabase
    AppLogger.info('Initializing Supabase...');
    await SupabaseService.initialize();
    AppLogger.info('Supabase initialized successfully');

    // Initialize offline service
    AppLogger.info('Initializing offline service...');
    final offlineService = OfflineService();
    await offlineService.initialize();
    AppLogger.info('Offline service initialized successfully');

    runApp(const AdminApp());
  } catch (e, stackTrace) {
    AppLogger.fatal('Failed to initialize app', e, stackTrace);
    runApp(const ErrorApp());
  }
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

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
        title: '3:11 Security Admin',
        debugShowCheckedModeBanner: false,
        theme: lightTheme, // Reusing theme from user app
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
          // Check if user has admin role
          return _AdminAccessCheck(
            onPermissionCheck: () {
              // Trigger permission check when user logs in
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<AdminProvider>().checkPermissions();
              });
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}

class _AdminAccessCheck extends StatefulWidget {
  final VoidCallback onPermissionCheck;

  const _AdminAccessCheck({required this.onPermissionCheck});

  @override
  State<_AdminAccessCheck> createState() => _AdminAccessCheckState();
}

class _AdminAccessCheckState extends State<_AdminAccessCheck> {
  bool _hasCheckedPermissions = false;

  @override
  void initState() {
    super.initState();
    // Trigger permission check when widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPermissionCheck();
      setState(() {
        _hasCheckedPermissions = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        // Show loading while checking permissions
        if (!_hasCheckedPermissions || adminProvider.isCheckingPermissions) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user has admin permissions, show dashboard
        if (adminProvider.isAdmin || adminProvider.isSuperAdmin) {
          return const AdminDashboardScreen();
        }

              // User is authenticated but not an admin
              final authProvider = context.read<AuthProvider>();
              final userEmail = authProvider.user?.email ?? 'Unknown';
              
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Access Denied'),
                  automaticallyImplyLeading: false,
                ),
                body: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.block,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Access Denied',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'You do not have admin privileges to access this panel.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Logged in as: $userEmail',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'To gain access:\n'
                          '1. Go to Supabase Dashboard\n'
                          '2. Open the "profiles" table\n'
                          '3. Find your user record\n'
                          '4. Set the "role" field to "admin" or "super_admin"\n'
                          '5. Click "Refresh Permissions" below',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await authProvider.signOut();
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign Out'),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            // Re-check permissions
                            adminProvider.checkPermissions();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Permissions'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
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
