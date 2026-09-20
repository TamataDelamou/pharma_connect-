import 'package:equatable/equatable.dart';

class DailyStats extends Equatable {
  final DateTime date;
  final int consultationsCount;
  final int prescriptionsCount;
  final int reservationsCount;
  final int deliveriesCount;
  final int transactionsCount;
  final int revenue;

  const DailyStats({
    required this.date,
    required this.consultationsCount,
    required this.prescriptionsCount,
    required this.reservationsCount,
    required this.deliveriesCount,
    required this.transactionsCount,
    required this.revenue,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) => DailyStats(
    date: DateTime.parse(json['stat_date'] as String),
    consultationsCount: json['consultations_count'] as int? ?? 0,
    prescriptionsCount: json['prescriptions_count'] as int? ?? 0,
    reservationsCount: json['reservations_count'] as int? ?? 0,
    deliveriesCount: json['deliveries_count'] as int? ?? 0,
    transactionsCount: json['transactions_count'] as int? ?? 0,
    revenue: json['revenue'] as int? ?? 0,
  );

  @override
  List<Object?> get props => [
    date,
    consultationsCount,
    prescriptionsCount,
    reservationsCount,
    deliveriesCount,
    transactionsCount,
    revenue,
  ];
}

class PharmacyPerformance extends Equatable {
  final String id;
  final String name;
  final String? city;
  final int totalReservations;
  final int totalDeliveries;
  final int totalTransactions;
  final int totalRevenue;
  final double? avgRating;
  final int productsInStock;
  final int activeAlerts;

  const PharmacyPerformance({
    required this.id,
    required this.name,
    this.city,
    required this.totalReservations,
    required this.totalDeliveries,
    required this.totalTransactions,
    required this.totalRevenue,
    this.avgRating,
    required this.productsInStock,
    required this.activeAlerts,
  });

  factory PharmacyPerformance.fromJson(Map<String, dynamic> json) =>
      PharmacyPerformance(
        id: json['id'] as String,
        name: json['name'] as String,
        city: json['city'] as String?,
        totalReservations: json['total_reservations'] as int? ?? 0,
        totalDeliveries: json['total_deliveries'] as int? ?? 0,
        totalTransactions: json['total_transactions'] as int? ?? 0,
        totalRevenue: json['total_revenue'] as int? ?? 0,
        avgRating: (json['avg_rating'] as num?)?.toDouble(),
        productsInStock: json['products_in_stock'] as int? ?? 0,
        activeAlerts: json['active_alerts'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [
    id,
    name,
    city,
    totalReservations,
    totalDeliveries,
    totalTransactions,
    totalRevenue,
    avgRating,
    productsInStock,
    activeAlerts,
  ];
}

class ProductPerformance extends Equatable {
  final String id;
  final String name;
  final String genericName;
  final String? category;
  final int prescriptionCount;
  final int reservationCount;
  final int totalQuantitySold;
  final double avgPrice;
  final int pharmaciesWithStock;
  final int totalStockQuantity;

  const ProductPerformance({
    required this.id,
    required this.name,
    required this.genericName,
    this.category,
    required this.prescriptionCount,
    required this.reservationCount,
    required this.totalQuantitySold,
    required this.avgPrice,
    required this.pharmaciesWithStock,
    required this.totalStockQuantity,
  });

  factory ProductPerformance.fromJson(Map<String, dynamic> json) =>
      ProductPerformance(
        id: json['id'] as String,
        name: json['name'] as String,
        genericName: json['generic_name'] as String? ?? '',
        category: json['category'] as String?,
        prescriptionCount: json['prescription_count'] as int? ?? 0,
        reservationCount: json['reservation_count'] as int? ?? 0,
        totalQuantitySold: json['total_quantity_sold'] as int? ?? 0,
        avgPrice: (json['avg_price'] as num?)?.toDouble() ?? 0,
        pharmaciesWithStock: json['pharmacies_with_stock'] as int? ?? 0,
        totalStockQuantity: json['total_stock_quantity'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [
    id,
    name,
    genericName,
    category,
    prescriptionCount,
    reservationCount,
    totalQuantitySold,
    avgPrice,
    pharmaciesWithStock,
    totalStockQuantity,
  ];
}

class AnalyticsSummary {
  final int totalConsultations;
  final int totalPrescriptions;
  final int totalReservations;
  final int totalDeliveries;
  final int totalRevenue;
  final double revenueGrowth;
  final int activePharmacies;
  final int lowStockProducts;
  final int pendingAlerts;

  // Arbitrage porteur de projet (20/09/2026) : AnalyticsService.getSummary()
  // appelait getTodayStats() sans jamais exploiter son retour - methode
  // confirmee pure (lecture seule, aucun effet de bord) donc Cas 1 retenu
  // (integrer le retour dans le payload plutot que separer get/write).
  final DailyStats? todayStats;

  const AnalyticsSummary({
    required this.totalConsultations,
    required this.totalPrescriptions,
    required this.totalReservations,
    required this.totalDeliveries,
    required this.totalRevenue,
    this.revenueGrowth = 0,
    this.activePharmacies = 0,
    this.lowStockProducts = 0,
    this.pendingAlerts = 0,
    this.todayStats,
  });
}
