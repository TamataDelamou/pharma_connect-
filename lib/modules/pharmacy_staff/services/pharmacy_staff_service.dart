import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../models/staff_entry.dart';

/// C209 / D59 : personnel d'officine. Le titulaire invite un compte
/// pharmacien par son numéro ; l'employé accepte ou refuse ; le titulaire peut
/// annuler une invitation ou retirer un employé ; un employé peut quitter
/// l'officine. Toutes les règles sont appliquées par le serveur (RPC
/// pharmacy_*), jamais par l'application.
class PharmacyStaffService {
  SupabaseClient get _client => SupabaseService().client;

  /// Personnel rattaché (titulaire en tête) et invitations en attente.
  /// Réservé au titulaire de l'officine.
  Future<List<StaffEntry>> listStaff(String pharmacyId) async {
    final rows =
        await _client.rpc(
              'pharmacy_list_staff',
              params: {'p_pharmacy_id': pharmacyId},
            )
            as List<dynamic>;
    return rows
        .map((row) => StaffEntry.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> invite(String pharmacyId, String phone) async {
    await _client.rpc(
      'pharmacy_invite_staff',
      params: {'p_pharmacy_id': pharmacyId, 'p_phone': phone},
    );
  }

  Future<void> cancelInvitation(String invitationId) async {
    await _client.rpc(
      'pharmacy_cancel_invitation',
      params: {'p_invitation_id': invitationId},
    );
  }

  Future<void> removeStaff(String pharmacyId, String userId) async {
    await _client.rpc(
      'pharmacy_remove_staff',
      params: {'p_pharmacy_id': pharmacyId, 'p_user_id': userId},
    );
  }

  /// Invitations en attente adressées à l'utilisateur connecté.
  Future<List<StaffInvitation>> myInvitations() async {
    final rows = await _client.rpc('pharmacy_my_invitations') as List<dynamic>;
    return rows
        .map((row) => StaffInvitation.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> respond(String invitationId, {required bool accept}) async {
    await _client.rpc(
      'pharmacy_respond_invitation',
      params: {'p_invitation_id': invitationId, 'p_accept': accept},
    );
  }

  Future<void> leave() async {
    await _client.rpc('pharmacy_leave');
  }

  /// Vrai si l'erreur est un refus d'accès (42501) : écran réservé au
  /// titulaire.
  static bool isAccessDenied(Object error) =>
      error is PostgrestException && error.code == '42501';

  /// Message lisible d'une erreur serveur (préfixe « OFFICINE: » retiré,
  /// accents rétablis sur les messages de ces RPC).
  static String describeError(Object error) {
    if (error is! PostgrestException) {
      return 'Opération impossible, vérifiez la connexion.';
    }
    var message = error.message.replaceFirst(RegExp(r'^OFFICINE:\s*'), '');
    const accents = {
      'reserve au titulaire': 'réservé au titulaire',
      'validee': 'validée',
      'numero': 'numéro',
      'telephone': 'téléphone',
      'inscrit ': 'inscrit ',
      'deja': 'déjà',
      'rattache ': 'rattaché ',
      'rattache a': 'rattaché à',
      'traitee': 'traitée',
      'reponse': 'réponse',
      'lui-meme': 'lui-même',
      ' a une autre': ' à une autre',
      ' a son officine': ' à son officine',
      'plus validee': 'plus validée',
      'role actuel': 'rôle actuel',
    };
    accents.forEach((from, to) => message = message.replaceAll(from, to));
    if (message.isEmpty) return message;
    return message[0].toUpperCase() + message.substring(1);
  }
}
