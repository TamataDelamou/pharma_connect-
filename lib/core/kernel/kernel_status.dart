import 'package:flutter/material.dart';

import '../theme/colors.dart';

enum KernelServiceStatus { online, degraded, offline }

class KernelService {
  final String name;
  final String icon;
  final KernelServiceStatus status;

  const KernelService({
    required this.name,
    required this.icon,
    required this.status,
  });

  Color get statusColor {
    switch (status) {
      case KernelServiceStatus.online:
        return PharmaConnectColors.accentGreen;
      case KernelServiceStatus.degraded:
        return PharmaConnectColors.accentOrange;
      case KernelServiceStatus.offline:
        return PharmaConnectColors.accentRed;
    }
  }

  String get statusLabel {
    switch (status) {
      case KernelServiceStatus.online:
        return 'Online';
      case KernelServiceStatus.degraded:
        return 'Dégradé';
      case KernelServiceStatus.offline:
        return 'Offline';
    }
  }
}

class KernelStatus {
  final bool isConnected;
  final String version;
  final List<KernelService> services;
  final DateTime lastSync;

  const KernelStatus({
    required this.isConnected,
    required this.version,
    required this.services,
    required this.lastSync,
  });

  int get onlineCount {
    return services.where((s) => s.status == KernelServiceStatus.online).length;
  }

  int get totalCount => services.length;

  bool get isFullyOperational => onlineCount == totalCount;
}
