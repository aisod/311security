import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:security_311_admin/providers/admin/admin_provider.dart';
import 'package:security_311_admin/models/crime_report.dart';
import 'package:security_311_admin/models/missing_report.dart';
import 'package:intl/intl.dart';

class ReportsManagementScreen extends StatefulWidget {
  const ReportsManagementScreen({super.key});

  @override
  State<ReportsManagementScreen> createState() => _ReportsManagementScreenState();
}

class _ReportsManagementScreenState extends State<ReportsManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStatus;
  String? _selectedSeverity;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = context.read<AdminProvider>();
      adminProvider.loadCrimeReports();
      adminProvider.loadMissingReports();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Tab bar
        Container(
          color: theme.colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(
                icon: Icon(Icons.report),
                text: 'Crime Reports',
              ),
              Tab(
                icon: Icon(Icons.person_search),
                text: 'Missing Reports',
              ),
            ],
          ),
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _CrimeReportsTab(
                selectedStatus: _selectedStatus,
                selectedSeverity: _selectedSeverity,
                onStatusChanged: (status) => setState(() => _selectedStatus = status),
                onSeverityChanged: (severity) => setState(() => _selectedSeverity = severity),
              ),
              const _MissingReportsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// Crime Reports Tab
class _CrimeReportsTab extends StatefulWidget {
  final String? selectedStatus;
  final String? selectedSeverity;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onSeverityChanged;

  const _CrimeReportsTab({
    required this.selectedStatus,
    required this.selectedSeverity,
    required this.onStatusChanged,
    required this.onSeverityChanged,
  });

  @override
  State<_CrimeReportsTab> createState() => _CrimeReportsTabState();
}

class _CrimeReportsTabState extends State<_CrimeReportsTab> {
  bool _isMapView = false;
  GoogleMapController? _mapController;
  final LatLng _defaultCenter = const LatLng(-22.5609, 17.0658); // Windhoek

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminProvider = context.watch<AdminProvider>();
    final reports = _filterReports(adminProvider.crimeReports);

