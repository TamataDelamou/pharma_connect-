import 'package:equatable/equatable.dart';

class ProfessionalAvailability extends Equatable {
  final String id;
  final String professionalId;
  final int dayOfWeek; // 0=Sunday .. 6=Saturday
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final bool isTeleconsult;
  final bool isBreak;
  final int breakDurationMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const ProfessionalAvailability({
    required this.id,
    required this.professionalId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isTeleconsult = false,
    this.isBreak = false,
    this.breakDurationMinutes = 0,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  ProfessionalAvailability copyWith({
    String? id,
    String? professionalId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isTeleconsult,
    bool? isBreak,
    int? breakDurationMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return ProfessionalAvailability(
      id: id ?? this.id,
      professionalId: professionalId ?? this.professionalId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isTeleconsult: isTeleconsult ?? this.isTeleconsult,
      isBreak: isBreak ?? this.isBreak,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'professional_id': professionalId,
    'day_of_week': dayOfWeek,
    'start_time': startTime,
    'end_time': endTime,
    'is_teleconsult': isTeleconsult,
    'is_break': isBreak,
    'break_duration_minutes': breakDurationMinutes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory ProfessionalAvailability.fromJson(Map<String, dynamic> json) =>
      ProfessionalAvailability(
        id: json['id'] as String,
        professionalId: json['professional_id'] as String,
        dayOfWeek: json['day_of_week'] as int,
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String,
        isTeleconsult: json['is_teleconsult'] as bool? ?? false,
        isBreak: json['is_break'] as bool? ?? false,
        breakDurationMinutes: json['break_duration_minutes'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        createdBy: json['created_by'] as String?,
        updatedBy: json['updated_by'] as String?,
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
    isTeleconsult,
    isBreak,
    breakDurationMinutes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  String get dayLabel {
    const days = [
      'Dimanche',
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
    ];
    return days[dayOfWeek];
  }

  String get timeRange => '$startTime - $endTime';
}
