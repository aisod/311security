import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:security_311_user/widgets/quick_action_card.dart';
import 'package:security_311_user/widgets/skeleton_loader.dart';
import 'package:security_311_user/widgets/location_header.dart';
import 'package:security_311_user/widgets/safety_tips_card.dart';
import 'package:security_311_user/screens/crime_report_screen.dart';
import 'package:security_311_user/screens/alerts_screen.dart';
import 'package:security_311_user/screens/notifications_screen.dart';
import 'package:security_311_user/screens/profile_screen.dart';
import 'package:security_311_user/providers/auth_provider.dart';
import 'package:security_311_user/providers/location_provider.dart';
import 'package:security_311_user/providers/safety_alerts_provider.dart';
import 'package:security_311_user/providers/notifications_provider.dart';
import 'package:security_311_user/providers/danger_zone_provider.dart';
import 'package:security_311_user/models/alert.dart';
import 'package:security_311_user/models/danger_zone.dart';
import 'package:security_311_user/core/logger.dart';
import 'package:security_311_user/services/emergency_alert_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;
  final EmergencyAlertService _emergencyAlertService = EmergencyAlertService();
  bool _isTriggeringPanic = false;

  @override
  void initState() {
    super.initState();
    _screens = [
      _DashboardContent(
        onTabChange: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      CrimeReportScreen(
        onReportSubmitted: () {
          setState(() {
            _selectedIndex = 0;
          });
        },
      ),
      ProfileScreen(onBackPressed: () {
        setState(() {
          _selectedIndex = 0; // Navigate back to home tab
        });
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton:
          _selectedIndex == 0 ? _buildPanicButton(context) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -8),
              spreadRadius: 0,
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
              ),
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.description_outlined,
                activeIcon: Icons.description_rounded,
                label: 'Reports',
              ),
              _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the floating panic button
  Widget _buildPanicButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
          bottom: 80, right: 16), // Space above bottom nav
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isTriggeringPanic ? null : () => _handlePanicButton(context),
          borderRadius: BorderRadius.circular(60),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE53935), // Bright emergency red
                  Color(0xFFC62828), // Deep red
                  Color(0xFFB71C1C), // Darker red
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935).withValues(alpha: 0.6),
                  blurRadius: 24,
                  spreadRadius: 4,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFFC62828).withValues(alpha: 0.4),
                  blurRadius: 40,
                  spreadRadius: 6,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isTriggeringPanic
                ? const Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PANIC',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// Build a custom navigation item with enhanced design
  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? primaryColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: isSelected ? 30 : 28,
                color: isSelected 
                    ? primaryColor 
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 10),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
                child: Text(label),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Handle panic button press
  Future<void> _handlePanicButton(BuildContext context) async {
    // Show confirmation dialog to prevent accidental triggers
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: Colors.red,
              size: 32,
            ),
            const SizedBox(width: 12),
            const Text('Emergency Alert'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will send an emergency alert with your current location to security services.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Are you in immediate danger?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('SEND ALERT'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isTriggeringPanic = true;
    });

    try {
      // Get current location
      final locationProvider = context.read<LocationProvider>();
      await locationProvider.getCurrentLocation(forceRefresh: true);

      final currentLocation = locationProvider.currentLocation;
      String? locationDescription;
      double? latitude;
      double? longitude;

      if (currentLocation != null) {
        latitude = currentLocation.latitude;
        longitude = currentLocation.longitude;
        locationDescription = currentLocation.formattedAddress;
      }

      // Create emergency alert
      final alert = await _emergencyAlertService.createEmergencyAlert(
        type: 'panic',
        description: 'Panic button activated by user',
        latitude: latitude,
        longitude: longitude,
        locationDescription: locationDescription,
      );

      if (!mounted) return;

      if (alert != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Emergency alert sent! Help is on the way.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );

        AppLogger.info('Panic alert created successfully: ${alert.id}');
      } else {
        throw Exception('Failed to create emergency alert');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error triggering panic alert', e, stackTrace);

      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to send alert. Please try again or call emergency services directly.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: () => _handlePanicButton(context),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTriggeringPanic = false;
        });
      }
    }
  }
}

class _DashboardContent extends StatefulWidget {
  final Function(int) onTabChange;
  
  const _DashboardContent({required this.onTabChange});

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  static const String _locationUnavailableLabel = "Location unavailable";

  String _currentLocation = "Getting location...";
  bool _isLocationLoading = true;
  GoogleMapController? _mapController;

  // Current user location
  LatLng? _userLocation;

  // Windhoek, Namibia coordinates (fallback)
  final LatLng _windhoekCenter = const LatLng(-22.5609, 17.0658);

