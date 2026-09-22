import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/reservation.dart';
import '../models/reservation_item.dart';
import '../models/reservation_status.dart';
import '../models/timeslot.dart';
import '../../../core/services/supabase_service.dart';
import '../../stock/services/stock_service.dart';

class ReservationService {
  SupabaseClient get _client => SupabaseService().client;
  final StockService _stockService = StockService();
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
        .eq('pharmacy_id', pharmacyId);
    return rows.map((row) => Reservation.fromJson(row)).toList();
  }

  Future<List<Reservation>> getReservationsForPatient(String patientId) async {
    final rows = await _client
        .from('reservations')
        .select(_reservationSelect)
        .eq('patient_id', patientId);
    return rows.map((row) => Reservation.fromJson(row)).toList();
  }

  Future<int> _pendingCountForPharmacy(
    String pharmacyId, {
    String? excludeReservationId,
  }) async {
    var query = _client
        .from('reservations')
        .select('id')
        .eq('pharmacy_id', pharmacyId)
        .inFilter('status', [
          ReservationStatus.pending.name,
          ReservationStatus.confirmed.name,
        ]);
    if (excludeReservationId != null) {
      query = query.neq('id', excludeReservationId);
    }
    final rows = await query;
    return rows.length;
  }

  // RG-RES-01 (audit Module 6, 29/08/2026) : une réservation doit bloquer
  // immédiatement la quantité réservée dans le stock visible de l'officine,
  // pour toute la durée de la réservation — sinon deux patients peuvent
  // réserver le même dernier exemplaire, et le stock affiché (Module 4)
  // reste faux tant que personne n'a "vraiment" acheté. Le moteur de
  // réservation FEFO existe déjà et a été audité correct au Module 4
  // (StockService.reserveStock/confirmReservation/cancelReservation) mais
  // n'était jusqu'ici appelé par AUCUN module de l'application — ce service
  // créait des réservations sans jamais toucher au stock. On réserve donc
  // ici, ligne par ligne, avant d'écrire quoi que ce soit dans
  // reservations/reservation_items, avec compensation (libération) des
  // lignes déjà réservées si une ligne suivante échoue (rupture entre-temps,
  // produit introuvable) ou si l'écriture de la réservation elle-même
  // échoue ensuite — il n'existe pas de transaction cross-table côté client
  // dans cette architecture (même limite que partout ailleurs dans le
  // projet), donc cette compensation est best-effort et non atomique.
  Future<Reservation> createReservation({
    required String patientId,
    required String patientName,
    required String patientPhone,
    String? patientEmail,
    required String pharmacyId,
    required String pharmacyName,
    required String pharmacyAddress,
    String? pharmacyPhone,
    required List<ReservationItem> items,
    required DateTime? preferredPickupTime,
    String? deliveryAddress,
    String? paymentMethod,
    String? notes,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final pendingCount = await _pendingCountForPharmacy(pharmacyId);

    final reservedItems = <ReservationItem>[];
    for (final item in items) {
      // Ligne sans produit catalogué (productId vide) : rien à réserver côté
      // stock — voir registre des écarts (panier libre, hors cahier normal).
      if (item.productId.isEmpty) continue;
      bool reserved;
      try {
        reserved = await _stockService.reserveStock(
          productId: item.productId,
          pharmacyId: pharmacyId,
          quantity: item.quantity,
          referenceId: id,
          userId: patientId,
        );
      } catch (e) {
        reserved = false;
      }
      if (!reserved) {
        for (final done in reservedItems) {
          try {
            await _stockService.cancelReservation(
              productId: done.productId,
              pharmacyId: pharmacyId,
              quantity: done.quantity,
              referenceId: id,
            );
          } catch (_) {
            // best-effort — voir docstring ci-dessus.
          }
        }
        throw StateError(
          'Stock insuffisant pour "${item.productName}" — réservation annulée.',
        );
      }
      reservedItems.add(item);
    }

    final reservation = Reservation(
      id: id,
      patientId: patientId,
      patientName: patientName,
      patientPhone: patientPhone,
      patientEmail: patientEmail,
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      pharmacyAddress: pharmacyAddress,
      pharmacyPhone: pharmacyPhone,
      items: const [],
      reservedAt: now,
      pickupTime: preferredPickupTime,
      pickupDeadline: now.add(const Duration(hours: 2)),
      status: ReservationStatus.pending,
      totalPrice: items.fold(0, (sum, item) => sum + item.totalPrice),
      qrCodeToken: 'qr_${const Uuid().v4().substring(0, 8)}',
      notes: notes,
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      queuePosition: pendingCount + 1,
      estimatedWaitMinutes: 5 + pendingCount * 3,
    );

    try {
      await _client.from('reservations').insert(reservation.toJson());

      if (items.isNotEmpty) {
        await _client
            .from('reservation_items')
            .insert(items.map((i) => i.toJson(reservationId: id)).toList());
      }
    } catch (e) {
      // Le stock a déjà été réservé côté serveur mais l'écriture de la
      // réservation elle-même a échoué (RLS, réseau) : libérer pour ne pas
      // laisser du stock bloqué sans réservation qui le justifie.
      for (final done in reservedItems) {
        try {
          await _stockService.cancelReservation(
            productId: done.productId,
            pharmacyId: pharmacyId,
            quantity: done.quantity,
            referenceId: id,
          );
        } catch (_) {}
      }
      rethrow;
    }

    return getReservation(id);
  }

  Future<Reservation> confirmReservation(String id) async {
    final current = await getReservation(id);
    final pendingCount = await _pendingCountForPharmacy(
      current.pharmacyId,
      excludeReservationId: id,
    );

    final row = await _client
        .from('reservations')
        .update({
          'status': ReservationStatus.confirmed.name,
          'confirmed_at': DateTime.now().toIso8601String(),
          'queue_position': pendingCount + 1,
          'estimated_wait_minutes': 5 + pendingCount * 3,
        })
        .eq('id', id)
        .select(_reservationSelect)
        .single();
    return Reservation.fromJson(row);
  }

  Future<Reservation> markAsReady(String id) async {
    final row = await _client
        .from('reservations')
        .update({
          'status': ReservationStatus.ready.name,
          'ready_at': DateTime.now().toIso8601String(),
          'queue_position': 0,
          'estimated_wait_minutes': 0,
        })
        .eq('id', id)
        .select(_reservationSelect)
        .single();
    return Reservation.fromJson(row);
  }

  Future<Reservation> markAsPickedUp(String id) async {
    // RG-RES-01 : le retrait finalise la vente — décrémente réellement le
    // stock (StockService.confirmReservation), symétrique du blocage fait à
    // createReservation. Best-effort ligne par ligne : un échec réseau isolé
    // sur une ligne ne doit pas empêcher d'enregistrer un retrait déjà
    // effectué physiquement en officine (à réconcilier manuellement le cas
        // échéant — voir registre des écarts).
    final current = await getReservation(id);
    for (final item in current.items) {
      if (item.productId.isEmpty) continue;
      try {
        await _stockService.confirmReservation(
          productId: item.productId,
          pharmacyId: current.pharmacyId,
          quantity: item.quantity,
          referenceId: id,
          userId: current.patientId.isEmpty ? null : current.patientId,
        );
      } catch (_) {}
    }

    final row = await _client
        .from('reservations')
        .update({
          'status': ReservationStatus.pickedUp.name,
          'picked_up_at': DateTime.now().toIso8601String(),
          'queue_position': 0,
          'estimated_wait_minutes': 0,
        })
        .eq('id', id)
        .select(_reservationSelect)
        .single();
    return Reservation.fromJson(row);
  }

  Future<Reservation> cancelReservation(String id, {String? reason}) async {
    final current = await getReservation(id);
    // Ne libérer le stock que si la réservation le retenait encore (pending/
    // confirmed/ready) : au-delà (déjà retirée), le stock a déjà été
    // décrémenté définitivement par markAsPickedUp et ne doit plus bouger.
    if (current.status == ReservationStatus.pending ||
        current.status == ReservationStatus.confirmed ||
        current.status == ReservationStatus.ready) {
      for (final item in current.items) {
        if (item.productId.isEmpty) continue;
        try {
          await _stockService.cancelReservation(
            productId: item.productId,
            pharmacyId: current.pharmacyId,
            quantity: item.quantity,
            referenceId: id,
          );
        } catch (_) {}
      }
    }

    final row = await _client
        .from('reservations')
        .update({
          'status': ReservationStatus.cancelled.name,
          'cancelled_at': DateTime.now().toIso8601String(),
          'notes': reason,
          'queue_position': 0,
          'estimated_wait_minutes': 0,
        })
        .eq('id', id)
        .select(_reservationSelect)
        .single();
    return Reservation.fromJson(row);
  }

  /// RG-RES-02 : au-delà du délai de retrait (pickup_deadline), une
  /// réservation non retirée doit être automatiquement expirée et le stock
  /// qu'elle retenait libéré. Aucune infrastructure de tâche planifiée
  /// (cron / job serveur) n'existe dans ce projet (voir registre des
  /// écarts) : ce balayage est déclenché de façon opportuniste par
  /// ReservationProvider, au chargement de "mes réservations" et de la file
  /// d'attente pharmacien, plutôt que vraiment en tâche de fond. Best-effort
  /// et silencieux de bout en bout : un échec ici ne doit jamais empêcher
  /// l'affichage de la liste qui le déclenche.
  Future<void> expireOverdueReservations({String? pharmacyId}) async {
    try {
      var query = _client
          .from('reservations')
          .select(_reservationSelect)
          .inFilter('status', [
            ReservationStatus.pending.name,
            ReservationStatus.confirmed.name,
            ReservationStatus.ready.name,
          ])
          .lt('pickup_deadline', DateTime.now().toIso8601String());
      if (pharmacyId != null) {
        query = query.eq('pharmacy_id', pharmacyId);
      }
      final rows = await query;
      for (final row in rows) {
        final reservation = Reservation.fromJson(row);
        for (final item in reservation.items) {
          if (item.productId.isEmpty) continue;
          try {
            await _stockService.cancelReservation(
              productId: item.productId,
              pharmacyId: reservation.pharmacyId,
              quantity: item.quantity,
              referenceId: reservation.id,
            );
          } catch (_) {}
        }
        try {
          await _client
              .from('reservations')
              .update({
                'status': ReservationStatus.expired.name,
                'queue_position': 0,
                'estimated_wait_minutes': 0,
              })
              .eq('id', reservation.id);
        } catch (_) {}
      }
    } catch (_) {
      // best-effort — voir docstring.
    }
  }

  /// Persiste côté serveur une position de file recalculée localement par
  /// ReservationProvider.refreshQueue — sans cet appel, un autre appareil
  /// (le patient consultant sa propre réservation) voyait une position
  /// figée à celle du moment de la création, jamais mise à jour au fil de
  /// la file (bug relevé à l'audit Module 6). Best-effort : un échec isolé
  /// sur une ligne ne doit pas interrompre le rafraîchissement de la file.
  Future<void> updateQueuePosition(
    String id, {
    required int position,
    required int estimatedWaitMinutes,
  }) async {
    await _client
        .from('reservations')
        .update({
          'queue_position': position,
          'estimated_wait_minutes': estimatedWaitMinutes,
        })
        .eq('id', id);
  }

  Future<Reservation> updateReservationStatus(
    String id,
    ReservationStatus newStatus,
  ) async {
    final row = await _client
        .from('reservations')
        .update({'status': newStatus.name})
        .eq('id', id)
        .select(_reservationSelect)
        .single();
    return Reservation.fromJson(row);
  }

  // Créneaux horaires simulés — aucune table dédiée (voir
  // PharmaConnect_CLAUDE.md : TimeSlot n'a pas d'id, calculé à la volée).
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
