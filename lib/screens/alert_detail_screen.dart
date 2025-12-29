import 'package:flutter/material.dart';
import 'package:security_311_user/models/alert.dart';
import 'package:security_311_user/utils/app_utils.dart';
import 'package:security_311_user/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

/// Detailed view of a safety alert
/// 
/// Shows full information including images, description,
/// location, and action buttons
class AlertDetailScreen extends StatelessWidget {
  final SafetyAlert alert;

  const AlertDetailScreen({
    super.key,
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareAlert(context),
            tooltip: 'Share Alert',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Alert Severity Banner
            _buildSeverityBanner(),
            
            // Alert Images (if any)
            if (alert.imageUrls != null && alert.imageUrls!.isNotEmpty)
              _buildImageGallery(),
            
            // Alert Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alert Type Badge
                  _buildTypeBadge(context),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    alert.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Timestamp & Location
                  _buildMetaInfo(context),
                  const SizedBox(height: 24),
                  
                  // Description
                  _buildSection(
                    context,
                    'Details',
                    Icons.description,
                    alert.message,
                  ),
                  const SizedBox(height: 24),
                  
                  // Location Information
                  if (alert.locationDescription != null)
                    _buildSection(
                      context,
                      'Location',
                      Icons.location_on,
                      alert.locationDescription!,
                    ),
                  const SizedBox(height: 24),
                  
                  // Additional Metadata
                  if (alert.metadata != null)
                    _buildMetadataSection(context),
                  
                  // Action Buttons
                  const SizedBox(height: 32),
                  _buildActionButtons(context),
                  
                  const SizedBox(height: 16),
                  
                  // Report Info
                  _buildReportInfo(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityBanner() {
    Color bannerColor;
    IconData icon;
    String severityText;

    switch (alert.severity.toLowerCase()) {
      case 'critical':
        bannerColor = Colors.red;
        icon = Icons.error;
        severityText = 'CRITICAL ALERT';
        break;
      case 'warning':
        bannerColor = Colors.orange;
        icon = Icons.warning;
        severityText = 'WARNING';
        break;
      default:
        bannerColor = Colors.blue;
        icon = Icons.info;
        severityText = 'INFORMATION';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: bannerColor,
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            severityText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              alert.priority.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: alert.imageUrls!.length,
        itemBuilder: (context, index) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                alert.imageUrls![index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 64, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Image not available'),
                        ],
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
              // Image counter
              if (alert.imageUrls!.length > 1)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${index + 1} / ${alert.imageUrls!.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTypeBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getAlertTypeIcon(),
            size: 16,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            _formatAlertType(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfo(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Text(
          AppUtils.formatRelativeTime(alert.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
        if (alert.region != null) ...[
          const SizedBox(width: 16),
          Icon(
            Icons.location_on,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${alert.city ?? ''}, ${alert.region}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    String content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    final metadata = alert.metadata;
    if (metadata == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline, size: 20),
            const SizedBox(width: 8),
            Text(
              'Additional Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...metadata.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '${_formatKey(entry.key)}:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.value.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Primary action button based on alert type
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handlePrimaryAction(context),
            icon: const Icon(Icons.phone),
            label: const Text('Call Emergency Services'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Secondary actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showOnMap(context),
                icon: const Icon(Icons.map),
                label: const Text('View Map'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _reportIssue(context),
                icon: const Icon(Icons.flag),
                label: const Text('Report'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Verified Alert',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This alert has been verified and issued by authorized personnel. '
            'Please take appropriate action and stay safe.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Alert ID: ${alert.id.substring(0, 8)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontFamily: 'monospace',
                ),
          ),
        ],
      ),
    );
  }

  IconData _getAlertTypeIcon() {
    switch (alert.type.toLowerCase()) {
      case 'wanted_person':
        return Icons.person_search;
      case 'vehicle_alert':
        return Icons.directions_car;
      case 'lost_items':
        return Icons.search;
      case 'found_items':
        return Icons.inventory;
      case 'crime_warning':
        return Icons.warning;
      case 'weather_alert':
        return Icons.wb_cloudy;
      case 'road_closure':
        return Icons.block;
      default:
        return Icons.notifications;
    }
  }

  String _formatAlertType() {
    return alert.type.replaceAll('_', ' ').toUpperCase();
  }

  String _formatKey(String key) {
    return key.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  void _handlePrimaryAction(BuildContext context) async {
    // Call emergency services based on alert type
    final url = Uri.parse('tel:${AppConstants.emergencyNumbers['police']}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        AppUtils.showErrorSnackBar(
          context,
          'Unable to make phone call',
        );
      }
    }
  }

  void _showOnMap(BuildContext context) {
    if (alert.latitude != null && alert.longitude != null) {
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${alert.latitude},${alert.longitude}',
      );
      launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      AppUtils.showInfoSnackBar(context, 'Location coordinates not available');
    }
  }

  void _reportIssue(BuildContext context) {
    AppUtils.showConfirmationDialog(
      context,
      title: 'Report Issue',
      message: 'Do you want to report an issue with this alert?',
      confirmText: 'Report',
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        AppUtils.showSuccessSnackBar(
          context,
          'Thank you for your report. Our team will review it.',
        );
      }
    });
  }

  void _shareAlert(BuildContext context) {
    // In a real app, use share_plus package to share this text:
    // final shareText = '''
    // 3:11 Security Alert
    // 
    // ${alert.title}
    // 
    // ${alert.message}
    // 
    // Location: ${alert.city}, ${alert.region}
    // Severity: ${alert.severity}
    // 
    // Stay safe!
    // ''';
    
    AppUtils.showInfoSnackBar(context, 'Share functionality coming soon');
  }
}

