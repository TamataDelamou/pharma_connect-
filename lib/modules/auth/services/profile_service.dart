import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

/// public.profiles n'a jusqu'ici jamais été écrite par le produit : le nom et
/// le rôle saisis à l'inscription (register_screen.dart) n'étaient conservés
/// qu'en mémoire côté AuthProvider, perdus à la fermeture de l'app. upsert
/// plutôt qu'insert : appelé aussi bien à l'inscription (première écriture)
/// qu'à la connexion d'un compte existant (rafraîchit phone/email sans rien
/// écraser d'autre — pharmacy_id est intentionnellement absent d'ici, réservé
/// à l'assignation post-vérification de licence, RG-AUT-01, voir
/// pharmacy_service.dart et la migration 20260829013000).
class ProfileService {
  SupabaseClient get _client => SupabaseService().client;

  /// Retourne la ligne persistée (audit Module 1, 29/08/2026) : AuthProvider
  /// en a besoin pour relire `role`/`pharmacy_id` après écriture, y compris
  /// à une simple connexion où ces valeurs ne sont pas re-fournies en
  /// paramètre — sans quoi needsLicenseVerification serait toujours faux
  /// pour un pharmacien qui se reconnecte au lieu de s'inscrire.
  ///
  /// C211 / D58 : le rôle n'est envoyé qu'à la création du profil. Sur un
  /// profil existant (connexion, ou nouvelle inscription avec un identifiant
  /// déjà connu), le serveur refuse tout changement de rôle hors
  /// administration GSG (42501) : le rôle en base fait foi et est relu.
  Future<Map<String, dynamic>?> upsertProfile({
    required String id,
    String? phone,
    String? fullName,
    String? role,
  }) async {
    final existing = await _client
        .from('profiles')
        .select('id')
        .eq('id', id)
        .maybeSingle();
    return await _client
        .from('profiles')
        .upsert({
          'id': id,
          if (phone != null) 'phone': phone,
          if (fullName != null) 'full_name': fullName,
          if (role != null && existing == null) 'role': role,
        })
        .select()
        .single();
  }

  /// Audit Module 5 (ORD, 29/08/2026) : prescription_upload_screen.dart
  /// envoyait un nom de patient en dur ('Jean Dupont') faute d'un moyen
  /// simple de lire le nom réel de l'utilisateur connecté — AuthProvider ne
  /// conserve pas full_name après l'inscription (seulement écrit via
  /// upsertProfile ci-dessus, jamais relu). Lecture best-effort : un échec
  /// réseau ici ne doit pas bloquer le dépôt d'une ordonnance.
  Future<String?> getFullName(String userId) async {
    try {
      final row = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      return row?['full_name'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// C199 : relecture du profil à la restauration d'une session existante
  /// (redémarrage de l'app), sans rien écrire. Best-effort, comme
  /// getFullName() : un échec réseau ne doit pas bloquer l'ouverture.
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      return await _client
          .from('profiles')
          .select('role, pharmacy_id')
          .eq('id', userId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }
}
