import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_311_admin/providers/auth_provider.dart';
import 'package:security_311_admin/providers/admin/admin_provider.dart';
import 'package:security_311_admin/providers/safety_alerts_provider.dart';
import 'package:security_311_admin/screens/login_screen.dart';
import 'package:security_311_admin/screens/alerts/alerts_management_screen.dart';
import 'package:security_311_admin/screens/reports/reports_management_screen.dart';
import 'package:security_311_admin/screens/users/users_management_screen.dart';
import 'package:security_311_admin/screens/danger_zones/danger_zones_screen.dart';
import 'package:security_311_admin/screens/emergency/emergency_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadSystemStatistics();
      context.read<SafetyAlertsProvider>().loadAlerts();
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
    final adminProvider = Provider.of<AdminProvider>(context);

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    final isSuperAdmin = adminProvider.isSuperAdmin;

    // Build navigation items based on role
    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Overview',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.emergency),
        label: 'Emergencies',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.map),
        label: 'Zones',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.warning),
        label: 'Alerts',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.report),
        label: 'Reports',
      ),
      if (isSuperAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Users',
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(_selectedIndex, isSuperAdmin)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              adminProvider.refreshAll();
            },
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'broadcast') {
                _showBroadcastDialog(context);
              } else if (value == 'logout') {
                await authProvider.signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'broadcast',
                child: Row(
                  children: [
                    Icon(Icons.campaign, size: 20),
                    SizedBox(width: 8),
                    Text('Broadcast Message'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(context, isSuperAdmin),
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }

  String _getTitle(int index, bool isSuperAdmin) {
    switch (index) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'Emergency Management';
      case 2:
        return 'Danger Zones';
      case 3:
        return 'Safety Alerts';
      case 4:
        return 'Reports';
      case 5:
        return isSuperAdmin ? 'User Management' : 'Admin Dashboard';
      default:
        return 'Admin Dashboard';
    }
  }

  Widget _buildBody(BuildContext context, bool isSuperAdmin) {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab(context);
      case 1:
        return const EmergencyManagementScreen();
      case 2:
        return const DangerZonesScreen();
      case 3:
        return const AlertsManagementScreen();
      case 4:
        return const ReportsManagementScreen();
      case 5:
        return isSuperAdmin
            ? const UsersManagementScreen()
            : _buildOverviewTab(context);
      default:
        return _buildOverviewTab(context);
    }
  }

  void _showBroadcastDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _BroadcastMessageDialog(),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final stats = adminProvider.systemStats;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        await adminProvider.loadSystemStatistics();
        await adminProvider.loadRecentActivity();
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
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
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
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      adminProvider.isSuperAdmin
                          ? Icons.shield
                          : Icons.admin_panel_settings,
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
                          'Welcome, ${adminProvider.isSuperAdmin ? 'Super Admin' : 'Admin'}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Monitor and manage the security system',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildQuickActionCard(
                  context,
                  icon: Icons.map,
                  title: 'Danger Zones',
                  subtitle: 'Mark dangerous areas',
                  color: Colors.red,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                const SizedBox(width: 12),
                _buildQuickActionCard(
                  context,
                  icon: Icons.add_alert,
                  title: 'New Alert',
                  subtitle: 'Create safety alert',
                  color: Colors.orange,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildQuickActionCard(
                  context,
                  icon: Icons.assignment,
                  title: 'Reports',
                  subtitle: 'View crime reports',
                  color: Colors.purple,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
                const SizedBox(width: 12),
                if (adminProvider.isSuperAdmin)
                  _buildQuickActionCard(
                    context,
                    icon: Icons.people,
                    title: 'Users',
                    subtitle: 'Manage users',
                    color: Colors.blue,
                    onTap: () => setState(() => _selectedIndex = 4),
                  )
                else
                  _buildQuickActionCard(
                    context,
                    icon: Icons.campaign,
                    title: 'Broadcast',
                    subtitle: 'Send notification',
                    color: Colors.teal,
                    onTap: () => _showBroadcastDialog(context),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // System Statistics
            Text(
              'System Statistics',
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
                _buildEnhancedStatsCard(
                  context,
                  title: 'Total Users',
                  value: stats['total_users']?.toString() ?? '0',
                  subtitle: '${stats['verified_users'] ?? 0} verified',
                  icon: Icons.people,
                  color: Colors.blue,
                  trend: '+${stats['new_users_week'] ?? 0} this week',
                ),
                _buildEnhancedStatsCard(
                  context,
                  title: 'Active Alerts',
                  value: stats['active_alerts']?.toString() ?? '0',
                  subtitle: '${stats['alerts_last_24h'] ?? 0} today',
                  icon: Icons.warning_amber,
                  color: Colors.orange,
                ),
                _buildEnhancedStatsCard(
                  context,
                  title: 'Pending Reports',
                  value:
                      '${(stats['report_statuses'] as Map?)?['pending'] ?? 0}',
                  subtitle: '${stats['reports_last_24h'] ?? 0} today',
                  icon: Icons.assignment_late,
                  color: Colors.red,
                ),
                _buildEnhancedStatsCard(
                  context,
                  title: 'Missing Reports',
                  value: '${stats['missing_reports_pending'] ?? 0}',
                  subtitle:
                      '${stats['missing_reports_approved'] ?? 0} approved',
                  icon: Icons.person_search,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Emergency Stats
            if (stats['total_emergencies'] != null &&
                stats['total_emergencies'] > 0) ...[
              Text(
                'Emergency Alerts',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildEmergencyStatItem(
                      'Total',
                      stats['total_emergencies']?.toString() ?? '0',
                      Colors.red,
                    ),
                    _buildEmergencyStatItem(
                      'Active',
                      stats['active_emergencies']?.toString() ?? '0',
                      Colors.orange,
                    ),
                    _buildEmergencyStatItem(
                      'Last 24h',
                      stats['emergencies_last_24h']?.toString() ?? '0',
                      Colors.purple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Recent Activity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => adminProvider.loadRecentActivity(limit: 50),
                  icon: const Icon(Icons.more_horiz),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRecentActivitySection(context, adminProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(BuildContext context,
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
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
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
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedStatsCard(BuildContext context,
      {required String title,
      required String value,
      required String subtitle,
      required IconData icon,
      required Color color,
      String? trend}) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
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
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(
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
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.timeline,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No recent activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
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
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: activities.length > 10 ? 10 : activities.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _buildActivityItem(context, activity);
        },
      ),
    );
  }

  Widget _buildActivityItem(
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
              color:
                  getActivityColor(activity['type'] ?? 'info').withOpacity(0.1),
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
                  activity['title'] ?? 'Activity',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['description'] ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatActivityTime(activity['timestamp']),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
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

// Broadcast Message Dialog
class _BroadcastMessageDialog extends StatefulWidget {
  const _BroadcastMessageDialog();

  @override
  State<_BroadcastMessageDialog> createState() =>
      _BroadcastMessageDialogState();
}

class _BroadcastMessageDialogState extends State<_BroadcastMessageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'broadcast';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.campaign, color: Colors.purple),
          SizedBox(width: 8),
          Text('Broadcast Message'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  hintText: 'Enter notification title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                  hintText: 'Enter your message to all users',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'broadcast', child: Text('General Broadcast')),
                  DropdownMenuItem(
                      value: 'announcement', child: Text('Announcement')),
                  DropdownMenuItem(
                      value: 'update', child: Text('System Update')),
                  DropdownMenuItem(
                      value: 'maintenance', child: Text('Maintenance Notice')),
                ],
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _sendBroadcast,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: const Text('Send'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _sendBroadcast() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final adminProvider = context.read<AdminProvider>();
      final success = await adminProvider.broadcastMessage(
        _titleController.text.trim(),
        _messageController.text.trim(),
        type: _selectedType,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Broadcast sent successfully to all users'
                  : 'Failed to send broadcast',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