    return Column(
      children: [
        // Filters & View Toggle
        _buildFilters(context),
        
        // Reports content
        Expanded(
          child: adminProvider.isLoadingCrimeReports
              ? const Center(child: CircularProgressIndicator())
              : reports.isEmpty
                  ? _buildEmptyState(theme)
                  : _isMapView
                      ? _buildMapView(reports)
                      : _buildListView(reports, adminProvider),
        ),
      ],
    );
  }

  Widget _buildListView(List<CrimeReport> reports, AdminProvider adminProvider) {
    return RefreshIndicator(
      onRefresh: () => adminProvider.loadCrimeReports(
        status: widget.selectedStatus,
        severity: widget.selectedSeverity,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          return _CrimeReportCard(report: reports[index]);
        },
      ),
    );
  }

  Widget _buildMapView(List<CrimeReport> reports) {
    // Filter reports with valid coordinates
    final reportsWithLocation = reports
        .where((r) => r.latitude != null && r.longitude != null)
        .toList();

    final markers = reportsWithLocation.map((report) {
      return Marker(
        markerId: MarkerId(report.id),
        position: LatLng(report.latitude!, report.longitude!),
        infoWindow: InfoWindow(
          title: report.title,
          snippet: '${report.crimeType} - ${report.status}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getSeverityHue(report.severity),
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => _ReportDetailsSheet(report: report),
          );
        },
      );
    }).toSet();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _defaultCenter,
        zoom: 12,
      ),
      onMapCreated: (controller) => _mapController = controller,
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
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
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Status filter
                  _FilterChip(
                    label: widget.selectedStatus ?? 'All Status',
                    isSelected: widget.selectedStatus != null,
                    onTap: () => _showStatusFilter(context),
                  ),
                  const SizedBox(width: 8),
                  // Severity filter
                  _FilterChip(
                    label: widget.selectedSeverity ?? 'All Severity',
                    isSelected: widget.selectedSeverity != null,
                    onTap: () => _showSeverityFilter(context),
                  ),
                  const SizedBox(width: 8),
                  // Clear filters
                  if (widget.selectedStatus != null || widget.selectedSeverity != null)
                    TextButton.icon(
                      onPressed: () {
                        widget.onStatusChanged(null);
                        widget.onSeverityChanged(null);
                        context.read<AdminProvider>().loadCrimeReports();
                      },
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Clear'),
                    ),
                ],
              ),
            ),
          ),
          // View Toggle
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.list,
                    color: !_isMapView ? theme.colorScheme.primary : null,
                  ),
                  onPressed: () => setState(() => _isMapView = false),
                  tooltip: 'List View',
                ),
                IconButton(
                  icon: Icon(
                    Icons.map,
                    color: _isMapView ? theme.colorScheme.primary : null,
                  ),
                  onPressed: () => setState(() => _isMapView = true),
                  tooltip: 'Map View',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<CrimeReport> _filterReports(List<CrimeReport> reports) {
    return reports.where((report) {
      if (widget.selectedStatus != null && report.status != widget.selectedStatus) {
        return false;
      }
      if (widget.selectedSeverity != null && report.severity != widget.selectedSeverity) {
        return false;
      }
      return true;
    }).toList();
  }

  void _showStatusFilter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filter by Status'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              widget.onStatusChanged(null);
              context.read<AdminProvider>().loadCrimeReports(severity: widget.selectedSeverity);
              Navigator.pop(context);
            },
            child: const Text('All Status'),
          ),
          for (final status in ['pending', 'investigating', 'resolved', 'closed'])
            SimpleDialogOption(
              onPressed: () {
                widget.onStatusChanged(status);
                context.read<AdminProvider>().loadCrimeReports(
                  status: status,
                  severity: widget.selectedSeverity,
                );
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_capitalize(status)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showSeverityFilter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filter by Severity'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              widget.onSeverityChanged(null);
              context.read<AdminProvider>().loadCrimeReports(status: widget.selectedStatus);
              Navigator.pop(context);
            },
            child: const Text('All Severity'),
          ),
          for (final severity in ['critical', 'high', 'medium', 'low'])
            SimpleDialogOption(
              onPressed: () {
                widget.onSeverityChanged(severity);
                context.read<AdminProvider>().loadCrimeReports(
                  status: widget.selectedStatus,
                  severity: severity,
                );
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
                  Text(_capitalize(severity)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Reports Found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crime reports will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'investigating':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red[700]!;
      case 'high':
        return Colors.orange[700]!;
      case 'medium':
        return Colors.amber[700]!;
      case 'low':
        return Colors.blue[600]!;
      default:
        return Colors.grey;
    }
  }

  double _getSeverityHue(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return BitmapDescriptor.hueRed;
      case 'high':
        return BitmapDescriptor.hueOrange;
      case 'medium':
        return BitmapDescriptor.hueYellow;
      case 'low':
        return BitmapDescriptor.hueAzure;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

// Crime Report Card
class _CrimeReportCard extends StatelessWidget {
  final CrimeReport report;

  const _CrimeReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getStatusColor(report.status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showReportDetails(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getCrimeTypeColor(report.crimeType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCrimeTypeIcon(report.crimeType),
                      color: _getCrimeTypeColor(report.crimeType),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildBadge(_capitalize(report.crimeType), _getCrimeTypeColor(report.crimeType)),
                            const SizedBox(width: 8),
                            _buildBadge(_capitalize(report.severity), _getSeverityColor(report.severity)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(report.status),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                report.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Location & Date
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${report.city}, ${report.region}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(report.incidentDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Reporter & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!report.isAnonymous && report.reporterName != null)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          child: Text(
                            report.reporterName![0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          report.reporterName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_off,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Anonymous',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _showUpdateStatusDialog(context),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Update'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
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

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
        ),
      ),
      child: Text(
        _capitalize(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showReportDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ReportDetailsSheet(report: report),
    );
  }

  void _showUpdateStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _UpdateReportStatusDialog(report: report),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'investigating':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red[700]!;
      case 'high':
        return Colors.orange[700]!;
      case 'medium':
        return Colors.amber[700]!;
      case 'low':
        return Colors.blue[600]!;
      default:
        return Colors.grey;
    }
  }

  Color _getCrimeTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'theft':
        return Colors.orange;
      case 'assault':
        return Colors.red;
      case 'burglary':
        return Colors.brown;
      case 'vandalism':
        return Colors.purple;
      case 'fraud':
        return Colors.indigo;
      case 'robbery':
        return Colors.deepOrange;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getCrimeTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'theft':
        return Icons.shopping_bag;
      case 'assault':
        return Icons.sports_mma;
      case 'burglary':
        return Icons.home;
      case 'vandalism':
        return Icons.broken_image;
      case 'fraud':
        return Icons.attach_money;
      case 'robbery':
        return Icons.warning;
      default:
        return Icons.report;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

// Report Details Sheet
class _ReportDetailsSheet extends StatelessWidget {
  final CrimeReport report;

  const _ReportDetailsSheet({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
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
              Text(
                report.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              // Status badges
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip('Status: ${_capitalize(report.status)}', _getStatusColor(report.status)),
                  _buildChip('Severity: ${_capitalize(report.severity)}', _getSeverityColor(report.severity)),
                  _buildChip(report.crimeType, _getCrimeTypeColor(report.crimeType)),
                ],
              ),
              const SizedBox(height: 24),

              // Description
              _buildSection(context, 'Description', Icons.description, report.description),
              const SizedBox(height: 16),

              // Location
              _buildSection(
                context,
                'Location',
                Icons.location_on,
                '${report.city}, ${report.region}${report.locationDescription != null ? '\n${report.locationDescription}' : ''}',
              ),
              const SizedBox(height: 16),

              // Incident Date
              _buildSection(
                context,
                'Incident Date',
                Icons.calendar_today,
                DateFormat('EEEE, MMMM d, yyyy').format(report.incidentDate),
              ),
              const SizedBox(height: 16),

              // Reporter Info
              if (!report.isAnonymous && report.reporterName != null) ...[
                _buildSection(
                  context,
                  'Reporter',
                  Icons.person,
                  '${report.reporterName}\n${report.reporterPhone ?? ''}\n${report.reporterEmail ?? ''}',
                ),
                const SizedBox(height: 16),
              ],

              // Assigned Officer
              if (report.assignedOfficerName != null) ...[
                _buildSection(
                  context,
                  'Assigned Officer',
                  Icons.badge,
                  report.assignedOfficerName!,
                ),
                const SizedBox(height: 16),
              ],

              // Resolution Notes
              if (report.resolutionNotes != null && report.resolutionNotes!.isNotEmpty) ...[
                _buildSection(
                  context,
                  'Resolution Notes',
                  Icons.notes,
                  report.resolutionNotes!,
                ),
                const SizedBox(height: 16),
              ],

              // Evidence
              if (report.evidenceUrls != null && report.evidenceUrls!.isNotEmpty) ...[
                Text(
                  'Evidence',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: report.evidenceUrls!.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            report.evidenceUrls![index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.broken_image),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) => _UpdateReportStatusDialog(report: report),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Update Status'),
                    ),
                  ),
                ],
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'investigating':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red[700]!;
      case 'high':
        return Colors.orange[700]!;
      case 'medium':
        return Colors.amber[700]!;
      case 'low':
        return Colors.blue[600]!;
      default:
        return Colors.grey;
    }
  }

  Color _getCrimeTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'theft':
        return Colors.orange;
      case 'assault':
        return Colors.red;
      case 'burglary':
        return Colors.brown;
      case 'vandalism':
        return Colors.purple;
      case 'fraud':
        return Colors.indigo;
      case 'robbery':
        return Colors.deepOrange;
      default:
        return Colors.blueGrey;
    }
  }
}

