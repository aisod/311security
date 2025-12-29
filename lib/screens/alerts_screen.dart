import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_311_user/providers/safety_alerts_provider.dart';
import 'package:security_311_user/providers/missing_reports_provider.dart';
import 'package:security_311_user/models/alert.dart';
import 'package:security_311_user/models/missing_report.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    // Load fresh data when entering screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SafetyAlertsProvider>().loadAlerts();
      context.read<MissingReportsProvider>().loadApprovedReports();
    });
  }

  // Convert SafetyAlert from provider to CommunityAlert for UI
  List<CommunityAlert> _convertAlerts(List<SafetyAlert> alerts) {
    return alerts.map((alert) {
      String category = 'crime_alert';
      if (alert.type.toLowerCase().contains('traffic') || 
          alert.type.toLowerCase().contains('road')) {
        category = 'traffic_alert';
      } else if (alert.type.toLowerCase().contains('lost') || 
                 alert.type.toLowerCase().contains('found')) {
        category = 'lost_found';
      } else if (alert.type.toLowerCase().contains('wanted')) {
        category = 'wanted';
      }
      
      AlertSeverity severity = AlertSeverity.medium;
      if (alert.severity == 'high' || alert.severity == 'critical') {
        severity = AlertSeverity.high;
      } else if (alert.severity == 'low' || alert.severity == 'info') {
        severity = AlertSeverity.low;
      }
      
      return CommunityAlert(
        id: alert.id,
        category: category,
        title: alert.title,
        message: alert.message,
        timestamp: alert.createdAt,
        region: alert.region ?? 'Namibia',
        severity: severity,
        isActive: alert.isActive,
        imageUrl: alert.imageUrls?.isNotEmpty == true ? alert.imageUrls!.first : null,
      );
    }).toList();
  }

  // Convert MissingReport from provider to CommunityAlert for UI
  List<CommunityAlert> _convertMissingReports(List<MissingReport> reports) {
    return reports.map((report) {
      String category = 'lost_found';
      if (report.reportType == MissingReportType.missingPerson) {
        category = 'missing_person';
      } else if (report.reportType == MissingReportType.foundPerson) {
        category = 'lost_found'; // or maybe a distinct 'found' category?
      }

      // Default to high severity for missing persons, medium for others
      AlertSeverity severity = AlertSeverity.medium;
      if (report.reportType == MissingReportType.missingPerson) {
        severity = AlertSeverity.high;
      }

      return CommunityAlert(
        id: report.id,
        category: category,
        title: report.title,
        message: report.description, // Use description as message
        timestamp: report.createdAt,
        region: report.lastSeenLocation ?? 'Unknown Location',
        severity: severity,
        isActive: report.status == MissingReportStatus.approved,
        imageUrl: report.photoUrls?.isNotEmpty == true ? report.photoUrls!.first : null,
      );
    }).toList();
  }

  static const Map<String, AlertCategoryConfig> _categoryConfigs = {
    'crime_alert': AlertCategoryConfig(
      key: 'crime_alert',
      title: 'Crime Alerts',
      subtitle: 'Police & safety updates',
      icon: Icons.local_police,
      color: Color(0xFFD32F2F),
      defaultImageUrl:
          'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=900&q=80',
    ),
    'missing_person': AlertCategoryConfig(
      key: 'missing_person',
      title: 'Missing Persons',
      subtitle: 'Help locate missing individuals',
      icon: Icons.person_search,
      color: Color(0xFFE65100), // Deep Orange
      defaultImageUrl:
          'https://images.unsplash.com/photo-1455390582262-044cdead277a?auto=format&fit=crop&w=900&q=80',
    ),
    'traffic_alert': AlertCategoryConfig(
      key: 'traffic_alert',
      title: 'Traffic Alerts',
      subtitle: 'Road closures & accidents',
      icon: Icons.traffic,
      color: Color(0xFFF57C00),
      defaultImageUrl:
          'https://images.unsplash.com/photo-1465447142348-e9952c393450?auto=format&fit=crop&w=900&q=80',
    ),
    'lost_found': AlertCategoryConfig(
      key: 'lost_found',
      title: 'Lost & Found',
      subtitle: 'Recovered items & notices',
      icon: Icons.find_in_page,
      color: Color(0xFF00796B),
      defaultImageUrl:
          'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?auto=format&fit=crop&w=900&q=80',
    ),
    'wanted': AlertCategoryConfig(
      key: 'wanted',
      title: 'Wanted',
      subtitle: 'Persons & vehicles of interest',
      icon: Icons.search,
      color: Color(0xFF512DA8),
      defaultImageUrl:
          'https://images.unsplash.com/photo-1516223725307-6f76a04b2356?auto=format&fit=crop&w=900&q=80',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer2<SafetyAlertsProvider, MissingReportsProvider>(
      builder: (context, alertsProvider, missingProvider, child) {
        final safetyAlerts = _convertAlerts(alertsProvider.allAlerts);
        final missingReports = _convertMissingReports(missingProvider.approvedReports);
        
        // Combine and sort by timestamp descending
        final allAlerts = [...safetyAlerts, ...missingReports]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        final isLoading = alertsProvider.isLoading || missingProvider.isLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Safety Alerts'),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: () {
                  _showNotificationSettings(context);
                },
                icon: const Icon(Icons.settings),
                tooltip: 'Alert Settings',
              ),
            ],
          ),
          body: isLoading && allAlerts.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _ActiveAlertsTab(
                  alerts: allAlerts,
                  initialCategory: widget.initialCategory,
                  onRefresh: () async {
                    await Future.wait([
                      alertsProvider.loadAlerts(),
                      missingProvider.loadApprovedReports(),
                    ]);
                  },
                ),
        );
      },
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _NotificationSettingsSheet(),
    );
  }
}

