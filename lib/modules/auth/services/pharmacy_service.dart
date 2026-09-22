import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

/// Soumission de candidature d'officine (RG-AUT-01, audit Module 1 —
/// 29/08/2026). Écrit dans public.pharmacies à l'état 'pending' — jamais
/// 'verified'/'active' : la policy RLS `pharmacies_insert_own_pending`
/// (migration 20260829013000) l'impose déjà côté serveur, ce service ne
/// fait que refléter honnêtement cette contrainte côté client plutôt que de
/// la dupliquer. Le passage à 'verified'/'active' — et le rattachement de
/// `profiles.pharmacy_id` qui en découle — est un geste back-office
/// (`is_gsg_admin()`), hors périmètre de ce module (Module 15 — ADM).
class PharmacyService {
  SupabaseClient get _client => SupabaseService().client;

  Future<Map<String, dynamic>> submitLicenseVerification({
    required String pharmacyName,
    required String managerName,
    required String phone,
    required String address,
    String? licenseNumber,
  }) async {
    final userId = SupabaseService().currentUser?.id;
    if (userId == null) {
      throw StateError(
        'Impossible de soumettre une candidature d\'officine sans utilisateur authentifié.',
      );
    }
    return await _client
        .from('pharmacies')
        .insert({
          'name': pharmacyName,
          'manager_id': userId,
          'manager_name': managerName,
          'phone': phone,
          'address': address,
          if (licenseNumber != null && licenseNumber.isNotEmpty)
            'license_number': licenseNumber,
          'status': 'pending',
        })
        .select()
        .single();
  }
}
