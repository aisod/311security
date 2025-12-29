import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:security_311_admin/providers/admin/admin_provider.dart';
import 'package:security_311_admin/core/logger.dart';

/// Screen for managing danger zones on a map
class DangerZonesScreen extends StatefulWidget {
  const DangerZonesScreen({super.key});

  @override
  State<DangerZonesScreen> createState() => _DangerZonesScreenState();
}

class _DangerZonesScreenState extends State<DangerZonesScreen> {
  GoogleMapController? _mapController;

  // Drawing mode state
  bool _isDrawingMode = false;
  String _drawingType = 'circle'; // 'circle' or 'polygon'
  List<LatLng> _polygonPoints = [];
  LatLng? _circleCenter;
  double _circleRadius = 500; // meters

  // Danger zones data
  // List<Map<String, dynamic>> _dangerZones = []; // Now using provider
  final bool _isLoading = false;

  // Map elements
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Polygon> _polygons = {};

  // Windhoek center (default)
  final LatLng _defaultCenter = const LatLng(-22.5609, 17.0658);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDangerZones();
    });
  }

  Future<void> _loadDangerZones() async {
    // setState(() => _isLoading = true); // Handled by provider

    try {
      await context.read<AdminProvider>().loadDangerZones();
      _buildMapElements();
    } catch (e) {
      AppLogger.error('Error loading danger zones: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildMapElements(); // Rebuild map elements when provider updates
  }

  void _buildMapElements() {
    final adminProvider = context.watch<AdminProvider>();
    final dangerZones = adminProvider.dangerZones;

    final markers = <Marker>{};
    final circles = <Circle>{};
    final polygons = <Polygon>{};

    for (final zone in dangerZones) {
      final id = zone['id'] as String;
      final name = zone['name'] as String;
      final riskLevel = zone['risk_level'] as String? ?? 'medium';
      final geometryType = zone['geometry_type'] as String;
      final color = _getRiskColor(riskLevel);

      if (geometryType == 'circle') {
        final lat = zone['center_latitude'] as double;
        final lng = zone['center_longitude'] as double;
        final radius = (zone['radius_meters'] as num).toDouble();

        circles.add(Circle(
          circleId: CircleId('zone_$id'),
          center: LatLng(lat, lng),
          radius: radius,
          fillColor: color.withOpacity(0.2),
          strokeColor: color,
          strokeWidth: 2,
        ));

        markers.add(Marker(
          markerId: MarkerId('zone_marker_$id'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(_getRiskHue(riskLevel)),
          infoWindow: InfoWindow(
            title: name,
            snippet: 'Risk: ${riskLevel.toUpperCase()}',
          ),
          onTap: () => _showZoneDetails(zone),
        ));
      } else if (geometryType == 'polygon') {
        final points = zone['polygon_points'] as List;
        final latLngPoints = points.map((p) {
          return LatLng(p['lat'] as double, p['lng'] as double);
        }).toList();

        if (latLngPoints.length >= 3) {
          polygons.add(Polygon(
            polygonId: PolygonId('zone_$id'),
            points: latLngPoints,
            fillColor: color.withOpacity(0.2),
            strokeColor: color,
            strokeWidth: 2,
          ));

          // Add marker at centroid
          final centroid = _calculateCentroid(latLngPoints);
          markers.add(Marker(
            markerId: MarkerId('zone_marker_$id'),
            position: centroid,
            icon: BitmapDescriptor.defaultMarkerWithHue(_getRiskHue(riskLevel)),
            infoWindow: InfoWindow(
              title: name,
              snippet: 'Risk: ${riskLevel.toUpperCase()}',
            ),
            onTap: () => _showZoneDetails(zone),
          ));
        }
      }
    }

    // Add drawing elements if in drawing mode
    if (_isDrawingMode) {
      if (_drawingType == 'circle' && _circleCenter != null) {
        circles.add(Circle(
          circleId: const CircleId('drawing_circle'),
          center: _circleCenter!,
          radius: _circleRadius,
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.blue,
          strokeWidth: 3,
        ));

        markers.add(Marker(
          markerId: const MarkerId('drawing_center'),
          position: _circleCenter!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _circleCenter = newPosition;
              _buildMapElements();
            });
          },
        ));
      } else if (_drawingType == 'polygon' && _polygonPoints.isNotEmpty) {
        // Add polygon being drawn
        if (_polygonPoints.length >= 3) {
          polygons.add(Polygon(
            polygonId: const PolygonId('drawing_polygon'),
            points: _polygonPoints,
            fillColor: Colors.blue.withOpacity(0.2),
            strokeColor: Colors.blue,
            strokeWidth: 3,
          ));
        }

        // Add markers for each point
        for (int i = 0; i < _polygonPoints.length; i++) {
          markers.add(Marker(
            markerId: MarkerId('drawing_point_$i'),
            position: _polygonPoints[i],
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            draggable: true,
            onDragEnd: (newPosition) {
              setState(() {
                _polygonPoints[i] = newPosition;
                _buildMapElements();
              });
            },
          ));
        }
      }
    }

    setState(() {
      _markers = markers;
      _circles = circles;
      _polygons = polygons;
    });
  }

  LatLng _calculateCentroid(List<LatLng> points) {
    double latSum = 0;
    double lngSum = 0;
    for (final point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    return LatLng(latSum / points.length, lngSum / points.length);
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'critical':
        return Colors.red[800]!;
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow[700]!;
      default:
        return Colors.orange;
    }
  }

  double _getRiskHue(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'critical':
        return BitmapDescriptor.hueRed;
      case 'high':
        return BitmapDescriptor.hueRose;
      case 'medium':
        return BitmapDescriptor.hueOrange;
      case 'low':
        return BitmapDescriptor.hueYellow;
      default:
        return BitmapDescriptor.hueOrange;
    }
  }

  void _onMapTap(LatLng position) {
    if (!_isDrawingMode) return;

    setState(() {
      if (_drawingType == 'circle') {
        _circleCenter = position;
      } else if (_drawingType == 'polygon') {
        _polygonPoints.add(position);
      }
      _buildMapElements();
    });
  }

  void _clearDrawing() {
    setState(() {
      _polygonPoints = [];
      _circleCenter = null;
      _circleRadius = 500;
      _buildMapElements();
    });
  }

  void _showZoneDetails(Map<String, dynamic> zone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ZoneDetailsSheet(
        zone: zone,
        onEdit: () {
          Navigator.pop(context);
          _showEditZoneDialog(zone);
        },
        onDelete: () async {
          Navigator.pop(context);
          await _deleteZone(zone['id']);
        },
        onToggleStatus: (isActive) async {
          // TODO: Implement toggle status
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showCreateZoneDialog() {
    if (_drawingType == 'circle' && _circleCenter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please tap on the map to set the circle center')),
      );
      return;
    }

    if (_drawingType == 'polygon' && _polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add at least 3 points to create a polygon')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _CreateZoneDialog(
        geometryType: _drawingType,
        circleCenter: _circleCenter,
        circleRadius: _circleRadius,
        polygonPoints: _polygonPoints,
        onCreated: (zone) {
          setState(() {
            // _dangerZones.add(zone); // Handled by provider refresh
            _isDrawingMode = false;
            _clearDrawing();
            _buildMapElements();
          });
        },
      ),
    );
  }

  void _showEditZoneDialog(Map<String, dynamic> zone) {
    showDialog(
      context: context,
      builder: (context) => _EditZoneDialog(
        zone: zone,
        onUpdated: (updates) {
          // Provider handles refresh, UI will update automatically
        },
      ),
    );
  }

  Future<void> _deleteZone(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Zone'),
        content:
            const Text('Are you sure you want to delete this danger zone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context.read<AdminProvider>().deleteDangerZone(id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Danger zone deleted'
                : 'Failed to delete danger zone'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminProvider = context.watch<AdminProvider>();
    final dangerZones = adminProvider.dangerZones;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danger Zones'),
        actions: [
          IconButton(
            onPressed: _loadDangerZones,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          if (_isDrawingMode)
            IconButton(
              onPressed: () {
                setState(() {
                  _isDrawingMode = false;
                  _clearDrawing();
                });
              },
              icon: const Icon(Icons.close),
              tooltip: 'Cancel Drawing',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _defaultCenter,
              zoom: 12,
            ),
            markers: _markers,
            circles: _circles,
            polygons: _polygons,
            onTap: _onMapTap,
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Loading overlay
          if (_isLoading || adminProvider.isLoadingDangerZones)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Drawing mode panel
          if (_isDrawingMode)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _drawingType == 'circle'
                                ? Icons.circle_outlined
                                : Icons.pentagon_outlined,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Drawing ${_drawingType == 'circle' ? 'Circle' : 'Polygon'}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _drawingType == 'circle'
                            ? 'Tap on the map to set the center point'
                            : 'Tap on the map to add polygon points (min 3)',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (_drawingType == 'circle' &&
                          _circleCenter != null) ...[
                        const SizedBox(height: 12),
                        Text('Radius: ${_circleRadius.toInt()} meters'),
                        Slider(
                          value: _circleRadius,
                          min: 100,
                          max: 2000,
                          divisions: 19,
                          label: '${_circleRadius.toInt()}m',
                          onChanged: (value) {
                            setState(() {
                              _circleRadius = value;
                              _buildMapElements();
                            });
                          },
                        ),
                      ],
                      if (_drawingType == 'polygon')
                        Text('Points: ${_polygonPoints.length}'),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _clearDrawing,
                            child: const Text('Clear'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _showCreateZoneDialog,
                            child: const Text('Create Zone'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Zone list panel (when not drawing)
          if (!_isDrawingMode)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Card(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: dangerZones.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map_outlined,
                                    size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'No danger zones defined',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  'Tap the + button to add one',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: dangerZones.length,
                          itemBuilder: (context, index) {
                            final zone = dangerZones[index];
                            return ListTile(
                              leading: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getRiskColor(
                                      zone['risk_level'] ?? 'medium'),
                                ),
                              ),
                              title: Text(zone['name'] ?? 'Unnamed Zone'),
                              subtitle: Text(
                                (zone['crime_types'] as List?)?.join(', ') ??
                                    'General',
                              ),
                              trailing: Text(
                                zone['risk_level']?.toUpperCase() ?? 'MEDIUM',
                                style: TextStyle(
                                  color: _getRiskColor(
                                      zone['risk_level'] ?? 'medium'),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              onTap: () {
                                _showZoneDetails(zone);
                                // Move map to zone
                                final center = zone['geometry_type'] == 'circle'
                                    ? LatLng(
                                        zone['center_latitude'] as double,
                                        zone['center_longitude'] as double,
                                      )
                                    : _calculateCentroid(
                                        (zone['polygon_points'] as List)
                                            .map((p) {
                                          return LatLng(
                                            p['lat'] as double,
                                            p['lng'] as double,
                                          );
                                        }).toList(),
                                      );
                                try {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLngZoom(center, 15),
                                  );
                                } catch (e) {
                                  AppLogger.error('Error moving camera: $e');
                                }
                              },
                            );
                          },
                        ),
                ),
              ),
            ),

          // Map type selector
          Positioned(
            right: 16,
            bottom: 320,
            child: Column(
              children: [
                FloatingActionButton.small(
                  onPressed: () {
                    try {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_defaultCenter, 12),
                      );
                    } catch (e) {
                      AppLogger.error('Error centering map: $e');
                    }
                  },
                  heroTag: 'center',
                  backgroundColor: Colors.white,
                  child: Icon(Icons.center_focus_strong,
                      color: theme.colorScheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: !_isDrawingMode
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    _showDrawingTypeDialog();
                  },
                  heroTag: 'add_zone',
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            )
          : null,
    );
  }

  void _showDrawingTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Danger Zone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select the zone shape:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.circle_outlined, color: Colors.blue),
              title: const Text('Circle'),
              subtitle:
                  const Text('Define a circular area with center and radius'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _isDrawingMode = true;
                  _drawingType = 'circle';
                  _clearDrawing();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.pentagon_outlined, color: Colors.blue),
              title: const Text('Polygon'),
              subtitle: const Text('Draw a custom shape by adding points'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _isDrawingMode = true;
                  _drawingType = 'polygon';
                  _clearDrawing();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Zone Details Sheet
class _ZoneDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> zone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onToggleStatus;

  const _ZoneDetailsSheet({
    required this.zone,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riskLevel = zone['risk_level'] as String? ?? 'medium';
    final isActive = zone['is_active'] as bool? ?? true;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getRiskColor(riskLevel).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.warning_amber,
                      color: _getRiskColor(riskLevel),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone['name'] ?? 'Unnamed Zone',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _getRiskColor(riskLevel).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                riskLevel.toUpperCase(),
                                style: TextStyle(
                                  color: _getRiskColor(riskLevel),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isActive ? 'ACTIVE' : 'INACTIVE',
                                style: TextStyle(
                                  color: isActive ? Colors.green : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
              const SizedBox(height: 24),

              // Description
              if (zone['description'] != null) ...[
                Text(
                  'Description',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(zone['description']),
                const SizedBox(height: 16),
              ],

              // Crime Types
              Text(
                'Crime Types',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ((zone['crime_types'] as List?) ?? ['general'])
                    .map((type) => Chip(
                          label: Text(
                            type.toString().replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Warning Message
              if (zone['warning_message'] != null) ...[
                Text(
                  'Warning Message',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(zone['warning_message'])),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Safety Tips
              if (zone['safety_tips'] != null) ...[
                Text(
                  'Safety Tips',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tips_and_updates,
                          color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(zone['safety_tips'])),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Statistics
              if (zone['incident_count'] != null) ...[
                Text(
                  'Statistics',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatCard(
                      'Incidents',
                      zone['incident_count'].toString(),
                      Icons.report,
                      Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Actions
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
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

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'critical':
        return Colors.red[800]!;
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow[700]!;
      default:
        return Colors.orange;
    }
  }
}

// Create Zone Dialog
class _CreateZoneDialog extends StatefulWidget {
  final String geometryType;
  final LatLng? circleCenter;
  final double circleRadius;
  final List<LatLng> polygonPoints;
  final Function(Map<String, dynamic>) onCreated;

  const _CreateZoneDialog({
    required this.geometryType,
    this.circleCenter,
    required this.circleRadius,
    required this.polygonPoints,
    required this.onCreated,
  });

  @override
  State<_CreateZoneDialog> createState() => _CreateZoneDialogState();
}

class _CreateZoneDialogState extends State<_CreateZoneDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _warningController = TextEditingController();
  final _safetyTipsController = TextEditingController();

  String _selectedRiskLevel = 'medium';
  final List<String> _selectedCrimeTypes = ['general'];
  bool _isLoading = false;

  final List<String> _allCrimeTypes = [
    'theft',
    'robbery',
    'assault',
    'carjacking',
    'mugging',
    'burglary',
    'vandalism',
    'drug_activity',
    'gang_activity',
    'fraud',
    'kidnapping',
    'general',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _warningController.dispose();
    _safetyTipsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Danger Zone'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Zone Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedRiskLevel,
                decoration: const InputDecoration(
                  labelText: 'Risk Level',
                  border: OutlineInputBorder(),
                ),
                items: ['low', 'medium', 'high', 'critical']
                    .map((level) => DropdownMenuItem(
                          value: level,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getRiskColor(level),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(level.toUpperCase()),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedRiskLevel = value!),
              ),
              const SizedBox(height: 16),
              const Text('Crime Types'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allCrimeTypes.map((type) {
                  final isSelected = _selectedCrimeTypes.contains(type);
                  return FilterChip(
                    label: Text(type.replaceAll('_', ' ')),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCrimeTypes.add(type);
                        } else {
                          _selectedCrimeTypes.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _warningController,
                decoration: const InputDecoration(
                  labelText: 'Warning Message',
                  border: OutlineInputBorder(),
                  hintText: 'Message shown when user enters zone',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _safetyTipsController,
                decoration: const InputDecoration(
                  labelText: 'Safety Tips',
                  border: OutlineInputBorder(),
                  hintText: 'Tips for staying safe in this area',
                ),
                maxLines: 2,
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
          onPressed: _isLoading ? null : _createZone,
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

  Future<void> _createZone() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCrimeTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one crime type')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create zone data
      final zone = <String, dynamic>{
        'id': DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'geometry_type': widget.geometryType,
        'crime_types': _selectedCrimeTypes,
        'risk_level': _selectedRiskLevel,
        'warning_message': _warningController.text.trim().isNotEmpty
            ? _warningController.text.trim()
            : null,
        'safety_tips': _safetyTipsController.text.trim().isNotEmpty
            ? _safetyTipsController.text.trim()
            : null,
        'is_active': true,
        'incident_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (widget.geometryType == 'circle') {
        zone['center_latitude'] = widget.circleCenter!.latitude;
        zone['center_longitude'] = widget.circleCenter!.longitude;
        zone['radius_meters'] = widget.circleRadius;
      } else {
        zone['polygon_points'] = widget.polygonPoints
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList();
      }

      // Save to Supabase using AdminProvider
      final success = await Provider.of<AdminProvider>(context, listen: false)
          .createDangerZone(zone);

      if (success) {
        widget.onCreated(zone);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Danger zone created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create danger zone'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'critical':
        return Colors.red[800]!;
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow[700]!;
      default:
        return Colors.orange;
    }
  }
}

// Edit Zone Dialog
class _EditZoneDialog extends StatefulWidget {
  final Map<String, dynamic> zone;
  final Function(Map<String, dynamic>) onUpdated;

  const _EditZoneDialog({
    required this.zone,
    required this.onUpdated,
  });

  @override
  State<_EditZoneDialog> createState() => _EditZoneDialogState();
}

class _EditZoneDialogState extends State<_EditZoneDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _warningController;
  late TextEditingController _safetyTipsController;

  late String _selectedRiskLevel;
  late List<String> _selectedCrimeTypes;
  late bool _isActive;
  bool _isLoading = false;

  final List<String> _allCrimeTypes = [
    'theft',
    'robbery',
    'assault',
    'carjacking',
    'mugging',
    'burglary',
    'vandalism',
    'drug_activity',
    'gang_activity',
    'fraud',
    'kidnapping',
    'general',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.zone['name']);
    _descriptionController =
        TextEditingController(text: widget.zone['description']);
    _warningController =
        TextEditingController(text: widget.zone['warning_message']);
    _safetyTipsController =
        TextEditingController(text: widget.zone['safety_tips']);

    _selectedRiskLevel = widget.zone['risk_level'] ?? 'medium';
    _selectedCrimeTypes =
        List<String>.from(widget.zone['crime_types'] ?? ['general']);
    _isActive = widget.zone['is_active'] ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _warningController.dispose();
    _safetyTipsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Danger Zone'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Zone Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedRiskLevel,
                decoration: const InputDecoration(
                  labelText: 'Risk Level',
                  border: OutlineInputBorder(),
                ),
                items: ['low', 'medium', 'high', 'critical']
                    .map((level) => DropdownMenuItem(
                          value: level,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getRiskColor(level),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(level.toUpperCase()),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedRiskLevel = value!),
              ),
              const SizedBox(height: 16),
              const Text('Crime Types'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allCrimeTypes.map((type) {
                  final isSelected = _selectedCrimeTypes.contains(type);
                  return FilterChip(
                    label: Text(type.replaceAll('_', ' ')),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCrimeTypes.add(type);
                        } else {
                          _selectedCrimeTypes.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _warningController,
                decoration: const InputDecoration(
                  labelText: 'Warning Message',
                  border: OutlineInputBorder(),
                  hintText: 'Message shown when user enters zone',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _safetyTipsController,
                decoration: const InputDecoration(
                  labelText: 'Safety Tips',
                  border: OutlineInputBorder(),
                  hintText: 'Tips for staying safe in this area',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text('Enable or disable this zone'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
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
          onPressed: _isLoading ? null : _updateZone,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _updateZone() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCrimeTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one crime type')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updates = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'risk_level': _selectedRiskLevel,
        'crime_types': _selectedCrimeTypes,
        'warning_message': _warningController.text.trim().isNotEmpty
            ? _warningController.text.trim()
            : null,
        'safety_tips': _safetyTipsController.text.trim().isNotEmpty
            ? _safetyTipsController.text.trim()
            : null,
        'is_active': _isActive,
      };

      final success = await Provider.of<AdminProvider>(context, listen: false)
          .updateDangerZone(widget.zone['id'], updates);

      if (success) {
        widget.onUpdated(updates);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Danger zone updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update danger zone'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'critical':
        return Colors.red[800]!;
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow[700]!;
      default:
        return Colors.orange;
    }
  }
}
