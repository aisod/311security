import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_311_admin/providers/admin/admin_provider.dart';
import 'package:intl/intl.dart';

class AlertsManagementScreen extends StatefulWidget {
  const AlertsManagementScreen({super.key});

  @override
  State<AlertsManagementScreen> createState() => _AlertsManagementScreenState();
}

class _AlertsManagementScreenState extends State<AlertsManagementScreen> {
  String? _selectedType;
  String? _selectedSeverity;
  bool? _activeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadSafetyAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminProvider = context.watch<AdminProvider>();
    final alerts = _filterAlerts(adminProvider.safetyAlerts);

    return Scaffold(
      body: Column(
        children: [
          // Filters
          _buildFilters(context),
          
          // Alerts list
          Expanded(
            child: adminProvider.isLoadingAlerts
                ? const Center(child: CircularProgressIndicator())
                : alerts.isEmpty
                    ? _buildEmptyState(theme)
                    : RefreshIndicator(
                        onRefresh: () => adminProvider.loadSafetyAlerts(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: alerts.length,
                          itemBuilder: (context, index) {
                            return _buildAlertCard(context, alerts[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAlertDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Alert'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Type filter
            _buildFilterChip(
              label: _selectedType ?? 'All Types',
              isSelected: _selectedType != null,
              onTap: () => _showTypeFilterDialog(context),
            ),
            const SizedBox(width: 8),
            // Severity filter
            _buildFilterChip(
              label: _selectedSeverity ?? 'All Severities',
              isSelected: _selectedSeverity != null,
              onTap: () => _showSeverityFilterDialog(context),
            ),
            const SizedBox(width: 8),
            // Active filter
            _buildFilterChip(
              label: _activeFilter == null
                  ? 'All Status'
                  : _activeFilter!
                      ? 'Active'
                      : 'Inactive',
              isSelected: _activeFilter != null,
              onTap: () => _showStatusFilterDialog(context),
            ),
            const SizedBox(width: 8),
            // Clear filters
            if (_selectedType != null || _selectedSeverity != null || _activeFilter != null)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedType = null;
                    _selectedSeverity = null;
                    _activeFilter = null;
                  });
                },
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Clear'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterAlerts(List<Map<String, dynamic>> alerts) {
    return alerts.where((alert) {
      if (_selectedType != null && alert['type'] != _selectedType) {
        return false;
      }
      if (_selectedSeverity != null && alert['severity'] != _selectedSeverity) {
        return false;
      }
      if (_activeFilter != null && alert['is_active'] != _activeFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Alerts Found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new alert to notify users',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, Map<String, dynamic> alert) {
    final theme = Theme.of(context);
    final isActive = alert['is_active'] == true;
    final severity = alert['severity'] as String? ?? 'info';
    final type = alert['type'] as String? ?? 'general';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getSeverityColor(severity).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showAlertDetails(context, alert),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(severity).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getTypeIcon(type),
                      color: _getSeverityColor(severity),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert['title'] ?? 'No Title',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildBadge(
                              _capitalizeFirst(type),
                              _getTypeColor(type),
                            ),
                            const SizedBox(width: 8),
                            _buildBadge(
                              _capitalizeFirst(severity),
                              _getSeverityColor(severity),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isActive,
                    onChanged: (value) => _toggleAlertStatus(alert, value),
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Message
              Text(
                alert['message'] ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(alert['created_at']),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _showAlertDetails(context, alert),
                        icon: const Icon(Icons.visibility, size: 20),
                        tooltip: 'View',
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        onPressed: () => _confirmDeleteAlert(context, alert),
                        icon: Icon(Icons.delete_outline, size: 20, color: Colors.red[400]),
                        tooltip: 'Delete',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showTypeFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Type'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() => _selectedType = null);
              Navigator.pop(context);
            },
            child: const Text('All Types'),
          ),
          for (final type in ['crime', 'emergency', 'weather', 'traffic', 'community', 'general'])
            SimpleDialogOption(
              onPressed: () {
                setState(() => _selectedType = type);
                Navigator.pop(context);
              },
              child: Text(_capitalizeFirst(type)),
            ),
        ],
      ),
    );
  }

  void _showSeverityFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Severity'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() => _selectedSeverity = null);
              Navigator.pop(context);
            },
            child: const Text('All Severities'),
          ),
          for (final severity in ['critical', 'warning', 'info'])
            SimpleDialogOption(
              onPressed: () {
                setState(() => _selectedSeverity = severity);
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getSeverityColor(severity),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_capitalizeFirst(severity)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showStatusFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Status'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() => _activeFilter = null);
              Navigator.pop(context);
            },
            child: const Text('All Status'),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _activeFilter = true);
              Navigator.pop(context);
            },
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text('Active'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _activeFilter = false);
              Navigator.pop(context);
            },
            child: const Row(
              children: [
                Icon(Icons.cancel, color: Colors.grey, size: 20),
                SizedBox(width: 8),
                Text('Inactive'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreateAlertDialog(),
    );
  }

  void _showAlertDetails(BuildContext context, Map<String, dynamic> alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AlertDetailsSheet(alert: alert),
    );
  }

  Future<void> _toggleAlertStatus(Map<String, dynamic> alert, bool isActive) async {
    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.updateSafetyAlertStatus(
      alert['id'],
      isActive,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Alert ${isActive ? 'activated' : 'deactivated'}'
                : 'Failed to update alert',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _confirmDeleteAlert(BuildContext context, Map<String, dynamic> alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alert'),
        content: Text('Are you sure you want to delete "${alert['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final adminProvider = context.read<AdminProvider>();
              final success = await adminProvider.deleteSafetyAlert(alert['id']);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Alert deleted' : 'Failed to delete alert'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red[700]!;
      case 'warning':
        return Colors.orange[700]!;
      case 'info':
      default:
        return Colors.blue[600]!;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'crime':
        return Colors.red;
      case 'emergency':
        return Colors.purple;
      case 'weather':
        return Colors.blue;
      case 'traffic':
        return Colors.orange;
      case 'community':
        return Colors.teal;
      case 'general':
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'crime':
        return Icons.gavel;
      case 'emergency':
        return Icons.emergency;
      case 'weather':
        return Icons.cloud;
      case 'traffic':
        return Icons.traffic;
      case 'community':
        return Icons.people;
      case 'general':
      default:
        return Icons.info;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('MMM d, yyyy HH:mm').format(dateTime);
    } catch (e) {
      return 'Unknown';
    }
  }
}

// Create Alert Dialog
class _CreateAlertDialog extends StatefulWidget {
  const _CreateAlertDialog();

  @override
  State<_CreateAlertDialog> createState() => _CreateAlertDialogState();
}

class _CreateAlertDialogState extends State<_CreateAlertDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _selectedType = 'general';
  String _selectedSeverity = 'info';
  String _selectedPriority = 'medium';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Alert'),
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
                ),
                maxLines: 3,
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
                items: ['crime', 'emergency', 'weather', 'traffic', 'community', 'general']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type[0].toUpperCase() + type.substring(1)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedSeverity,
                decoration: const InputDecoration(
                  labelText: 'Severity',
                  border: OutlineInputBorder(),
                ),
                items: ['critical', 'warning', 'info']
                    .map((severity) => DropdownMenuItem(
                          value: severity,
                          child: Text(severity[0].toUpperCase() + severity.substring(1)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedSeverity = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: ['critical', 'high', 'medium', 'low']
                    .map((priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(priority[0].toUpperCase() + priority.substring(1)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedPriority = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Windhoek Central',
                ),
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
        ElevatedButton(
          onPressed: _isLoading ? null : _createAlert,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createAlert() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final adminProvider = context.read<AdminProvider>();
      final success = await adminProvider.createSafetyAlert(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        type: _selectedType,
        severity: _selectedSeverity,
        priority: _selectedPriority,
        locationDescription: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Alert created successfully' : 'Failed to create alert'),
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

// Alert Details Sheet
class _AlertDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> alert;

  const _AlertDetailsSheet({required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severity = alert['severity'] as String? ?? 'info';
    final type = alert['type'] as String? ?? 'general';

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(severity).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getTypeIcon(type),
                      color: _getSeverityColor(severity),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert['title'] ?? 'No Title',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildChip(type, _getTypeColor(type)),
                            const SizedBox(width: 8),
                            _buildChip(severity, _getSeverityColor(severity)),
                            const SizedBox(width: 8),
                            _buildChip(
                              alert['is_active'] == true ? 'Active' : 'Inactive',
                              alert['is_active'] == true ? Colors.green : Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Message
              _buildSection(
                context,
                'Message',
                Icons.message,
                alert['message'] ?? 'No message',
              ),
              const SizedBox(height: 16),
              
              // Location
              if (alert['location_description'] != null)
                _buildSection(
                  context,
                  'Location',
                  Icons.location_on,
                  alert['location_description'],
                ),
              if (alert['location_description'] != null)
                const SizedBox(height: 16),
              
              // Priority
              _buildSection(
                context,
                'Priority',
                Icons.priority_high,
                _capitalize(alert['priority'] as String? ?? 'medium'),
              ),
              const SizedBox(height: 16),
              
              // Created
              _buildSection(
                context,
                'Created',
                Icons.schedule,
                _formatDate(alert['created_at']),
              ),
              
              // Region
              if (alert['region'] != null) ...[
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  'Region',
                  Icons.map,
                  alert['region']['name'] ?? 'Unknown',
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, String content) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            content,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _capitalize(text),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('EEEE, MMMM d, yyyy \'at\' HH:mm').format(dateTime);
    } catch (e) {
      return 'Unknown';
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red[700]!;
      case 'warning':
        return Colors.orange[700]!;
      case 'info':
      default:
        return Colors.blue[600]!;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'crime':
        return Colors.red;
      case 'emergency':
        return Colors.purple;
      case 'weather':
        return Colors.blue;
      case 'traffic':
        return Colors.orange;
      case 'community':
        return Colors.teal;
      case 'general':
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'crime':
        return Icons.gavel;
      case 'emergency':
        return Icons.emergency;
      case 'weather':
        return Icons.cloud;
      case 'traffic':
        return Icons.traffic;
      case 'community':
        return Icons.people;
      case 'general':
      default:
        return Icons.info;
    }
  }
}


