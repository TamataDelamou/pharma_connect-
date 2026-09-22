import 'package:equatable/equatable.dart';

class EPrescriptionHistory extends Equatable {
  final String id;
  final String eprescriptionId;
  final String? oldStatus;
  final String newStatus;
  final String? changedBy;
  final String? notes;
  final DateTime createdAt;

  const EPrescriptionHistory({
    required this.id,
    required this.eprescriptionId,
    this.oldStatus,
    required this.newStatus,
    this.changedBy,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'eprescription_id': eprescriptionId,
    if (oldStatus != null) 'old_status': oldStatus,
    'new_status': newStatus,
    if (changedBy != null) 'changed_by': changedBy,
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };

  factory EPrescriptionHistory.fromJson(Map<String, dynamic> json) =>
      EPrescriptionHistory(
        id: json['id'] as String,
        eprescriptionId: json['eprescription_id'] as String,
        oldStatus: json['old_status'] as String?,
        newStatus: json['new_status'] as String,
        changedBy: json['changed_by'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [
    id,
    eprescriptionId,
    oldStatus,
    newStatus,
    changedBy,
    notes,
    createdAt,
  ];
}
