import 'dart:math';
import 'package:pharma_connect/core/utils/user_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pickup_line.dart';
import '../models/reservation.dart';
import '../models/reservation_item.dart';
import '../models/reservation_status.dart';
import '../models/timeslot.dart';
import '../../../core/services/supabase_service.dart';
import '../../pos/services/pos_service.dart';

/// C243 : refus du serveur lors d'une réservation, d'une annulation ou d'un
/// retrait, message lisible tel qu'affiché à l'utilisateur.
class ReservationException implements UserFacingException {
  @override
  final String message;
  const ReservationException(this.message);

  @override
  String toString() => message;
}

/// C243 : la réservation est faite par le serveur (fonctions `reservation_*`,
/// migration 20261004020000). L'application ne fait plus que lire les tables
/// `reservations` et `reservation_items` : elle n'écrit plus ni réservation
/// ni stock. Les boîtes sont retenues, libérées et vendues par le serveur,
/// dans une seule transaction à chaque étape.
class ReservationService {
  SupabaseClient get _client => SupabaseService().client;
  static final Random _random = Random();

  static const _reservationSelect = '*, reservation_items(*)';

  Future<List<Reservation>> getReservations({ReservationStatus? status}) async {
    var query = _client.from('reservations').select(_reservationSelect);
    if (status != null) {
      query = query.eq('status', status.name);
    }
    final rows = await query.order('reserved_at', ascending: false);
    return rows.map((row) => Reservation.fromJson(row)).toList();
  }

  Future<Reservation> getReservation(String id) async {
    final row = await _client
        .from('reservations')
        .select(_reservationSelect)
        .eq('id', id)
        .single();
    return Reservation.fromJson(row);
  }

  Future<List<Reservation>> getReservationsForPharmacy(
    String pharmacyId,
  ) async {
    final rows = await _client
        .from('reservations')
        .select(_reservationSelect)
        .eq('pharmacy_id', pharmacyId)
        .order('reserved_at');
    return rows.map((row) => Reservation.fromJson(row)).toList();
  }

  Future<List<Reservation>> getReservationsForPatient(String patientId) async {
    final rows = await _client
        .from('reservations')
        .select(_reservationSelect)
        .eq('patient_id', patientId)
        .order('reserved_at', ascending: false);
    return rows.map((row) => Reservation.fromJson(row)).toList();
  }

  Future<T> _rpc<T>(String name, Map<String, dynamic> params) async {
    try {
      return await _client.rpc(name, params: params) as T;
    } on PostgrestException catch (e) {
      throw ReservationException(serverMessage(e.message));
    }
  }

  /// Réserve le panier dans une officine : le serveur retient les boîtes lot
  /// par lot et refuse si le vendable ne suffit pas. Patient, prix
  /// (indicatif), échéance de retrait (24 h) et code de retrait sont fixés
  /// par le serveur.
  Future<Reservation> createReservation({
    required String pharmacyId,
    required List<ReservationItem> items,
    String? notes,
  }) async {
    final id = await _rpc<String>('reservation_create', {
      'p_pharmacy_id': pharmacyId,
      'p_items': [
        for (final item in items)
          {'product_id': item.productId, 'quantity': item.quantity},
      ],
      'p_notes': notes,
    });
    return getReservation(id);
  }

  Future<Reservation> markAsReady(String id) async {
    await _rpc<dynamic>('reservation_mark_ready', {'p_reservation_id': id});
    return getReservation(id);
  }

  /// Annulation par le patient (la sienne) ou par l'officine (motif
  /// obligatoire) : les boîtes retenues sont libérées.
  Future<Reservation> cancelReservation(String id, {String? reason}) async {
    await _rpc<dynamic>('reservation_cancel', {
      'p_reservation_id': id,
      'p_reason': reason,
    });
    return getReservation(id);
  }

