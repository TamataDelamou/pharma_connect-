import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/core/services/push_notification_service.dart';
import 'package:uuid/uuid.dart';
import '../models/sos_alert.dart';

class SOSService {
  final _client = SupabaseService().client;
  final _uuid = const Uuid();

  Future<SOSAlert> createSOSAlert({
    required String patientId,
    required String familyMemberId,
    required String alertType,
    String? message,
    double? lat,
    double? lon,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final id = _uuid.v4();
      final data = {
        'id': id,
        'patient_id': patientId,
        'family_member_id': familyMemberId,
        'alert_type': alertType,
        if (message != null) 'message': message,
        if (lat != null) 'location_lat': lat,
        if (lon != null) 'location_lon': lon,
        'status': 'active',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'created_by': SupabaseService().currentUser?.id,
        'updated_by': SupabaseService().currentUser?.id,
      };
      final response = await _client
          .from('sos_alerts')
          .insert(data)
          .select()
          .single();

      // Send push notification to family member
      await _sendSOSNotification(familyMemberId, patientId, alertType);

      return SOSAlert.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create SOS alert: $e');
    }
  }

  Future<List<SOSAlert>> getAlertsForPatient(String patientId) async {
    try {
      final response = await _client
          .from('sos_alerts')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => SOSAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load SOS alerts: $e');
    }
  }

  Future<List<SOSAlert>> getAlertsForFamilyMember(String familyMemberId) async {
    try {
      final response = await _client
          .from('sos_alerts')
          .select()
          .eq('family_member_id', familyMemberId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => SOSAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load SOS alerts: $e');
    }
  }

  Future<void> acknowledgeSOS(String sosId, String familyMemberId) async {
    try {
      await _client.from('sos_acknowledgements').insert({
        'sos_alert_id': sosId,
        'family_member_id': familyMemberId,
        'acknowledged_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Check if all family members acknowledged
      await _checkAndUpdateStatus(sosId);
    } catch (e) {
      throw Exception('Failed to acknowledge SOS: $e');
    }
  }

  // Audit Module 22 (FAM), Étape 3 (30/08/2026), FAM-3 : le code d'origine
  // résolvait systématiquement TOUTE alerte SOS dès le premier accusé de
  // réception d'UN SEUL proche (commenté "Mock: always resolve after first
  // acknowledgment" dans le code lui-même), sans jamais vérifier que
  // l'ensemble des proches liés avait acquitté ni que le patient était
  // réellement en sécurité — motif « logique factice », même famille que
  // C56 (score de crédit)/série FID, mais ici sur une fonctionnalité de
  // sécurité/urgence. Limite structurelle assumée : `sos_alerts` n'a pas de
  // colonne d'incident partagé — un appui sur le bouton SOS crée une ligne
  // PAR proche lié actif (voir `SOSScreen._sendSOS`) — donc la corrélation
  // entre les lignes d'un même incident se fait ici par patient + type
  // d'alerte + fenêtre de création rapprochée, faute d'un identifiant
  // d'incident explicite (à envisager comme évolution de schéma séparée,
  // voir le rapport d'audit §7).
  Future<void> _checkAndUpdateStatus(String sosId) async {
    final now = DateTime.now().toUtc();
    final alertResponse = await _client
        .from('sos_alerts')
        .select()
        .eq('id', sosId)
        .single();
    final alert = alertResponse as Map<String, dynamic>;

    // Marque la copie de CE proche comme acquittée (le statut
    // `acknowledged`, prévu par la contrainte CHECK, n'était jamais
    // utilisé par le code d'origine).
    await _client
        .from('sos_alerts')
        .update({'status': 'acknowledged', 'updated_at': now.toIso8601String()})
        .eq('id', sosId);

    final createdAt = DateTime.parse(alert['created_at'] as String);
    final windowStart = createdAt.subtract(const Duration(minutes: 2));
    final windowEnd = createdAt.add(const Duration(minutes: 2));

    final siblingsResponse = await _client
        .from('sos_alerts')
        .select('id, status')
        .eq('patient_id', alert['patient_id'] as String)
        .eq('alert_type', alert['alert_type'] as String)
        .gte('created_at', windowStart.toIso8601String())
        .lte('created_at', windowEnd.toIso8601String());
    final siblings = (siblingsResponse as List).cast<Map<String, dynamic>>();

    final allAcknowledgedOrResolved = siblings.every(
      (s) => s['status'] != 'active',
    );

    // Ne clôt l'incident (`resolved`) que lorsque TOUS les proches liés de
    // cette fenêtre ont acquitté leur propre copie — remplace la
    // résolution automatique inconditionnelle au premier acquittement.
    if (allAcknowledgedOrResolved) {
      for (final sibling in siblings) {
        await _client
            .from('sos_alerts')
            .update({
              'status': 'resolved',
              'resolved_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            })
            .eq('id', sibling['id'] as String);
      }
    }
  }

  Future<void> _sendSOSNotification(
    String familyMemberId,
    String patientId,
    String alertType,
  ) async {
    try {
      final patient = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', patientId)
          .single();

      final name = (patient as Map<String, dynamic>)['full_name'] ?? 'Patient';

      final messages = {
        'medical_emergency':
            '🚨 URGENCE MÉDICALE : $name a besoin d\'aide immédiatement !',
        'accident': '🚨 ACCIDENT : $name a signalé un accident !',
        'panic': '🚨 ALERTE : $name a déclenché une alerte panique !',
        'location_share': '📍 $name partage sa position avec vous.',
      };

      final message = messages[alertType] ?? '🚨 Alerte SOS de $name';

      // Send push notification
      await _sendPush(familyMemberId, 'SOS Alerte', message);
    } catch (e) {
      // Silent fail
    }
  }

  // Audit Module 22 (FAM), Étape 3 (30/08/2026), FAM-4 : n'envoyait aucune
  // notification réelle (`print()` console uniquement), malgré un
  // commentaire indiquant l'intention de brancher `PushNotificationService`
  // — service déjà construit et utilisé ailleurs dans le projet
  // (`lib/core/services/push_notification_service.dart`,
  // `sendNotificationToUser()`), simplement jamais câblé ici. Corrigé.
  Future<void> _sendPush(String userId, String title, String message) async {
    await PushNotificationService().sendNotificationToUser(
      userId: userId,
      title: title,
      body: message,
    );
  }
}
