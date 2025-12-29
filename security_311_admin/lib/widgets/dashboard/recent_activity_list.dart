import 'package:flutter/material.dart';

class RecentActivityList extends StatelessWidget {
  final List<Map<String, dynamic>> activities;

  const RecentActivityList({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                'No recent activity',
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
          return _buildActivityItem(context, activity);
        },
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, Map<String, dynamic> activity) {
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
              color: getActivityColor(activity['type'] ?? 'info').withValues(alpha: 0.1),
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

