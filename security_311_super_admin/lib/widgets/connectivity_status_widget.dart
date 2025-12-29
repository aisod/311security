import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_311_super_admin/providers/connectivity_provider.dart';

/// Widget that displays connectivity status and pending operations
///
/// Shows a banner when offline and displays sync status
class ConnectivityStatusWidget extends StatelessWidget {
  final Widget child;
  final bool showBanner;
  final bool showSyncButton;

  const ConnectivityStatusWidget({
    super.key,
    required this.child,
    this.showBanner = true,
    this.showSyncButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, _) {
        return Column(
          children: [
            // Offline banner
            if (showBanner && connectivityProvider.isOffline)
              _buildOfflineBanner(context, connectivityProvider),

            // Sync status banner
            if (showBanner &&
                connectivityProvider.isOnline &&
                connectivityProvider.pendingOperationsCount > 0)
              _buildSyncBanner(context, connectivityProvider),

            // Main content
            Expanded(child: child),
          ],
        );
      },
    );
  }

  /// Build offline status banner
  Widget _buildOfflineBanner(
      BuildContext context, ConnectivityProvider provider) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.orange.shade100,
      child: Row(
        children: [
          Icon(
            Icons.cloud_off,
            color: Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You\'re offline',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Your actions will be saved and synced when connection is restored.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (provider.pendingOperationsCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${provider.pendingOperationsCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build sync status banner
  Widget _buildSyncBanner(BuildContext context, ConnectivityProvider provider) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Icon(
            Icons.sync,
            color: Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Syncing ${provider.pendingOperationsCount} pending operations...',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Your offline actions are being synchronized.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (showSyncButton) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => provider.forcSync(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: const Text('Sync Now'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Simple connectivity indicator widget
class ConnectivityIndicator extends StatelessWidget {
  final bool showText;
  final double iconSize;

  const ConnectivityIndicator({
    super.key,
    this.showText = true,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, child) {
        final theme = Theme.of(context);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              connectivityProvider.isOnline
                  ? (connectivityProvider.hasWifi
                      ? Icons.wifi
                      : Icons.signal_cellular_4_bar)
                  : Icons.cloud_off,
              size: iconSize,
              color: connectivityProvider.isOnline ? Colors.green : Colors.red,
            ),
            if (showText) ...[
              const SizedBox(width: 6),
              Text(
                connectivityProvider.isOnline
                    ? connectivityProvider.connectionType
                    : 'Offline',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      connectivityProvider.isOnline ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Floating sync button for manual sync
class SyncFloatingActionButton extends StatelessWidget {
  const SyncFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, child) {
        // Only show if online and has pending operations
        if (!connectivityProvider.isOnline ||
            connectivityProvider.pendingOperationsCount == 0) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton.small(
          onPressed: () => connectivityProvider.forcSync(),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          tooltip:
              'Sync ${connectivityProvider.pendingOperationsCount} pending operations',
          child: Stack(
            children: [
              const Icon(Icons.sync),
              if (connectivityProvider.pendingOperationsCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${connectivityProvider.pendingOperationsCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
