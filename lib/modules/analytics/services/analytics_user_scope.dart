import 'package:pharma_connect/core/services/supabase_service.dart';

/// Contexte d'accès BI de l'utilisateur courant (Module 28, BI-1/BI-2/BI-7).
///
/// Les 4 vues matérialisées du module ne portent aucune RLS (impossible en
/// PostgreSQL) : l'étanchéité réseau/officine est portée soit par les vues
/// `_scoped` (dont la clause WHERE est elle-même la garde d'accès, voir la
/// migration `20260905070000_analytics_module_fixes.sql`), soit par
/// `get_pharmacy_daily_stats()`, une fonction SECURITY DEFINER qui vérifie
/// l'accès en son sein. Ce contexte ne remplace donc PAS ces gardes
/// côté serveur — il évite seulement à la couche Dart d'appeler la mauvaise
/// vue/fonction pour le rôle courant (un mauvais choix ici renvoie au pire
/// une liste vide, jamais une fuite : les gardes réelles restent en base).
class AnalyticsUserScope {
  final String? userId;
  final String? role;
  final String? pharmacyId;
  final bool isGsgAdmin;

  const AnalyticsUserScope({
    this.userId,
    this.role,
    this.pharmacyId,
    this.isGsgAdmin = false,
  });

  bool get isPharmacyStaff => role == 'pharmacien' && pharmacyId != null;

  static Future<AnalyticsUserScope> resolveCurrent() async {
    final userId = SupabaseService().currentUser?.id;
    if (userId == null) return const AnalyticsUserScope();
    final client = SupabaseService().client;
    try {
      final results = await Future.wait([
        client
            .from('profiles')
            .select('role, pharmacy_id')
            .eq('id', userId)
            .maybeSingle(),
        client
            .from('admin_users')
            .select('id')
            .eq('user_id', userId)
            .eq('is_active', true)
            .maybeSingle(),
      ]);
      final profile = results[0] as Map<String, dynamic>?;
      final adminRow = results[1] as Map<String, dynamic>?;
      return AnalyticsUserScope(
        userId: userId,
        role: profile?['role'] as String?,
        pharmacyId: profile?['pharmacy_id'] as String?,
        isGsgAdmin: adminRow != null,
      );
    } catch (e) {
      // Contexte incomplet plutôt que crash : les vues/fonctions scopées
      // n'accorderont de toute façon rien à un utilisateur non résolu.
      return AnalyticsUserScope(userId: userId);
    }
  }
}
