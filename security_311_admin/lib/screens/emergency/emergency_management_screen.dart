import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_311_admin/providers/admin/admin_provider.dart';
import 'package:security_311_admin/models/emergency_alert.dart';
import 'package:intl/intl.dart';

class EmergencyManagementScreen extends StatefulWidget {
  const EmergencyManagementScreen({super.key});

  @override
  State<EmergencyManagementScreen> createState() => _EmergencyManagementScreenState();
}

class _EmergencyManagementScreenState extends State<EmergencyManagementScreen> {
  bool _showActiveOnly = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadEmergencyAlerts(activeOnly: _showActiveOnly);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminProvider = context.watch<AdminProvider>();
    final alerts = adminProvider.emergencyAlerts;

    return Column(
      children: [
        // Header / Filters
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.surface,
          child: Row(
            children: [
              Text(
                'Emergency Alerts',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              FilterChip(
                label: const Text('Active Only'),
                selected: _showActiveOnly,
                onSelected: (value) {
                  setState(() => _showActiveOnly = value);
                  context.read<AdminProvider>().loadEmergencyAlerts(activeOnly: value);
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => context.read<AdminProvider>().loadEmergencyAlerts(activeOnly: _showActiveOnly),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: adminProvider.isLoadingEmergencyAlerts
              ? const Center(child: CircularProgressIndicator())
              : alerts.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        return _EmergencyAlertCard(alert: alerts[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emergency_outlined,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Emergency Alerts',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showActiveOnly
                ? 'No active emergencies at the moment'
                : 'No emergency history found',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyAlertCard extends StatelessWidget {
  final EmergencyAlert alert;

  const _EmergencyAlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCritical = alert.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCritical ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCritical
            ? BorderSide(color: theme.colorScheme.error, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showDetails(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCritical
                          ? theme.colorScheme.error.withOpacity(0.1)
                          : theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.emergency,
                      color: isCritical ? theme.colorScheme.error : theme.colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatType(alert.type),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isCritical ? theme.colorScheme.error : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, HH:mm').format(alert.triggeredAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (alert.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withOpacity(0.5)),
                      ),
                      child: Text(
                        'RESOLVED',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // User Information Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Information',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // User ID
                    Row(
                      children: [
                        Icon(
                          Icons.badge,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ID: ${alert.userId}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Phone Number
                    if (alert.userPhoneNumber != null && alert.userPhoneNumber!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              alert.userPhoneNumber!,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'No phone number',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    // User Name
                    if (alert.userFullName != null && alert.userFullName!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              alert.userFullName!,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            alert.locationDescription ?? 
                            (alert.latitude != null && alert.longitude != null
                                ? '${alert.latitude!.toStringAsFixed(6)}, ${alert.longitude!.toStringAsFixed(6)}'
                                : 'Location not available'),
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (alert.latitude != null && alert.longitude != null) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(
                          'Coordinates: ${alert.latitude!.toStringAsFixed(6)}, ${alert.longitude!.toStringAsFixed(6)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (alert.isActive)
                    ElevatedButton.icon(
                      onPressed: () => _markResolved(context),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Mark Resolved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatType(String type) {
    return type.split('_').map((word) => 
      word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
    ).join(' ');
  }

  void _showDetails(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.emergency,
              color: theme.colorScheme.error,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _formatType(alert.type),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Information Section - Prominently Displayed
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'User Details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      Icons.badge,
                      'User ID',
                      alert.userId,
                      isMonospace: true,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      context,
                      Icons.phone,
                      'Phone Number',
                      alert.userPhoneNumber ?? 'Not available',
                      isImportant: true,
                    ),
                    const SizedBox(height: 8),
                    if (alert.userFullName != null && alert.userFullName!.isNotEmpty)
                      _buildDetailRow(
                        context,
                        Icons.person_outline,
                        'Full Name',
                        alert.userFullName!,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Location Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Location',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alert.locationDescription ?? 'Location description not available',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (alert.latitude != null && alert.longitude != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Coordinates:',
                        style: theme.textTheme.labelSmall,
                      ),
                      Text(
                        '${alert.latitude!.toStringAsFixed(6)}, ${alert.longitude!.toStringAsFixed(6)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Alert Information
              _buildDetailRow(
                context,
                Icons.info_outline,
                'Status',
                alert.status.toUpperCase(),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                Icons.access_time,
                'Triggered At',
                DateFormat('yyyy-MM-dd HH:mm:ss').format(alert.triggeredAt),
              ),
              if (alert.resolvedAt != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                  context,
                  Icons.check_circle_outline,
                  'Resolved At',
                  DateFormat('yyyy-MM-dd HH:mm:ss').format(alert.resolvedAt!),
                ),
              ],
              if (alert.description != null && alert.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Description:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.description!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (alert.isActive)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _markResolved(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Resolve', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isMonospace = false,
    bool isImportant = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isImportant
              ? theme.colorScheme.error
              : theme.colorScheme.onSurface.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: isMonospace ? 'monospace' : null,
                  fontWeight: isImportant ? FontWeight.bold : null,
                  color: isImportant ? theme.colorScheme.error : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _markResolved(BuildContext context) async {
    final success = await context.read<AdminProvider>().updateEmergencyAlertStatus(
      alert.id,
      status: 'resolved',
      isActive: false,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Alert marked as resolved' : 'Failed to update alert'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