  @override
  void initState() {
    super.initState();
    // Delay location fetching to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation(forceRefresh: true);
      _setupDangerZoneAlerts();
    });
  }
  
  /// Set up danger zone proximity alert callbacks
  void _setupDangerZoneAlerts() {
    final dangerZoneProvider = context.read<DangerZoneProvider>();
    
    dangerZoneProvider.onEnteredDangerZone = (zone) {
      if (!mounted) return;
      _showDangerZoneEntryAlert(zone);
    };
    
    dangerZoneProvider.onExitedDangerZone = (zone) {
      if (!mounted) return;
      // Optionally show exit notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have left the ${zone.name} area'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    };
  }
  
  /// Show alert when user enters a danger zone
  void _showDangerZoneEntryAlert(DangerZone zone) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getDangerZoneDialogColor(zone.riskLevel).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_amber,
                color: _getDangerZoneDialogColor(zone.riskLevel),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DANGER ZONE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    zone.name,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Risk Level Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getDangerZoneDialogColor(zone.riskLevel).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getDangerZoneDialogColor(zone.riskLevel).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  zone.riskLevel.displayName.toUpperCase(),
                  style: TextStyle(
                    color: _getDangerZoneDialogColor(zone.riskLevel),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Warning message
              if (zone.warningMessage != null && zone.warningMessage!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          zone.warningMessage!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Crime types
              const Text(
                'Known Crime Types:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: zone.crimeTypes.map((type) => Chip(
                  label: Text(
                    type.displayName,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.red.withOpacity(0.1),
                  side: BorderSide(color: Colors.red.withOpacity(0.3)),
                )).toList(),
              ),
              
              // Safety tips
              if (zone.safetyTips != null && zone.safetyTips!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tips_and_updates, color: Colors.blue, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Safety Tips',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        zone.safetyTips!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I UNDERSTAND'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to emergency contacts
              _showEmergencyServicesDialog(context);
            },
            icon: const Icon(Icons.phone, size: 18),
            label: const Text('EMERGENCY'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getDangerZoneDialogColor(DangerZoneRiskLevel riskLevel) {
    switch (riskLevel) {
      case DangerZoneRiskLevel.critical:
        return const Color(0xFFB71C1C);
      case DangerZoneRiskLevel.high:
        return const Color(0xFFD32F2F);
      case DangerZoneRiskLevel.medium:
        return const Color(0xFFFF9800);
      case DangerZoneRiskLevel.low:
        return const Color(0xFFFFC107);
    }
  }
  
  /// Check if user is in any danger zones and trigger alerts
  void _checkDangerZones(double latitude, double longitude) {
    final dangerZoneProvider = context.read<DangerZoneProvider>();
    dangerZoneProvider.checkUserLocationImmediate(latitude, longitude);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation({bool forceRefresh = false}) async {
    if (!mounted) return;

      final locationProvider = context.read<LocationProvider>();
    // Prevent multiple concurrent requests
    if (locationProvider.isLoadingLocation) return;

    setState(() => _isLocationLoading = true);

    try {
      // Log the attempt
      AppLogger.info(
          'Dashboard: Requesting location (forceRefresh: $forceRefresh)');

      await locationProvider.getCurrentLocation(forceRefresh: forceRefresh);

      if (!mounted) return; // Check again after async operation

      // Log the result
      if (locationProvider.currentLocation != null) {
        AppLogger.info(
            'Dashboard: Location obtained - ${locationProvider.currentLocation!.formattedAddress}');
      } else if (locationProvider.locationError != null) {
        AppLogger.error(
            'Dashboard: Location error - ${locationProvider.locationError}');
      } else {
        AppLogger.warning('Dashboard: No location and no error');
      }

      if (!mounted) return;
      setState(() {
        _isLocationLoading = false;
        if (locationProvider.currentLocation != null) {
          _currentLocation = locationProvider.currentLocation!.formattedAddress;
          _userLocation = LatLng(
            locationProvider.currentLocation!.latitude,
            locationProvider.currentLocation!.longitude,
          );

          // Move map to user's location
          try {
            _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(_userLocation!, 14.0));
          } catch (e) {
            AppLogger.warning('Dashboard: Map controller error (animateCamera): $e');
          }
          
          // Check if user is in any danger zones
          _checkDangerZones(
            locationProvider.currentLocation!.latitude,
            locationProvider.currentLocation!.longitude,
          );
        } else {
          // Only set to unavailable if we truly don't have a location
          if (forceRefresh ||
              _currentLocation == "Getting location..." ||
              _currentLocation.isEmpty) {
          _currentLocation = _locationUnavailableLabel;
          _userLocation = _windhoekCenter; // Use Windhoek as fallback
          }
        }
      });

      // Show snackbar with error
      if (mounted && locationProvider.locationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locationProvider.locationError!),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _getCurrentLocation(forceRefresh: true),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Dashboard: Exception getting location', e, stackTrace);
      if (!mounted) return;
      setState(() {
        _isLocationLoading = false;
        _currentLocation = _locationUnavailableLabel;
        // Don't reset map center on error if we had a location before
        _userLocation ??= _windhoekCenter;
      });

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location error: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _getCurrentLocation(forceRefresh: true),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _openAlerts(BuildContext context, {String? categoryKey}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlertsScreen(initialCategory: categoryKey),
      ),
    );
  }

  String get _mapLocationLabel {
    if (_isLocationLoading) {
      return 'Locating...';
    }
    if (_currentLocation == _locationUnavailableLabel ||
        _currentLocation.trim().isEmpty) {
      return _locationUnavailableLabel;
    }
    final commaIndex = _currentLocation.indexOf(',');
    return commaIndex == -1
        ? _currentLocation
        : _currentLocation.substring(0, commaIndex);
  }

  Widget _buildInteractiveMap(BuildContext context) {
    final theme = Theme.of(context);
    final mapCenter = _userLocation ?? _windhoekCenter;
    final alertsProvider = context.watch<SafetyAlertsProvider>();
    final dangerZoneProvider = context.watch<DangerZoneProvider>();
    final activeAlerts = alertsProvider.allAlerts
        .where((alert) => alert.isActive && !alert.isExpired)
        .toList();
    final alertOverlays = _buildAlertOverlays(activeAlerts);
    final dangerZoneOverlays = _buildDangerZoneOverlays(dangerZoneProvider.activeDangerZones);

    final markers = {
      // User location marker
      Marker(
        markerId: const MarkerId('user_location'),
        position: mapCenter,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Current position',
        ),
      ),
      ...alertOverlays.markers,
      ...dangerZoneOverlays.markers,
    };

    return Container(
      height: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.surface.withValues(alpha: 0.5),
          width: 4,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Google Map
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: mapCenter,
                zoom: 14.0,
              ),
              markers: markers,
              polygons: {...alertOverlays.polygons, ...dangerZoneOverlays.polygons},
              circles: {...alertOverlays.circles, ...dangerZoneOverlays.circles},
              mapType: MapType.normal,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
            ),

            // Top Gradient Overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Top Controls Overlay
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  // Location info chip
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                          _isLocationLoading
                              ? Icons.location_searching
                              : Icons.location_on,
                              size: 18,
                          color: theme.colorScheme.primary,
                        ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                        Text(
                                  _isLocationLoading
                                      ? "Finding location..."
                                      : "Current Location",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _mapLocationLabel,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                      ],
                    ),
                  ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Recenter button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => _getCurrentLocation(forceRefresh: true),
                      icon: _isLocationLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : Icon(
                              Icons.my_location,
                              color: theme.colorScheme.primary,
                            ),
                      tooltip: 'Refresh Location',
                    ),
                  ),
                ],
              ),
            ),

            // Floating Action Button - Recenter
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.small(
                onPressed: () async {
                  // Refresh user location and recenter map
                  await _getCurrentLocation(forceRefresh: true);

                  // Move map to user's current location
                  final centerPoint = _userLocation ?? _windhoekCenter;
                  try {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(centerPoint, 14.0),
                  );
                  } catch (e) {
                    AppLogger.warning(
                        'Dashboard: Map controller error (recenter): $e');
                  }
                },
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.my_location,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
            ),

            if (alertsProvider.isLoading)
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loading map overlays...',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

            if (!alertsProvider.isLoading && alertOverlays.isEmpty)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No marked zones available nearby yet. Stay tuned for updates.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyServicesDialog(BuildContext context) {
    // Check if user is in Windhoek by checking the hardcoded location
    const String currentLocation = "Windhoek, Khomas Region";
    bool isInWindhoek = currentLocation.toLowerCase().contains('windhoek');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        List<Widget> emergencyServices = [
          _EmergencyServiceItem(
            icon: Icons.local_police,
            title: 'Namibian Police',
            number: '10111',
            color: Colors.blue,
            description: 'General police emergency',
          ),
        ];

        // Add City Police if user is in Windhoek
        if (isInWindhoek) {
          emergencyServices.addAll([
            const SizedBox(height: 8),
            _EmergencyServiceItem(
              icon: Icons.shield,
              title: 'Windhoek City Police',
              number: '061290-2888',
              color: Colors.indigo,
              description: 'City police services',
            ),
          ]);
        }

        emergencyServices.addAll([
          const SizedBox(height: 8),
          _EmergencyServiceItem(
            icon: Icons.local_hospital,
            title: 'Emergency Medical',
            number: '2032276',
            color: Colors.red,
            description: 'Ambulance & medical emergency',
          ),
          const SizedBox(height: 8),
          _EmergencyServiceItem(
            icon: Icons.local_fire_department,
            title: 'Fire Department',
            number: '061290111',
            color: Colors.orange,
            description: 'Fire emergency services',
          ),
          const SizedBox(height: 8),
          _EmergencyServiceItem(
            icon: Icons.security,
            title: '3:11 Emergency',
            number: '311',
            color: theme.colorScheme.primary,
            description: '24/7 security assistance',
          ),
        ]);

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
                child: Icon(
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
                  ...emergencyServices,
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final notificationsProvider = context.watch<NotificationsProvider>();
    final fullName = authProvider.userProfile?['full_name'] as String?;
    final firstName = fullName != null && fullName.isNotEmpty
        ? fullName.split(' ').first
        : null;
    final profileImageUrl =
        authProvider.userProfile?['profile_image_url'] as String?;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              expandedHeight: 120.0,
              backgroundColor: theme.colorScheme.surface,
              surfaceTintColor: theme.colorScheme.surface,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "👋 Stay Safe",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ).animate().fadeIn().slideX(begin: -0.2),
                      if (firstName != null)
                        Text(
                          "Welcome back, $firstName",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2)
                      else
                        Text(
                          "Here to keep you informed",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
                    ],
                  ),
                ),
              ),
              title: innerBoxIsScrolled
                  ? Text(
                      "Stay Safe",
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
              centerTitle: true,
              actions: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Navigate to notifications screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (notificationsProvider.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD32F2F),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            notificationsProvider.unreadCount > 99
                                ? '99+'
                                : notificationsProvider.unreadCount.toString(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    // Switch to profile tab (index 2)
                    widget.onTabChange(2);
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage:
                        profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : null,
                    child: profileImageUrl == null || profileImageUrl.isEmpty
                        ? Icon(
                            Icons.person_outline,
                            color: theme.colorScheme.primary,
                            size: 20,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ];
        },
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Header (Moved inside body)
              LocationHeader(
                location: _currentLocation,
                isLocationLoading: _isLocationLoading,
                onLocationRefresh: () =>
                    _getCurrentLocation(forceRefresh: true),
              ),
              const SizedBox(height: 24),

              // Interactive Map with Skeleton Loading
              _isLocationLoading
                  ? const SkeletonLoader(
                      height: 350,
                      borderRadius: BorderRadius.all(Radius.circular(20)))
                  : _buildInteractiveMap(context)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.95, 0.95)),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                "Quick Actions",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 20),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
                children: [
                  QuickActionCard(
                    icon: Icons.warning_amber,
                    title: "Safety Alerts",
                    subtitle: "View security & safety notifications",
                    iconColor: Colors.amber,
                    onTap: () => _openAlerts(context),
                  ),
                  QuickActionCard(
                    icon: Icons.search,
                    title: "Lost & Found Alerts",
                    subtitle: "Browse missing or found cases",
                    iconColor: Colors.purple,
                    onTap: () =>
                        _openAlerts(context, categoryKey: 'lost_found'),
                  ),
                  QuickActionCard(
                    icon: Icons.local_police,
                    title: "Emergency Services",
                    subtitle: "Quick access to emergency numbers",
                    iconColor: Colors.green,
                    onTap: () {
                      _showEmergencyServicesDialog(context);
                    },
                  ),
                  QuickActionCard(
                    icon: Icons.person_search,
                    title: "Wanted Alerts",
                    subtitle: "People & vehicles of interest",
                    iconColor: Colors.deepOrange,
                    onTap: () => _openAlerts(context, categoryKey: 'wanted'),
                  ),
                ]
                    .animate(interval: 100.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOutQuad),
              ),

              const SizedBox(height: 32),

              // Safety Tips Section
              const SafetyTipsCard().animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 32),

              // Recent Activity Section
              Text(
                "Recent Activity",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ).animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "System Status: All Good",
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  "All emergency services are operational",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience wrapper for the different overlay collections derived from
/// safety alerts. Storing the sets together keeps the GoogleMap configuration
/// tidy and guarantees the call site can determine whether any overlays exist.
class _AlertMapOverlays {
  const _AlertMapOverlays({
    required this.markers,
    required this.polygons,
    required this.circles,
  });

