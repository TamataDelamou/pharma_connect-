import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/reservation.dart';
import '../models/reservation_item.dart';
import '../models/reservation_status.dart';
import '../models/timeslot.dart';
import '../../../core/services/supabase_service.dart';

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

    await _client.from('reservations').insert(reservation.toJson());

    if (items.isNotEmpty) {
      await _client
          .from('reservation_items')
          .insert(items.map((i) => i.toJson(reservationId: id)).toList());
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