// Update Report Status Dialog
class _UpdateReportStatusDialog extends StatefulWidget {
  final CrimeReport report;

  const _UpdateReportStatusDialog({required this.report});

  @override
  State<_UpdateReportStatusDialog> createState() => _UpdateReportStatusDialogState();
}

class _UpdateReportStatusDialogState extends State<_UpdateReportStatusDialog> {
  late String _selectedStatus;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status;
    _notesController.text = widget.report.resolutionNotes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Report Status'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report: ${widget.report.title}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: ['pending', 'investigating', 'resolved', 'closed']
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getStatusColor(status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(_capitalize(status)),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedStatus = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Resolution Notes',
                border: OutlineInputBorder(),
                hintText: 'Add notes about the resolution...',
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateStatus,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateStatus() async {
    setState(() => _isLoading = true);

    try {
      final adminProvider = context.read<AdminProvider>();
      final success = await adminProvider.updateCrimeReportStatus(
        widget.report.id,
        _selectedStatus,
        resolutionNotes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Report updated successfully' : 'Failed to update report'),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'investigating':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

// Missing Reports Tab
class _MissingReportsTab extends StatelessWidget {
  const _MissingReportsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminProvider = context.watch<AdminProvider>();
    final reports = adminProvider.missingReports;

    return adminProvider.isLoadingMissingReports
        ? const Center(child: CircularProgressIndicator())
        : reports.isEmpty
            ? _buildEmptyState(theme)
            : RefreshIndicator(
                onRefresh: () => adminProvider.loadMissingReports(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    return _MissingReportCard(report: reports[index]);
                  },
                ),
              );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Missing Reports',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Missing person reports will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// Missing Report Card
class _MissingReportCard extends StatelessWidget {
  final dynamic report;

  const _MissingReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusValue = report.status.toString().split('.').last;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getStatusColor(statusValue).withOpacity(0.3),
          width: 1,
        ),
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
                  // Photo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.primary.withOpacity(0.1),
                    ),
                    child: report.photoUrls != null && report.photoUrls!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              report.photoUrls!.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.person, size: 30);
                              },
                            ),
                          )
                        : const Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (report.personName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            report.personName!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildBadge(
                              report.reportType.toString().split('.').last.replaceAll('_', ' '),
                              theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(statusValue),
                ],
              ),
              const SizedBox(height: 12),
              
              // Description
              Text(
                report.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Actions
              if (statusValue == 'pending')
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _updateStatus(context, 'rejected'),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Reject', style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _updateStatus(context, 'approved'),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
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

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _capitalize(text),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
        ),
      ),
      child: Text(
        _capitalize(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MissingReportDetailsSheet(report: report),
    );
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    final adminProvider = context.read<AdminProvider>();
    
    // Convert string to enum
    final statusEnum = status == 'approved' 
        ? MissingReportStatus.approved 
        : MissingReportStatus.rejected;

    final success = await adminProvider.updateMissingReportStatus(
      report.id,
      statusEnum,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Report ${_capitalize(status)}' : 'Failed to update report'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

// Missing Report Details Sheet
class _MissingReportDetailsSheet extends StatelessWidget {
  final dynamic report;

  const _MissingReportDetailsSheet({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusValue = report.status.toString().split('.').last;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
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

              // Photo
              if (report.photoUrls != null && report.photoUrls!.isNotEmpty) ...[
                Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        report.photoUrls!.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person, size: 60);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Title & Status
              Text(
                report.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(statusValue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _capitalize(statusValue),
                    style: TextStyle(
                      color: _getStatusColor(statusValue),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Person Info
              if (report.personName != null)
                _buildSection(context, 'Person Name', Icons.person, report.personName!),
              if (report.age != null) ...[
                const SizedBox(height: 16),
                _buildSection(context, 'Age', Icons.cake, '${report.age} years old'),
              ],
              if (report.lastSeenLocation != null) ...[
                const SizedBox(height: 16),
                _buildSection(context, 'Last Seen Location', Icons.location_on, report.lastSeenLocation!),
              ],
              if (report.lastSeenDate != null) ...[
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  'Last Seen Date',
                  Icons.calendar_today,
                  DateFormat('EEEE, MMMM d, yyyy').format(report.lastSeenDate!),
                ),
              ],
              const SizedBox(height: 16),
              _buildSection(context, 'Description', Icons.description, report.description),

              // Contact Info
              if (report.contactPhone != null || report.contactEmail != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Contact Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (report.contactPhone != null)
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(report.contactPhone!),
                    contentPadding: EdgeInsets.zero,
                  ),
                if (report.contactEmail != null)
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: Text(report.contactEmail!),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],

              // Admin Notes
              if (report.adminNotes != null && report.adminNotes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSection(context, 'Admin Notes', Icons.notes, report.adminNotes!),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              _capitalize(label),
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

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}