  final Set<Marker> markers;
  final Set<Polygon> polygons;
  final Set<Circle> circles;

  bool get isEmpty => markers.isEmpty && polygons.isEmpty && circles.isEmpty;
}

/// Internal geometry descriptor to simplify parsing metadata into either a
/// polygon outline or circular radius based zone.
enum _AlertGeometryType { polygon, circle }

/// Lightweight geometry model used while translating admin-defined metadata
/// into map overlays. Each instance represents a single polygon or circle.
class _AlertGeometry {
  const _AlertGeometry._({
    required this.type,
    this.polygonPoints,
    this.center,
    this.radiusMeters,
  });

  const _AlertGeometry.polygon(List<LatLng> points)
      : this._(type: _AlertGeometryType.polygon, polygonPoints: points);

  const _AlertGeometry.circle(LatLng center, double radiusMeters)
      : this._(
            type: _AlertGeometryType.circle,
            center: center,
            radiusMeters: radiusMeters);

  final _AlertGeometryType type;
  final List<LatLng>? polygonPoints;
  final LatLng? center;
  final double? radiusMeters;
}

/// Parsed circle information with a guaranteed center and radius measured in
/// meters. This keeps the parsing helpers small and readable.
class _CircleDefinition {
  const _CircleDefinition(this.center, this.radiusMeters);

