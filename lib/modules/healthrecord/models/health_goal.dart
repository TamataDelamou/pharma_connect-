import 'package:equatable/equatable.dart';

class HealthGoal extends Equatable {
  final String id;
  final String patientId;
  final String goalType; // steps, water, fruits, meditation, sleep
  final double targetValue;
  final double currentValue;
  final String period; // daily, weekly, monthly
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // active, completed, abandoned
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const HealthGoal({
    required this.id,
    required this.patientId,
    required this.goalType,
    required this.targetValue,
    this.currentValue = 0,
    this.period = 'daily',
    required this.startDate,
    this.endDate,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  HealthGoal copyWith({
    String? id,
    String? patientId,
    String? goalType,
    double? targetValue,
    double? currentValue,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return HealthGoal(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      goalType: goalType ?? this.goalType,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
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
    'patient_id': patientId,
    'goal_type': goalType,
    'target_value': targetValue,
    'current_value': currentValue,
    'period': period,
    'start_date': startDate.toIso8601String().split('T').first,
    if (endDate != null)
      'end_date': endDate!.toIso8601String().split('T').first,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory HealthGoal.fromJson(Map<String, dynamic> json) => HealthGoal(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    goalType: json['goal_type'] as String,
    targetValue: (json['target_value'] as num).toDouble(),
    currentValue: (json['current_value'] as num?)?.toDouble() ?? 0,
    period: json['period'] as String? ?? 'daily',
    startDate: DateTime.parse(json['start_date'] as String),
    endDate: json['end_date'] != null
        ? DateTime.parse(json['end_date'] as String)
        : null,
    status: json['status'] as String? ?? 'active',
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
    patientId,
    goalType,
    targetValue,
    currentValue,
    period,
    startDate,
    endDate,
    status,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];

  String get typeLabel {
    switch (goalType) {
      case 'steps':
        return '🚶 Pas';
      case 'water':
        return '💧 Eau';
      case 'fruits':
        return '🍎 Fruits';
      case 'meditation':
        return '🧘 Méditation';
      case 'sleep':
        return '😴 Sommeil';
      default:
        return goalType;
    }
  }

  double get progressPercentage =>
      targetValue > 0 ? currentValue / targetValue : 0;
  bool get isCompleted => status == 'completed' || currentValue >= targetValue;
}
