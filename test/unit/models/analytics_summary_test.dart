import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_connect/modules/analytics/models/daily_stats.dart';

// Arbitrage porteur de projet (20/09/2026) : AnalyticsService.getSummary()
// appelait getTodayStats() sans jamais exploiter son retour dans le payload
// restitue. getTodayStats() confirmee pure (lecture seule Supabase, aucun
// effet de bord) -> Cas 1 retenu : integrer le retour dans le payload.
//
// AnalyticsService.getSummary() dependant directement de Supabase (aucune
// abstraction/mock injectable pour SupabaseService dans ce projet -
// mockito/mocktail absents de pubspec.yaml), son comportement reseau n'est
// pas testable en unitaire sans backend reel. Ce test couvre donc ce qui
// est reellement testable sans reseau : le contrat du modele AnalyticsSummary
// porte bien les statistiques du jour, au lieu de les rejeter silencieusement.
void main() {
  group('AnalyticsSummary.todayStats', () {
    test('defaults to null when no daily stats are supplied', () {
      const summary = AnalyticsSummary(
        totalConsultations: 10,
        totalPrescriptions: 5,
        totalReservations: 3,
        totalDeliveries: 2,
        totalRevenue: 100000,
      );

      expect(summary.todayStats, isNull);
    });

    test('carries the DailyStats instance when supplied', () {
      final today = DailyStats(
        date: DateTime(2026, 9, 20),
        consultationsCount: 4,
        prescriptionsCount: 2,
        reservationsCount: 1,
        deliveriesCount: 1,
        transactionsCount: 3,
        revenue: 15000,
      );

      final summary = AnalyticsSummary(
        totalConsultations: 10,
        totalPrescriptions: 5,
        totalReservations: 3,
        totalDeliveries: 2,
        totalRevenue: 100000,
        todayStats: today,
      );

      expect(summary.todayStats, isNotNull);
      expect(summary.todayStats!.consultationsCount, 4);
      expect(summary.todayStats!.revenue, 15000);
      expect(summary.todayStats!.date, DateTime(2026, 9, 20));
    });
  });
}
