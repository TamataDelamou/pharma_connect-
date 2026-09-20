import 'package:equatable/equatable.dart';
import 'package:pharma_connect/core/utils/currency_formatter.dart';

class NetworkDashboard extends Equatable {
  final String groupId;
  final String groupName;
  final int pharmacyCount;
  final int totalSales;
  final int totalRevenue;
  final int totalStockItems;
  final int activeAlerts;
  final int totalUsers;

  const NetworkDashboard({
    required this.groupId,
    required this.groupName,
    this.pharmacyCount = 0,
    this.totalSales = 0,
    this.totalRevenue = 0,
    this.totalStockItems = 0,
    this.activeAlerts = 0,
    this.totalUsers = 0,
  });

  NetworkDashboard copyWith({
    String? groupId,
    String? groupName,
    int? pharmacyCount,
    int? totalSales,
    int? totalRevenue,
    int? totalStockItems,
    int? activeAlerts,
    int? totalUsers,
  }) {
    return NetworkDashboard(
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      pharmacyCount: pharmacyCount ?? this.pharmacyCount,
      totalSales: totalSales ?? this.totalSales,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalStockItems: totalStockItems ?? this.totalStockItems,
      activeAlerts: activeAlerts ?? this.activeAlerts,
      totalUsers: totalUsers ?? this.totalUsers,
    );
  }

  Map<String, dynamic> toJson() => {
    'group_id': groupId,
    'group_name': groupName,
    'pharmacy_count': pharmacyCount,
    'total_sales': totalSales,
    'total_revenue': totalRevenue,
    'total_stock_items': totalStockItems,
    'active_alerts': activeAlerts,
    'total_users': totalUsers,
  };

  factory NetworkDashboard.fromJson(Map<String, dynamic> json) =>
      NetworkDashboard(
        groupId: json['group_id'] as String,
        groupName: json['group_name'] as String,
        pharmacyCount: json['pharmacy_count'] as int? ?? 0,
        totalSales: json['total_sales'] as int? ?? 0,
        totalRevenue: json['total_revenue'] as int? ?? 0,
        totalStockItems: json['total_stock_items'] as int? ?? 0,
        activeAlerts: json['active_alerts'] as int? ?? 0,
        totalUsers: json['total_users'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [
    groupId,
    groupName,
    pharmacyCount,
    totalSales,
    totalRevenue,
    totalStockItems,
    activeAlerts,
    totalUsers,
  ];

  String get formattedRevenue => CurrencyFormatter.format(totalRevenue);
}
