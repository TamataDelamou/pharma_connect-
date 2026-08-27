import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

/// public.profiles n'a jusqu'ici jamais été écrite par le produit : le nom et
/// le rôle saisis à l'inscription (register_screen.dart) n'étaient conservés
/// qu'en mémoire côté AuthProvider, perdus à la fermeture de l'app. upsert
/// plutôt qu'insert : appelé aussi bien à l'inscription (première écriture)
/// qu'à la connexion d'un compte existant (rafraîchit phone/email sans rien
/// écraser d'autre — pharmacy_id est intentionnellement absent d'ici, réservé
/// à l'assignation post-vérification de licence, RG-AUT-01).
class ProfileService {
  SupabaseClient get _client => SupabaseService().client;

  Future<void> upsertProfile({
    required String id,
    String? phone,
    String? fullName,
    String? role,
  }) async {
    await _client.from('profiles').upsert({
      'id': id,
      if (phone != null) 'phone': phone,
      if (fullName != null) 'full_name': fullName,
      if (role != null) 'role': role,
    });
  }
}