  /// Aperçu du retrait pour le personnel : prix indicatif, prix du jour,
  /// ordonnance à présenter, boîtes qui ne peuvent plus être remises.
  Future<List<PickupLine>> getPickupPreview(String id) async {
    final rows = await _rpc<List<dynamic>>('reservation_pickup_preview', {
      'p_reservation_id': id,
    });
    return rows
        .map((row) => PickupLine.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Retrait à l'officine : la réservation devient une vente au comptoir en
  /// espèces, au prix du jour. Le serveur refuse sans le code de retrait du
  /// patient. Rend l'identifiant de la vente.
  Future<String> pickUp(
    String id, {
    required String pickupCode,
    bool prescriptionChecked = false,
    bool allowPartial = false,
    String? partialReason,
  }) {
    return _rpc<String>('reservation_pickup', {
      'p_reservation_id': id,
      'p_pickup_code': pickupCode,
      'p_prescription_checked': prescriptionChecked,
      'p_allow_partial': allowPartial,
      'p_partial_reason': partialReason,
    });
  }

  /// Expiration à l'usage, au chargement de la file de l'officine : les
  /// réservations dépassées libèrent leurs boîtes même si la tâche planifiée
  /// n'a pas encore tourné. Silencieuse : un échec ne doit pas empêcher
  /// l'affichage de la file.
  Future<void> expireOverdueForPharmacy(String pharmacyId) async {
    try {
      await _client.rpc(
        'reservation_expire_for_pharmacy',
        params: {'p_pharmacy_id': pharmacyId},
      );
    } catch (_) {}
  }

  /// Réservations actives dont un produit n'est plus disponible (lot rappelé
  /// ou périmé depuis la réservation) : identifiant de réservation → noms
  /// des produits. Sans [pharmacyId] : celles de l'utilisateur connecté.
  /// Silencieuse : rend une carte vide en cas d'échec.
  Future<Map<String, List<String>>> getUnavailableItems({
    String? pharmacyId,
  }) async {
    try {
      final List<dynamic> rows = await _client.rpc(
        'reservation_unavailable_items',
        params: {'p_pharmacy_id': pharmacyId},
      );
      final result = <String, List<String>>{};
      for (final row in rows) {
        result
            .putIfAbsent(row['reservation_id'] as String, () => [])
            .add(row['product_name'] as String);
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Message d'erreur serveur (« RES: … » ou « POS: … », sans accents) rendu
  /// lisible.
  static String serverMessage(String raw) {
    if (raw.startsWith('POS: ') || raw.startsWith('STK: ')) {
      return POSService.serverMessage(raw);
    }
    var message = raw.replaceFirst(RegExp(r'^RES: '), '');
    const accents = {
      'acces refuse': 'accès refusé',
      'reservation expiree': 'réservation expirée',
      'delai de retrait depasse': 'délai de retrait dépassé',
      'deja': 'déjà',
      'reservations': 'réservations',
      'reservation': 'réservation',
      'ne peut pas etre reserve': 'ne peut pas être réservé',
      'stupefiant': 'stupéfiant',
      'presentez-vous a ': 'présentez-vous à ',
      'boites': 'boîtes',
      'quantite': 'quantité',
      'meme produit': 'même produit',
      'designer': 'désigner',
      'non renseigne': 'non renseigné',
      'non attribue, reessayez': 'non attribué, réessayez',
      'ne peut plus etre remis': 'ne peut plus être remis',
      'ne peut etre remis': 'ne peut être remis',
      'lot rappele ou perime': 'lot rappelé ou périmé',
      'peut etre marquee prete': 'peut être marquée prête',
      'ne peut plus etre annulee': 'ne peut plus être annulée',
      'ne peut pas etre retiree': 'ne peut pas être retirée',
    };
    accents.forEach((from, to) => message = message.replaceAll(from, to));
    if (message.isEmpty) return message;
    return message[0].toUpperCase() + message.substring(1);
  }

  // Créneaux horaires simulés — aucune table dédiée (voir
  // PharmaConnect_CLAUDE.md : TimeSlot n'a pas d'id, calculé à la volée).
  // Étape masquée pendant le pilote (PilotConfig.reservationTimeslots).
  Future<List<TimeSlot>> getAvailableTimeSlots({
    required String pharmacyId,
    required DateTime date,
  }) async {
    final slots = <TimeSlot>[];

    const startHour = 8;
    const endHour = 20;

    for (int hour = startHour; hour < endHour; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final start = DateTime(date.year, date.month, date.day, hour, minute);
        final end = start.add(const Duration(minutes: 30));

        final isAvailable = _random.nextDouble() < 0.8;
        final isPeak = (hour >= 12 && hour <= 13) || (hour >= 17 && hour <= 18);
        final waitMinutes = isPeak
            ? 5 + _random.nextInt(10)
            : _random.nextInt(5);

        slots.add(
          TimeSlot(
            start: start,
            end: end,
            label: _formatSlotTime(start, end),
            isAvailable: isAvailable,
            isPeak: isPeak,
            estimatedWaitMinutes: isAvailable ? waitMinutes : null,
          ),
        );
      }
    }

    return slots;
  }

  String _formatSlotTime(DateTime start, DateTime end) {
    final startStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }
}
