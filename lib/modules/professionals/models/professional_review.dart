import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show Color;
import 'package:pharma_connect/core/theme/palette.dart';

class ProfessionalReview extends Equatable {
  final String id;
  final String professionalId;
  final String patientId;
  final String? consultationId;
  final int rating;
  final String? reviewText;
  final bool isVerified;
  final bool isAnonymous;
  final int helpfulCount;
  final int notHelpfulCount;
  final String status; // pending, approved, rejected, flagged
  final String? moderationNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? gsgId;
  final String? gsgOrgId;

  // Derived
  final String? patientName;
  final String? professionalName;
  final bool? userVotedHelpful;

  const ProfessionalReview({
    required this.id,
    required this.professionalId,
    required this.patientId,
    this.consultationId,
    required this.rating,
    this.reviewText,
    this.isVerified = false,
    this.isAnonymous = false,
    this.helpfulCount = 0,
    this.notHelpfulCount = 0,
    required this.status,
    this.moderationNotes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.gsgId,
    this.gsgOrgId,
    this.patientName,
    this.professionalName,
    this.userVotedHelpful,
  });

  ProfessionalReview copyWith({
    String? id,
    String? professionalId,
    String? patientId,
    String? consultationId,
    int? rating,
    String? reviewText,
    bool? isVerified,
    bool? isAnonymous,
    int? helpfulCount,
    int? notHelpfulCount,
    String? status,
    String? moderationNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? gsgId,
    String? gsgOrgId,
    String? patientName,
    String? professionalName,
    bool? userVotedHelpful,
  }) {
    return ProfessionalReview(
      id: id ?? this.id,
      professionalId: professionalId ?? this.professionalId,
      patientId: patientId ?? this.patientId,
      consultationId: consultationId ?? this.consultationId,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      isVerified: isVerified ?? this.isVerified,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      notHelpfulCount: notHelpfulCount ?? this.notHelpfulCount,
      status: status ?? this.status,
      moderationNotes: moderationNotes ?? this.moderationNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      gsgId: gsgId ?? this.gsgId,
      gsgOrgId: gsgOrgId ?? this.gsgOrgId,
      patientName: patientName ?? this.patientName,
      professionalName: professionalName ?? this.professionalName,
      userVotedHelpful: userVotedHelpful ?? this.userVotedHelpful,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'professional_id': professionalId,
    'patient_id': patientId,
    if (consultationId != null) 'consultation_id': consultationId,
    'rating': rating,
    if (reviewText != null) 'review_text': reviewText,
    'is_verified': isVerified,
    'is_anonymous': isAnonymous,
    'helpful_count': helpfulCount,
    'not_helpful_count': notHelpfulCount,
    'status': status,
    if (moderationNotes != null) 'moderation_notes': moderationNotes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (gsgId != null) 'gsg_id': gsgId,
    if (gsgOrgId != null) 'gsg_org_id': gsgOrgId,
  };

  factory ProfessionalReview.fromJson(Map<String, dynamic> json) =>
      ProfessionalReview(
        id: json['id'] as String,
        professionalId: json['professional_id'] as String,
        patientId: json['patient_id'] as String,
        consultationId: json['consultation_id'] as String?,
        rating: json['rating'] as int,
        reviewText: json['review_text'] as String?,
        isVerified: json['is_verified'] as bool? ?? false,
        isAnonymous: json['is_anonymous'] as bool? ?? false,
        helpfulCount: json['helpful_count'] as int? ?? 0,
        notHelpfulCount: json['not_helpful_count'] as int? ?? 0,
        status: json['status'] as String,
        moderationNotes: json['moderation_notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        createdBy: json['created_by'] as String?,
        updatedBy: json['updated_by'] as String?,
        gsgId: json['gsg_id'] as String?,
        gsgOrgId: json['gsg_org_id'] as String?,
        patientName: json['patients'] != null
            ? (json['patients'] as Map<String, dynamic>)['full_name'] as String?
            : null,
        professionalName: json['professionals'] != null
            ? (json['professionals'] as Map<String, dynamic>)['full_name']
                  as String?
            : null,
        userVotedHelpful: json['user_voted_helpful'] as bool?,
      );

  @override
  List<Object?> get props => [
    id,
    professionalId,
    patientId,
    consultationId,
    rating,
    reviewText,
    isVerified,
    isAnonymous,
    helpfulCount,
    notHelpfulCount,
    status,
    moderationNotes,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
    gsgId,
    gsgOrgId,
    patientName,
    professionalName,
    userVotedHelpful,
  ];

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente de modération';
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      case 'flagged':
        return 'Signalé';
      default:
        return status;
    }
  }

  String get ratingDisplay {
    return '⭐' * rating + '☆' * (5 - rating);
  }

  // Phase 3 (module professionals) : import Color manquant - défaut de
  // compilation, jamais détecté faute de compilateur exécuté à la clôture
  // du Module 19/INF. Corrigé avec les tokens PharmaConnectColors (KER-DES-03)
  // plutôt qu'un import Color brut, pour ne pas réintroduire la régression
  // déjà documentée et gardée par check_no_hardcoded_color.sh.
  ColorRole get statusColor {
    switch (status) {
      case 'pending':
        return ColorRole.warning;
      case 'approved':
        return ColorRole.success;
      case 'rejected':
        return ColorRole.danger;
      case 'flagged':
        return ColorRole.danger;
      default:
        return ColorRole.textMuted;
    }
  }
}
