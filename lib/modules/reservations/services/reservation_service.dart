import 'dart:math';
import '../models/reservation.dart';
import '../models/reservation_item.dart';
import '../models/reservation_status.dart';
import '../models/timeslot.dart';

class ReservationService {
  static final List<Reservation> _reservations = [];
  static final Random _random = Random();
  static int _counter = 0;

  // ==================== DONNÉES MOCKÉES ====================

  static final List<Reservation> _mockReservations = [
    _createMockReservation(
      id: 'res_001',
      patientName: 'Jean Dupont',
      pharmacyName: 'Pharmacie Centrale',
      status: ReservationStatus.pending,
      items: [
        _createMockItem('Doliprane 1000mg', 2500, 2),
        _createMockItem('Amoxicilline 500mg', 4500, 1),
      ],
      queuePosition: 3,
      estimatedWaitMinutes: 12,
    ),
    _createMockReservation(
      id: 'res_002',
      patientName: 'Marie Konaté',
      pharmacyName: 'Pharmacie du Soleil',
      status: ReservationStatus.confirmed,
      items: [_createMockItem('Ventoline 100µg', 8500, 1)],
      queuePosition: 1,
      estimatedWaitMinutes: 5,
    ),
    _createMockReservation(
      id: 'res_003',
      patientName: 'Ibrahim Camara',
      pharmacyName: 'Pharmacie Moderne',
      status: ReservationStatus.ready,
      items: [_createMockItem('Spasfon 80mg', 3500, 3)],
      queuePosition: 0,
      estimatedWaitMinutes: 0,
    ),
    _createMockReservation(
      id: 'res_004',
      patientName: 'Fatoumata Diallo',
      pharmacyName: 'Pharmacie Centrale',
      status: ReservationStatus.pickedUp,
      items: [_createMockItem('Crestor 10mg', 12000, 1)],
      queuePosition: 0,
      estimatedWaitMinutes: 0,
    ),
  ];

  static ReservationItem _createMockItem(String name, int price, int qty) {
    return ReservationItem(
      productId: 'prod_${_random.nextInt(100)}',
      productName: name,
      genericName: name,
      dosage: '500 mg',
      pricePerUnit: price,
      quantity: qty,
      stockAtReservation: 10,
    );
  }

  static Reservation _createMockReservation({
    required String id,
    required String patientName,
    required String pharmacyName,
    required ReservationStatus status,
    required List<ReservationItem> items,
    int queuePosition = 0,
    int estimatedWaitMinutes = 0,
  }) {
    final now = DateTime.now();
    final pickupDeadline = now.add(const Duration(hours: 2));
    final int totalPrice = items.fold(0, (sum, item) => sum + item.totalPrice);
    return Reservation(
      id: id,
      patientId: 'patient_${_random.nextInt(100)}',
      patientName: patientName,
      patientPhone: '+224612345678',
      pharmacyId: 'ph_${_random.nextInt(5)}',
      pharmacyName: pharmacyName,
      pharmacyAddress: '123 Rue du Commerce, Conakry',
      pharmacyPhone: '+224622334455',
      items: items,
      reservedAt: now.subtract(Duration(minutes: _random.nextInt(60))),
      pickupDeadline: pickupDeadline,
      status: status,
      totalPrice: totalPrice,
      qrCodeToken: 'qr_${_random.nextInt(1000000)}',
      queuePosition: queuePosition,
      estimatedWaitMinutes: estimatedWaitMinutes,
    );
  }

  static void _initMockData() {
    if (_reservations.isEmpty) {
      _reservations.addAll(_mockReservations);
      _counter = _reservations.length;
    }
  }

  // ==================== MÉTHODES ====================

  Future<List<Reservation>> getReservations({ReservationStatus? status}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    if (status != null) {
      return _reservations.where((r) => r.status == status).toList();
    }
    return _reservations;
  }

  Future<Reservation> getReservation(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    return _reservations.firstWhere((r) => r.id == id);
  }

  Future<List<Reservation>> getReservationsForPharmacy(
    String pharmacyId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    return _reservations.where((r) => r.pharmacyId == pharmacyId).toList();
  }

  Future<List<Reservation>> getReservationsForPatient(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    return _reservations.where((r) => r.patientId == patientId).toList();
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
    await Future.delayed(const Duration(seconds: 1));
    _initMockData();

    final id = 'res_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final pickupDeadline = now.add(const Duration(hours: 2));
    _counter++;

    // Calculer la position dans la file d'attente
    final pendingCount = _reservations
        .where(
          (r) =>
              r.pharmacyId == pharmacyId &&
              (r.status == ReservationStatus.pending ||
                  r.status == ReservationStatus.confirmed),
        )
        .length;

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
      items: items,
      reservedAt: now,
      pickupTime: preferredPickupTime,
      pickupDeadline: pickupDeadline,
      status: ReservationStatus.pending,
      totalPrice: items.fold(0, (sum, item) => sum + item.totalPrice),
      qrCodeToken: 'qr_${_counter}${_random.nextInt(1000000)}',
      notes: notes,
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      queuePosition: pendingCount + 1,
      estimatedWaitMinutes: 5 + pendingCount * 3,
    );

    _reservations.add(reservation);
    return reservation;
  }

  Future<Reservation> confirmReservation(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index == -1) throw Exception('Reservation not found');

    // Recalculer la position dans la file d'attente
    final pharmacyId = _reservations[index].pharmacyId;
    final pendingCount = _reservations
        .where(
          (r) =>
              r.pharmacyId == pharmacyId &&
              r.id != id &&
              (r.status == ReservationStatus.pending ||
                  r.status == ReservationStatus.confirmed),
        )
        .length;

    final updated = _reservations[index].copyWith(
      status: ReservationStatus.confirmed,
      confirmedAt: DateTime.now(),
      queuePosition: pendingCount + 1,
      estimatedWaitMinutes: 5 + pendingCount * 3,
    );
    _reservations[index] = updated;
    return updated;
  }

  Future<Reservation> markAsReady(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index == -1) throw Exception('Reservation not found');

    final updated = _reservations[index].copyWith(
      status: ReservationStatus.ready,
      readyAt: DateTime.now(),
      queuePosition: 0,
      estimatedWaitMinutes: 0,
    );
    _reservations[index] = updated;
    return updated;
  }

  Future<Reservation> markAsPickedUp(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index == -1) throw Exception('Reservation not found');

    final updated = _reservations[index].copyWith(
      status: ReservationStatus.pickedUp,
      pickedUpAt: DateTime.now(),
      queuePosition: 0,
      estimatedWaitMinutes: 0,
    );
    _reservations[index] = updated;
    return updated;
  }

  Future<Reservation> cancelReservation(String id, {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initMockData();
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index == -1) throw Exception('Reservation not found');

    final updated = _reservations[index].copyWith(
      status: ReservationStatus.cancelled,
      cancelledAt: DateTime.now(),
      notes: reason,
      queuePosition: 0,
      estimatedWaitMinutes: 0,
    );
    _reservations[index] = updated;
    return updated;
  }

  Future<Reservation> updateReservationStatus(
    String id,
    ReservationStatus newStatus,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _initMockData();
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index == -1) throw Exception('Reservation not found');

    final updated = _reservations[index].copyWith(status: newStatus);
    _reservations[index] = updated;
    return updated;
  }

  Future<List<TimeSlot>> getAvailableTimeSlots({
    required String pharmacyId,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
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