class _ActiveAlertsTab extends StatefulWidget {
  final List<CommunityAlert> alerts;
  final String? initialCategory;
  final Future<void> Function()? onRefresh;

  const _ActiveAlertsTab({
    required this.alerts, 
    this.initialCategory,
    this.onRefresh,
  });

  @override
  State<_ActiveAlertsTab> createState() => _ActiveAlertsTabState();
}

class _ActiveAlertsTabState extends State<_ActiveAlertsTab> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final allAlerts = widget.alerts;
    final filteredAlerts = _selectedCategory == null
        ? allAlerts
        : allAlerts
            .where((alert) => alert.category == _selectedCategory)
            .toList();

    final content = <Widget>[
      _buildQuickShortcuts(context),
      const SizedBox(height: 24),
    ];

    if (allAlerts.isEmpty) {
      content.add(_buildEmptyState(
        context,
        icon: Icons.verified_user,
        message:
            'All clear for now. We will notify you immediately when a new alert is published.',
      ));
    } else if (filteredAlerts.isEmpty) {
      final selectedConfig = _selectedCategory != null
          ? _getCategoryConfig(_selectedCategory!)
          : null;
      content.add(_buildEmptyState(
        context,
        icon: selectedConfig?.icon ?? Icons.notifications_active_outlined,
        message:
            'No ${selectedConfig?.title.toLowerCase() ?? 'alerts'} are active right now. Check back soon.',
      ));
    } else {
      content.addAll(_buildGroupedSections(context, filteredAlerts));
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (widget.onRefresh != null) {
          await widget.onRefresh!();
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: content,
      ),
    );
  }

  Widget _buildQuickShortcuts(BuildContext context) {
    final theme = Theme.of(context);
    final configs = _AlertsScreenState._categoryConfigs.values.toList();
    final totalAlerts = widget.alerts.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Shortcuts',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Jump to specific alert streams curated by the 3:11 control room.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 16),
            itemCount: configs.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildShortcutCard(
                  context: context,
                  title: 'All Alerts',
                  subtitle: '$totalAlerts active',
                  icon: Icons.dashboard_customize_outlined,
                  color: theme.colorScheme.primary,
                  imageUrl: null,
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                );
              }

              final config = configs[index - 1];
              final count = widget.alerts
                  .where((alert) => alert.category == config.key)
                  .length;

              return _buildShortcutCard(
                context: context,
                title: config.title,
                subtitle: '$count active',
                icon: config.icon,
                color: config.color,
                imageUrl: config.defaultImageUrl,
                isSelected: _selectedCategory == config.key,
                onTap: () => setState(() => _selectedCategory = config.key),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    String? imageUrl,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isSelected ? 0.35 : 0.18),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned.fill(
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        color:
                            Colors.black
                                .withValues(alpha: isSelected ? 0.25 : 0.4),
                        colorBlendMode: BlendMode.darken,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withValues(alpha: 0.9),
                                color.withValues(alpha: 0.6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withValues(alpha: 0.9),
                              color.withValues(alpha: 0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.black.withValues(alpha: 0.65),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 28,
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedSections(
      BuildContext context, List<CommunityAlert> alerts) {
    final sections = <Widget>[];
    final theme = Theme.of(context);

    for (final entry in _AlertsScreenState._categoryConfigs.entries) {
      final categoryAlerts =
          alerts.where((alert) => alert.category == entry.key).toList();
      if (categoryAlerts.isEmpty) continue;

      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.value.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              entry.value.subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 12),
            ...categoryAlerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CommunityAlertCard(
                  alert: alert,
                  categoryConfig: entry.value,
                  onTap: () => _showAlertDetails(context, alert),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    return sections;
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String message,
  }) {
    final theme = Theme.of(context);
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 42,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlertDetails(BuildContext context, CommunityAlert alert) {
    final categoryConfig = _getCategoryConfig(alert.category);
    final severityColor = _getSeverityColor(alert.severity);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              categoryConfig.icon,
              color: categoryConfig.color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                alert.title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    alert.imageUrl ?? categoryConfig.defaultImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: categoryConfig.color.withValues(alpha: 0.15),
                      child: Center(
                        child: Icon(
                          categoryConfig.icon,
                          size: 36,
                          color: categoryConfig.color,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(alert.message),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimestamp(alert.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      alert.severity.name.toUpperCase(),
                      style: TextStyle(
                        color: severityColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    alert.region,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (alert.category == 'crime_alert' || alert.category == 'wanted')
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: categoryConfig.color,
              ),
              onPressed: () {
                Navigator.pop(context);
                _showEmergencyServices(context);
              },
              child: const Text('Emergency Services'),
            ),
        ],
      ),
    );
  }

  void _showEmergencyServices(BuildContext context) {
    const String currentLocation = "Windhoek, Khomas Region";
    final isInWindhoek = currentLocation.toLowerCase().contains('windhoek');

    final emergencyNumbers = <Widget>[
      _buildEmergencyServiceCard(
        context: context,
        icon: Icons.local_police,
        title: 'Namibian Police',
        number: '10111',
        description: 'General police emergency',
        color: Colors.blue,
      ),
    ];

    if (isInWindhoek) {
      emergencyNumbers.addAll([
        const SizedBox(height: 8),
        _buildEmergencyServiceCard(
          context: context,
          icon: Icons.shield,
          title: 'Windhoek City Police',
          number: '061290-2888',
          description: 'City police services',
          color: Colors.indigo,
        ),
      ]);
    }

    emergencyNumbers.addAll([
      const SizedBox(height: 8),
      _buildEmergencyServiceCard(
        context: context,
        icon: Icons.local_hospital,
        title: 'Emergency Medical',
        number: '2032276',
        description: 'Ambulance & medical emergency',
        color: Colors.red,
      ),
      const SizedBox(height: 8),
      _buildEmergencyServiceCard(
        context: context,
        icon: Icons.local_fire_department,
        title: 'Fire Department',
        number: '061290111',
        description: 'Fire emergency services',
        color: Colors.orange,
      ),
      const SizedBox(height: 8),
      _buildEmergencyServiceCard(
        context: context,
        icon: Icons.security,
        title: '3:11 Emergency',
        number: '311',
        description: '24/7 security assistance',
        color: Theme.of(context).colorScheme.primary,
      ),
    ]);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = Theme.of(context);

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          titlePadding: const EdgeInsets.all(20),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emergency,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isInWindhoek
                    ? 'Emergency Services - Windhoek'
                    : 'Emergency Services',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap any service to call immediately',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  ...emergencyNumbers,
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmergencyServiceCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String number,
    required String description,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.phone, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Calling $title: $number'),
                ],
              ),
              backgroundColor: color,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.03),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      number,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.phone,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AlertCategoryConfig _getCategoryConfig(String category) {
    return _AlertsScreenState._categoryConfigs[category] ??
        _AlertsScreenState._categoryConfigs.values.first;
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.high:
        return const Color(0xFFD32F2F);
      case AlertSeverity.medium:
        return const Color(0xFFF57C00);
      case AlertSeverity.low:
        return const Color(0xFF388E3C);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class AlertCategoryConfig {
  const AlertCategoryConfig({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.defaultImageUrl,
  });

  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String defaultImageUrl;
}

class _NotificationSettingsSheet extends StatefulWidget {
  const _NotificationSettingsSheet();

  @override
  State<_NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends State<_NotificationSettingsSheet> {
  bool _emergencyAlerts = true;
  bool _communityAlerts = true;
  bool _weatherAlerts = true;
  bool _trafficAlerts = true;
  double _alertRadius = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Notification Settings',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alert Types',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Emergency Alerts'),
                    subtitle: const Text('Critical safety notifications'),
                    value: _emergencyAlerts,
                    onChanged: (value) =>
                        setState(() => _emergencyAlerts = value),
                  ),
                  SwitchListTile(
                    title: const Text('Community Alerts'),
                    subtitle: const Text('Local safety information'),
                    value: _communityAlerts,
                    onChanged: (value) =>
                        setState(() => _communityAlerts = value),
                  ),
                  SwitchListTile(
                    title: const Text('Weather Alerts'),
                    subtitle: const Text('Severe weather warnings'),
                    value: _weatherAlerts,
                    onChanged: (value) =>
                        setState(() => _weatherAlerts = value),
                  ),
                  SwitchListTile(
                    title: const Text('Traffic Alerts'),
                    subtitle: const Text('Road closures and traffic updates'),
                    value: _trafficAlerts,
                    onChanged: (value) =>
                        setState(() => _trafficAlerts = value),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Alert Radius',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Receive alerts within ${_alertRadius.round()} km of your location',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _alertRadius,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: '${_alertRadius.round()} km',
                    onChanged: (value) => setState(() => _alertRadius = value),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Alert settings saved successfully'),
                            backgroundColor: Color(0xFF388E3C),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Save Alert Settings'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Data Models
enum AlertSeverity { low, medium, high }

class CommunityAlert {
  final String id;
  final String category;
  final String title;
  final String message;
  final DateTime timestamp;
  final String region;
  final AlertSeverity severity;
  final bool isActive;
  final String? imageUrl;

  CommunityAlert({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.region,
    required this.severity,
    required this.isActive,
    this.imageUrl,
  });
}

// UI Components
class CommunityAlertCard extends StatelessWidget {
  final CommunityAlert alert;
  final AlertCategoryConfig categoryConfig;
  final VoidCallback onTap;

  const CommunityAlertCard({
    super.key,
    required this.alert,
    required this.categoryConfig,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityColor = _getSeverityColor(alert.severity);
    final imageUrl = alert.imageUrl ?? categoryConfig.defaultImageUrl;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: categoryConfig.color.withValues(alpha: 0.08),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: categoryConfig.color.withValues(alpha: 0.12),
                      child: Center(
                        child: Icon(
                          categoryConfig.icon,
                          size: 48,
                          color: categoryConfig.color,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _buildCategoryPill(categoryConfig),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            categoryConfig.icon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            categoryConfig.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alert.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTimestamp(alert.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          alert.region,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: severityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          alert.severity.name.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: severityColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill(AlertCategoryConfig config) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        config.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.high:
        return const Color(0xFFD32F2F);
      case AlertSeverity.medium:
        return const Color(0xFFF57C00);
      case AlertSeverity.low:
        return const Color(0xFF388E3C);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
