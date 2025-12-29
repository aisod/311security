import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_311_super_admin/providers/auth_provider.dart';
import 'package:security_311_super_admin/providers/admin/admin_provider.dart';
import 'package:security_311_super_admin/screens/login_screen.dart';
// Will reuse or copy widget
import 'package:security_311_super_admin/screens/users/user_management_screen.dart';
import 'package:security_311_super_admin/screens/admin_creation/create_admin_screen.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadSystemStatistics();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
            },
          ),
        ],
      ),
      body: _buildBody(context),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admins',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 2
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreateAdminScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab(context);
      case 1:
        return const UserManagementScreen();
      case 2:
        return const Center(
            child: Text('Admin Management List (Coming Soon)')); // Placeholder
      default:
        return _buildOverviewTab(context);
    }
  }

  Widget _buildOverviewTab(BuildContext context) {
    final theme = Theme.of(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final stats = adminProvider.systemStats;

    return RefreshIndicator(
      onRefresh: () async {
        await adminProvider.loadSystemStatistics();
        await adminProvider.loadRecentActivity();
        await adminProvider.loadAllUsers();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple,
                    Colors.deepPurple.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.supervisor_account,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Super Admin Control Center',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Complete system management and oversight',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Management Actions
            Text(
              'Management Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildManagementActionCard(
                  context,
                  icon: Icons.people,
                  title: 'Users',
                  subtitle: 'Manage all users',
                  color: Colors.blue,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                const SizedBox(width: 12),
                _buildManagementActionCard(
                  context,
                  icon: Icons.admin_panel_settings,
                  title: 'Admins',
                  subtitle: 'Create admin accounts',
                  color: Colors.deepPurple,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Advanced Statistics
            Text(
              'Advanced Statistics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSuperAdminStatsCard(
                  context,
                  title: 'Total Users',
                  value: stats['total_users']?.toString() ?? '0',
                  subtitle: '${stats['verified_users'] ?? 0} verified',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                _buildSuperAdminStatsCard(
                  context,
                  title: 'Admin Users',
                  value: '${stats['admin_users'] ?? 0}',
                  subtitle: '${stats['super_admin_users'] ?? 0} super admins',
                  icon: Icons.admin_panel_settings,
                  color: Colors.deepPurple,
                ),
                _buildSuperAdminStatsCard(
                  context,
                  title: 'Active Alerts',
                  value: stats['active_alerts']?.toString() ?? '0',
                  subtitle: '${stats['alerts_last_24h'] ?? 0} today',
                  icon: Icons.warning_amber,
                  color: Colors.orange,
                ),
                _buildSuperAdminStatsCard(
                  context,
                  title: 'System Health',
                  value: 'Operational',
                  subtitle: 'All services running',
                  icon: Icons.health_and_safety,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Activity with Admin Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'System Activity',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSystemActivitySection(context, adminProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementActionCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required VoidCallback onTap}) {
    final theme = Theme.of(context);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuperAdminStatsCard(BuildContext context,
      {required String title,
      required String value,
      required String subtitle,
      required IconData icon,
      required Color color}) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemActivitySection(
      BuildContext context, AdminProvider adminProvider) {
    final theme = Theme.of(context);
    final activities = adminProvider.recentActivity;

    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.timeline,
                size: 48,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No recent system activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: activities.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _buildSystemActivityItem(context, activity);
        },
      ),
    );
  }

  Widget _buildSystemActivityItem(
      BuildContext context, Map<String, dynamic> activity) {
    final theme = Theme.of(context);

    IconData getActivityIcon(String type) {
      switch (type) {
        case 'alert':
          return Icons.warning;
        case 'report':
          return Icons.report;
        case 'emergency':
          return Icons.emergency;
        case 'user':
          return Icons.person_add;
        case 'admin':
          return Icons.admin_panel_settings;
        default:
          return Icons.info;
      }
    }

    Color getActivityColor(String type) {
      switch (type) {
        case 'alert':
          return Colors.orange;
        case 'report':
          return Colors.red;
        case 'emergency':
          return Colors.purple;
        case 'user':
          return Colors.blue;
        case 'admin':
          return Colors.deepPurple;
        default:
          return Colors.grey;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: getActivityColor(activity['type'] ?? 'info')
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              getActivityIcon(activity['type'] ?? 'info'),
              color: getActivityColor(activity['type'] ?? 'info'),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] ?? 'System Activity',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['description'] ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatActivityTime(activity['timestamp']),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatActivityTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';

    try {
      final dateTime = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }
}
