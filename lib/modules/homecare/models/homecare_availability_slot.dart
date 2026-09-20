import 'package:equatable/equatable.dart';

class HomecareAvailabilitySlot extends Equatable {
  final String id;
  final String professionalId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? gsgId;
  final String? gsgOrgId;

  const HomecareAvailabilitySlot({
    required this.id,
    required this.professionalId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.durationMinutes = 60,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.gsgId,
    this.gsgOrgId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'professional_id': professionalId,
    'day_of_week': dayOfWeek,
    'start_time': startTime,
    'end_time': endTime,
    'duration_minutes': durationMinutes,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  // Phase 3 (module homecare) : copyWith() jamais écrit alors qu'appelé par
  // HomecareService.createAvailabilitySlot()/updateAvailabilitySlot() -
  // défaut de compilation, même motif que CHN-10/ASR-8 déjà rencontrés dans
  // ce projet, jamais détecté faute de compilateur exécuté à la clôture du
  // Module 18/HOM.
  HomecareAvailabilitySlot copyWith({
    String? id,
    String? professionalId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? gsgId,
    String? gsgOrgId,
  }) => HomecareAvailabilitySlot(
    id: id ?? this.id,
    professionalId: professionalId ?? this.professionalId,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    gsgId: gsgId ?? this.gsgId,
    gsgOrgId: gsgOrgId ?? this.gsgOrgId,
  );

  factory HomecareAvailabilitySlot.fromJson(Map<String, dynamic> json) =>
      HomecareAvailabilitySlot(
        id: json['id'] as String,
        professionalId: json['professional_id'] as String,
        dayOfWeek: json['day_of_week'] as int,
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String,
        durationMinutes: json['duration_minutes'] as int? ?? 60,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    professionalId,
    dayOfWeek,
    startTime,
    endTime,
    durationMinutes,
    isActive,
    createdAt,
    updatedAt,
    gsgId,
    gsgOrgId,
  ];
}
