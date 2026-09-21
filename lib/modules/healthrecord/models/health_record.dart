import 'package:equatable/equatable.dart';

class Allergy extends Equatable {
  final String id;
  final String name;
  final String? severity; // 'mild', 'moderate', 'severe'
  final String? reaction;
  final DateTime? diagnosedDate;

  const Allergy({
    required this.id,
    required this.name,
    this.severity,
    this.reaction,
    this.diagnosedDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (severity != null) 'severity': severity,
    if (reaction != null) 'reaction': reaction,
    if (diagnosedDate != null)
      'diagnosed_date': diagnosedDate!.toIso8601String(),
  };

  factory Allergy.fromJson(Map<String, dynamic> json) => Allergy(
    id: json['id'] as String,
    name: json['name'] as String,
    severity: json['severity'] as String?,
    reaction: json['reaction'] as String?,
    diagnosedDate: json['diagnosed_date'] != null
        ? DateTime.parse(json['diagnosed_date'] as String)
        : null,
  );

  @override
  List<Object?> get props => [id, name, severity, reaction, diagnosedDate];
}

class MedicalCondition extends Equatable {
  final String id;
  final String name;
  final String? status; // 'active', 'resolved', 'chronic'
  final DateTime? diagnosedDate;
  final String? notes;

  const MedicalCondition({
    required this.id,
    required this.name,
    this.status,
    this.diagnosedDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (status != null) 'status': status,
    if (diagnosedDate != null)
      'diagnosed_date': diagnosedDate!.toIso8601String(),
    if (notes != null) 'notes': notes,
  };

  factory MedicalCondition.fromJson(Map<String, dynamic> json) =>
      MedicalCondition(
        id: json['id'] as String,
        name: json['name'] as String,
        status: json['status'] as String?,
        diagnosedDate: json['diagnosed_date'] != null
            ? DateTime.parse(json['diagnosed_date'] as String)
            : null,
        notes: json['notes'] as String?,
      );

  @override
  List<Object?> get props => [id, name, status, diagnosedDate, notes];
}

class Medication extends Equatable {
  final String id;
  final String name;
  final String? dosage;
  final String? frequency;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? prescribedBy;

  const Medication({
    required this.id,
    required this.name,
    this.dosage,
    this.frequency,
    this.startDate,
    this.endDate,
    this.prescribedBy,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (dosage != null) 'dosage': dosage,
    if (frequency != null) 'frequency': frequency,
    if (startDate != null) 'start_date': startDate!.toIso8601String(),
    if (endDate != null) 'end_date': endDate!.toIso8601String(),
    if (prescribedBy != null) 'prescribed_by': prescribedBy,
  };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    id: json['id'] as String,
    name: json['name'] as String,
    dosage: json['dosage'] as String?,
    frequency: json['frequency'] as String?,
    startDate: json['start_date'] != null
        ? DateTime.parse(json['start_date'] as String)
        : null,
    endDate: json['end_date'] != null
        ? DateTime.parse(json['end_date'] as String)
        : null,
    prescribedBy: json['prescribed_by'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    dosage,
    frequency,
    startDate,
    endDate,
    prescribedBy,
  ];
}

class Vaccination extends Equatable {
  final String id;
  final String name;
  final DateTime? date;
  final DateTime? boosterDate;
  final String? provider;

  const Vaccination({
    required this.id,
    required this.name,
    this.date,
    this.boosterDate,
    this.provider,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (date != null) 'date': date!.toIso8601String(),
    if (boosterDate != null) 'booster_date': boosterDate!.toIso8601String(),
    if (provider != null) 'provider': provider,
  };

  factory Vaccination.fromJson(Map<String, dynamic> json) => Vaccination(
    id: json['id'] as String,
    name: json['name'] as String,
    date: json['date'] != null ? DateTime.parse(json['date'] as String) : null,
    boosterDate: json['booster_date'] != null
        ? DateTime.parse(json['booster_date'] as String)
        : null,
    provider: json['provider'] as String?,
  );

  @override
  List<Object?> get props => [id, name, date, boosterDate, provider];
}

class HealthRecord extends Equatable {
  final String id;
  final String patientId;
  final String? bloodType;
  final int? height;
  final int? weight;
  final List<Allergy> allergies;
  final List<MedicalCondition> medicalConditions;
  final List<Medication> medications;
  final List<Vaccination> vaccinations;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  const HealthRecord({
    required this.id,
    required this.patientId,
    this.bloodType,
    this.height,
    this.weight,
    this.allergies = const [],
    this.medicalConditions = const [],
    this.medications = const [],
    this.vaccinations = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
  });

  HealthRecord copyWith({
    String? id,
    String? patientId,
    String? bloodType,
    int? height,
    int? weight,
    List<Allergy>? allergies,
    List<MedicalCondition>? medicalConditions,
    List<Medication>? medications,
    List<Vaccination>? vaccinations,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      bloodType: bloodType ?? this.bloodType,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      medications: medications ?? this.medications,
      vaccinations: vaccinations ?? this.vaccinations,
      notes: notes ?? this.notes,
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
    if (bloodType != null) 'blood_type': bloodType,
    if (height != null) 'height': height,
    if (weight != null) 'weight': weight,
    'allergies': allergies.map((a) => a.toJson()).toList(),
    'medical_conditions': medicalConditions.map((c) => c.toJson()).toList(),
    'medications': medications.map((m) => m.toJson()).toList(),
    'vaccinations': vaccinations.map((v) => v.toJson()).toList(),
    if (notes != null) 'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory HealthRecord.fromJson(Map<String, dynamic> json) => HealthRecord(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    bloodType: json['blood_type'] as String?,
    height: json['height'] as int?,
    weight: json['weight'] as int?,
    allergies:
        (json['allergies'] as List?)
            ?.map((e) => Allergy.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    medicalConditions:
        (json['medical_conditions'] as List?)
            ?.map((e) => MedicalCondition.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    medications:
        (json['medications'] as List?)
            ?.map((e) => Medication.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    vaccinations:
        (json['vaccinations'] as List?)
            ?.map((e) => Vaccination.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    notes: json['notes'] as String?,
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
    bloodType,
    height,
    weight,
    allergies,
    medicalConditions,
    medications,
    vaccinations,
    notes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
  ];
}
