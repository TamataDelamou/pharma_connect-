import 'package:flutter/material.dart';
import '../../../core/theme/palette.dart';

class DashboardData {
  final List<StatCardData> stats;
  final List<QuickAction> actions;
  final List<ActivityItem> activities;
  final List<AlertItem> alerts;

  const DashboardData({
    required this.stats,
    required this.actions,
    required this.activities,
    required this.alerts,
  });
}

class StatCardData {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final ColorRole color;

  const StatCardData({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
  });
}

class QuickAction {
  final String label;
  final IconData icon;
  final String route;
  final ColorRole color;

  const QuickAction({
    required this.label,
    required this.icon,
    required this.route,
    required this.color,
  });
}

class ActivityItem {
  final String title;
  final String subtitle;
  final DateTime time;
  final IconData icon;
  final ColorRole color;

  const ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }
}

class AlertItem {
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;

  const AlertItem({
    required this.message,
    required this.severity,
    required this.timestamp,
  });
}

enum AlertSeverity { info, warning, danger, success }
