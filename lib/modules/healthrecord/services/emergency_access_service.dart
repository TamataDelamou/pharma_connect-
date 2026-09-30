import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../models/emergency_access.dart';

/// C219 : refus du serveur sur un accès d'urgence, message lisible tel
/// qu'affiché à l'utilisateur.
class EmergencyAccessException implements Exception {
  final String message;
  const EmergencyAccessException(this.message);

  @override
  String toString() => message;
}

/// C219 / D63 : accès d'urgence au dossier de santé (bris de glace).
/// Un professionnel vérifié, affilié à l'hôpital où le patient est au triage,
/// déclare l'urgence avec un motif ; l'accès dure 24 heures, est tracé et
/// visible par le patient, qui peut y mettre fin. Tout passe par des RPC
/// contrôlées côté serveur (aucune écriture directe dans la table).
class EmergencyAccessService {
  final _client = SupabaseService().client;

  /// Longueur minimale du motif, identique au contrôle serveur.
  static const int minReasonLength = 10;

  static String _message(PostgrestException e) {
    final message = e.message.replaceFirst(RegExp(r'^URGENCE: '), '');
    if (message.isEmpty) return 'Opération refusée.';
    return message[0].toUpperCase() + message.substring(1);
  }

  /// Déclare une urgence pour le patient d'un triage. Retourne l'identifiant
  /// de l'accès accordé.
  Future<String> declare({
    required String triagePatientId,
    required String reason,
  }) async {
    try {
      final response = await _client.rpc(
        'declare_emergency_access',
        params: {'p_triage_patient_id': triagePatientId, 'p_reason': reason},
      );
      return response as String;
    } on PostgrestException catch (e) {
      throw EmergencyAccessException(_message(e));
    }
  }

  /// Accès d'urgence visibles par l'utilisateur : ceux qui concernent son
  /// dossier (patient) ou qu'il a déclarés (professionnel).
  Future<List<EmergencyAccess>> list() async {
    try {
      final response = await _client.rpc('list_emergency_access');
      return (response as List)
          .map((e) => EmergencyAccess.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw EmergencyAccessException(_message(e));
    }
  }

  /// Met fin à un accès d'urgence en cours (patient, professionnel ou GSG).
  Future<void> end(String grantId) async {
    try {
      await _client.rpc(
        'end_emergency_access',
        params: {'p_grant_id': grantId},
      );
    } on PostgrestException catch (e) {
      throw EmergencyAccessException(_message(e));
    }
  }
}
