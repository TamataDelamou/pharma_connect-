import 'package:equatable/equatable.dart';

class PreConsultationSession extends Equatable {
  final String id;
  final String patientId;
  final String? consultationId;
  final String? symptoms;
  final Map<String, dynamic> analysis;
  final String? specialtySuggestion;
  final int? urgencyLevel;
  final bool isCritical;
  final String? summary;
  final String status; // in_progress, completed, abandoned
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? gsgId;
  final String? gsgOrgId;

  const PreConsultationSession({
    required this.id,
    required this.patientId,
    this.consultationId,
    this.symptoms,
    this.analysis = const {},
    this.specialtySuggestion,
    this.urgencyLevel,
    this.isCritical = false,
    this.summary,
    this.status = 'in_progress',
    required this.createdAt,
    required this.updatedAt,
    this.gsgId,
    this.gsgOrgId,
  });

  PreConsultationSession copyWith({
    String? id,
    String? patientId,
    String? consultationId,
    String? symptoms,
    Map<String, dynamic>? analysis,
    String? specialtySuggestion,
    int? urgencyLevel,
    bool? isCritical,
    String? summary,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? gsgId,
    String? gsgOrgId,
  }) {
    return PreConsultationSession(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      consultationId: consultationId ?? this.consultationId,
      symptoms: symptoms ?? this.symptoms,
      analysis: analysis ?? this.analysis,
      specialtySuggestion: specialtySuggestion ?? this.specialtySuggestion,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      isCritical: isCritical ?? this.isCritical,
      summary: summary ?? this.summary,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    if (consultationId != null) 'consultation_id': consultationId,
    if (symptoms != null) 'symptoms': symptoms,
    'analysis': analysis,
    if (specialtySuggestion != null)
      'specialty_suggestion': specialtySuggestion,
    if (urgencyLevel != null) 'urgency_level': urgencyLevel,
    'is_critical': isCritical,
    if (summary != null) 'summary': summary,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory PreConsultationSession.fromJson(Map<String, dynamic> json) =>
      PreConsultationSession(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        consultationId: json['consultation_id'] as String?,
        symptoms: json['symptoms'] as String?,
        analysis: json['analysis'] as Map<String, dynamic>? ?? {},
        specialtySuggestion: json['specialty_suggestion'] as String?,
        urgencyLevel: json['urgency_level'] as int?,
        isCritical: json['is_critical'] as bool? ?? false,
        summary: json['summary'] as String?,
        status: json['status'] as String? ?? 'in_progress',
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    patientId,
    consultationId,
    symptoms,
    analysis,
    specialtySuggestion,
    urgencyLevel,
    isCritical,
    summary,
    status,
    createdAt,
    updatedAt,
    gsgId,
    gsgOrgId,
  ];
}

class DecisionTreeNode extends Equatable {
  final String id;
  final String? parentId;
  final String question;
  final Map<String, dynamic> options;
  final String? leafResult;
  final bool isLeaf;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? gsgId;
  final String? gsgOrgId;

  const DecisionTreeNode({
    required this.id,
    this.parentId,
    required this.question,
    this.options = const {},
    this.leafResult,
    this.isLeaf = false,
    required this.createdAt,
    required this.updatedAt,
    this.gsgId,
    this.gsgOrgId,
  });

  // Phase 4 (module teleconsult) : copyWith() jamais écrit alors qu'appelé
  // par PreConsultationAIService.createNode() - même motif que CHN-10/
  // ASR-8/HOM (déjà rencontrés dans ce projet), jamais détecté faute de
  // compilateur exécuté à la clôture du Module 15/CNS.
  DecisionTreeNode copyWith({
    String? id,
    String? parentId,
    String? question,
    Map<String, dynamic>? options,
    String? leafResult,
    bool? isLeaf,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? gsgId,
    String? gsgOrgId,
  }) => DecisionTreeNode(
    id: id ?? this.id,
    parentId: parentId ?? this.parentId,
    question: question ?? this.question,
    options: options ?? this.options,
    leafResult: leafResult ?? this.leafResult,
    isLeaf: isLeaf ?? this.isLeaf,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    gsgId: gsgId ?? this.gsgId,
    gsgOrgId: gsgOrgId ?? this.gsgOrgId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (parentId != null) 'parent_id': parentId,
    'question': question,
    'options': options,
    if (leafResult != null) 'leaf_result': leafResult,
    'is_leaf': isLeaf,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory DecisionTreeNode.fromJson(Map<String, dynamic> json) =>
      DecisionTreeNode(
        id: json['id'] as String,
        parentId: json['parent_id'] as String?,
        question: json['question'] as String,
        options: json['options'] as Map<String, dynamic>? ?? {},
        leafResult: json['leaf_result'] as String?,
        isLeaf: json['is_leaf'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    parentId,
    question,
    options,
    leafResult,
    isLeaf,
    createdAt,
    updatedAt,
    gsgId,
    gsgOrgId,
  ];
}