  final LatLng center;
  final double radiusMeters;
}

/// Builds markers, polygons, and circles for the active safety alerts so that
/// the user can see admin-defined zones directly on the dashboard map.
_AlertMapOverlays _buildAlertOverlays(List<SafetyAlert> alerts) {
  final markers = <Marker>{};
  final polygons = <Polygon>{};
  final circles = <Circle>{};

  for (final alert in alerts) {
    final alertColor = _resolveAlertColor(alert);

    if (alert.latitude != null && alert.longitude != null) {
      final markerHue = _markerHueForAlert(alert);
      markers.add(
        Marker(
          markerId: MarkerId('alert_${alert.id}'),
          position: LatLng(alert.latitude!, alert.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
          infoWindow: InfoWindow(
            title: alert.title,
            snippet: _buildAlertSnippet(alert),
          ),
        ),
      );
    }

    final geometries = _extractGeometries(alert);
    var polygonIndex = 0;
    var circleIndex = 0;

    for (final geometry in geometries) {
      switch (geometry.type) {
        case _AlertGeometryType.polygon:
          final points = geometry.polygonPoints ?? [];
          if (points.length >= 3) {
            polygons.add(
              Polygon(
                polygonId: PolygonId('alert_${alert.id}_poly_$polygonIndex'),
                points: points,
                strokeColor: alertColor,
                strokeWidth: 2,
                fillColor: alertColor.withValues(alpha: 0.18),
              ),
            );

            if (alert.latitude == null || alert.longitude == null) {
              final centroid = _computePolygonCentroid(points);
              final markerHue = _markerHueForAlert(alert);
              markers.add(
                Marker(
                  markerId:
                      MarkerId('alert_${alert.id}_poly_center_$polygonIndex'),
                  position: centroid,
                  icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
                  infoWindow: InfoWindow(
                    title: alert.title,
                    snippet: _buildAlertSnippet(alert),
                  ),
                ),
              );
            }

            polygonIndex += 1;
          }
          break;
        case _AlertGeometryType.circle:
          final center = geometry.center;
          final radiusMeters = geometry.radiusMeters;
          if (center != null && radiusMeters != null && radiusMeters > 0) {
            circles.add(
              Circle(
                circleId: CircleId('alert_${alert.id}_circle_$circleIndex'),
                center: center,
                radius: radiusMeters,
                strokeColor: alertColor,
                strokeWidth: 2,
                fillColor: alertColor.withValues(alpha: 0.18),
              ),
            );

            if (alert.latitude == null || alert.longitude == null) {
              final markerHue = _markerHueForAlert(alert);
              markers.add(
                Marker(
                  markerId:
                      MarkerId('alert_${alert.id}_circle_center_$circleIndex'),
                  position: center,
                  icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
                  infoWindow: InfoWindow(
                    title: alert.title,
                    snippet: _buildAlertSnippet(alert),
                  ),
                ),
              );
            }

            circleIndex += 1;
          }
          break;
      }
    }
  }

  return _AlertMapOverlays(
    markers: markers,
    polygons: polygons,
    circles: circles,
  );
}

/// Build map overlays for danger zones
_AlertMapOverlays _buildDangerZoneOverlays(List<DangerZone> zones) {
  final markers = <Marker>{};
  final polygons = <Polygon>{};
  final circles = <Circle>{};

  for (final zone in zones) {
    final zoneColor = _getDangerZoneColor(zone.riskLevel);
    final markerHue = _getDangerZoneMarkerHue(zone.riskLevel);

    if (zone.geometryType == DangerZoneGeometryType.circle) {
      // Circle geometry
      if (zone.centerLatitude != null && 
          zone.centerLongitude != null && 
          zone.radiusMeters != null) {
        final center = LatLng(zone.centerLatitude!, zone.centerLongitude!);
        
        circles.add(
          Circle(
            circleId: CircleId('danger_zone_${zone.id}'),
            center: center,
            radius: zone.radiusMeters!,
            strokeColor: zoneColor,
            strokeWidth: 3,
            fillColor: zoneColor.withValues(alpha: 0.25),
          ),
        );

        markers.add(
          Marker(
            markerId: MarkerId('danger_zone_marker_${zone.id}'),
            position: center,
            icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
            infoWindow: InfoWindow(
              title: '⚠️ ${zone.name}',
              snippet: '${zone.riskLevel.displayName} - ${zone.formattedCrimeTypes}',
            ),
          ),
        );
      }
    } else if (zone.geometryType == DangerZoneGeometryType.polygon) {
      // Polygon geometry
      if (zone.polygonPoints != null && zone.polygonPoints!.length >= 3) {
        polygons.add(
          Polygon(
            polygonId: PolygonId('danger_zone_${zone.id}'),
            points: zone.polygonPoints!,
            strokeColor: zoneColor,
            strokeWidth: 3,
            fillColor: zoneColor.withValues(alpha: 0.25),
          ),
        );

        // Add marker at centroid
        final centroid = zone.center;
        markers.add(
          Marker(
            markerId: MarkerId('danger_zone_marker_${zone.id}'),
            position: centroid,
            icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
            infoWindow: InfoWindow(
              title: '⚠️ ${zone.name}',
              snippet: '${zone.riskLevel.displayName} - ${zone.formattedCrimeTypes}',
            ),
          ),
        );
      }
    }
  }

  return _AlertMapOverlays(
    markers: markers,
    polygons: polygons,
    circles: circles,
  );
}

/// Get color for danger zone based on risk level
Color _getDangerZoneColor(DangerZoneRiskLevel riskLevel) {
  switch (riskLevel) {
    case DangerZoneRiskLevel.critical:
      return const Color(0xFFB71C1C); // Dark red
    case DangerZoneRiskLevel.high:
      return const Color(0xFFD32F2F); // Red
    case DangerZoneRiskLevel.medium:
      return const Color(0xFFFF9800); // Orange
    case DangerZoneRiskLevel.low:
      return const Color(0xFFFFC107); // Amber
  }
}

/// Get marker hue for danger zone based on risk level
double _getDangerZoneMarkerHue(DangerZoneRiskLevel riskLevel) {
  switch (riskLevel) {
    case DangerZoneRiskLevel.critical:
      return BitmapDescriptor.hueRed;
    case DangerZoneRiskLevel.high:
      return BitmapDescriptor.hueRose;
    case DangerZoneRiskLevel.medium:
      return BitmapDescriptor.hueOrange;
    case DangerZoneRiskLevel.low:
      return BitmapDescriptor.hueYellow;
  }
}

/// Converts admin-provided metadata into concrete geometries. The parser is
/// intentionally defensive so that it can tolerate a range of Supabase stored
/// structures (single object, list of zones, or GeoJSON Feature collections).
List<_AlertGeometry> _extractGeometries(SafetyAlert alert) {
  final metadata = alert.metadata;
  if (metadata == null || metadata.isEmpty) {
    return const [];
  }

  final geometries = <_AlertGeometry>[];

  void collect(dynamic data) {
    if (data == null) {
      return;
    }

    if (data is Map<String, dynamic>) {
      final typeValue = (data['geometry_type'] ?? data['type'] ?? data['shape'])
          ?.toString()
          .toLowerCase();

      final zones = data['zones'];
      if (zones is List) {
        for (final zone in zones) {
          collect(zone);
        }
      }

      final geometryNode = data['geometry'];
      if (geometryNode != null) {
        collect(geometryNode);
      }

      if (typeValue == 'featurecollection') {
        final features = data['features'];
        if (features is List) {
          for (final feature in features) {
            collect(feature);
          }
        }
        return;
      }

      if (typeValue == 'feature') {
        collect(data['geometry']);
        return;
      }

      final polygonPoints = _parsePolygonPoints(data);
      final circleDefinition = _parseCircleDefinition(data, alert);

      if (typeValue == 'polygon' || typeValue == 'multipolygon') {
        if (polygonPoints != null && polygonPoints.length >= 3) {
          geometries.add(_AlertGeometry.polygon(polygonPoints));
        }
        return;
      }

      if (typeValue == 'circle' ||
          typeValue == 'buffer' ||
          typeValue == 'radius') {
        if (circleDefinition != null) {
          geometries.add(
            _AlertGeometry.circle(
              circleDefinition.center,
              circleDefinition.radiusMeters,
            ),
          );
        }
        return;
      }

      if (polygonPoints != null && polygonPoints.length >= 3) {
        geometries.add(_AlertGeometry.polygon(polygonPoints));
        return;
      }

      if (circleDefinition != null) {
        geometries.add(
          _AlertGeometry.circle(
            circleDefinition.center,
            circleDefinition.radiusMeters,
          ),
        );
        return;
      }

      final coordinatesNode = data['coordinates'];
      if (coordinatesNode != null) {
        collect(coordinatesNode);
      }
      return;
    }

    if (data is List) {
      if (data.isEmpty) {
        return;
      }

      if (data.first is Map) {
        for (final element in data) {
          collect(element);
        }
        return;
      }

      if (data.first is List) {
        // Attempt to parse the list as a nested polygon ring first. If parsing
        // fails, walk the children recursively and try again.
        final maybePolygon = _parseLatLngList(data);
        if (maybePolygon != null && maybePolygon.length >= 3) {
          geometries.add(_AlertGeometry.polygon(maybePolygon));
          return;
        }

        for (final element in data) {
          collect(element);
        }
        return;
      }

      final maybePolygon = _parseLatLngList(data);
      if (maybePolygon != null && maybePolygon.length >= 3) {
        geometries.add(_AlertGeometry.polygon(maybePolygon));
      }
    }
  }

  collect(metadata);
  return geometries;
}

/// Attempts to parse polygon points from a metadata node. Supports both
/// GeoJSON-style maps and simple arrays of coordinates.
List<LatLng>? _parsePolygonPoints(Map<String, dynamic> data) {
  final coordinates = data['coordinates'];
  if (coordinates is List && coordinates.isNotEmpty) {
    if (coordinates.first is List) {
      // Geometries following GeoJSON wrap polygon coordinates inside another
      // list that represents the outer linear ring.
      final flatCoordinates =
          coordinates.first is List && (coordinates.first as List).isNotEmpty
              ? coordinates.first
              : coordinates;
      final parsed = _parseLatLngList(flatCoordinates);
      if (parsed != null && parsed.isNotEmpty) {
        return parsed;
      }
    }
  }

  final polygon = data['polygon'] ?? data['polygon_points'] ?? data['boundary'];
  if (polygon != null) {
    if (polygon is List) {
      final parsed = _parseLatLngList(polygon);
      if (parsed != null && parsed.isNotEmpty) {
        return parsed;
      }
    } else if (polygon is Map<String, dynamic>) {
      final points = polygon['points'];
      if (points is List) {
        final parsed = _parseLatLngList(points);
        if (parsed != null && parsed.isNotEmpty) {
          return parsed;
        }
      }
    }
  }

  return null;
}

/// Parses any circle related metadata into a deterministic circle definition.
_CircleDefinition? _parseCircleDefinition(
    Map<String, dynamic> data, SafetyAlert alert) {
  LatLng? center;
  double? radiusMeters;

  center = _parseLatLng(
        data['center'] ??
            data['centroid'] ??
            data['center_point'] ??
            {
              'lat': data['center_lat'],
              'lng': data['center_lng'] ?? data['center_long'] ?? data['lon'],
            },
      ) ??
      (alert.latitude != null && alert.longitude != null
          ? LatLng(alert.latitude!, alert.longitude!)
          : null);

  final radiusCandidates = [
    data['radius_meters'],
    data['radiusMeters'],
    data['radius_in_meters'],
    data['radius'],
    data['radius_m'],
    data['buffer'],
  ];

  for (final candidate in radiusCandidates) {
    final parsed = _parseDouble(candidate);
    if (parsed != null) {
      radiusMeters = parsed;
      break;
    }
  }

  if (radiusMeters == null) {
    final radiusKmCandidates = [
      data['radius_km'],
      data['radiusKm'],
      data['radius_in_km'],
    ];
    for (final candidate in radiusKmCandidates) {
      final parsed = _parseDouble(candidate);
      if (parsed != null) {
        radiusMeters = parsed * 1000;
        break;
      }
    }
  }

  if (center == null || radiusMeters == null || radiusMeters <= 0) {
    return null;
  }

  return _CircleDefinition(center, radiusMeters);
}

/// Safely parses a list of coordinate nodes into `LatLng` positions. Returns
/// null if any coordinate is malformed so upstream callers can try alternative
/// parsing strategies.
List<LatLng>? _parseLatLngList(dynamic data) {
  if (data is! List) {
    return null;
  }

  final points = <LatLng>[];
  for (final item in data) {
    final latLng = _parseLatLng(item);
    if (latLng == null) {
      return null;
    }
    points.add(latLng);
  }
  return points;
}

/// Parses a single coordinate node into a `LatLng`. Supports map, list, and
/// already constructed LatLng inputs.
LatLng? _parseLatLng(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is LatLng) {
    return value;
  }

  if (value is Map) {
    final latCandidate =
        _parseDouble(value['lat'] ?? value['latitude'] ?? value['y']);
    final lngCandidate = _parseDouble(
        value['lng'] ?? value['lon'] ?? value['longitude'] ?? value['x']);
    if (latCandidate != null && lngCandidate != null) {
      return LatLng(latCandidate, lngCandidate);
    }

    final coordinates = value['coordinates'];
    if (coordinates != null) {
      return _parseLatLng(coordinates);
    }
  }

  if (value is List && value.length >= 2) {
    final first = _parseDouble(value[0]);
    final second = _parseDouble(value[1]);
    if (first != null && second != null) {
      final firstLooksLat = first.abs() <= 90 && second.abs() <= 180;
      final lat = firstLooksLat ? first : second;
      final lng = firstLooksLat ? second : first;
      return LatLng(lat, lng);
    }
  }

  if (value is String && value.contains(',')) {
    final parts = value.split(',');
    if (parts.length >= 2) {
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
  }

  return null;
}

/// Attempts to convert arbitrary numeric values into doubles.
double? _parseDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

/// Derives the Google Maps hue (0-360 degrees) that best matches the alert's
/// severity to keep markers visually consistent with polygons and circles.
double _markerHueForAlert(SafetyAlert alert) {
  switch (alert.severity.toLowerCase()) {
    case 'critical':
      return BitmapDescriptor.hueRed;
    case 'warning':
      return BitmapDescriptor.hueOrange;
    case 'high':
      return BitmapDescriptor.hueOrange;
    case 'medium':
      return BitmapDescriptor.hueYellow;
    case 'info':
    default:
      return BitmapDescriptor.hueAzure;
  }
}

/// Picks the fill/stroke color for the alert. If admins supply a hexadecimal
/// color override in metadata it is honoured, otherwise the severity level
/// determines the palette.
Color _resolveAlertColor(SafetyAlert alert) {
  final metadataColor = _parseColorString(alert.metadata?['color'] ??
      alert.metadata?['stroke_color'] ??
      alert.metadata?['fill_color']);
  if (metadataColor != null) {
    return metadataColor;
  }

  switch (alert.severity.toLowerCase()) {
    case 'critical':
      return Colors.red.shade600;
    case 'warning':
    case 'high':
      return Colors.orange.shade600;
    case 'medium':
      return Colors.amber.shade700;
    case 'info':
    default:
      return Colors.blue.shade600;
  }
}

/// Tries to convert a hex string (e.g. `#FF0000` or `FF0000`) into a `Color`.
Color? _parseColorString(dynamic value) {
  if (value is! String) {
    return null;
  }

  var cleaned = value.trim();
  if (cleaned.isEmpty) {
    return null;
  }

  if (cleaned.startsWith('#')) {
    cleaned = cleaned.substring(1);
  }

  if (cleaned.length == 6) {
    cleaned = 'FF$cleaned';
  }

  if (cleaned.length != 8) {
    return null;
  }

  final parsed = int.tryParse(cleaned, radix: 16);
  if (parsed == null) {
    return null;
  }
  return Color(parsed);
}

/// Generates a concise info window snippet so markers remain readable even on
/// compact screens.
String _buildAlertSnippet(SafetyAlert alert) {
  final buffer = StringBuffer();
  if (alert.priority.isNotEmpty) {
    buffer.write(alert.priority.toUpperCase());
  }
  if (alert.message.isNotEmpty) {
    if (buffer.isNotEmpty) {
      buffer.write(' • ');
    }
    final trimmed = alert.message.length > 64
        ? '${alert.message.substring(0, 61)}...'
        : alert.message;
    buffer.write(trimmed);
  }
  return buffer.toString();
}

/// Computes the centroid of a polygon using the simple average of its points.
/// This is sufficient for small areas and lets us drop a marker when admins
/// only provide polygon coordinates without explicit lat/lng.
LatLng _computePolygonCentroid(List<LatLng> points) {
  if (points.isEmpty) {
    return const LatLng(0, 0);
  }

  double latitudeSum = 0;
  double longitudeSum = 0;
  for (final point in points) {
    latitudeSum += point.latitude;
    longitudeSum += point.longitude;
  }

  return LatLng(latitudeSum / points.length, longitudeSum / points.length);
}

class _EmergencyServiceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String number;
  final Color color;
  final String? description;

  const _EmergencyServiceItem({
    required this.icon,
    required this.title,
    required this.number,
    required this.color,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // Close the dialog first
          Navigator.of(context).pop();

          try {
            // Import url_launcher for phone calls
            final Uri phoneUri = Uri(scheme: 'tel', path: number);

            // Show confirmation dialog before calling
            final bool? shouldCall = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Call $title?'),
                content: Text('This will call $number'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Call'),
                  ),
                ],
              ),
            );

            if (shouldCall == true) {
              // Try to launch the phone app
              bool launched = false;
              try {
                launched = await launchUrl(
                  phoneUri,
                  mode: LaunchMode.externalApplication,
                );
              } catch (e) {
                AppLogger.error('Error launching phone app', e);
              }

              // Show feedback
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        launched ? Icons.phone : Icons.error,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(launched
                          ? 'Opening phone app to call $title: $number'
                          : 'Could not open phone app. Number: $number'),
                    ],
                  ),
                  backgroundColor: launched ? color : Colors.red,
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }
          } catch (e) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not make call: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
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
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
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
}
